-- showa_parties under the headless gen-2 loader: the schedule against a live
-- venue graph, the guest trainer class, and the two swaps performed for real
-- against a save.
--
--   luajit mods/showa_parties/tests/parties_headless_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Schedule = require("mods.showa_parties.party.schedule")

local SPECIES = { "PIDGEY", "RATTATA", "SPEAROW", "ZUBAT", "ODDISH", "PARAS",
  "VENONAT", "DIGLETT", "MEOWTH", "PSYDUCK", "MANKEY", "GROWLITHE",
  "POLIWAG", "ABRA", "MACHOP", "BELLSPROUT", "TENTACOOL", "GEODUDE",
  "PONYTA", "SLOWPOKE", "MAGNEMITE", "GASTLY", "ONIX", "DROWZEE", "KRABBY",
  "VOLTORB", "EXEGGCUTE", "CUBONE", "KOFFING", "RHYHORN", "GOLDEEN",
  "STARYU", "MAGIKARP", "EEVEE", "HOOTHOOT", "LEDYBA", "SPINARAK",
  "CHINCHOU", "MAREEP", "MARILL", "HOPPIP", "SUNKERN", "WOOPER", "PINECO",
  "GLIGAR", "SNUBBULL", "TEDDIURSA", "SLUGMA", "SWINUB", "PHANPY",
  "STANTLER", "TOGEPI", "PIKACHU", "CLEFFA", "IGGLYBUFF", "SMOOCHUM",
  "ELEKID", "MAGBY", "WOBBUFFET", "NATU", "SUDOWOODO", "MR__MIME",
  "CHANSEY", "SNORLAX", "MANTINE", "TYROGUE", "MISDREAVUS", "UNOWN",
  "JIGGLYPUFF", "CLEFAIRY", "DELIBIRD", "ELECTABUZZ", "PORYGON",
  "HOUNDOUR", "MAGMAR", "BAYLEEF", "AIPOM", "XATU", "MILTANK", "MACHOKE",
  "HERACROSS", "REMORAID", "QWILFISH", "SEAKING", "HITMONLEE",
  "HITMONCHAN", "HITMONTOP", "VULPIX", "PIDGEOTTO" }

local function goldData()
  local data = T.fixtures.fresh()
  local index = 400
  for _, species in ipairs(SPECIES) do
    if not data.pokemon[species] then
      index = index + 1
      data.pokemon[species] = { id = species, name = species, dex = index,
        baseStats = { hp = 50, attack = 50, defense = 50, speed = 50,
                      special = 50, specialDefense = 50 } }
    end
  end
  data.gen2Maps = data.maps
  data.gen2Tilesets = data.tilesets
  data.gen2Pokemon = data.pokemon
  data.gen2Sprites = data.sprites
  data.gen2Trainers = { classes = {} }
  data.trainers = data.gen2Trainers
  data.gen2Tilesets.TILESET_MART =
    data.gen2Tilesets.TILESET_MART or { id = "TILESET_MART" }
  return data
end

local function standUpGame(run, save)
  run.loader.game = { data = run.data, save = save or {} }
  return run.loader.game
end

