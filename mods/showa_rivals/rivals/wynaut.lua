-- The shy kid, hiding behind a handheld and a very thick manga.
-- Speaks up only when a battle makes it unavoidable.
return {
  id = "wynaut",
  name = "SHIZUKU",
  trainerClass = "SHOWA_WYNAUT_KID",
  sprite = "SPRITE_LASS",
  seed = 19940412,
  pace = 0.9,
  home = "VIOLET",
  haunts = { VIOLET = true, POKE_CENTER = true, SPROUT_TOWER = true },
  starter = { { species = "WOBBUFFET", level = 6 } },
  catches = { "NATU", "HOOTHOOT", "SUNKERN" },
  catchChance = 8,
  lines = {
    greet = "...(they do not look up from\nthe game)...oh. Hi.",
    challenge = "...if you want to. I don't\nmind either way. Really.",
    win = "...oh. I won. ...sorry.",
    loss = "...that's okay. That's\nokay. I'm okay.",
  },
}
