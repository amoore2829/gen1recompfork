-- The eldest triplet: all legs, all reach, and no patience for a long
-- match.
return {
  id = "tyrogue_lee",
  name = "RIKI",
  trainerClass = "SHOWA_TYROGUE_LEE",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19810107,
  pace = 1.1,
  home = "MAHOGANY",
  haunts = { MAHOGANY = true, ECRUTEAK = true, MAHOGANY = true },
  starter = { { species = "TYROGUE", level = 6 } },
  catches = { "TYROGUE", "MACHOP", "HITMONLEE" },
  catchChance = 12,
  lines = {
    greet = "I kick FIRST. Ask my\nbrothers how that goes.",
    challenge = "Three of us. You get me\nfirst. Lucky you.",
    win = "Reach beats everything!",
    loss = "Tch. Go on, my brothers\nare waiting.",
  },
}
