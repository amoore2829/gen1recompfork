-- Multi-currency ledger over a plain state table.  Pure: no engine access,
-- no upvalue state -- the caller owns the table and its persistence, which
-- is what makes every rule here unit-testable with a literal.
local Wallet = {}

function Wallet.ensure(state)
  state.currencies = state.currencies or {}
  state.balances = state.balances or {}
  return state
end

-- Defining twice is allowed and keeps the first label unless a new one is
-- given: two mods may both declare the currency they share.
function Wallet.define(state, id, label)
  assert(type(id) == "string" and id ~= "", "currency id must be a string")
  state.currencies[id] = label or state.currencies[id] or id
end

function Wallet.defined(state, id)
  return state.currencies[id] ~= nil
end

function Wallet.label(state, id)
  return state.currencies[id]
end

function Wallet.get(state, id)
  return state.balances[id] or 0
end

-- Credits clamp at zero from below: a negative `add` is allowed as a
-- convenience but can never overdraw.
function Wallet.add(state, id, n)
  assert(state.currencies[id], "undefined currency: " .. tostring(id))
  local balance = (state.balances[id] or 0) + n
  if balance < 0 then balance = 0 end
  state.balances[id] = balance
  return balance
end

-- Spending is all-or-nothing: false and an unchanged balance when short.
function Wallet.spend(state, id, n)
  assert(n >= 0, "spend amount must be non-negative")
  local balance = state.balances[id] or 0
  if balance < n then return false, balance end
  state.balances[id] = balance - n
  return true, balance - n
end

return Wallet