-- ------- alone with showa_core: no venues, so no parties

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_parties" },
    { data = goldData(), generation = 2 })

  T.eq(#run.errors, 0, "the mod loads alone with no boot errors")
  T.eq(run.mods.showa_parties and run.mods.showa_parties.state, "loaded",
    "showa_parties loaded with none of its optional dependencies")

  local parties = run.loader.exports.showa_parties
  -- showa_core registers no venues of its own, so nowhere is available
  T.eq(parties.today(), nil, "with nowhere to throw one, there is no party")
  T.eq(parties.next(), nil, "and no next one")
  T.eq(#parties.guests(), 0, "and nobody is standing anywhere")
  T.eq(parties.debug.spawned(), 0, "and nothing was spawned")

  -- the guest class still registered, addressable by number
  local class = run.data.gen2Trainers.classes.SHOWA_PARTY_GUEST
  T.check(class ~= nil, "the guest trainer class registered")
  T.check(type(class.index) == "number", "with a numeric class index")
  T.check(class.index >= 180, "inside this mod's own block (" .. class.index .. ")")
  T.check(#class.trainers >= 5, "and a member per guest slot")

  -- the battler row lists are the shape the VM needs
  for slot, rows in ipairs(parties.debug.rows) do
    T.eq(rows[1][1], "showa_parties:call", "slot " .. slot .. " calls first")
    T.eq(rows[2].op, "loadtrainer", "then loads the trainer")
    T.eq(rows[2].member, slot, "naming this guest's member number")
    T.eq(rows[3].op, "startbattle", "then battles")
    T.eq(rows[4][1], "showa_parties:result",
      "then records the result, BEFORE the reload")
    T.eq(rows[5].op, "reloadmapafterbattle", "which is last")
    for _, row in ipairs(rows) do
      if row.op then
        T.eq(type(row[1]), "nil",
          row.op .. " carries no [1], or runList reads it as a verb")
      end
    end
  end

  run.release()
end

-- ------- with venues in the graph, parties happen

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_rivals",
    "mods/showa_parties" }, { data = goldData(), generation = 2 })

  T.eq(#run.errors, 0, "core + rivals + parties load clean")
  local core = run.loader.exports.showa_core
  local parties = run.loader.exports.showa_parties

  -- showa_rivals registers ELM_LAB, which is on the party rotation
  T.check(core.venues.get("ELM_LAB") ~= nil, "a party venue is live")

  -- the clock starts at day 0, which is a party day
  local today = parties.today()
  T.check(today ~= nil, "there is a party on day zero")
  T.check(today.guests >= 3, "with guests (" .. today.guests .. ")")

  local guests = parties.guests()
  T.eq(#guests, today.guests, "the guest list matches the head count")
  local roles = {}
  for _, guest in ipairs(guests) do
    roles[guest.role] = (roles[guest.role] or 0) + 1
    T.check(guest.name ~= nil, "guest " .. guest.index .. " has a name")
  end
  for _, role in ipairs(Schedule.ROLE_ORDER) do
    T.check((roles[role] or 0) >= 1, "at least one " .. role .. " turned up")
  end

  -- re-reading does not reroll them
  local again = parties.guests()
  for i, guest in ipairs(guests) do
    T.eq(again[i].name, guest.name, "guest " .. i .. " is the same on re-read")
  end

  -- and the news announced one
  local sawNews = false
  for _, entry in ipairs(core.news.recent(10)) do
    if entry.text:find("PARTY") or entry.text:find("MEET") then
      sawNews = true
    end
  end
  T.eq(sawNews, true, "the next party reached the news feed")

  run.release()
end

-- ------- an item swap really moves items

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_rivals",
    "mods/showa_parties" }, { data = goldData(), generation = 2 })
  local parties = run.loader.exports.showa_parties

  local swapper
  for _, guest in ipairs(parties.guests()) do
    if guest.role == "swapper" then swapper = guest break end
  end
  T.check(swapper ~= nil, "a swapper is at the party")

  local save = { inventory = {}, party = {} }
  standUpGame(run, save)

  T.eq(parties.debug.swap(swapper.index), nil,
    "with an empty bag the swap does not happen")

  save.inventory[swapper.wants] = 2
  local swap = parties.debug.swap(swapper.index)
  T.check(swap ~= nil, "with the item in the bag it does")
  T.eq(swap.gave, swapper.wants, "what they wanted went")
  T.eq(swap.got, swapper.offers, "what they offered came")
  T.eq(save.inventory[swapper.wants], 1, "one left in the bag")
  T.eq(save.inventory[swapper.offers], 1, "and one gained")

  run.release()
end

-- ------- a Pokemon trade really moves a Pokemon

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_rivals",
    "mods/showa_parties" }, { data = goldData(), generation = 2 })
  local parties = run.loader.exports.showa_parties

  local trader
  for _, guest in ipairs(parties.guests()) do
    if guest.role == "trader" then trader = guest break end
  end
  T.check(trader ~= nil, "a trader is at the party")

  local save = { inventory = {}, party = {} }
  standUpGame(run, save)

  T.check(parties.debug.trade(trader.index):find("second") ~= nil,
    "your last POKEMON stays with you")

  -- a party with what they want, plus somebody to keep
  save.party = {
    { species = "PIDGEY", level = 10, dvs = {}, moves = {} },
    { species = trader.wantsMon, level = 22, dvs = {}, moves = {} },
  }
  local note = parties.debug.trade(trader.index)
  T.check(note:find(trader.offersMon) ~= nil,
    "the trade went through (" .. note .. ")")
  T.eq(#save.party, 2, "the party is still two strong")

  local received
  for _, mon in ipairs(save.party) do
    if mon.species == trader.offersMon then received = mon end
  end
  T.check(received ~= nil, "the traded-for mon is in the party")
  T.eq(received.level, 22, "at the level of the one handed over")
  T.eq(received.otName, trader.name or received.otName,
    "with the guest as its original trainer")
  T.check(received.maxHp and received.maxHp > 0,
    "and stats recomputed for the new species")

  local gone = false
  for _, mon in ipairs(save.party) do
    if mon.species == trader.wantsMon then gone = true end
  end
  T.eq(gone, false, "and the one they wanted really left")

  T.eq(save.pokedex.caught[trader.offersMon], true,
    "the received mon is ticked off in the #DEX")

  -- and the guest will not trade twice at the same party
  save.party[#save.party + 1] = { species = trader.wantsMon, level = 9,
                                  dvs = {}, moves = {} }
  local second = parties.debug.trade(trader.index)
  T.check(second == nil or not second:find("!"),
    "a guest already traded with does not trade again")

  run.release()
end

-- ------- a party a day off is a different party

do
  local run = T.sdk.loadMods({ "mods/showa_core", "mods/showa_rivals",
    "mods/showa_parties" }, { data = goldData(), generation = 2 })
  local parties = run.loader.exports.showa_parties

  local a = parties.debug.partyOn(0)
  local b = parties.debug.partyOn(Schedule.CYCLE)
  T.check(a ~= nil and b ~= nil, "both days have parties")
  T.check(a.venue ~= b.venue or a.theme.id ~= b.theme.id,
    "and the next one is somewhere else, or something else")
  T.eq(parties.debug.partyOn(1), nil, "a quiet day has none")

  local guestsA = parties.debug.guestsOn(0)
  local guestsB = parties.debug.guestsOn(Schedule.CYCLE)
  local same = 0
  for i, guest in ipairs(guestsA) do
    if guestsB[i] and guestsB[i].name == guest.name then same = same + 1 end
  end
  T.check(same < #guestsA, "and a different crowd turns up")

  run.release()
end

T.finish("showa_parties headless")
