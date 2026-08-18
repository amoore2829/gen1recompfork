-- Who turns up to a cup.
--
-- The player, then whichever rivals suit the cup, then the house field to
-- fill.  Pure: it is handed a list of rivals rather than reaching for the
-- rival mod, which is what lets this mod run with showa_rivals absent (the
-- list is simply empty and the house fills every slot) and lets the suite
-- test the selection from literals.
local Cups = require("mods.showa_tournaments.cups.list")
local Strength = require("mods.showa_tournaments.bracket.strength")

local Field = {}

Field.PLAYER = "you"

local function leadLevel(party)
  local best = 0
  for _, mon in ipairs(party or {}) do
    local level = tonumber(mon.level) or 0
    if level > best then best = level end
  end
  return best
end

-- A rival's fit for a cup: how close their lead is to the cap, from below.
-- Somebody miles under it is out of their depth and somebody miles over it is
-- there to be capped down into a walkover, so the entry list is the rivals the
-- cup is actually FOR -- which is also what makes the three cups feel like
-- three different fields rather than one field at three levels.
function Field.fit(rival, cap)
  local level = leadLevel(rival.party)
  if level == 0 then return math.huge end
  return math.abs(cap - level)
end

-- opts: { rivals = { { id, name, party, ... } }, playerParty = {...} }
-- Returns the entrant list, in a stable order (the draw shuffles it).
function Field.build(cup, opts)
  opts = opts or {}
  local cap = cup.cap
  local entrants = {
    { id = Field.PLAYER, name = "YOU", you = true,
      party = opts.playerParty or {} },
  }

  local rivals = {}
  for _, rival in ipairs(opts.rivals or {}) do
    if rival.id and rival.id ~= Field.PLAYER then
      rivals[#rivals + 1] = rival
    end
  end
  table.sort(rivals, function(x, y)
    local fx, fy = Field.fit(x, cap), Field.fit(y, cap)
    if fx ~= fy then return fx < fy end
    return tostring(x.id) < tostring(y.id)
  end)

  local room = (cup.field or 8) - 1
  for i = 1, math.min(room, #rivals) do
    local rival = rivals[i]
    entrants[#entrants + 1] = {
      id = "rival:" .. rival.id, name = rival.name or rival.id,
      rival = rival.id, party = rival.party or {},
    }
  end

  for _, house in ipairs(Cups.houseField(cap)) do
    if #entrants >= (cup.field or 8) then break end
    entrants[#entrants + 1] = house
  end

  for _, entrant in ipairs(entrants) do
    entrant.strength = Strength.of(entrant.party, cap)
  end
  return entrants
end

return Field
