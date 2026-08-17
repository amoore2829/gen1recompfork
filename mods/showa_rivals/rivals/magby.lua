-- The festival food-stall kid: the family runs a stall at the
-- pop-up markets, and he battles the way he tends a grill.
return {
  id = "magby",
  name = "TAKESHI",
  trainerClass = "SHOWA_MAGBY_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19760720,
  pace = 1.05,
  home = "AZALEA",
  haunts = { AZALEA = true, ECRUTEAK = true, GOLDENROD_ST = true },
  starter = { { species = "MAGBY", level = 6 } },
  catches = { "SLUGMA", "GROWLITHE", "HOUNDOUR", "MAGMAR" },
  catchChance = 14,
  lines = {
    greet = "Grill's hot! You eating or\nfighting? Both works!",
    challenge = "HIGH HEAT! Let's go before\nthe skewers burn!",
    win = "HAH! Well done! ...that was\na cooking joke.",
    loss = "Argh! Rare! You got me RARE!",
  },
}
