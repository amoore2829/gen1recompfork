-- showa_tournaments under the headless gen-2 loader, three ways: alone with
-- showa_core, with the rival cast, and with a cup played all the way to a
-- trophy.  What this suite is really for is the BATTLE SEAM -- the class the
-- referee's row list loads and the roster the engine would build from it --
-- because none of that is visible from the pure suite.
--
--   luajit mods/showa_tournaments/tests/tournaments_headless_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Cups = require("mods.showa_tournaments.cups.list")
local Draw = require("mods.showa_tournaments.bracket.draw")
local Field = require("mods.showa_tournaments.cups.field")

-- The fixture is Gen 1 shaped; the house field and the rival cast lead with
-- Gen 2 species a real Gold cache has and it does not.  Same move
-- tests/engine/gen2_content_registries.lua makes for its items.
local SPECIES = { "MACHOP", "GEODUDE", "JIGGLYPUFF", "CLEFAIRY", "GROWLITHE",
  "VULPIX", "GASTLY", "ZUBAT", "ODDISH", "BELLSPROUT", "PIDGEY", "SPEAROW",
  "PSYDUCK", "POLIWAG", "ONIX", "RHYHORN", "RATTATA", "TOGEPI", "PIKACHU",
  "MARILL", "CLEFFA", "IGGLYBUFF", "SMOOCHUM", "ELEKID", "MAGBY",
  "WOBBUFFET", "NATU", "SUDOWOODO", "MR__MIME", "CHANSEY", "SNORLAX",
  "MANTINE", "TYROGUE", "MISDREAVUS", "UNOWN", "HOOTHOOT", "DELIBIRD",
  "MAGNEMITE", "VOLTORB", "ELECTABUZZ", "PORYGON", "SLUGMA", "HOUNDOUR",
  "MAGMAR", "SUNKERN", "HOPPIP", "BAYLEEF", "AIPOM", "XATU", "MILTANK",
  "TEDDIURSA", "SWINUB", "MACHOKE", "HERACROSS", "REMORAID", "QWILFISH",
  "SEAKING", "GOLDEEN", "MAGIKARP", "HITMONLEE", "HITMONCHAN", "HITMONTOP" }

local function goldData()
  local data = T.fixtures.fresh()
  local index = 400
  for _, species in ipairs(SPECIES) do
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
  -- src/core/Game2.lua:963 aliases these to one table
  data.trainers = data.gen2Trainers
  data.gen2Tilesets.TILESET_MART =
    data.gen2Tilesets.TILESET_MART or { id = "TILESET_MART" }
  return data
end

-- A game the roster writer can reach.  mod.game resolves through
-- Loader:_game on every touch, which answers nil under Gen 2 headless, so a
-- stub set after the load is enough to drive the real write.
local function standUpGame(run, party, money, badges)
  run.loader.game = {
    data = run.data,
    save = {
      party = party or {},
      player = { money = money or 100000, badges = badges or 8 },
    },
  }
  return run.loader.game
end

