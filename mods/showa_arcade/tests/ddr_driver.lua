-- Driver: the DITTO DITTO REVOLUTION cabinet on a real Gold boot.  Buys
-- tokens, starts a song, steps on the pad, and checks the board.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=ddr_driver POKEPORT_NO_DISCORD=1 --     POKEPORT_DRIVER=mods/showa_arcade/tests/ddr_driver.lua love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local DIR = os.getenv("SHOT_DIR") or "shots"
  local fails = 0
  local function check(c, m) U.log(c and "ok  " or "FAIL", m); if not c then fails = fails + 1 end end
  U.wait(30)
  local core = game.mods.exports.showa_core
  local arcade = game.mods.exports.showa_arcade
  game.save.player = game.save.player or {}
  game.save.player.money = 9000

  local function settle(x, y, f)
    for _ = 1, 8 do
      arcade.debugWarp(x, y, f)
      for _ = 1, 90 do
        U.wait(1)
        local p = game.world.player
        if p and p.cellX == x and p.cellY == y and not p.moving then return true end
      end
    end
    return false
  end
  local function clear()
    for _ = 1, 40 do
      if not (game.world.vm and game.world.vm.busy) then return end
      U.tap(game, "a"); U.wait(4)
    end
  end

  -- buy tokens
  check(settle(2, 11, "left"), "at the clerk")
  U.wait(10); U.tap(game, "a"); U.wait(30); clear()
  local tokens = core.wallet.get("ARCADE_TOKEN")
  check(tokens >= 10, "bought tokens (" .. tokens .. ")")

  -- the DDR cabinet
  check(settle(3, 5, "up"), "at the DDR cabinet")
  U.wait(10)
  U.tap(game, "a"); U.wait(40)
  check(core.wallet.get("ARCADE_TOKEN") == tokens - 1, "DDR took a token")
  U.shot(game, DIR .. "/20-ddr-start.png")
  -- play a bit: mash the pad so arrows get claimed
  for i = 1, 90 do
    U.tap(game, ({ "left", "down", "up", "right" })[(i % 4) + 1])
    U.wait(3)
  end
  U.shot(game, DIR .. "/21-ddr-playing.png")
  U.tap(game, "b"); U.wait(40)
  U.shot(game, DIR .. "/22-ddr-results.png")
  U.tap(game, "a"); U.wait(30)
  local best = arcade.highScore("ddr")
  check(best >= 0, "the DDR board exists (best " .. best .. ")")
  U.log("DDR DRIVER FAILURES:", fails)
end
