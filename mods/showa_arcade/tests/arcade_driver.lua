-- Driver: the arcade on a real Gold boot.  Warps to the Game Corner,
-- buys tokens from the clerk, plays (and quits) an EKANS run, and turns
-- the gatcha crank -- the whole token economy end to end.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=arcade_driver POKEPORT_NO_DISCORD=1 \
--     POKEPORT_DRIVER=mods/showa_arcade/tests/arcade_driver.lua love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local failures = 0
  local function check(cond, msg)
    U.log(cond and "ok  " or "FAIL", msg)
    if not cond then failures = failures + 1 end
  end

  U.wait(30)

  local core = game.mods and game.mods.exports and game.mods.exports.showa_core
  local arcade = game.mods and game.mods.exports
    and game.mods.exports.showa_arcade
  check(core ~= nil, "showa_core loaded")
  check(arcade ~= nil, "showa_arcade loaded")
  if not (core and arcade) then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end

  local world = game.world

  -- give the player shopping money and jump to the arcade floor
  game.save.player = game.save.player or {}
  game.save.player.money = 3000
  arcade.debugWarp()
  U.wait(30)
  check(world.map and world.map.id == "GOLDENROD_GAME_CORNER",
    "warped to the Game Corner")

  local runtime = 0
  for _, npc in ipairs(world.npcs or {}) do
    if npc.def and npc.def.runtime then runtime = runtime + 1 end
  end
  check(runtime == 3, "clerk, cabinet, and gatcha all spawned ("
    .. runtime .. ")")

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
      arcade.debugWarp(x, y, facing)
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

  local function talkAt(x, y, facing)
    check(closeDialogs(), "no dialog stuck before the talk at "
      .. x .. "," .. y)
    check(settleAt(x, y, facing), "player settled at " .. x .. "," .. y)
    U.wait(10)
    U.tap(game, "a")
    U.wait(30)
    closeDialogs()
  end

  -- ------- the clerk sells a pack

  local moneyBefore = game.save.player.money
  local tokens0 = core.wallet.get("ARCADE_TOKEN")
  local owned0, total0 = arcade.gatchaOwned(), 0
  for _, count in pairs(owned0) do total0 = total0 + count end
  talkAt(2, 11, "left")
  check(core.wallet.get("ARCADE_TOKEN") == tokens0 + 10,
    "the clerk sold 10 tokens (have "
    .. tostring(core.wallet.get("ARCADE_TOKEN")) .. ")")
  check(game.save.player.money == moneyBefore - 500,
    "and took $500 (money " .. tostring(game.save.player.money) .. ")")

  -- ------- the EKANS cabinet

  check(closeDialogs(), "no dialog stuck before the cabinet")
  check(settleAt(9, 5, "up"), "player settled at the cabinet")
  U.wait(10)
  U.wait(10)
  U.tap(game, "a")
  U.wait(30)
  check(core.wallet.get("ARCADE_TOKEN") == tokens0 + 9,
    "the cabinet took one token")
  -- quit the run (B = game over), wait out the results-card debounce
  -- (20 frames), close it with A, and DO NOT press A again while still
  -- facing the cabinet -- that is a second paid play
  U.tap(game, "b")
  U.wait(40)
  U.tap(game, "a")
  U.wait(30)
  check(game.stack:top() == nil, "the cabinet run closed")

  -- ------- the gatcha machine

  check(closeDialogs(), "no dialog stuck before the gatcha")
  check(settleAt(15, 5, "up"), "player settled at the gatcha")
  U.wait(10)
  U.tap(game, "a")
  U.wait(30)
  -- crank (40f) + drop (~16f) + reveal debounce (15f)
  U.wait(90)
  U.tap(game, "a")
  U.wait(30)
  check(game.stack:top() == nil, "the gatcha closed")
  check(core.wallet.get("ARCADE_TOKEN") == tokens0 + 6,
    "the gatcha took three tokens (have "
    .. tostring(core.wallet.get("ARCADE_TOKEN")) .. ")")
  local owned, total = arcade.gatchaOwned(), 0
  for _, count in pairs(owned) do total = total + count end
  check(total == total0 + 1, "and one prize entered the collection ("
    .. total .. " vs " .. total0 .. ")")

  U.log("DRIVER FAILURES:", failures)
end
