-- One coarse tick of a rival's life.  PURE: state in, state out, plus a
-- list of things that happened for the caller to turn into news.  No
-- engine, no globals, no clock -- everything it needs arrives in `world`.
--
-- v1 moves rivals across the venue GRAPH rather than across map tiles:
-- a rival is *at* a venue, and entering that venue's map is what makes
-- it appear.  That is the whole reason this file can be a pure function
-- and therefore soak-tested for a thousand ticks in the suite.
local Rng = require("mods.showa_rivals.sim.rng")
local Growth = require("mods.showa_rivals.sim.growth")

local Advance = {}

-- world: {
--   playerLevel, badges,        -- for the rubber band
--   neighbors = function(venueId) -> { { id = ..., cost = ... }, ... },
--   venueExists = function(venueId) -> boolean,
-- }
-- def: the rival's static character sheet (rivals/<id>.lua)
function Advance.tick(state, def, world)
  local events = {}

  -- ------- travel: one edge toward the goal, or a wander

  state.travel = state.travel or 0
  if state.travel > 0 then
    state.travel = state.travel - 1
  else
    local options = world.neighbors(state.location) or {}
    if #options > 0 then
      -- a rival prefers the venues its character cares about; anything
      -- tagged for it wins, otherwise it drifts
      local favored = {}
      for _, edge in ipairs(options) do
        if def.haunts and def.haunts[edge.id] then favored[#favored + 1] = edge end
      end
      local pool = #favored > 0 and favored or options
      local hop
      hop, state.seed = Rng.pick(state.seed, pool)
      if hop and hop.id ~= state.location then
        state.location = hop.id
        state.travel = math.max(0, (hop.cost or 1) - 1)
        events[#events + 1] = { kind = "moved", to = hop.id }
      end
    end
  end

  -- ------- training

  local target = Growth.targetLevel(world.playerLevel, world.badges, def.pace)
  local moved = Growth.trainParty(state.party, target)
  if moved > 0 then
    events[#events + 1] = { kind = "trained", count = moved,
                            level = state.party[1].level }
  end

  -- ------- shopping: rivals earn a little and spend it on balls

  state.money = (state.money or 0) + 100
  if state.money >= 600 then
    state.money = state.money - 600
    state.inventory = state.inventory or {}
    state.inventory.POKE_BALL = (state.inventory.POKE_BALL or 0) + 2
    events[#events + 1] = { kind = "shopped", item = "POKE_BALL" }
  end

  -- ------- catching, from the character's own pool

  if def.catches and #def.catches > 0 and #state.party < 6 then
    local roll
    roll, state.seed = Rng.below(state.seed, 100)
    if roll < (def.catchChance or 12) then
      local species
      species, state.seed = Rng.pick(state.seed, def.catches)
      if species then
        state.party[#state.party + 1] = {
          species = species,
          level = math.max(Growth.MIN_LEVEL, target - 2),
        }
        events[#events + 1] = { kind = "caught", species = species }
      end
    end
  end

  state.ticks = (state.ticks or 0) + 1
  return state, events
end

-- A fresh rival from its character sheet.  Deterministic: the same def
-- and seed always produce the same starting rival.
function Advance.spawn(def, seed)
  local party = {}
  for _, entry in ipairs(def.starter or {}) do
    party[#party + 1] = { species = entry.species, level = entry.level }
  end
  return {
    id = def.id,
    seed = seed or def.seed or 1,
    location = def.home,
    travel = 0,
    party = party,
    money = 0,
    inventory = {},
    ticks = 0,
    history = { wins = 0, losses = 0 },
  }
end

return Advance
