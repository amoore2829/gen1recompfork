# Showa Johto — Roadmap & Timeline Checklist

A modular mod suite for Pokémon Gold on this fork: 70s/80s/90s Japan setting,
young Champion Oak, kid-rival Elm, ~20 baby-Pokémon rivals, arcade + gatcha,
department stores + sticker rally, contests, and later tournaments, parties,
and a safari zone. Full context lives in [SHOWA_HANDOVER.md](SHOWA_HANDOVER.md).

**Update rule: check items off (and date them) the moment they land; add new
rows rather than rewriting history.**

## M0 — Upstream sync + Gold-runtime audit

- [x] Merge `upstream/dev` into fork `dev` (fast-forward; 752 commits) — 2026-08-17
- [x] Merge `dev` into `feature/celadon-battle-facility`; resolve `.gitignore` union (ROM ignore rules kept) — 2026-08-17
- [x] Celadon Battle Facility suite green post-merge (304/304) — 2026-08-17
- [x] Headless Red re-import for the new cache format; audio cache copied into dev tree — 2026-08-17
- [x] Gold ROM imported (canonical US SHA-1, v10 cache) for default + driver identities — 2026-08-17
- [x] Read `docs/mod-api-gen2-compat.md` + note design pivots (see handover) — 2026-08-17
- [x] Johto anchor map ids confirmed from the Gold cache (`GOLDENROD_GAME_CORNER`, `GOLDENROD_DEPT_STORE_1F..6F/B1F`, `GOLDENROD_UNDERGROUND`, `NATIONAL_PARK_BUG_CONTEST`, `LAKE_OF_RAGE`, `OLIVINE_CITY`, `ELMS_LAB`) — 2026-08-17
- [x] `mods/gen2_api_probe` built; headless harness suite 10/10 — 2026-08-17
- [x] Gold boot driver fully green (16/16: spawnNpc → interact → VM row list → mod verb → showText all proven) — 2026-08-17
- [x] `modkit validate` + `gen2check` clean on the probe — 2026-08-17
- [x] Commit M0 on `feature/showa-m0`; merged to `dev` — 2026-08-17
- [ ] FEATURES.md row for the probe (fold into M1 landing)

## M1 — showa_core + showa_arcade (first playable)

- [x] `showa_core`: wallet, clock (wraps Gen 2 clock events), scheduler, news, venues, minigame base — 40/40 pure checks — 2026-08-17
- [x] `showa_core` exports wired; save schema v1; ShowaNews screen on START menu; 13/13 headless checks — 2026-08-17
- [x] `showa_arcade`: clerk + EKANS cabinet + gatcha NPCs on the Game Corner floor (runtime-object seam; placements verified against bgEvent/object/collision dumps) — 2026-08-17
- [x] Ekans snake (pure seeded `rules.lua` + procedural LCD view) — 2026-08-17
- [x] Gatcha machine (weighted pool, capsule screen, trophy duplicate protection, RARE news posts) — 2026-08-17
- [x] ARCADE_TOKEN currency + counter clerk (10 tokens / $500 via `save.player.money`) — 2026-08-17
- [x] High-score ledger + `submitScore`/`highScore`/`gatchaOwned` exports (rival seam) — 2026-08-17
- [x] Suites: 2017 rules checks + 12 headless + end-to-end Gold driver (18 checks, 0 failures) — 2026-08-17
- [x] validate + gen2check clean on both mods — 2026-08-17
- [x] FEATURES.md rows — 2026-08-17
- [x] DDR as arcade game 2 — landed in M5 — 2026-08-17

## M2 — showa_contests

- [x] Shared framework: `session.lua` + `judging.lua` (pure, 76 checks) — 2026-08-17
- [x] Fish derby at Lake of Rage (judge NPC on the south shore, deterministic size records, standings) — 2026-08-17
- [x] Bug Contest wrap (`bug_contest.scored` lands in the same record book) — 2026-08-17
- [x] `registerCompetitor` / `records` / `isSessionActive` export seam — 2026-08-17
- [x] Driver: full derby on Gold with a forced Seaking (12 checks, 0 failures) — 2026-08-17
- [x] validate + gen2check clean — 2026-08-17
- [ ] Seaking-weighted `encounter.fishing` at the lake (deferred to polish)
- [ ] Entry fee, timer, and placement prizes (deferred to polish)

## M3 — showa_malls

- [x] Olivine shopping arcade: SHOWA_MALL_1F + 2F registered on OLIVINE_MART's verified block layout — 2026-08-17
- [x] SHOWA_MALL_TUNNEL chikagai passage + working staircases and street/underground exits (real staircase blocks substituted so warps fire) — 2026-08-17
- [x] Four sticker-rally counters (spawnNpc + verb rows), no double-stamping — 2026-08-17
- [x] `ShowaStickerAlbum` screen on the START menu + 100 MALL POINTS for a full book — 2026-08-17
- [x] `stickerCount`/`hasSticker`/`album` exports — 2026-08-17
- [x] Driver: rooms load, staircase round trip, rally stamps (16 checks, 0 failures) — 2026-08-17
- [x] validate + gen2check clean — 2026-08-17
- [ ] A real shopfront stamped onto Olivine City (deferred: needs render verification)

## M4 — showa_rivals

