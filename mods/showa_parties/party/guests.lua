-- Who turns up, and what they brought.
--
-- Drawn from the party's seed, so the guest list is a function of the day and
-- the room: walk out and back in and the same people are standing there with
-- the same things to swap.  Pure.
local Rng = require("mods.showa_parties.party.rng")

local Guests = {}

-- Showa-era given names, the sort of crowd a neighbourhood meet-up draws.
Guests.NAMES = {
  "KAZU", "MIKI", "TOORU", "SACHI", "JUNKO", "HIDEO", "REIKO", "TATSU",
  "AYUMI", "SHINJI", "NAOKO", "KENTA", "YUKI", "MASA", "CHIE", "GORO",
  "HARU", "SETSU", "TOMO", "RAN",
}

Guests.SPRITES = {
  "SPRITE_LASS", "SPRITE_GENTLEMAN", "SPRITE_POKEFAN_M", "SPRITE_TEACHER",
  "SPRITE_YOUNGSTER", "SPRITE_POKEFAN_F",
}

-- Items a guest may want or offer.  Common enough that a want is usually
-- satisfiable and an offer is usually worth having, and all of them exist in
-- Gold.
Guests.ITEMS = {
  "POTION", "SUPER_POTION", "ANTIDOTE", "PARLYZ_HEAL", "AWAKENING",
  "BURN_HEAL", "ICE_HEAL", "REVIVE", "GREAT_BALL", "ULTRA_BALL",
  "REPEL", "SUPER_REPEL", "ESCAPE_ROPE", "FULL_HEAL", "ELIXER",
  "HYPER_POTION", "MOOMOO_MILK", "BERRY", "GOLD_BERRY", "MYSTERYBERRY",
}

-- The trade pool: common Johto/Kanto species a guest could plausibly have
-- spare, and would plausibly want.
Guests.SPECIES = {
  "PIDGEY", "RATTATA", "SPEAROW", "ZUBAT", "ODDISH", "PARAS", "VENONAT",
  "DIGLETT", "MEOWTH", "PSYDUCK", "MANKEY", "GROWLITHE", "POLIWAG",
  "ABRA", "MACHOP", "BELLSPROUT", "TENTACOOL", "GEODUDE", "PONYTA",
  "SLOWPOKE", "MAGNEMITE", "GASTLY", "ONIX", "DROWZEE", "KRABBY",
  "VOLTORB", "EXEGGCUTE", "CUBONE", "KOFFING", "RHYHORN", "GOLDEEN",
  "STARYU", "MAGIKARP", "EEVEE", "HOOTHOOT", "LEDYBA", "SPINARAK",
  "CHINCHOU", "MAREEP", "MARILL", "HOPPIP", "SUNKERN", "WOOPER",
  "PINECO", "GLIGAR", "SNUBBULL", "TEDDIURSA", "SLUGMA", "SWINUB",
  "PHANPY", "STANTLER",
}

Guests.LINES = {
  battler = {
    "You look like you can battle!\nOne match, come on!",
    "I have been waiting all night\nfor somebody to say yes!",
    "Party rules: one match,\nno hard feelings.",
  },
  swapper = {
    "I am after one thing tonight.\nMaybe you have it?",
    "Swap meet! You give,\nyou get. Simple.",
    "I brought a spare. Trade me\nfor what I am after?",
  },
  trader = {
    "I am looking to trade\na POKEMON tonight.",
    "Mine is going to a good home\nor it is not going at all.",
    "Trade with me? I have\nsomething you might want.",
  },
}

local function pick(seed, list)
  local index
  index, seed = Rng.below(seed, #list)
  return list[index + 1], seed
end

-- Build the guest list for a party.  `roles` is Schedule.roles(theme).
--
-- Names are drawn without replacement inside one party: two guests called
-- KAZU standing in the same room is the sort of thing nobody notices until
-- they do.
function Guests.build(party, roles)
  local seed = party.seed
  local pool = {}
  for i, name in ipairs(Guests.NAMES) do pool[i] = name end

  local out = {}
  for index, role in ipairs(roles) do
    local nameIndex
    nameIndex, seed = Rng.below(seed, #pool)
    local name = table.remove(pool, nameIndex + 1) or ("GUEST" .. index)

    local sprite, line
    sprite, seed = pick(seed, Guests.SPRITES)
    line, seed = pick(seed, Guests.LINES[role] or Guests.LINES.battler)

    local guest = {
      index = index, role = role, name = name, sprite = sprite, line = line,
    }

    if role == "swapper" then
      guest.wants, seed = pick(seed, Guests.ITEMS)
      repeat
        guest.offers, seed = pick(seed, Guests.ITEMS)
      until guest.offers ~= guest.wants
    elseif role == "trader" then
      guest.wantsMon, seed = pick(seed, Guests.SPECIES)
      repeat
        guest.offersMon, seed = pick(seed, Guests.SPECIES)
      until guest.offersMon ~= guest.wantsMon
      -- what the mon they hand over arrives wearing
      local nick
      nick, seed = pick(seed, Guests.NAMES)
      guest.nickname = nick
      guest.otName = name
      local id
      id, seed = Rng.below(seed, 65536)
      guest.otId = id
    else
      -- a battler's team; levels are set against the player at build time
      local lead, second
      lead, seed = pick(seed, Guests.SPECIES)
      repeat
        second, seed = pick(seed, Guests.SPECIES)
      until second ~= lead
      guest.team = { lead, second }
    end

    out[#out + 1] = guest
  end
  return out
end

-- A battler's party, scaled to the player so a party match is a match.  Two
-- mons, the second trailing by one, and never below 2 or above 60.
function Guests.battleParty(guest, playerLevel)
  local level = math.floor((tonumber(playerLevel) or 5))
  if level < 2 then level = 2 end
  if level > 60 then level = 60 end
  local party = {}
  for i, species in ipairs(guest.team or {}) do
    party[i] = { species = species, level = math.max(2, level - (i - 1)) }
  end
  if #party == 0 then
    party[1] = { species = "RATTATA", level = level }
  end
  return party
end

return Guests
