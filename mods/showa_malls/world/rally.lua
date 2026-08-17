-- The stamp rally: which counters give which sticker, and whether the
-- book is full.  Pure -- the caller owns the collected set.
local Rally = {}

-- Counters sit on the back row (y=2), which is open across x=3..11 on
-- every floor; the info desk is on the ground floor's south aisle.
Rally.STORES = {
  { id = "TOYS", label = "TOY FLOOR", map = "SHOWA_MALL_1F",
    sprite = "SPRITE_CLERK", x = 5, y = 2,
    line = "Welcome to the toy floor!\nHere is your rally sticker." },
  { id = "RECORDS", label = "RECORD SHOP", map = "SHOWA_MALL_1F",
    sprite = "SPRITE_LASS", x = 8, y = 2,
    line = "Latest singles, right here!\nTake a sticker for your book." },
  { id = "FASHION", label = "FASHION FLOOR", map = "SHOWA_MALL_2F",
    sprite = "SPRITE_LASS", x = 5, y = 2,
    line = "That is a bold look you have.\nA sticker suits it." },
  { id = "RAMEN", label = "RAMEN STAND", map = "SHOWA_MALL_TUNNEL",
    sprite = "SPRITE_GENTLEMAN", x = 5, y = 2,
    line = "One bowl, extra chashu!\nAnd a sticker on the house." },
}

function Rally.byId(id)
  for _, store in ipairs(Rally.STORES) do
    if store.id == id then return store end
  end
  return nil
end

function Rally.count(collected)
  local n = 0
  for _, store in ipairs(Rally.STORES) do
    if collected[store.id] then n = n + 1 end
  end
  return n
end

function Rally.total() return #Rally.STORES end

function Rally.complete(collected)
  return Rally.count(collected) >= Rally.total()
end

-- one row per store, in board order, for the album screen
function Rally.album(collected)
  local rows = {}
  for _, store in ipairs(Rally.STORES) do
    rows[#rows + 1] = {
      id = store.id, label = store.label,
      owned = collected[store.id] ~= nil,
      day = collected[store.id],
    }
  end
  return rows
end

return Rally
