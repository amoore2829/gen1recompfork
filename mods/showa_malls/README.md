# Showa Malls

An Olivine shopping arcade over two floors, joined to Goldenrod's
underground by a chikagai passage. Collect a stamp at every counter, watch
the book fill on the STAMPS screen, and claim the set prize at the info
desk. Greeters on the Olivine street and down in the Goldenrod Underground
show you in.

Requires `showa_core`. Part of the Showa Johto suite
([../../SHOWA_ROADMAP.md](../../SHOWA_ROADMAP.md)).

Try it:

```sh
# the rally board and the map records (warp indices, warp tiles, cast cells)
luajit mods/showa_malls/tests/malls_rules_test.lua

# headless gen-2 loader
luajit mods/showa_malls/tests/malls_headless_test.lua

# the rooms, the staircase and the rally on a real Gold boot
POKEPORT_GAME=gold POKEPORT_IDENTITY=mall_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/showa_malls/tests/mall_driver.lua love .
```
