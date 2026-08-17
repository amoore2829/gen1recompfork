-- A mirror of Gold's clock as the mod API reports it.  Pure fold: main.lua
-- feeds it event payloads and the world.tod hook's answers; nothing here
-- reads the engine, so a test drives it with literals.
--
-- Payload shapes are defensive on purpose: the engine's `clock.day_changed`
-- carries { day, previous, reason } and `world.tod_changed` carries the new
-- time-of-day, but the suite only ever needs "which day token" and "which
-- tod token", so unknown shapes degrade to nil rather than erroring.
local Clock = {}

Clock.DAYS = { "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY",
               "FRIDAY", "SATURDAY" }

function Clock.new()
  return { day = nil, tod = nil }
end

local function dayToken(day)
  if type(day) == "number" then
    -- the cart counts days 0-6 starting Sunday
    return Clock.DAYS[(day % 7) + 1]
  end
  if type(day) == "string" then return day:upper() end
  return nil
end

function Clock.onDayChanged(clock, payload)
  if type(payload) ~= "table" then return end
  clock.day = dayToken(payload.day) or clock.day
end

function Clock.onTodChanged(clock, payload)
  if type(payload) == "table" then
    clock.tod = payload.tod or payload.to or clock.tod
  elseif payload ~= nil then
    clock.tod = payload
  end
end

-- the world.tod hook's pass-through answer, recorded as the live value
function Clock.observeTod(clock, tod)
  if tod ~= nil then clock.tod = tod end
  return tod
end

function Clock.today(clock) return clock.day end
function Clock.tod(clock) return clock.tod end

return Clock
