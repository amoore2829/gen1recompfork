# Fork features

Features added on top of [bryanthaboi/gen1recomp](https://github.com/bryanthaboi/gen1recomp)
in this fork. Upstream's own additions are documented in
[docs/new-features.md](docs/new-features.md); this file covers only what is
ours.

Updated at the completion of every feature. Planning and continuity for the
Showa Johto project live in [SHOWA_ROADMAP.md](SHOWA_ROADMAP.md) (the sprint
checklist) and [SHOWA_HANDOVER.md](SHOWA_HANDOVER.md) (decisions, state, and
the gotchas each cost a debugging cycle once).

| Feature | Kind | Version | Status | Lives in |
|---|---|---|---|---|
| [Showa Core](#showa-core) | Mod | 0.1.0 | Shipped | [mods/showa_core/](mods/showa_core/) |
| [Showa Arcade](#showa-arcade) | Mod | 0.2.0 | Shipped | [mods/showa_arcade/](mods/showa_arcade/) |
| [Showa Contests](#showa-contests) | Mod | 0.1.0 | Shipped | [mods/showa_contests/](mods/showa_contests/) |
| [Showa Malls](#showa-malls) | Mod | 0.1.0 | Shipped | [mods/showa_malls/](mods/showa_malls/) |
| [Showa Rivals](#showa-rivals) | Mod | 0.1.0 | Shipped | [mods/showa_rivals/](mods/showa_rivals/) |
| [Gen 2 API Probe](#gen-2-api-probe) | Mod (dev tool) | 0.1.0 | Shipped | [mods/gen2_api_probe/](mods/gen2_api_probe/) |
| ROM files gitignored | Repo hygiene | — | Shipped | [.gitignore](.gitignore) |

The Celadon Battle Facility lives on `feature/celadon-battle-facility` and is
documented there; it is a Gen 1 mod and predates the Gold work.

---

## The Showa Johto suite

A spin on Pokemon Gold set in 70s/80s/90s Japan, built as five mods rather
than one conversion so each piece ships, tests and fails on its own. Every
mod is `api` 2, `games: ["gen2"]`, and carries a pure suite, a headless
gen-2 loader suite, and a driver that runs on a real Gold boot.

```
showa_core  (shared library: wallet, clock, scheduler, news, venues, minigames)
   ^            ^               ^                ^
showa_arcade  showa_malls   showa_contests   showa_rivals
                                             (optional deps on the other three)
```

### Showa Core

The library the rest of the suite is written against, and no gameplay of its
own: a multi-currency wallet, a mirror of Gold's clock fed by
`clock.day_changed` / `world.tod_changed` / the `world.tod` hook, day-and-time
opening hours, a capped town news feed behind a NEWS row on the START menu,
the venue graph the rival simulation walks, and the arcade cabinet scaffold
(fixed tick, pause, results card, score handoff). Everything but the scaffold
is pure Lua.

Suites: 40 pure lib checks, 13 headless.

### Showa Arcade

The Goldenrod Game Corner as a Showa-era arcade. A clerk sells 10 GAME TOKENS
for $500, the EKANS cabinet takes one, and the gatcha machine takes three.
EKANS is a seeded snake — same seed, same game, move for move.
**DITTO DITTO REVOLUTION** is the second cabinet: four lanes, a chart generated
from a seed, PERFECT/GOOD windows and a combo bonus every tenth step. The
gatcha rolls a weighted three-tier pool with duplicate protection on its two
trophies. Records and rare pulls reach the news feed, and
`highScore` / `submitScore` are the seam the rivals post through.

Suites: 3732 pure rules checks, 12 headless, 18-check Gold driver plus a DDR driver.

### Showa Contests

The Lake of Rage Seaking Derby. A judge on the south shore opens a sitting;
every catch made during it is measured deterministically from the mon's level
and DVs (with a SEAKING bonus), so the biggest fish is always the biggest
fish. Reporting back gives standings against a competitor field other mods
fill in. Gold runs its own Bug Catching Contest, so that half is wrapped
rather than rebuilt: `bug_contest.scored` lands in the same record book.

Suites: 76 pure rules checks, 11 headless, 12-check Gold driver.

### Showa Malls

An Olivine shopping arcade over two floors, joined to Goldenrod's underground
by a chikagai passage — the first fork feature to register maps rather than
spawn into vanilla ones. Four counters make up a stamp rally, tracked on a
STAMPS screen, with a prize for a full book.

The load-bearing detail is that **a Gen 2 warp only fires where the tile says
so**: `World:checkWarpOnArrive` tests the arrival cell's collision, so a warp
record on plain floor is inert. The staircases are made by substituting
TILESET_MART's own staircase block at each warp cell, and the street exits sit
on the template's carpet mat. The rules suite asserts it for every warp.

Suites: 69 pure rules checks, 10 headless, 16-check Gold driver.

### Showa Rivals

Rivals with lives of their own: they travel the venue graph, train toward the
player's level, shop, and catch from their own species pools, and the team you
fight is the team they have actually been building (substituted live through
the `trainer.party` hook). Three of a planned cast of twenty ship — ELM,
SPARKS the arcade rat who really does take over the EKANS board, and NAGISA
the fishing prodigy who enters the derby against you.

The brain is pure and seeded, so a rival's whole life replays from its seed
and the suite can soak a thousand ticks per rival. The world turns when the
player *leaves* a map rather than enters one, so a rival is where the news
said it was. Adding rivals 4 through 20 is one data file each.

Clean-room work: MrKrisSatan's AIRivals is the inspiration for the idea and
nothing else — it ships without a license and only as zips, so none of it was
read, unpacked or copied.

Suites: 29,778 pure sim checks, 27 headless (including a load with none of the
optional dependencies present), 21-check Gold driver.

### Gen 2 API Probe

A dev diagnostic that measures which mod-API seams actually fire on a Gold
boot — event and hook counts, registry routing, `mod.world`, `mod.save` —
behind a PROBE row on the START menu. `docs/mod-api-gen2-compat.md` documents
the intended coverage; this measures the real one. Re-run it after every
upstream sync.

## Conventions for the next feature

The house rules the celadon branch established, plus what the Gen 2 work
added. The long form, with the debugging each came from, is in
[SHOWA_HANDOVER.md](SHOWA_HANDOVER.md).

1. **Prefer a mod to an engine change.** Note the standing cost: any loaded
   mod disables online link play.
2. **One branch per feature, `feature/<name>`, off `dev`**; keep upstream
   merges as their own commits.
3. **Verify against the data before you trust it.** On Gen 2 that means three
   layers, not one: a cell can be walkable and still be a bgEvent that runs a
   cart script, or already be a vanilla NPC's. Dump collision, objects and
   bgEvents before placing anything.
4. **A warp needs a warping tile**, not just a warp record.
5. **`map_scripts` has no Gen 2 home.** Interaction is `mod.world:spawnNpc`
   plus a row-list `scriptKey` dispatching this mod's own verbs through the
   VM, which is what the probe proved and every suite mod uses.
6. **Ship a pure suite, a headless gen-2 suite, and a driver.** Keep the
   simulation logic pure and the engine at the edges; that is what makes a
   thousand-tick soak possible.
7. **Never ship ROM-derived content.** `modkit lint` and `pack` enforce it.
8. **Update this file, SHOWA_ROADMAP.md and SHOWA_HANDOVER.md** when a
   feature lands.

## Running the tests on Windows

There is no LuaJIT binary for Windows (CI installs it via apt). LÖVE embeds
LuaJIT 2.1 and can stand in: point a one-file game directory's `main.lua` at
the script, clear `_G.love` so the harness installs its own stub, and set
`MODKIT_LUAJIT` at that shim for `modkit validate`.

```sh
LUA_SCRIPT=mods/showa_core/tests/core_libs_test.lua LUA_CWD=. \
  lovec.exe <shim>/luarun

POKEPORT_GAME=gold POKEPORT_IDENTITY=<id> POKEPORT_NO_DISCORD=1 \
  POKEPORT_DRIVER=mods/<mod>/tests/<driver>.lua lovec.exe .
```

A driver identity needs its own imported cache:
`POKEPORT_IMPORT_ONLY=1 POKEPORT_IMPORT_ROM=<rom> POKEPORT_IDENTITY=<id>
lovec.exe .`
