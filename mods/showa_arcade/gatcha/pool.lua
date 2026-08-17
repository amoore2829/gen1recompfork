-- The gatcha prize pool: a weighted roll with duplicate protection on
-- unique prizes.  Pure -- the same LCG discipline as the EKANS rules, so a
-- seed replays a pull and the distribution test can count thousands.
local Pool = {}

local function lcg(seed)
  return (seed * 1103515245 + 12345) % 2147483648
end

-- v1 prizes are collection pieces (dolls, stickers, trophies) recorded in
-- the arcade's own album; granting bag items is a later drop once the
-- give-item seam on Gold is settled (see mod.card known limitations).
Pool.DEFAULT = {
  { id = "STICKER_EKANS", label = "EKANS STICKER", tier = "COMMON", weight = 24 },
  { id = "STICKER_DITTO", label = "DITTO STICKER", tier = "COMMON", weight = 24 },
  { id = "DOLL_MAGIKARP", label = "MAGIKARP DOLL", tier = "COMMON", weight = 18 },
  { id = "DOLL_CLEFAIRY", label = "CLEFAIRY DOLL", tier = "UNCOMMON", weight = 12 },
  { id = "BADGE_ARCADE", label = "ARCADE PIN", tier = "UNCOMMON", weight = 12 },
  { id = "CEL_POSTER", label = "MOVIE POSTER", tier = "UNCOMMON", weight = 6 },
  { id = "TROPHY_SILVER", label = "SILVER TROPHY", tier = "RARE", weight = 3,
    unique = true },
  { id = "TROPHY_GOLD", label = "GOLD TROPHY", tier = "RARE", weight = 1,
    unique = true },
}

local function pick(entries, rng)
  local total = 0
  for _, entry in ipairs(entries) do total = total + entry.weight end
  rng = lcg(rng)
  local ticket = rng % total
  for _, entry in ipairs(entries) do
    if ticket < entry.weight then return entry, rng end
    ticket = ticket - entry.weight
  end
  return entries[#entries], rng
end

-- owned = { [prizeId] = count }.  A unique prize already owned rerolls over
-- the non-unique entries, so a lucky second GOLD TROPHY becomes a doll
-- rather than a dead pull.
function Pool.roll(entries, rng, owned)
  owned = owned or {}
  local entry
  entry, rng = pick(entries, rng)
  if entry.unique and (owned[entry.id] or 0) > 0 then
    local commons = {}
    for _, e in ipairs(entries) do
      if not e.unique then commons[#commons + 1] = e end
    end
    entry, rng = pick(commons, rng)
  end
  return entry, rng
end

return Pool
