-- The EKANS cabinet: rules glued into showa_core's minigame scaffold.
-- Drawing is procedural (rectangles on the 160x144 canvas) so no assets
-- ship -- the Blackjack Corner pattern for staying ROM-clean.
local Rules = require("mods.showa_arcade.games.ekans.rules")

-- playfield geometry: 8px cells, centered under the score bar
local CELL = 8
local OX, OY = 8, 24

return function(core)
  return core.minigame.screen({
    title = "EKANS",
    tick = 8,
    init = function(state, _, opts)
      state.game = Rules.new(opts and opts.seed or os.time())
    end,
    step = function(state, input, api)
      for _, dir in ipairs({ "up", "down", "left", "right" }) do
        if input:wasPressed(dir) then Rules.turn(state.game, dir) end
      end
      Rules.step(state.game)
      if not state.game.alive or state.game.won then api.gameOver() end
    end,
    score = function(state)
      return state.game and state.game.score or 0
    end,
    draw = function(state)
      local g = state.game
      if not g then return end
      -- cabinet bezel + playfield
      love.graphics.setColor(0.13, 0.13, 0.18, 1)
      love.graphics.rectangle("fill", 0, 0, 160, 144)
      love.graphics.setColor(0.72, 0.78, 0.55, 1) -- LCD green
      love.graphics.rectangle("fill", OX, OY,
        Rules.W * CELL, Rules.H * CELL)
      love.graphics.setColor(0.25, 0.30, 0.16, 1)
      love.graphics.rectangle("line", OX - 1, OY - 1,
        Rules.W * CELL + 2, Rules.H * CELL + 2)

      -- the apple
      if g.food then
        love.graphics.setColor(0.55, 0.15, 0.15, 1)
        love.graphics.rectangle("fill",
          OX + (g.food.x - 1) * CELL + 1, OY + (g.food.y - 1) * CELL + 1,
          CELL - 2, CELL - 2)
      end

      -- Ekans: dark body, darker head
      for i, seg in ipairs(g.snake) do
        if i == 1 then
          love.graphics.setColor(0.20, 0.16, 0.35, 1)
        else
          love.graphics.setColor(0.35, 0.28, 0.55, 1)
        end
        love.graphics.rectangle("fill",
          OX + (seg.x - 1) * CELL, OY + (seg.y - 1) * CELL, CELL, CELL)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end,
  })
end
