# Showa Tournaments

The cup circuit on the National Park lawn: a folding table, a hand-lettered
bracket board, and three tournaments to work your way up.

## Where

**NATIONAL_PARK**, on the lawn south of the middle of the map.

- **The registrar** at (13,44) — enter a cup, read the board, check records.
- **The referee** at (15,44) — talk to play your match.

Both are one cell north of a free walkable tile, so you can always stand in
front and press A.

## The cups

| Cup | Cap | Fee | Needs | Prize |
|---|---|---|---|---|
| ROOKIE | Lv15 | $500 | — | $3,000 |
| OPEN | Lv30 | $1,500 | 3 badges | $9,000 |
| MASTER | Lv50 | $3,000 | 6 badges | $25,000 |

Eight entrants, single elimination: you, whichever rivals the cup suits, and a
house field to fill the rest. The draw is seeded, so the bracket you read is
the bracket you play.

Your matches are real trainer battles. The other three matches in a round are
settled by a seeded roll over party strength while you play yours — which is
honest about being a formula, and at least a formula over the same teams the
real battle would have used.

**The cap applies to your opponents by construction** (their teams are built
at the cap for the match and put back afterwards). It cannot apply to you the
same way without rewriting mons in your save, so an over-levelled party is
turned away at the desk instead.

## With and without `showa_rivals`

With it, the field is drawn from the twenty rivals — sorted by how close their
lead is to the cup's cap, so the three cups field three different casts, and
their battle teams are the ones the news has been reporting. Without it, the
house field fills every slot and the mod runs exactly the same.

## Testing

```sh
# pure suites (no boot) -- see FEATURES.md for the Windows LuaJIT shim
LUA_SCRIPT=mods/showa_tournaments/tests/tournaments_rules_test.lua LUA_CWD=. \
  lovec.exe <shim>/luarun

# headless, against the Gold data tables
LUA_SCRIPT=mods/showa_tournaments/tests/tournaments_headless_test.lua LUA_CWD=. \
  lovec.exe <shim>/luarun

# on a live Gold boot
POKEPORT_GAME=gold POKEPORT_IDENTITY=cup_driver POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/showa_tournaments/tests/cup_driver.lua lovec.exe .
```

## The battle seam

This is the first mod in the suite to start a real trainer battle. The three
facts that make it work are written at the top of `main.lua`; the short
version is that a mod's row list may carry native VM rows (`loadtrainer`,
`startbattle`, `reloadmapafterbattle`) alongside its own verbs, that
`loadtrainer` addresses a class by number so the class needs an explicit
`index`, and that the party the engine fights is built from the class record
rather than from whatever the `trainer.party` hook hands back.
