-- Driver: a party on a real Gold boot.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=party_driver POKEPORT_NO_DISCORD=1 \
--     SHOT_DIR=shots POKEPORT_DRIVER=mods/showa_parties/tests/party_driver.lua \
--     lovec.exe .
--
-- Walks in, reads the host's clipboard, swaps an item with a swapper, trades
-- a POKEMON with a trader, and fights a battler -- the three things a party
-- is for, each through the path a player would take.  Everything anybody says
-- is shot, because a green suite proves state and never pixels.
local U = dofile("tests/drivers/util.lua")
local Mon = require("src.battle.gen2.Mon")

return function(game)
  local DIR = os.getenv("SHOT_DIR")
  local failures = 0
  local function check(cond, msg)
    U.log(cond and "ok  " or "FAIL", msg)
    if not cond then failures = failures + 1 end
  end
  local function shot(name)
    if DIR then U.shot(game, DIR .. "/" .. name) end
  end

  U.wait(45)

  local e = game.mods and game.mods.exports or {}
  local core, parties = e.showa_core, e.showa_parties
  check(core ~= nil, "showa_core loaded")
  check(parties ~= nil, "showa_parties loaded")
  if not (core and parties) then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end

  local function clearVm()
    for _ = 1, 240 do
      if not (game.world.vm and game.world.vm.busy) then return true end
      U.tap(game, "a")
      U.wait(6)
    end
    return false
  end

  -- ------- there is a party on, and we know who is at it

  local party = parties.today()
  check(party ~= nil, "there is a party today")
  if not party then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end
  U.log("     party:", ("%s at %s, %d guests")
    :format(tostring(party.label), tostring(party.venue), party.guests))

  local guests = parties.guests()
  check(#guests == party.guests, "the guest list is the whole guest list")
  local byRole = {}
  for _, guest in ipairs(guests) do byRole[guest.role] = guest end
  check(byRole.swapper ~= nil, "a swapper is here")
  check(byRole.trader ~= nil, "a trader is here")
  check(byRole.battler ~= nil, "a battler is here")

  -- ------- a party the player can actually take part in

  -- A guest's team scales to the player's BEST mon, so a higher level does
  -- not make the match easier -- it just raises both sides.  What wins is
  -- SPECIES: a fully evolved starter against the common-or-garden mons a
  -- neighbour brings to a party is the edge that lets this run finish.
  local lead = Mon.new(game.data, "TYPHLOSION", 45)
  local spare = byRole.trader
    and Mon.new(game.data, byRole.trader.wantsMon, 18)
  check(lead ~= nil and #lead.moves > 0, "built a L45 TYPHLOSION with moves")
  check(spare ~= nil, "and the mon the trader is after ("
    .. tostring(byRole.trader and byRole.trader.wantsMon) .. ")")
  game.save.party = { lead, spare }
  game.save.player = game.save.player or {}
  game.save.player.money = 20000
  game.save.inventory = game.save.inventory or {}
  if byRole.swapper then
    game.save.inventory[byRole.swapper.wants] = 3
  end

  -- ------- walk in

  local ok = parties.debug.warp()
  check(ok ~= false, "warped to the party (" .. tostring(parties.debug.note())
    .. ")")
  U.wait(80)
  parties.debug.refresh()
  U.wait(30)
  local spawned = parties.debug.spawned()
  check(spawned >= party.guests, ("everybody turned up (%d of %d + host)")
    :format(spawned, party.guests))
  shot("60-the-party.png")

  -- ------- the host's clipboard

  local venue = core.venues.get(party.venue)
  check(venue ~= nil, "the party venue is a real venue")

  -- Face the HOST, by the cell the mod reports rather than by warping near
  -- the venue and pressing A: the first version of this run talked to the
  -- mall's own greeter ("Lots of POKEMON") and counted it as a pass.
  local hostCell = parties.debug.cells().host
  check(hostCell ~= nil, "the host is standing somewhere ("
    .. (hostCell and (hostCell.x .. "," .. hostCell.y) or "?") .. ")")
  check(parties.debug.face("host") ~= false, "warped to face the host")
  U.wait(70)
  clearVm()
  local top = game.stack:top()
  U.tap(game, "a")
  U.wait(50)
  local opened = game.stack:top() ~= top
  check(opened, "the host opened the party menu, not a vanilla NPC's line")
  shot("61-host.png")
  U.tap(game, "b")
  U.wait(25)
  clearVm()

  -- ------- the item swap, through the verb the guest runs

  if byRole.swapper then
    local before = game.save.inventory[byRole.swapper.wants] or 0
    local gained = game.save.inventory[byRole.swapper.offers] or 0
    local swap = parties.debug.swap(byRole.swapper.index)
    check(swap ~= nil, "the swapper took the deal")
    check((game.save.inventory[byRole.swapper.wants] or 0) == before - 1,
      "one of what they wanted left the bag")
    check((game.save.inventory[byRole.swapper.offers] or 0) == gained + 1,
      "and one of what they offered arrived")
  end

  -- ------- the POKEMON trade, for real

  if byRole.trader then
    local wanted = byRole.trader.wantsMon
    local offered = byRole.trader.offersMon
    local note = parties.debug.trade(byRole.trader.index)
    U.log("     trade:", tostring(note))
    check(note ~= nil and note:find(offered) ~= nil,
      "the trade went through (" .. tostring(note) .. ")")

    local got, gone = nil, true
    for _, mon in ipairs(game.save.party) do
      if mon.species == offered then got = mon end
      if mon.species == wanted then gone = false end
    end
    check(got ~= nil, "the traded-for " .. offered .. " is in the party")
    check(gone, "and the " .. wanted .. " really left")
    if got then
      check(got.level == 18, "it kept the level of the one handed over ("
        .. tostring(got.level) .. ")")
      check(got.maxHp and got.maxHp > 0, "with stats for its own species")
      check(#(got.moves or {}) > 0, "and moves it can actually use")
      check(game.save.pokedex and game.save.pokedex.caught[offered] == true,
        "and it was ticked off in the #DEX")
    end
    -- and not twice
    local again = parties.debug.trade(byRole.trader.index)
    check(again == nil or again:find("already") ~= nil,
      "a guest already traded with will not trade again ("
        .. tostring(again) .. ")")
  end

  -- ------- the friendly battle

  if byRole.battler then
    -- Down to ONE mon before the match.  A guest's team scales to the
    -- player's best, so the fight is always level-even and a faint opens the
    -- forced-switch party list -- a pushed screen this driver then has to
    -- navigate blind.  With nothing to switch to there is no list: the match
    -- either resolves or whites out, and both are an answer.  The trade
    -- above needed the second mon, and has already had it.
    game.save.party = { lead }
    parties.debug.refresh()
    U.wait(20)
    -- drive the battler's row list the way the referee's is driven: arm by
    -- talking, which is what the guest's scriptKey does
    local rows = parties.debug.rows[byRole.battler.index]
    check(rows ~= nil, "the battler has a row list")

    -- Stand directly in front of THIS guest.  Where each one ended up is
    -- not knowable in advance -- the spawn search steps aside for whoever
    -- already owns a cell -- so the mod reports it.
    local key = "guest" .. byRole.battler.index
    local placed = parties.debug.cells()[key]
    check(placed ~= nil, "the battler's cell is known ("
      .. (placed and (placed.x .. "," .. placed.y) or "?") .. ")")
    local faced = parties.debug.face(key)
    check(faced ~= false, "warped to face the battler")
    U.wait(70)
    clearVm()
    shot("62-facing-the-battler.png")

    local battle
    U.tap(game, "a"); U.wait(30)
    shot("63-battler-speaks.png")
    for _ = 1, 300 do
      local state = game.stack:top()
      if state and state.battle then battle = state break end
      U.tap(game, "a")
      U.wait(4)
    end

    if battle then
      check(battle.battle.wild ~= true, "the party match is a TRAINER battle")
      local enemy = battle.battle.enemyParty or {}
      check(#enemy >= 1, "the guest brought a team (" .. #enemy .. ")")
      local armed = 0
      for _, mon in ipairs(enemy) do
        if mon.moves and #mon.moves > 0 then armed = armed + 1 end
      end
      check(armed == #enemy, ("every mon knows moves (%d/%d)")
        :format(armed, #enemy))
      shot("64-party-battle.png")
      -- two mons a side, so this needs more presses than the cup's
      -- one-mon first round
      -- A is right on the battle menu, the move list and for paging text.
      -- "submenu" is a screen pushed OVER the battle (the party list, the
      -- pack), and which button leaves it depends on why it opened: a
      -- voluntary list cancels on B, a FORCED switch cannot be cancelled at
      -- all and wants A to pick a mon.  So press A, and fall back to B when
      -- the phase has not moved for a while -- this run hung on "submenu"
      -- with each button alone.
      local lastPhase, stalled = nil, 0
      for _ = 1, 900 do
        if battle.battle.over then break end
        local phase = battle.phase
        stalled = (phase == lastPhase) and (stalled + 1) or 0
        lastPhase = phase
        if phase == "menu" then
          U.tap(game, "a"); U.wait(4)
        elseif phase == "moves" then
          U.tap(game, "a"); U.wait(6)
        elseif stalled > 8 then
          U.tap(game, "b"); U.wait(6)
          stalled = 0
        else
          U.tap(game, "a"); U.wait(4)
        end
      end
      check(battle.battle.over == true, "the match resolved (phase "
        .. tostring(battle.phase) .. ")")
      U.log("     outcome:", tostring(battle.battle.outcome))
      for _ = 1, 400 do
        if not game.stack:top() or not game.stack:top().battle then break end
        U.tap(game, "a")
        U.wait(4)
      end
      U.wait(50)
      shot("65-after-match.png")
      clearVm()
    else
      check(false, "the battler started a battle")
    end
  end

  -- ------- and the news has been keeping up

  local sawParty = false
  for _, entry in ipairs(core.news.recent(20)) do
    if entry.text:find("PARTY") or entry.text:find("MEET")
      or entry.text:find("traded") then
      sawParty = true
    end
  end
  check(sawParty, "the party reached the news feed")

  U.log("DRIVER FAILURES:", failures)
end
