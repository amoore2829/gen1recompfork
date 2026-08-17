-- Venue/event opening hours.  Pure: `isOpen` answers from the spec and the
-- clock tokens it is handed, so the whole calendar is testable without a
-- boot.  A spec omitting a dimension is open across it (no `days` = every
-- day), which lets M1 venues ship always-open and grow hours later.
local Scheduler = {}

local function toSet(list)
  if list == nil then return nil end
  local set = {}
  for _, token in ipairs(list) do set[tostring(token):upper()] = true end
  return set
end

-- spec: { days = {"TUESDAY", ...} | nil, tods = {"MORN","DAY"} | nil }
function Scheduler.normalize(spec)
  return { days = toSet(spec.days), tods = toSet(spec.tods) }
end

function Scheduler.isOpen(normalized, day, tod)
  if normalized.days then
    if day == nil then return false end
    if not normalized.days[tostring(day):upper()] then return false end
  end
  if normalized.tods then
    if tod == nil then return false end
    if not normalized.tods[tostring(tod):upper()] then return false end
  end
  return true
end

return Scheduler
