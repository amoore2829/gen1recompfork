# Changelog

All notable changes to this mod are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-08-17

### Added

- A SHOWA DEV row on the START menu opening a paged test kit.
- Warp to any venue in the graph; open any arcade cabinet directly;
  stock tokens, money and mall points; open, catch in, and settle a
  derby; stamp every rally counter; run the rival simulation forward,
  call the whole cast to where you are, or warp to any rival.
- A diagnostic page reporting which suite mods are installed, how many
  venues the graph holds, and how big the cast is.
- `menu.lua` is pure data, so the whole tree — including the branches
  that only appear when a feature mod is installed, and the column
  widths — is tested without a boot.
- Suites: 96 menu checks and an 18-check Gold driver.

## 0.1.1 — 2026-08-17

- New **CUPS** page: enter any tournament cup, settle your own match either
  way, arm the referee, or withdraw. Hidden when `showa_tournaments` is not
  installed, like every other feature page.
- Fixed a crash on the B button: `ListMenu`'s `onCancel` takes no arguments
  and runs after the menu has already popped itself, so the kit's second
  `menu:close()` indexed nil.
