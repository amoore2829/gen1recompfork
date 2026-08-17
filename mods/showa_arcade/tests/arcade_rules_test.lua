-- The pure half of the arcade: EKANS rules and the gatcha pool.
--
--   luajit mods/showa_arcade/tests/arcade_rules_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Rules = require("mods.showa_arcade.games.ekans.rules")
local Pool = require("mods.showa_arcade.gatcha.pool")

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

T.finish("showa_arcade rules")
