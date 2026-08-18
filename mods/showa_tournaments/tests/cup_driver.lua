-- Driver: the cup circuit on a real Gold boot.
--
--   POKEPORT_GAME=gold POKEPORT_IDENTITY=cup_driver POKEPORT_NO_DISCORD=1 \
--     SHOT_DIR=shots POKEPORT_DRIVER=mods/showa_tournaments/tests/cup_driver.lua \
--     lovec.exe .
--
-- What this run is for is the one thing no headless suite can say: that
-- talking to the referee really starts a TRAINER BATTLE against the class the
-- mod armed, that the party the engine builds from the class record has
-- moves, and that the verb after `startbattle` sees the outcome.  Everything
-- up to that point (menus, the draw, the roster) is covered elsewhere; here it
-- is walked the way a player walks it, and shot.
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
  local core, cup = e.showa_core, e.showa_tournaments
  check(core ~= nil, "showa_core loaded")
  check(cup ~= nil, "showa_tournaments loaded")
  if not (core and cup) then
    U.log("DRIVER FAILURES:", failures + 1)
    return
  end

  -- ------- a trainer who can actually fight

  local lead = Mon.new(game.data, "QUILAVA", 15)
  check(lead ~= nil and #lead.moves > 0,
    "built a L15 QUILAVA with real moves")
  game.save.party = { lead }
  game.save.player = game.save.player or {}
  game.save.player.money = 50000

  -- ------- the lawn

  local ok = cup.debug.warp("registrar")
  check(ok ~= false, "warped to the cup grounds")
  U.wait(70)
  check(game.world.map and game.world.map.id == "NATIONAL_PARK",
    "standing in NATIONAL_PARK (" .. tostring(game.world.map
      and game.world.map.id) .. ")")
  check(cup.debug.spawned() == 2,
    "both the registrar and the referee spawned ("
      .. cup.debug.spawned() .. ")")

  -- The player was warped one cell south of the registrar facing up, so an A
  -- press here is the press a player would make.
  local function clearVm()
    for _ = 1, 240 do
      if not (game.world.vm and game.world.vm.busy) then return true end
      U.tap(game, "a")
      U.wait(6)
    end
    return false
  end

  local top = game.stack:top()
  U.tap(game, "a")
  U.wait(40)
  check(game.stack:top() ~= top, "talking to the registrar opened the desk")
  shot("50-cup-desk.png")
  U.tap(game, "b")
  U.wait(20)
  clearVm()

  -- ------- enter, and read the board
  --
  -- Entering through the menu would be four more presses of navigation for
  -- the same state; the menu itself is shot above and covered by the headless
  -- suite, so the run spends its frames on the battle instead.

  local entered, why = cup.debug.enter("rookie")
  check(entered == true, "entered the ROOKIE CUP (" .. tostring(why) .. ")")
  local live = cup.current()
  check(live ~= nil and live.cupId == "rookie", "a cup is running")
  check(live ~= nil and live.alive == true, "with the player in it")

  top = game.stack:top()
  U.tap(game, "a")
  U.wait(40)
  check(game.stack:top() ~= top, "the desk reopened with a cup running")
  shot("51-cup-entered.png")

  -- BOARD is the first row with a cup running: walk into it, which is both
  -- the page nobody had looked at and the row that collided.
  local desk = game.stack:top()
  U.tap(game, "a")
  U.wait(40)
  check(game.stack:top() ~= desk, "the board opened from the desk")
  shot("52-the-board.png")

  -- B backs out of the board and lands on the desk again.  This is the press
  -- that used to crash: onCancel is called with no menu and after the pop.
  U.tap(game, "b")
  U.wait(40)
  check(game.stack:top() ~= nil, "B backed out of the board without crashing")
  shot("53-back-at-desk.png")
  U.tap(game, "b")
  U.wait(20)
  clearVm()

  -- ------- the referee, and a real trainer battle

  cup.debug.warp("referee")
  U.wait(70)
  local before = cup.current()
  local roundBefore = before and before.round or 0

  local armed = cup.debug.arm()
  check(armed ~= nil, "the mod can name this round's opponent")
  if armed then
    U.log("     opponent:", tostring(armed.name) .. " class "
      .. tostring(armed.class) .. " member " .. tostring(armed.member))
    -- The roster the engine will build the enemy party from.  Found by
    -- walking the live class table for the armed index, which is the same
    -- resolution `loadtrainer` does and needs no engine internals to say.
    local class
    for _, candidate in pairs(game.data.trainers.classes) do
      if candidate.index == armed.class then class = candidate break end
    end
    check(class ~= nil, "the armed class number resolves to a real class")
    local roster = class and class.trainers and class.trainers[armed.member]
      and class.trainers[armed.member].party
    check(roster ~= nil and #roster >= 1, "and that member has a roster")
    if roster then
      for _, mon in ipairs(roster) do
        check(mon.level <= 15, ("the roster is inside the cap (Lv%d)")
          :format(mon.level))
      end
    end
  end

  -- Talk.  The verb speaks first, then the loadtrainer / startbattle rows
  -- behind it run: this is the whole seam.
  U.tap(game, "a")
  U.wait(30)
  shot("54-referee-calls.png")

  local battle
  for _ = 1, 900 do
    local state = game.stack:top()
    if state and state.battle then battle = state break end
    U.tap(game, "a")
    U.wait(4)
  end
  check(battle ~= nil, "talking to the referee started a battle")

  if battle then
    check(battle.battle.wild ~= true, "and it is a TRAINER battle, not a wild one")
    local enemyParty = battle.battle.enemyParty or {}
    check(#enemyParty >= 1, "the opponent brought a party (" .. #enemyParty .. ")")
    local withMoves = 0
    for _, mon in ipairs(enemyParty) do
      if mon.moves and #mon.moves > 0 then withMoves = withMoves + 1 end
    end
    check(withMoves == #enemyParty,
      ("every opponent mon knows moves (%d/%d) -- the class-record roster "
        .. "really went through the engine's party builder")
        :format(withMoves, #enemyParty))
    check(battle.showEnemyTrainer == true,
      "and the class has a battle portrait to draw")
    U.wait(30)
    shot("55-cup-battle.png")

    -- Fight it out.  A is right on the battle menu, the move list and for
    -- paging text; "submenu" is a screen pushed OVER the battle and which
    -- button leaves it depends on why it opened, so fall back to B when the
    -- phase has not moved for a while.  Both drivers hung here without it.
    local lastPhase, stalled = nil, 0
    for _ = 1, 900 do
      if battle.battle.over then break end
      local phase = battle.phase
      stalled = (phase == lastPhase) and (stalled + 1) or 0
      lastPhase = phase
      if phase == "menu" then
        U.tap(game, "a"); U.wait(4)   -- FIGHT
      elseif phase == "moves" then
        U.tap(game, "a"); U.wait(6)   -- first move
      elseif stalled > 8 then
        U.tap(game, "b"); U.wait(6)
        stalled = 0
      else
        U.tap(game, "a"); U.wait(4)
      end
    end
    check(battle.battle.over == true, "the battle resolved (phase "
      .. tostring(battle.phase) .. ")")
    U.log("     outcome:", tostring(battle.battle.outcome))
  end

  -- ------- back on the lawn, the cup moved on

  for _ = 1, 400 do
    if not game.stack:top() or not game.stack:top().battle then break end
    U.tap(game, "a")
    U.wait(4)
  end
  U.wait(60)

  -- The referee's own line after the battle.  Shot BEFORE it is cleared:
  -- this dialogue goes through core.dialogue, and the whole reason that
  -- exists is that a raw showText prints "..." while every state assertion
  -- still passes.
  local spoke = game.world.vm and game.world.vm.busy
  check(spoke == true, "the referee says something after the match")
  shot("56-match-result.png")
  clearVm()
  shot("57-after-match.png")

  local after = cup.current()
  local advanced = (after == nil)
    or (after.round > roundBefore)
    or (after.alive == false)
  check(advanced, "the cup moved on after the match ("
    .. (after and ("round " .. after.round .. ", alive "
      .. tostring(after.alive)) or "cup finished") .. ")")

  -- and a rival who was armed got their real team back
  local rivals = e.showa_rivals
  if rivals and armed and armed.rival then
    local card = rivals.battleCard(armed.rival)
    local class = game.data.trainers.classes[card.classId]
    check(class.trainers[1].party[1].level == card.party[1].level,
      "the rival left the cup with their real team, not the capped one")
  end

  U.log("DRIVER FAILURES:", failures)
end
