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
  -- src/core/Game2.lua:963 aliases these to one table, and the roster
  -- writer follows data.trainers; a fixture that only sets one of them
  -- would let a broken write pass.
  data.trainers = data.gen2Trainers
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

  -- ------- the battle seam
  --
  -- A class without a numeric index is unreachable from `loadtrainer`, and a
  -- roster the engine never sees is a rival who fights with their starter.
  -- Both were true before tournaments needed a real battle, and neither is
  -- visible from anywhere else, so they are asserted here.

  local seenIndex = {}
  for id, class in pairs(run.data.gen2Trainers.classes) do
    T.check(type(class.index) == "number",
      id .. " carries a numeric class index")
    T.check(class.index > 66, id .. " does not shadow one of Gold's own")
    T.eq(seenIndex[class.index], nil,
      "no two rival classes share index " .. tostring(class.index))
    seenIndex[class.index] = id
    T.check(#class.trainers >= 1, id .. " fields a trainer")
    -- no pic yet: the portrait is read out of the player's cache table on
    -- game.ready, and this load has no game
    T.eq(class.pic, nil, id .. " carries no hardcoded art path")
  end

  local card = rivals.battleCard("pichu")
  T.check(card ~= nil, "a rival hands out a battle card")
  T.eq(card.classId, "SHOWA_PICHU_KID", "naming the class to load")
  T.eq(card.index, run.data.gen2Trainers.classes.SHOWA_PICHU_KID.index,
    "and the number to load it by")
  T.eq(rivals.battleCard("nobody"), nil, "an unknown rival has no card")

  -- The roster writer reads mod.game.data, and a headless load has no game
  -- (Loader:_game answers nil under Gen 2 when nothing injected one).  It is
  -- resolved on every touch, so standing a stub up here is enough to drive
  -- the real write rather than assert around it.
  run.loader.game = { data = run.data, save = { party = {} } }

  -- the portrait table a real Gold cache carries
  run.data.gen2MenuGfx = { battleHud = { trainerPics = {
    SCHOOLBOY = "art/schoolboy.png",
    LASS = "art/lass.png" } } }
  rivals.debug.dress()
  for id, class in pairs(run.data.gen2Trainers.classes) do
    T.check(type(class.pic) == "string" and class.pic ~= "",
      id .. " took a portrait from the player's own art table")
  end

  local function classParty(classId)
    return run.data.gen2Trainers.classes[classId].trainers[1].party
  end

  -- grow the rival past their starter so a stale roster would show
  local live = rivals.battleCard("pichu")
  for _ = 1, 12 do rivals.debug.tick() end
  local grown = rivals.battleCard("pichu")
  T.check(grown.level >= live.level, "ticking does not un-train a rival")

  T.eq(classParty("SHOWA_PICHU_KID")[1].species, grown.party[1].species,
    "the class roster is the rival's LIVE team, not their starter")
  T.eq(classParty("SHOWA_PICHU_KID")[1].level, grown.party[1].level,
    "at the level the news has been reporting")
  T.eq(#classParty("SHOWA_PICHU_KID"), math.min(6, #grown.party),
    "and their whole bench comes with them")

  -- and a cup can stand that team up under a cap, then put it back
  rivals.syncParty("pichu", { cap = 5 })
  T.eq(classParty("SHOWA_PICHU_KID")[1].level, 5, "a cap caps the roster")
  rivals.syncParty("pichu")
  T.eq(classParty("SHOWA_PICHU_KID")[1].level, grown.party[1].level,
    "and syncing again puts the real team back")
  T.eq(rivals.syncParty("nobody"), false,
    "syncing a rival who is not there is a refusal, not a crash")

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
