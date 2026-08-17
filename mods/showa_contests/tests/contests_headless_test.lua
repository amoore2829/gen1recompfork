-- showa_contests under the headless gen-2 loader: dependency resolution,
-- the venue, and the competitor/record seams other mods use.
--
--   luajit mods/showa_contests/tests/contests_headless_test.lua
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

local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_contests" }, {
  data = goldData(), generation = 2 })

T.eq(#run.errors, 0, "both mods load with no boot errors")
T.eq(run.mods.showa_contests and run.mods.showa_contests.state, "loaded",
  "showa_contests loaded")

local core = run.loader.exports.showa_core
local contests = run.loader.exports.showa_contests

T.eq(core.venues.get("LAKE_DERBY").map, "LAKE_OF_RAGE",
  "the derby venue registered at the lake")

-- a rival-style competitor, registered the way showa_rivals will
contests.registerCompetitor(function()
  return { name = "AZURILL KID", species = "SEAKING", size = 70 }
end)

T.eq(contests.isSessionActive(), false, "no derby before the judge opens one")
contests.debug.start()
T.eq(contests.isSessionActive(), true, "the judge opened a session")

contests.debug.catch({ species = "SEAKING", level = 30,
  dvs = { attack = 15, defense = 15, speed = 15, special = 15 } })
local standings = contests.debug.finish()
T.check(#standings >= 2, "the player and the competitor both placed")
T.eq(contests.isSessionActive(), false, "and the session closed")

local records = contests.records()
T.check(records.fish ~= nil, "a fish record was written")
T.check(records.fish.size > 0, "with a size")
T.check(core.news.recent(1)[1].text:find("DERBY") ~= nil,
  "the derby result reached the news feed")

-- a losing follow-up derby must not overwrite the record
local best = records.fish.size
contests.debug.start()
contests.debug.catch({ species = "MAGIKARP", level = 2,
  dvs = { attack = 0, defense = 0, speed = 0, special = 0 } })
contests.debug.finish()
T.eq(contests.records().fish.size, best, "a smaller fish keeps the record")

run.release()

T.finish("showa_contests headless")
