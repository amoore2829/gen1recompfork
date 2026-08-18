-- Trainer classes a mod can actually FIGHT on Gold.
--
-- Registering a class into `trainers` is only half of a battle.  The rest of
-- the seam is two facts the compat doc does not spell out, both learned the
-- hard way, and this module is where the suite keeps them:
--
--   1. `loadtrainer` addresses a class by its NUMERIC index, not its id.
--      src/world/gen2/Trainers.lua:classIndex builds index -> class from
--      `class.index`, so a class registered without one is unreachable from a
--      script no matter how well formed the record is.  Gold's own 66 classes
--      hold 1..66; everything above is free, and BLOCKS below hands each Showa
--      mod its own slice so two of them can never land on the same number.
--
--   2. The party the engine fights is built by `Trainers.party` FROM THE CLASS
--      RECORD, at battle time.  Handing raw {species, level} tables back from
--      the `trainer.party` hook skips Mon.new -- so the mons arrive with no
--      moves.  A live party belongs in the class record's roster, where the
--      engine's own builder reads it; `Trainers.rows` shapes it.
--
-- Pure: allocation is a plain table the caller owns, and `rows` is a
-- transform.  The one impure half (writing a roster into the live data table)
-- is in main.lua, because only it has the game.
local Trainers = {}

-- Gold's classes end at 66.  Each mod gets a slice with room to grow rather
-- than a shared free-list, so an index is stable while a mod's own cast
-- changes and a crash log naming class 131 says which mod owns it.
Trainers.BLOCKS = {
  showa_rivals      = { first = 100, last = 129 },
  showa_tournaments = { first = 130, last = 179 },
}

-- Gold's own classes, so a claim can refuse to shadow one.
Trainers.VANILLA_LAST = 66

function Trainers.newAllocator()
  return { byClass = {}, byIndex = {}, cursor = {} }
end

-- Claim a numeric class index inside `blockId`'s slice.  Claiming the same
-- class id twice answers the same number: a mod that re-registers on a hot
-- reload must not walk its cast up the block every time.
function Trainers.claim(alloc, blockId, classId)
  assert(type(classId) == "string" and classId ~= "",
    "trainer class id must be a string")
  local held = alloc.byClass[classId]
  if held then return held end
  local block = Trainers.BLOCKS[blockId]
  if not block then
    return nil, "no index block for " .. tostring(blockId)
  end
  local at = alloc.cursor[blockId] or block.first
  while at <= block.last and alloc.byIndex[at] do at = at + 1 end
  if at > block.last then
    return nil, ("index block %s is full (%d..%d)")
      :format(blockId, block.first, block.last)
  end
  alloc.byClass[classId] = at
  alloc.byIndex[at] = classId
  alloc.cursor[blockId] = at + 1
  return at
end

function Trainers.indexOf(alloc, classId)
  return alloc.byClass[classId]
end

function Trainers.classAt(alloc, index)
  return alloc.byIndex[index]
end

-- A live party -> the roster rows the engine's party builder reads.
--
-- opts.cap clamps every level to a cup's ceiling (this is what makes a
-- level-15 cup a level-15 cup even when the entrant is a level-40 rival);
-- opts.max caps the party size, which the cart puts at six.
function Trainers.rows(party, opts)
  opts = opts or {}
  local cap = opts.cap
  local max = math.min(opts.max or 6, 6)
  local out = {}
  for _, mon in ipairs(party or {}) do
    if #out >= max then break end
    local species = mon.species
    local level = tonumber(mon.level) or 5
    if cap and level > cap then level = cap end
    if level < 1 then level = 1 end
    if type(species) == "string" and species ~= "" then
      out[#out + 1] = { species = species, level = math.floor(level) }
    end
  end
  -- A trainer with an empty party is a battle that cannot start, so never
  -- hand one back: an entrant with nothing legal fields its own placeholder.
  if #out == 0 then
    out[1] = { species = opts.fallbackSpecies or "RATTATA",
               level = math.max(1, math.floor(cap or 5)) }
  end
  return out
end

return Trainers
