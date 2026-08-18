# Showa Johto — Handover Log

The continuity document for this project: what the suite is, every decision
made so far and why, the exact state of the work, and the gotchas that cost
time once and must not cost it twice. **Update rule: append a dated session
entry every working session; edit the "Current state" and "Gotchas" sections
in place so they stay true.** The sprint checklist lives in
[SHOWA_ROADMAP.md](SHOWA_ROADMAP.md).

## What this project is

The user's spin on Pokémon Gold, built as a **modular suite of five Gen 2
mods** on this fork (bryanthaboi/gen1recomp, Lua/LÖVE2D). Theme: 70s/80s/90s
Japan; young Champion Oak; kid Professor Elm as a rival; ~20 baby-Pokémon
rivals each following their own path. Phase 1 = arcade + gatcha, rival
simulation foundation (Elm, Pichu, Azurill first), department stores +
tunnels + sticker rally, bug + fish contests.

```
showa_core  (shared library: wallet, clock, scheduler, news, venues, minigame base)
   ▲            ▲               ▲                ▲
showa_arcade  showa_malls   showa_contests   showa_rivals
                                             (optional deps on the other three)
```

## Locked decisions (user-approved 2026-08-17)

1. **Gold via upstream sync**, not Gen2Recomped (license) and not a Gen 1
   reskin. Fork `dev` now tracks upstream `dev` (Gold tab, beta).
2. **AI rivals are a clean-room rebuild.** MrKrisSatan/AIRivials has NO
   license and ships ZIP-only: design inspiration only, zero code reuse,
   never unpack its ZIPs into this repo. Its design (persistent rivals with
   own saves/routes/teams, heuristic AI, news feed) is the inspiration.
3. **Blackjack Corner (martin2844, MIT)** is the arcade's structural
   reference (`games/<id>/{rules,screen,view}.lua`, transforms.lua asset
   recipes). Borrowing code is fine WITH attribution in `mod.card.credits`.
4. **Modular suite** over one total conversion; cross-mod talk only via
   `mod.exports` / `mod.find(id).exports`.
5. Rivals v1 uses **scheduled venue appearances**, not tile pathing.
6. All suite mods: `api: 2`, `games: ["gen2"]`, `profile: "content"`.

## Current state (edit in place)

- Branches: `dev` == `upstream/dev` (22bcd95d) + the Showa M0 merge;
  `feature/showa-m0` carries the probe mod + these docs;
  `feature/celadon-battle-facility` carries the upstream merge commit
  `0a6af549` (celadon suite verified green on it).
- Gold caches imported (v10) for identities `pokemon-love2d` (default) and
  `probe_driver` (driver runs). Red re-imported fresh under `showa_import`
  and its audio.lua + programs.bin copied into the repo dev tree.
- Seven suite mods on `dev` (showa_core 0.2.0, showa_arcade, showa_contests,
  showa_malls, showa_rivals 0.3.0, showa_tournaments 0.1.0, showa_devkit
  0.1.1) plus the probe. 15 suites, ~44,900 checks, every driver at zero
  failures, `modkit validate` + `gen2check` clean on all eight.
- `mods/gen2_api_probe` DONE: headless suite **10/10**, Gold boot driver
  **16/16**, `modkit validate` + `gen2check` clean. The driver proves the
  full mod-NPC dialogue chain on Gold end to end.
- Red T3 repo suite has ~36 pre-existing upstream failures on this dev tree
  (token-oracle/parity divergences). NOT fork regressions; parked.
- Stale local `options.lua*` moved to `../.local-backup/` (they broke
  options-menu tests).

## The Gen 2 reality (from docs/mod-api-gen2-compat.md — READ IT FIRST)

