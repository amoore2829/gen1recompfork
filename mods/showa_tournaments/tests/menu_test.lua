-- The registrar's menu, walked at its worst case.
--
-- This suite exists because "SEE THE BOARDOKIE" shipped past a green rules
-- suite AND a green Gold driver: both assert STATE, and a column collision is
-- a RENDER fault.  So every page is built here at the longest strings it can
-- ever carry and held to the row budget.
--
--   luajit mods/showa_tournaments/tests/menu_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Menu = require("mods.showa_tournaments.desk.menu")
local Cups = require("mods.showa_tournaments.cups.list")

local YEN = "\xc2\xa5"

local function widest(rows, page)
  for _, row in ipairs(rows) do
    local width = Menu.width(row)
    T.check(width <= Menu.WIDTH,
      ("%s row fits the budget: %q + %q = %d <= %d"):format(page,
        row.label or "", row.right or "", width, Menu.WIDTH))
  end
end

-- ------- the desk, with no cup running, at every lock state

do
  for _, unlocked in ipairs({ true, false }) do
    local gates = {}
    for _, cup in ipairs(Cups.LIST) do gates[cup.id] = unlocked end
    local rows = Menu.desk({ unlocked = gates, yen = YEN })
    T.eq(#rows, #Cups.LIST + 2,
      "every cup, plus RECORDS and LEAVE (" .. #rows .. ")")
    widest(rows, "desk/" .. tostring(unlocked))

    local ids = {}
    for _, row in ipairs(rows) do ids[row.id] = row end
    for _, cup in ipairs(Cups.LIST) do
      T.check(ids["enter:" .. cup.id] ~= nil, cup.id .. " is on the desk")
      T.eq(ids["enter:" .. cup.id].right,
        unlocked and (YEN .. cup.fee) or "LOCKED",
        cup.id .. " shows its " .. (unlocked and "fee" or "lock"))
    end
    T.check(ids.records ~= nil, "RECORDS is on the desk")
    T.check(ids.close ~= nil, "LEAVE is on the desk")
  end
end

-- ------- the desk with a cup running (the row that collided)

do
  for _, cup in ipairs(Cups.LIST) do
    local rows = Menu.desk({ running = { short = cup.short } })
    widest(rows, "desk/running/" .. cup.id)
    T.eq(rows[1].id, "board", "the board is the first thing offered")
    T.eq(rows[1].right, cup.short, "labelled with the cup you are in")
    T.eq(rows[2].id, "withdraw", "then WITHDRAW")
    -- the regression itself, named
    T.check(Menu.width(rows[1]) <= Menu.WIDTH,
      ("BOARD + %s does not collide (%d)"):format(cup.short,
        Menu.width(rows[1])))
  end

  -- and a cup name longer than any real one still fits
  local rows = Menu.desk({ running = { short = ("X"):rep(10) } })
  widest(rows, "desk/running/long")
end

-- ------- the board

do
  local ctx = { board = {
    { a = "YOU", b = "GOROU", mark = "v" },
    { a = "SPARKS", b = "TAKESHI", mark = "<" },
    { a = "BYE", b = "MASARU", mark = ">" },
  } }
  local rows = Menu.board(ctx)
  T.eq(#rows, 4, "three matches and a BACK row")
  widest(rows, "board")
  T.eq(rows[#rows].id, "back", "BACK is last")

  -- worst case: two names at the longest a real entrant can have
  local long = { board = {} }
  for i = 1, 4 do
    long.board[i] = { a = ("A"):rep(20), b = ("B"):rep(20), mark = "v" }
  end
  widest(Menu.board(long), "board/long")

  -- a match with a side missing must not crash or run wide
  widest(Menu.board({ board = { { mark = "v" } } }), "board/empty")

  local none = Menu.board({})
  T.eq(#none, 1, "with no cup the board says so in one row")
  widest(none, "board/none")
end

-- ------- records

do
  local rows = Menu.records({ records = {
    rookie = { entered = 3, won = 1 }, open = { entered = 12, won = 11 } } })
  T.eq(#rows, #Cups.LIST + 1, "one row per cup, plus BACK")
  widest(rows, "records")

  -- a cup never entered still reads
  local fresh = Menu.records({})
  for i = 1, #Cups.LIST do
    T.eq(fresh[i].right, "0/0", "an unplayed cup reads 0/0")
  end
  widest(fresh, "records/fresh")

  -- and a record book nobody could really fill still fits the row
  widest(Menu.records({ records = {
    rookie = { entered = 9999, won = 9999 },
    open = { entered = 9999, won = 9999 },
    master = { entered = 9999, won = 9999 } } }), "records/huge")
end

-- ------- every page is reachable and titled

do
  for page, build in pairs(Menu.PAGES) do
    T.check(type(build) == "function", page .. " builds rows")
    T.check(type(Menu.TITLES[page]) == "string", page .. " has a title")
    T.check(#Menu.TITLES[page] <= 12,
      ("%s's title fits the header (%q)"):format(page, Menu.TITLES[page]))
  end
  T.check(Menu.PAGES.desk ~= nil, "the desk is a page")
  T.check(Menu.PAGES.board ~= nil, "the board is a page")
  T.check(Menu.PAGES.records ~= nil, "records is a page")
end

-- ------- width itself

do
  T.eq(Menu.width({ label = "ABC" }), 3, "a row with no right column costs 3")
  T.eq(Menu.width({ label = "ABC", right = "DE" }), 5, "and with one, 5")
  T.eq(Menu.width({}), 0, "an empty row costs nothing")
end

T.finish("showa_tournaments menu")
