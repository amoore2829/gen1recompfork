-- showa_core under the headless loader, generation 2: loads clean and
-- publishes the whole export surface.
--
--   luajit mods/showa_core/tests/core_headless_test.lua
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

local run = T.sdk.loadMod("mods/showa_core", {
  data = goldData(), generation = 2 })

T.eq(run.mod and run.mod.state, "loaded",
  "showa_core loads on gen 2: " .. tostring(run.mod and run.mod.skipReason))
T.eq(#run.errors, 0, "and loads with no boot errors")

local exports = run.loader.exports.showa_core
T.check(type(exports) == "table", "exports published")
for _, name in ipairs({ "wallet", "clock", "scheduler", "news", "venues",
                        "minigame" }) do
  T.check(type(exports[name]) == "table", "exports." .. name .. " present")
end

-- the bound wallet persists through mod.save
exports.wallet.define("ARCADE_TOKEN", "GAME TOKEN")
exports.wallet.add("ARCADE_TOKEN", 7)
T.eq(exports.wallet.get("ARCADE_TOKEN"), 7, "bound wallet credits")
local ok = exports.wallet.spend("ARCADE_TOKEN", 9)
T.eq(ok, false, "bound wallet refuses overdraft")

-- venues + news roundtrip through the bound API
exports.venues.register("GOLDENROD_ARCADE", { map = "GOLDENROD_GAME_CORNER" })
T.eq(#exports.venues.all(), 1, "venue registration lands")
exports.news.post("The arcade opened its doors!")
T.eq(exports.news.recent(1)[1].text, "The arcade opened its doors!",
  "news roundtrips")

run.release()

T.finish("showa_core headless")
