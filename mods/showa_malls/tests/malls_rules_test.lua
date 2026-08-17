-- The pure half of showa_malls: the stamp rally board and the map
-- records' internal consistency (warp indices are load bearing).
--
--   luajit mods/showa_malls/tests/malls_rules_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local Maps = require("mods.showa_malls.world.maps")
local Rally = require("mods.showa_malls.world.rally")

-- ------- the rally board

do
  local collected = {}
  T.eq(Rally.count(collected), 0, "an empty book counts zero")
  T.eq(Rally.complete(collected), false, "and is not complete")
  T.eq(Rally.total(), 4, "four counters make up the rally")

  collected.TOYS = "MONDAY"
  T.eq(Rally.count(collected), 1, "a sticker counts")
  local album = Rally.album(collected)
  T.eq(#album, 4, "the album always shows every store")
  T.eq(album[1].owned, true, "the collected one reads as owned")
  T.eq(album[2].owned, false, "the missing ones do not")

  for _, store in ipairs(Rally.STORES) do collected[store.id] = "TUESDAY" end
  T.eq(Rally.complete(collected), true, "a full board completes")

  T.check(Rally.byId("RAMEN") ~= nil, "stores look up by id")
  T.eq(Rally.byId("NOPE"), nil, "and an unknown id is nil, not a crash")

  local seen = {}
  for _, store in ipairs(Rally.STORES) do
    T.check(not seen[store.id], "store ids are unique: " .. store.id)
    seen[store.id] = true
    T.check(type(store.line) == "string" and #store.line > 0,
      "every counter has a line: " .. store.id)
  end
end

-- ------- the maps

do
  local records = Maps.records()
  T.eq(#records, 3, "three maps: two floors and the passage")

  local byId = {}
  for _, record in ipairs(records) do byId[record.id] = record end

  for id, record in pairs(byId) do
    T.eq(#record.blocks, record.width * record.height,
      "blocks match width*height: " .. id)
    T.eq(record.tileset, "TILESET_MART", "on the template's tileset: " .. id)
    T.check(record.width <= 7 and record.height <= 6,
      "small enough to keep its cast on camera: " .. id)
  end

  -- warp indices must point at a warp that exists in the destination
  local function destOk(from, index, wantMap)
    local warp = byId[from].warps[index]
    T.eq(warp.destMap, wantMap,
      ("%s warp %d goes to %s"):format(from, index, wantMap))
    local dest = byId[wantMap]
    if dest then
      T.check(dest.warps[warp.destWarp] ~= nil,
        ("%s warp %d lands on a real warp in %s (#%d)")
          :format(from, index, wantMap, warp.destWarp))
    end
    return warp
  end

  destOk(Maps.ONE_F, 1, "OLIVINE_CITY")
  destOk(Maps.ONE_F, 2, "OLIVINE_CITY")
  local up = destOk(Maps.ONE_F, 3, Maps.TWO_F)
  local down = destOk(Maps.ONE_F, 4, Maps.TUNNEL)
  local back = destOk(Maps.TWO_F, 1, Maps.ONE_F)
  local upFromTunnel = destOk(Maps.TUNNEL, 1, Maps.ONE_F)
  destOk(Maps.TUNNEL, 2, "GOLDENROD_UNDERGROUND")

  -- and the round trips have to be symmetric, or a staircase is one-way
  T.eq(byId[Maps.TWO_F].warps[up.destWarp].x, 10,
    "1F's up warp arrives beside 2F's down warp")
  T.eq(back.destWarp, 3, "2F comes back to 1F's staircase, not its door")
  T.eq(upFromTunnel.destWarp, 4,
    "the passage comes back to 1F's basement stair")
  T.eq(down.destWarp, 1, "1F's basement stair arrives at the passage stair")

  -- EVERY warp must sit on a cell whose collision actually warps.
  -- World:checkWarpOnArrive tests the arrival tile through
  -- Permissions.isWarpCollision, so a warp record on plain floor is inert
  -- however right it reads.  The two block ids this layout uses:
  --   block 42 = { 0, 0, 112, 112 }  carpet-down on its lower cells
  --   block  1 = { 122, 7, 0, 0 }    staircase on its top-left cell
  local BLOCK_COLL = { [42] = { 0, 0, 112, 112 }, [1] = { 122, 7, 0, 0 } }
  local function warps(coll)
    return coll == 0x60 or coll == 0x68 or math.floor(coll / 16) == 7
  end
  for id, record in pairs(byId) do
    for index, warp in ipairs(record.warps) do
      local bx, dx = math.floor(warp.x / 2), warp.x % 2
      local by, dy = math.floor(warp.y / 2), warp.y % 2
      local block = record.blocks[by * record.width + bx + 1]
      local quad = BLOCK_COLL[block]
      T.check(quad ~= nil,
        ("%s warp %d stands on a block this test knows (%s)")
          :format(id, index, tostring(block)))
      if quad then
        T.check(warps(quad[dy * 2 + dx + 1]),
          ("%s warp %d is on a warping tile, not plain floor")
            :format(id, index))
      end
    end
  end

  -- the cast has to stand on this layout's walkable floor, and the two
  -- rows that are open across the map are y=2 (back) and y=6..7 (south)
  for _, store in ipairs(Rally.STORES) do
    T.check(byId[store.map] ~= nil,
      "every counter is in one of our maps: " .. store.id)
    T.eq(store.y, 2, "counters stand on the open back row: " .. store.id)
    T.check(store.x >= 3 and store.x <= 11,
      "and within its walkable span: " .. store.id)
  end
end

T.finish("showa_malls rules")
