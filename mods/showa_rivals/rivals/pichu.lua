-- The arcade rat: hyper-competitive, fast-talking, treats every battle
-- like a fighting-game set.  Wired to showa_arcade -- he actually posts
-- scores to the EKANS cabinet and taunts you when he holds the record.
return {
  id = "pichu",
  name = "SPARKS",
  trainerClass = "SHOWA_PICHU_KID",
  sprite = "SPRITE_LASS",
  seed = 19831231,
  pace = 1.15,
  home = "GOLDENROD_ARCADE",
  haunts = { GOLDENROD_ARCADE = true, SHOWA_MALL = true },
  starter = { { species = "PIKACHU", level = 6 } },
  catches = { "VOLTORB", "MAGNEMITE", "ELECTABUZZ" },
  catchChance = 14,
  -- how good he is at EKANS; the sim turns this into a posted score
  arcade = { game = "ekans", skill = 40, variance = 60 },
  lines = {
    greet = "You gonna play or just\nstand there? Clock's ticking!",
    challenge = "Best of one. No continues.\nLet's GO!",
    win = "GG! That's a new personal\nbest for me!",
    loss = "Rematch! I had lag!\n...okay, I didn't. Nice one.",
  },
}
