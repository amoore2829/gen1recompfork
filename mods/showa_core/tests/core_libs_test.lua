-- The pure half of showa_core, driven with literals.  No engine, no
-- loader: these are the rules the whole suite leans on.
--
--   luajit mods/showa_core/tests/core_libs_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Wallet = require("mods.showa_core.lib.wallet")
local Clock = require("mods.showa_core.lib.clock")
local Scheduler = require("mods.showa_core.lib.scheduler")
local News = require("mods.showa_core.lib.news")
local Venues = require("mods.showa_core.lib.venues")
local Minigame = require("mods.showa_core.lib.minigame")
local Dialogue = require("mods.showa_core.lib.dialogue")

-- ------- wallet

do
  local w = Wallet.ensure({})
  Wallet.define(w, "ARCADE_TOKEN", "GAME TOKEN")
  T.eq(Wallet.get(w, "ARCADE_TOKEN"), 0, "a new currency starts at zero")
  T.eq(Wallet.add(w, "ARCADE_TOKEN", 5), 5, "credit lands")
  local ok, balance = Wallet.spend(w, "ARCADE_TOKEN", 3)
  T.eq(ok, true, "spend within balance succeeds")
  T.eq(balance, 2, "and reports the new balance")
  ok, balance = Wallet.spend(w, "ARCADE_TOKEN", 3)
  T.eq(ok, false, "overspend refuses")
  T.eq(Wallet.get(w, "ARCADE_TOKEN"), 2, "and the balance is unchanged")
  T.eq(Wallet.add(w, "ARCADE_TOKEN", -10), 0, "negative credit clamps at zero")
  Wallet.define(w, "ARCADE_TOKEN")
  T.eq(Wallet.label(w, "ARCADE_TOKEN"), "GAME TOKEN",
    "redefining keeps the first label")
  T.check(not pcall(Wallet.add, w, "STICKER", 1),
    "crediting an undefined currency raises")
end

-- ------- clock

do
  local c = Clock.new()
  T.eq(Clock.today(c), nil, "unknown until the first event")
  Clock.onDayChanged(c, { day = 2, previous = 1, reason = "rollover" })
  T.eq(Clock.today(c), "TUESDAY", "cart day numbers map Sunday-first")
  Clock.onDayChanged(c, { day = "friday" })
  T.eq(Clock.today(c), "FRIDAY", "string days normalize upper")
  Clock.onDayChanged(c, "garbage")
  T.eq(Clock.today(c), "FRIDAY", "a malformed payload changes nothing")
  Clock.onTodChanged(c, { tod = "NITE" })
  T.eq(Clock.tod(c), "NITE", "tod payload lands")
  T.eq(Clock.observeTod(c, "MORN"), "MORN", "the hook pass-through echoes")
  T.eq(Clock.tod(c), "MORN", "and records")
  Clock.observeTod(c, nil)
  T.eq(Clock.tod(c), "MORN", "a nil answer does not clear the mirror")
end

-- ------- scheduler

do
  local spec = Scheduler.normalize({ days = { "TUESDAY", "thursday" },
                                     tods = { "MORN", "DAY" } })
  T.eq(Scheduler.isOpen(spec, "TUESDAY", "DAY"), true, "open day+tod")
  T.eq(Scheduler.isOpen(spec, "tuesday", "day"), true, "tokens case-fold")
  T.eq(Scheduler.isOpen(spec, "MONDAY", "DAY"), false, "closed day refuses")
  T.eq(Scheduler.isOpen(spec, "TUESDAY", "NITE"), false, "closed tod refuses")
  T.eq(Scheduler.isOpen(spec, nil, "DAY"), false,
    "a day-gated venue is closed while the day is unknown")
  local always = Scheduler.normalize({})
  T.eq(Scheduler.isOpen(always, nil, nil), true,
    "no gates = open, even with no clock yet")
end

-- ------- news

