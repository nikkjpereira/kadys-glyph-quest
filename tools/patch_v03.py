#!/usr/bin/env python3
"""Apply v0.3 art-first presentation changes to the existing Godot project."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
p=R/'scripts/main.gd';s=p.read_text()
assert s.count('func _background()')==1 and s.count('func _input(')==1
ui=(R/'tools/ui_v03_body.gdpart').read_text()
ui=ui.replace('rect.translated(Vector2(0, 8))','Rect2(rect.position + Vector2(0, 8), rect.size)')
ui=ui.replace('"KADY\'S",x+w*0.50','Brand.TITLE_LINE_1,x+w*0.50')
ui=ui.replace('"GLYPH QUEST",x+w*0.50','Brand.TITLE_LINE_2,x+w*0.50')
s=s[:s.index('func _background()')]+ui+s[s.index('func _input('):]
s=s.replace('const SaveData = preload("res://scripts/save_data.gd")','const SaveData = preload("res://scripts/save_data.gd")\nconst Brand = preload("res://scripts/brand_config.gd")',1)
s=s.replace('var ui_font: Font\n','var ui_font: Font\nvar display_font: Font\nvar art: Dictionary = {}\nvar render_tick := -1\n',1)
s=s.replace('    ui_font = ThemeDB.fallback_font','    ui_font = ThemeDB.fallback_font\n    display_font = load("res://assets/fonts/DejaVuSerif-Bold.ttf") as Font\n    if display_font == null:\n        display_font = ui_font',1)
s=s.replace('''    for i in range(6):
        gems.append(load("res://assets/art/gem_%s.png" % i) as Texture2D)
    for item in ["runes", "egypt", "asia", "mixed"]:
        backgrounds.append(load("res://assets/art/bg_%s.png" % item) as Texture2D)
    scene_bg = load("res://assets/art/storybook.png") as Texture2D
    logo = load("res://assets/art/logo.png") as Texture2D''','''    for i in range(6):
        gems.append(load("res://assets/v03/gem_%s.png" % i) as Texture2D)
    for item in ["runes", "egypt", "asia", "mixed"]:
        backgrounds.append(load("res://assets/v03/%s_scene.png" % item) as Texture2D)
    scene_bg = load("res://assets/v03/menu_scene.png") as Texture2D
    for item in ["title", "button", "ribbon", "parchment", "medallion", "spark"]:
        var file_name := "hud_medallion" if item == "medallion" else ("title_plaque" if item == "title" else ("button_plaque" if item == "button" else ("magic_spark" if item == "spark" else item)))
        art[item] = load("res://assets/v03/" + file_name + ".png") as Texture2D
    art["board_frame"] = load("res://assets/v03/board_gold_frame.png") as Texture2D
    for i in range(4):
        art["world_%d" % i] = load("res://assets/v03/world_%d.png" % i) as Texture2D
    for i in range(3):
        art["booster_%d" % i] = load("res://assets/v03/booster_%d.png" % i) as Texture2D''',1)
s=s.replace('''    var ambience := load("res://assets/audio/ambient.wav")
    if ambience is AudioStreamWAV:
        ambience.loop_mode = AudioStreamWAV.LOOP_FORWARD
    music_player.stream = ambience
    music_player.volume_db = -16''','''    var ambience := load("res://assets/audio/enchanted_library.ogg")
    if ambience is AudioStreamOggVorbis:
        ambience.loop = true
    music_player.stream = ambience
    music_player.volume_db = -4''',1)
# Refresh effects periodically without redrawing at an unbounded frame rate.
s=s.replace('    clock += delta\n','''    clock += delta
    var tick := int(clock * 17.0)
    if tick != render_tick:
        render_tick = tick
        queue_redraw()
''',1)
s=s.replace('''    var pref_keys := ["music","sfx","haptics","reduce_motion","color_assist","auto_hints","large_text"]
    for idx in range(pref_keys.size()):
        if _inside(p,74,345+idx*101-11,558,72):
            save.toggle_pref(pref_keys[idx])
            _music_state()
            return
    if _inside(p,79,1070,559,77):''','''    var pref_keys := ["music","sfx","haptics","reduce_motion","color_assist","auto_hints","large_text"]
    for idx in range(pref_keys.size()):
        if _inside(p,74,341+idx*82-10,558,71):
            save.toggle_pref(pref_keys[idx])
            _music_state()
            return
    for i in range(2):
        var yy := 944 + i * 74
        if _inside(p,277,yy-39,373,58):
            var volume := clampi(int(round((p.x-300) / 292.0 * 100.0 / 10.0) * 10),0,100)
            save.set_int("music_volume" if i==0 else "sfx_volume",volume)
            _music_state()
            return
    if _inside(p,79,1107,559,73):''',1)
# Retain audio on/off settings but make the soundtrack genuinely audible.
s=s.replace('''func _play_sound(name: String) -> void:
    if save.pref("sfx") and sound_players.has(name):
        var player: AudioStreamPlayer=sound_players[name]
        player.play()

func _music_state() -> void:
    if music_player==null:
        return
    if save.pref("music"):
        if not music_player.playing:
            music_player.play()
    elif music_player.playing:
        music_player.stop()''','''func _play_sound(name: String) -> void:
    if save.pref("sfx") and sound_players.has(name):
        var player: AudioStreamPlayer = sound_players[name]
        player.volume_db = linear_to_db(maxf(0.001,float(save.setting_int("sfx_volume",85))/100.0)) - 2.0
        player.play()

func _music_state() -> void:
    if music_player == null:
        return
    var level_linear := maxf(0.001,float(save.setting_int("music_volume",85))/100.0)
    music_player.volume_db = linear_to_db(level_linear) - 2.0
    if save.pref("music") and save.setting_int("music_volume",85)>0:
        if not music_player.playing:
            music_player.play()
    elif music_player.playing:
        music_player.stop()''',1)
assert 'res://assets/audio/enchanted_library.ogg' in s
assert 'save.set_int' in s
p.write_text(s)

p=R/'scripts/save_data.gd';s=p.read_text()
s=s.replace('    "large_text": false\n','    "large_text": false,\n    "music_volume": 85,\n    "sfx_volume": 85\n',1)
anchor='func unlocked_level(world: int) -> int:\n'
assert anchor in s
s=s.replace(anchor,'''func setting_int(name: String, fallback: int = 85) -> int:
    return clampi(int(data["prefs"].get(name, fallback)), 0, 100)

func set_int(name: String, value: int) -> void:
    if name in ["music_volume", "sfx_volume"]:
        data["prefs"][name] = clampi(value, 0, 100)
        save_all()

'''+anchor,1)
p.write_text(s)

p=R/'scripts/brand_config.gd';s=p.read_text();s=s.replace('const VERSION := "0.2.0"','const VERSION := "0.3.0"').replace('const DISPLAY_NAME := "Kady\'s Glyph Quest"','const DISPLAY_NAME := "Kady\'s Glyph Quest"\nconst TITLE_LINE_1 := "KADY\'S"\nconst TITLE_LINE_2 := "GLYPH QUEST"')
p.write_text(s)

p=R/'export_presets.cfg';s=p.read_text();s=s.replace('v0.2.0-debug.apk','v0.3.0-debug.apk').replace('version/code=3','version/code=4').replace('version/name="0.2.0"','version/name="0.3.0"').replace('res://assets/icon.png','res://assets/v03/app_icon.png');p.write_text(s)

p=R/'.github/workflows/android.yml';s=p.read_text();s=s.replace('v0.2.0','v0.3.0');s=s.replace('        continue-on-error: true\n','',1)
anchor='      - name: Make APK available to testers\n'
assert anchor in s
step='''      - name: Enable KVM for Android emulator
        run: |
          echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
          sudo udevadm control --reload-rules
          sudo udevadm trigger --name-match=kvm

      - name: Verify APK installs on a fresh Android 16 emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 36
          target: google_apis
          arch: x86_64
          profile: pixel_7_pro
          ram-size: 3072M
          disk-size: 4096M
          emulator-boot-timeout: 900
          emulator-options: -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim
          script: |
            adb install --no-incremental build/kadys-glyph-quest-v0.3.0-debug.apk
            adb shell pm path com.nefariousmedia.kadysglyphquest

'''
s=s.replace(anchor,step+anchor,1)
p.write_text(s)

p=R/'tests/smoke.gd';s=p.read_text();needle='''    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)'''
assert needle in s
s=s.replace(needle,'''    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    if not ResourceLoader.exists("res://assets/v03/board_gold_frame.png"):
        push_error("v0.3 render artwork missing")
        quit(1)
        return
    if not ResourceLoader.exists("res://assets/audio/enchanted_library.ogg"):
        push_error("v0.3 audible music missing")
        quit(1)
        return
    if game.music_player == null or game.music_player.stream == null:
        push_error("v0.3 soundtrack not assigned")
        quit(1)
        return
    game.save.set_int("music_volume",70)
    game.save.set_int("sfx_volume",40)
    if game.save.setting_int("music_volume") != 70 or game.save.setting_int("sfx_volume") != 40:
        push_error("Volume settings are not persisted")
        quit(1)
        return''',1)
p.write_text(s)

p=R/'README.md';s=p.read_text();s=s.replace('**Version 0.2.0 — Storybook Edition**','**Version 0.3.0 — Render Art Edition**').replace('v0.2.0','v0.3.0')
s='''# Kady's Glyph Quest v0.3.0 — Render Art Edition

This release rebuilds the Godot presentation around the original polished fantasy render. The working 48-level offline matching game, progress storage, settings, and world system from v0.2 are retained.

**New visual system**
- New illustrated backgrounds derived from the original visual concept and separately generated fantasy artwork.
- New octagonal gemstone sprites cleaned for dynamic Unicode glyph overlays, never a static board screenshot.
- Original-style carved blue-stone and ornate gold board frame, parchment objectives, gold ribbon and gemstone HUD medallions.
- Painted world previews, glossy booster artwork and a dynamically titled logo (for future renaming).
- Better glow, particle sprites, effects, and illustrated settings/level/result screens.
- Original 44-second looping enchanted-library soundtrack with separate music and effects volume controls.
- New app launcher icon and display font.

**Source**: `scripts/main.gd`, `scripts/save_data.gd`, `assets/v03/`, `assets/audio/enchanted_library.ogg`.

**Testing**: GitHub Actions imports and checks Godot scripts, executes match-3/saving/soundtrack smoke tests, captures real Godot screenshots, builds and verifies the APK's v1-v3 signatures, and installs it on a clean Android 16 emulator.

**Installation**: Get the **verified ZIP** from the v0.3 GitHub release, extract its APK, then install using Android Files. Older debug builds use different ephemeral signing keys and cannot be updated in place. Uninstalling an old test APK will erase its local save. A permanent test signing key and export/import save workflow are needed before public tester rollout.

**Monetization**: Ads and in-app purchases remain disabled; the architecture preserves a dedicated brand/config file and future reserved product IDs. The game may target younger players, so child-directed ad and purchase compliance needs review before a store launch.

**Artwork licensing**: Concept-derived and AI-generated graphics are included in the project for use with this game. The included DejaVu Serif font retains its original open-source license; Unicode Noto fonts retain their SIL OFL license. See existing license documentation.

---

'''+s
p.write_text(s)

print('v0.3 patch complete:',len((R/'scripts/main.gd').read_text()),'chars in main.gd')
