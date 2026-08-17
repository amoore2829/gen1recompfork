-- Professor Elm, as a kid: book-smart, obsessed with data, treats a
-- battle as an experiment with one variable.  He is the story rival, so
-- he keeps to the lab and the ruins and needs no other Showa mod.
return {
  id = "elm",
  name = "ELM",
  trainerClass = "SHOWA_ELM",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19790401,
  pace = 1.05,
  home = "ELM_LAB",
  haunts = { ELM_LAB = true, ALPH_RUINS = true },
  starter = { { species = "TOGEPI", level = 5 } },
  catches = { "NATU", "HOOTHOOT", "SENTRET" },
  catchChance = 10,
  lines = {
    greet = "Fascinating! Your party is\nmy control group today.",
    challenge = "One battle, one variable.\nShall we record the result?",
    win = "Hypothesis confirmed!\nI must write this down...",
    loss = "An unexpected result!\nThose are the best ones.",
  },
}
