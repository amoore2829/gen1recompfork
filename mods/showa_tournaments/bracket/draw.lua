-- A single-elimination draw, as pure data.
--
-- Nothing here knows what a Pokemon is.  An entrant is an id and a name; who
-- wins a match is somebody else's decision, handed back in through `settle`.
-- That is what lets the whole cup -- the draw, the byes, the round rollover,
-- the placement table -- be tested from literals, and it is why the player's
-- match can be a real battle while the other three in the round are settled
-- by a formula: both are just a call to `settle`.
local Rng = require("mods.showa_tournaments.bracket.rng")

local Draw = {}

Draw.BYE = "__bye"

local function nextPowerOfTwo(n)
  local size = 1
  while size < n do size = size * 2 end
  return size
end

-- entrants: list of { id = "you", name = "YOU", ... }.  Duplicated ids are
-- rejected rather than quietly collapsed: two slots answering to one name is
-- a bracket that can never resolve.
function Draw.build(entrants, seed)
  assert(type(entrants) == "table", "entrants must be a list")
  assert(#entrants >= 2, "a cup needs at least two entrants")
  local byId = {}
  for _, entrant in ipairs(entrants) do
    assert(type(entrant.id) == "string" and entrant.id ~= "",
      "every entrant needs an id")
    assert(entrant.id ~= Draw.BYE, "an entrant may not be called " .. Draw.BYE)
    assert(byId[entrant.id] == nil, "duplicate entrant: " .. entrant.id)
    byId[entrant.id] = entrant
  end

  local order
  order, seed = Rng.shuffled(seed or 0, entrants)
  local size = nextPowerOfTwo(#order)
  -- Byes ride at the BACK of the shuffled order, so the field a player reads
  -- in the bracket screen is the field that was drawn, with the empty slots
  -- where a short field would really leave them.
  local slots = {}
  for i = 1, size do
    slots[i] = order[i] and order[i].id or Draw.BYE
  end

  local matches = {}
  for i = 1, size, 2 do
    matches[#matches + 1] = { a = slots[i], b = slots[i + 1] }
  end

  return {
    v = 1,
    seed = seed,
    size = size,
    entrants = byId,
    round = 1,
    rounds = { matches },
    champion = nil,
    done = false,
  }
end

function Draw.entrant(bracket, id)
  return bracket.entrants[id]
end

function Draw.currentRound(bracket)
  return bracket.rounds[bracket.round]
end

-- How many rounds a field of this size has to play; 8 entrants is 3.
function Draw.totalRounds(bracket)
  local rounds, size = 0, bracket.size
  while size > 1 do size = size / 2; rounds = rounds + 1 end
  return rounds
end

Draw.ROUND_NAMES = { [1] = "FINAL", [2] = "SEMI", [3] = "QUARTER" }

-- Named from the END, the way a tournament is spoken about: the last round is
-- the FINAL whether the field was 4 or 32.
function Draw.roundName(bracket, round)
  local left = Draw.totalRounds(bracket) - (round or bracket.round) + 1
  return Draw.ROUND_NAMES[left] or ("ROUND " .. tostring(round or bracket.round))
end

-- The index of `id`'s match in the current round, or nil when they are out
-- (or already through).  Returns index, match, opponentId.
function Draw.matchFor(bracket, id)
  for i, match in ipairs(Draw.currentRound(bracket) or {}) do
    if match.winner == nil then
      if match.a == id then return i, match, match.b end
      if match.b == id then return i, match, match.a end
    end
  end
  return nil
end

-- A match against a bye is already over; the engine never has to be asked.
function Draw.isBye(match)
  return match.a == Draw.BYE or match.b == Draw.BYE
end

function Draw.byeWinner(match)
  if match.a == Draw.BYE and match.b == Draw.BYE then return Draw.BYE end
  if match.a == Draw.BYE then return match.b end
  return match.a
end

function Draw.settle(bracket, index, winnerId)
  local round = Draw.currentRound(bracket)
  local match = round and round[index]
  if not match then return false, "no such match" end
  if match.winner ~= nil then return false, "already settled" end
  if winnerId ~= match.a and winnerId ~= match.b then
    return false, "winner is not in this match"
  end
  match.winner = winnerId
  return true
end

-- Settle every unfinished match in the round except `exceptId`'s, using
-- resolve(match, aId, bId) -> winnerId.  Byes settle themselves and are never
-- put to the resolver, which is what keeps a short field from asking who beat
-- nobody.
function Draw.settleRound(bracket, resolve, exceptId)
  local settled = 0
  for i, match in ipairs(Draw.currentRound(bracket) or {}) do
    if match.winner == nil then
      if Draw.isBye(match) then
        match.winner = Draw.byeWinner(match)
        settled = settled + 1
      elseif match.a ~= exceptId and match.b ~= exceptId then
        local winner = resolve(match, match.a, match.b)
        if winner == match.a or winner == match.b then
          match.winner = winner
          settled = settled + 1
        end
      end
    end
  end
  return settled
end

function Draw.roundComplete(bracket)
  for _, match in ipairs(Draw.currentRound(bracket) or {}) do
    if match.winner == nil then return false end
  end
  return true
end

-- Roll the round over when it is complete.  Answers whether it moved, so a
-- caller can tell "the cup went on" from "somebody is still to play".
function Draw.advance(bracket)
  if bracket.done then return false end
  if not Draw.roundComplete(bracket) then return false end
  local winners = {}
  for _, match in ipairs(Draw.currentRound(bracket)) do
    winners[#winners + 1] = match.winner
  end
  if #winners <= 1 then
    bracket.champion = winners[1] ~= Draw.BYE and winners[1] or nil
    bracket.done = true
    return true
  end
  local matches = {}
  for i = 1, #winners, 2 do
    matches[#matches + 1] = { a = winners[i], b = winners[i + 1] }
  end
  bracket.round = bracket.round + 1
  bracket.rounds[bracket.round] = matches
  return true
end

-- Did `id` lose a match that has been played?
function Draw.eliminated(bracket, id)
  for _, round in ipairs(bracket.rounds) do
    for _, match in ipairs(round) do
      if match.winner ~= nil and (match.a == id or match.b == id)
        and match.winner ~= id then
        return true
      end
    end
  end
  return false
end

function Draw.alive(bracket, id)
  return bracket.entrants[id] ~= nil and not Draw.eliminated(bracket, id)
end

-- Placement: champion first, then runner-up, then by the round each entrant
-- went out in.  Ties inside a round break by entrant id so the table is the
-- same table every time it is read.
function Draw.standings(bracket)
  local exitRound = {}
  for number, round in ipairs(bracket.rounds) do
    for _, match in ipairs(round) do
      if match.winner ~= nil then
        for _, id in ipairs({ match.a, match.b }) do
          if id ~= Draw.BYE and id ~= match.winner then exitRound[id] = number end
        end
      end
    end
  end
  local out = {}
  for id, entrant in pairs(bracket.entrants) do
    out[#out + 1] = {
      id = id,
      name = entrant.name or id,
      champion = bracket.champion == id,
      exit = exitRound[id],
    }
  end
  table.sort(out, function(x, y)
    if x.champion ~= y.champion then return x.champion end
    local xr = x.exit or math.huge
    local yr = y.exit or math.huge
    if xr ~= yr then return xr > yr end
    return x.id < y.id
  end)
  for i, row in ipairs(out) do row.place = i end
  return out
end

return Draw
