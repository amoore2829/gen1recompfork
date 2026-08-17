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

**Next session picks up at M2 (`showa_contests`)**: fish derby at Lake of
Rage first (judge NPC + `encounter.fishing` weighting + size records),
then wrap the engine's own Bug Contest (`bug_contest.scored`). The
framework files and design live in the plan
(`~/.claude/plans/i-would-liek-to-melodic-hejlsberg.md`) and the roadmap.
