-- EKANS: the snake game as a pure state machine.  step(state) advances one
-- tick; turn(state, dir) queues a direction.  No engine, no clock, no
-- randomness source but the LCG inside the state -- a seed replays a game
-- move for move, which is what the suite's tests lean on.
local Rules = {}

Rules.W, Rules.H = 18, 12

local function lcg(seed)
  return (seed * 1103515245 + 12345) % 2147483648
end

local OPPOSITE = { up = "down", down = "up", left = "right", right = "left" }
local DELTA = { up = { 0, -1 }, down = { 0, 1 },
                left = { -1, 0 }, right = { 1, 0 } }

local function occupied(state, x, y)
  for _, seg in ipairs(state.snake) do
    if seg.x == x and seg.y == y then return true end
  end
  return false
end

function Rules.placeFood(state)
  -- bounded roll: after enough misses walk the grid for the first free cell,
  -- so a nearly-won board cannot spin forever
  for _ = 1, 64 do
    state.rng = lcg(state.rng)
    local x = (state.rng % Rules.W) + 1
    state.rng = lcg(state.rng)
    local y = (state.rng % Rules.H) + 1
    if not occupied(state, x, y) then
      state.food = { x = x, y = y }
      return
    end
  end
  for y = 1, Rules.H do
    for x = 1, Rules.W do
      if not occupied(state, x, y) then
        state.food = { x = x, y = y }
        return
      end
    end
  end
  state.food = nil -- the board is full; step() calls that a win
end

function Rules.new(seed)
  local state = {
    snake = { { x = 5, y = 6 }, { x = 4, y = 6 }, { x = 3, y = 6 } },
    dir = "right", nextDir = "right",
    grow = 0, score = 0, alive = true, won = false,
    rng = seed or 42,
  }
  Rules.placeFood(state)
  return state
end

function Rules.turn(state, dir)
  if not DELTA[dir] then return end
  if OPPOSITE[dir] == state.dir then return end
  state.nextDir = dir
end

function Rules.step(state)
  if not state.alive or state.won then return state end
  state.dir = state.nextDir
  local d = DELTA[state.dir]
  local head = state.snake[1]
  local nx, ny = head.x + d[1], head.y + d[2]

  if nx < 1 or nx > Rules.W or ny < 1 or ny > Rules.H then
    state.alive = false
    return state
  end

  -- the tail cell vacates this tick unless the snake is growing, so moving
  -- into it is legal exactly when grow == 0
  local tail = state.snake[#state.snake]
  for i, seg in ipairs(state.snake) do
    if seg.x == nx and seg.y == ny
        and not (state.grow == 0 and seg == tail and i == #state.snake) then
      state.alive = false
      return state
    end
  end

  table.insert(state.snake, 1, { x = nx, y = ny })
  if state.grow > 0 then
    state.grow = state.grow - 1
  else
    table.remove(state.snake)
  end

  if state.food and nx == state.food.x and ny == state.food.y then
    state.score = state.score + 10
    state.grow = state.grow + 2
    Rules.placeFood(state)
  end
  if state.food == nil then state.won = true end
  return state
end

return Rules
