-- The fashionista: judges your battling on presentation first and
-- results second. Lives on the department store's upper floors.
return {
  id = "smoochum",
  name = "RUKA",
  trainerClass = "SHOWA_SMOOCHUM_KID",
  sprite = "SPRITE_LASS",
  seed = 19910301,
  pace = 1.1,
  home = "DEPT_STORE",
  haunts = { DEPT_STORE = true, GOLDENROD_ST = true, SHOWA_MALL = true, CHIKAGAI = true },
  starter = { { species = "SMOOCHUM", level = 6 } },
  catches = { "CLEFAIRY", "MISDREAVUS", "DELIBIRD" },
  catchChance = 12,
  lines = {
    greet = "Hmm. That outfit is a\nCHOICE. Bold. Not for me.",
    challenge = "Let's see if your battling\nhas any STYLE to it.",
    win = "Presentation. It's always\npresentation.",
    loss = "Fine. FINE. You have taste.\nI'm putting it in writing.",
  },
}
