-- The pure half of showa_parties: the schedule, the guest list, the two
-- swaps, and the menu's column budget.  No engine, no boot.
--
--   luajit mods/showa_parties/tests/parties_rules_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Schedule = require("mods.showa_parties.party.schedule")
local Guests = require("mods.showa_parties.party.guests")
local Exchange = require("mods.showa_parties.party.exchange")
local Menu = require("mods.showa_parties.party.menu")

-- ------- the schedule

do
  T.eq(Schedule.isPartyDay(0), true, "day zero throws a party")
  T.eq(Schedule.isPartyDay(3), true, "and every third day after")
  T.eq(Schedule.isPartyDay(1), false, "but not the day after one")
  T.eq(Schedule.isPartyDay(2), false, "nor the day after that")

  T.eq(Schedule.nextPartyDay(1), 3, "the next party after day 1 is day 3")
  T.eq(Schedule.nextPartyDay(3), 3, "and on a party day, it is today")

  local party = Schedule.on(0)
  T.check(party ~= nil, "day zero has a party")
  T.check(party.venue ~= nil, "somewhere")
  T.check(party.theme ~= nil, "with a theme")
  T.eq(Schedule.on(1), nil, "and a quiet day has none")

  -- the same day is always the same party
  local again = Schedule.on(0)
  T.eq(again.venue, party.venue, "the same day is the same room")
  T.eq(again.theme.id, party.theme.id, "and the same theme")
  T.eq(again.seed, party.seed, "and the same seed")
end

do
  -- the rotation really moves, in both venue and theme
  local venues, themes = {}, {}
  for day = 0, Schedule.CYCLE * 12, Schedule.CYCLE do
    local party = Schedule.on(day)
    venues[party.venue] = true
    themes[party.theme.id] = true
  end
  local venueCount, themeCount = 0, 0
  for _ in pairs(venues) do venueCount = venueCount + 1 end
  for _ in pairs(themes) do themeCount = themeCount + 1 end
  T.eq(venueCount, #Schedule.VENUES,
    "every venue gets a turn (" .. venueCount .. ")")
  T.eq(themeCount, #Schedule.THEMES,
    "and every theme (" .. themeCount .. ")")
end

do
  -- a venue whose feature mod is missing drops out rather than crashing
  local only = Schedule.on(0, { "ELM_LAB" })
  T.eq(only.venue, "ELM_LAB", "with one venue live, that is where it is")
  for day = 0, 30, Schedule.CYCLE do
    local party = Schedule.on(day, { "ELM_LAB" })
    T.eq(party.venue, "ELM_LAB", "and it stays there on day " .. day)
  end
  T.eq(Schedule.on(0, {}), nil, "with nowhere live there is no party")
  T.eq(Schedule.next(0, {}), nil, "and no next one either")
end

do
  local upcoming = Schedule.next(1)
  T.check(upcoming ~= nil, "there is always a next party")
  T.eq(upcoming.day, 3, "the one on day 3")
  T.eq(Schedule.next(0).day, 0, "and today's counts as next when it is on")
end

