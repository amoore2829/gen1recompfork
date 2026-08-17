# Changelog

All notable changes to this mod are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-08-17

### Added

- `lib/wallet.lua`: multi-currency ledger (define/get/add/spend, clamped,
  all-or-nothing spends).
- `lib/clock.lua`: mirror of Gold's clock fed by `clock.day_changed`,
  `world.tod_changed`, and the `world.tod` hook pass-through.
- `lib/scheduler.lua`: day/tod opening-hours specs.
- `lib/news.lua`: capped append-only world news feed.
- `lib/venues.lua`: the venue graph the rival simulation walks.
- `lib/minigame.lua`: arcade cabinet screen scaffold (fixed tick, pause,
  results card, score handoff).
- `ShowaNews` screen behind a NEWS row on the START menu.
- Full export surface: `wallet`, `clock`, `scheduler`, `news`, `venues`,
  `minigame`.
- Pure-lib suite (40 checks) + headless gen-2 loader suite (13 checks).
