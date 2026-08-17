# Showa Rivals

Rivals with lives of their own. They travel Johto on the venue graph,
train toward your level, catch Pokemon, and turn up where their interests
take them — and when you fight one, the team you face is the team it has
actually been building. Check the RIVALS row on the START menu to see who
is where.

Ships three of a planned cast of twenty: **ELM** (kid Professor Elm, who
treats a battle as an experiment), **SPARKS** (the arcade rat, who really
does take over the EKANS high-score board), and **NAGISA** (the fishing
prodigy, who enters the Seaking Derby against you).

Requires `showa_core`; makes optional use of `showa_arcade`,
`showa_contests` and `showa_malls`, and runs without any of them. Part of
the Showa Johto suite ([../../SHOWA_ROADMAP.md](../../SHOWA_ROADMAP.md)).

Clean-room work: MrKrisSatan's AIRivals is the inspiration for the idea,
and nothing else — that mod ships without a license and only as zips, so
none of it was read, unpacked or copied.

Try it:

```sh
# the brain, soaked for a thousand ticks per rival
luajit mods/showa_rivals/tests/sim_test.lua

# headless gen-2 loader, with the suite and then alone
luajit mods/showa_rivals/tests/rivals_headless_test.lua

# ticking, appearing and talking on a real Gold boot
POKEPORT_GAME=gold POKEPORT_IDENTITY=rivals_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/showa_rivals/tests/rivals_driver.lua love .
```
