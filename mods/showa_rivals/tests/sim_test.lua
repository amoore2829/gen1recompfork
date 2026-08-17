-- The rival brain, driven without an engine.  This is the suite that
-- makes the v1 design worth it: because sim/ is pure, a thousand ticks
-- of a rival's life can be soaked here rather than discovered in a save.
--
--   luajit mods/showa_rivals/tests/sim_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Rng = require("mods.showa_rivals.sim.rng")
local Growth = require("mods.showa_rivals.sim.growth")
local Advance = require("mods.showa_rivals.sim.advance")

local ELM = require("mods.showa_rivals.rivals.elm")
local PICHU = require("mods.showa_rivals.rivals.pichu")
local AZURILL = require("mods.showa_rivals.rivals.azurill")

-- ------- rng

do
  T.eq(Rng.next(1), Rng.next(1), "the generator is a pure function")
  T.check(Rng.next(1) ~= Rng.next(2), "and different seeds diverge")
  local value, seed = Rng.below(7, 10)
  T.check(value >= 0 and value < 10, "below stays in range")
  T.check(seed ~= 7, "and advances the seed")
  local picked = Rng.pick(3, { "a", "b", "c" })
  T.check(picked == "a" or picked == "b" or picked == "c",
    "pick returns a member")
  T.eq(Rng.pick(3, {}), nil, "picking from nothing is nil, not a crash")
end

-- ------- growth

do
  T.eq(Growth.targetLevel(5, 0, 1.0), 5, "a fresh player, a fresh rival")
  T.check(Growth.targetLevel(30, 4, 1.0) > Growth.targetLevel(10, 1, 1.0),
    "the band follows the player")
  T.check(Growth.targetLevel(30, 4, 1.2) > Growth.targetLevel(30, 4, 0.9),
    "an eager rival races ahead of a laid-back one")
  T.eq(Growth.targetLevel(500, 99, 2.0), Growth.MAX_LEVEL,
    "and the band is capped")
  T.check(Growth.targetLevel(-5, 0, 0.1) >= Growth.MIN_LEVEL,
    "never below the floor")

  local party = { { level = 5 }, { level = 9 } }
  Growth.trainParty(party, 8)
  T.eq(party[1].level, 6, "training closes one level a tick")
  T.eq(party[2].level, 9, "and never takes a level away")
end

-- ------- one tick

do
  local world = {
    playerLevel = 20, badges = 3,
    neighbors = function(id)
      local map = {
        ELM_LAB = { { id = "ALPH_RUINS", cost = 1 } },
        ALPH_RUINS = { { id = "ELM_LAB", cost = 1 } },
      }
      return map[id] or {}
    end,
    venueExists = function() return true end,
  }
  local live = Advance.spawn(ELM, ELM.seed)
  T.eq(live.location, "ELM_LAB", "a rival starts at home")
  T.eq(#live.party, 1, "with its starter")
  T.eq(live.party[1].species, "TOGEPI", "and Elm's is a TOGEPI")

  local _, events = Advance.tick(live, ELM, world)
  T.eq(live.ticks, 1, "a tick counts")
  T.check(type(events) == "table", "and reports what happened")
end

-- ------- determinism: the same seed lives the same life

do
  local world = {
    playerLevel = 25, badges = 4,
    neighbors = function(id)
      local ring = { "ELM_LAB", "ALPH_RUINS", "GOLDENROD_ARCADE" }
      local out = {}
      for _, other in ipairs(ring) do
        if other ~= id then out[#out + 1] = { id = other, cost = 1 } end
      end
      return out
    end,
    venueExists = function() return true end,
  }
  local a = Advance.spawn(PICHU, PICHU.seed)
  local b = Advance.spawn(PICHU, PICHU.seed)
  for _ = 1, 200 do
    Advance.tick(a, PICHU, world)
    Advance.tick(b, PICHU, world)
  end
  T.eq(a.location, b.location, "same seed, same place after 200 ticks")
  T.eq(#a.party, #b.party, "same team size")
  T.eq(a.party[1].level, b.party[1].level, "same levels")
  T.eq(a.seed, b.seed, "and the same generator state")
end

-- ------- the soak: a thousand ticks must leave a legal rival

do
  local venues = { "ELM_LAB", "ALPH_RUINS", "GOLDENROD_ARCADE",
                   "SHOWA_MALL", "LAKE_DERBY" }
  local known = {}
  for _, id in ipairs(venues) do known[id] = true end
  local world = {
    playerLevel = 40, badges = 8,
    neighbors = function(id)
      local out = {}
      for _, other in ipairs(venues) do
        if other ~= id then out[#out + 1] = { id = other, cost = 2 } end
      end
      return out
    end,
    venueExists = function(id) return known[id] == true end,
  }

  for _, def in ipairs({ ELM, PICHU, AZURILL }) do
    local live = Advance.spawn(def, def.seed)
    local lastLevel = 0
    for tick = 1, 1000 do
      Advance.tick(live, def, world)
      T.check(known[live.location] ~= nil,
        ("%s is always at a real venue (tick %d: %s)")
          :format(def.id, tick, tostring(live.location)))
      T.check(live.money >= 0, def.id .. " never goes into debt")
      T.check(#live.party >= 1 and #live.party <= 6,
        def.id .. " keeps a legal party size")
      local best = 0
      for _, mon in ipairs(live.party) do
        T.check(mon.level >= Growth.MIN_LEVEL
          and mon.level <= Growth.MAX_LEVEL,
          ("%s stays inside the level band (%s)")
            :format(def.id, tostring(mon.level)))
        if mon.level > best then best = mon.level end
      end
      T.check(best >= lastLevel, def.id .. " never loses ground")
      lastLevel = best
    end
    T.check(live.ticks == 1000, def.id .. " counted every tick")
  end
end

-- ------- the character sheets themselves

do
  local seen = {}
  for _, def in ipairs({ ELM, PICHU, AZURILL }) do
    T.check(not seen[def.id], "rival ids are unique: " .. def.id)
    seen[def.id] = true
    T.check(not seen[def.trainerClass], "trainer classes are unique")
    seen[def.trainerClass] = true
    T.check(#def.starter >= 1, def.id .. " has a starter")
    T.check(def.home ~= nil, def.id .. " has a home venue")
    for _, key in ipairs({ "greet", "challenge", "win", "loss" }) do
      T.check(type(def.lines[key]) == "string" and #def.lines[key] > 0,
        ("%s has a %s line"):format(def.id, key))
    end
  end
end

T.finish("showa_rivals sim")
