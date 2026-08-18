-- Showa Tournaments: the National Park cup circuit.
--
-- A folding table on the park lawn, a hand-lettered bracket board, and three
-- cups a year.  Enter at the registrar, then talk to the referee to play your
-- match; the other matches in your round are settled while you play yours,
-- and the bracket rolls over when the round is done.
--
-- THE BATTLE SEAM.  This is the first Showa mod that starts a real trainer
-- battle, and it does it the only way Gold allows: a mod's row list may carry
-- NATIVE VM rows next to its own verbs, so the referee's script is
--
--   { "showa_tournaments:call" }        -- our verb; ends the list if no match
--   { op = "loadtrainer", class = N, member = M }
--   { op = "startbattle" }
--   { "showa_tournaments:result" }      -- reads ctx.vm.battleOutcome
--   { op = "reloadmapafterbattle" }
--
-- Three things about that are easy to get wrong and cost a debugging cycle
-- each, so they are written down here as well as in the handover:
--
--   * The rows carrying `op` are NOT the Gen 1 { "name", args } shape.
--     runList normalises any row without an `op` whose [1] is a string into a
--     MOD COMMAND, so { "loadtrainer", 130, 1 } is read as a verb named
--     "loadtrainer" and quietly does nothing.
--   * `loadtrainer` addresses a class by NUMBER.  The class this mod fights
--     changes per match, so the row is rewritten in place by the verb in
--     front of it -- this mod owns that table, and the VM reads cmd.class at
--     the moment it runs the row.
--   * `reloadmapafterbattle` ENDS the script on a loss (it is the whiteout
--     jump), so the result verb goes BEFORE it or a defeat is never recorded.
local Draw = require("mods.showa_tournaments.bracket.draw")
local Strength = require("mods.showa_tournaments.bracket.strength")
local Cups = require("mods.showa_tournaments.cups.list")
local Field = require("mods.showa_tournaments.cups.field")
local Rng = require("mods.showa_tournaments.bracket.rng")
local Menu = require("mods.showa_tournaments.desk.menu")

local PARK = "NATIONAL_PARK"
-- Verified free against the map's collision, objects, bgEvents and warps,
-- each with a free walkable cell directly south so the player can always
-- stand in front and press A.
local REGISTRAR_AT = { x = 13, y = 44 }
local REFEREE_AT = { x = 15, y = 44 }

local SCREEN = "ShowaCupDesk"

-- charmap.asm's currency glyph, the one MartMenu prices with.  Gold's font
-- has no "$" at all -- it drops the character and logs a missing glyph.
local YEN = "\xc2\xa5"

