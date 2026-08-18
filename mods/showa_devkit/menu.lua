-- The menu tree, built as pure data from whatever is actually installed.
--
-- Pure on purpose: `build` takes a description of the world (which mods
-- are present, what the wallet holds, where the rivals are) and returns
-- rows.  That means the whole menu -- including the parts that only
-- appear when a feature mod is installed -- is testable without a boot,
-- which is the same bet sim/ makes in showa_rivals.
local Menu = {}

-- ctx = {
--   have  = { arcade = bool, contests = bool, malls = bool, rivals = bool,
--             cups = bool },
--   venues = { { id, label, map }, ... },
--   tokens = n, mallPoints = n, money = n,
--   rivals = { { id, name, location, level }, ... },
--   derbyOpen = bool, stickers = "2/4",
--   cup = { short = "ROOKIE", round = 1, alive = true } | nil,
-- }

function Menu.root(ctx)
  local rows = {
    { id = "warp", label = "WARP TO...", right = "" },
  }
  if ctx.have.arcade then
    rows[#rows + 1] = { id = "games", label = "CABINETS", right = "" }
  end
  rows[#rows + 1] = { id = "wallet", label = "WALLET", right = "" }
  if ctx.have.contests then
    rows[#rows + 1] = { id = "derby", label = "DERBY",
                        right = ctx.derbyOpen and "OPEN" or "SHUT" }
  end
  if ctx.have.malls then
    rows[#rows + 1] = { id = "stamps", label = "STAMPS",
                        right = ctx.stickers or "" }
  end
  if ctx.have.rivals then
    rows[#rows + 1] = { id = "rivals", label = "RIVALS", right = "" }
  end
  if ctx.have.cups then
    rows[#rows + 1] = { id = "cups", label = "CUPS",
                        right = ctx.cup and ctx.cup.short or "NONE" }
  end
  rows[#rows + 1] = { id = "status", label = "DIAGNOSTIC", right = "" }
  rows[#rows + 1] = { id = "close", label = "CLOSE", right = "" }
  return rows
end

function Menu.warp(ctx)
  local rows = {}
  for _, venue in ipairs(ctx.venues) do
    rows[#rows + 1] = { id = "venue:" .. venue.id, label = venue.label,
                        right = "", venue = venue.id }
  end
  table.sort(rows, function(a, b) return a.label < b.label end)
  rows[#rows + 1] = { id = "back", label = "BACK", right = "" }
  return rows
end

function Menu.games(ctx)
  return {
    { id = "play:ShowaEkans", label = "EKANS", right = "SNAKE" },
    { id = "play:ShowaDdr", label = "DITTO REV.", right = "DANCE" },
    { id = "play:ShowaGatcha", label = "GATCHA", right = "PRIZE" },
    { id = "back", label = "BACK", right = "" },
  }
end

function Menu.wallet(ctx)
  return {
    { id = "give:tokens", label = "+50 TOKENS",
      right = tostring(ctx.tokens or 0) },
    { id = "give:money", label = "+9000 CASH",
      right = tostring(ctx.money or 0) },
    { id = "give:points", label = "+100 POINTS",
      right = tostring(ctx.mallPoints or 0) },
    { id = "back", label = "BACK", right = "" },
  }
end

function Menu.derby(ctx)
  return {
    { id = "derby:open", label = "OPEN SITTING",
      right = ctx.derbyOpen and "OPEN" or "" },
    { id = "derby:catch", label = "LAND A SEAKING", right = "" },
    { id = "derby:finish", label = "WEIGH IN", right = "" },
    { id = "back", label = "BACK", right = "" },
  }
end

function Menu.stamps(ctx)
  return {
    { id = "stamps:all", label = "STAMP ALL",
      right = ctx.stickers or "" },
    { id = "back", label = "BACK", right = "" },
  }
end

-- ListMenu draws a label from x=16 and right-aligns its right column to
-- x=152, so the two share 17 glyph slots.  Anything wider collides into
-- one mashed word ("SPARKS Lv6CHIKAGAI"), which is what a screenshot
-- caught.  16 keeps a visible gap.
Menu.WIDTH = 16

function Menu.rivals(ctx)
  local rows = {
    { id = "rivals:tick", label = "RUN 10 TICKS", right = "" },
    { id = "rivals:gather", label = "CALL ALL HERE", right = "" },
  }
  for _, rival in ipairs(ctx.rivals or {}) do
    rows[#rows + 1] = {
      id = "goto:" .. rival.id,
      -- name and level in the label, a short place in the right column:
      -- selecting the row warps to them anyway, so the place is a hint
      label = ("%s L%d"):format((rival.name or "?"):sub(1, 7),
        rival.level or 5),
      -- four glyphs, so the row still fits at a three-digit level
      right = (rival.locationLabel or "?"):sub(1, 4),
      rival = rival.id,
    }
  end
  rows[#rows + 1] = { id = "back", label = "BACK", right = "" }
  return rows
end

-- The cup circuit.  With a cup running the page is about the cup you are
-- in; without one it is the three ways to start one.
function Menu.cups(ctx)
  local rows = {}
  if ctx.cup then
    rows[#rows + 1] = { id = "cup:play", label = "WIN A MATCH",
                        right = "R" .. tostring(ctx.cup.round or 1) }
    rows[#rows + 1] = { id = "cup:lose", label = "LOSE A MATCH", right = "" }
    rows[#rows + 1] = { id = "cup:arm", label = "ARM REFEREE", right = "" }
    rows[#rows + 1] = { id = "cup:drop", label = "WITHDRAW",
                        right = ctx.cup.alive and "IN" or "OUT" }
  else
    for _, cup in ipairs(ctx.cups or {}) do
      rows[#rows + 1] = { id = "cup:enter:" .. cup.id,
                          label = "ENTER " .. cup.short,
                          right = "L" .. tostring(cup.cap) }
    end
  end
  rows[#rows + 1] = { id = "back", label = "BACK", right = "" }
  return rows
end

function Menu.status(ctx)
  local rows = {}
  local function row(label, ok)
    rows[#rows + 1] = { id = "info", label = label,
                        right = ok and "OK" or "--" }
  end
  row("SHOWA CORE", true)
  row("ARCADE", ctx.have.arcade)
  row("CONTESTS", ctx.have.contests)
  row("MALLS", ctx.have.malls)
  row("RIVALS", ctx.have.rivals)
  row("CUPS", ctx.have.cups)
  rows[#rows + 1] = { id = "info", label = "VENUES",
                      right = tostring(#ctx.venues) }
  rows[#rows + 1] = { id = "info", label = "CAST",
                      right = tostring(#(ctx.rivals or {})) }
  rows[#rows + 1] = { id = "back", label = "BACK", right = "" }
  return rows
end

Menu.PAGES = {
  warp = Menu.warp, games = Menu.games, wallet = Menu.wallet,
  derby = Menu.derby, stamps = Menu.stamps, rivals = Menu.rivals,
  cups = Menu.cups, status = Menu.status,
}

return Menu
