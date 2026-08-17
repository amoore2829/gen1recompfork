-- How a rival's team grows between sightings.  Rubber-banded to the
-- player so a rival met late is a real fight and one met early is not a
-- wall, and capped so a rival left alone for a hundred ticks does not
-- come back with a level 90 team.
local Growth = {}

Growth.MIN_LEVEL = 5
Growth.MAX_LEVEL = 70

-- The band a rival should be sitting in given the player's own progress.
-- `pace` is the rival's own eagerness: 1.0 keeps level with the player,
-- above races ahead, below trails.
function Growth.targetLevel(playerLevel, badges, pace)
  local base = math.max(Growth.MIN_LEVEL, (playerLevel or 5))
  local target = base + (badges or 0) * 0.5
  target = target * (pace or 1.0)
  if target < Growth.MIN_LEVEL then target = Growth.MIN_LEVEL end
  if target > Growth.MAX_LEVEL then target = Growth.MAX_LEVEL end
  return math.floor(target + 0.5)
end

-- One tick of training: a rival closes at most one level on its target,
-- and never loses ground it has earned.
function Growth.step(level, target)
  if level < target then return level + 1 end
  return level
end

-- Apply a tick across a party in place; returns how many levelled.
function Growth.trainParty(party, target)
  local moved = 0
  for _, mon in ipairs(party) do
    local after = Growth.step(mon.level, target)
    if after ~= mon.level then
      mon.level = after
      moved = moved + 1
    end
  end
  return moved
end

return Growth