- **`map_scripts` does not work on Gold** (VM runs cart bytecode). The
  interaction pattern for ALL suite features is:
  `mod.world:spawnNpc(mapId, objDef)` → player presses A →
  `World:interactBody` dispatches `npc.def.scriptKey` → **a table scriptKey
  is run by `Vm:start` as a row list** → rows like `{ "mymod:verb", ... }`
  dispatch through `mod.content.commands`; the handler gets `ctx.vm` and may
  block on `ctx.vm:showText(...)`. Respawn NPCs on `map.entered` (runtime
  objects are not serialized).
- Runtime objects must carry **no eventFlag** (mask derivation hides them
  otherwise). Minimal objDef: sprite, x, y, movement, radius, hours,
  scriptKey.
- `maps:register`/`:patch` DO work on Gold (`data.gen2Maps`); registered
  maps are warpable. Map records need an explicit `id` field. Gen 2 tileset
  walkability field is `collision`; tileset ids are `TILESET_*`.
- Bug Contest is implemented in-engine (`bug_contest.scored` event,
  encounter hooks wired into it) → wrap it, don't rebuild.
- `trainer.party` fires on Gold; `trainers` registry = class-level records
  (`{ name, trainers = { { name, party = {...} } } }`) into
  `data.gen2Trainers.classes`. `trainer.before_battle` does NOT fire.
- Real clock is mod-visible: `clock.day_changed`, `world.tod_changed`,
  hook `world.tod`.
- Gold text ids are ROM pointer strings ("55:4067"); dialogue for mod
  content goes through verbs/`showText`, not the text registry.
- No Gen 2 home (writes dropped + reported): `rulesets`, `transitions`,
  `field`, `text_pointers`, `link_fields`, `map_scripts`.
- Static check: `python tools/modkit.py gen2check <id>`. Headless harness:
  `T.sdk.loadMod("mods/<id>", { data = goldData(), generation = 2 })` —
  pattern in `mods/gen2_api_probe/tests/probe_headless_test.lua` and
  `tests/engine/gen2_content_registries.lua`.

## Gotchas (edit in place; each cost real time once)

- **Windows has no luajit binary.** Rebuild the shim per FEATURES.md:
  a `luarun/` one-file LÖVE game dir + `luajit.bat`; run suites as
  `LUA_SCRIPT=<test.lua> LUA_CWD=. lovec.exe <shim>/luarun` and set
  `MODKIT_LUAJIT=<shim>/luajit.bat` for modkit. The shim lives in the
  session scratchpad — recreate it if gone (contents in this repo's
  history / FEATURES.md description).
- **Headless import**: `POKEPORT_IMPORT_ONLY=1 POKEPORT_IMPORT_ROM=<rom>
  [POKEPORT_IDENTITY=<id>] lovec.exe .` imports and quits. Caches live in
  `%APPDATA%/LOVE/<identity>/<version>/`. Each driver identity needs its own
  Gold cache.
- **`tools/build_data.py` (dev tree, Gen 1 only) does not produce
  audio.lua/programs.bin** — the in-engine importer does. Copy both from a
  fresh import into `data/generated/` + `assets/generated/audio/` or the T3
  suite fails on `data.generated.audio`.
- Stale root `options.lua` breaks options/parity tests — keep it out of the
  repo root when running suites.
- Gold boot drivers: the driver env boots straight to the overworld (no
  cinema) with `POKEPORT_GAME=gold POKEPORT_DRIVER=<file> lovec.exe .`;
  `tests/drivers/gold_boot_smoke.lua` is the reference; `game.mods.exports.
  <id>` reaches a mod's exports; `game.world` is the Gen 2 world,
  `game.data.gen2Maps` the live map table.
- ROMs are gitignored (`*.gb`, `*.gbc`, `*.sav`) — three ROMs sit at repo
  root; **never** commit them or ROM-derived bytes (modkit lint enforces).
