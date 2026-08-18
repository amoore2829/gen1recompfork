-- The pure half of showa_tournaments: the draw, the strength roll, the cup
-- table and the field builder.  No engine, no boot.
--
--   luajit mods/showa_tournaments/tests/tournaments_rules_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Draw = require("mods.showa_tournaments.bracket.draw")
local Rng = require("mods.showa_tournaments.bracket.rng")
local Strength = require("mods.showa_tournaments.bracket.strength")
local Cups = require("mods.showa_tournaments.cups.list")
local Field = require("mods.showa_tournaments.cups.field")

local function entrants(n)
  local out = {}
  for i = 1, n do
    out[i] = { id = "e" .. i, name = "E" .. i, strength = i * 10 }
  end
  return out
end

-- ------- the rng

do
  T.eq(Rng.next(1), Rng.next(1), "the generator is a function of its seed")
  local a = Rng.shuffled(99, { 1, 2, 3, 4, 5 })
  local b = Rng.shuffled(99, { 1, 2, 3, 4, 5 })
  T.eq(table.concat(a, ","), table.concat(b, ","),
    "the same seed shuffles the same way")

  local source = { 1, 2, 3, 4, 5 }
  Rng.shuffled(7, source)
  T.eq(table.concat(source, ","), "1,2,3,4,5",
    "and the caller's list is left alone")

  local seen = {}
  for _, v in ipairs(Rng.shuffled(12345, { 1, 2, 3, 4, 5, 6, 7, 8 })) do
    T.eq(seen[v], nil, "no value is duplicated by the shuffle")
    seen[v] = true
  end
  local count = 0
  for _ in pairs(seen) do count = count + 1 end
  T.eq(count, 8, "and none is lost")
end

-- ------- the draw

