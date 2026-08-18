-- What party is on, and where.
--
-- A party is a function of the DAY: the same day always throws the same
-- party, so the news can announce tomorrow's and be right, and a player who
-- reloads a save finds the same people standing in the same room.  Pure --
-- it is handed a day number and the venues that actually exist, and knows
-- nothing about the world beyond that.
local Schedule = {}

-- Parties run on a three-day cycle rather than a weekday: Gold's clock is a
-- day counter to a mod, and a cycle keeps a party findable without asking a
-- player to wait out a real week.
Schedule.CYCLE = 3

-- The themes rotate independently of the venue, so the same room throws a
-- different kind of evening each time it comes round.
Schedule.THEMES = {
  {
    id = "trade",
    label = "TRADE MEET",
    short = "TRADE",
    blurb = "Everyone brought something\nthey are hoping to swap.",
    -- how many guests of each role turn up; the sum is the guest count
    roles = { battler = 1, swapper = 2, trader = 2 },
  },
  {
    id = "battle",
    label = "BATTLE PARTY",
    short = "BATTLE",
    blurb = "The furniture is pushed back\nand everyone wants a match.",
    roles = { battler = 3, swapper = 1, trader = 1 },
  },
  {
    id = "swap",
    label = "SWAP MEET",
    short = "SWAP",
    blurb = "Bring what you do not need.\nLeave with what you do.",
    roles = { battler = 1, swapper = 3, trader = 1 },
  },
}

-- Where a party can be thrown.  Named as VENUE ids, so a venue whose feature
-- mod is not installed simply drops out of the rotation rather than throwing
-- a party in a room that does not exist.
Schedule.VENUES = {
  "SHOWA_MALL", "GOLDENROD_ARCADE", "CHIKAGAI", "CUP_GROUNDS", "LAKE_DERBY",
  "ELM_LAB",
}

function Schedule.theme(index)
  return Schedule.THEMES[((index - 1) % #Schedule.THEMES) + 1]
end

function Schedule.guestCount(theme)
  local n = 0
  for _, count in pairs(theme.roles) do n = n + count end
  return n
end

-- The roles at a party, in a fixed order, so guest 1 is guest 1 on every
-- read.  Sorted by role name and then filled, rather than by pairs order --
-- pairs over a hash is not stable in Lua and the guest list has to be.
Schedule.ROLE_ORDER = { "battler", "swapper", "trader" }

function Schedule.roles(theme)
  local out = {}
  for _, role in ipairs(Schedule.ROLE_ORDER) do
    for _ = 1, (theme.roles[role] or 0) do out[#out + 1] = role end
  end
  return out
end

-- Is there a party today?  Every CYCLE days.
function Schedule.isPartyDay(day)
  return (tonumber(day) or 0) % Schedule.CYCLE == 0
end

-- The next day on or after `day` that has a party.
function Schedule.nextPartyDay(day)
  day = tonumber(day) or 0
  for offset = 0, Schedule.CYCLE do
    if Schedule.isPartyDay(day + offset) then return day + offset end
  end
  return day
end

-- The party for a day.  `available` is the list of venue ids that really
-- exist right now; nil means "all of them", which is what the pure suite
-- uses.  Answers nil when nowhere is available -- a suite with no feature
-- mods installed throws no parties rather than crashing.
function Schedule.on(day, available)
  day = tonumber(day) or 0
  if not Schedule.isPartyDay(day) then return nil end

  local venues = {}
  if available == nil then
    for _, id in ipairs(Schedule.VENUES) do venues[#venues + 1] = id end
  else
    local live = {}
    for _, id in ipairs(available) do live[id] = true end
    for _, id in ipairs(Schedule.VENUES) do
      if live[id] then venues[#venues + 1] = id end
    end
  end
  if #venues == 0 then return nil end

  local slot = math.floor(day / Schedule.CYCLE)
  local venue = venues[(slot % #venues) + 1]
  local theme = Schedule.theme(slot + 1)
  return {
    day = day,
    slot = slot,
    venue = venue,
    theme = theme,
    -- the seed every guest at this party is drawn from
    seed = day * 7717 + slot * 131 + #venue,
    guests = Schedule.guestCount(theme),
  }
end

-- The next party at or after `day`, for the news feed and the host's
-- "come back on..." line.
function Schedule.next(day, available)
  day = tonumber(day) or 0
  for offset = 0, Schedule.CYCLE * (#Schedule.VENUES + 1) do
    local party = Schedule.on(day + offset, available)
    if party then return party end
  end
  return nil
end

return Schedule
