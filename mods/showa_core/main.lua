-- Showa Core: the shared library mod for the Showa Johto suite.  Ships no
-- gameplay -- it publishes a wallet, a clock mirror, a scheduler, the world
-- news feed, the venue graph, and the arcade minigame scaffold through
-- mod.exports, which is the suite's only cross-mod channel.
--
-- Consumers: local core = mod.find("showa_core").exports
local Wallet = require("mods.showa_core.lib.wallet")
local Clock = require("mods.showa_core.lib.clock")
local Scheduler = require("mods.showa_core.lib.scheduler")
local News = require("mods.showa_core.lib.news")
local Venues = require("mods.showa_core.lib.venues")
local Minigame = require("mods.showa_core.lib.minigame")
local Dialogue = require("mods.showa_core.lib.dialogue")

return function(mod)
  -- ------- persistent state, one versioned blob

  local state = mod.save:get("state")
  if type(state) ~= "table" or state.v ~= 1 then
    state = { v = 1, wallet = {}, news = {} }
  end
  Wallet.ensure(state.wallet)
  News.ensure(state.news)
  local function persist() mod.save:set("state", state) end
  persist()

  -- ------- the clock mirror

  local clock = Clock.new()
  mod.events:on("clock.day_changed", function(payload)
    Clock.onDayChanged(clock, payload)
  end)
  mod.events:on("world.tod_changed", function(payload)
    Clock.onTodChanged(clock, payload)
  end)
  mod.hooks:wrap("world.tod", function(nextFn, ...)
    return Clock.observeTod(clock, nextFn(...))
  end)

  -- ------- the venue graph (in-memory; dependents re-register every boot)

  local graph = Venues.new()

  -- ------- the news screen, reachable from the START menu

  mod.content.screens:register("ShowaNews", {
    new = function(game)
      local items = {}
      for _, entry in ipairs(News.recent(state.news, 20)) do
        items[#items + 1] = {
          label = entry.text,
          right = entry.day and tostring(entry.day):sub(1, 3) or "",
        }
      end
      return mod.ui.ListMenu.new(game, "TOWN NEWS", items, {
        onChoose = function(_, menu) menu:close() end,
      })
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(nextFn, game, items)
    local out = nextFn(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "NEWS",
      onSelect = function() mod.ui.push(game, "ShowaNews") end,
    })
  end)

  -- ------- the published API

  mod.exports.version = "0.1.0"

  mod.exports.wallet = {
    define = function(id, label)
      Wallet.define(state.wallet, id, label); persist()
    end,
    defined = function(id) return Wallet.defined(state.wallet, id) end,
    label = function(id) return Wallet.label(state.wallet, id) end,
    get = function(id) return Wallet.get(state.wallet, id) end,
    add = function(id, n)
      local balance = Wallet.add(state.wallet, id, n); persist()
      return balance
    end,
    spend = function(id, n)
      local ok, balance = Wallet.spend(state.wallet, id, n)
      if ok then persist() end
      return ok, balance
    end,
  }

  mod.exports.clock = {
    today = function() return Clock.today(clock) end,
    tod = function() return Clock.tod(clock) end,
  }

  mod.exports.scheduler = {
    normalize = Scheduler.normalize,
    -- answers against the live clock; pass day/tod explicitly in tests
    isOpen = function(normalized, day, tod)
      return Scheduler.isOpen(normalized,
        day or Clock.today(clock), tod or Clock.tod(clock))
    end,
  }

  mod.exports.news = {
    post = function(entry)
      if type(entry) == "string" then entry = { text = entry } end
      entry.day = entry.day or Clock.today(clock)
      local serial = News.post(state.news, entry)
      persist()
      return serial
    end,
    recent = function(n) return News.recent(state.news, n) end,
  }

  mod.exports.venues = {
    register = function(id, def) return Venues.register(graph, id, def) end,
    connect = function(a, b, cost) return Venues.connect(graph, a, b, cost) end,
    get = function(id) return Venues.get(graph, id) end,
    neighbors = function(id) return Venues.neighbors(graph, id) end,
    atMap = function(mapId) return Venues.atMap(graph, mapId) end,
    all = function() return Venues.all(graph) end,
  }

  mod.exports.minigame = {
    screen = Minigame.screen,
  }

  -- Saying something from a verb is NOT as simple as handing the VM a
  -- sentence; see lib/dialogue.lua.  Every Showa mod goes through this.
  mod.exports.dialogue = {
    say = Dialogue.say,
    lastShown = Dialogue.lastShown,
  }
end
