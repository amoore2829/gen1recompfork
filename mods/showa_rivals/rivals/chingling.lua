-- The shrine apprentice: disciplined, speaks in proverbs, and treats
-- a battle as an exercise rather than a contest.
return {
  id = "chingling",
  name = "SUZU",
  trainerClass = "SHOWA_CHINGLING_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19730303,
  pace = 1.0,
  home = "SPROUT_TOWER",
  haunts = { SPROUT_TOWER = true, ECRUTEAK = true, VIOLET = true },
  starter = { { species = "NATU", level = 6 } },
  catches = { "XATU", "MISDREAVUS", "HOOTHOOT" },
  catchChance = 12,
  lines = {
    greet = "The bell is rung slowly, or\nit is only noise.",
    challenge = "Come. A still mind strikes\nfirst.",
    win = "You hurried. Hurrying is\nhow one arrives late.",
    loss = "Ah. You have been\npractising. Good.",
  },
}
