-- A seeded generator carried IN the state, so a rival's whole life is a
-- function of its seed and the ticks it has taken.  Nothing here reads
-- os.time or math.random: two runs from the same save must agree, or the
-- world news feed reports a different history every boot.
local Rng = {}

function Rng.next(seed)
  return (seed * 1103515245 + 12345) % 2147483648
end

-- returns value, newSeed
function Rng.below(seed, n)
  seed = Rng.next(seed)
  return seed % n, seed
end

function Rng.pick(seed, list)
  if #list == 0 then return nil, seed end
  local index
  index, seed = Rng.below(seed, #list)
  return list[index + 1], seed
end

return Rng
