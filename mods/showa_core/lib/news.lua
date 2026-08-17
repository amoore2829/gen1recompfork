-- The world news feed: an append-only ring buffer over a plain state
-- table.  Rivals post victories, contests post standings, the arcade posts
-- broken high scores; the NewsScreen and the rival dex read it back.
-- Pure -- the caller owns persistence.
local News = {}

local DEFAULT_CAP = 64

function News.ensure(state, cap)
  state.cap = cap or state.cap or DEFAULT_CAP
  state.entries = state.entries or {}
  state.serial = state.serial or 0
  return state
end

-- entry: { text = "...", tags = {"arcade"} | nil, day = <clock token> | nil }
function News.post(state, entry)
  assert(type(entry) == "table" and type(entry.text) == "string",
    "a news entry needs a text field")
  state.serial = state.serial + 1
  entry.serial = state.serial
  table.insert(state.entries, entry)
  while #state.entries > state.cap do
    table.remove(state.entries, 1)
  end
  return entry.serial
end

-- newest first
function News.recent(state, n)
  local out = {}
  local count = #state.entries
  for i = count, math.max(1, count - (n or count) + 1), -1 do
    out[#out + 1] = state.entries[i]
  end
  return out
end

return News
