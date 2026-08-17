# Changelog

All notable changes to this mod are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-08-17

### Added

- Event and hook counters over the seams the Showa suite depends on.
- Registration probes: `maps`, `trainers`, `commands`, `screens`.
- `mod.save` roundtrip check, `mod.world.spawnNpc` presence check.
- `Gen2ProbeReport` screen behind a PROBE row on the START menu.
- `report` and `spawnProbeNpc` exports for drivers and other mods.
- Headless harness suite and a Gold boot driver that talks to a spawned
  NPC through the probe's own VM verb.
