# Kady's Glyph Quest v0.5.0 — Gemstorm Edition

**Android prerelease, Godot 4.7.2.** The public title remains provisional. Ads and in-app purchases remain disabled.

## What's new

- 48 finite puzzles with constructive, booster-free clearing solutions of 9–19 moves. These are *certified solution paths*, not proven shortest solutions.
- Sparse blockers, cracked stones that break near matches, and locked gems that release on neighboring matches.
- No automatic gem replenishment in Quest Mode. All gems must be cleared to win; an exhausted board with remaining gems is a failed round. Move efficiency and booster use determine stars.
- Refined HUD inspired by the original screenshot: illustrated logo, tighter status panels, parchment objectives, a thinner blue-stone board frame, and blue-and-gold booster buttons.
- Purple match glows, expanding rings, golden sparkle trails, animated combo-point popups, falling gems, cracking stones, and unlocking effects. The Reduce Motion setting remains supported.
- Five original loopable instrumental themes: Menu, Runes, Egypt, East Asia, and Mixed, with transitions and independent volume settings.
- Existing completed levels and settings are preserved where possible, but old in-progress layouts must be restarted under the new puzzle rules.

## Test release

**Publish standalone debug APKs only, no ZIP.** The side-by-side preview uses a separate Android package ID, allowing testing without uninstalling an earlier version. Saves are independent. The standard application may not update earlier debug builds because the temporary signing certificate changes between builds.

Automated QA checks all 48 puzzle clearing paths, no-refill behavior, obstacles, Undo, Arcade Mode, saved settings, Android signing, and emulator installation. It also captures screenshots from the actual Godot game. Hardware installation, gameplay feel and audio playback still require testing.

## Source files

- `scripts/quest_rules.gd`: puzzle physics, locks, cracked obstacles, and solution verification.
- `data/levels_v05.json` and `tools/make_levels_v05.py`: 48 deterministic levels and known full-clearing paths.
- `scripts/main.gd`: gameplay, HUD, effects, input, and music transitions.
- `assets/v05/` and `tools/make_art_v05.py`: artwork and asset generator.
- `assets/audio/worlds/` and `tools/make_world_audio_v05.py`: world music and procedural composition script.
- `tests/smoke.gd`: automated gameplay regression checks.

Older implementation history is available in Git history and previous tags.
