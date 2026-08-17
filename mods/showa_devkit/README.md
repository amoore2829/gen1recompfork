# Showa Dev Kit

A test menu for the whole Showa suite. Press START and pick **SHOWA DEV**.

| Page | What it does |
|---|---|
| **WARP TO...** | Every venue in the graph, alphabetical. Picking one puts you one step south of it, facing it. |
| **CABINETS** | Opens EKANS, DITTO REV. or the GATCHA directly, without paying. |
| **WALLET** | +50 game tokens, +9000 money, +100 mall points. |
| **DERBY** | Open a sitting, land a big Seaking, weigh in — the whole contest without fishing. |
| **STAMPS** | Stamps every rally counter, through the same verb the counters use. |
| **RIVALS** | Run 10 simulation ticks, call the whole cast to where you are, or pick a rival to warp to them. Each row shows their level and where they are. |
| **DIAGNOSTIC** | Which suite mods are installed, how many venues the graph holds, how big the cast is. |

Every page that depends on a feature mod is hidden when that mod is not
installed, so the kit works on any subset of the suite. Requires
`showa_core` only.

Part of the Showa Johto suite
([../../SHOWA_ROADMAP.md](../../SHOWA_ROADMAP.md)).

Try it:

```sh
# the menu tree, built from literals
luajit mods/showa_devkit/tests/devkit_menu_test.lua

# the kit driving itself on a real Gold boot
POKEPORT_GAME=gold POKEPORT_IDENTITY=devkit_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/showa_devkit/tests/devkit_driver.lua love .
```

Turn it off in the in-game mod manager (F10) when you want to play
normally — it is a TOOL, not content.
