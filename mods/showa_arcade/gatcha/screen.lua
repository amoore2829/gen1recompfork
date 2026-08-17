-- The gatcha machine's capsule reveal.  Pure presentation: the verb that
-- pushes this screen already spent the tokens and rolled the prize, so all
-- this does is turn the crank, drop the capsule, and show the card.
local Screen = {}
Screen.__index = Screen
Screen.isOpaque = true

local function fontDraw(text, x, y)
  local ok, Font = pcall(require, "src.render.Font")
  if not ok then return end
  local okS, Strings = pcall(require, "src.core.Strings")
  Font.draw(okS and Strings(text) or text, x, y)
end

local TIER_COLORS = {
  COMMON = { 0.75, 0.75, 0.78 },
  UNCOMMON = { 0.45, 0.65, 0.85 },
  RARE = { 0.90, 0.75, 0.25 },
}

function Screen:update()
  local input = self.game.input
  self.t = self.t + 1
  if self.phase == "crank" then
    if self.t > 40 then self.phase = "drop" end
  elseif self.phase == "drop" then
    self.capsuleY = self.capsuleY + 3
    if self.capsuleY >= 96 then self.phase = "reveal"; self.t = 0 end
  elseif self.phase == "reveal" then
    if self.t > 15 and (input:wasPressed("a") or input:wasPressed("b")) then
      self.game.stack:pop()
      if self.onDone then self.onDone(self.prize) end
    end
  end
end

function Screen:draw()
  love.graphics.clear(0.10, 0.08, 0.14, 1)
  -- the machine: a globe of capsules on a red base
  love.graphics.setColor(0.85, 0.85, 0.92, 1)
  love.graphics.circle("fill", 80, 48, 30)
  love.graphics.setColor(0.7, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", 56, 72, 48, 40)
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  love.graphics.circle("fill", 80, 84, 7) -- the crank
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.push()
  love.graphics.translate(80, 84)
  love.graphics.rotate(self.phase == "crank" and self.t * 0.3 or 0)
  love.graphics.rectangle("fill", -1, -6, 2, 12)
  love.graphics.pop()

  if self.phase == "drop" or self.phase == "reveal" then
    local color = TIER_COLORS[self.prize.tier] or TIER_COLORS.COMMON
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.circle("fill", 80,
      self.phase == "reveal" and 96 or self.capsuleY, 8)
  end

  love.graphics.setColor(1, 1, 1, 1)
  if self.phase == "crank" then
    fontDraw("TURNING THE CRANK...", 16, 124)
  elseif self.phase == "reveal" then
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 16, 108, 128, 30)
    love.graphics.setColor(1, 1, 1, 1)
    fontDraw(("%s! (%s)"):format(self.prize.label, self.prize.tier), 20, 112)
    fontDraw("A: TAKE IT", 20, 126)
  end
end

return {
  new = function(game, opts)
    opts = opts or {}
    return setmetatable({
      game = game, t = 0, phase = "crank", capsuleY = 48,
      prize = opts.prize or { id = "STICKER_EKANS",
        label = "EKANS STICKER", tier = "COMMON" },
      onDone = opts.onDone,
    }, Screen)
  end,
}
