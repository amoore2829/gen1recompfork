-- The menu tree, built from literals.  The point of keeping menu.lua
-- pure is that the branches which only appear when a feature mod is
-- installed can be proven here, including the one that matters most:
-- the kit must not offer a page it cannot deliver.
--
--   luajit mods/showa_devkit/tests/devkit_menu_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Menu = require("mods.showa_devkit.menu")

local function ctx(have, extra)
  local base = {
    have = have or {},
    venues = { { id = "GOLDENROD_ARCADE", label = "GOLDENROD ARCADE",
                 map = "GOLDENROD_GAME_CORNER" },
               { id = "LAKE_DERBY", label = "SEAKING DERBY",
                 map = "LAKE_OF_RAGE" },
               { id = "ELM_LAB", label = "ELM'S LAB", map = "ELMS_LAB" } },
    rivals = {},
    tokens = 0, mallPoints = 0, money = 0,
    derbyOpen = false, stickers = "0/4",
  }
  for key, value in pairs(extra or {}) do base[key] = value end
  return base
end

local function ids(rows)
  local out = {}
  for _, row in ipairs(rows) do out[#out + 1] = row.id end
  return table.concat(out, ",")
end

local function has(rows, id)
  for _, row in ipairs(rows) do if row.id == id then return true end end
  return false
end

-- ------- the root only offers what is installed

do
  local bare = Menu.root(ctx({}))
  T.check(has(bare, "warp"), "warping is always offered")
  T.check(has(bare, "wallet"), "so is the wallet")
  T.check(has(bare, "status"), "and the diagnostic")
  T.check(has(bare, "close"), "and a way out")
  T.check(not has(bare, "games"), "no cabinets without the arcade")
  T.check(not has(bare, "derby"), "no derby without contests")
  T.check(not has(bare, "stamps"), "no rally without malls")
  T.check(not has(bare, "rivals"), "no roster without rivals")

  local full = Menu.root(ctx({ arcade = true, contests = true,
                               malls = true, rivals = true }))
  for _, id in ipairs({ "warp", "games", "wallet", "derby", "stamps",
                        "rivals", "status", "close" }) do
    T.check(has(full, id), "the full suite offers " .. id)
  end

  -- every page the root points at must exist, or a press opens nothing
  for _, row in ipairs(full) do
    if row.id ~= "close" and row.id ~= "warp" then
      T.check(Menu.PAGES[row.id] ~= nil or row.id == "warp",
        "the root only offers pages that exist: " .. row.id)
    end
  end
  T.check(Menu.PAGES.warp ~= nil, "including warp")
end

-- ------- the derby row reports the live state

do
  local shut = Menu.root(ctx({ contests = true }))
  local open = Menu.root(ctx({ contests = true }, { derbyOpen = true }))
  local function rightOf(rows, id)
    for _, row in ipairs(rows) do if row.id == id then return row.right end end
  end
  T.eq(rightOf(shut, "derby"), "SHUT", "a closed derby says so")
  T.eq(rightOf(open, "derby"), "OPEN", "and an open one says so")
end

-- ------- warping lists every venue, sorted, with a way back

do
  local rows = Menu.warp(ctx({}))
  T.eq(#rows, 4, "three venues and a BACK")
  T.eq(rows[1].label, "ELM'S LAB", "sorted by label")
  T.eq(rows[#rows].id, "back", "with BACK last")
  for i = 1, #rows - 1 do
    T.check(rows[i].venue ~= nil, "every venue row carries its id")
  end
end

-- ------- every page ends in a way back

do
  for name, build in pairs(Menu.PAGES) do
    local rows = build(ctx({ arcade = true, contests = true, malls = true,
                             rivals = true }))
    T.check(#rows >= 1, name .. " has rows")
    T.eq(rows[#rows].id, "back", name .. " ends with BACK")
  end
end

-- ------- the roster page names who is where

do
  local rows = Menu.rivals(ctx({ rivals = true }, { rivals = {
    { id = "elm", name = "ELM", location = "ELM_LAB",
      locationLabel = "ELM'S LAB", level = 12 },
    { id = "pichu", name = "SPARKS", location = "GOLDENROD_ARCADE",
      locationLabel = "GOLDENROD ARCADE", level = 14 },
  } }))
  T.check(has(rows, "rivals:tick"), "the roster can run the simulation")
  T.check(has(rows, "rivals:gather"), "and call everyone over")
  local found = 0
  for _, row in ipairs(rows) do
    if row.rival then
      found = found + 1
      T.check(row.label:find("L%d"), "a rival row shows a level: " .. row.label)
      T.check(row.right ~= "", "and where they are")
    end
  end
  T.eq(found, 2, "one row per rival")
end

-- ------- the diagnostic tells the truth about a partial install

do
  local rows = Menu.status(ctx({ arcade = true }))
  local seen = {}
  for _, row in ipairs(rows) do seen[row.label] = row.right end
  T.eq(seen["SHOWA CORE"], "OK", "core is always in")
  T.eq(seen["ARCADE"], "OK", "the arcade is installed here")
  T.eq(seen["CONTESTS"], "--", "contests are not")
  T.eq(seen["RIVALS"], "--", "nor rivals")
  T.eq(seen["VENUES"], "3", "and the venue count is real")
end

-- ------- nothing may overflow the box
--
-- ListMenu shares 17 glyph slots between a row's label and its right
-- column, so anything wider collides into one mashed word
-- ("SEAKING DERBYSHUT", "SPARKS Lv6CHIKAGAI").  Both were caught by
-- screenshot rather than by a green suite; pinned here so neither can
-- come back.

do
  local WIDTH = Menu.WIDTH
  local full = ctx({ arcade = true, contests = true, malls = true,
                     rivals = true }, { rivals = {
    { id = "magby", name = "TAKESHI", location = "CHIKAGAI",
      locationLabel = "CHIKAGAI PASSAGE", level = 100 },
    { id = "tyrogue_chan", name = "RYU", location = "ECRUTEAK",
      locationLabel = "ECRUTEAK CITY", level = 42 },
  }, stickers = "4/4", tokens = 9999, money = 999999, mallPoints = 100 })

  local pages = { root = Menu.root }
  for name, build in pairs(Menu.PAGES) do pages[name] = build end
  for name, build in pairs(pages) do
    for _, row in ipairs(build(full)) do
      local used = #row.label + #(row.right or "")
      T.check(used <= WIDTH,
        ("%s row fits the box: %q + %q = %d"):format(
          name, row.label, row.right or "", used))
    end
  end
end

T.finish("showa_devkit menu")
