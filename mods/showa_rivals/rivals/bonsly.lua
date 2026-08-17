-- The neighbourhood prankster: leaves his partner standing around as
-- a potted plant and waits for somebody to walk too close.
return {
  id = "bonsly",
  name = "KEN",
  trainerClass = "SHOWA_BONSLY_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19871111,
  pace = 1.0,
  home = "GOLDENROD_ST",
  haunts = { GOLDENROD_ST = true, AZALEA = true, ROUTE_34 = true },
  starter = { { species = "SUDOWOODO", level = 7 } },
  catches = { "HOPPIP", "SUNKERN", "AIPOM" },
  catchChance = 12,
  lines = {
    greet = "AHA! You walked right past\nhim twice! TWICE!",
    challenge = "Bet you can't tell which\none's the real tree.",
    win = "Told you! Nobody ever\nchecks the plants!",
    loss = "Okay that was a good one.\nI'm stealing that.",
  },
}
