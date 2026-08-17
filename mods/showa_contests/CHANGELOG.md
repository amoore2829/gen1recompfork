# Changelog

All notable changes to this mod are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-08-17

### Added

- Seaking Derby judge on the Lake of Rage south shore (runtime-object
  seam; verb dispatches through Gold's VM).
- `framework/judging.lua`: deterministic centimeter measurement from a
  mon's level and DVs, with the SEAKING derby bonus.
- `framework/session.lua`: pure sitting state machine — start, record,
  finish against a competitor field, sorted standings.
- `pokemon.caught` measures every catch made during a sitting.
- Persistent fish and bug record book; results and new records post to
  the town news feed.
- Bug Contest wrap: `bug_contest.scored` from Gold's own contest lands
  in the same record book.
- `records`, `isSessionActive`, and `registerCompetitor` exports (the
  rival integration seam).
- Suites: 76 pure rules checks, 11 headless gen-2 loader checks, and a
  12-check end-to-end Gold driver.
