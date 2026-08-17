-- The DITTO DITTO REVOLUTION cabinet: the rules on showa_core's minigame
-- scaffold, drawn procedurally so no art ships.
local Rules = require("mods.showa_arcade.games.ddr.rules")

-- four lanes across the 160px canvas, arrows falling to a line near the
-- bottom the way the cabinet's own screen reads
local LANE_W = 28
local LANE_X = { 20, 50, 80, 110 }
local TOP_Y, LINE_Y = 22, 108

local function fontDraw(text, x, y)
  local ok, Font = pcall(require, "src.render.Font")
  if not ok then return end
  local okS, Strings = pcall(require, "src.core.Strings")
  Font.draw(okS and Strings(text) or text, x, y)
end

-- a chunky arrow, pointing the way its lane does
local function arrow(cx, cy, lane, scale)
  local s = scale or 1
  local dirs = {
    { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 0 },   -- left, down, up, right
  }
  local d = dirs[lane]
  local hx, hy = cx + d[1] * 7 * s, cy + d[2] * 7 * s
  -- shaft
  love.graphics.setLineWidth(3 * s)
  love.graphics.line(cx - d[1] * 5 * s, cy - d[2] * 5 * s, hx, hy)
  -- head
  love.graphics.polygon("fill",
    hx + d[1] * 3 * s, hy + d[2] * 3 * s,
    hx - d[1] * 3 * s - d[2] * 5 * s, hy - d[2] * 3 * s - d[1] * 5 * s,
    hx - d[1] * 3 * s + d[2] * 5 * s, hy - d[2] * 3 * s + d[1] * 5 * s)
  love.graphics.setLineWidth(1)
end

return function(core)
  return core.minigame.screen({
    title = "DITTO DITTO REVOLUTION",
    tick = 1,                     -- a rhythm game reads the pad every frame
    init = function(state, _, opts)
      state.game = Rules.new(opts and opts.seed or os.time())
    end,
    step = function(state, input, api)
      for lane, button in ipairs(Rules.LANES) do
        if input:wasPressed(button) then Rules.press(state.game, lane) end
      end
      Rules.step(state.game)
      if state.game.done then api.gameOver() end
    end,
    score = function(state)
      return state.game and state.game.score or 0
    end,
    draw = function(state)
      local g = state.game
      if not g then return end

      love.graphics.setColor(0.06, 0.05, 0.12, 1)
      love.graphics.rectangle("fill", 0, 0, 160, 144)

      -- the lanes, and the line the arrows have to reach
      for lane = 1, 4 do
        local x = LANE_X[lane]
        love.graphics.setColor(0.13, 0.11, 0.22, 1)
        love.graphics.rectangle("fill", x - LANE_W / 2, TOP_Y,
          LANE_W, LINE_Y - TOP_Y + 14)
        -- the target: brighter while an arrow is claimable there
        local claim = Rules.claimable(g, lane)
        if claim then
          love.graphics.setColor(0.95, 0.85, 0.35, 1)
        else
          love.graphics.setColor(0.35, 0.32, 0.48, 1)
        end
        arrow(x, LINE_Y, lane, 1)
      end

      -- the falling arrows: Ditto pink, because it is copying your steps
      love.graphics.setColor(0.90, 0.55, 0.80, 1)
      for _, note in ipairs(Rules.visible(g)) do
        local x = LANE_X[note.lane]
        local y = LINE_Y - (LINE_Y - TOP_Y) * note.progress
        arrow(x, y, note.lane, 0.9)
      end

      -- the call, flashed for a beat after it lands
      love.graphics.setColor(1, 1, 1, 1)
      if g.judgement and g.t - g.judgeAt < 12 then
        local tint = { PERFECT = { 1, 0.9, 0.3 }, GOOD = { 0.5, 0.9, 1 },
                       MISS = { 1, 0.4, 0.4 } }
        local c = tint[g.judgement]
        love.graphics.setColor(c[1], c[2], c[3], 1)
        fontDraw(g.judgement, 58, 62)
        love.graphics.setColor(1, 1, 1, 1)
      end

      if g.combo >= 4 then
        fontDraw(("%d COMBO"):format(g.combo), 52, 128)
      end
    end,
  })
end
