-- The probe under the headless harness, generation 2: loads, registers into
-- the Gen 2 targets, and publishes its report.  ROM-free -- the fixture
-- dataset stands in for the Gold cache the way tests/engine/
-- gen2_content_registries.lua does it.
--
--   luajit mods/gen2_api_probe/tests/probe_headless_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function goldData()
  local data = T.fixtures.fresh()
  -- the fixture tables under the keys Gold routes to (Schemas.GEN2_TARGETS)
  data.gen2Maps = data.maps
  data.gen2Tilesets = data.tilesets
  data.gen2Pokemon = data.pokemon
  data.gen2Sprites = data.sprites
  data.gen2Trainers = { classes = {} }
  -- the probe prefers this id on a real cache; give the fixture one so the
  -- same branch is exercised here
  data.gen2Tilesets.TILESET_GAME_CORNER =
    data.gen2Tilesets.TILESET_GAME_CORNER or { id = "TILESET_GAME_CORNER" }
  return data
end

local run = T.sdk.loadMod("mods/gen2_api_probe", {
  data = goldData(), generation = 2 })

T.eq(run.mod and run.mod.state, "loaded",
  "probe loads on gen 2: " .. tostring(run.mod and run.mod.skipReason))
T.eq(#run.errors, 0, "and loads with no boot errors")

T.check(run.data.gen2Maps.SHOWA_PROBE_ROOM ~= nil,
  "maps:register landed in gen2Maps")
T.check(run.data.gen2Trainers.classes.SHOWA_PROBE ~= nil,
  "trainers:register landed in gen2Trainers.classes")

local exports = run.loader.exports.gen2_api_probe
T.check(type(exports) == "table" and type(exports.report) == "function",
  "the report export is published")

local rep = exports.report()
T.check(rep.checks.maps, "probe's own maps check passes")
T.check(rep.checks.trainers, "probe's own trainers check passes")
T.check(rep.checks.commands, "probe's own commands check passes")
T.check(rep.checks.screens, "probe's own screens check passes")
T.check(rep.checks.save_roundtrip, "mod.save roundtrips under the harness")

run.release()

T.finish("gen2_api_probe headless")
