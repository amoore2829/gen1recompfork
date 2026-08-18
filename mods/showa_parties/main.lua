-- Showa Parties: the neighbourhood meet-up.
--
-- Every third day somebody throws a party at one of the suite's venues.  Five
-- guests turn up, each with one thing on their mind: a battle, an item they
-- are after, or a Pokemon they will trade.  Walk in, talk to whoever you
-- like, walk out.  The host stands by the door with the clipboard.
--
-- The whole guest list is a function of the day and the room (party/), so the
-- people standing there are the people the news said would be, and leaving
-- and coming back does not reroll them.
--
-- Two seams this leans on, both proved by earlier mods and both documented in
-- SHOWA_HANDOVER.md rather than here:
--
--   * a battler's scriptKey carries NATIVE VM rows (loadtrainer / startbattle
--     / reloadmapafterbattle) around this mod's own verbs, which is the only
--     way a mod starts a trainer battle on Gold;
--   * everything anybody SAYS goes through core.dialogue, because
--     ctx.vm:showText takes a text key and prints "..." for a sentence.
--
-- The one thing that is new here is trading a Pokemon out of the player's
-- party, and that is deliberately NOT hand-rolled: src/core/gen2/NpcTrade.lua
-- is the cart's own trade routine and already gets the parts that are easy to
-- get wrong -- the received mon keeps the given mon's LEVEL and recomputes
-- its stats, the party closes up rather than swapping in place, the mail slot
-- shifts with it, and the #DEX is ticked.  Reaching for it is why this mod
-- declares the engine_internals permission.
local Schedule = require("mods.showa_parties.party.schedule")
local Guests = require("mods.showa_parties.party.guests")
local Exchange = require("mods.showa_parties.party.exchange")
local Menu = require("mods.showa_parties.party.menu")

local NpcTrade = require("src.core.gen2.NpcTrade")

local SCREEN = "ShowaPartyDesk"
local GUEST_CLASS = "SHOWA_PARTY_GUEST"

