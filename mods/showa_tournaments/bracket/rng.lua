-- The same seeded LCG the rival simulation carries, for the same reason: a
-- cup's draw and every result it decides without you are a function of the
-- cup's seed alone, so re-reading a bracket never re-rolls it.  Nothing here
-- touches math.random or os.time.
local Rng = {}

function Rng.next(seed)
  return (seed * 1103515245 + 12345) % 2147483648
end

-- returns value in [0, n), newSeed
function Rng.below(seed, n)
  seed = Rng.next(seed)
  return seed % n, seed
end

-- Fisher-Yates over a COPY, so the caller's list is never reordered under it.
function Rng.shuffled(seed, list)
  local out = {}
  for i, v in ipairs(list) do out[i] = v end
  for i = #out, 2, -1 do
    local j
    j, seed = Rng.below(seed, i)
    out[i], out[j + 1] = out[j + 1], out[i]
  end
  return out, seed
end

return Rng