- **A Gen 2 warp only fires where the TILE says so.**
  `World:checkWarpOnArrive` tests the arrival cell's collision through
  `Permissions.isWarpCollision` (`0x60`, `0x68`, or high nybble `7`), so a
  perfectly-shaped warp record on plain floor is inert. Put warps on
  blocks that carry the collision: in TILESET_MART, block 42
  (`{0,0,112,112}`) is the carpet-down exit mat and block 1
  (`{122,7,0,0}`) is a staircase on its top-left cell. Carpet warps
  additionally need the player to hold that direction; staircases are
  immediate.
- When registering a new map, crib an existing map's `blocks` list rather
  than inventing block ids — the ids are tileset-specific and a wrong one
  renders garbage. `OLIVINE_MART` (6x4, TILESET_MART) is the small-room
  template this suite uses.
- `tests/drivers/util.lua`'s `U.hold` leaves `input.state[btn]` latched
  after the loop — clear the direction keys and wait for
  `world.player.moving == false` before reading player positions, or every
  cell read is racy (this masqueraded as an NPC-interaction engine bug).
- `mod.world:spawnNpc` answers `nil, err` (NOT an error) until the
  overworld is live — a `pcall`-and-latch spawn guard silently gives up
  forever. Track per-NPC returned ids and retry on the next
  `game.ready`/`map.entered`.
- **Verify NPC placement against the map's bgEvents AND objects, not just
  collision.** The Game Corner's machine banks are bgEvent columns
  (x=6-7, 12-13, 18 at y=6..11) that run cart scripts ("You have no
  coins."), and vanilla NPCs occupy more cells ((5,10), (8,7), (11,10),
  (14,8), (17,6)). A mod NPC placed on either gets shadowed. Dump all
  three layers from the gold cache before placing (this is house rule #3
  — "verify against the data, then against the render" — in Gen 2 form).
- Facing a counter tile doubles the OBJECT lookup one cell further
  (`World:interactBody`), so an NPC directly behind a counter-collision
  tile is skipped in favor of whatever the doubled cell holds.
- **A ListMenu row shares 17 glyph slots** between its label (drawn from
  x=16) and its right column (right-aligned to x=152). Anything wider
  collides into one mashed word. Budget 16 and the gap stays visible;
  `Menu.WIDTH` in showa_devkit pins it in a test. Two collisions shipped
  past green suites here — screenshot any new menu.
- **`ctx.vm:showText` takes a text KEY, not a sentence.** It looks the key
  up in the cache's text table and falls back to the literal `"..."` when
  it misses, so passing prose changes state correctly and prints dots.
  Every Showa mod says things through `core.dialogue.say`, which parks the
  line in `vm.text` under a rotating key first. This one survived four
  green drivers because they asserted STATE, never the render — take a
  screenshot of any new dialogue.
- Do NOT tick a world simulation on `map.entered`: it moves everything
  at the exact moment the player walks in to look at it. Tick on
  `map.exited` (and a step counter) so a place is as the news described
  it when you arrive.
- In a driver, `game.world` is the raw World object, NOT the mod-facing
  WorldAPI: `game.world:warpTo` fails where `mod.world:warpTo` works.
  Expose a debug warp from the mod and call that.
- **Starting a real TRAINER battle from a mod, on Gold.** A mod's table
  scriptKey may carry NATIVE VM rows beside its own verbs:
  `{ op = "loadtrainer", class = <index>, member = <n> }`,
  `{ op = "startbattle" }`, `{ op = "reloadmapafterbattle" }`. Four things
  each cost a cycle:
  (1) a native row must NOT have a string at `[1]` -- `runList` normalises
  any row without an `op` whose `[1]` is a string into a MOD COMMAND, so
  `{ "loadtrainer", 130, 1 }` is silently read as a verb of that name;
  (2) `loadtrainer` addresses a class by NUMBER
  (`src/world/gen2/Trainers.lua:classIndex` reads `class.index`), so a
  registered class without an explicit `index` is unreachable from any
  script -- Gold's own classes hold 1..66 and `showa_core`'s
  `trainers.BLOCKS` hands each mod a slice above 100;
  (3) the party the engine fights is built by `Trainers.party` FROM THE
  CLASS RECORD, so rows handed back from the `trainer.party` hook skip
  `Mon.new` and the mons arrive WITH NO MOVES -- write the live roster into
  `data.trainers.classes[id].trainers[n].party` instead (they are the same
  table as `data.gen2Trainers`, src/core/Game2.lua:963);
  (4) `reloadmapafterbattle` ENDS the script on a loss (it is the whiteout
  jump), so a verb that records the result must sit BEFORE it. The verb
  after `startbattle` reads `ctx.vm.battleOutcome` ("win"/"lose"/"draw").
  A fixed row list can fight a different opponent each time: the mod owns
  the table, and the VM reads `cmd.class` at the moment the row runs.
