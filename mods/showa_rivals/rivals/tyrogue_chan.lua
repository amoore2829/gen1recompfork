-- The middle triplet: the technical one, and the only one of the three
-- who trains to a schedule.
return {
  id = "tyrogue_chan",
  name = "RYU",
  trainerClass = "SHOWA_TYROGUE_CHAN",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19810214,
  pace = 1.1,
  home = "ECRUTEAK",
  haunts = { ECRUTEAK = true, ECRUTEAK = true, MAHOGANY = true },
  starter = { { species = "TYROGUE", level = 6 } },
  catches = { "TYROGUE", "MACHOP", "HITMONCHAN" },
  catchChance = 12,
  lines = {
    greet = "Second brother. The one who\nactually does the drills.",
    challenge = "Guard up. Let's keep this\nclean.",
    win = "Technique. Every time.",
    loss = "Good combination. I'll\ndrill against it.",
  },
}
