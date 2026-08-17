-- Showa Arcade: the Goldenrod Game Corner as a Showa-era arcade.  v1 ships
-- the EKANS snake cabinet, the gatcha machine, a token clerk, and the
-- high-score ledger.  Interactions follow the Gen 2 pattern the probe mod
-- proved: spawned NPCs whose scriptKey row lists dispatch this mod's own
-- verbs through Gold's VM.
local EkansGame = require("mods.showa_arcade.games.ekans.game")
local Pool = require("mods.showa_arcade.gatcha.pool")
local GatchaScreen = require("mods.showa_arcade.gatcha.screen")

local ARCADE_MAP = "GOLDENROD_GAME_CORNER"
local TOKEN = "ARCADE_TOKEN"
local PLAY_COST, GATCHA_COST = 1, 3
local TOKEN_PACK, TOKEN_PRICE = 10, 500

return function(mod)
  local core = assert(mod.find("showa_core"),
    "showa_arcade needs showa_core").exports

  -- ------- persistent state

  local state = mod.save:get("state")
  if type(state) ~= "table" or state.v ~= 1 then
    state = { v = 1, scores = {}, gatcha = { pulls = 0, owned = {} },
              rng = 20260817 }
  end
  local function persist() mod.save:set("state", state) end
  persist()

  core.wallet.define(TOKEN, "GAME TOKEN")
  core.venues.register("GOLDENROD_ARCADE", {
    map = ARCADE_MAP, label = "GOLDENROD ARCADE",
    tags = { "arcade" }, x = 5, y = 11,
  })

  -- ------- the score ledger (rivals post through the same export)

  local function highScore(gameId)
    local row = state.scores[gameId]
    return row and row.best or 0, row and row.by or nil
  end

  local function submitScore(gameId, score, who)
    local row = state.scores[gameId] or { best = 0 }
    state.scores[gameId] = row
    local broke = score > row.best
    if broke then
      row.best, row.by = score, who or "YOU"
      core.news.post(("%s set the %s record: %d points!")
        :format(row.by, gameId:upper(), score))
    end
    persist()
    return broke
  end

  -- ------- screens

  mod.content.screens:register("ShowaEkans", EkansGame(core))
  mod.content.screens:register("ShowaGatcha", GatchaScreen)

  -- ------- the cabinet verbs

  -- Not ctx.vm:showText(text): that takes a KEY and prints "..." for a
  -- sentence.  core.dialogue parks the line in the text table first.
  local function say(ctx, text)
    return core.dialogue.say(ctx, text)
  end

  -- verb entry/exit counts, read by the driver
  local stats = { clerk = 0, ekans = 0, gatcha = 0, pushes = 0,
                  lastError = nil }

  mod.content.commands:register("showa_arcade:clerk", function(ctx)
    stats.clerk = stats.clerk + 1
    local save = mod.game and mod.game.save
    local player = save and save.player
    local balance = core.wallet.get(TOKEN)
    if not player then
      say(ctx, "The counter is closed right now.")
      return "end"
    end
    if (player.money or 0) < TOKEN_PRICE then
      say(ctx, ("Welcome to GOLDENROD ARCADE!\n%d GAME TOKENS are $%d...\n"
        .. "come back with more money!\n(You hold %d tokens.)")
        :format(TOKEN_PACK, TOKEN_PRICE, balance))
      return "end"
    end
    player.money = player.money - TOKEN_PRICE
    balance = core.wallet.add(TOKEN, TOKEN_PACK)
    say(ctx, ("Here are %d GAME TOKENS!\nYou now hold %d tokens.")
      :format(TOKEN_PACK, balance))
    return "end"
  end)

  mod.content.commands:register("showa_arcade:ekans", function(ctx)
    stats.ekans = stats.ekans + 1
    if not core.wallet.spend(TOKEN, PLAY_COST) then
      say(ctx, ("EKANS wants %d GAME TOKEN.\nThe clerk by the counter "
        .. "sells them."):format(PLAY_COST))
      return "end"
    end
    local ok, err = pcall(function()
      mod.ui.push(mod.game, "ShowaEkans", {
        onDone = function(score)
          if not submitScore("ekans", score) and score > 0 then
            core.news.post(("Somebody scored %d on EKANS."):format(score))
          end
        end,
      })
    end)
    if ok then stats.pushes = stats.pushes + 1
    else stats.lastError = tostring(err) end
    return "end"
  end)

  mod.content.commands:register("showa_arcade:gatcha", function(ctx)
    stats.gatcha = stats.gatcha + 1
    if not core.wallet.spend(TOKEN, GATCHA_COST) then
      say(ctx, ("The gatcha machine takes %d GAME TOKENS per turn.")
        :format(GATCHA_COST))
      return "end"
    end
    local prize
    prize, state.rng = Pool.roll(Pool.DEFAULT, state.rng, state.gatcha.owned)
    state.gatcha.pulls = state.gatcha.pulls + 1
    persist()
    mod.ui.push(mod.game, "ShowaGatcha", {
      prize = prize,
      onDone = function(won)
        state.gatcha.owned[won.id] = (state.gatcha.owned[won.id] or 0) + 1
        persist()
        if won.tier == "RARE" then
          core.news.post(("A %s came out of the arcade gatcha!")
            :format(won.label))
        end
      end,
    })
    return "end"
  end)

  -- ------- the cast, respawned once per boot

  -- the clerk behind the counter, the cabinet, and the machine sit on the
  -- open floor south of the vanilla seat rows (x=6..7, y=6..11); the
  -- entrance warps are at (2..3, 13)
  local CAST = {
    clerk = { sprite = "SPRITE_CLERK", x = 1, y = 11,
      movement = 9, radius = { x = 0, y = 0 }, hours = { -1, -1 },
      scriptKey = { { "showa_arcade:clerk" } } },
    -- free floor: the machine banks are bgEvent columns at x=6-7, 12-13,
    -- 18 (y=6..11) and vanilla NPCs sit at (5,10), (8,7), (11,10), (14,8),
    -- (17,6) -- row 4 is open
    ekans = { sprite = "SPRITE_GENTLEMAN", x = 9, y = 4,
      movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
      scriptKey = { { "showa_arcade:ekans" } } },
    gatcha = { sprite = "SPRITE_LASS", x = 15, y = 4,
      movement = 6, radius = { x = 0, y = 0 }, hours = { -1, -1 },
      scriptKey = { { "showa_arcade:gatcha" } } },
  }

  -- spawnNpc answers nil (not an error) until the overworld is live, so
  -- each cast member retries on the next event until its id comes back
  local spawnedIds = {}
  local function spawnCast()
    for key, def in pairs(CAST) do
      if not spawnedIds[key] then
        local ok, id = pcall(function()
          return mod.world:spawnNpc(ARCADE_MAP, def)
        end)
        if ok and id then spawnedIds[key] = id end
      end
    end
  end

  mod.events:on("game.ready", spawnCast)
  mod.events:on("map.entered", function() spawnCast() end)

  -- ------- exports (the rival seam)

  mod.exports.highScore = highScore
  mod.exports.submitScore = submitScore
  mod.exports.gatchaOwned = function()
    local out = {}
    for id, count in pairs(state.gatcha.owned) do out[id] = count end
    return out
  end
  -- dev convenience for drivers: jump to a cell on the arcade floor
  mod.exports.debugWarp = function(x, y, facing)
    return mod.world:warpTo(ARCADE_MAP, x or 5, y or 11, facing or "up")
  end
  mod.exports.debugStats = function()
    return { clerk = stats.clerk, ekans = stats.ekans,
             gatcha = stats.gatcha, pushes = stats.pushes,
             lastError = stats.lastError }
  end
end
