-- The pure half of showa_contests: deterministic judging and the session
-- state machine.
--
--   luajit mods/showa_contests/tests/contests_rules_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Judging = require("mods.showa_contests.framework.judging")
local Session = require("mods.showa_contests.framework.session")

-- ------- judging

do
  local mon = { species = "MAGIKARP", level = 10,
                dvs = { attack = 5, defense = 5, speed = 5, special = 5 } }
  local size = Judging.fishSize(mon)
  T.eq(Judging.fishSize(mon), size, "the same mon always measures the same")

  local bigger = { species = "MAGIKARP", level = 20,
                   dvs = { attack = 5, defense = 5, speed = 5, special = 5 } }
  T.check(Judging.fishSize(bigger) > size, "a higher level measures longer")

  local seaking = { species = "SEAKING", level = 10,
                    dvs = { attack = 5, defense = 5, speed = 5, special = 5 } }
  T.eq(Judging.fishSize(seaking), size + 30,
    "SEAKING carries the derby's own bonus")

  T.check(Judging.fishSize({ species = "MAGIKARP" }) > 0,
    "a bare mon still measures (defaults, no crash)")

  -- the whole range stays sane: no negative or absurd fish
  for level = 1, 100, 7 do
    for dv = 0, 15, 5 do
      local s = Judging.fishSize({ species = "GYARADOS", level = level,
        dvs = { attack = dv, defense = dv, speed = dv, special = dv } })
      T.check(s > 0 and s < 400, ("size in range at L%d/DV%d (%d)")
        :format(level, dv, s))
    end
  end
end

-- ------- the session

do
  local s = Session.new()
  T.eq(Session.record(s, "YOU", "MAGIKARP", 50), false,
    "no entries before the session opens")

  Session.start(s)
  T.eq(s.active, true, "start opens it")
  Session.record(s, "YOU", "MAGIKARP", 50)
  Session.record(s, "YOU", "SEAKING", 90)
  Session.record(s, "YOU", "GOLDEEN", 40)
  T.eq(s.best.size, 90, "the best catch is kept")
  T.eq(s.best.species, "SEAKING", "with its species")

  local standings = Session.finish(s, {
    { name = "AZURILL KID", species = "SEAKING", size = 85 },
    { name = "FISHER", species = "MAGIKARP", size = 95 },
  })
  T.eq(s.active, false, "finish closes the session")
  T.eq(#standings, 3, "the player joins the field")
  T.eq(standings[1].name, "FISHER", "sorted by size, biggest first")
  T.eq(standings[2].you, true, "the player placed second")
  T.eq(standings[3].name, "AZURILL KID", "and the rest follow")

  -- an empty derby is not a crash
  local empty = Session.new()
  Session.start(empty)
  T.eq(#Session.finish(empty, {}), 0, "a derby nobody entered ends cleanly")

  -- a malformed competitor row is skipped, not fatal.  No nil hole in the
  -- literal: that would truncate ipairs and test Lua, not the guard.
  local guard = Session.new()
  Session.start(guard)
  Session.record(guard, "YOU", "SEAKING", 60)
  local rows = Session.finish(guard, { { name = "GHOST" },
    { name = "REAL", size = 10 } })
  T.eq(#rows, 2, "a competitor with no size is dropped, the rest survive")
  T.eq(rows[1].you, true, "and the sound rows still sort")
end

T.finish("showa_contests rules")
