-- The street performer: works a manzai routine on the busy corners,
-- and battles the way he heckles -- all misdirection.
return {
  id = "mimejr",
  name = "MANJI",
  trainerClass = "SHOWA_MIMEJR_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19800808,
  pace = 1.0,
  home = "GOLDENROD_ST",
  haunts = { GOLDENROD_ST = true, DEPT_STORE = true, CHIKAGAI = true, SHOWA_MALL = true },
  starter = { { species = "MR__MIME", level = 8 } },
  catches = { "CLEFAIRY", "JIGGLYPUFF", "AIPOM" },
  catchChance = 10,
  lines = {
    greet = "You're the straight man.\nCongratulations, no refunds.",
    challenge = "Now -- watch this hand.\nNo, the OTHER hand.",
    win = "Thank you, you've been\nlovely! Tip the partner!",
    loss = "Tough crowd! Tough crowd.\nSame time tomorrow?",
  },
}
