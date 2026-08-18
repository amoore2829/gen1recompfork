-- The registrar's menu, as pure data.
--
-- Split out of main.lua for one reason: a ListMenu row shares SEVENTEEN glyph
-- slots between its label (drawn from x=16) and its right column
-- (right-aligned to x=152), and anything wider collides into one mashed word.
-- This mod shipped "SEE THE BOARDOKIE" past a green suite and a green driver
-- and it was a screenshot that caught it -- the fourth time in this project.
-- So the rows are built here, where a test can walk every page at its worst
-- case and hold them to WIDTH.
local Cups = require("mods.showa_tournaments.cups.list")

local Menu = {}

-- Sixteen, not seventeen: budgeting the last slot away is what keeps a
-- visible gap between the two columns instead of a seam.
Menu.WIDTH = 16

-- ctx = {
--   running = { short = "ROOKIE" } | nil,
--   unlocked = { rookie = true, ... },   -- fee affordable AND gates passed
--   yen = "\xc2\xa5",
--   records = { rookie = { entered = 1, won = 0 }, ... },
--   board = { { a = "YOU", b = "GOROU", mark = "vs" }, ... },
-- }

function Menu.desk(ctx)
  local rows = {}
  if ctx.running then
    -- "BOARD", not "SEE THE BOARD": five glyphs leaves room for the cup name
    -- beside it, and thirteen did not.
    rows[#rows + 1] = { id = "board", label = "BOARD",
                        right = ctx.running.short }
    rows[#rows + 1] = { id = "withdraw", label = "WITHDRAW" }
  else
    for _, cup in ipairs(Cups.LIST) do
      rows[#rows + 1] = {
        id = "enter:" .. cup.id,
        label = cup.short,
        right = ctx.unlocked and ctx.unlocked[cup.id]
          and ((ctx.yen or "") .. cup.fee) or "LOCKED",
      }
    end
  end
  rows[#rows + 1] = { id = "records", label = "RECORDS" }
  rows[#rows + 1] = { id = "close", label = "LEAVE" }
  return rows
end

function Menu.board(ctx)
  if not ctx.board then
    return { { id = "close", label = "NO CUP RUNNING" } }
  end
  local rows = {}
  for i, match in ipairs(ctx.board) do
    -- six, one, six and the two spaces around the mark: fifteen glyphs, and
    -- no right column to collide with
    rows[#rows + 1] = {
      id = "match:" .. i,
      label = ("%-6s %s %s"):format((match.a or "BYE"):sub(1, 6),
        match.mark or "v", (match.b or "BYE"):sub(1, 6)),
    }
  end
  rows[#rows + 1] = { id = "back", label = "BACK" }
  return rows
end

function Menu.records(ctx)
  local rows = {}
  for _, cup in ipairs(Cups.LIST) do
    local record = (ctx.records or {})[cup.id] or { entered = 0, won = 0 }
    rows[#rows + 1] = {
      id = "record:" .. cup.id, label = cup.short,
      right = ("%d/%d"):format(record.won, record.entered),
    }
  end
  rows[#rows + 1] = { id = "back", label = "BACK" }
  return rows
end

Menu.PAGES = { desk = Menu.desk, board = Menu.board, records = Menu.records }
Menu.TITLES = { desk = "SHOWA CUP", board = "THE BOARD", records = "RECORDS" }

-- What a row costs in glyph slots.  The label and the right column share the
-- budget; a row with no right column spends only its label.
--
-- Bytes, not codepoints, so a multi-byte glyph (the ¥ is two) is charged for
-- more slots than it draws.  That errs TIGHT, which is the right direction
-- for a budget whose failure mode is two words mashed together.
function Menu.width(row)
  return #(row.label or "") + #(row.right or "")
end

return Menu
