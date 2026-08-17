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

- [ ] `showa_core`: wallet, clock (wraps Gen 2 clock), scheduler, news, venues, minigame base — each pure-Lua with unit suite
- [ ] `showa_core` exports wired; save schema v1 + migration discipline
- [ ] `showa_arcade`: Goldenrod Game Corner interior patch (cabinets + gatcha NPCs)
- [ ] Ekans snake (pure `rules.lua` state machine + screen + view)
- [ ] Gatcha machine (weighted pool, capsule screen, trophy duplicate protection)
- [ ] ARCADE_TOKEN currency + counter clerk
- [ ] High-score table + `submitScore`/`highScore` exports (rival seam)
- [ ] Unit suites + arcade entry driver + scripted Ekans game driver
- [ ] validate/gen2check/lint clean; FEATURES.md row

## M2 — showa_contests

- [ ] Shared framework: `session.lua` + `judging.lua` (pure, unit-tested)
- [ ] Fish derby at Lake of Rage (judge NPC, Seaking-weighted fishing, size records, leaderboard)
- [ ] Bug Contest wrap (engine already runs it: hook `bug_contest.scored`, add leaderboard + rival competitors)
- [ ] `registerCompetitor` export seam
- [ ] Drivers: fish derby with forced Seaking; bug contest scored
- [ ] validate/gen2check clean; FEATURES.md row

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
