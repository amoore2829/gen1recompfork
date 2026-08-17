-- The gadget tinkerer: takes apart radios, cassette decks and CRTs
-- to find out how they work, and mostly gets them back together.
return {
  id = "elekid",
  name = "DENJI",
  trainerClass = "SHOWA_ELEKID_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19820605,
  pace = 1.1,
  home = "ROUTE_34",
  haunts = { ROUTE_34 = true, GOLDENROD_ST = true, BLACKTHORN = true },
  starter = { { species = "ELEKID", level = 6 } },
  catches = { "MAGNEMITE", "VOLTORB", "ELECTABUZZ", "PORYGON" },
  catchChance = 15,
  lines = {
    greet = "Don't touch that, it's live.\n...probably. Mostly.",
    challenge = "I rewired my strategy last\nnight. Want to field-test it?",
    win = "Ha! The circuit holds!",
    loss = "Interesting failure mode.\nI'm taking notes.",
  },
}
