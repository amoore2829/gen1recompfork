-- The circuit: three cups on the National Park lawn, and the house field that
-- fills the empty slots.
--
-- Pure data.  A new cup is a row here; a new house entrant is a row in HOUSE
-- and one more member on the single house trainer class.
local Cups = {}

-- Amateur tournaments held on a park lawn, which is what a Showa-era regional
-- circuit actually looked like: a folding table, a hand-lettered bracket
-- board, and a trophy somebody's shop donated.
Cups.LIST = {
  {
    id = "rookie",
    label = "ROOKIE CUP",
    -- 16 glyphs is the ListMenu budget shared with the right column; these
    -- are the strings the registrar's menu shows.
    short = "ROOKIE",
    cap = 15,
    fee = 500,
    badges = 0,
    field = 8,
    prize = 3000,
    trophy = "TROPHY_ROOKIE",
    blurb = "Level 15 and under.\nEight entrants, one winner.",
  },
  {
    id = "open",
    label = "OPEN CUP",
    short = "OPEN",
    cap = 30,
    fee = 1500,
    badges = 3,
    field = 8,
    prize = 9000,
    trophy = "TROPHY_OPEN",
    blurb = "Level 30 and under.\nThree badges to enter.",
  },
  {
    id = "master",
    label = "MASTER CUP",
    short = "MASTER",
    cap = 50,
    fee = 3000,
    badges = 6,
    field = 8,
    prize = 25000,
    trophy = "TROPHY_MASTER",
    blurb = "Level 50 and under.\nSix badges. Bring everything.",
  },
}

function Cups.get(id)
  for _, cup in ipairs(Cups.LIST) do
    if cup.id == id then return cup end
  end
  return nil
end

-- The house field.  One trainer CLASS with many members, because that is what
-- `loadtrainer class, member` is for -- eight classes would burn eight index
-- slots to say the same thing.  `member` is the 1-based row in the class's
-- trainers list and doubles as the entrant id suffix.
Cups.HOUSE_CLASS = "SHOWA_CUP_ENTRANT"

-- `tier` scales a house entrant's party against the cup cap: 100 is at the
-- cap, 80 is a level under it.  Nobody in the house field is AT the cap in a
-- rookie cup, so a first cup is winnable with a starter.
Cups.HOUSE = {
  { member = 1, name = "TAKESHI", tier = 74,
    species = { "MACHOP", "GEODUDE" } },
  { member = 2, name = "YUMIKO", tier = 80,
    species = { "JIGGLYPUFF", "CLEFAIRY" } },
  { member = 3, name = "HIROSHI", tier = 86,
    species = { "GROWLITHE", "VULPIX" } },
  { member = 4, name = "AKIRA", tier = 92,
    species = { "GASTLY", "ZUBAT" } },
  { member = 5, name = "NORIKO", tier = 78,
    species = { "ODDISH", "BELLSPROUT" } },
  { member = 6, name = "SATOSHI", tier = 88,
    species = { "PIDGEY", "SPEAROW" } },
  { member = 7, name = "KEIKO", tier = 96,
    species = { "PSYDUCK", "POLIWAG" } },
  { member = 8, name = "MASARU", tier = 100,
    species = { "ONIX", "RHYHORN" } },
}

function Cups.houseEntrant(member)
  for _, entry in ipairs(Cups.HOUSE) do
    if entry.member == member then return entry end
  end
  return nil
end

-- A house entrant's party at a cup's cap.  Two mons each: enough that a cup
-- match is a match, few enough that eight of them are quick to settle.
function Cups.houseParty(entry, cap)
  local level = math.floor(cap * (entry.tier or 100) / 100)
  if level < 2 then level = 2 end
  local party = {}
  for i, species in ipairs(entry.species) do
    -- the second mon trails the lead by one, the way a cart trainer's does
    party[i] = { species = species, level = math.max(2, level - (i - 1)) }
  end
  return party
end

-- Every house entrant as a draw entrant, ids namespaced so they can never
-- collide with a rival id or with "you".
function Cups.houseField(cap)
  local out = {}
  for _, entry in ipairs(Cups.HOUSE) do
    out[#out + 1] = {
      id = "house:" .. entry.member,
      name = entry.name,
      house = entry.member,
      party = Cups.houseParty(entry, cap),
    }
  end
  return out
end

return Cups
