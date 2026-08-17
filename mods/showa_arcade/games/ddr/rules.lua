-- DITTO DITTO REVOLUTION: step on the arrow when it reaches the line.
-- A pure state machine on a tick clock -- the chart is generated from a
-- seed, so a machine plays the same song twice, and every judgement is a
-- function of (chart, presses) rather than of when a frame happened to
-- land.
local Rules = {}

Rules.LANES = { "left", "down", "up", "right" }

-- Judgement windows, in ticks either side of a note's beat.
Rules.PERFECT, Rules.GOOD = 2, 5
Rules.SCORE = { PERFECT = 100, GOOD = 50, MISS = 0 }

Rules.LEAD_IN = 40      -- ticks before the first arrow
Rules.BEAT = 14         -- ticks between beats
Rules.BEATS = 48        -- how long a song runs

local function lcg(seed)
  return (seed * 1103515245 + 12345) % 2147483648
end

-- The chart: one arrow per beat, with the occasional rest and the
-- occasional double, built from the seed alone.
function Rules.chart(seed)
  local notes = {}
  for beat = 0, Rules.BEATS - 1 do
    seed = lcg(seed)
    -- every eighth beat is a rest, so the song breathes
    if beat % 8 ~= 7 then
      local lane = (seed % 4) + 1
      notes[#notes + 1] = { time = Rules.LEAD_IN + beat * Rules.BEAT,
                            lane = lane, hit = nil }
      seed = lcg(seed)
      -- a second arrow on the same beat, later in the song
      if beat > 16 and seed % 100 < 18 then
        local other = ((lane + 1 + (seed % 3)) % 4) + 1
        if other ~= lane then
          notes[#notes + 1] = { time = Rules.LEAD_IN + beat * Rules.BEAT,
                                lane = other, hit = nil }
        end
      end
    end
  end
  return notes
end

function Rules.new(seed)
  return {
    t = 0,
    notes = Rules.chart(seed or 1),
    score = 0, combo = 0, best = 0,
    counts = { PERFECT = 0, GOOD = 0, MISS = 0 },
    judgement = nil,     -- the last call, for the view to flash
    judgeAt = -999,
    done = false,
  }
end

local function award(state, verdict)
  state.counts[verdict] = state.counts[verdict] + 1
  state.score = state.score + Rules.SCORE[verdict]
  if verdict == "MISS" then
    state.combo = 0
  else
    state.combo = state.combo + 1
    if state.combo > state.best then state.best = state.combo end
    -- every tenth step in a row is worth a bonus, which is what makes a
    -- clean run score better than a lucky one
    if state.combo % 10 == 0 then state.score = state.score + 100 end
  end
  state.judgement = verdict
  state.judgeAt = state.t
end

-- The nearest unjudged arrow in this lane that is still close enough to
-- claim.  Nil when the player stepped on nothing.
function Rules.claimable(state, lane)
  local best, bestGap
  for _, note in ipairs(state.notes) do
    if note.lane == lane and note.hit == nil then
      local gap = math.abs(note.time - state.t)
      if gap <= Rules.GOOD and (bestGap == nil or gap < bestGap) then
        best, bestGap = note, gap
      end
    end
  end
  return best, bestGap
end

function Rules.press(state, lane)
  if state.done then return nil end
  local note, gap = Rules.claimable(state, lane)
  if not note then
    -- stepping on nothing is not punished; the cart's own pads do not
    -- either, and punishing it makes the game feel like it is lying
    return nil
  end
  local verdict = gap <= Rules.PERFECT and "PERFECT" or "GOOD"
  note.hit = verdict
  award(state, verdict)
  return verdict
end

function Rules.step(state)
  if state.done then return state end
  state.t = state.t + 1
  for _, note in ipairs(state.notes) do
    if note.hit == nil and state.t - note.time > Rules.GOOD then
      note.hit = "MISS"
      award(state, "MISS")
    end
  end
  local last = state.notes[#state.notes]
  if last and state.t > last.time + Rules.GOOD + 30 then
    state.done = true
  end
  return state
end

-- What the view needs: arrows still on screen, with 0 = at the line and
-- 1 = at the top of the lane.
function Rules.visible(state, lead)
  lead = lead or 60
  local out = {}
  for _, note in ipairs(state.notes) do
    local delta = note.time - state.t
    if note.hit == nil and delta <= lead and delta > -Rules.GOOD then
      out[#out + 1] = { lane = note.lane, progress = delta / lead }
    end
  end
  return out
end

return Rules
