-- showa_arcade + showa_core under the headless gen-2 loader: dependency
-- resolution, registrations, and the export seam.
--
--   luajit mods/showa_arcade/tests/arcade_headless_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function goldData()
  local data = T.fixtures.fresh()
  data.gen2Maps = data.maps
  data.gen2Tilesets = data.tilesets
  data.gen2Pokemon = data.pokemon
  data.gen2Sprites = data.sprites
  data.gen2Trainers = { classes = {} }
  return data
end

local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_arcade" }, {
  data = goldData(), generation = 2 })

T.eq(#run.errors, 0, "both mods load with no boot errors")
T.eq(run.mods.showa_core and run.mods.showa_core.state, "loaded",
  "showa_core loaded")
T.eq(run.mods.showa_arcade and run.mods.showa_arcade.state, "loaded",
  "showa_arcade loaded (dependency satisfied)")

local core = run.loader.exports.showa_core
local arcade = run.loader.exports.showa_arcade

T.check(core.wallet.defined("ARCADE_TOKEN"),
  "the arcade defined its currency in the core wallet")
T.eq(#core.venues.all(), 1, "the arcade registered its venue")
T.eq(core.venues.get("GOLDENROD_ARCADE").map, "GOLDENROD_GAME_CORNER",
  "at the Game Corner")

T.eq(arcade.highScore("ekans"), 0, "the ledger starts empty")
T.eq(arcade.submitScore("ekans", 120, "PICHU KID"), true,
  "a first score is a record")
local best, by = arcade.highScore("ekans")
T.eq(best, 120, "and is readable back")
T.eq(by, "PICHU KID", "with its holder")
T.eq(arcade.submitScore("ekans", 60), false, "a lower score is not")
T.eq(core.news.recent(1)[1].text:find("PICHU KID") ~= nil, true,
  "the record hit the news feed")

run.release()

T.finish("showa_arcade headless")
