-- Driver: the probe on a real Gold boot.  Asserts the mod loaded, its
-- registrations landed in the live dataset, then spawns the probe NPC in
-- front of the player and talks to it, which proves the whole mod-NPC
-- dialogue chain on Gen 2: spawnNpc -> interact -> Vm:start(row list) ->
-- the probe's own verb -> ctx.vm:showText.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=probe_driver POKEPORT_NO_DISCORD=1 \
--     POKEPORT_DRIVER=mods/gen2_api_probe/tests/gold_boot_driver.lua love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local failures = 0
  local function check(cond, msg)
    U.log(cond and "ok  " or "FAIL", msg)
    if not cond then failures = failures + 1 end
  end

  U.wait(30)

  local exports = game.mods and game.mods.exports
    and game.mods.exports.gen2_api_probe
  check(exports ~= nil, "probe mod loaded and published exports")
  if not exports then
    U.log("driver aborted: probe not loaded")
    U.log("DRIVER FAILURES:", 1)
    return
  end

  check(game.data.gen2Maps and game.data.gen2Maps.SHOWA_PROBE_ROOM ~= nil,
    "SHOWA_PROBE_ROOM registered into the live gen2Maps")
  check(game.data.gen2Trainers and game.data.gen2Trainers.classes
    and game.data.gen2Trainers.classes.SHOWA_PROBE ~= nil,
    "SHOWA_PROBE trainer class registered")

  local world = game.world
  check(world ~= nil and world.player ~= nil, "the overworld is live")

  local rep = exports.report()
  check(rep.checks.save_roundtrip, "mod.save roundtripped on this boot")
  check(rep.events["game.ready"] > 0, "game.ready fired")
  check(rep.events["map.entered"] > 0, "map.entered fired")

  -- walk one step so world.stepped has a count, then release the pad and
  -- let the player settle -- U.hold leaves the button latched, and a still-
  -- walking player makes every position read below racy
  U.hold(game, "down", 20)
  for _, btn in ipairs({ "up", "down", "left", "right" }) do
    game.input.state[btn] = false
  end
  for _ = 1, 60 do
    if world.player and not world.player.moving then break end
    U.wait(1)
  end
  U.wait(10)
  rep = exports.report()
  check(rep.events["world.stepped"] > 0, "world.stepped fired on a walk")
  check(rep.hooks["input.step"] > 0, "input.step hook wraps the pad")

  -- ------- the spawned NPC, talked to

  local p = world.player
  local DELTA = { up = { 0, -1 }, down = { 0, 1 },
                  left = { -1, 0 }, right = { 1, 0 } }
  local d = DELTA[p.facing] or DELTA.down
  local mapId = world.map and world.map.id
  check(type(mapId) == "string", "current map id readable")

  local sx, sy = p.cellX + d[1], p.cellY + d[2]
  local npcId, err = exports.spawnProbeNpc(mapId, sx, sy)
  check(npcId ~= nil, "spawnNpc returned an id (" .. tostring(err) .. ")")
  U.wait(10)
  check(world.npcPool and world.npcPool[npcId] ~= nil,
    "the spawned NPC is live in the pool")

  U.log(("player at %s,%s facing %s; spawned at %s,%s"):format(
    p.cellX, p.cellY, p.facing, sx, sy))
  for _, npc in ipairs(world.npcs or {}) do
    U.log(("  npc %s cell=%s,%s def=%s,%s sprite=%s runtime=%s"):format(
      tostring(npc.def and npc.def.index), tostring(npc.cellX),
      tostring(npc.cellY), tostring(npc.def and npc.def.x),
      tostring(npc.def and npc.def.y), tostring(npc.def and npc.def.sprite),
      tostring(npc.def and npc.def.runtime)))
  end

  U.tap(game, "a")
  U.wait(30)
  -- close whatever text box the verb opened
  for _ = 1, 10 do U.tap(game, "a"); U.wait(5) end

  rep = exports.report()
  check(rep.checks.command_ran == true,
    "talking to the spawned NPC ran the probe's own verb through the VM"
    .. " (last interact kind: " .. tostring(rep.checks.last_interact) .. ")")
  check(rep.events["world.interacted"] > 0, "world.interacted fired")

  U.log("event counts after the run:")
  for name, count in pairs(rep.events) do U.log("  event", name, count) end
  for name, count in pairs(rep.hooks) do U.log("  hook ", name, count) end

  U.log("DRIVER FAILURES:", failures)
end
