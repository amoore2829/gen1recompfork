-- The helper: practically lives at the Center shadowing the nurses,
-- and will tell you about status conditions whether you asked or not.
return {
  id = "happiny",
  name = "NOZOMI",
  trainerClass = "SHOWA_HAPPINY_KID",
  sprite = "SPRITE_LASS",
  seed = 19930623,
  pace = 0.9,
  home = "POKE_CENTER",
  haunts = { POKE_CENTER = true, GOLDENROD_ST = true, VIOLET = true },
  starter = { { species = "CHANSEY", level = 8 } },
  catches = { "MARILL", "MILTANK", "TEDDIURSA" },
  catchChance = 12,
  lines = {
    greet = "Is your party alright? Are\nyou SURE? I can check.",
    challenge = "A battle? Only if you let\nme heal you afterwards.",
    win = "Oh no, are you hurt? Sit,\nsit, I'll take care of it.",
    loss = "See? You DID need those\nPotions. I'm not smug.",
  },
}
