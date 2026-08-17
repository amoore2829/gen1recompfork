-- showa_rivals under the headless gen-2 loader, twice: once with the
-- whole suite present, and once ALONE -- the optional dependencies are
-- only worth declaring if the mod really does stand up without them.
--
--   luajit mods/showa_rivals/tests/rivals_headless_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

-- The ROM-free fixture carries a handful of Gen 1 species; the rivals
-- lead with Gen 2 ones a real Gold cache has and it does not.  Seeding
-- them is the same move tests/engine/gen2_content_registries.lua makes
-- for the items its registries reference.
local STARTERS = { "TOGEPI", "PIKACHU", "MARILL", "CLEFFA", "IGGLYBUFF",
  "SMOOCHUM", "ELEKID", "MAGBY", "WOBBUFFET", "BELLSPROUT", "NATU",
  "SUDOWOODO", "MR__MIME", "CHANSEY", "SNORLAX", "MACHOP", "MANTINE",
  "TYROGUE", "MISDREAVUS", "UNOWN", "HOOTHOOT", "JIGGLYPUFF", "CLEFAIRY",
  "DELIBIRD", "MAGNEMITE", "VOLTORB", "ELECTABUZZ", "PORYGON", "SLUGMA",
  "GROWLITHE", "HOUNDOUR", "MAGMAR", "SUNKERN", "HOPPIP", "ODDISH",
  "BAYLEEF", "AIPOM", "XATU", "MILTANK", "TEDDIURSA", "SWINUB", "MACHOKE",
  "HERACROSS", "REMORAID", "QWILFISH", "POLIWAG", "SEAKING", "GOLDEEN",
  "MAGIKARP", "NATU", "HITMONLEE", "HITMONCHAN", "HITMONTOP", "VOLTORB" }

local function goldData()
  local data = T.fixtures.fresh()
  local index = 400
  for _, species in ipairs(STARTERS) do
    if not data.pokemon[species] then
      index = index + 1
      data.pokemon[species] = { id = species, name = species, dex = index }
    end
  end
  data.gen2Maps = data.maps
  data.gen2Tilesets = data.tilesets
  data.gen2Pokemon = data.pokemon
  data.gen2Sprites = data.sprites
  data.gen2Trainers = { classes = {} }
  data.gen2Tilesets.TILESET_MART =
    data.gen2Tilesets.TILESET_MART or { id = "TILESET_MART" }
  return data
end

-- ------- the whole suite together

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_arcade",
    "mods/showa_contests", "mods/showa_malls", "mods/showa_rivals" },
    { data = goldData(), generation = 2 })

  T.eq(#run.errors, 0, "the whole suite loads with no boot errors")
  for _, id in ipairs({ "showa_core", "showa_arcade", "showa_contests",
                        "showa_malls", "showa_rivals" }) do
    T.eq(run.mods[id] and run.mods[id].state, "loaded", id .. " loaded")
  end

  local core = run.loader.exports.showa_core
  local rivals = run.loader.exports.showa_rivals
  local arcade = run.loader.exports.showa_arcade

  local roster = rivals.roster()
  T.eq(#roster, 20, "the whole cast ships (" .. #roster .. ")")
  for _, entry in ipairs(roster) do
    T.check(core.venues.get(entry.location) ~= nil,
      entry.name .. " starts at a registered venue")
    T.check(#entry.party >= 1, entry.name .. " has a team")
  end

  -- the trainer classes really landed in the Gen 2 table
  local classes = 0
  for _ in pairs(run.data.gen2Trainers.classes) do classes = classes + 1 end
  T.eq(classes, 20, "one trainer class per rival (" .. classes .. ")")
  for _, class in ipairs({ "SHOWA_ELM", "SHOWA_PICHU_KID",
                           "SHOWA_AZURILL_KID", "SHOWA_CLEFFA_KID",
                           "SHOWA_TYROGUE_TOP", "SHOWA_MUNCHLAX_KID" }) do
    T.check(run.data.gen2Trainers.classes[class] ~= nil,
      "trainer class registered: " .. class)
  end

  -- ticking moves the world: the arcade rat posts a score
  rivals.debug.tick()
  T.check(arcade.highScore("ekans") > 0,
    "the arcade rat posted a score to the cabinet")
  local _, holder = arcade.highScore("ekans")
  T.eq(holder, "SPARKS", "and the board names him")

  -- re-read: the tick above moved them, so the roster captured earlier
  -- is a snapshot of where they WERE
  local moved = rivals.roster()
  T.check(#rivals.at(moved[1].location) >= 1,
    "at() finds who is standing at a venue")

  rivals.recordBattle("elm", true)
  T.eq(#rivals.roster(), 20, "recording a battle keeps the roster whole")

  run.release()
end

-- ------- alone, with none of the optional dependencies

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_rivals" },
    { data = goldData(), generation = 2 })

  T.eq(#run.errors, 0, "rivals load alone with no boot errors")
  T.eq(run.mods.showa_rivals and run.mods.showa_rivals.state, "loaded",
    "showa_rivals loaded without arcade, contests or malls")

  local rivals = run.loader.exports.showa_rivals
  T.eq(#rivals.roster(), 20, "the whole roster is still there")
  for _, entry in ipairs(rivals.roster()) do
    T.check(entry.location ~= nil,
      entry.name .. " was re-homed to a venue that exists")
  end
  -- and a tick must not reach for the missing mods
  rivals.debug.tick()
  T.eq(#rivals.roster(), 20, "a tick with no feature mods is harmless")

  run.release()
end

T.finish("showa_rivals headless")