return function(mod)
  local core = assert(mod.find("showa_core"),
    "showa_parties needs showa_core").exports

  local function say(ctx, text)
    return core.dialogue.say(ctx, text)
  end

  -- ------- persistent state

  local state = mod.save:get("state")
  if type(state) ~= "table" or state.v ~= 1 then
    state = { v = 1, attended = 0, done = {}, lastAnnounced = nil }
  end
  local function persist() mod.save:set("state", state) end
  persist()

  -- `done` is keyed by day and guest index, so a guest you have already
  -- swapped with stays swapped for the evening and is fresh at the next
  -- party.  One day's worth is kept; the rest is dropped on the way in.
  local function doneKey(party, guest)
    return tostring(party.day) .. ":" .. tostring(guest.index)
  end
  local function isDone(party, guest)
    return state.done[doneKey(party, guest)] == true
  end
  local function markDone(party, guest)
    -- a new day clears the book rather than growing it forever
    if state.doneDay ~= party.day then
      state.done, state.doneDay = {}, party.day
    end
    state.done[doneKey(party, guest)] = true
    persist()
  end

  -- ------- today's party

  local function liveVenues()
    local out = {}
    for _, id in ipairs(Schedule.VENUES) do
      if core.venues.get(id) then out[#out + 1] = id end
    end
    return out
  end

  local function today()
    return core.clock.today() or 0
  end

  local function partyToday()
    return Schedule.on(today(), liveVenues())
  end

  local function nextParty()
    local day = today()
    local party = Schedule.next(day + 1, liveVenues())
    if party then party.inDays = party.day - day end
    return party
  end

  -- The guest list is rebuilt rather than stored: it is a pure function of
  -- the party, so keeping a copy in the save could only ever go stale.
  local guestCache = { day = nil, list = nil }
  local function guestsAt(party)
    if not party then return {} end
    if guestCache.day == party.day and guestCache.list then
      return guestCache.list
    end
    local list = Guests.build(party, Schedule.roles(party.theme))
    guestCache.day, guestCache.list = party.day, list
    return list
  end

  local function playerLevel()
    local party = mod.game and mod.game.save and mod.game.save.party
    local best = 5
    for _, mon in ipairs(party or {}) do
      if (mon.level or 0) > best then best = mon.level end
    end
    return best
  end

  -- ------- the guest trainer class
  --
  -- One class, one member per guest slot, the same shape the cup's house
  -- field uses: `loadtrainer class, member` is built for exactly this.

  local guestIndex = assert(core.trainers.claim("showa_parties", GUEST_CLASS))

  local guestRows = {}
  for i = 1, 8 do
    guestRows[i] = { name = "GUEST",
                     party = { { species = "RATTATA", level = 5 } } }
  end
  mod.content.trainers:register(GUEST_CLASS, {
    name = "PARTY GUEST",
    index = guestIndex,
    baseMoney = 10,
    trainers = guestRows,
  })

  local function dressGuests()
    core.trainers.setPic(GUEST_CLASS, "SCHOOLBOY")
  end
  mod.events:on("game.ready", dressGuests)
  dressGuests()

  -- ------- the battler's row list
  --
  -- One table per guest slot, so two battlers at the same party can be armed
  -- independently and a fixed script still fights whoever you walked up to.
  local matchRows = {}
  local pending = {}
  for slot = 1, 8 do
    matchRows[slot] = {
      { "showa_parties:call", slot },
      { op = "loadtrainer", class = guestIndex, member = slot },
      { op = "startbattle" },
      { "showa_parties:result", slot },
      { op = "reloadmapafterbattle" },
    }
  end

  mod.content.commands:register("showa_parties:call", function(ctx, slot)
    pending[slot] = nil
    local party = partyToday()
    if not party then
      say(ctx, "The party is over.\nCatch us next time!")
      return "end"
    end
    local guest = guestsAt(party)[slot]
    if not guest then
      say(ctx, "...")
      return "end"
    end
    if isDone(party, guest) then
      say(ctx, ("%s: Good match earlier!\nEnjoy the rest of the party.")
        :format(guest.name))
      return "end"
    end

    -- stand the guest's team up at the player's level
    core.trainers.setParty(GUEST_CLASS, slot,
      core.trainers.rows(Guests.battleParty(guest, playerLevel())))
    matchRows[slot][2].member = slot
    pending[slot] = guest

    say(ctx, ("%s: %s"):format(guest.name, guest.line))
    -- no "end": the rows behind this one are the battle
  end)

  mod.content.commands:register("showa_parties:result", function(ctx, slot)
    local guest = pending[slot]
    pending[slot] = nil
    if not guest then return end
    local outcome = ctx.vm and ctx.vm.battleOutcome
    if outcome == "lose" then
      -- a loss is a whiteout on Gold and the row after this one performs it,
      -- so say nothing and let the host mention it next time
      return
    end
    local party = partyToday()
    if party then markDone(party, guest) end
    core.news.post(("%s lost a friendly match at the party."):format(guest.name))
    say(ctx, ("%s: Nice one!\nThat is what a party is for."):format(guest.name))
  end)

  -- ------- the swapper and the trader

  mod.content.commands:register("showa_parties:swap", function(ctx, slot)
    local party = partyToday()
    local guest = party and guestsAt(party)[slot]
    if not guest then say(ctx, "..."); return "end" end
    if isDone(party, guest) then
      say(ctx, ("%s: Thanks again for the %s!"):format(guest.name,
        guest.offers and guest.wants or "swap"))
      return "end"
    end

    local save = mod.game and mod.game.save
    local inventory = save and save.inventory
    if not inventory then
      say(ctx, ("%s: %s"):format(guest.name, guest.line))
      return "end"
    end

    local ok, why = Exchange.canSwapItem(inventory, guest)
    if not ok then
      say(ctx, ("%s: I am after a %s.\nI would swap my %s for it.\n(%s)")
        :format(guest.name, guest.wants, guest.offers, why))
      return "end"
    end

    local swap = Exchange.swapItem(inventory, guest)
    markDone(party, guest)
    say(ctx, ("%s: My %s for your %s --\nthank you!")
      :format(guest.name, swap.got, swap.gave))
    return "end"
  end)

  -- A Pokemon leaving the party for good gets a confirmation screen rather
  -- than a single unexplained A press.
  mod.content.commands:register("showa_parties:trade", function(ctx, slot)
    local party = partyToday()
    local guest = party and guestsAt(party)[slot]
    if not guest then say(ctx, "..."); return "end" end
    if isDone(party, guest) then
      say(ctx, ("%s: Look after it, won't you?"):format(guest.name))
      return "end"
    end
    local ok = pcall(function()
      mod.ui.push(mod.game, SCREEN, { page = "trade", slot = slot })
    end)
    if not ok then
      say(ctx, ("%s: %s"):format(guest.name, guest.line))
    end
    return "end"
  end)

  -- The trade itself.  Answers a line for the footer.
  local function performTrade(slot)
    local party = partyToday()
    local guest = party and guestsAt(party)[slot]
    if not guest then return "they have gone" end
    -- The verb in front of the screen checks this too, but the check belongs
    -- HERE as well: this is the function that moves a Pokemon out of the
    -- party, and it must not do that twice however it was reached.
    if isDone(party, guest) then return "already traded tonight" end
    local save = mod.game and mod.game.save
    if not save then return "no save" end
    local ok, why, index = Exchange.canTradeMon(save.party, guest)
    if not ok then return why end
    local row = Exchange.tradeRow(guest)
    local given, received = NpcTrade.perform(mod.game.data, save, row, index)
    if not received then return "the trade did not go through" end
    markDone(party, guest)
    core.news.post(("A %s was traded for a %s at the party.")
      :format(given.species, received.species))
    return ("%s for %s!"):format(given.species, received.species)
  end

  -- ------- the host

  local function hostContext(page, slot)
    local party = partyToday()
    local guests = guestsAt(party)
    local rows = {}
    for _, guest in ipairs(guests) do
      rows[#rows + 1] = { index = guest.index, name = guest.name,
                          role = guest.role, done = isDone(party, guest) }
    end
    local upcoming = nextParty()
    local ctx = {
      party = party and {
        theme = party.theme, day = party.day,
        venueLabel = (core.venues.get(party.venue) or {}).label,
      } or nil,
      next = upcoming and {
        theme = upcoming.theme, day = upcoming.day, inDays = upcoming.inDays,
        venueLabel = (core.venues.get(upcoming.venue) or {}).label,
      } or nil,
      guests = rows,
      attended = state.attended or 0,
    }
    if page == "trade" then
      local guest = guests[slot]
      ctx.guest = guest
      ctx.canTrade = guest ~= nil
        and select(1, Exchange.canTradeMon(
          (mod.game and mod.game.save and mod.game.save.party) or {}, guest))
    end
    return ctx
  end

  local function openDesk(game, page, note, slot)
    page = page or "host"
    local build = Menu.PAGES[page] or Menu.host
    local items = {}
    for _, row in ipairs(build(hostContext(page, slot))) do
      items[#items + 1] = { label = row.label, right = row.right, value = row }
    end
    return mod.ui.ListMenu.new(game, Menu.TITLES[page] or "THE PARTY", items, {
      wrap = true, footer = note,
      onChoose = function(item, menu)
        local id = item.value.id or ""
        if id == "close" then menu:close(); return end
        if id == "info" then return end
        if id == "back" then
          menu:close()
          mod.ui.push(game, SCREEN, { page = "host" })
          return
        end
        if id == "guests" then
          menu:close()
          mod.ui.push(game, SCREEN, { page = "guests" })
          return
        end
        if id == "trade:yes" then
          local said = performTrade(slot)
          menu:close()
          mod.ui.push(game, SCREEN, { page = "host", note = said })
          return
        end
        -- a guest row is a read, not a warp: the guests are standing right
        -- there to be talked to
      end,
      -- onCancel takes NO arguments and runs after ListMenu has popped
      -- itself; closing again here is a crash on the B button
      onCancel = function()
        if page ~= "host" then mod.ui.push(game, SCREEN, { page = "host" }) end
      end,
    })
  end

  mod.content.screens:register(SCREEN, {
    new = function(game, opts)
      opts = opts or {}
      return openDesk(game, opts.page, opts.note, opts.slot)
    end,
  })

  mod.content.commands:register("showa_parties:host", function(ctx)
    local party = partyToday()
    if not party then
      local upcoming = nextParty()
      say(ctx, upcoming
        and ("No party tonight.\nNext one is in %d days,\nat %s."):format(
          upcoming.inDays, (core.venues.get(upcoming.venue) or {}).label
            or "somewhere")
        or "No parties are planned.\nCheck back another time.")
      return "end"
    end
    if state.attendedDay ~= party.day then
      state.attendedDay = party.day
      state.attended = (state.attended or 0) + 1
      persist()
    end
    local ok = pcall(function()
      mod.ui.push(mod.game, SCREEN, { page = "host" })
    end)
    if not ok then
      say(ctx, ("%s\n%s"):format(party.theme.label, party.theme.blurb))
    end
    return "end"
  end)

  -- ------- putting everybody in the room

  -- Spawned per map entry and cleared on the way out, the same way the
  -- rivals are: the world only ever holds the people actually standing
  -- there.  Cells are searched outward from the venue's own, because that
  -- cell often already belongs to somebody (the derby judge stands on the
  -- lake venue's).
  local spawned = {}
  -- where each guest actually ended up, which is not knowable in advance:
  -- the search steps aside for whoever already owns a cell
  local cells = {}
  local lastNote = "not attempted"

  local function scriptFor(guest)
    if guest.role == "battler" then return matchRows[guest.index] end
    if guest.role == "swapper" then
      return { { "showa_parties:swap", guest.index } }
    end
    return { { "showa_parties:trade", guest.index } }
  end

  local function clearGuests()
    for key, id in pairs(spawned) do
      pcall(function() mod.world:removeNpc(id) end)
      spawned[key] = nil
      cells[key] = nil
    end
  end

  local function refreshGuests()
    local here = mod.world and mod.world:current()
    local mapId = here and here.mapId
    local party = partyToday()
    local venue = party and core.venues.get(party.venue)
    lastNote = ("map=%s party=%s"):format(tostring(mapId),
      party and party.venue or "none")

    if not (venue and mapId and venue.map == mapId) then
      clearGuests()
      return
    end

    -- One `taken` set for the whole pass, so five guests and a host do not
    -- all pick the same free cell.  The predicate vetoes an unwalkable cell
    -- as well as an occupied one -- without that, guests stand on the
    -- shelves, which is exactly how it looks.
    local taken = {}
    local free = core.placement.forWorld(mod.world, taken)
    -- cells already spoken for by somebody still standing there
    for _, cell in pairs(cells) do
      core.placement.claim(taken, cell.x, cell.y)
    end

    local bx, by = venue.x or 5, venue.y or 3

    for _, guest in ipairs(guestsAt(party)) do
      local key = "guest" .. guest.index
      if not spawned[key] then
        local x, y = core.placement.pick(free, bx, by, { radius = 4 })
        if x then
          local ok, npcId = pcall(function()
            return mod.world:spawnNpc(venue.map, {
              sprite = guest.sprite, x = x, y = y,
              movement = 6, radius = { x = 0, y = 0 },
              hours = { -1, -1 },
              scriptKey = scriptFor(guest),
            })
          end)
          if ok and npcId then
            spawned[key] = npcId
            core.placement.claim(taken, x, y)
            cells[key] = { x = x, y = y, map = venue.map,
                           role = guest.role, index = guest.index }
          end
        else
          lastNote = lastNote .. " (no room for " .. guest.name .. ")"
        end
      end
    end

    -- The host prefers to be south of the spot -- by the door, facing the
    -- room -- but takes whatever is going rather than standing on a counter.
    if not spawned.host then
      local x, y = core.placement.pick(free, bx, by, {
        radius = 4, prefer = { { 0, 1 }, { -1, 1 }, { 1, 1 }, { 0, 2 } } })
      if x then
        local ok, npcId = pcall(function()
          return mod.world:spawnNpc(venue.map, {
            sprite = "SPRITE_POKEFAN_F", x = x, y = y,
            movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
            scriptKey = { { "showa_parties:host" } },
          })
        end)
        if ok and npcId then
          spawned.host = npcId
          core.placement.claim(taken, x, y)
          cells.host = { x = x, y = y, map = venue.map, role = "host" }
        end
      end
    end
  end

  mod.events:on("map.entered", refreshGuests)
  mod.events:on("map.exited", clearGuests)
  mod.events:on("game.ready", refreshGuests)

  -- ------- the news announces the next one

  local function announce()
    local upcoming = nextParty()
    if not upcoming then return end
    local key = tostring(upcoming.day)
    if state.lastAnnounced == key then return end
    state.lastAnnounced = key
    persist()
    local label = (core.venues.get(upcoming.venue) or {}).label or "town"
    core.news.post(("A %s is planned at %s."):format(
      upcoming.theme.label, label))
  end
  mod.events:on("clock.day_changed", announce)
  mod.events:on("game.ready", announce)
  -- Also at load: a save picked up mid-cycle should already have the next
  -- party in the feed rather than waiting for a midnight that may be days
  -- off.  This mod's priority (130) puts it after every mod that registers
  -- a venue, so the rotation is complete by the time this runs.
  announce()

  -- ------- exports

  mod.exports.today = function()
    local party = partyToday()
    if not party then return nil end
    return { day = party.day, venue = party.venue, theme = party.theme.id,
             label = party.theme.label, guests = #guestsAt(party) }
  end
  mod.exports.next = function()
    local upcoming = nextParty()
    if not upcoming then return nil end
    return { day = upcoming.day, inDays = upcoming.inDays,
             venue = upcoming.venue, theme = upcoming.theme.id }
  end
  mod.exports.guests = function()
    local out = {}
    for _, guest in ipairs(guestsAt(partyToday())) do
      out[#out + 1] = { index = guest.index, name = guest.name,
                        role = guest.role, wants = guest.wants,
                        offers = guest.offers, wantsMon = guest.wantsMon,
                        offersMon = guest.offersMon }
    end
    return out
  end
  mod.exports.attended = function() return state.attended or 0 end
  mod.exports.debug = {
    -- A party is a function of the day, and a driver cannot wait three of
    -- them, so the clock is what a driver moves.
    partyOn = function(day) return Schedule.on(day, liveVenues()) end,
    guestsOn = function(day)
      local party = Schedule.on(day, liveVenues())
      if not party then return {} end
      return Guests.build(party, Schedule.roles(party.theme))
    end,
    refresh = refreshGuests,
    spawned = function()
      local n = 0
      for _ in pairs(spawned) do n = n + 1 end
      return n
    end,
    note = function() return lastNote end,
    -- where everybody actually stands, so a driver can walk up to a
    -- particular guest instead of wandering
    cells = function()
      local out = {}
      for key, cell in pairs(cells) do
        out[key] = { x = cell.x, y = cell.y, map = cell.map,
                     role = cell.role, index = cell.index }
      end
      return out
    end,
    -- one cell south of somebody, facing them
    face = function(key)
      local cell = cells[key]
      if not cell then return false, "nobody there" end
      return mod.world:warpTo(cell.map, cell.x, cell.y + 1, "up")
    end,
    trade = performTrade,
    swap = function(slot)
      local party = partyToday()
      local guest = party and guestsAt(party)[slot]
      local save = mod.game and mod.game.save
      if not (guest and save and save.inventory) then return nil end
      return Exchange.swapItem(save.inventory, guest)
    end,
    warp = function()
      local party = partyToday()
      local venue = party and core.venues.get(party.venue)
      if not venue then return false, "no party today" end
      return mod.world:warpTo(venue.map, venue.x or 5, (venue.y or 3) + 3,
        "up")
    end,
    guestClass = function() return guestIndex end,
    rows = matchRows,
  }
end
