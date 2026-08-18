-- The host's clipboard, as pure data.
--
-- Same reason showa_devkit and showa_tournaments keep their rows out here: a
-- ListMenu row shares seventeen glyph slots between its label and its right
-- column, four collisions have shipped past green suites in this project, and
-- the only thing that has ever caught one is a screenshot or a width test.
local Menu = {}

Menu.WIDTH = 16

-- ctx = {
--   party = { theme = { short = "TRADE" }, venueLabel = "SHOWA MALL",
--             day = 12 } | nil,
--   next = { theme = ..., venueLabel = ..., day = 15, inDays = 3 } | nil,
--   guests = { { name = "KAZU", role = "swapper", done = false }, ... },
--   attended = 4,
-- }

Menu.ROLE_TAG = { battler = "BTL", swapper = "SWAP", trader = "TRADE" }

function Menu.host(ctx)
  local rows = {}
  if ctx.party then
    rows[#rows + 1] = { id = "guests", label = "WHO IS HERE",
                        right = tostring(#(ctx.guests or {})) }
    rows[#rows + 1] = { id = "theme", label = "TONIGHT",
                        right = ctx.party.theme.short }
  else
    rows[#rows + 1] = { id = "info", label = "NO PARTY TODAY", right = "" }
  end
  if ctx.next then
    rows[#rows + 1] = { id = "info", label = "NEXT PARTY",
                        -- days out, not an absolute day: "in 2" is what a
                        -- guest would actually say
                        right = "IN " .. tostring(ctx.next.inDays) }
  end
  rows[#rows + 1] = { id = "info", label = "PARTIES BEEN",
                      right = tostring(ctx.attended or 0) }
  rows[#rows + 1] = { id = "close", label = "LEAVE" }
  return rows
end

function Menu.guests(ctx)
  local rows = {}
  for _, guest in ipairs(ctx.guests or {}) do
    rows[#rows + 1] = {
      id = "guest:" .. tostring(guest.index or #rows + 1),
      -- eight and five, plus the gap: inside the budget at every role
      label = (guest.name or "?"):sub(1, 8),
      right = guest.done and "DONE" or (Menu.ROLE_TAG[guest.role] or "?"),
    }
  end
  if #rows == 0 then
    rows[#rows + 1] = { id = "info", label = "NOBODY YET", right = "" }
  end
  rows[#rows + 1] = { id = "back", label = "BACK" }
  return rows
end

-- The trade a trader guest is offering, laid out as a confirmation.  Two
-- rows and a refusal line, because a Pokemon leaving the party for good is
-- not something to do on a single unexplained A press.
function Menu.trade(ctx)
  local guest = ctx.guest
  if not guest then
    return { { id = "back", label = "NOBODY THERE" } }
  end
  -- Five and ten.  A Gen 2 species name is at most ten glyphs
  -- (BELLSPROUT, EXEGGCUTE), so "THEY WANT" left no room for one -- which
  -- the width test caught before this ever reached a screen.
  local rows = {
    { id = "info", label = "WANTS",
      right = (guest.wantsMon or "?"):sub(1, 10) },
    { id = "info", label = "GIVES",
      right = (guest.offersMon or "?"):sub(1, 10) },
  }
  if ctx.canTrade then
    rows[#rows + 1] = { id = "trade:yes", label = "TRADE" }
  else
    rows[#rows + 1] = { id = "info", label = "CANNOT TRADE",
                        right = "" }
  end
  rows[#rows + 1] = { id = "back", label = "NOT NOW" }
  return rows
end

Menu.PAGES = { host = Menu.host, guests = Menu.guests, trade = Menu.trade }
Menu.TITLES = { host = "THE PARTY", guests = "GUESTS", trade = "TRADE?" }

function Menu.width(row)
  return #(row.label or "") + #(row.right or "")
end

return Menu
