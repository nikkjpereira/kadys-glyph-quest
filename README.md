# Kady's Glyph Quest

**v0.4.0 — Finite Quest + Arcade, UI Rebuild**

Offline Android puzzle game, Godot 4.7.2, GDScript. The consumer-facing name is provisional.

## What changed in v0.4.0

**Quest Mode (the default)** now uses finite, non-replenishing boards. Matching 3+ identical glyphs removes them; the gems above fall down, and *no new gems spawn*. The round ends only when the board is empty or no legal swaps remain. Clear 100% for 3 stars; clear >=85% for 2 stars, >=65% for 1 star. A round below 65% is a loss and offers retry. There is no arbitrary Quest Mode move limit.

Puzzle generation is deterministic per world+level. The current level generator creates 6-gem row gadgets whose intended sequence is mathematically solvable. A known clearing path is verified for all 48 levels by CI, so every level can be cleared without ads or payments. The stone barriers at the sides prevent moving into those cells. Additional puzzle types and difficulty ramps are future work.

**Arcade Mode** remains selectable from the main menu. It preserves the v0.3 refill-based match-3 score/collect gameplay with limited moves.

**Navigation / visual fixes:**
- Home icon on the top-left saves the current run and returns immediately.
- Small Pause icon on top-right opens Resume / Settings / Save & Home.
- Board rim now renders behind the gems with added margins; none should be clipped.
- Four clearly labeled boosters (Hint, Shuffle, Hammer, Undo) with charge counts.
- Stone walls and empty sockets have distinct visuals. Different worlds apply subtle gem tints.
- Gravity movement overlays, match sparkle effects, combo scoring.
- World card selection, level selection, achievements/progress screen and audio settings preserved.

**Boosters:**
- Hint highlights a legal swap and costs a charge.
- Shuffle rearranges *only existing gems*, preserving wall/empty positions; it does not add gems. It does not spend a charge if no playable shuffle can be found.
- Hammer removes one selected gem (no replacements in Quest).
- Undo reverts a move, plus score and booster balances, and costs one Undo charge. A short undo history is autosaved.

**Saving:** Settings, stars and unlocked levels from prior versions continue to load (same schema). The v0.3 in-progress *refill-mode board* is not reopened as a finite Quest board: on the first v0.4 continue attempt the incompatible board is discarded while completed levels and stars remain. The v0.4 preview package has a separate app ID and therefore separate saved progress by Android design.

**Sound:** Retains the v0.3 looping fantasy instrumental, sound effects, volume sliders, and accessibility settings.

## Testing

1. GitHub Actions imports the project and checks script syntax.
2. Smoke tests check all 48 curated quest layouts, proof of complete clearing, no refill, undo, no premature victory, saving, hammer behavior, and preserved Arcade refill gameplay.
3. Godot captures *actual* menu, Quest, Arcade, Settings, Pause, and Victory screenshots.
4. The signed APK is checked with Android apksigner/JAR verification and installed into a clean Android 16 emulator.
5. A verified ZIP with the signed APK and SHA-256 hash is published for hardware sideload testing. ZIP extraction has previously avoided damaged direct APK transfers.

**Important signing caveat:** v0.3 debug APKs and v0.4 debug builds are signed with different ephemeral test certificates. A v0.4 **side-by-side** preview (distinct package ID) is preferred for first testing, so v0.3 and its local progress are unaffected. Do not uninstall a prior build without backing up its data. Persistent signing is an unresolved pre-production requirement.

## World design
- Runes: Norse glyphs, enchanted stone room, blue-purple gem lighting.
- Egypt: hieroglyphs, warm sandstone and gold.
- East Asia: Han, kana and Hangul samples, jade/teal colors.
- Mixed: magical archive with a cross-script assortment.

Glyphs are visual motifs, not translations or language-learning claims. The currently available illustrations are intentionally style-guided by the concept render; runtime gameplay, controls, and text are native Godot, not pasted onto an image.

## Monetization plan (not active)
The source retains `scripts/brand_config.gd` with feature flags for a future store name, opt-in rewarded ads, an ad-removal purchase, and purely optional cosmetics/boosters. No ad SDK, payment processing, trackers, or network permissions are present in test builds. Complete store billing verification and youth/privacy policy review before enabling anything.

## Build locally

Install Godot 4.7.2 and Python 3 with Pillow.

```bash
python3 tools/prepare_assets.py
python3 tools/make_art_v04.py
godot --editor --path . --import
godot --path .
```

The main files are `scripts/main.gd` (UI/game), `scripts/quest_rules.gd` (finite puzzles), `scripts/save_data.gd` (offline save), `assets/v03` and `assets/v04` (art).

### License

Original source and generated icon art: MIT. The fonts included during asset preparation are released under their respective SIL OFL 1.1 licenses; retain those license notices.
