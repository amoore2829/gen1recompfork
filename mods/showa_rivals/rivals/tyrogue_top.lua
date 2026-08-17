-- The youngest triplet: spins constantly, wins arguments by outlasting
-- everyone, and is the hardest of the three to hit.
return {
  id = "tyrogue_top",
  name = "GORO",
  trainerClass = "SHOWA_TYROGUE_TOP",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19810321,
  pace = 1.1,
  home = "BLACKTHORN",
  haunts = { BLACKTHORN = true, ECRUTEAK = true, MAHOGANY = true },
  starter = { { species = "TYROGUE", level = 6 } },
  catches = { "TYROGUE", "MACHOP", "HITMONTOP" },
  catchChance = 12,
  lines = {
    greet = "Youngest! Which means\nfastest. That's how it works.",
    challenge = "Can't hit what won't hold\nstill!",
    win = "HA! Dizzy yet?",
    loss = "Whoa! Okay! Okay! Stopping!",
  },
}
