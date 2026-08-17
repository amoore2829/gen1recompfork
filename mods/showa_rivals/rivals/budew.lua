-- The community gardener: keeps the shrine flowerbeds and the park
-- planters, and battles litterbugs on principle.
return {
  id = "budew",
  name = "MIDORI",
  trainerClass = "SHOWA_BUDEW_KID",
  sprite = "SPRITE_LASS",
  seed = 19890505,
  pace = 0.95,
  home = "CHERRYGROVE",
  haunts = { CHERRYGROVE = true, NATIONAL_PARK = true, ECRUTEAK = true },
  starter = { { species = "BELLSPROUT", level = 5 } },
  catches = { "HOPPIP", "SUNKERN", "ODDISH", "BAYLEEF" },
  catchChance = 18,
  lines = {
    greet = "The azaleas came back this\nyear. I'm so pleased.",
    challenge = "If you tread on the beds\nwe're going to have words.",
    win = "Good. Now help me weed.",
    loss = "You battle beautifully.\nCome back in spring!",
  },
}
