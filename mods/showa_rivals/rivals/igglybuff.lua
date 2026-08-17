-- The aspiring idol: rehearsing in the park for a debut that is
-- absolutely happening, any day now.
return {
  id = "igglybuff",
  name = "MOMO",
  trainerClass = "SHOWA_IGGLYBUFF_KID",
  sprite = "SPRITE_LASS",
  seed = 19850214,
  pace = 1.0,
  home = "NATIONAL_PARK",
  haunts = { NATIONAL_PARK = true, GOLDENROD_ST = true, ECRUTEAK = true },
  starter = { { species = "IGGLYBUFF", level = 5 } },
  catches = { "JIGGLYPUFF", "CHANSEY", "SMOOCHUM" },
  catchChance = 14,
  lines = {
    greet = "One two, one two...\nHow did that sound? Honest!",
    challenge = "Battle me! It's basically\na duet with attacks.",
    win = "Thank you! Thank you!\nI'll sign something later!",
    loss = "Okay, okay -- but my ENCORE\nis going to be incredible.",
  },
}
