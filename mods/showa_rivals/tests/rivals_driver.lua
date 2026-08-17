-- Driver: rivals on a real Gold boot.  Ticks the simulation, walks to
-- wherever a rival has ended up, and talks to them -- which is the whole
-- appearance chain: venue -> map -> spawned NPC -> the mod's own verb.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=rivals_driver POKEPORT_NO_DISCORD=1 \
--     POKEPORT_DRIVER=mods/showa_rivals/tests/rivals_driver.lua love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local failures = 0
  local function check(cond, msg)
    U.log(cond and "ok  " or "FAIL", msg)
    if not cond then failures = failures + 1 end
  end

  U.wait(30)

  local exports = game.mods and game.mods.exports or {}
  local core, rivals = exports.showa_core, exports.showa_rivals
  local arcade, contests = exports.showa_arcade, exports.showa_contests
  check(core ~= nil, "showa_core loaded")
  check(rivals ~= nil, "showa_rivals loaded")
  if not (core and rivals) then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end

  local world = game.world

  -- ------- the roster is real and placed

  local roster = rivals.roster()
  check(#roster == 20, "the whole cast is in the roster (" .. #roster .. ")")
  for _, entry in ipairs(roster) do
    local venue = core.venues.get(entry.location)
    check(venue ~= nil, entry.name .. " is at a registered venue")
    check(venue and game.data.gen2Maps[venue.map] ~= nil,
      entry.name .. "'s venue points at a real map")
  end

  -- ------- the trainer classes reached the live Gen 2 table

  for _, class in ipairs({ "SHOWA_ELM", "SHOWA_PICHU_KID",
                           "SHOWA_AZURILL_KID" }) do
    check(game.data.gen2Trainers.classes[class] ~= nil,
      "trainer class live: " .. class)
  end

  -- ------- the simulation moves the world

  local before = roster[1].party[1].level
  for _ = 1, 20 do rivals.debug.tick() end
  local after = rivals.roster()[1].party[1].level
  check(after >= before, "twenty ticks never cost a rival levels ("
    .. before .. " -> " .. after .. ")")

  if arcade then
    local score, holder = arcade.highScore("ekans")
    check(score > 0, "the arcade rat posted an EKANS score (" .. score .. ")")
    check(holder == "SPARKS", "and holds the board (" .. tostring(holder)
      .. ")")
  end

  -- ------- an appearance, walked to and talked to

  local placed = rivals.roster()
  local target
  for _, entry in ipairs(placed) do
    local venue = core.venues.get(entry.location)
    if venue and game.data.gen2Maps[venue.map] then
      target = { entry = entry, venue = venue }
      break
    end
  end
  check(target ~= nil, "at least one rival is somewhere reachable")

  if target then
    local venue = target.venue
    -- stand one cell south of the venue spot and face it
    for _ = 1, 8 do
      local ok, err = rivals.debug.warp(venue.map, venue.x, venue.y + 1, "up")
      if not ok then
        U.log(("warpTo %s (%d,%d) refused: %s"):format(venue.map, venue.x,
          venue.y + 1, tostring(err)))
      end
      local settled = false
      for _ = 1, 90 do
        U.wait(1)
        local p = world.player
        if p and world.map and world.map.id == venue.map and not p.moving then
          settled = true
          break
        end
      end
      if settled then break end
    end
    check(world.map and world.map.id == venue.map,
      "reached " .. target.entry.name .. "'s map (" .. venue.map .. ")")

    rivals.debug.refresh()
    U.wait(20)

    -- The world turns while you travel -- leaving a map ticks the
    -- simulation -- so who is HERE is read after arriving, never from
    -- the roster captured before the walk.  The invariant that matters
    -- is that everyone the simulation says is here is standing here.
    local hereMap = world.map and world.map.id
    local expected = {}
    for _, entry in ipairs(rivals.roster()) do
      local venue = core.venues.get(entry.location)
      if venue and venue.map == hereMap then expected[#expected + 1] = entry end
    end

    local found = 0
    for _, npc in ipairs(world.npcs or {}) do
      if npc.def and npc.def.runtime and type(npc.def.scriptKey) == "table"
          and npc.def.scriptKey[1]
          and npc.def.scriptKey[1][1] == "showa_rivals:talk" then
        found = found + 1
      end
    end
    check(found == #expected,
      ("everyone the simulation places here is standing here (%d of %d; %s)")
        :format(found, #expected, tostring(rivals.debug.spawnNote())))

    if found > 0 then
      U.tap(game, "a")
      U.wait(30)
      -- a generous budget: real dialogue types out a character at a time,
      -- so this needs far longer than it did when every line printed as
      -- the three-dot fallback
      for _ = 1, 120 do
        if not (world.vm and world.vm.busy) then break end
        U.tap(game, "a")
        U.wait(6)
      end
      check(not (world.vm and world.vm.busy), "the conversation finished")
    end
  end

  -- ------- the derby competitor seam

  if contests then
    contests.debug.start()
    contests.debug.catch({ species = "MAGIKARP", level = 5,
      dvs = { attack = 0, defense = 0, speed = 0, special = 0 } })
    local standings = contests.debug.finish()
    local sawRival = false
    for _, row in ipairs(standings) do
      if row.name == "NAGISA" then sawRival = true end
    end
    check(sawRival, "the fishing prodigy entered the derby against you")
  end

  U.log("DRIVER FAILURES:", failures)
end