- **A mod's trainer class needs a battle portrait** or the intro opens on an
  empty plinth (`BattleState.trainerArt` finds nothing and
  `showEnemyTrainer` stays false). Do NOT write a cache path: modkit MK301
  fails any lua/json in the mod containing "assets/generated/", rightly.
  `core.trainers.setPic(classId, "SCHOOLBOY")` reads the art out of the
  player's own `data.gen2MenuGfx.battleHud.trainerPics` instead. It needs
  the live game, so hang it on `game.ready`.
- **`ListMenu`'s `onCancel` takes NO arguments and runs AFTER the menu has
  already popped itself** (`src/ui/ListMenu.lua:168`). `onCancel =
  function(menu) menu:close() end` is a crash on the B button -- it shipped
  in showa_devkit and was only found when a driver pressed B.
- **Gold's font has no "$".** It drops the character and logs
  `font: no glyph for "$"`. The currency glyph is charmap.asm's yen,
  `"Â¥"` (what `src/ui/gen2/Chrome.lua` and MartMenu price with).
- When a driver closes a minigame's results card, do NOT mash extra A
  presses while still facing the cabinet — each one is another paid play.
  Driver checks on `mod.save`-backed values must be relative deltas: the
  save persists across driver runs of the same identity.

## Session log (append entries; newest last)

### 2026-08-17 — M0: upstream sync, Gold import, probe mod

