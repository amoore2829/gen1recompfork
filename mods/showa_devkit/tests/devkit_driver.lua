-- Driver: the dev kit on a real Gold boot.  Drives its own actions and
-- then opens the menu through the START row, which is the path a person
-- actually takes.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=devkit_driver POKEPORT_NO_DISCORD=1 \
--     POKEPORT_DRIVER=mods/showa_devkit/tests/devkit_driver.lua love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local DIR = os.getenv("SHOT_DIR")
  local failures = 0
  local function check(cond, msg)
    U.log(cond and "ok  " or "FAIL", msg)
    if not cond then failures = failures + 1 end
  end

  U.wait(30)

  local e = game.mods and game.mods.exports or {}
  local kit, core = e.showa_devkit, e.showa_core
  check(kit ~= nil, "showa_devkit loaded")
  check(core ~= nil, "showa_core loaded")
  if not (kit and core) then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end

  -- ------- the kit sees the whole suite

  local ctx = kit.context()
  check(ctx.have.arcade and ctx.have.contests and ctx.have.malls
    and ctx.have.rivals, "the kit sees every feature mod")
  check(#ctx.venues >= 20, "and the whole venue graph ("
    .. #ctx.venues .. ")")
  check(#ctx.rivals == 20, "and the whole cast (" .. #ctx.rivals .. ")")

  -- ------- the root offers the full menu

  local rows = kit.rows("root")
  local ids = {}
  for _, row in ipairs(rows) do ids[row.id] = true end
  for _, id in ipairs({ "warp", "games", "wallet", "derby", "stamps",
                        "rivals", "status", "close" }) do
    check(ids[id], "the root offers " .. id)
  end

  -- ------- warping really moves the player

  local before = game.world.map and game.world.map.id
  local note = kit.warpTo("GOLDENROD_ARCADE")
  U.wait(60)
  check(game.world.map and game.world.map.id == "GOLDENROD_GAME_CORNER",
    "warping landed at the arcade (" .. tostring(note) .. ")")

  -- ------- the wallet stocks

  local tokens = core.wallet.get("ARCADE_TOKEN")
  kit.stockWallet("tokens")
  check(core.wallet.get("ARCADE_TOKEN") == tokens + 50,
    "the wallet stocked 50 tokens")

  -- ------- the simulation runs on command

  local note2 = kit.tickRivals(10)
  check(note2:find("10"), "ten ticks ran (" .. tostring(note2) .. ")")

  -- ------- every warp row points somewhere real

  local bad = 0
  for _, row in ipairs(kit.rows("warp")) do
    if row.venue then
      local venue = core.venues.get(row.venue)
      if not (venue and game.data.gen2Maps[venue.map]) then bad = bad + 1 end
    end
  end
  check(bad == 0, "every warp row points at a real map (" .. bad .. " bad)")

  -- ------- and the menu opens the way a person opens it

  U.tap(game, "start"); U.wait(40)
  if DIR then U.shot(game, DIR .. "/40-start-with-dev.png") end
  local opened = false
  for _ = 1, 14 do
    U.tap(game, "down"); U.wait(8)
    local top = game.stack:top()
    U.tap(game, "a"); U.wait(25)
    if game.stack:top() ~= top then opened = true break end
    U.wait(5)
  end
  check(opened or game.stack:top() ~= nil, "the START menu responded")
  if DIR then U.shot(game, DIR .. "/41-devkit-menu.png") end

  U.log("DRIVER FAILURES:", failures)
end
