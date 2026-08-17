# Showa Contests

The Lake of Rage Seaking Derby. Talk to the judge on the south shore to
open a sitting, fish the lake, then report back for the standings — every
catch is measured deterministically from what the mon actually is, so the
biggest fish is the biggest fish. Records persist and reach the town news
feed, and Gold's own Bug Catching Contest scores join the same record book.

Requires `showa_core`. Part of the Showa Johto suite
([../../SHOWA_ROADMAP.md](../../SHOWA_ROADMAP.md)).

Try it:

```sh
# pure judging + session rules
luajit mods/showa_contests/tests/contests_rules_test.lua

# headless gen-2 loader
luajit mods/showa_contests/tests/contests_headless_test.lua

# a whole derby on a real Gold boot
POKEPORT_GAME=gold POKEPORT_IDENTITY=derby_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/showa_contests/tests/derby_driver.lua love .
```
