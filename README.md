# Runefall

**v0.7.0: Living Gems + Restored Worlds Update** · Godot 4.7.2 · Android · Offline

A gemstone-and-glyph match-3 adventure with four themed worlds: Runes, Egypt, East Asia, and Mixed. The new visual identity is **Runefall** with the tagline **Match. Discover. Awaken.**. The internal package ID is intentionally unchanged for continuity.

## Planned v0.7.5 — combined feature release

The former v0.7.2 cleanup is bundled into **v0.7.5**: relic unlock animations,
restoration feedback, cleaner Home navigation, background/tablet artwork fixes,
special gems, world maps and offline achievements. Existing saves and Android
app IDs must remain compatible. Monetization remains for v0.8.0.
See [the v0.7.5 combined implementation plan](docs/v0.7.5-combined-release-plan.md).

## New visuals in v0.7.0

- Six newly generated 256px multi-faceted gemstone materials with colored beveled edges, glass highlights and internal caustics.
- Animated crystalline refractions, gold sparkle stars, impact shockwaves, colored crystal shards and local board lighting.
- New restoration scenery for **all 4 worlds at 5 stages each** (20 atmosphere scenes), with world-specific torch/light, desert dust, falling blossoms and arcane motes.
- A more responsive movement feel with smooth falling spring easing, opt-in micro-shake, glowing threshold markers and animated victory stars.
- Existing Reduce Motion, Low Effects, Gem Shimmer, Reactive Light and Ambient Motion settings control the v0.7 effects.
- Existing levels, 75/85/100% Quest win rules, Arcade gameplay, music, relics and saved-progress schema stay unchanged.
- For technical and playtest details, see [v0.7.0 release notes](docs/v0.7.0-release-notes.md).

## Fair Quest in v0.6.2

Quest levels now pass at **75% cleared (1 star)**, award **2 stars at 85%** and **3 stars for 100%**. Qualified players can claim victory or continue. A deadlocked level at or above 75% is a win; below 75%, one free rescue is offered. Puzzle-aware hints prioritize known solutions. The new release preserves the same Android app IDs and save format as v0.6.1. **No ads or purchases are enabled.** See [v0.6.2 release notes](docs/v0.6.2-release-notes.md).

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
