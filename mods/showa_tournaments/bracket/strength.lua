-- Who wins a match nobody watches.
--
-- Three of the four first-round matches in an eight-entrant cup are between
-- two rivals, and the player is somewhere else while they happen.  Fighting
-- them for real would mean simulating six mons a side to decide a line of
-- text, so they are decided here instead: a strength number per party and one
-- seeded roll, which is honest about being a formula and is at least a formula
-- that reads the same parties the real battle would have used.
--
-- Pure and seeded: the same cup decides the same way however often the
-- bracket is re-read.
local Rng = require("mods.showa_tournaments.bracket.rng")

local Strength = {}

-- A level cap is the whole shape of a cup, so it is applied HERE as well as
-- in the roster the engine builds: a level-50 rival entering a level-15 cup
-- must not walk it on paper either.
function Strength.of(party, cap)
  local total, count = 0, 0
  for _, mon in ipairs(party or {}) do
    local level = tonumber(mon.level) or 1
    if cap and level > cap then level = cap end
    total = total + level
    count = count + 1
    if count >= 6 then break end
  end
  if count == 0 then return 1 end
  -- Sum, plus a bonus for a fuller bench: six level-20s should beat one
  -- level-50 in a six-on-six, and the sum alone already says so -- the bonus
  -- keeps the ordering when a cap has flattened every level to the same
  -- number.
  return total + (count - 1) * 2
end

-- Deterministic, and NOT a coin flip: the stronger party wins most of the
-- time and the gap decides how often.  A 20% underdog window is wide enough
-- that a cup is worth reading the bracket for and narrow enough that being
-- the strongest entrant still means something.
Strength.UPSET_WINDOW = 20

-- Returns winnerId, newSeed.  `a` and `b` are { id, strength }.
function Strength.resolve(a, b, seed)
  local sa = math.max(1, a.strength or 1)
  local sb = math.max(1, b.strength or 1)
  -- share of a 100-point roll, so the favourite's edge scales with the gap
  local favour = math.floor(sa * 100 / (sa + sb))
  if favour < Strength.UPSET_WINDOW then favour = Strength.UPSET_WINDOW end
  if favour > 100 - Strength.UPSET_WINDOW then
    favour = 100 - Strength.UPSET_WINDOW
  end
  local roll
  roll, seed = Rng.below(seed, 100)
  if roll < favour then return a.id, seed end
  return b.id, seed
end

return Strength
