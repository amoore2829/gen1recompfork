# Changelog

All notable changes to this mod are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-08-17

### Added

- Token clerk, EKANS cabinet, and gatcha machine NPCs on the Goldenrod
  Game Corner floor (spawned via the Gen 2 runtime-object seam; verbs
  dispatch through Gold's VM).
- `ARCADE_TOKEN` currency in the showa_core wallet; clerk sells 10/$500.
- EKANS: seeded, fully deterministic snake rules + procedural LCD
  playfield on the showa_core minigame scaffold.
- Gatcha: weighted prize pool (8 prizes, 3 tiers), duplicate protection
  on trophies, capsule reveal screen, RARE pulls hit the news feed.
- High-score ledger with `highScore`/`submitScore` exports (the rival
  integration seam) and news posts on broken records.
- Suites: 2017 pure rules checks, 12 headless gen-2 loader checks, and an
  end-to-end Gold driver (warp, purchase, play, gatcha — 18 checks).
