-- The mall foodie: never seen without a pretzel, and does not stop
-- battling until a post-match snack has been earned.
return {
  id = "munchlax",
  name = "GOROU",
  trainerClass = "SHOWA_MUNCHLAX_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19860101,
  pace = 1.0,
  home = "SHOWA_MALL",
  haunts = { SHOWA_MALL = true, CHIKAGAI = true, DEPT_STORE = true, GOLDENROD_ST = true },
  starter = { { species = "SNORLAX", level = 8 } },
  catches = { "TEDDIURSA", "MILTANK", "SWINUB" },
  catchChance = 12,
  lines = {
    greet = "They changed the pretzel\nguy. It's NOT the same.",
    challenge = "Winner buys. Loser also\nbuys. Let's battle.",
    win = "Great match! I'm starving.\nFood court. Now.",
    loss = "Worth it. Still eating.",
  },
}
