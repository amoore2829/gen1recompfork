-- The fishing prodigy: laid back, usually asleep by the water, and your
-- real competition at the Seaking Derby.  Wired to showa_contests --
-- she enters sittings as a live competitor.
return {
  id = "azurill",
  name = "NAGISA",
  trainerClass = "SHOWA_AZURILL_KID",
  sprite = "SPRITE_LASS",
  seed = 19880808,
  pace = 0.95,
  home = "LAKE_DERBY",
  haunts = { LAKE_DERBY = true },
  starter = { { species = "MARILL", level = 6 } },
  catches = { "GOLDEEN", "SEAKING", "MAGIKARP", "POLIWAG" },
  catchChance = 20,
  -- what she lands at a derby: a base size plus her party's best level
  derby = { base = 55, perLevel = 2, luck = 40 },
  lines = {
    greet = "...huh? Oh. Hey.\nThe fish are biting slow today.",
    challenge = "Sure, I guess. Just don't\nspook the water, okay?",
    win = "Told you. Patience.",
    loss = "Whoa! You're good.\nI'll be here tomorrow though.",
  },
}
