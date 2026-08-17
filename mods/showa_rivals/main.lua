-- Showa Rivals: rivals with lives of their own.
--
-- Clean-room work.  MrKrisSatan's AIRivals is the inspiration for the
-- IDEA -- persistent rivals who travel, train and turn up on their own --
-- and nothing else: that mod ships without a license and only as zips,
-- so none of it was read, unpacked or copied.
--
-- The v1 bet is scheduled appearances on showa_core's venue graph rather
-- than tile-level pathing: a rival is *at* a venue, and walking into that
-- venue's map is what makes it appear.  That keeps the whole brain in
-- sim/ as pure functions -- seeded, replayable, soak-testable -- and
-- leaves tile pathing as a later swap of the travel step alone.
local Advance = require("mods.showa_rivals.sim.advance")

local Venues = require("mods.showa_rivals.world.venues")

-- The cast, one data file each -- which is the framework paying off: a
-- new rival is a character sheet, never a code change.
--
-- Where a rival's baby Pokemon is a later generation than Gold, they
-- carry its Gen 2 relative instead (Azurill -> MARILL, Bonsly ->
-- SUDOWOODO, Mime Jr. -> MR__MIME, Happiny -> CHANSEY, Munchlax ->
-- SNORLAX, Mantyke -> MANTINE, Wynaut -> WOBBUFFET, Riolu -> MACHOP,
-- Budew -> BELLSPROUT, Chingling -> NATU).  Named honestly in mod.card
-- rather than pretending Gold has species it does not.
local ROSTER = {
  require("mods.showa_rivals.rivals.elm"),
  require("mods.showa_rivals.rivals.pichu"),
  require("mods.showa_rivals.rivals.azurill"),
  require("mods.showa_rivals.rivals.cleffa"),
  require("mods.showa_rivals.rivals.igglybuff"),
  require("mods.showa_rivals.rivals.smoochum"),
  require("mods.showa_rivals.rivals.elekid"),
  require("mods.showa_rivals.rivals.magby"),
  require("mods.showa_rivals.rivals.wynaut"),
  require("mods.showa_rivals.rivals.budew"),
  require("mods.showa_rivals.rivals.chingling"),
  require("mods.showa_rivals.rivals.bonsly"),
  require("mods.showa_rivals.rivals.mimejr"),
  require("mods.showa_rivals.rivals.happiny"),
  require("mods.showa_rivals.rivals.munchlax"),
  require("mods.showa_rivals.rivals.riolu"),
  require("mods.showa_rivals.rivals.mantyke"),
  require("mods.showa_rivals.rivals.tyrogue_lee"),
  require("mods.showa_rivals.rivals.tyrogue_chan"),
  require("mods.showa_rivals.rivals.tyrogue_top"),
}

-- One tick per this many steps: coarse on purpose.  core.update would be
-- a per-frame tax for a simulation whose whole point is that it moves at
-- the pace of a day out, not a frame.
local STEPS_PER_TICK = 256

