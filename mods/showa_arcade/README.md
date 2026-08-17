# Showa Arcade

The Goldenrod Game Corner becomes a Showa-era arcade: buy GAME TOKENS from
the clerk, play the EKANS snake cabinet, and turn the gatcha crank for
capsule prizes. Records post to the town news feed, and other Showa mods
(the rivals) can post scores through the export seam.

Requires `showa_core`. Part of the Showa Johto suite
([../../SHOWA_ROADMAP.md](../../SHOWA_ROADMAP.md)).

Try it:

```sh
# pure rules
luajit mods/showa_arcade/tests/arcade_rules_test.lua

# headless gen-2 loader
luajit mods/showa_arcade/tests/arcade_headless_test.lua

# the whole token economy on a real Gold boot
POKEPORT_GAME=gold POKEPORT_IDENTITY=arcade_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/showa_arcade/tests/arcade_driver.lua love .
```
