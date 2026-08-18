-- The two swaps a party offers, as rules over plain tables.
--
-- Neither of these touches the save: they answer WHETHER a swap may happen
-- and WHAT it would do, and main.lua performs it.  That split is what lets
-- every refusal -- the bag that has none, the bag that is full, the last mon
-- in the party, the mon that is holding mail -- be tested from literals
-- rather than from a boot.
local Exchange = {}

-- Gold's bag caps a stack at 99 (engine/items/pack.asm), and a swap that
-- would overflow one is refused rather than silently clipped.
Exchange.MAX_STACK = 99

-- ------- item for item

-- inventory: { ITEM_ID = count }.  Answers ok, reason.
function Exchange.canSwapItem(inventory, guest)
  if type(guest) ~= "table" or not (guest.wants and guest.offers) then
    return false, "nothing to swap"
  end
  inventory = inventory or {}
  local held = inventory[guest.wants] or 0
  if held <= 0 then
    return false, "you have no " .. guest.wants
  end
  if (inventory[guest.offers] or 0) >= Exchange.MAX_STACK then
    return false, "your bag is full of " .. guest.offers
  end
  return true
end

-- The swap itself, as a description main.lua applies.  Kept separate from
-- the check so a caller cannot half-apply one.
function Exchange.swapItem(inventory, guest)
  local ok, why = Exchange.canSwapItem(inventory, guest)
  if not ok then return nil, why end
  local held = inventory[guest.wants] - 1
  inventory[guest.wants] = held > 0 and held or nil
  inventory[guest.offers] = (inventory[guest.offers] or 0) + 1
  return { gave = guest.wants, got = guest.offers }
end

-- ------- mon for mon

-- Which party slot could satisfy this guest, if any.  The FIRST match, so
-- the choice is predictable; a caller that wants to offer the player a pick
-- can use Exchange.eligible instead.
function Exchange.slotFor(party, guest)
  for index, mon in ipairs(party or {}) do
    if mon.species == guest.wantsMon then return index end
  end
  return nil
end

function Exchange.eligible(party, guest)
  local out = {}
  for index, mon in ipairs(party or {}) do
    if mon.species == guest.wantsMon then
      out[#out + 1] = { index = index, mon = mon }
    end
  end
  return out
end

-- Answers ok, reason.  The refusals are the cart's own, in the cart's order:
--
--   * you cannot trade away your last Pokemon (TryAddMonToParty runs after
--     RemoveMonFromPartyOrBox, so the party would be momentarily empty and
--     the overworld has no state for that);
--   * a mon holding MAIL cannot be traded (the Day-Care and the PC both
--     refuse it, and a party guest is not more permissive than the PC);
--   * and the guest wants a specific species.
function Exchange.canTradeMon(party, guest)
  if type(guest) ~= "table" or not (guest.wantsMon and guest.offersMon) then
    return false, "nothing to trade"
  end
  party = party or {}
  if #party <= 1 then
    return false, "you need a second POKEMON"
  end
  local index = Exchange.slotFor(party, guest)
  if not index then
    return false, "no " .. guest.wantsMon .. " with you"
  end
  local mon = party[index]
  if mon.mail or mon.hasMail then
    return false, "that one is holding MAIL"
  end
  return true, nil, index
end

-- The NpcTrade row this guest's trade amounts to.  Built here so the shape
-- the engine's own trade routine expects is stated in one place, and so the
-- suite can assert it without requiring an engine module.
function Exchange.tradeRow(guest)
  if not (guest and guest.wantsMon and guest.offersMon) then return nil end
  return {
    -- NPCTRADE_GIVEMON is what the PLAYER hands over and GETMON what they
    -- receive -- the opposite way round from the macro's own comment, which
    -- src/core/gen2/NpcTrade.lua warns about at the top.
    give = guest.wantsMon,
    get = guest.offersMon,
    nickname = guest.nickname,
    otName = guest.otName or guest.name,
    otId = guest.otId or 0,
    -- TRADE_GENDER_EITHER: a party guest is not fussy
    gender = "TRADE_GENDER_EITHER",
  }
end

return Exchange
