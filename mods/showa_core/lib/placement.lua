-- Finding somewhere to stand.
--
-- Spawning an NPC near a spot is not "the venue's cell, or one step east":
-- that cell may already be somebody's, and the one next to it may be a
-- SHELF.  A mod NPC on an unwalkable cell still draws -- it just draws on top
-- of the furniture, which is exactly what it looks like.
--
-- So a search: rings outward from the wanted cell, taking the first one that
-- is walkable, unoccupied, and not already promised to somebody else in the
-- same pass.  Pure: the caller supplies a `free(x, y)` predicate built from
-- whatever it can see (the live map's isWalkableCell, the overworld's npcAt),
-- and every rule here is testable from a literal grid.
local Placement = {}

-- Offsets in rings of increasing Chebyshev distance, and inside a ring in a
-- stable order.  Stable matters: a party's guests are placed in one pass, and
-- a search that answered in a different order each boot would shuffle who is
-- standing where for no reason.
local function ringOffsets(radius)
  local out = {}
  for r = 0, radius do
    local ring = {}
    for dy = -r, r do
      for dx = -r, r do
        if math.max(math.abs(dx), math.abs(dy)) == r then
          ring[#ring + 1] = { dx, dy }
        end
      end
    end
    table.sort(ring, function(a, b)
      -- nearer the wanted cell first, then a fixed sweep
      local da = a[1] * a[1] + a[2] * a[2]
      local db = b[1] * b[1] + b[2] * b[2]
      if da ~= db then return da < db end
      if a[2] ~= b[2] then return a[2] < b[2] end
      return a[1] < b[1]
    end)
    for _, offset in ipairs(ring) do out[#out + 1] = offset end
  end
  return out
end

Placement.DEFAULT_RADIUS = 3

local cache = {}
function Placement.offsets(radius)
  radius = radius or Placement.DEFAULT_RADIUS
  if not cache[radius] then cache[radius] = ringOffsets(radius) end
  return cache[radius]
end

-- free(x, y) -> true when an NPC may stand there.
--
-- opts.radius   how far to look (default 3)
-- opts.prefer   a list of {dx, dy} to try BEFORE the rings, for a caller
--               that would rather somebody stood in a particular direction
--               (a host by the door, a shopkeeper behind a counter)
--
-- Answers x, y or nil.
function Placement.pick(free, bx, by, opts)
  opts = opts or {}
  if type(free) ~= "function" then return nil end
  for _, offset in ipairs(opts.prefer or {}) do
    local x, y = bx + offset[1], by + offset[2]
    if free(x, y) then return x, y end
  end
  for _, offset in ipairs(Placement.offsets(opts.radius)) do
    local x, y = bx + offset[1], by + offset[2]
    if free(x, y) then return x, y end
  end
  return nil
end

-- The predicate most callers want, built from the three things that can make
-- a cell unusable.  Any of them may be nil -- a headless caller has no map --
-- and a nil check simply does not veto.
--
--   walkable(x, y)  the live map's isWalkableCell
--   occupied(x, y)  the overworld's npcAt
--   taken           a set the caller mutates as it places, keyed "x,y"
function Placement.freeFn(walkable, occupied, taken)
  return function(x, y)
    if taken and taken[x .. "," .. y] then return false end
    if walkable and not walkable(x, y) then return false end
    if occupied and occupied(x, y) then return false end
    return true
  end
end

function Placement.claim(taken, x, y)
  if taken then taken[x .. "," .. y] = true end
  return x, y
end

return Placement
