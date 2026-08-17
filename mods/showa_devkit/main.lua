-- Showa Dev Kit: a test menu for the whole suite, on the START menu as
-- SHOWA DEV.
--
-- Warp to any venue, open any cabinet without paying, stock the wallet,
-- run the rival simulation forward, open or settle a derby, stamp the
-- rally, and read a diagnostic of what is installed.  Every branch that
-- depends on a feature mod is hidden when that mod is absent, so this
-- works on any subset of the suite.
--
-- The menu tree lives in menu.lua as pure data; this file is the wiring.
local Menu = require("mods.showa_devkit.menu")

local SCREEN = "ShowaDevKit"

return function(mod)
  local core = assert(mod.find("showa_core"),
    "showa_devkit needs showa_core").exports

  local function ex(id)
    local other = mod.find(id)
    return other and other.exports or nil
  end

  -- resolved lazily: a mod's exports table is only there once it loaded,
  -- and the manager can turn one off between boots
  local function parts()
    return {
      arcade = ex("showa_arcade"),
      contests = ex("showa_contests"),
      malls = ex("showa_malls"),
      rivals = ex("showa_rivals"),
    }
  end

  local function context()
    local p = parts()
    local venues = {}
    for _, id in ipairs(core.venues.all()) do
      local venue = core.venues.get(id)
      venues[#venues + 1] = { id = id, label = venue.label, map = venue.map }
    end
    local roster = {}
    if p.rivals then
      for _, entry in ipairs(p.rivals.roster()) do
        local venue = entry.location and core.venues.get(entry.location)
        roster[#roster + 1] = {
          id = entry.id, name = entry.name, location = entry.location,
          locationLabel = venue and venue.label or "?",
          level = entry.party and entry.party[1] and entry.party[1].level,
        }
      end
    end
    local stickers
    if p.malls then
      stickers = ("%d/4"):format(p.malls.stickerCount())
    end
    local save = mod.game and mod.game.save
    return {
      have = { arcade = p.arcade ~= nil, contests = p.contests ~= nil,
               malls = p.malls ~= nil, rivals = p.rivals ~= nil },
      venues = venues,
      rivals = roster,
      tokens = core.wallet.get("ARCADE_TOKEN"),
      mallPoints = core.wallet.get("MALL_POINT"),
      money = (save and save.player and save.player.money) or 0,
      derbyOpen = p.contests and p.contests.isSessionActive() or false,
      stickers = stickers,
    }, p
  end

  -- ------- the actions
  --
  -- Each returns a short line for the footer, so a press always says
  -- what it did rather than leaving you guessing.

  local function warpTo(venueId)
    local venue = core.venues.get(venueId)
    if not venue then return "no such venue" end
    -- one cell south of the venue spot, facing it
    local ok, err = mod.world:warpTo(venue.map, venue.x or 5,
      (venue.y or 3) + 1, "up")
    if not ok then return "refused: " .. tostring(err) end
    return "warped to " .. venue.label
  end

  local function play(screenId)
    local ok = pcall(function()
      mod.ui.push(mod.game, screenId, {
        prize = { id = "STICKER_EKANS", label = "EKANS STICKER",
                  tier = "COMMON" },
        onDone = function() end,
      })
    end)
    return ok and "opened" or "could not open"
  end

  local function stockWallet(what)
    local p = parts()
    if what == "tokens" then
      core.wallet.define("ARCADE_TOKEN", "GAME TOKEN")
      core.wallet.add("ARCADE_TOKEN", 50)
      return "+50 tokens"
    elseif what == "points" then
      core.wallet.define("MALL_POINT", "MALL POINT")
      core.wallet.add("MALL_POINT", 100)
      return "+100 mall points"
    end
    local save = mod.game and mod.game.save
    if not (save and save.player) then return "no save yet" end
    save.player.money = (save.player.money or 0) + 9000
    return "+9000 money"
  end

  local function derby(action)
    local p = parts()
    if not p.contests then return "contests not installed" end
    if action == "open" then
      p.contests.debug.start()
      return "a sitting is open"
    elseif action == "catch" then
      if not p.contests.isSessionActive() then return "open a sitting first" end
      p.contests.debug.catch({ species = "SEAKING", level = 38,
        dvs = { attack = 15, defense = 15, speed = 15, special = 15 } })
      return "landed a big SEAKING"
    end
    local standings = p.contests.debug.finish()
    local top = standings and standings[1]
    if not top then return "nobody entered" end
    return ("%s won at %dcm"):format(top.you and "you" or top.name, top.size)
  end

  local function stampAll()
    local p = parts()
    if not p.malls then return "malls not installed" end
    -- through the same verb the counters use, so this exercises the real
    -- path rather than writing the save behind its back
    local commands = mod.game and mod.game.data and mod.game.data.commands
    local fn = commands and commands["showa_malls:counter"]
    fn = type(fn) == "table" and fn.fn or fn
    if type(fn) ~= "function" then return "counter verb missing" end
    for _, id in ipairs({ "TOYS", "RECORDS", "FASHION", "RAMEN" }) do
      pcall(fn, { generation = 2 }, id)
    end
    return ("stamped: %d/4"):format(p.malls.stickerCount())
  end

  local function tickRivals(n)
    local p = parts()
    if not p.rivals then return "rivals not installed" end
    for _ = 1, n do p.rivals.debug.tick() end
    p.rivals.debug.refresh()
    return ("ran %d ticks"):format(n)
  end

  -- Put every rival on the map the player is standing on, which is the
  -- fastest way to eyeball the whole cast at once.
  local function gatherRivals()
    local p = parts()
    if not p.rivals then return "rivals not installed" end
    local here = mod.world:current()
    if not here then return "no overworld" end
    local venue
    for _, id in ipairs(core.venues.all()) do
      local candidate = core.venues.get(id)
      if candidate.map == here.mapId then venue = id break end
    end
    if not venue then return "this map is not a venue" end
    p.rivals.debug.sendAll(venue)
    p.rivals.debug.refresh()
    return "everyone is here"
  end

  local function gotoRival(rivalId)
    local p = parts()
    if not p.rivals then return "rivals not installed" end
    for _, entry in ipairs(p.rivals.roster()) do
      if entry.id == rivalId then
        local note = warpTo(entry.location)
        p.rivals.debug.refresh()
        return note
      end
    end
    return "not on the roster"
  end

  -- ------- the screen

  local open  -- forward declaration: pages re-open each other

  local function pageRows(page, ctx)
    if page == "root" then return Menu.root(ctx) end
    local build = Menu.PAGES[page]
    return build and build(ctx) or Menu.root(ctx)
  end

  local function titleFor(page)
    local titles = { root = "SHOWA DEV", warp = "WARP TO", games = "CABINETS",
                     wallet = "WALLET", derby = "DERBY", stamps = "STAMPS",
                     rivals = "RIVALS", status = "DIAGNOSTIC" }
    return titles[page] or "SHOWA DEV"
  end

  local function act(row, ctx)
    local id = row.id or ""
    if row.venue then return warpTo(row.venue) end
    if row.rival then return gotoRival(row.rival) end
    local verb, arg = id:match("^(%a+):(.+)$")
    if verb == "play" then return play(arg) end
    if verb == "give" then return stockWallet(arg) end
    if verb == "derby" then return derby(arg) end
    if verb == "stamps" then return stampAll() end
    if verb == "rivals" then
      if arg == "tick" then return tickRivals(10) end
      if arg == "gather" then return gatherRivals() end
    end
    return nil
  end

  open = function(game, page, note)
    local ctx = context()
    local rows = pageRows(page or "root", ctx)
    local items = {}
    for _, row in ipairs(rows) do
      items[#items + 1] = { label = row.label, right = row.right,
                            value = row }
    end
    return mod.ui.ListMenu.new(game, titleFor(page or "root"), items, {
      wrap = true, keyRepeat = true,
      footer = note,
      onChoose = function(item, menu)
        local row = item.value
        if row.id == "close" then menu:close(); return end
        if row.id == "back" then
          menu:close()
          mod.ui.push(game, SCREEN, { page = "root" })
          return
        end
        if row.id == "info" then return end
        -- a page name with no colon opens that page
        if Menu.PAGES[row.id] then
          menu:close()
          mod.ui.push(game, SCREEN, { page = row.id })
          return
        end
        local said = act(row, ctx)
        menu:close()
        -- a warp has to land in the world, not back in a menu
        if row.venue or row.rival then return end
        mod.ui.push(game, SCREEN, { page = page or "root", note = said })
      end,
      onCancel = function(menu)
        menu:close()
        if page and page ~= "root" then
          mod.ui.push(game, SCREEN, { page = "root" })
        end
      end,
    })
  end

  mod.content.screens:register(SCREEN, {
    new = function(game, opts)
      opts = opts or {}
      return open(game, opts.page or "root", opts.note)
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(nextFn, game, items)
    local out = nextFn(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "SHOWA DEV",
      onSelect = function() mod.ui.push(game, SCREEN, { page = "root" }) end,
    })
  end)

  -- ------- exports, so a driver can drive the kit itself

  mod.exports.context = context
  mod.exports.rows = function(page)
    return pageRows(page or "root", (context()))
  end
  mod.exports.run = function(rowId, arg)
    local ctx = context()
    return act({ id = rowId, venue = arg and rowId == "venue" and arg or nil },
      ctx)
  end
  mod.exports.warpTo = warpTo
  mod.exports.tickRivals = tickRivals
  mod.exports.stockWallet = stockWallet
end
