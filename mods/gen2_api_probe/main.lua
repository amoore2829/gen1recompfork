-- Gen 2 API probe: a dev TOOL that audits which mod-API seams are live on a
-- Gold boot.  docs/mod-api-gen2-compat.md documents the intended coverage;
-- this mod measures the actual one, so the Showa suite is built on counts,
-- not claims.  Re-run after every upstream sync (FEATURES.md convention).
--
-- The report is reachable three ways: the PROBE row on the START menu, the
-- `report` export (mods and drivers), and one log line on game.ready.
return function(mod)
  local counters = { events = {}, hooks = {}, checks = {} }

  -- ------- seams Phase 1 listens on, counted

  local EVENTS = {
    "game.ready", "map.entered", "map.exited", "world.stepped",
    "world.interacted", "world.trainer_engaged", "world.tod_changed",
    "clock.day_changed", "battle.started", "battle.ended",
    "pokemon.caught", "bug_contest.scored", "screen.pushed",
    "save.loaded", "flag.changed", "script.started",
  }
  for _, name in ipairs(EVENTS) do
    counters.events[name] = 0
    mod.events:on(name, function()
      counters.events[name] = counters.events[name] + 1
    end)
  end
  -- what kind of thing each A press actually landed on, for the driver
  mod.events:on("world.interacted", function(payload)
    if type(payload) == "table" then
      counters.checks.last_interact = tostring(payload.kind)
    end
  end)

  local HOOKS = {
    "trainer.party", "encounter.roll", "encounter.species",
    "encounter.fishing", "warp.destination", "world.tod",
    "input.step", "save.write",
  }
  for _, name in ipairs(HOOKS) do
    counters.hooks[name] = 0
    mod.hooks:wrap(name, function(nextFn, ...)
      counters.hooks[name] = counters.hooks[name] + 1
      return nextFn(...)
    end)
  end

  -- ------- registrations, one per registry Phase 1 leans on.
  -- Ids come off the merged view rather than being hardcoded, so the same
  -- probe validates against the ROM-free fixture and a real Gold cache.

  local function pickId(reg, prefer)
    local ok, hit = pcall(function() return reg:get(prefer) end)
    if ok and hit then return prefer end
    for id in reg:each() do return id end
    return nil
  end

  local tileset = pickId(mod.content.tilesets, "TILESET_GAME_CORNER")
  if tileset then
    local blocks = {}
    for i = 1, 16 do blocks[i] = 1 end
    mod.content.maps:register("SHOWA_PROBE_ROOM", {
      id = "SHOWA_PROBE_ROOM",
      tileset = tileset, width = 4, height = 4,
      blocks = blocks, borderBlock = 0,
      warps = { { x = 1, y = 3, destMap = "GOLDENROD_GAME_CORNER",
                  destWarp = 1 } },
    })
  end
  counters.checks.maps = mod.content.maps:get("SHOWA_PROBE_ROOM") ~= nil

  local species = pickId(mod.content.pokemon, "RATTATA")
  if species then
    mod.content.trainers:register("SHOWA_PROBE", {
      name = "PROBE",
      trainers = { { name = "PROBE", party = {
        { level = 5, species = species } } } },
    })
  end
  counters.checks.trainers = mod.content.trainers:get("SHOWA_PROBE") ~= nil

  -- The verb a spawned NPC's row list dispatches through Gold's VM
  -- (docs/mod-api-gen2-compat.md "mod.commands"): the handler may block on
  -- ctx.vm:showText, which is the whole dialogue channel on Gen 2.
  mod.content.commands:register("probe:hello", function(ctx)
    counters.checks.command_ran = true
    if ctx and ctx.vm and ctx.vm.showText then
      ctx.vm:showText("GEN2 PROBE: a mod verb ran on this boot!")
    end
  end)
  counters.checks.commands = mod.content.commands:get("probe:hello") ~= nil

  mod.content.screens:register("Gen2ProbeReport", {
    new = function(game)
      local items = {}
      local function add(label, right)
        items[#items + 1] = { label = label, right = tostring(right) }
      end
      for _, name in ipairs(EVENTS) do add(name, counters.events[name]) end
      for _, name in ipairs(HOOKS) do add(name, counters.hooks[name]) end
      local names = {}
      for name in pairs(counters.checks) do names[#names + 1] = name end
      table.sort(names)
      for _, name in ipairs(names) do
        add(name, counters.checks[name] and "OK" or "MISSING")
      end
      return mod.ui.ListMenu.new(game, "GEN2 PROBE", items, {
        onChoose = function(_, menu) menu:close() end,
      })
    end,
  })
  counters.checks.screens = mod.content.screens:get("Gen2ProbeReport") ~= nil

  mod.hooks:wrap("ui.start_menu.items", function(nextFn, game, items)
    counters.hooks["ui.start_menu.items"] =
      (counters.hooks["ui.start_menu.items"] or 0) + 1
    local out = nextFn(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "PROBE",
      onSelect = function() mod.ui.push(game, "Gen2ProbeReport") end,
    })
  end)

  -- ------- direct API presence + persistence roundtrip

  counters.checks.world_api = type(mod.world) == "table"
    and type(mod.world.spawnNpc) == "function"

  local boots = (mod.save:get("boots") or 0) + 1
  mod.save:set("boots", boots)
  counters.checks.save_roundtrip = mod.save:get("boots") == boots

  -- ------- exports: the report, and a spawn exercised by the boot driver

  mod.exports.report = function()
    return { events = counters.events, hooks = counters.hooks,
             checks = counters.checks }
  end

  mod.exports.spawnProbeNpc = function(mapId, x, y)
    local sprite = pickId(mod.content.sprites, "SPRITE_CLERK")
    -- deliberately no eventFlag: a runtime object carries none, which is
    -- what keeps it visible through LoadObjectMasks' derivation
    local npcId, err = mod.world:spawnNpc(mapId, {
      sprite = sprite, x = x, y = y,
      movement = 6, radius = { x = 0, y = 0 },
      hours = { -1, -1 },
      -- a table scriptKey is run by Vm:start as a row list; the row is the
      -- probe's own verb, which is the supported mod-NPC dialogue route
      scriptKey = { { "probe:hello" } },
    })
    counters.checks.spawn_npc = npcId ~= nil
    return npcId, err
  end

  mod.events:on("game.ready", function()
    local c = counters.checks
    local function s(v) return v and "ok" or "MISSING" end
    mod.log:warn(("gen2 probe: maps=%s trainers=%s commands=%s screens=%s "
      .. "world=%s save=%s (PROBE row on the START menu has live counts)")
      :format(s(c.maps), s(c.trainers), s(c.commands), s(c.screens),
              s(c.world_api), s(c.save_roundtrip)))
  end)
end
