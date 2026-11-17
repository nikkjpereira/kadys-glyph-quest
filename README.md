# Kady's Glyph Quest

**v0.6.0: Living Worlds Edition** · Godot 4.7.2 · Android · Offline

A gemstone-and-glyph match-3 adventure with four themed worlds: Runes, Egypt, East Asia, and Mixed. The public game title is provisional.

## New in v0.6

- **Dense finite Quest puzzles:** 48 board layouts with 57–60 gems each, no automatic refills, sparse blockers, and a known booster-free clearing solution for every level. A known 18–19-swap solution is **not** a proof that no shorter solution exists. The generator also runs randomized shortcut probes.
- **Animated world mechanics:** cracked stones, single-hit locks, frozen gems, and two-hit rune chains. The rules engine applies adjacent damage, gravity, and Undo state consistently.
- **Living visual effects:** glossy gems with subtle independent shimmer, violet-white match bursts, gold particles, animated swaps/gravity, and enhanced environmental lighting. Reduce Motion and Low Effects options are available.
- **Relic Collection:** four collectible relics per world (16 total); completing world milestones unlocks them. World Restoration visually brightens scenery as progression advances.
- **Five distinct looping tracks**, one for the menu and one per world, plus original stone/lock/combo/landing/relic sound effects.
- **Phone and tablet support in one APK:** phone portrait, optimized tablet portrait, and a separate landscape board-and-sidebar layout. Layout changes do not change puzzle state.
- **Saving:** offline progress, preferences, gems, obstacle types, stars, and collection state. Incompatible old active boards are restarted while completed level records remain available.

## Installation and release

The [GitHub Releases](https://github.com/nikkjpereira/kadys-glyph-quest/releases) page distributes **standalone Android APKs only**, not ZIP archives. The optional side-by-side preview has a separate package ID, so it can install without removing an older testing build. Its save data is independent.

**Important:** Existing experimental versions used different temporary debug signing identities. The normal v0.6 APK may not update an older debug build in place. Do not uninstall an older build if you need its unsynced local progress. Persistent production signing must be configured before Google Play distribution.

There are **no active ads, in-app purchases, trackers, or online accounts** in this test version.

## Architecture

- `scripts/main.gd` — gameplay state, rendering, touch/keyboard controls, animations, sound and responsive presentation.
- `scripts/quest_rules.gd` — deterministic gravity, matching, obstacle/lock interactions and proof replay.
- `scripts/save_data.gd` — offline save schema with legacy migration, collectibles, settings and restoration.
- `data/levels_v06.json` and `tools/make_levels_v06.py` — 48 puzzle definitions, known clearing sequences and generation/shortcut probes.
- `assets/v06/` and `tools/make_art_v06.py` — relic medallions, murals and artwork.
- `assets/audio/worlds/` — four world tracks plus title soundtrack.
- `assets/audio/v06/` and `tools/make_sfx_v06.py` — synthesized original feedback sounds.
- `tests/smoke.gd` — core gameplay verification.
- `tools/capture.gd`, `tools/capture_tablets.gd` — screenshots of actual Godot renders.
- `.github/workflows/android.yml` — import, gameplay checks, portrait/tablet visual QA, signed debug APK verification and Android 16 emulator installation.

## Quality criteria

Each world must be playable without purchasing boosters; all 48 levels must have at least one independently replayed booster-free clearing certificate. Screens must be verified against the original fantasy render at portrait and landscape aspect ratios. Physical Android playtesting, audio checks, battery/performance profiling and accessibility review are still required before considering it production-ready.

For the approved v0.6 scope and release definition, see [the release plan](docs/v0.6.0-release-plan.md).

Original code and generated assets are in this repository; third-party Noto fonts retain their own SIL Open Font License 1.1 notices.
