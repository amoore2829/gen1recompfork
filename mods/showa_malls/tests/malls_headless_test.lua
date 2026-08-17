-- showa_malls under the headless gen-2 loader: the maps really land in
-- the Gen 2 map table, and the sticker seam works.
--
--   luajit mods/showa_malls/tests/malls_headless_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function goldData()
  local data = T.fixtures.fresh()
  data.gen2Maps = data.maps
  data.gen2Tilesets = data.tilesets
  data.gen2Pokemon = data.pokemon
  data.gen2Sprites = data.sprites
  data.gen2Trainers = { classes = {} }
  data.gen2Tilesets.TILESET_MART =
    data.gen2Tilesets.TILESET_MART or { id = "TILESET_MART" }
  return data
end

local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_malls" }, {
  data = goldData(), generation = 2 })

T.eq(#run.errors, 0, "both mods load with no boot errors")
T.eq(run.mods.showa_malls and run.mods.showa_malls.state, "loaded",
  "showa_malls loaded")

local core = run.loader.exports.showa_core
local malls = run.loader.exports.showa_malls

for _, id in ipairs({ "SHOWA_MALL_1F", "SHOWA_MALL_2F",
                      "SHOWA_MALL_TUNNEL" }) do
  T.check(run.data.gen2Maps[id] ~= nil, "registered into gen2Maps: " .. id)
end

T.eq(core.venues.get("SHOWA_MALL").map, "SHOWA_MALL_1F",
  "the mall venue points at the ground floor")
T.eq(#core.venues.neighbors("SHOWA_MALL"), 1,
  "and connects to the passage")

T.eq(malls.stickerCount(), 0, "the stamp book starts empty")
T.eq(malls.hasSticker("TOYS"), false, "with no toy-floor sticker")
T.eq(#malls.album(), 4, "the album lists every counter regardless")

run.release()

T.finish("showa_malls headless")