- Fast-forwarded `dev` 752 commits to `upstream/dev`; merged into
  `feature/celadon-battle-facility` (one conflict: `.gitignore`, union
  kept the fork's ROM ignore block). Celadon suite 304/304 post-merge.
- Re-imported Red (new cache format) + imported Gold (v10, canonical SHA)
  headlessly; fixed dev-tree audio gap; moved stale options.lua aside
  (repo suite failures 39 → ~36, remainder are upstream dev-tree issues).
- Read the two gen2 compat docs; recorded the design pivots above (biggest:
  map_scripts → spawnNpc + verb row lists).
- Confirmed Johto anchor map ids in the Gold cache.
- Built `mods/gen2_api_probe` (manifest, main, mod.card, README, CHANGELOG,
  headless suite, Gold boot driver). Headless 10/10. Driver 16/16: mod
  loads on Gold, registries land (maps/trainers/commands/screens),
  mod.save roundtrips, events/hooks fire (game.ready, map.entered,
  world.stepped, world.interacted, input.step, world.tod), spawnNpc
  returns an id, the NPC is pooled, and talking to it runs the probe's
  own verb through the VM (`ctx.vm:showText` works). Two debugging
  lessons now in Gotchas: runtime objects must carry no eventFlag, and
  `U.hold` leaves the button latched — release the pad and wait for
  `player.moving == false` before reading positions in a driver.
- `modkit validate` + `gen2check` green on the probe.
- Created SHOWA_ROADMAP.md + this handover doc.
- Committed on `feature/showa-m0`, merged to `dev`.

### 2026-08-17 (later) — M1: showa_core + showa_arcade land

- `mods/showa_core` 0.1.0: wallet/clock/scheduler/news/venues (pure libs)
  + minigame scaffold + ShowaNews screen + full export surface. 40/40
  pure checks, 13/13 headless, validate + gen2check clean.
- `mods/showa_arcade` 0.1.0: token clerk (reads/writes
  `game.save.player.money`), EKANS cabinet (seeded snake on the
  scaffold), gatcha (weighted pool + duplicate protection + reveal
  screen), high-score ledger with news posts and the
  `submitScore`/`highScore`/`gatchaOwned` rival seam. 2017 rules checks,
  12 headless, Gold driver 18 checks / 0 failures, validate + gen2check
  clean.
- Debugging that produced the new Gotchas above: NPC placement shadowed
  by the Game Corner's machine bgEvents and a vanilla NPC at (14,8); the
  spawn guard latching on a nil spawn; results-card A-mash re-buying
  plays; per-identity save persistence in driver checks.
- Both mods committed on `feature/showa-m1`, merged to `dev`, pushed.

### 2026-08-17 (later still) — M2: showa_contests lands

- `mods/showa_contests` 0.1.0: Seaking Derby judge at Lake of Rage
  (18,29 — south shore, verified free against the map's object/bgEvent/
  collision layers), pure `judging.lua` (size from level+DVs, SEAKING
  bonus) and `session.lua` (start/record/finish/standings), persistent
  fish+bug record book, news coverage, and the
  `registerCompetitor` seam showa_rivals will fill.
- Bug Contest is wrapped, not rebuilt: the engine runs its own contest
  and `bug_contest.scored` feeds our record book.
- 76 pure checks, 11 headless, derby driver 12 checks / 0 failures,
  validate + gen2check clean. Merged to `dev`, pushed.
- Test-writing gotcha worth keeping: a `nil` hole in a Lua array literal
  truncates `ipairs`, so a "malformed row is skipped" test written with
  an embedded nil tests Lua, not the guard.

**Superseded — M3 landed. (Was: next session picks up at M3.)**: Olivine shopping-street
mall (new `maps:register` interiors, ≤7×6 blocks/floor, NPCs at y≥4),
tunnel maps linking Goldenrod Underground to the mall basement, and the
per-store sticker rally with the `ShowaStickerAlbum` screen. Design lives
in the plan (`~/.claude/plans/i-would-liek-to-melodic-hejlsberg.md`) and
the roadmap. Note M3 is the first milestone that REGISTERS new maps
rather than spawning into vanilla ones — expect the render-verification
step (house rule #3) to matter most here.

### 2026-08-17 (M3) — showa_malls lands

- `mods/showa_malls` 0.1.0: three registered maps (SHOWA_MALL_1F / 2F /
  TUNNEL) on OLIVINE_MART's verified block layout, with real staircase
  blocks substituted at the warp cells; greeters in Olivine City (17,18)
  and Goldenrod Underground (5,13); a four-counter stamp rally with the
  ShowaStickerAlbum screen and a full-book prize.
- The debugging lesson is now the biggest new Gotcha above: warps need a
  warping TILE, not just a warp record. The rules suite now asserts it for
  every warp, so the whole suite inherits the guard.
- 69 pure checks, 10 headless, mall driver 16 checks / 0 failures,
  validate + gen2check clean.

### 2026-08-17 (M4) — showa_rivals lands; PHASE 1 COMPLETE

- `mods/showa_rivals` 0.1.0: `sim/` (rng, growth, advance) is pure and
  seeded, so a rival's whole life replays from its seed; 1000-tick soak
  per rival holds every invariant (always at a real venue, never in
  debt, legal party size, never loses levels). Three rivals ship: ELM,
  SPARKS (posts real EKANS scores to showa_arcade), NAGISA (enters
  Seaking Derby sittings through showa_contests' registerCompetitor).
- Battle parties are substituted live through `trainer.party`, so the
  team you fight is the team the news has been reporting.
- 29,778 sim checks, 27 headless (including a load with NONE of the
  optional dependencies), driver 21 checks / 0 failures, validate +
  gen2check clean.
- Two fixes worth remembering, both now in Gotchas:
  ticking the simulation on `map.entered` moved rivals away at the
  moment the player walked in to see them (now ticks on `map.exited`),
  and drivers must warp through the mod's own WorldAPI-backed helper,
  not `game.world:warpTo`.

**Phase 1 is complete.** All five suite mods plus the probe are on `dev`,
each with pure suites, headless gen-2 suites, a live Gold driver at zero
failures, and clean `modkit validate` + `gen2check`. Whole-project suite
run: 32,063 checks green across 11 suites.

**Next session picks up at M5 (polish)** — see the roadmap: DDR as arcade
game 2, FEATURES.md rows for the suite, and then the Phase 2 backlog
(the remaining ~17 rivals are one data file each in
`mods/showa_rivals/rivals/`, which is the framework paying off).

### 2026-08-17 (dev tooling) — showa_devkit

- `mods/showa_devkit` 0.1.0: a SHOWA DEV row on the START menu opening a
  paged test kit (warp / cabinets / wallet / derby / stamps / rivals /
  diagnostic). Pages for absent feature mods are hidden, so it runs on
  any subset; requires only showa_core.
- `menu.lua` is pure data and `main.lua` is the wiring, so the tree is
  testable without a boot — 96 checks, plus an 18-check Gold driver.
- Added `showa_rivals` `debug.sendAll(venueId)` so the kit can gather the
  whole cast onto one map.
- Two menu-layout collisions were caught by screenshot after the suites
  were green; the glyph-budget rule is now in Gotchas and pinned by a
  test.

### 2026-08-17 (M6) — showa_tournaments, and the trainer-battle seam

- `mods/showa_tournaments` 0.1.0: three cups on the National Park lawn
  (ROOKIE Lv15 / OPEN Lv30 + 3 badges / MASTER Lv50 + 6 badges), an
  eight-slot seeded single-elimination draw, a registrar and a referee at
  (13,44) and (15,44), a bracket board, per-cup records, prize money and
  news coverage. `bracket/` and `cups/` are pure, so the draw, the byes,
  the round rollover and the placement table are all testable from
  literals; `desk/menu.lua` is pure for the same reason the devkit's is.
- **The big one: this is the first Showa mod that starts a REAL trainer
  battle**, and the recipe is now in Gotchas above. The short version is
  that a mod's row list may carry native `loadtrainer` / `startbattle` /
  `reloadmapafterbattle` rows, that `loadtrainer` needs a numeric class
  index, that the roster must go into the CLASS RECORD (not through the
  `trainer.party` hook, which skips `Mon.new` and hands over mons with no
  moves), and that the result verb must sit before the reload.
- That found a latent bug in showa_rivals: its `trainer.party` substitution
  would have put move-less mons into any battle. Rivals 0.3.0 writes the
  live roster into the class record instead, carries a class index, and
  exports `battleCard` / `syncParty` so a cup can stand a team up under a
  level cap and put it back afterwards.
- showa_core 0.2.0 owns the shared half: `core.trainers` hands each mod its
  own slice of the class-index space, writes rosters, and borrows a
  portrait out of the player's own art table (a cache path written into a
  mod is an MK301 failure, and rightly).
- Three bugs the Gold driver caught that no suite could: a crash on the B
  button (`ListMenu`'s `onCancel` takes no arguments and the menu is
  already popped -- showa_devkit had the same bug and is fixed too), Gold's
  font having no "$", and a fourth menu-column collision
  ("SEE THE BOARDOKIE"). All three are in Gotchas.
- Suites: 1837 rules + 123 headless + 102 menu, Gold driver 28 checks / 0
  failures, validate + gen2check clean. showa_devkit 0.1.1 gains a CUPS
  page so the whole circuit can be driven from the START menu.