- [x] `sim/` pure framework: rng, growth, advance (seeded, deterministic; 1000-tick soak per rival) — 2026-08-17
- [x] Venue-graph scheduled appearances; rivals spawn where they stand and leave when they move on — 2026-08-17
- [x] Rival battle seam: trainer class per rival + live-party substitution through `trainer.party` — 2026-08-17
- [x] Rival 1: ELM (Togepi; Elm's Lab / Ruins of Alph; story rival) — 2026-08-17
- [x] Rival 2: SPARKS the Pichu arcade rat (really posts EKANS scores) — 2026-08-17
- [x] Rival 3: NAGISA the Azurill fishing prodigy (enters derby sittings) — 2026-08-17
- [x] News feed integration; `ShowaRivalDex` screen off the START menu — 2026-08-17
- [x] Driver: ticking, appearing, talking, derby entry (21 checks, 0 failures) — 2026-08-17
- [x] Loads correctly with NONE of its optional dependencies (asserted in the headless suite) — 2026-08-17
- [x] validate + gen2check clean — 2026-08-17
- [ ] Rival-vs-rival battles and gym challenges (deferred)

**Phase 1 complete: all four feature groups shipped and driver-verified on Gold.**

## M5 — Polish pass

- [x] Honest `mod.card` known-limitations ledgers, READMEs, CHANGELOGs across the suite — 2026-08-17
- [x] FEATURES.md written on `dev` with the suite, conventions, and the Windows test recipe — 2026-08-17
- [x] Ditto Ditto Revolution as arcade game 2 (seeded chart, combo scoring; original chiptune still pending) — 2026-08-17
- [ ] Re-run the probe and record the coverage table after the next upstream sync

## M6 — showa_tournaments (the cup circuit)

- [x] Pure bracket engine: seeded draw, byes, round rollover, standings — 1837 checks — 2026-08-17
- [x] Seeded strength roll settles the matches the player is not in — 2026-08-17
- [x] Three cups on the National Park lawn (ROOKIE Lv15 / OPEN Lv30+3 badges / MASTER Lv50+6 badges) with fees and prize money — 2026-08-17
- [x] Field mixes the player, the rivals a cup suits, and an eight-strong house field; runs standalone without `showa_rivals` — 2026-08-17
- [x] **Real trainer battles** for the player's own matches (native `loadtrainer`/`startbattle` rows in the referee's row list) — 2026-08-17
- [x] Registrar + referee NPCs, bracket board, per-cup records, news coverage — 2026-08-17
- [x] Suites: 1837 rules + 123 headless + 102 menu-width + Gold driver (28 checks, 0 failures) — 2026-08-17
- [x] validate + gen2check clean — 2026-08-17
- [ ] Cup calendar (a cup should open on a schedule, not whenever you ask)
- [ ] Rival-vs-rival matches simulated rather than rolled

## The battle seam (landed with M6, used by everything after it)

- [x] `showa_core` 0.2.0 `core.trainers`: per-mod class-index blocks, live-roster writer, portrait borrower — 2026-08-17
- [x] `showa_rivals` 0.3.0: every rival class is now fightable (numeric index, real roster, portrait) — 2026-08-17
- [x] Fixed: rival parties handed back from the `trainer.party` hook arrived with NO MOVES; the roster goes into the class record instead — 2026-08-17

## M7 — showa_parties (the neighbourhood meet-up)

- [x] Pure schedule: a party every third day, rotating venue and theme — 2026-08-17
- [x] Pure guest generation: five guests drawn from the day and the room, names unique per party — 2026-08-17
- [x] Item exchange ("I want X, I'll give you Y") with bag and stack-limit rules — 2026-08-17
- [x] **Real POKEMON trades** through the engine's own `NpcTrade.perform`: level carried over, stats recomputed, nickname + OT set, #DEX ticked — 2026-08-17
- [x] Friendly trainer battles against guests, scaled to the player — 2026-08-17
- [x] A host with the guest list, tonight's theme and the countdown; news announces the next party — 2026-08-17
- [x] Suites: 582 rules + 123 headless + Gold driver (34 checks, 0 failures) — 2026-08-17
- [x] validate + gen2check clean — 2026-08-17
- [ ] A time-of-day window (a party currently lasts the whole day)
- [ ] Guests who react to your #DEX, badges or trophies

## Placement (landed with M7, fixes every mod that spawns an NPC)

- [x] `showa_core` 0.3.0 `core.placement`: ring search that vetoes unwalkable, occupied and already-claimed cells — 2026-08-17
- [x] Fixed: party guests and rivals stood **on the shelves** — the spawn search only checked for other NPCs, never walkability — 2026-08-17

## Dev tooling

- [x] `showa_devkit`: START-menu test kit — warp to any venue, open any cabinet, stock the wallet, drive the derby and the rally, run the rival simulation, diagnostic page — 2026-08-17
- [x] `showa_devkit` 0.1.1: CUPS page (enter a cup, win or lose your match, arm the referee, withdraw); fixed a crash on the B button — 2026-08-17
- [x] `showa_devkit` 0.1.2: PARTIES page (walk into today's party, read the guest list, swap an item, trade a mon) — 2026-08-17

## Later phases (backlog, not scheduled)

- [x] The full cast of twenty rivals — one data file each, all homed on verified venue cells — 2026-08-17
- [ ] Safari zone
- [ ] More arcade games: Hoppip jump, Slowpoke fishing, poke pinball, Munchlax pac-man vs Gastlys, Lickitung conveyor sushi, guitar hero, Rapidash derby, Ekans snake variants
- [ ] Gatcha pool expansions (Pokémon prizes)
- [ ] `showa_setting` era overhaul (signage/text/flavor: 70s–90s Japan)
- [ ] Tile-level rival pathing upgrade (replaces venue-edge traversal)
- [ ] Fish Catching Contest expansion: town-wide festival events
