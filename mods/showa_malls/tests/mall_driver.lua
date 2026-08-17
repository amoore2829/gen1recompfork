-- Driver: the arcade on a real Gold boot.  This is the first Showa mod
-- that REGISTERS maps rather than spawning into vanilla ones, so the
-- driver's job is to prove the rooms actually load, the staircases round
-- trip, and the rally records a sticker.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=mall_driver POKEPORT_NO_DISCORD=1 \
--     POKEPORT_DRIVER=mods/showa_malls/tests/mall_driver.lua love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local failures = 0
  local function check(cond, msg)
    U.log(cond and "ok  " or "FAIL", msg)
    if not cond then failures = failures + 1 end
  end

  U.wait(30)

  local core = game.mods and game.mods.exports and game.mods.exports.showa_core
  local malls = game.mods and game.mods.exports
    and game.mods.exports.showa_malls
  check(core ~= nil, "showa_core loaded")
  check(malls ~= nil, "showa_malls loaded")
  if not (core and malls) then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end

  local world = game.world
  local ids = malls.debug.maps
  local before = malls.stickerCount()

  for _, id in pairs(ids) do
    check(game.data.gen2Maps[id] ~= nil, "map registered live: " .. id)
  end

  local function closeDialogs()
    for _ = 1, 60 do
      if not (world.vm and world.vm.busy) then return true end
      U.tap(game, "a")
      U.wait(4)
    end
    return not (world.vm and world.vm.busy)
  end

  local function settleAt(mapId, x, y, facing)
    for _ = 1, 8 do
      malls.debug.warp(mapId, x, y, facing)
      for _ = 1, 90 do
        U.wait(1)
        local p = world.player
        if p and world.map and world.map.id == mapId
            and p.cellX == x and p.cellY == y and not p.moving then
          return true
        end
      end
    end
    return false
  end

  -- ------- the rooms load at all

  check(settleAt(ids.oneF, 3, 6, "up"), "the ground floor loads and stands")
  check(world.map and world.map.def and #world.map.def.blocks == 24,
    "with the template's 6x4 block layout")

  check(settleAt(ids.twoF, 5, 3, "up"), "the upper floor loads")
  check(settleAt(ids.tunnel, 5, 3, "up"), "the chikagai passage loads")

  -- ------- a counter grants a sticker

  check(settleAt(ids.oneF, 5, 3, "up"), "player settled at the toy counter")
  local clerk = world:npcAt(5, 2)
  check(clerk ~= nil and clerk.def and clerk.def.runtime,
    "the toy-floor clerk spawned")
  U.wait(10)
  U.tap(game, "a")
  U.wait(30)
  closeDialogs()
  check(malls.stickerCount() == before + 1,
    "talking to the counter granted a sticker (" ..
    malls.stickerCount() .. " vs " .. before .. ")")
  check(malls.hasSticker("TOYS"), "and it is the toy-floor one")

  -- talking again must not double-stamp
  local afterFirst = malls.stickerCount()
  U.tap(game, "a")
  U.wait(30)
  closeDialogs()
  check(malls.stickerCount() == afterFirst, "a second visit does not restamp")

  -- ------- the staircase round trips

  check(settleAt(ids.oneF, 10, 3, "up"), "player below the up staircase")
  U.hold(game, "up", 24)
  for _, btn in ipairs({ "up", "down", "left", "right" }) do
    game.input.state[btn] = false
  end
  for _ = 1, 120 do
    U.wait(1)
    if world.map and world.map.id == ids.twoF then break end
  end
  check(world.map and world.map.id == ids.twoF,
    "walking into the staircase reached 2F (on " ..
    tostring(world.map and world.map.id) .. ")")

  U.log("DRIVER FAILURES:", failures)
end
