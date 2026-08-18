-- The suite's seeded LCG again, carried per mod so a mod is one require deep
-- and never reaches across into another's internals.  Same constants as
-- showa_rivals/sim/rng.lua and showa_tournaments/bracket/rng.lua on purpose:
-- one generator, so a value drawn the same way from the same seed is the same
-- value wherever it was drawn.
local Rng = {}

function Rng.next(seed)
  return (seed * 1103515245 + 12345) % 2147483648
end

-- returns value in [0, n), newSeed
function Rng.below(seed, n)
  seed = Rng.next(seed)
  return seed % n, seed
end

return Rng
