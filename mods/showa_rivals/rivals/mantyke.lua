-- The coastal surfer: waiting on the perfect wave, and taking the
-- bus everywhere because walking is a lot.
return {
  id = "mantyke",
  name = "KAI",
  trainerClass = "SHOWA_MANTYKE_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19840717,
  pace = 0.95,
  home = "CHERRYGROVE",
  haunts = { CHERRYGROVE = true, OLIVINE = true, ROUTE_34 = true },
  starter = { { species = "MANTINE", level = 8 } },
  catches = { "REMORAID", "QWILFISH", "POLIWAG", "SEAKING" },
  catchChance = 16,
  lines = {
    greet = "Swell's flat. Been flat all\nweek. Bummer.",
    challenge = "Yeah, alright. Keep it\nmellow though.",
    win = "Nice. No worries, yeah?",
    loss = "Whoa. Respect. You've got\nthe flow.",
  },
}
