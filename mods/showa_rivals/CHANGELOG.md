# Changelog

All notable changes to this mod are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-08-17

### Added

- The full cast of twenty. Seventeen new rivals, one data file each --
  the occult nerd at the Ruins, the idol rehearsing in the park, the
  fashionista on the department store floors, the tinkerer on Route 34,
  the festival cook in Azalea, the shy kid, the gardener, the shrine
  apprentice, the prankster, the street performer, the Center helper,
  the mall foodie, the shonen protagonist, the surfer, and the Tyrogue
  triplets who each take a different evolution.
- `world/venues.lua`: fourteen Johto venues and the edges between them,
  every cell picked by scanning each map for a tile that is walkable,
  free of objects, bg events and warps, AND has a free walkable cell
  directly south so the rival standing there can always be talked to.

### Changed

- Verb dialogue goes through `core.dialogue.say`.

## [0.1.0] - 2026-08-17

### Added

- `sim/`: the rival brain as pure functions — a seeded generator carried
  in the state, a rubber-banded growth curve, and a coarse tick that
  travels the venue graph, trains, shops and catches. Soak-tested for
  1000 ticks per rival.
- Three rivals: ELM (Togepi, the story rival), SPARKS the arcade rat
  (posts real EKANS scores), and NAGISA the fishing prodigy (enters
  Seaking Derby sittings).
- Trainer classes whose battle party is substituted with the rival's
  live team through the `trainer.party` hook.
- Appearances: a rival is spawned where it stands and removed when it
  moves on, stepping aside if a venue's cell is already occupied.
- `ShowaRivalDex` screen behind a RIVALS row on the START menu.
- `roster`, `at`, `recordBattle` exports.
- Suites: 29,778 pure sim checks, 27 headless gen-2 checks (including a
  load with none of the optional dependencies present), and a 21-check
  Gold driver.

## 0.3.0 — 2026-08-17

Rivals can now be **fought**.

- Each rival's trainer class carries a numeric `index`, without which
  `loadtrainer` cannot reach it and no script can put the rival in front of
  you.
- Their live team is written into the class record rather than substituted
  through the `trainer.party` hook, so the engine's own party builder gives
  the mons the moves they know at that level. Rows handed back from the hook
  skipped `Mon.new` and arrived with an empty move list.
- Battle portraits are taken from the player's own cache table for a vanilla
  class (`core.trainers.setPic`), so a rival battle no longer opens on an
  empty plinth — and the mod ships no reference to ROM-derived art.
- New exports for other mods: `battleCard(id)` (the class, index, level and
  team to fight) and `syncParty(id, opts)` (stand the team up under a level
  cap, and put it back).