return function(mod)
  local core = assert(mod.find("showa_core"),
    "showa_tournaments needs showa_core").exports

  local function rivalsMod()
    local other = mod.find("showa_rivals")
    return other and other.exports or nil
  end

  -- ------- persistent state

  local state = mod.save:get("state")
  if type(state) ~= "table" or state.v ~= 1 then
    state = { v = 1, cup = nil, records = {}, trophies = {} }
  end
  local function persist() mod.save:set("state", state) end
  persist()

  core.venues.register("CUP_GROUNDS", {
    map = PARK, label = "CUP GROUNDS", tags = { "contest", "tournament" },
    x = REGISTRAR_AT.x, y = REGISTRAR_AT.y,
  })

  -- ------- the house field's trainer class
  --
  -- One class with eight members, not eight classes: `loadtrainer class,
  -- member` is built for exactly this and eight classes would spend eight
  -- index slots saying the same thing.

  local houseIndex = assert(core.trainers.claim("showa_tournaments",
    Cups.HOUSE_CLASS))

  local houseRows = {}
  for _, entry in ipairs(Cups.HOUSE) do
    houseRows[entry.member] = {
      name = entry.name,
      -- a placeholder roster; the real one is written per match at the cup's
      -- own cap, which is the whole point of a capped cup
      party = Cups.houseParty(entry, 15),
    }
  end
  mod.content.trainers:register(Cups.HOUSE_CLASS, {
    name = "CUP ENTRANT",
    index = houseIndex,
    baseMoney = 14,
    trainers = houseRows,
  })

  -- Without a portrait the battle intro opens on an empty plinth: a class
  -- the extractor never saw has no menu_gfx.battleHud.trainerPics entry.
  -- showa_core reads the art out of the player's OWN cache table for a
  -- vanilla class -- a path written here would be a mod shipping a
  -- reference to ROM-derived art.  Needs the live game, so it hangs on
  -- game.ready rather than on the registration above.
  local function dressHouse()
    core.trainers.setPic(Cups.HOUSE_CLASS, "SCHOOLBOY")
  end
  mod.events:on("game.ready", dressHouse)
  dressHouse()

  -- ------- reading the live cup

  local function cup()
    return state.cup and Cups.get(state.cup.cupId) or nil
  end

  local function bracket()
    return state.cup and state.cup.bracket or nil
  end

  local function partyOf(entrantId)
    local entrant = bracket() and bracket().entrants[entrantId]
    if not entrant then return {} end
    if entrant.house then
      local entry = Cups.houseEntrant(entrant.house)
      return entry and Cups.houseParty(entry, cup().cap) or {}
    end
    if entrant.rival then
      local rivals = rivalsMod()
      local card = rivals and rivals.battleCard(entrant.rival)
      return card and card.party or {}
    end
    local save = mod.game and mod.game.save
    return (save and save.party) or {}
  end

  -- ------- entering

  local function playerParty()
    local save = mod.game and mod.game.save
    return (save and save.party) or {}
  end

  local function badgeCount()
    local save = mod.game and mod.game.save
    local badges = save and (save.badges or (save.player and save.player.badges))
    if type(badges) == "number" then return badges end
    local n = 0
    for _, has in pairs(badges or {}) do if has then n = n + 1 end end
    return n
  end

  -- The cup caps its OPPONENTS by building their rosters at the cap.  It
  -- cannot cap the player the same way without rewriting mons in the save, so
  -- it does what a real registrar does instead and turns an over-levelled
  -- entrant away at the table.
  local function overCap(cap)
    for _, mon in ipairs(playerParty()) do
      if (mon.level or 0) > cap then return mon end
    end
    return nil
  end

  local function canEnter(cupDef)
    if state.cup then return false, "you are already in a cup" end
    local party = playerParty()
    if #party == 0 then return false, "you have no POKEMON" end
    if badgeCount() < (cupDef.badges or 0) then
      return false, ("%d badges needed"):format(cupDef.badges)
    end
    local over = overCap(cupDef.cap)
    if over then
      return false, ("%s is over Lv%d"):format(tostring(over.species or "a mon"),
        cupDef.cap)
    end
    local save = mod.game and mod.game.save
    local money = (save and save.player and save.player.money) or 0
    if money < cupDef.fee then
      return false, ("the fee is " .. YEN .. "%d"):format(cupDef.fee)
    end
    return true
  end

  local function rivalField()
    local rivals = rivalsMod()
    if not rivals then return {} end
    local out = {}
    for _, entry in ipairs(rivals.roster()) do
      out[#out + 1] = { id = entry.id, name = entry.name,
                        party = entry.party or {} }
    end
    return out
  end

  local function enter(cupId)
    local cupDef = Cups.get(cupId)
    if not cupDef then return false, "no such cup" end
    local ok, why = canEnter(cupDef)
    if not ok then return false, why end

    local save = mod.game.save
    save.player.money = save.player.money - cupDef.fee

    local entrants = Field.build(cupDef, {
      rivals = rivalField(), playerParty = playerParty(),
    })
    -- The parties are what STRENGTH was computed from; they are not kept in
    -- the save.  A rival's team keeps changing while the cup runs and the
    -- house field is a formula, so both are re-derived when a match needs
    -- them (partyOf) rather than frozen into a stale copy.
    for _, entrant in ipairs(entrants) do entrant.party = nil end

    local seed = (core.clock.today() or 0) * 7919
      + (save.player.money or 0) + #entrants
    state.cup = {
      cupId = cupId,
      bracket = Draw.build(entrants, seed),
      played = 0,
    }
    persist()
    core.news.post(("The %s draw is up at NATIONAL PARK."):format(cupDef.label))
    return true
  end

  -- ------- settling the matches the player is not in

  local function resolveOne(match, aId, bId, seed)
    local a = { id = aId, strength = bracket().entrants[aId].strength }
    local b = { id = bId, strength = bracket().entrants[bId].strength }
    local winner
    winner, seed = Strength.resolve(a, b, seed)
    return winner, seed
  end

  local function settleOthers()
    local live = state.cup
    if not live then return 0 end
    local seed = live.bracket.seed
    local settled = Draw.settleRound(live.bracket, function(match, aId, bId)
      local winner
      winner, seed = resolveOne(match, aId, bId, seed)
      return winner
    end, Field.PLAYER)
    live.bracket.seed = seed
    return settled
  end

  -- Run the cup forward while the player has nothing to play: byes, rounds
  -- they are not in, and -- once they are out -- the rest of the cup.
  local function runOn()
    local live = state.cup
    if not live then return end
    for _ = 1, 8 do
      settleOthers()
      if Draw.roundComplete(live.bracket) then
        if not Draw.advance(live.bracket) then break end
        if live.bracket.done then break end
      else
        break
      end
    end
    persist()
  end

  -- ------- prizes

  local function finish()
    local live = state.cup
    local cupDef = cup()
    if not (live and cupDef and live.bracket.done) then return nil end
    local standings = Draw.standings(live.bracket)
    local champion = live.bracket.champion
    local record = state.records[live.cupId] or { entered = 0, won = 0 }
    record.entered = record.entered + 1

    local note
    if champion == Field.PLAYER then
      record.won = record.won + 1
      state.trophies[cupDef.trophy] = (state.trophies[cupDef.trophy] or 0) + 1
      local save = mod.game and mod.game.save
      if save and save.player then
        save.player.money = (save.player.money or 0) + cupDef.prize
      end
      core.news.post(("The %s went to the challenger from NEW BARK.")
        :format(cupDef.label))
      note = ("You won the %s!\nPrize: " .. YEN .. "%d")
        :format(cupDef.label, cupDef.prize)
    else
      local name = champion and live.bracket.entrants[champion]
        and live.bracket.entrants[champion].name or "nobody"
      core.news.post(("%s won the %s."):format(name, cupDef.label))
      note = ("%s won the %s."):format(name, cupDef.label)
    end
    state.records[live.cupId] = record
    state.cup = nil
    persist()
    return note, standings
  end

  -- ------- the referee's row list
  --
  -- ONE table, reused every match and rewritten in place before the VM walks
  -- it.  See the header: the class a `loadtrainer` row names is read when the
  -- row runs, so this is how a fixed script fights a different opponent each
  -- time.

  local matchRows = {
    { "showa_tournaments:call" },
    { op = "loadtrainer", class = houseIndex, member = 1 },
    { op = "startbattle" },
    { "showa_tournaments:result" },
    { op = "reloadmapafterbattle" },
  }

  -- what the current match is against, set by `call` and read by `result`
  local pending = nil

  local function say(ctx, text)
    return core.dialogue.say(ctx, text)
  end

  -- Stand the opponent's roster up at the cup's cap, and answer the class +
  -- member `loadtrainer` needs.
  local function armOpponent(entrantId)
    local live = state.cup
    local cupDef = cup()
    local entrant = live and live.bracket.entrants[entrantId]
    if not (entrant and cupDef) then return nil end

    if entrant.rival then
      local rivals = rivalsMod()
      local card = rivals and rivals.battleCard(entrant.rival)
      if not card then return nil end
      rivals.syncParty(entrant.rival, { cap = cupDef.cap })
      return { class = card.index, member = 1, name = card.name,
               rival = entrant.rival, lines = card.lines }
    end

    local entry = Cups.houseEntrant(entrant.house)
    if not entry then return nil end
    core.trainers.setParty(Cups.HOUSE_CLASS, entry.member,
      core.trainers.rows(Cups.houseParty(entry, cupDef.cap),
        { cap = cupDef.cap }))
    return { class = houseIndex, member = entry.member, name = entry.name }
  end

  -- Put a rival's real team back.  The class record is shared with every
  -- other battle in the game, so a capped roster left standing would follow
  -- them out of the park.
  local function disarm()
    if pending and pending.rival then
      local rivals = rivalsMod()
      if rivals then rivals.syncParty(pending.rival) end
    end
  end

  mod.content.commands:register("showa_tournaments:call", function(ctx)
    pending = nil
    local live = state.cup
    if not live then
      say(ctx, "No cup is running.\nEnter at the desk first!")
      return "end"
    end
    local cupDef = cup()
    if live.bracket.done then
      say(ctx, "That cup is over.\nSee the desk for the result.")
      return "end"
    end
    if Draw.eliminated(live.bracket, Field.PLAYER) then
      say(ctx, "You are out of this one.\nStay and watch the final!")
      return "end"
    end
    local index, _, opponentId = Draw.matchFor(live.bracket, Field.PLAYER)
    if not index then
      say(ctx, "Your match is not up yet.\nThe board is at the desk.")
      return "end"
    end
    if opponentId == Draw.BYE then
      Draw.settle(live.bracket, index, Field.PLAYER)
      runOn()
      say(ctx, "You have a bye this round.\nRest up -- you are through!")
      return "end"
    end

    local armed = armOpponent(opponentId)
    if not armed then
      say(ctx, "Your opponent has not\nshown up. Try again shortly.")
      return "end"
    end
    pending = { entrantId = opponentId, matchIndex = index,
                rival = armed.rival, name = armed.name }

    -- rewrite the loadtrainer row in front of the battle
    matchRows[2].class = armed.class
    matchRows[2].member = armed.member

    say(ctx, ("%s -- %s!\n%s, you are up.")
      :format(cupDef.short, Draw.roundName(live.bracket), armed.name))
    -- no "end": the rows after this one are the battle
  end)

  mod.content.commands:register("showa_tournaments:result", function(ctx)
    local live = state.cup
    if not (live and pending) then return end
    -- "win" / "lose" / "draw", parked by `startbattle` when it resumed
    local outcome = ctx.vm and ctx.vm.battleOutcome
    local won = outcome ~= "lose"
    disarm()

    Draw.settle(live.bracket, pending.matchIndex,
      won and Field.PLAYER or pending.entrantId)
    live.played = (live.played or 0) + 1
    local rivals = rivalsMod()
    if rivals and pending.rival then
      rivals.recordBattle(pending.rival, won)
    end
    local beaten = pending.name
    pending = nil
    runOn()

    if not won then
      -- A loss IS a whiteout on Gold, and the row after this one is the jump
      -- that performs it -- so say nothing here and let the registrar break
      -- the news next time the player comes back to the lawn.
      persist()
      return
    end

    local note = finish()
    if note then
      say(ctx, note)
    else
      say(ctx, ("You beat %s!\n%s next."):format(beaten,
        Draw.roundName(live.bracket)))
    end
    persist()
  end)

  -- ------- the registrar's desk

  -- The rows themselves live in desk/menu.lua as pure data; this is the
  -- reading of the live state that feeds it.
  local function deskContext()
    local live = state.cup
    local ctx = { yen = YEN, records = state.records }
    if live then
      ctx.running = { short = cup().short }
      ctx.board = {}
      for _, match in ipairs(Draw.currentRound(live.bracket)) do
        local a = live.bracket.entrants[match.a]
        local b = live.bracket.entrants[match.b]
        local mark = "v"
        if match.winner then
          mark = (match.winner == match.a) and "<" or ">"
        end
        ctx.board[#ctx.board + 1] = {
          a = a and a.name or "BYE", b = b and b.name or "BYE", mark = mark }
      end
    else
      ctx.unlocked = {}
      for _, cupDef in ipairs(Cups.LIST) do
        ctx.unlocked[cupDef.id] = select(1, canEnter(cupDef)) and true or false
      end
    end
    return ctx
  end

  local function openDesk(game, page, note)
    page = page or "desk"
    local build = Menu.PAGES[page] or Menu.desk
    local items = {}
    for _, row in ipairs(build(deskContext())) do
      items[#items + 1] = { label = row.label, right = row.right, value = row }
    end
    return mod.ui.ListMenu.new(game, Menu.TITLES[page] or "SHOWA CUP", items, {
      wrap = true, footer = note,
      onChoose = function(item, menu)
        local row = item.value
        local id = row.id or ""
        if id == "close" then menu:close(); return end
        if id == "back" then
          menu:close()
          mod.ui.push(game, SCREEN, { page = "desk" })
          return
        end
        if id == "board" or id == "records" then
          menu:close()
          mod.ui.push(game, SCREEN, { page = id })
          return
        end
        local cupId = id:match("^enter:(.+)$")
        if cupId then
          local ok, why = enter(cupId)
          menu:close()
          mod.ui.push(game, SCREEN, { page = "desk",
            note = ok and "you are entered!" or why })
          return
        end
        if id == "withdraw" then
          state.cup = nil
          persist()
          menu:close()
          mod.ui.push(game, SCREEN, { page = "desk", note = "withdrawn" })
          return
        end
      end,
      -- onCancel takes NO arguments and runs AFTER ListMenu has already
      -- popped itself (src/ui/ListMenu.lua:168).  Closing again here is an
      -- index of nil, which is a crash on the B button.
      onCancel = function()
        if page ~= "desk" then mod.ui.push(game, SCREEN, { page = "desk" }) end
      end,
    })
  end

  mod.content.screens:register(SCREEN, {
    new = function(game, opts)
      opts = opts or {}
      return openDesk(game, opts.page, opts.note)
    end,
  })

  mod.content.commands:register("showa_tournaments:desk", function(ctx)
    local live = state.cup
    -- A player who lost their match walked away mid-cup with nothing said
    -- (the loss was a whiteout).  This is where they hear about it.
    if live and Draw.eliminated(live.bracket, Field.PLAYER)
      and not live.toldOut then
      live.toldOut = true
      runOn()
      local note = finish()
      say(ctx, note and ("You went out early.\n" .. note)
        or "You went out this round.\nBetter luck in the next cup!")
      persist()
      return "end"
    end
    local ok = pcall(function()
      mod.ui.push(mod.game, SCREEN, { page = "desk" })
    end)
    if not ok then
      say(ctx, "The SHOWA CUP desk is\nclosed right now.")
    end
    return "end"
  end)

  -- ------- the two NPCs on the lawn

  local CAST = {
    registrar = { sprite = "SPRITE_POKEFAN_M", x = REGISTRAR_AT.x,
      y = REGISTRAR_AT.y, movement = 6, radius = { x = 0, y = 0 },
      hours = { -1, -1 }, scriptKey = { { "showa_tournaments:desk" } } },
    referee = { sprite = "SPRITE_TEACHER", x = REFEREE_AT.x, y = REFEREE_AT.y,
      movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
      scriptKey = matchRows },
  }

  -- spawnNpc answers nil (not an error) until the overworld is live, so
  -- track what actually landed and retry rather than latching on one miss
  local spawnedIds = {}
  local function spawnCast()
    for key, def in pairs(CAST) do
      if not spawnedIds[key] then
        local ok, id = pcall(function()
          return mod.world:spawnNpc(PARK, def)
        end)
        if ok and id then spawnedIds[key] = id end
      end
    end
  end
  mod.events:on("game.ready", spawnCast)
  mod.events:on("map.entered", function() spawnCast() end)

  -- ------- exports

  mod.exports.cups = function() return Cups.LIST end
  mod.exports.current = function()
    local live = state.cup
    if not live then return nil end
    return {
      cupId = live.cupId, round = live.bracket.round,
      done = live.bracket.done, champion = live.bracket.champion,
      alive = Draw.alive(live.bracket, Field.PLAYER),
      standings = Draw.standings(live.bracket),
    }
  end
  mod.exports.records = function()
    local out = {}
    for id, record in pairs(state.records) do
      out[id] = { entered = record.entered, won = record.won }
    end
    return out
  end
  mod.exports.debug = {
    enter = enter,
    -- hangs on game.ready in play; callable so a suite with a stub game can
    -- drive the real thing rather than assert around it
    dress = dressHouse,
    -- settle the player's match without fighting it, for drivers
    play = function(won)
      local live = state.cup
      if not live then return "no cup" end
      local index, _, opponentId = Draw.matchFor(live.bracket, Field.PLAYER)
      if not index then return "no match" end
      if opponentId == Draw.BYE then
        Draw.settle(live.bracket, index, Field.PLAYER)
      else
        Draw.settle(live.bracket, index,
          won ~= false and Field.PLAYER or opponentId)
      end
      runOn()
      local note = finish()
      persist()
      return note or ("round " .. tostring(live.bracket.round))
    end,
    arm = function()
      local live = state.cup
      if not live then return nil end
      local index, _, opponentId = Draw.matchFor(live.bracket, Field.PLAYER)
      if not (index and opponentId and opponentId ~= Draw.BYE) then return nil end
      local armed = armOpponent(opponentId)
      if armed then
        matchRows[2].class = armed.class
        matchRows[2].member = armed.member
        pending = { entrantId = opponentId, matchIndex = index,
                    rival = armed.rival, name = armed.name }
      end
      return armed
    end,
    rows = matchRows,
    abandon = function() state.cup = nil; persist() end,
    -- one cell south of whichever of the two you want to talk to, facing them
    warp = function(who)
      local at = (who == "referee") and REFEREE_AT or REGISTRAR_AT
      return mod.world:warpTo(PARK, at.x, at.y + 1, "up")
    end,
    at = function(who)
      return (who == "referee") and REFEREE_AT or REGISTRAR_AT
    end,
    spawned = function()
      local n = 0
      for _ in pairs(spawnedIds) do n = n + 1 end
      return n
    end,
    houseIndex = function() return houseIndex end,
    seedRoll = function(seed, n) return Rng.below(seed, n) end,
  }
end
