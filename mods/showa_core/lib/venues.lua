-- The venue graph: where the world's places of interest are and how they
-- connect.  Feature mods register their venues (the arcade, the malls, the
-- contest sites); the rival simulation walks the edges.  In-memory only --
-- registrations are code, rebuilt every boot, exactly like a content
-- registry.  Pure.
local Venues = {}

function Venues.new()
  return { nodes = {}, edges = {} }
end

-- def: { map = "GOLDENROD_GAME_CORNER", label = "GOLDENROD ARCADE",
--        tags = {"arcade"} | nil, x = <cell> | nil, y = <cell> | nil }
function Venues.register(graph, id, def)
  assert(type(id) == "string" and id ~= "", "venue id must be a string")
  assert(type(def) == "table" and type(def.map) == "string",
    "a venue needs a map id")
  assert(graph.nodes[id] == nil, "venue already registered: " .. id)
  graph.nodes[id] = { id = id, map = def.map, label = def.label or id,
                      tags = def.tags or {}, x = def.x, y = def.y }
  graph.edges[id] = graph.edges[id] or {}
  return graph.nodes[id]
end

-- undirected; cost is abstract travel time in sim ticks (default 1)
function Venues.connect(graph, a, b, cost)
  assert(graph.nodes[a], "unknown venue: " .. tostring(a))
  assert(graph.nodes[b], "unknown venue: " .. tostring(b))
  graph.edges[a][b] = cost or 1
  graph.edges[b] = graph.edges[b] or {}
  graph.edges[b][a] = cost or 1
end

function Venues.get(graph, id) return graph.nodes[id] end

function Venues.neighbors(graph, id)
  local out = {}
  for other, cost in pairs(graph.edges[id] or {}) do
    out[#out + 1] = { id = other, cost = cost }
  end
  table.sort(out, function(x, y) return x.id < y.id end)
  return out
end

function Venues.atMap(graph, mapId)
  local out = {}
  for id, node in pairs(graph.nodes) do
    if node.map == mapId then out[#out + 1] = node end
  end
  table.sort(out, function(x, y) return x.id < y.id end)
  return out
end

function Venues.all(graph)
  local out = {}
  for id in pairs(graph.nodes) do out[#out + 1] = id end
  table.sort(out)
  return out
end

return Venues
