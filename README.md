# Kady's Glyph Quest

A 2D Android match-3 game for Kady, built in Godot 4.7.2 using GDScript.

## v0.1.1 features
- Four glyph worlds: Runes, Egypt, East Asia, and Mixed.
- Touch/swipe matching, score goal, 24 moves, hints, two shuffles, cascades.
- Local/offline play with no ads, accounts, or data collection.
- Real runic, hieroglyphic and East Asian Unicode glyphs rendered with open-licensed Noto fonts.

## Get the first Android APK
Go to **Actions → Build Android APK → newest successful run → Artifacts**. Download **Kady-Glyph-Quest-Android-v0.1.1**; unzip and sideload the APK.

The automatic workflow produces a debug-signed APK for testing, not a release build for Google Play.

## Local development
1. Install Godot 4.7.2 and Python 3.
2. Run `python3 tools/prepare_assets.py` to download bundled Noto fonts and create the launcher PNG.
3. Open `project.godot` in Godot, then press F5.

## Files
- `scripts/main.gd`: game logic and visuals.
- `scenes/Main.tscn`: main scene.
- `tests/smoke.gd`: board and score smoke tests.
- `.github/workflows/android.yml`: Android APK build and upload.
- `tools/prepare_assets.py`: font/icon generation.

## Licensing
Game code: MIT. Fonts: Noto Sans Runic, Noto Sans Egyptian Hieroglyphs, Noto Sans JP and Noto Sans KR, copyright the respective authors and released under SIL Open Font License 1.1. The licenses are downloaded alongside the fonts by the asset preparation script. Glyphs represent real scripts but are not educational translations.
## v0.1.1 Android installer compatibility

APK is explicitly signed using both legacy v1 (JAR) and modern v2/v3 signature schemes. The CI build verifies all three and ZIP alignment before distribution. Each CI run uses a temporary debug keystore, so subsequent APKs are **not** interchangeable as in-place updates: uninstall a prior debug test build before installing a newer version.
