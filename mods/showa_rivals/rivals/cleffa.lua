-- The occult nerd: convinced something is visiting Johto, and the
-- Ruins are where the proof is. 90s paranoia and mystery magazines.
return {
  id = "cleffa",
  name = "LUNA",
  trainerClass = "SHOWA_CLEFFA_KID",
  sprite = "SPRITE_LASS",
  seed = 19770917,
  pace = 1.0,
  home = "ALPH_RUINS",
  haunts = { ALPH_RUINS = true, VIOLET = true, SPROUT_TOWER = true },
  starter = { { species = "CLEFFA", level = 5 } },
  catches = { "NATU", "MISDREAVUS", "UNOWN", "HOOTHOOT" },
  catchChance = 16,
  lines = {
    greet = "Did you SEE that light last\nnight? I have photographs.",
    challenge = "A test! Believers battle\nbetter. It's documented.",
    win = "The truth protects me.",
    loss = "Interference. Definitely\ninterference.",
  },
}
