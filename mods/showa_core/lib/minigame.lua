-- The arcade cabinet scaffold: fixed-step loop, pause, results card, and
-- score handoff, so a game module ships only its rules and its playfield
-- drawing.  Engine-facing on purpose (the one lib file that is): it draws
-- with love.graphics and the engine Font, which is why showa_core carries
-- the engine_internals permission.
--
-- spec:
--   title        cabinet name for the results card
--   tick         frames per logic step (1 = every frame; snake wants ~8)
--   init(state, game, opts)      fill the fresh state table
--   step(state, input, api)      one logic step while playing
--   draw(state, game)            the playfield (160x144 canvas space)
--   score(state) -> number       live score readout
--
-- api handed to step():
--   api.gameOver()               end the run, show the results card
--
-- Minigame.screen(spec) returns a screens-registry record whose new(game,
-- opts) takes { onDone = function(score) } -- the arcade mod settles
-- tokens/high scores there, not the game module.
local Minigame = {}

local Screen = {}
Screen.__index = Screen
Screen.isOpaque = true

local function fontDraw(text, x, y)
  local ok, Font = pcall(require, "src.render.Font")
  if not ok then return end
  local okS, Strings = pcall(require, "src.core.Strings")
  Font.draw(okS and Strings(text) or text, x, y)
end

function Screen:update()
  local input = self.game.input
  self.t = self.t + 1

  if self.phase == "results" then
    if self.t - self.phaseAt > 20
        and (input:wasPressed("a") or input:wasPressed("b")) then
      self.game.stack:pop()
      if self.onDone then self.onDone(self.spec.score(self.state) or 0) end
    end
    return
  end

  if input:wasPressed("start") then
    self.paused = not self.paused
  end
  if self.paused then return end
  if input:wasPressed("b") then
    self:gameOver()
    return
  end

  self.sinceStep = self.sinceStep + 1
  if self.sinceStep >= (self.spec.tick or 1) then
    self.sinceStep = 0
    self.spec.step(self.state, input, self.api)
  end
end

function Screen:gameOver()
  if self.phase ~= "results" then
    self.phase = "results"
    self.phaseAt = self.t
  end
end

function Screen:draw()
  love.graphics.clear(0, 0, 0, 1)
  self.spec.draw(self.state, self.game)
  fontDraw(("SCORE %d"):format(self.spec.score(self.state) or 0), 4, 2)

  if self.paused then
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    love.graphics.setColor(1, 1, 1, 1)
    fontDraw("PAUSE", 64, 68)
  elseif self.phase == "results" then
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 24, 48, 112, 48)
    love.graphics.setColor(1, 1, 1, 1)
    fontDraw(self.spec.title or "GAME OVER", 32, 56)
    fontDraw(("SCORE %d"):format(self.spec.score(self.state) or 0), 32, 68)
    fontDraw("A: DONE", 32, 80)
  end
end

function Minigame.screen(spec)
  assert(type(spec.step) == "function" and type(spec.draw) == "function"
    and type(spec.score) == "function", "spec needs step, draw, score")
  return {
    new = function(game, opts)
      opts = opts or {}
      local self = setmetatable({
        game = game, spec = spec, state = {},
        t = 0, sinceStep = 0, phase = "play", phaseAt = 0,
        paused = false, onDone = opts.onDone,
      }, Screen)
      self.api = { gameOver = function() self:gameOver() end }
      if spec.init then spec.init(self.state, game, opts) end
      return self
    end,
  }
end

return Minigame
