-- Showa Malls: an Olivine shopping arcade over two floors, joined to
-- Goldenrod's underground by a chikagai passage, with a stamp rally.
--
-- Reaching it: greeters outside (Olivine street, Goldenrod Underground)
-- warp the player in, and the arcade's own warps carry them between the
-- floors, the passage, and back out to the street.  Greeters rather than
-- a stamped shopfront on purpose -- patching a vanilla city's blocks is
-- the one change this suite cannot verify without eyes on the render.
local Maps = require("mods.showa_malls.world.maps")
local Rally = require("mods.showa_malls.world.rally")

return function(mod)
  local core = assert(mod.find("showa_core"),
    "showa_malls needs showa_core").exports

  -- ------- persistent state

  local state = mod.save:get("state")
  if type(state) ~= "table" or state.v ~= 1 then
    state = { v = 1, stickers = {}, setClaimed = false }
  end
  local function persist() mod.save:set("state", state) end
  persist()

  -- ------- the maps

  for _, record in ipairs(Maps.records()) do
    mod.content.maps:register(record.id, record)
  end

  core.venues.register("SHOWA_MALL", {
    map = Maps.ONE_F, label = "SHOWA MALL", tags = { "mall", "shopping" },
    x = 5, y = 3,
  })
  core.venues.register("CHIKAGAI", {
    map = Maps.TUNNEL, label = "CHIKAGAI PASSAGE", tags = { "tunnel" },
    x = 5, y = 3,
  })
  core.venues.connect("SHOWA_MALL", "CHIKAGAI", 1)

  -- ------- the sticker rally

  local function grant(storeId)
    if state.stickers[storeId] then return false end
    state.stickers[storeId] = core.clock.today() or "SOMEDAY"
    persist()
    return true
  end

  local function say(ctx, text)
    if ctx and ctx.vm and ctx.vm.showText then ctx.vm:showText(text) end
  end

  mod.content.commands:register("showa_malls:counter", function(ctx, storeId)
    local store = Rally.byId(storeId)
    if not store then return "end" end
    if grant(store.id) then
      local have, total = Rally.count(state.stickers), Rally.total()
      say(ctx, ("%s\nRALLY STICKERS: %d/%d"):format(store.line, have, total))
      if Rally.complete(state.stickers) then
        core.news.post("Somebody filled a whole mall stamp book!")
      end
    else
      say(ctx, ("%s\nYou already have this one."):format(store.label))
    end
    return "end"
  end)

  mod.content.commands:register("showa_malls:info", function(ctx)
    local have, total = Rally.count(state.stickers), Rally.total()
    if not Rally.complete(state.stickers) then
      say(ctx, ("INFO DESK.\nStamp rally: %d of %d stickers.\nVisit every "
        .. "counter for a prize!"):format(have, total))
      return "end"
    end
    if state.setClaimed then
      say(ctx, "INFO DESK.\nYour book is full. Thank you\nfor shopping "
        .. "with us!")
      return "end"
    end
    state.setClaimed = true
    persist()
    core.wallet.define("MALL_POINT", "MALL POINT")
    core.wallet.add("MALL_POINT", 100)
    say(ctx, "INFO DESK.\nA full book! Please accept\n100 MALL POINTS.")
    core.news.post("A full stamp book was turned in at the mall info desk!")
    return "end"
  end)

  -- ------- the album

  mod.content.screens:register("ShowaStickerAlbum", {
    new = function(game)
      local items = {}
      for _, row in ipairs(Rally.album(state.stickers)) do
        items[#items + 1] = {
          label = row.label,
          right = row.owned and "GOT" or "----",
        }
      end
      local have, total = Rally.count(state.stickers), Rally.total()
      return mod.ui.ListMenu.new(game,
        ("STAMP RALLY %d/%d"):format(have, total), items, {
          onChoose = function(_, menu) menu:close() end,
        })
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(nextFn, game, items)
    local out = nextFn(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "STAMPS",
      onSelect = function() mod.ui.push(game, "ShowaStickerAlbum") end,
    })
  end)

  -- ------- the cast: counters inside, greeters outside

  mod.content.commands:register("showa_malls:enter_mall", function(ctx)
    say(ctx, "Welcome to the SHOWA MALL!\nRight this way...")
    mod.world:warpTo(Maps.ONE_F, 3, 6, "up")
    return "end"
  end)

  mod.content.commands:register("showa_malls:enter_tunnel", function(ctx)
    say(ctx, "The CHIKAGAI passage runs\nall the way to OLIVINE!")
    mod.world:warpTo(Maps.TUNNEL, 3, 6, "up")
    return "end"
  end)

  local CAST = {}
  for _, store in ipairs(Rally.STORES) do
    CAST[#CAST + 1] = { map = store.map, def = {
      sprite = store.sprite, x = store.x, y = store.y,
      movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
      scriptKey = { { "showa_malls:counter", store.id } },
    } }
  end
  -- the info desk, on the ground floor's south aisle
  CAST[#CAST + 1] = { map = Maps.ONE_F, def = {
    sprite = "SPRITE_CLERK", x = 1, y = 6,
    movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
    scriptKey = { { "showa_malls:info" } },
  } }
  -- greeters: free cells verified against each map's collision and
  -- object layers (Olivine's south shopping block; the Underground's
  -- west corridor)
  CAST[#CAST + 1] = { map = "OLIVINE_CITY", def = {
    sprite = "SPRITE_LASS", x = 17, y = 18,
    movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
    scriptKey = { { "showa_malls:enter_mall" } },
  } }
  CAST[#CAST + 1] = { map = "GOLDENROD_UNDERGROUND", def = {
    sprite = "SPRITE_GENTLEMAN", x = 5, y = 13,
    movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
    scriptKey = { { "showa_malls:enter_tunnel" } },
  } }

  local spawnedIds = {}
  local function spawnCast()
    for i, entry in ipairs(CAST) do
      if not spawnedIds[i] then
        local ok, id = pcall(function()
          return mod.world:spawnNpc(entry.map, entry.def)
        end)
        if ok and id then spawnedIds[i] = id end
      end
    end
  end
  mod.events:on("game.ready", spawnCast)
  mod.events:on("map.entered", function() spawnCast() end)

  -- ------- exports

  mod.exports.stickerCount = function() return Rally.count(state.stickers) end
  mod.exports.hasSticker = function(id) return state.stickers[id] ~= nil end
  mod.exports.album = function() return Rally.album(state.stickers) end
  mod.exports.debug = {
    warp = function(mapId, x, y, facing)
      return mod.world:warpTo(mapId or Maps.ONE_F, x or 3, y or 6,
        facing or "up")
    end,
    maps = { oneF = Maps.ONE_F, twoF = Maps.TWO_F, tunnel = Maps.TUNNEL },
  }
end
