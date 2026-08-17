-- Contest scoring, pure and deterministic: the same mon always measures
-- the same, so a derby is replayable and the suite can assert exact sizes.
local Judging = {}

-- Size in centimeters from what the mon IS (level + DVs), never a roll.
-- Seaking carries the derby bonus -- it is the Seaking Derby, after all.
function Judging.fishSize(mon)
  local level = tonumber(mon.level) or 5
  local dvs = mon.dvs or {}
  local atk = tonumber(dvs.attack or dvs.atk) or 0
  local def = tonumber(dvs.defense or dvs.def) or 0
  local spd = tonumber(dvs.speed or dvs.spd) or 0
  local spc = tonumber(dvs.special or dvs.specialAttack or dvs.spc) or 0
  local base = 20 + level * 2
  local spread = (atk * 8 + def * 4 + spd * 2 + spc) % 64
  local size = base + spread
  local species = tostring(mon.species or ""):upper()
  if species == "SEAKING" then size = size + 30 end
  return size
end

return Judging
