# Gen 2 API Probe

A dev diagnostic that measures which mod-API seams are live on a Gold boot:
event and hook fire counts, registry routing, `mod.world` and `mod.save`.
`docs/mod-api-gen2-compat.md` documents the intended coverage; this measures
the actual one. Re-run after every upstream sync.

Try it:

```sh
# headless (ROM-free)
luajit mods/gen2_api_probe/tests/probe_headless_test.lua

# on a real Gold boot, then open START -> PROBE
POKEPORT_GAME=gold love .

# scripted end-to-end (spawns an NPC and talks to it through a mod verb)
POKEPORT_GAME=gold POKEPORT_IDENTITY=probe_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/gen2_api_probe/tests/gold_boot_driver.lua love .
```
