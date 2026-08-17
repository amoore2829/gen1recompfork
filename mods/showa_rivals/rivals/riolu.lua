-- The shonen protagonist: believes he is the main character of a
-- 90s action anime, and honestly makes a decent case for it.
return {
  id = "riolu",
  name = "HAYATO",
  trainerClass = "SHOWA_RIOLU_KID",
  sprite = "SPRITE_GENTLEMAN",
  seed = 19900909,
  pace = 1.2,
  home = "BLACKTHORN",
  haunts = { BLACKTHORN = true, MAHOGANY = true, ECRUTEAK = true, GOLDENROD_ST = true },
  starter = { { species = "MACHOP", level = 7 } },
  catches = { "TYROGUE", "MACHOKE", "HERACROSS" },
  catchChance = 13,
  lines = {
    greet = "I felt your presence from\nthree routes away.",
    challenge = "Our destinies were always\ngoing to collide here!",
    win = "This... this is only the\nbeginning of my power!",
    loss = "Impossible! Then... then\nI must train HARDER!",
  },
}