return function(mod)
  local core = assert(mod.find("showa_core"),
    "showa_rivals needs showa_core").exports
  local arcadeMod = mod.find("showa_arcade")
  local arcade = arcadeMod and arcadeMod.exports
  local contestsMod = mod.find("showa_contests")
  local contests = contestsMod and contestsMod.exports

  local defs = {}
  for _, def in ipairs(ROSTER) do defs[def.id] = def end

  -- ------- venues this mod owns, then the edges

  -- cells verified free against each map's collision and object layers
  core.venues.register("ELM_LAB", {
    map = "ELMS_LAB", label = "ELM'S LAB", tags = { "story" },
    x = 3, y = 4 })
  core.venues.register("ALPH_RUINS", {
    map = "RUINS_OF_ALPH_OUTSIDE", label = "RUINS OF ALPH",
    tags = { "story", "mystery" }, x = 11, y = 17 })
  for _, spot in ipairs(Venues.LIST) do
    core.venues.register(spot.id, {
      map = spot.map, label = spot.label, tags = spot.tags,
      x = spot.x, y = spot.y })
  end

  -- Connect everything that exists.  A venue a feature mod did not
  -- register simply is not there, and the graph stays whole around it --
  -- which is what lets this mod load with none of the others.
  local function link(a, b, cost)
    if core.venues.get(a) and core.venues.get(b) then
      core.venues.connect(a, b, cost)
    end
  end
  for _, edge in ipairs(Venues.EDGES) do link(edge[1], edge[2], edge[3]) end
  link("GOLDENROD_ARCADE", "CHIKAGAI", 1)
  link("CHIKAGAI", "SHOWA_MALL", 1)
  link("ELM_LAB", "ALPH_RUINS", 2)

  -- ------- persistent rival state

  local state = mod.save:get("state")
  if type(state) ~= "table" or state.v ~= 1 then
    state = { v = 1, rivals = {}, steps = 0 }
  end
  for id, def in pairs(defs) do
    local live = state.rivals[id]
    -- a rival whose home venue vanished (its feature mod was removed)
    -- is re-homed rather than left pointing at nothing
    if not live or not core.venues.get(live.location) then
      local home = core.venues.get(def.home) and def.home or "ELM_LAB"
      live = Advance.spawn(def, def.seed)
      live.location = home
      state.rivals[id] = live
    end
  end
  local function persist() mod.save:set("state", state) end
  persist()

  -- ------- the world the sim sees (no engine reaches into sim/)

  local function playerLevel()
    local party = mod.game and mod.game.save and mod.game.save.party
    local best = 5
    for _, mon in ipairs(party or {}) do
      if (mon.level or 0) > best then best = mon.level end
    end
    return best
  end

  local function badgeCount()
    local save = mod.game and mod.game.save
    local badges = save and (save.badges or (save.player and save.player.badges))
    if type(badges) == "number" then return badges end
    local n = 0
    for _, has in pairs(badges or {}) do if has then n = n + 1 end end
    return n
  end

  local function worldView()
    return {
      playerLevel = playerLevel(),
      badges = badgeCount(),
      neighbors = function(venueId) return core.venues.neighbors(venueId) end,
      venueExists = function(venueId)
        return core.venues.get(venueId) ~= nil
      end,
    }
  end

  local function tickAll()
    local view = worldView()
    for id, live in pairs(state.rivals) do
      local def = defs[id]
      if def then
        local _, events = Advance.tick(live, def, view)
        for _, event in ipairs(events) do
          if event.kind == "caught" then
            core.news.post(("%s caught a %s."):format(def.name, event.species))
          end
        end
        -- the arcade rat actually posts scores to the cabinet
        if def.arcade and arcade then
          local roll = live.seed % 100
          local score = def.arcade.skill * 10
            + math.floor(roll * def.arcade.variance / 100)
          arcade.submitScore(def.arcade.game, score, def.name)
        end
      end
    end
    persist()
  end

  -- Ticking on map.ENTERED would move everyone at the exact moment the
  -- player walks in to see them, so a rival could never be where the
  -- news said it was.  The world turns as you LEAVE a place instead.
  mod.events:on("game.ready", tickAll)
  mod.events:on("map.exited", function() tickAll() end)
  mod.events:on("world.stepped", function()
    state.steps = (state.steps or 0) + 1
    if state.steps >= STEPS_PER_TICK then
      state.steps = 0
      tickAll()
      -- a rival who wandered off mid-visit has to actually leave
      if mod.exports.debug then mod.exports.debug.refresh() end
    end
  end)

  -- ------- trainer classes, one per rival

  for _, def in ipairs(ROSTER) do
    mod.content.trainers:register(def.trainerClass, {
      name = def.name,
      trainers = {
        { name = def.name, party = {
          { level = def.starter[1].level, species = def.starter[1].species },
        } },
      },
    })
  end

  -- The live party is substituted at battle time rather than baked into
  -- the class: the class record is a placeholder the engine needs, and
  -- this hook is what makes the rival you fight the rival you have been
  -- reading about in the news.
  local classToRival = {}
  for _, def in ipairs(ROSTER) do classToRival[def.trainerClass] = def.id end

  mod.hooks:wrap("trainer.party", function(nextFn, classId, memberId, party)
    local out = nextFn(classId, memberId, party)
    local rivalId = classToRival[classId]
    local live = rivalId and state.rivals[rivalId]
    if not live or #live.party == 0 then return out end
    local built = {}
    for _, mon in ipairs(live.party) do
      built[#built + 1] = { species = mon.species, level = mon.level }
    end
    return built
  end)

  -- ------- appearances

  -- Not ctx.vm:showText(text): that takes a KEY and prints "..." for a
  -- sentence.  core.dialogue parks the line in the text table first.
  local function say(ctx, text)
    return core.dialogue.say(ctx, text)
  end

  mod.content.commands:register("showa_rivals:talk", function(ctx, rivalId)
    local def = defs[rivalId]
    local live = state.rivals[rivalId]
    if not (def and live) then return "end" end
    local lead = live.party[1]
    say(ctx, ("%s\n(%s, Lv%d %s)"):format(def.lines.greet, def.name,
      lead and lead.level or 5, lead and lead.species or "?"))
    return "end"
  end)

  -- Rivals are spawned per map entry and cleared when they move on, so
  -- the world only ever holds the ones actually standing there.
  local spawned = {}
  local lastSpawnNote = "not attempted"
  local function refreshAppearances()
    local here = mod.world and mod.world:current()
    local mapId = here and here.mapId
    lastSpawnNote = "map=" .. tostring(mapId)
    for id, live in pairs(state.rivals) do
      local def = defs[id]
      local venue = core.venues.get(live.location)
      local wanted = venue and mapId and venue.map == mapId
      if wanted and not spawned[id] then
        -- A venue's own cell may already be somebody's -- the derby
        -- judge stands on LAKE_DERBY's -- so step aside rather than
        -- stacking two NPCs on one tile, where only the first is
        -- reachable.
        local ok, npcId = pcall(function()
          local overworld = mod.world:overworld()
          local bx, by = venue.x or 5, venue.y or 3
          for _, offset in ipairs({ { 0, 0 }, { 1, 0 }, { -1, 0 },
                                    { 0, 1 }, { 0, -1 } }) do
            local cx, cy = bx + offset[1], by + offset[2]
            local taken = overworld and overworld.npcAt
              and overworld:npcAt(cx, cy)
            if not taken then
              return mod.world:spawnNpc(venue.map, {
                sprite = def.sprite, x = cx, y = cy,
                movement = 6, radius = { x = 0, y = 0 },
                hours = { -1, -1 },
                scriptKey = { { "showa_rivals:talk", id } },
              })
            end
          end
          return nil
        end)
        if ok and npcId then
          spawned[id] = npcId
        else
          lastSpawnNote = ("%s spawn at %s (%s,%s) failed: %s"):format(
            id, tostring(venue.map), tostring(venue.x), tostring(venue.y),
            tostring(npcId))
        end
      elseif not wanted and spawned[id] then
        pcall(function() mod.world:removeNpc(spawned[id]) end)
        spawned[id] = nil
      end
    end
  end

  mod.events:on("map.entered", refreshAppearances)
  mod.events:on("map.exited", function()
    for id, npcId in pairs(spawned) do
      pcall(function() mod.world:removeNpc(npcId) end)
      spawned[id] = nil
    end
  end)

  -- ------- the derby competitors (optional dependency)

  if contests and contests.registerCompetitor then
    for _, def in ipairs(ROSTER) do
      if def.derby then
        contests.registerCompetitor(function()
          local live = state.rivals[def.id]
          if not live then return nil end
          local best = 0
          for _, mon in ipairs(live.party) do
            if mon.level > best then best = mon.level end
          end
          local luck = (live.seed % 100) * def.derby.luck / 100
          return {
            name = def.name, species = "SEAKING",
            size = math.floor(def.derby.base + best * def.derby.perLevel
              + luck),
          }
        end)
      end
    end
  end

  -- ------- the rival dex

  mod.content.screens:register("ShowaRivalDex", {
    new = function(game)
      local items = {}
      for _, def in ipairs(ROSTER) do
        local live = state.rivals[def.id]
        local venue = live and core.venues.get(live.location)
        local lead = live and live.party[1]
        items[#items + 1] = {
          label = ("%s Lv%d"):format(def.name, lead and lead.level or 5),
          right = venue and venue.label:sub(1, 10) or "???",
        }
      end
      return mod.ui.ListMenu.new(game, "RIVALS", items, {
        onChoose = function(_, menu) menu:close() end,
      })
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(nextFn, game, items)
    local out = nextFn(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "RIVALS",
      onSelect = function() mod.ui.push(game, "ShowaRivalDex") end,
    })
  end)

  -- ------- exports

  mod.exports.roster = function()
    local out = {}
    for _, def in ipairs(ROSTER) do
      local live = state.rivals[def.id]
      out[#out + 1] = { id = def.id, name = def.name,
                        location = live and live.location,
                        party = live and live.party }
    end
    return out
  end
  mod.exports.at = function(venueId)
    local out = {}
    for id, live in pairs(state.rivals) do
      if live.location == venueId then out[#out + 1] = id end
    end
    table.sort(out)
    return out
  end
  mod.exports.recordBattle = function(rivalId, won)
    local live = state.rivals[rivalId]
    if not live then return end
    live.history = live.history or { wins = 0, losses = 0 }
    if won then
      live.history.losses = live.history.losses + 1
    else
      live.history.wins = live.history.wins + 1
    end
    persist()
  end
  mod.exports.debug = {
    tick = tickAll,
    refresh = refreshAppearances,
    -- drivers must warp through the mod-facing WorldAPI, not the raw
    -- World object hanging off `game` -- they are different types
    warp = function(mapId, x, y, facing)
      return mod.world:warpTo(mapId, x, y, facing or "up")
    end,
    spawnNote = function() return lastSpawnNote end,
    -- put the whole cast at one venue: the fastest way to eyeball every
    -- rival at once without waiting for the simulation to scatter them
    sendAll = function(venueId)
      if not core.venues.get(venueId) then return false end
      for _, live in pairs(state.rivals) do
        live.location = venueId
        live.travel = 0
      end
      persist()
      return true
    end,
  }
end
