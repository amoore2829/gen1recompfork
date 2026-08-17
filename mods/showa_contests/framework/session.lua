-- One contest sitting as a pure state machine: start, record entries,
-- finish against the competitor field, get sorted standings back.
local Session = {}

function Session.new()
  return { active = false, entries = {}, best = nil }
end

function Session.start(state)
  state.active = true
  state.entries = {}
  state.best = nil
end

function Session.record(state, name, species, size)
  if not state.active then return false end
  local entry = { name = name, species = species, size = size }
  table.insert(state.entries, entry)
  if not state.best or size > state.best.size then state.best = entry end
  return true
end

-- competitors: { { name, species, size }, ... }.  The player's single best
-- catch enters the field; ties keep the player's row first (stable sort by
-- strictly-greater comparison, player inserted ahead).
function Session.finish(state, competitors)
  state.active = false
  local rows = {}
  if state.best then
    rows[#rows + 1] = { name = state.best.name, species = state.best.species,
                        size = state.best.size, you = true }
  end
  for _, entry in ipairs(competitors or {}) do
    if entry and entry.size then
      rows[#rows + 1] = { name = entry.name or "???",
                          species = entry.species, size = entry.size }
    end
  end
  table.sort(rows, function(a, b) return a.size > b.size end)
  return rows
end

return Session