-- ------- alone with showa_core

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_tournaments" },
    { data = goldData(), generation = 2 })

  T.eq(#run.errors, 0, "the mod loads alone with no boot errors")
  T.eq(run.mods.showa_tournaments and run.mods.showa_tournaments.state,
    "loaded", "showa_tournaments loaded without showa_rivals")

  local core = run.loader.exports.showa_core
  local cup = run.loader.exports.showa_tournaments

  T.eq(core.venues.get("CUP_GROUNDS").map, "NATIONAL_PARK",
    "the cup grounds registered on the park lawn")
  T.eq(#cup.cups(), 3, "three cups are on the circuit")
  T.eq(cup.current(), nil, "and no cup is running yet")

  -- the house class landed in the Gen 2 table, addressable by number
  local house = run.data.gen2Trainers.classes[Cups.HOUSE_CLASS]
  T.check(house ~= nil, "the house trainer class registered")
  T.check(type(house.index) == "number",
    "with a numeric index loadtrainer can name (" .. tostring(house.index) .. ")")
  T.check(house.index > 66, "clear of Gold's own 66 classes")
  T.eq(#house.trainers, 8, "and eight members, one per house entrant")
  -- The portrait is read out of the player's own cache table on game.ready
  -- (a path written into the mod would be shipping a reference to
  -- ROM-derived art), so it is absent until there is a game to read.
  T.eq(house.pic, nil, "and no hardcoded art path")
  run.loader.game = { data = run.data, save = {} }
  run.data.gen2MenuGfx = { battleHud = { trainerPics = {
    SCHOOLBOY = "art/schoolboy.png" } } }
  cup.debug.dress()
  T.check(type(house.pic) == "string" and house.pic ~= "",
    "but a portrait once there is, or the intro opens on an empty plinth")
  run.loader.game = nil
  for i, member in ipairs(house.trainers) do
    T.check(#member.party >= 1, "house member " .. i .. " brings a team")
    T.eq(member.name, Cups.HOUSE[i].name, "named " .. Cups.HOUSE[i].name)
  end

  -- the referee's row list is the shape the VM needs
  local rows = cup.debug.rows
  T.eq(rows[1][1], "showa_tournaments:call", "row 1 is this mod's own verb")
  T.eq(rows[2].op, "loadtrainer", "row 2 is a NATIVE loadtrainer row")
  T.eq(rows[3].op, "startbattle", "row 3 starts the battle")
  T.eq(rows[4][1], "showa_tournaments:result",
    "row 4 reads the result -- BEFORE the reload, which ends on a loss")
  T.eq(rows[5].op, "reloadmapafterbattle", "row 5 is the reload")
  for _, row in ipairs(rows) do
    -- a Gen 1 shaped row is normalised to a mod verb by its [1] being a
    -- string; a native row must therefore NOT carry one
    if row.op then
      T.eq(type(row[1]), "nil",
        row.op .. " carries no [1], or runList would read it as a verb")
    end
  end

  run.release()
end

-- ------- entering a cup with no rivals installed

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_tournaments" },
    { data = goldData(), generation = 2 })
  local cup = run.loader.exports.showa_tournaments
  local game = standUpGame(run, { { species = "PIKACHU", level = 12 } })

  local ok, why = cup.debug.enter("rookie")
  T.eq(ok, true, "the rookie cup takes an entry (" .. tostring(why) .. ")")
  T.eq(game.save.player.money, 100000 - Cups.get("rookie").fee,
    "and charges the fee")

  local live = cup.current()
  T.check(live ~= nil, "a cup is running")
  T.eq(live.cupId, "rookie", "the one that was entered")
  T.eq(live.round, 1, "at round one")
  T.eq(live.alive, true, "with the player still in it")
  T.eq(#live.standings, 8, "against a field of eight")

  T.eq(cup.debug.enter("open"), false, "you cannot enter two cups at once")

  -- arming a match writes the opponent into the loadtrainer row
  local armed = cup.debug.arm()
  T.check(armed ~= nil, "the referee can arm the first match")
  T.eq(cup.debug.rows[2].class, armed.class,
    "and the loadtrainer row names that opponent's class")
  T.eq(cup.debug.rows[2].member, armed.member, "and their member number")
  T.eq(armed.class, cup.debug.houseIndex(),
    "which with no rivals installed is the house class")

  -- the roster the engine would build the party from is at the cup's cap
  local member = run.data.gen2Trainers.classes[Cups.HOUSE_CLASS]
    .trainers[armed.member]
  T.check(#member.party >= 1, "the opponent has a roster to fight with")
  for _, mon in ipairs(member.party) do
    T.check(mon.level <= Cups.get("rookie").cap,
      ("the roster is at the rookie cap (Lv%d)"):format(mon.level))
    T.check(type(mon.species) == "string", "and every row names a species")
  end

  run.release()
end

-- ------- the gates at the desk

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_tournaments" },
    { data = goldData(), generation = 2 })
  local cup = run.loader.exports.showa_tournaments

  standUpGame(run, {}, 100000, 8)
  local ok, why = cup.debug.enter("rookie")
  T.eq(ok, false, "a trainer with no POKEMON is turned away")
  T.check(why:find("POKEMON"), "and told why (" .. tostring(why) .. ")")

  standUpGame(run, { { species = "PIKACHU", level = 40 } }, 100000, 8)
  ok, why = cup.debug.enter("rookie")
  T.eq(ok, false, "an over-levelled party is turned away at the desk")
  T.check(why:find("over Lv15"), "naming the cap (" .. tostring(why) .. ")")

  standUpGame(run, { { species = "PIKACHU", level = 12 } }, 100000, 0)
  ok, why = cup.debug.enter("open")
  T.eq(ok, false, "the open cup wants badges")
  T.check(why:find("badges"), "and says so (" .. tostring(why) .. ")")

  standUpGame(run, { { species = "PIKACHU", level = 12 } }, 10, 8)
  ok, why = cup.debug.enter("rookie")
  T.eq(ok, false, "and it wants the fee")
  T.check(why:find("fee"), "and says so (" .. tostring(why) .. ")")

  T.eq(cup.debug.enter("nope"), false, "an unknown cup is refused")

  run.release()
end

-- ------- a cup played to the end, won

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_tournaments" },
    { data = goldData(), generation = 2 })
  local core = run.loader.exports.showa_core
  local cup = run.loader.exports.showa_tournaments
  local game = standUpGame(run, { { species = "PIKACHU", level = 15 } })

  T.eq(cup.debug.enter("rookie"), true, "entered")
  local spent = game.save.player.money

  local guard = 0
  while cup.current() and guard < 8 do
    cup.debug.play(true)
    guard = guard + 1
  end
  T.eq(cup.current(), nil, "a cup won to the end closes itself")
  T.eq(guard, 3, "in three matches")
  T.eq(game.save.player.money, spent + Cups.get("rookie").prize,
    "and pays the prize money")

  local records = cup.records()
  T.eq(records.rookie.entered, 1, "the record book counted the entry")
  T.eq(records.rookie.won, 1, "and the win")

  local news = core.news.recent(5)
  local sawResult = false
  for _, entry in ipairs(news) do
    if entry.text:find("ROOKIE CUP") then sawResult = true end
  end
  T.eq(sawResult, true, "and the cup reached the news feed")

  run.release()
end

-- ------- a cup the player goes out of early still plays itself out

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_tournaments" },
    { data = goldData(), generation = 2 })
  local cup = run.loader.exports.showa_tournaments
  local game = standUpGame(run, { { species = "PIKACHU", level = 15 } })

  T.eq(cup.debug.enter("rookie"), true, "entered")
  local before = game.save.player.money
  cup.debug.play(false)

  T.eq(cup.current(), nil,
    "losing the first match runs the rest of the cup out")
  T.eq(game.save.player.money, before, "and pays the loser nothing")
  T.eq(cup.records().rookie.entered, 1, "the entry is still counted")
  T.eq(cup.records().rookie.won, 0, "but not as a win")

  -- and the cup really was won by SOMEBODY
  local news = run.loader.exports.showa_core.news.recent(5)
  local named = false
  for _, entry in ipairs(news) do
    if entry.text:find("won the ROOKIE CUP") then named = true end
  end
  T.eq(named, true, "somebody else lifted the trophy, and the news said who")

  run.release()
end

-- ------- with the rival cast

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_rivals",
    "mods/showa_tournaments" }, { data = goldData(), generation = 2 })

  T.eq(#run.errors, 0, "core + rivals + tournaments load clean")
  local cup = run.loader.exports.showa_tournaments
  local rivals = run.loader.exports.showa_rivals
  standUpGame(run, { { species = "PIKACHU", level = 14 } })

  T.eq(cup.debug.enter("rookie"), true, "entered a cup with the cast present")
  local live = cup.current()
  local rivalSlots = 0
  for _, row in ipairs(live.standings) do
    if row.id:find("^rival:") then rivalSlots = rivalSlots + 1 end
  end
  T.check(rivalSlots > 0,
    "rivals really turn up to the cup (" .. rivalSlots .. ")")

  -- arm every match in the cup and check the opponent is fightable
  local armedRival = false
  local guard = 0
  while cup.current() and guard < 8 do
    local armed = cup.debug.arm()
    if armed then
      T.check(type(armed.class) == "number",
        "the armed opponent has a class number")
      T.check(armed.member >= 1, "and a member number")
      local classId = rivals.battleCard(armed.rival or "") and
        rivals.battleCard(armed.rival).classId or Cups.HOUSE_CLASS
      local class = run.data.gen2Trainers.classes[classId]
      T.eq(class.index, armed.class, "which is the class actually registered")
      local roster = class.trainers[armed.member].party
      T.check(#roster >= 1, "and a roster to fight with")
      for _, mon in ipairs(roster) do
        T.check(mon.level <= Cups.get("rookie").cap,
          ("the opponent is inside the cap (Lv%d)"):format(mon.level))
      end
      if armed.rival then armedRival = true end
    end
    cup.debug.play(true)
    guard = guard + 1
  end
  T.eq(armedRival, true, "at least one match was against a real rival")

  -- and the rivals got their real teams back afterwards
  for _, entry in ipairs(rivals.roster()) do
    local card = rivals.battleCard(entry.id)
    local class = run.data.gen2Trainers.classes[card.classId]
    T.eq(class.trainers[1].party[1].level, card.party[1].level,
      entry.name .. " walked out of the cup with their real team")
  end

  run.release()
end

-- ------- withdrawing, and the desk's own bookkeeping

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_tournaments" },
    { data = goldData(), generation = 2 })
  local cup = run.loader.exports.showa_tournaments
  standUpGame(run, { { species = "PIKACHU", level = 15 } })

  T.eq(cup.debug.enter("rookie"), true, "entered")
  cup.debug.abandon()
  T.eq(cup.current(), nil, "withdrawing clears the cup")
  T.eq(cup.records().rookie, nil, "and does not count as an entry")
  T.eq(cup.debug.enter("open"), true, "so another cup can be entered after")

  T.eq(cup.debug.play(true) ~= nil, true, "and it plays")

  run.release()
end

-- ------- the mod survives a boot with no game at all

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_tournaments" },
    { data = goldData(), generation = 2 })
  local cup = run.loader.exports.showa_tournaments
  T.eq(#run.errors, 0, "no errors with no game standing")
  T.eq(cup.debug.enter("rookie"), false,
    "entering with no save is a refusal, not a crash")
  T.eq(cup.debug.arm(), nil, "and arming with no cup answers nil")
  T.eq(cup.debug.play(true), "no cup", "and playing says there is no cup")
  T.eq(cup.debug.spawned(), 0, "nothing spawned without an overworld")
  run.release()
end

T.finish("showa_tournaments headless")
