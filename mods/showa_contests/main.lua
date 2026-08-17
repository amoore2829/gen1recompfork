-- Showa Contests: the Lake of Rage Seaking Derby, plus a wrap over Gold's
-- own Bug Catching Contest scores.  The derby judge stands on the south
-- shore; talk to open a session, catch fish (every catch is measured
-- deterministically), talk again for the standings against the competitor
-- field the rival mod fills in.
local Judging = require("mods.showa_contests.framework.judging")
local Session = require("mods.showa_contests.framework.session")

local LAKE_MAP = "LAKE_OF_RAGE"

return function(mod)
  local core = assert(mod.find("showa_core"),
    "showa_contests needs showa_core").exports

  -- ------- persistent record book

  local state = mod.save:get("state")
  if type(state) ~= "table" or state.v ~= 1 then
    state = { v = 1, records = {} } -- records.fish / records.bug
  end
  local function persist() mod.save:set("state", state) end
  persist()

  core.venues.register("LAKE_DERBY", {
    map = LAKE_MAP, label = "SEAKING DERBY", tags = { "contest", "fishing" },
    x = 18, y = 29,
  })

  -- ------- the sitting (in-memory: a derby is one session at the lake)

  local session = Session.new()
  local competitors = {}

  local function judgeCatch(mon)
    if not session.active or type(mon) ~= "table" then return nil end
    local size = Judging.fishSize(mon)
    Session.record(session, "YOU", tostring(mon.species or "???"), size)
    return size
  end

  mod.events:on("pokemon.caught", function(payload)
    local mon = type(payload) == "table" and (payload.mon or payload) or nil
    if mon then judgeCatch(mon) end
  end)

  local function startDerby()
    Session.start(session)
  end

  local function finishDerby()
    local field = {}
    for _, fn in ipairs(competitors) do
      local ok, entry = pcall(fn)
      if ok and type(entry) == "table" then field[#field + 1] = entry end
    end
    local standings = Session.finish(session, field)
    local top = standings[1]
    if top and top.you then
      local record = state.records.fish
      if not record or top.size > record.size then
        state.records.fish = { size = top.size, species = top.species,
                               day = core.clock.today() }
        persist()
        core.news.post(("A %dcm %s won the SEAKING DERBY -- a new record!")
          :format(top.size, top.species))
      else
        core.news.post(("The SEAKING DERBY went to a %dcm %s.")
          :format(top.size, top.species))
      end
    elseif top then
      core.news.post(("%s won the SEAKING DERBY with a %dcm %s.")
        :format(top.name, top.size, tostring(top.species or "fish")))
    end
    return standings
  end

  -- ------- the judge on the south shore

  -- Not ctx.vm:showText(text): that takes a KEY and prints "..." for a
  -- sentence.  core.dialogue parks the line in the text table first.
  local function say(ctx, text)
    return core.dialogue.say(ctx, text)
  end

  mod.content.commands:register("showa_contests:judge", function(ctx)
    if not session.active then
      startDerby()
      say(ctx, "The SEAKING DERBY is open!\nCatch the biggest fish in "
        .. "the lake,\nthen report back to me.")
      return "end"
    end
    local standings = finishDerby()
    if #standings == 0 then
      say(ctx, "Not one fish landed?\nThe derby is closed. Come again!")
      return "end"
    end
    local lines = {}
    for i = 1, math.min(3, #standings) do
      local row = standings[i]
      lines[#lines + 1] = ("%d) %s %dcm %s"):format(i,
        row.you and "YOU" or row.name, row.size,
        tostring(row.species or ""))
    end
    say(ctx, "DERBY RESULTS!\n" .. table.concat(lines, "\n"))
    return "end"
  end)

  local JUDGE = {
    judge = { sprite = "SPRITE_GENTLEMAN", x = 18, y = 29,
      movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
      scriptKey = { { "showa_contests:judge" } } },
  }
  local spawnedIds = {}
  local function spawnJudge()
    for key, def in pairs(JUDGE) do
      if not spawnedIds[key] then
        local ok, id = pcall(function()
          return mod.world:spawnNpc(LAKE_MAP, def)
        end)
        if ok and id then spawnedIds[key] = id end
      end
    end
  end
  mod.events:on("game.ready", spawnJudge)
  mod.events:on("map.entered", function() spawnJudge() end)

  -- ------- the Bug Contest wrap (Gold runs the vanilla contest itself)

  mod.events:on("bug_contest.scored", function(payload)
    if type(payload) ~= "table" then return end
    local score = tonumber(payload.score) or 0
    local species = payload.mon and payload.mon.species
    local record = state.records.bug
    if not record or score > record.score then
      state.records.bug = { score = score, species = species,
                            day = core.clock.today() }
      persist()
      core.news.post(("A new Bug Contest record: %d points!"):format(score))
    end
  end)

  -- ------- exports (the rival seam + dev drivers)

  mod.exports.records = function()
    local out = {}
    for kind, record in pairs(state.records) do
      local copy = {}
      for k, v in pairs(record) do copy[k] = v end
      out[kind] = copy
    end
    return out
  end
  mod.exports.isSessionActive = function() return session.active end
  -- fn() -> { name, species, size } | nil; consulted when a derby ends
  mod.exports.registerCompetitor = function(fn)
    assert(type(fn) == "function", "competitor must be a function")
    competitors[#competitors + 1] = fn
  end
  mod.exports.debug = {
    start = startDerby,
    finish = finishDerby,
    catch = judgeCatch,
    warp = function(x, y, facing)
      return mod.world:warpTo(LAKE_MAP, x or 18, y or 30, facing or "up")
    end,
  }
end
