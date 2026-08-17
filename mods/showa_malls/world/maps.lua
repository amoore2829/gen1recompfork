-- The three registered maps.
--
-- Every block id here is lifted verbatim from OLIVINE_MART's own block
-- list, so the layout is one the TILESET_MART tileset is known to render:
-- inventing block ids is the fastest way to a room that loads and draws
-- garbage.  The resulting 12x8 cell grid (`.` walkable) is
--
--        012345678901
--    0   ############
--    1   ############
--    2   ..#.........
--    3   ..#.........
--    4   ###.######.#
--    5   ##..######.#
--    6   ...........#
--    7   ..##.......#
--
-- A warp only fires where the TILE SAYS SO: World:checkWarpOnArrive tests
-- the arrival cell's collision through Permissions.isWarpCollision, so a
-- warp on plain floor is inert no matter how correct its record looks.
-- Two block ids carry what this mod needs, both out of TILESET_MART's own
-- table:
--
--   block 42 = { 0, 0, 112, 112 }  COLL_WARP_CARPET_DOWN on its lower two
--              cells -- the shop exit mat, taken by pressing DOWN on it.
--              The template already uses it at (2,7)/(3,7).
--   block  1 = { 122, 7, 0, 0 }    COLL_STAIRCASE on its TOP-LEFT cell,
--              an immediate warp, with floor beneath to approach from.
--
-- So the staircases are made by substituting block 1 into the second
-- block row, which puts a stair cell at (0,2) and (10,2) with (0,3) and
-- (10,3) as their landings.  It changes the art to stairs as well, which
-- is the point: the room reads the way it behaves.
local M = {}

local FLOOR, STAIR = 43, 1

local function layout(leftStair, rightStair)
  return {
    20, 39, 20, 19, 19, 19,
    leftStair and STAIR or FLOOR, 34, FLOOR, FLOOR, FLOOR,
      rightStair and STAIR or FLOOR,
    21, 41, 19, 19, 19, 40,
    43, 42, 43, 43, 43, 35,
  }
end

M.ONE_F = "SHOWA_MALL_1F"
M.TWO_F = "SHOWA_MALL_2F"
M.TUNNEL = "SHOWA_MALL_TUNNEL"

-- Warp indices are load bearing: a `destWarp` names the position of that
-- warp in the DESTINATION map's list, so these must stay in step.
--   1F: [1][2] street doors, [3] up to 2F, [4] down to the passage
--   2F: [1] down to 1F
--   passage: [1] up to 1F, [2] out to Goldenrod Underground
function M.records()
  local function base(id, label, leftStair, rightStair)
    return {
      id = id, label = label, tileset = "TILESET_MART",
      width = 6, height = 4, blocks = layout(leftStair, rightStair),
      borderBlock = 0, palette = "PALETTE_DAY",
    }
  end

  -- the ground floor has both staircases: down to the passage on the
  -- left, up to the fashion floor on the right
  local oneF = base(M.ONE_F, "SHOWA MALL 1F", true, true)
  oneF.warps = {
    { x = 2, y = 7, destMap = "OLIVINE_CITY", destWarp = 8 },
    { x = 3, y = 7, destMap = "OLIVINE_CITY", destWarp = 8 },
    { x = 10, y = 2, destMap = M.TWO_F, destWarp = 1 },
    { x = 0, y = 2, destMap = M.TUNNEL, destWarp = 1 },
  }

  local twoF = base(M.TWO_F, "SHOWA MALL 2F", false, true)
  twoF.warps = {
    { x = 10, y = 2, destMap = M.ONE_F, destWarp = 3 },
  }

  local tunnel = base(M.TUNNEL, "CHIKAGAI PASSAGE", true, false)
  tunnel.warps = {
    { x = 0, y = 2, destMap = M.ONE_F, destWarp = 4 },
    { x = 2, y = 7, destMap = "GOLDENROD_UNDERGROUND", destWarp = 3 },
  }

  return { oneF, twoF, tunnel }
end

return M
