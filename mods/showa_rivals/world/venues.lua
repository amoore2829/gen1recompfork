-- The places rivals hang around that no feature mod owns.
--
-- Every cell here was picked by scanning the map's own data for a tile
-- that is walkable, is not an object, bg event or warp, AND has a free
-- walkable cell directly south of it -- so a rival standing here can
-- always be talked to from below.  That is the Gen 2 form of the house
-- rule about verifying against the data before trusting it; the Game
-- Corner taught us that "walkable" alone is not enough.
local Venues = {}

Venues.LIST = {
  { id = "SPROUT_TOWER", map = "SPROUT_TOWER_1F", label = "SPROUT TOWER",
    x = 11, y = 6, tags = { "shrine", "traditional" } },
  { id = "ECRUTEAK", map = "ECRUTEAK_CITY", label = "ECRUTEAK CITY",
    x = 18, y = 25, tags = { "town", "traditional" } },
  { id = "CHERRYGROVE", map = "CHERRYGROVE_CITY", label = "CHERRYGROVE",
    x = 21, y = 10, tags = { "town", "coast", "gardens" } },
  { id = "NATIONAL_PARK", map = "NATIONAL_PARK", label = "NATIONAL PARK",
    x = 19, y = 40, tags = { "park", "contest" } },
  { id = "DEPT_STORE", map = "GOLDENROD_DEPT_STORE_1F",
    label = "DEPT STORE", x = 8, y = 5, tags = { "shopping", "fashion" } },
  { id = "VIOLET", map = "VIOLET_CITY", label = "VIOLET CITY",
    x = 22, y = 20, tags = { "town" } },
  { id = "OLIVINE", map = "OLIVINE_CITY", label = "OLIVINE CITY",
    x = 19, y = 24, tags = { "town", "coast" } },
  { id = "AZALEA", map = "AZALEA_TOWN", label = "AZALEA TOWN",
    x = 21, y = 7, tags = { "town", "festival" } },
  { id = "GOLDENROD_ST", map = "GOLDENROD_CITY", label = "GOLDENROD ST",
    x = 19, y = 25, tags = { "town", "street" } },
  { id = "NEW_BARK", map = "NEW_BARK_TOWN", label = "NEW BARK TOWN",
    x = 9, y = 10, tags = { "town", "story" } },
  { id = "MAHOGANY", map = "MAHOGANY_TOWN", label = "MAHOGANY TOWN",
    x = 10, y = 13, tags = { "town" } },
  { id = "BLACKTHORN", map = "BLACKTHORN_CITY", label = "BLACKTHORN",
    x = 21, y = 17, tags = { "town" } },
  { id = "POKE_CENTER", map = "GOLDENROD_POKECENTER_1F",
    label = "POKE CENTER", x = 5, y = 3, tags = { "center", "helping" } },
  { id = "ROUTE_34", map = "ROUTE_34", label = "ROUTE 34",
    x = 10, y = 18, tags = { "route", "daycare" } },
}

-- Edges: abstract travel time, roughly following how far apart these
-- places really are, so a rival crossing Johto takes longer than one
-- wandering across Goldenrod.
Venues.EDGES = {
  { "NEW_BARK", "CHERRYGROVE", 2 },
  { "CHERRYGROVE", "VIOLET", 3 },
  { "VIOLET", "SPROUT_TOWER", 1 },
  { "VIOLET", "AZALEA", 4 },
  { "AZALEA", "GOLDENROD_ST", 3 },
  { "GOLDENROD_ST", "DEPT_STORE", 1 },
  { "GOLDENROD_ST", "POKE_CENTER", 1 },
  { "GOLDENROD_ST", "ROUTE_34", 1 },
  { "GOLDENROD_ST", "NATIONAL_PARK", 2 },
  { "NATIONAL_PARK", "ECRUTEAK", 2 },
  { "ECRUTEAK", "OLIVINE", 3 },
  { "ECRUTEAK", "MAHOGANY", 3 },
  { "MAHOGANY", "BLACKTHORN", 3 },
  { "ROUTE_34", "CHERRYGROVE", 3 },
  -- and into the feature mods' venues, when those mods are installed
  { "GOLDENROD_ST", "GOLDENROD_ARCADE", 1 },
  { "GOLDENROD_ST", "CHIKAGAI", 1 },
  { "OLIVINE", "SHOWA_MALL", 1 },
  { "MAHOGANY", "LAKE_DERBY", 2 },
  { "NEW_BARK", "ELM_LAB", 1 },
  { "VIOLET", "ALPH_RUINS", 2 },
}

return Venues
