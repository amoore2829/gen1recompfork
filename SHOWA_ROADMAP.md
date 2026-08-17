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
- [ ] FEATURES.md rows (fold into suite polish)
- [ ] DDR as arcade game 2 (moved to M5 as planned)

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

- [ ] Olivine shopping street mall (new maps, ≤7×6 blocks/floor, NPCs y≥4, render-verified)
- [ ] Goldenrod Underground ↔ Olivine tunnel maps + warps
- [ ] Sticker rally clerks (spawnNpc + verb rows) + purchase tracking
- [ ] `ShowaStickerAlbum` screen + set-completion rewards
- [ ] `stickerCount`/`hasSticker` exports
- [ ] Tunnel roundtrip + sticker rally drivers
- [ ] validate/gen2check clean; FEATURES.md row

## M4 — showa_rivals

- [ ] `sim/` pure framework: advance, goals, growth, personality (seeded, deterministic; 1000-tick soak test)
- [ ] Venue-graph scheduled appearances (no tile pathing in v1)
- [ ] Rival battle seam: trainer class per rival + `trainer.party` substitution
- [ ] Rival 1: Elm (Togepi; New Bark lab / Ruins of Alph; story rival)
- [ ] Rival 2: Pichu arcade rat (arcade score integration)
- [ ] Rival 3: Azurill fishing prodigy (fish derby competitor)
- [ ] News feed integration; `rival_dex` screen off START menu
- [ ] Appearance + battle drivers
- [ ] validate/gen2check clean; FEATURES.md row

## M5 — Polish pass

- [ ] Ditto-Ditto-Revolution (DDR) as arcade game 2 (original chiptune)
- [ ] Honest `mod.card` known-limitations ledgers, READMEs, CHANGELOGs across the suite
- [ ] FEATURES.md table current; probe re-run recorded

## Later phases (backlog, not scheduled)

- [ ] Remaining ~17 rivals (one data file each): Cleffa, Igglybuff, Tyrogue ×3, Smoochum, Elekid, Magby, Wynaut, Budew*, Chingling*, Bonsly*, Mime Jr.*, Happiny*, Munchlax*, Riolu*, Mantyke* (* = Gen 4 species need `pokemon` registry additions or stand-ins)
- [ ] Tournaments
- [ ] Animal-Jam-style parties (battles, rare trades, "looking for item X" exchanges)
- [ ] Safari zone
- [ ] More arcade games: Hoppip jump, Slowpoke fishing, poke pinball, Munchlax pac-man vs Gastlys, Lickitung conveyor sushi, guitar hero, Rapidash derby, Ekans snake variants
- [ ] Gatcha pool expansions (Pokémon prizes)
- [ ] `showa_setting` era overhaul (signage/text/flavor: 70s–90s Japan)
- [ ] Tile-level rival pathing upgrade (replaces venue-edge traversal)
- [ ] Fish Catching Contest expansion: town-wide festival events
