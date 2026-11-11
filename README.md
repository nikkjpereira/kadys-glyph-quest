# Kady's Glyph Quest
**Version 0.2.0 — Storybook Edition**

An offline 2D match-3 puzzle adventure for Android, built in Godot 4.7.2 / GDScript. Name and brand are provisional. The Android application ID remains `com.nefariousmedia.kadysglyphquest` for update continuity.

## Install v0.2.0

Download the APK from [Releases](https://github.com/nikkjpereira/kadys-glyph-quest/releases). Install via Android Files (not a split-APK installer). The GitHub Actions [APK build](https://github.com/nikkjpereira/kadys-glyph-quest/actions/workflows/android.yml) signs with **v1, v2 and v3** and verifies certificates and archive alignment.

**Debug signing warning:** CI uses a newly generated debug key per build. Debug builds from different runs cannot be installed on top of each other. If Android says "App not installed", uninstall the older debug build first. This removes local progress. A stable, secure signing identity is required before distributing updates to testers or shipping on Google Play.

## New in 0.2.0

- Storybook fantasy backgrounds with stone architecture, windows, lighting, lanterns, a library, and jewel tile art (generated assets).
- Logo and decorative HUD, parchment objectives, gold level ribbons, jewel boards, effects and animated particles.
- 8×8 board; four worlds: Runes, Egypt, East Asia, and Mixed.
- 12 levels per world, 48 levels total, with progressively changing scores/move limits.
- Two objective types: collect a particular glyph or reach a target score.
- Correct win and loss screens, replay, next level, level selection and a pause menu.
- Offline autosaved progress after every valid move; saving stars, unlocked levels, high scores, settings and the resumable current board.
- Settings: music, sound effects, vibration, reduce motion, high-contrast gems, automatic hints, large text, reset progress.
- Three free test boosters: hints, shuffles, and hammer. No purchases or ad watching required.
- First-play tutorial; progress summary.
- Scalable portrait UI and richer effects.
- Lightweight ambient sound and SFX generated in-code.

### How to play

Select a world, tap Begin Adventure, and swap adjoining gems to match at least three identical glyphs. Follow the goal above the board and finish before running out of moves. Press pause to save and exit. Next time choose Continue Adventure. Win to earn 1–3 stars and unlock the next level.

## Files

- `scripts/main.gd`: game drawing, menu/levels/settings, touch, sound, boosters, match-3, outcomes.
- `scripts/save_data.gd`: offline JSON saving using atomic temporary file rename.
- `scripts/brand_config.gd`: provisional name, package ID, monetization feature flags and future product concepts.
- `tools/make_art.py`: reproducibly generates PNG art and WAV sounds using Pillow and standard Python.
- `tools/prepare_assets.py`: downloads OFL Noto fonts and launcher icon.
- `tests/smoke.gd`: smoke tests for 8×8 boards, playable moves, score, save, victory, failure.
- `.github/workflows/android.yml`: automated Android APK build, signing verification and artifact publishing.

Generate assets with Python 3 + Pillow:

    python3 tools/make_art.py
    python3 tools/prepare_assets.py

Run the game locally with Godot 4.7.2 and the project file `project.godot`.

## Future monetization design (NOT ENABLED)

v0.2.0 intentionally contains no ad SDK, billing SDK, trackers, store products, or paywalls. Ads and purchases must be implemented through independently testable Android/Google Play adapters. Do not simulate an ad view or a purchase by granting permanent entitlements before Play Billing verification.

Recommended model:
- Opt-in rewarded ads for limited booster rewards, never during an active swipe or forced after level failure.
- A non-consumable "Remove Ads" in-app purchase, and optional cosmetic themes.
- Consumable booster packs only with transparent pricing, a no-purchase route, and balanced gameplay.
- Local entitlement cache plus Play Billing purchase acknowledgement, restoration and server-side verification for financial security if used.
- Consent/age-appropriate ads and child-directed/families policies addressed BEFORE production. The audience includes younger players, so examine Google Play Families and applicable children's privacy requirements carefully.
- Branding can be changed by updating art generation, app label and Store listing without changing the immutable Android application ID.

Keep all current features offline; adding monetization must not make bought items necessary to progress.

## License
Original code: MIT. Generated artwork/sounds: MIT alongside source. Unicode symbols are examples of real writing systems, not reading lessons. Bundled Noto Sans Runic, Egyptian Hieroglyphs, JP and KR fonts belong to their respective copyright holders and are licensed under SIL Open Font License 1.1; license copies download with the fonts.
