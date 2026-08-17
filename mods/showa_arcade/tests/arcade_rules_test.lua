-- The pure half of the arcade: EKANS rules and the gatcha pool.
--
--   luajit mods/showa_arcade/tests/arcade_rules_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Rules = require("mods.showa_arcade.games.ekans.rules")
local Pool = require("mods.showa_arcade.gatcha.pool")
local Ddr = require("mods.showa_arcade.games.ddr.rules")

-- ------- EKANS

do
  local s = Rules.new(7)
  T.eq(#s.snake, 3, "the snake starts three long")
  T.eq(s.alive, true, "and alive")
  T.check(s.food ~= nil, "with food on the board")

  Rules.step(s)
  T.eq(s.snake[1].x, 6, "a step moves the head right")
  T.eq(#s.snake, 3, "and keeps the length")

  Rules.turn(s, "left")
  Rules.step(s)
  T.eq(s.snake[1].x, 7, "reversal is ignored")

  Rules.turn(s, "down")
  Rules.step(s)
  T.eq(s.snake[1].y, 7, "a legal turn applies")

  -- determinism: same seed, same food trail
  local a, b = Rules.new(99), Rules.new(99)
  for _ = 1, 30 do Rules.step(a); Rules.step(b) end
  T.eq(a.food and a.food.x, b.food and b.food.x, "same seed, same food x")
  T.eq(a.food and a.food.y, b.food and b.food.y, "same seed, same food y")

  -- walls kill
  local w = Rules.new(1)
  Rules.turn(w, "up")
  for _ = 1, Rules.H + 1 do Rules.step(w) end
  T.eq(w.alive, false, "the north wall ends the run")

  -- eating scores and grows
  local e = Rules.new(5)
  e.food = { x = 6, y = 6 }
  Rules.step(e)
  T.eq(e.score, 10, "eating scores ten")
  Rules.step(e)
  T.eq(#e.snake, 4, "and the tail grows next step")

  -- moving into the vacating tail cell is legal
  local t = Rules.new(11)
  t.snake = { { x = 5, y = 5 }, { x = 5, y = 6 }, { x = 6, y = 6 },
              { x = 6, y = 5 } }
  t.dir, t.nextDir, t.grow = "left", "down", 0
  t.food = { x = 1, y = 1 }
  -- head down into (5,6)? no -- turn right toward the tail loop
  t.nextDir = "right"
  local before = #t.snake
  Rules.step(t)
  T.eq(t.alive, true, "chasing the vacating tail is not a death")
  T.eq(#t.snake, before, "length holds")
end

-- ------- the gatcha pool

do
  -- distribution: rare stays rare across many pulls
  local rng, counts = 1, {}
  for _ = 1, 5000 do
    local prize
    prize, rng = Pool.roll(Pool.DEFAULT, rng, {})
    counts[prize.tier] = (counts[prize.tier] or 0) + 1
  end
  T.check((counts.COMMON or 0) > 2500, "commons dominate the drum")
  T.check((counts.RARE or 0) > 0, "rares do come out")
  T.check((counts.RARE or 0) < 500, "but stay rare")

  -- duplicate protection: an owned trophy rerolls to a non-unique prize
  local owned = { TROPHY_GOLD = 1, TROPHY_SILVER = 1 }
  rng = 1
  for _ = 1, 2000 do
    local prize
    prize, rng = Pool.roll(Pool.DEFAULT, rng, owned)
    T.check(not prize.unique,
      "no second trophy while both are owned (" .. prize.id .. ")")
    if prize.unique then break end
  end
end

-- ------- DITTO DITTO REVOLUTION

do
  -- the chart is a function of the seed alone
  local a, b = Ddr.chart(1234), Ddr.chart(1234)
  T.eq(#a, #b, "same seed, same number of arrows")
  local same = true
  for i = 1, #a do
    if a[i].time ~= b[i].time or a[i].lane ~= b[i].lane then same = false end
  end
  T.check(same, "and the very same chart")
  T.check(#Ddr.chart(1) > 20, "a song is worth playing")
  for _, note in ipairs(a) do
    T.check(note.lane >= 1 and note.lane <= 4, "every arrow has a real lane")
    T.check(note.time >= Ddr.LEAD_IN, "and lands after the lead-in")
  end

  -- stepping exactly on the beat is PERFECT
  local g = Ddr.new(7)
  local first = g.notes[1]
  g.t = first.time
  T.eq(Ddr.press(g, first.lane), "PERFECT", "on the beat is PERFECT")
  T.eq(g.combo, 1, "and starts a combo")
  T.eq(g.score, Ddr.SCORE.PERFECT, "and scores")

  -- a little early or late is GOOD
  local g2 = Ddr.new(7)
  local n2 = g2.notes[2]
  g2.t = n2.time - Ddr.GOOD
  T.eq(Ddr.press(g2, n2.lane), "GOOD", "just inside the window is GOOD")

  -- outside the window claims nothing, and is not punished
  local g3 = Ddr.new(7)
  local n3 = g3.notes[1]
  g3.t = n3.time - Ddr.GOOD - 5
  T.eq(Ddr.press(g3, n3.lane), nil, "too early claims no arrow")
  T.eq(g3.counts.MISS, 0, "and stepping on nothing is not a miss")

  -- one arrow cannot be claimed twice
  local g4 = Ddr.new(7)
  local n4 = g4.notes[1]
  g4.t = n4.time
  Ddr.press(g4, n4.lane)
  local before = g4.score
  Ddr.press(g4, n4.lane)
  T.eq(g4.score, before, "an arrow already stepped on scores nothing more")

  -- letting one go by is a miss, exactly once
  local g5 = Ddr.new(7)
  local n5 = g5.notes[1]
  g5.t = n5.time + Ddr.GOOD
  Ddr.step(g5)
  T.eq(g5.counts.MISS, 1, "an arrow that passes is missed")
  Ddr.step(g5)
  T.eq(g5.counts.MISS, 1, "and is not missed a second time")
  T.eq(g5.combo, 0, "a miss breaks the combo")

  -- a perfect run: every arrow claimed, and the song ends
  local g6 = Ddr.new(99)
  local total = #g6.notes
  for _ = 1, 2000 do
    for lane = 1, 4 do
      local claim, gap = Ddr.claimable(g6, lane)
      if claim and gap <= Ddr.PERFECT then Ddr.press(g6, lane) end
    end
    Ddr.step(g6)
    if g6.done then break end
  end
  T.eq(g6.done, true, "the song ends on its own")
  T.eq(g6.counts.MISS, 0, "a perfect run misses nothing")
  T.eq(g6.counts.PERFECT, total, "and claims every arrow")
  T.eq(g6.best, total, "with one unbroken combo")
  T.check(g6.score > total * Ddr.SCORE.PERFECT,
    "which pays a combo bonus on top")

  -- and a run that never touches the pad ends too, all misses
  local g7 = Ddr.new(99)
  local count = #g7.notes
  for _ = 1, 2000 do
    Ddr.step(g7)
    if g7.done then break end
  end
  T.eq(g7.done, true, "an untouched song still ends")
  T.eq(g7.counts.MISS, count, "having missed everything")
  T.eq(g7.score, 0, "for no score")

  -- the view only ever asks for arrows that are actually on screen
  local g8 = Ddr.new(3)
  for _ = 1, 200 do
    Ddr.step(g8)
    for _, note in ipairs(Ddr.visible(g8)) do
      T.check(note.progress <= 1 and note.progress > -0.2,
        "a drawn arrow is inside its lane")
      T.check(note.lane >= 1 and note.lane <= 4, "and in a real lane")
    end
  end
end

T.finish("showa_arcade rules")
