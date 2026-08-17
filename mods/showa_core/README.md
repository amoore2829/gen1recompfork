# Showa Core

The shared library for the Showa Johto suite: a multi-currency wallet, a
mirror of Gold's clock, venue opening hours, the town news feed, the venue
graph, and the arcade minigame screen scaffold — all published through
`mod.find("showa_core").exports`. Ships no gameplay of its own.

Try it:

```sh
# pure rules, no engine
luajit mods/showa_core/tests/core_libs_test.lua

# under the headless gen-2 loader
luajit mods/showa_core/tests/core_headless_test.lua

# in game: START -> NEWS on a Gold boot
POKEPORT_GAME=gold love .
```