do
  local n = News.ensure({}, 3)
  for i = 1, 5 do News.post(n, { text = "entry " .. i }) end
  T.eq(#n.entries, 3, "the ring caps")
  local recent = News.recent(n, 2)
  T.eq(recent[1].text, "entry 5", "newest first")
  T.eq(recent[2].text, "entry 4", "then older")
  T.eq(recent[1].serial, 5, "serials keep counting across evictions")
  T.check(not pcall(News.post, n, {}), "an entry needs text")
end

-- ------- venues

do
  local g = Venues.new()
  Venues.register(g, "GOLDENROD_ARCADE",
    { map = "GOLDENROD_GAME_CORNER", label = "GOLDENROD ARCADE",
      tags = { "arcade" } })
  Venues.register(g, "LAKE_DERBY", { map = "LAKE_OF_RAGE" })
  Venues.connect(g, "GOLDENROD_ARCADE", "LAKE_DERBY", 3)
  T.eq(Venues.get(g, "GOLDENROD_ARCADE").label, "GOLDENROD ARCADE",
    "registration lands")
  local hits = Venues.atMap(g, "GOLDENROD_GAME_CORNER")
  T.eq(#hits, 1, "atMap finds the arcade")
  T.eq(hits[1].id, "GOLDENROD_ARCADE", "by id")
  local nbs = Venues.neighbors(g, "LAKE_DERBY")
  T.eq(#nbs, 1, "edges are undirected")
  T.eq(nbs[1].cost, 3, "with their cost")
  T.check(not pcall(Venues.register, g, "GOLDENROD_ARCADE",
    { map = "X" }), "duplicate venue id raises")
  T.check(not pcall(Venues.connect, g, "GOLDENROD_ARCADE", "NOWHERE"),
    "connecting an unknown venue raises")
end

-- ------- minigame scaffold (headless: everything but draw)

do
  local steps, over = 0, false
  local record = Minigame.screen({
    title = "TEST GAME", tick = 2,
    init = function(s) s.hp = 2 end,
    step = function(s, _, api)
      steps = steps + 1
      s.hp = s.hp - 1
      if s.hp <= 0 then api.gameOver() end
    end,
    draw = function() end,
    score = function() return 42 end,
  })

  local popped = 0
  local pressed = {}
  local game = {
    input = { wasPressed = function(_, btn) return pressed[btn] == true end },
    stack = { pop = function() popped = popped + 1 end },
  }
  local doneScore
  local screen = record.new(game, { onDone = function(s) doneScore = s end })

  screen:update(); screen:update()
  T.eq(steps, 1, "tick=2 steps every second frame")
  screen:update(); screen:update()
  T.eq(steps, 2, "and again")
  T.eq(screen.phase, "results", "the game over moved to results")

  for _ = 1, 25 do screen:update() end
  pressed.a = true
  screen:update()
  T.eq(popped, 1, "A on the results card pops the screen")
  T.eq(doneScore, 42, "and hands the score to onDone")
end

-- ------- dialogue
--
-- The regression this exists for: Vm:showText takes a text KEY and
-- prints the literal "..." for one it cannot find, so handing it a
-- sentence changes state correctly and says nothing.  A fake VM that
-- behaves the way the real one does is enough to pin it.

do
  local shown = {}
  local vm = {
    text = {},
    lastTextKey = nil,
    showText = function(self, key)
      self.lastTextKey = key
      local body = self.text[key]
      if not body or body == "" then body = "..." end
      shown[#shown + 1] = body
    end,
  }
  local ctx = { vm = vm }

  T.eq(Dialogue.say(ctx, "Welcome to the arcade!"), true, "say reports it spoke")
  T.eq(shown[1], "Welcome to the arcade!",
    "the words reach the box, not \"...\"")
  T.eq(Dialogue.lastShown(ctx), "Welcome to the arcade!",
    "and are readable back for a driver to assert on")

  Dialogue.say(ctx, "A second line.")
  T.eq(shown[2], "A second line.", "a later line lands too")
  T.check(vm.lastTextKey ~= nil, "and it went through a real key")

  -- the raw call is what used to happen, and is what must never come back
  vm:showText("A sentence handed straight in.")
  T.eq(shown[3], "...", "proof: a raw sentence really does print as dots")

  T.eq(Dialogue.say(nil, "x"), false, "no ctx is a refusal, not a crash")
  T.eq(Dialogue.say({}, "x"), false, "no vm is a refusal too")
  T.eq(Dialogue.say(ctx, nil), false, "and so is no body")
end

T.finish("showa_core libs")