do
  for _, theme in ipairs(Schedule.THEMES) do
    local roles = Schedule.roles(theme)
    T.eq(#roles, Schedule.guestCount(theme),
      theme.id .. " fields the guests it says it does")
    T.check(#roles >= 3, theme.id .. " is a party, not a chat")
    T.check(#theme.short <= 6,
      theme.id .. "'s menu label fits (" .. theme.short .. ")")
    -- the role list must be stable, or guest 1 is a different person per read
    local again = Schedule.roles(theme)
    for i, role in ipairs(roles) do
      T.eq(again[i], role, theme.id .. " role order is stable at " .. i)
    end
  end

  -- every theme brings at least one of each kind, so no party is a dead end
  for _, theme in ipairs(Schedule.THEMES) do
    for _, role in ipairs(Schedule.ROLE_ORDER) do
      T.check((theme.roles[role] or 0) >= 1,
        theme.id .. " has at least one " .. role)
    end
  end
end

-- ------- the guest list

do
  local party = Schedule.on(0)
  local roles = Schedule.roles(party.theme)
  local guests = Guests.build(party, roles)
  T.eq(#guests, #roles, "one guest per role")

  local twin = Guests.build(party, roles)
  for i, guest in ipairs(guests) do
    T.eq(twin[i].name, guest.name, "the same party draws the same guest " .. i)
    T.eq(twin[i].role, guest.role, "in the same role")
  end

  local names = {}
  for _, guest in ipairs(guests) do
    T.eq(names[guest.name], nil, "no two guests share a name: " .. guest.name)
    names[guest.name] = true
    T.check(guest.sprite ~= nil, guest.name .. " has a sprite")
    T.check(guest.line ~= nil, guest.name .. " has something to say")
    T.eq(guest.index ~= nil, true, guest.name .. " knows their slot")
  end
end

do
  -- each role arrives carrying what its role needs
  for day = 0, Schedule.CYCLE * 8, Schedule.CYCLE do
    local party = Schedule.on(day)
    for _, guest in ipairs(Guests.build(party, Schedule.roles(party.theme))) do
      if guest.role == "swapper" then
        T.check(guest.wants and guest.offers,
          guest.name .. " brought an item swap")
        T.check(guest.wants ~= guest.offers,
          guest.name .. " does not want what they are offering")
      elseif guest.role == "trader" then
        T.check(guest.wantsMon and guest.offersMon,
          guest.name .. " brought a trade")
        T.check(guest.wantsMon ~= guest.offersMon,
          guest.name .. " does not want what they are offering")
        T.check(guest.otName and guest.otId, guest.name .. " is a real OT")
        T.check(guest.otId >= 0 and guest.otId < 65536,
          guest.name .. "'s trainer id fits two bytes")
      else
        T.check(#guest.team >= 2, guest.name .. " brought a team")
        T.check(guest.team[1] ~= guest.team[2],
          guest.name .. " brought two different mons")
      end
    end
  end
end

do
  -- a battler's team tracks the player and never leaves the sane range
  local party = Schedule.on(0)
  local guest = { team = { "PIDGEY", "RATTATA" } }
  for _, level in ipairs({ 1, 5, 25, 60, 100 }) do
    local team = Guests.battleParty(guest, level)
    T.eq(#team, 2, "two mons at player level " .. level)
    for _, mon in ipairs(team) do
      T.check(mon.level >= 2, "nobody below level 2 at " .. level)
      T.check(mon.level <= 60, "and nobody above 60 at " .. level)
    end
    T.check(team[1].level >= team[2].level, "the lead leads at " .. level)
  end
  T.eq(#Guests.battleParty({}, 20), 1,
    "a guest with no team still fields somebody")
  T.eq(Guests.battleParty({ team = {} }, 20)[1].level, 20,
    "at the player's level")
  T.check(party ~= nil, "and the party this was drawn for exists")
end

-- ------- item swaps

do
  local guest = { wants = "POTION", offers = "REVIVE" }

  local empty = {}
  local ok, why = Exchange.canSwapItem(empty, guest)
  T.eq(ok, false, "an empty bag cannot swap")
  T.check(why:find("POTION"), "and is told what is wanted")

  local bag = { POTION = 2 }
  T.eq(Exchange.canSwapItem(bag, guest), true, "a bag with the item can")
  local swap = Exchange.swapItem(bag, guest)
  T.eq(swap.gave, "POTION", "the POTION went")
  T.eq(swap.got, "REVIVE", "the REVIVE came")
  T.eq(bag.POTION, 1, "one POTION left")
  T.eq(bag.REVIVE, 1, "and one REVIVE gained")

  -- the last one clears the slot rather than leaving a zero
  Exchange.swapItem(bag, guest)
  T.eq(bag.POTION, nil, "the last POTION clears the slot")
  T.eq(bag.REVIVE, 2, "and the REVIVEs stack")

  -- and then there is nothing left to give
  ok, why = Exchange.canSwapItem(bag, guest)
  T.eq(ok, false, "with none left the swap is refused")

  -- a full stack of what they are offering is refused rather than clipped
  local stuffed = { POTION = 1, REVIVE = Exchange.MAX_STACK }
  ok, why = Exchange.canSwapItem(stuffed, guest)
  T.eq(ok, false, "a full stack refuses the swap")
  T.check(why:find("full"), "and says so (" .. tostring(why) .. ")")
  T.eq(stuffed.POTION, 1, "and nothing was taken")

  T.eq(Exchange.canSwapItem({}, {}), false, "a guest with no swap is refused")
  T.eq(Exchange.swapItem({ POTION = 1 }, {}), nil, "and cannot be applied")
end

-- ------- Pokemon trades

do
  local guest = { name = "KAZU", wantsMon = "GEODUDE", offersMon = "ONIX",
                  nickname = "ROCKY", otName = "KAZU", otId = 1234 }

  local ok, why = Exchange.canTradeMon({ { species = "GEODUDE" } }, guest)
  T.eq(ok, false, "your last POKEMON stays with you")
  T.check(why:find("second"), "and you are told why (" .. tostring(why) .. ")")

  ok, why = Exchange.canTradeMon(
    { { species = "PIDGEY" }, { species = "RATTATA" } }, guest)
  T.eq(ok, false, "a party without what they want cannot trade")
  T.check(why:find("GEODUDE"), "and names it (" .. tostring(why) .. ")")

  local party = { { species = "PIDGEY" }, { species = "GEODUDE" } }
  local index
  ok, why, index = Exchange.canTradeMon(party, guest)
  T.eq(ok, true, "a party with it can")
  T.eq(index, 2, "and the slot is named")
  T.eq(Exchange.slotFor(party, guest), 2, "slotFor agrees")

  -- mail is refused, the way the PC and the Day-Care refuse it
  local mailed = { { species = "PIDGEY" },
                   { species = "GEODUDE", mail = { text = "hi" } } }
  ok, why = Exchange.canTradeMon(mailed, guest)
  T.eq(ok, false, "a mon holding MAIL is not traded")
  T.check(why:find("MAIL"), "and says so (" .. tostring(why) .. ")")

  -- the first match is the one offered, and eligible lists them all
  local two = { { species = "GEODUDE" }, { species = "PIDGEY" },
                { species = "GEODUDE" } }
  T.eq(Exchange.slotFor(two, guest), 1, "the first match is taken")
  T.eq(#Exchange.eligible(two, guest), 2, "and both are listed")

  T.eq(Exchange.canTradeMon(party, {}), false,
    "a guest with no trade is refused")
  T.eq(Exchange.slotFor({}, guest), nil, "an empty party matches nothing")
end

do
  -- the row handed to the engine's own trade routine
  local guest = { name = "MIKI", wantsMon = "ABRA", offersMon = "MACHOP",
                  nickname = "PUNCHY", otName = "MIKI", otId = 42 }
  local row = Exchange.tradeRow(guest)
  T.eq(row.give, "ABRA", "GIVEMON is what the PLAYER hands over")
  T.eq(row.get, "MACHOP", "and GETMON is what they receive")
  T.eq(row.nickname, "PUNCHY", "the received mon arrives nicknamed")
  T.eq(row.otName, "MIKI", "with an original trainer")
  T.eq(row.otId, 42, "and their id")
  T.eq(row.gender, "TRADE_GENDER_EITHER", "and no gender demand")
  T.eq(Exchange.tradeRow({}), nil, "a guest with no trade builds no row")
  T.eq(Exchange.tradeRow(nil), nil, "and neither does nobody")
end

-- ------- the menu's column budget

do
  local function widest(rows, page)
    for _, row in ipairs(rows) do
      T.check(Menu.width(row) <= Menu.WIDTH,
        ("%s row fits: %q + %q = %d <= %d"):format(page, row.label or "",
          row.right or "", Menu.width(row), Menu.WIDTH))
    end
  end

  -- every theme, at a party and between parties, with the longest guest
  -- list and the longest names the generator can produce
  local longest = ""
  for _, name in ipairs(Guests.NAMES) do
    if #name > #longest then longest = name end
  end

  for _, theme in ipairs(Schedule.THEMES) do
    local guests = {}
    for i, role in ipairs(Schedule.roles(theme)) do
      guests[i] = { index = i, name = longest, role = role,
                    done = i % 2 == 0 }
    end
    local ctx = {
      party = { theme = theme, day = 999,
                venueLabel = "GOLDENROD UNDERGROUND" },
      next = { theme = theme, day = 9999, inDays = 999,
               venueLabel = "GOLDENROD UNDERGROUND" },
      guests = guests, attended = 9999,
    }
    widest(Menu.host(ctx), "host/" .. theme.id)
    widest(Menu.guests(ctx), "guests/" .. theme.id)
    widest(Menu.trade({ guest = { wantsMon = "CHARMANDER",
      offersMon = "BULBASAUR" }, canTrade = true }), "trade/" .. theme.id)
    widest(Menu.trade({ guest = { wantsMon = "CHARMANDER",
      offersMon = "BULBASAUR" }, canTrade = false }), "trade/no")
  end

  -- and the empty states
  widest(Menu.host({ attended = 0 }), "host/quiet")
  widest(Menu.guests({}), "guests/empty")
  widest(Menu.trade({}), "trade/nobody")

  -- every species in the trade pool fits the confirmation
  for _, species in ipairs(Guests.SPECIES) do
    widest(Menu.trade({ guest = { wantsMon = species, offersMon = species },
      canTrade = true }), "trade/" .. species)
  end

  -- every item in the pool fits a guest line's needs
  for _, item in ipairs(Guests.ITEMS) do
    T.check(#item <= 14, "item name is sayable in a text box: " .. item)
  end
end

do
  -- a quiet day says so, and still offers a way out
  local rows = Menu.host({ attended = 3 })
  local ids = {}
  for _, row in ipairs(rows) do ids[row.id] = true end
  T.check(ids.close, "there is always a way out of the host menu")
  T.check(not ids.guests, "and nothing to look at when nobody is there")

  local live = Menu.host({ party = { theme = Schedule.THEMES[1], day = 3 },
                           guests = { {}, {} }, attended = 1 })
  T.check(live[1].id == "guests", "at a party the guest list is offered first")
  T.eq(live[1].right, "2", "with a head count")
end

do
  -- the guest list marks who you have already dealt with
  local rows = Menu.guests({ guests = {
    { index = 1, name = "KAZU", role = "swapper", done = true },
    { index = 2, name = "MIKI", role = "trader", done = false } } })
  T.eq(rows[1].right, "DONE", "a guest already swapped with says DONE")
  T.eq(rows[2].right, "TRADE", "and the rest show what they are here for")
  T.eq(rows[#rows].id, "back", "with a way back")
end

do
  for page, build in pairs(Menu.PAGES) do
    T.check(type(build) == "function", page .. " builds rows")
    T.check(type(Menu.TITLES[page]) == "string", page .. " has a title")
    T.check(#Menu.TITLES[page] <= 12, page .. "'s title fits the header")
  end
end

T.finish("showa_parties rules")
