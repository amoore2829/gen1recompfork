-- Driver: the Seaking Derby on a real Gold boot.  Warps to the Lake of
-- Rage south shore, talks to the judge to open a sitting, lands a
-- (forced) Seaking, and talks again for the standings.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=derby_driver POKEPORT_NO_DISCORD=1 \
--     POKEPORT_DRIVER=mods/showa_contests/tests/derby_driver.lua love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local failures = 0
  local function check(cond, msg)
    U.log(cond and "ok  " or "FAIL", msg)
    if not cond then failures = failures + 1 end
  end

  U.wait(30)

  local core = game.mods and game.mods.exports and game.mods.exports.showa_core
  local contests = game.mods and game.mods.exports
    and game.mods.exports.showa_contests
  check(core ~= nil, "showa_core loaded")
  check(contests ~= nil, "showa_contests loaded")
  if not (core and contests) then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end

  local world = game.world
  local recordsBefore = contests.records().fish

  contests.debug.warp()
  U.wait(30)
  check(world.map and world.map.id == "LAKE_OF_RAGE",
    "warped to the Lake of Rage")

  local judge = world:npcAt(18, 29)
  check(judge ~= nil and judge.def and judge.def.runtime,
    "the derby judge spawned on the south shore")

  local function closeDialogs()
    for _ = 1, 60 do
      if not (world.vm and world.vm.busy) then return true end
      U.tap(game, "a")
      U.wait(4)
    end
    return not (world.vm and world.vm.busy)
  end

  local function settleAt(x, y, facing)
    for _ = 1, 8 do
      contests.debug.warp(x, y, facing)
      for _ = 1, 90 do
        U.wait(1)
        local p = world.player
        if p and p.cellX == x and p.cellY == y and not p.moving then
          return true
        end
      end
    end
    return false
  end

  -- ------- open the sitting

  check(settleAt(18, 30, "up"), "player settled facing the judge")
  U.wait(10)
  U.tap(game, "a")
  U.wait(30)
  check(contests.isSessionActive(), "talking to the judge opened a derby")
  closeDialogs()

  -- ------- land a fish (the catch event is what the mod measures)

  contests.debug.catch({ species = "SEAKING", level = 35,
    dvs = { attack = 15, defense = 15, speed = 15, special = 15 } })
  U.wait(5)

  -- ------- report back

  check(settleAt(18, 30, "up"), "player back at the judge")
  U.wait(10)
  U.tap(game, "a")
  U.wait(30)
  check(not contests.isSessionActive(), "reporting back closed the derby")
  closeDialogs()

  local record = contests.records().fish
  check(record ~= nil, "a fish record exists after the derby")
  if record then
    check(record.species == "SEAKING", "and it is the SEAKING that won ("
      .. tostring(record.species) .. ")")
    if recordsBefore then
      check(record.size >= recordsBefore.size,
        "the record never shrinks across runs")
    end
  end

  local news = core.news.recent(3)
  local sawDerby = false
  for _, entry in ipairs(news) do
    if entry.text:find("DERBY") then sawDerby = true end
  end
  check(sawDerby, "the derby result reached the town news feed")

  U.log("DRIVER FAILURES:", failures)
end