do
  local bracket = Draw.build(entrants(8), 4242)
  T.eq(bracket.size, 8, "eight entrants make an eight-slot draw")
  T.eq(#bracket.rounds[1], 4, "with four first-round matches")
  T.eq(Draw.totalRounds(bracket), 3, "and three rounds to play")
  T.eq(Draw.roundName(bracket, 1), "QUARTER", "round 1 is the quarter-final")
  T.eq(Draw.roundName(bracket, 2), "SEMI", "round 2 is the semi")
  T.eq(Draw.roundName(bracket, 3), "FINAL", "round 3 is the final")

  local twin = Draw.build(entrants(8), 4242)
  T.eq(twin.rounds[1][1].a, bracket.rounds[1][1].a,
    "the same seed draws the same bracket")

  -- every entrant is in the draw exactly once
  local slots = {}
  for _, match in ipairs(bracket.rounds[1]) do
    for _, id in ipairs({ match.a, match.b }) do
      T.eq(slots[id], nil, "no entrant is drawn twice: " .. id)
      slots[id] = true
    end
  end
  for i = 1, 8 do
    T.eq(slots["e" .. i], true, "e" .. i .. " is in the draw")
  end
end

-- ------- short fields get byes, and byes settle themselves

do
  local bracket = Draw.build(entrants(5), 77)
  T.eq(bracket.size, 8, "five entrants still play an eight-slot draw")
  -- three empty SLOTS, which is two walkover matches and one real match
  -- sharing a slot with a bye
  local byeSlots, byeMatches = 0, 0
  for _, match in ipairs(bracket.rounds[1]) do
    if match.a == Draw.BYE then byeSlots = byeSlots + 1 end
    if match.b == Draw.BYE then byeSlots = byeSlots + 1 end
    if Draw.isBye(match) then byeMatches = byeMatches + 1 end
  end
  T.eq(byeSlots, 3, "three of the eight slots are empty")
  T.eq(byeMatches, 2, "which is two matches nobody has to play")

  local asked = 0
  Draw.settleRound(bracket, function(_, a) asked = asked + 1; return a end)
  T.eq(asked, 2, "only the real matches are put to the resolver")
  T.eq(Draw.roundComplete(bracket), true, "and the round is complete")

  T.eq(Draw.advance(bracket), true, "the round rolls over")
  T.eq(bracket.round, 2, "into round two")
  T.eq(#bracket.rounds[2], 2, "with two matches")
end

do
  -- a bye against a bye must not crash or crown nobody
  local match = { a = Draw.BYE, b = Draw.BYE }
  T.eq(Draw.byeWinner(match), Draw.BYE, "two byes answer a bye")
end

-- ------- settling, advancing, and the champion

do
  local bracket = Draw.build(entrants(8), 31337)
  local rounds = 0
  while not bracket.done and rounds < 10 do
    Draw.settleRound(bracket, function(match) return match.a end)
    Draw.advance(bracket)
    rounds = rounds + 1
  end
  T.eq(bracket.done, true, "a cup played out finishes")
  T.eq(rounds, 3, "in exactly three rounds")
  T.check(bracket.champion ~= nil, "and crowns a champion")

  local standings = Draw.standings(bracket)
  T.eq(#standings, 8, "everybody is placed")
  T.eq(standings[1].id, bracket.champion, "the champion places first")
  T.eq(standings[1].place, 1, "and carries place 1")
  T.eq(standings[8].place, 8, "down to place 8")
  -- the four knocked out in round 1 are at the bottom
  for i = 5, 8 do
    T.eq(standings[i].exit, 1, "place " .. i .. " went out in round 1")
  end

  local again = Draw.standings(bracket)
  for i, row in ipairs(standings) do
    T.eq(again[i].id, row.id, "the standings table is stable at " .. i)
  end
end

-- ------- settle refuses what it should

do
  local bracket = Draw.build(entrants(4), 5)
  local ok, err = Draw.settle(bracket, 99, "e1")
  T.eq(ok, false, "settling a match that is not there fails")
  T.eq(err, "no such match", "and says so")

  local first = bracket.rounds[1][1]
  ok, err = Draw.settle(bracket, 1, "nobody")
  T.eq(ok, false, "a winner from outside the match is refused")
  T.eq(err, "winner is not in this match", "and says so")

  T.eq(Draw.settle(bracket, 1, first.a), true, "the real winner is taken")
  ok, err = Draw.settle(bracket, 1, first.b)
  T.eq(ok, false, "and a settled match cannot be settled again")
  T.eq(err, "already settled", "and says so")
end

-- ------- alive / eliminated / matchFor

do
  local bracket = Draw.build(entrants(4), 11)
  local first = bracket.rounds[1][1]
  T.eq(Draw.alive(bracket, first.a), true, "everybody starts alive")
  local index, _, opponent = Draw.matchFor(bracket, first.a)
  T.eq(index, 1, "the first entrant's match is match one")
  T.eq(opponent, first.b, "against the other side of it")

  Draw.settle(bracket, 1, first.a)
  T.eq(Draw.eliminated(bracket, first.b), true, "the loser is out")
  T.eq(Draw.alive(bracket, first.b), false, "and no longer alive")
  T.eq(Draw.alive(bracket, first.a), true, "the winner goes on")
  T.eq(Draw.matchFor(bracket, first.a), nil,
    "with nothing left to play this round")

  T.eq(Draw.alive(bracket, "somebody-else"), false,
    "somebody who never entered is not alive")
end

-- ------- the draw refuses nonsense

do
  T.eq(pcall(Draw.build, { { id = "a" } }, 1), false,
    "a one-entrant cup is refused")
  T.eq(pcall(Draw.build, { { id = "a" }, { id = "a" } }, 1), false,
    "a duplicated entrant is refused")
  T.eq(pcall(Draw.build, { { id = "a" }, { name = "no id" } }, 1), false,
    "an entrant with no id is refused")
  T.eq(pcall(Draw.build, { { id = "a" }, { id = Draw.BYE } }, 1), false,
    "and nobody may enter under the bye's name")
end

-- ------- strength

do
  T.eq(Strength.of({}), 1, "an empty party still has a strength")
  local one = Strength.of({ { level = 20 } })
  local two = Strength.of({ { level = 20 }, { level = 20 } })
  T.check(two > one, "a second mon is worth having")

  T.eq(Strength.of({ { level = 50 } }, 15), Strength.of({ { level = 15 } }, 15),
    "a cap really caps: a Lv50 lead counts as the cap")

  local six = {}
  for i = 1, 8 do six[i] = { level = 10 } end
  T.eq(Strength.of(six), Strength.of({ { level = 10 }, { level = 10 },
    { level = 10 }, { level = 10 }, { level = 10 }, { level = 10 } }),
    "and only the first six count")
end

do
  local a = { id = "a", strength = 100 }
  local b = { id = "b", strength = 10 }
  local wins = { a = 0, b = 0 }
  local seed = 12345
  for _ = 1, 400 do
    local winner
    winner, seed = Strength.resolve(a, b, seed)
    wins[winner] = wins[winner] + 1
  end
  T.check(wins.a > wins.b, "the stronger party wins more often")
  T.check(wins.b > 0, "but an upset is possible")
  T.check(wins.b < wins.a, "and never the norm")

  -- deterministic
  local w1 = Strength.resolve(a, b, 999)
  local w2 = Strength.resolve(a, b, 999)
  T.eq(w1, w2, "the same seed resolves the same match the same way")

  -- an equal match is close to even, and never one-sided
  local even = { a = 0, b = 0 }
  seed = 4242
  local c = { id = "a", strength = 50 }
  local d = { id = "b", strength = 50 }
  for _ = 1, 400 do
    local winner
    winner, seed = Strength.resolve(c, d, seed)
    even[winner] = even[winner] + 1
  end
  T.check(even.a > 120 and even.b > 120,
    ("an even match is close to even (%d/%d)"):format(even.a, even.b))

  -- a total mismatch still leaves the upset window open
  local mismatch = { a = 0, b = 0 }
  seed = 777
  local e = { id = "a", strength = 9999 }
  local f = { id = "b", strength = 1 }
  for _ = 1, 400 do
    local winner
    winner, seed = Strength.resolve(e, f, seed)
    mismatch[winner] = mismatch[winner] + 1
  end
  T.check(mismatch.b > 0,
    "even a hopeless entrant can win one (" .. mismatch.b .. ")")
  T.check(mismatch.a > mismatch.b * 2, "but is still a heavy underdog")
end

-- ------- the cup table

do
  T.eq(#Cups.LIST, 3, "three cups on the circuit")
  local seen = {}
  for _, cup in ipairs(Cups.LIST) do
    T.eq(seen[cup.id], nil, "no cup id is repeated: " .. cup.id)
    seen[cup.id] = true
    T.check(cup.cap > 0, cup.id .. " has a level cap")
    T.check(cup.fee >= 0, cup.id .. " has a fee")
    T.check(cup.prize > cup.fee, cup.id .. " pays more than it costs")
    T.check(cup.field >= 2, cup.id .. " has a field")
    T.check(#cup.short <= 8,
      cup.id .. "'s menu label fits the row budget (" .. cup.short .. ")")
    T.eq(Cups.get(cup.id), cup, "and is reachable by id")
  end
  T.eq(Cups.get("nope"), nil, "an unknown cup id answers nil")

  -- the tiers really are a ladder
  for i = 2, #Cups.LIST do
    T.check(Cups.LIST[i].cap > Cups.LIST[i - 1].cap, "caps climb at " .. i)
    T.check(Cups.LIST[i].fee > Cups.LIST[i - 1].fee, "fees climb at " .. i)
    T.check(Cups.LIST[i].badges >= Cups.LIST[i - 1].badges,
      "badge gates climb at " .. i)
  end
end

-- ------- the house field

do
  T.eq(#Cups.HOUSE, 8, "the house can field a whole cup on its own")
  local members = {}
  for _, entry in ipairs(Cups.HOUSE) do
    T.eq(members[entry.member], nil, "house members are unique")
    members[entry.member] = true
    T.check(#entry.species > 0, entry.name .. " brings a team")
    T.check(#entry.name <= 8, entry.name .. " fits a menu row")
  end

  for _, cup in ipairs(Cups.LIST) do
    for _, entry in ipairs(Cups.HOUSE) do
      local party = Cups.houseParty(entry, cup.cap)
      T.eq(#party, #entry.species, entry.name .. " fields their whole team")
      for _, mon in ipairs(party) do
        T.check(mon.level >= 2, "nobody enters below level 2")
        T.check(mon.level <= cup.cap,
          ("%s is inside the %s cap (%d <= %d)")
            :format(entry.name, cup.id, mon.level, cup.cap))
      end
      T.check(party[1].level >= party[#party].level,
        entry.name .. " leads with their best")
    end
  end

  T.eq(Cups.houseEntrant(99), nil, "an unknown house member answers nil")
  T.eq(#Cups.houseField(15), 8, "the house field is eight strong")
end

-- ------- the field builder

do
  local cup = Cups.get("rookie")
  local field = Field.build(cup, { playerParty = { { level = 10 } } })
  T.eq(#field, cup.field, "with no rivals the house fills the cup")
  T.eq(field[1].id, Field.PLAYER, "and the player is always in it")
  T.eq(field[1].you, true, "flagged as the player")
  for _, entrant in ipairs(field) do
    T.check(entrant.strength and entrant.strength > 0,
      entrant.id .. " arrives with a strength")
  end
end

do
  local cup = Cups.get("rookie")
  local rivals = {}
  for i = 1, 20 do
    rivals[i] = { id = "r" .. i, name = "R" .. i,
                  party = { { level = i * 3 } } }
  end
  local field = Field.build(cup, { rivals = rivals,
    playerParty = { { level = 12 } } })
  T.eq(#field, 8, "a full rival cast still fields exactly eight")

  local ids = {}
  for _, entrant in ipairs(field) do
    T.eq(ids[entrant.id], nil, "no entrant is drawn twice: " .. entrant.id)
    ids[entrant.id] = true
  end

  -- the rookie cup takes the rivals nearest ITS cap, not the strongest ones
  T.eq(ids["rival:r5"], true, "the Lv15 rival is in the rookie cup")
  T.eq(ids["rival:r20"], nil, "and the Lv60 one is not")

  local master = Field.build(Cups.get("master"), { rivals = rivals,
    playerParty = { { level = 40 } } })
  local masterIds = {}
  for _, entrant in ipairs(master) do masterIds[entrant.id] = true end
  T.eq(masterIds["rival:r17"], true, "the master cup fields the Lv51 rival")
  T.check(masterIds["rival:r5"] ~= true,
    "and leaves the rookie-cup rival at home")
end

do
  -- the same inputs build the same field, in the same order
  local cup = Cups.get("open")
  local rivals = { { id = "b", name = "B", party = { { level = 30 } } },
                   { id = "a", name = "A", party = { { level = 30 } } } }
  local one = Field.build(cup, { rivals = rivals })
  local two = Field.build(cup, { rivals = rivals })
  for i, entrant in ipairs(one) do
    T.eq(two[i].id, entrant.id, "field order is stable at slot " .. i)
  end
  T.eq(one[2].id, "rival:a", "ties break by id, so the order never drifts")

  -- a rival calling itself the player cannot displace the player
  local sneaky = Field.build(cup, { rivals = { { id = Field.PLAYER } } })
  T.eq(sneaky[1].id, Field.PLAYER, "the player holds slot one")
  T.eq(sneaky[1].you, true, "and it is really the player")
end

do
  -- a rival with no party is not a fit for any cup, but must not crash
  local field = Field.build(Cups.get("rookie"), {
    rivals = { { id = "empty", name = "EMPTY" } } })
  T.eq(#field, 8, "a party-less rival still leaves a full field")
  T.eq(Field.fit({ party = {} }, 15), math.huge,
    "and is ranked as no fit at all")
end

-- ------- a whole cup, end to end, the way the mod plays one

do
  local cup = Cups.get("rookie")
  local rivals = {}
  for i = 1, 10 do
    rivals[i] = { id = "r" .. i, name = "R" .. i,
                  party = { { level = 12 + i } } }
  end
  local field = Field.build(cup, { rivals = rivals,
    playerParty = { { level = 15 }, { level = 14 } } })
  local bracket = Draw.build(field, 20260817)
  local seed = bracket.seed

  local rounds = 0
  while not bracket.done and rounds < 10 do
    -- the player wins their own match; everybody else rolls for it
    local index = Draw.matchFor(bracket, Field.PLAYER)
    if index then Draw.settle(bracket, index, Field.PLAYER) end
    Draw.settleRound(bracket, function(match)
      local a = { id = match.a, strength = bracket.entrants[match.a].strength }
      local b = { id = match.b, strength = bracket.entrants[match.b].strength }
      local winner
      winner, seed = Strength.resolve(a, b, seed)
      return winner
    end)
    Draw.advance(bracket)
    rounds = rounds + 1
  end
  T.eq(bracket.done, true, "the cup finishes")
  T.eq(bracket.champion, Field.PLAYER,
    "a player who wins every match wins the cup")
  T.eq(Draw.standings(bracket)[1].name, "YOU", "and tops the standings")
end

do
  -- and the same cup where the player loses the first match
  local field = Field.build(Cups.get("rookie"), {})
  local bracket = Draw.build(field, 555)
  local seed = bracket.seed
  local index, _, opponent = Draw.matchFor(bracket, Field.PLAYER)
  Draw.settle(bracket, index, opponent)
  T.eq(Draw.eliminated(bracket, Field.PLAYER), true, "the player is out")

  local rounds = 0
  while not bracket.done and rounds < 10 do
    Draw.settleRound(bracket, function(match)
      local a = { id = match.a, strength = bracket.entrants[match.a].strength }
      local b = { id = match.b, strength = bracket.entrants[match.b].strength }
      local winner
      winner, seed = Strength.resolve(a, b, seed)
      return winner
    end)
    Draw.advance(bracket)
    rounds = rounds + 1
  end
  T.eq(bracket.done, true, "the cup still plays itself out without them")
  T.check(bracket.champion ~= Field.PLAYER,
    "and somebody else lifts the trophy")
  T.check(bracket.champion ~= nil, "somebody really does")
end

-- ------- a soak: every seed produces a cup that finishes and places everyone

do
  for seed = 1, 500 do
    local field = Field.build(Cups.get("open"), {})
    local bracket = Draw.build(field, seed)
    local roll = bracket.seed
    local guard = 0
    while not bracket.done and guard < 12 do
      Draw.settleRound(bracket, function(match)
        local a = { id = match.a,
                    strength = bracket.entrants[match.a].strength }
        local b = { id = match.b,
                    strength = bracket.entrants[match.b].strength }
        local winner
        winner, roll = Strength.resolve(a, b, roll)
        return winner
      end)
      Draw.advance(bracket)
      guard = guard + 1
    end
    T.eq(bracket.done, true, "cup " .. seed .. " finished")
    T.check(bracket.champion ~= nil, "cup " .. seed .. " has a champion")
    T.eq(#Draw.standings(bracket), 8, "cup " .. seed .. " placed everybody")
  end
end

T.finish("showa_tournaments rules")
