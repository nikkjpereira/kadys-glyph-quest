#!/usr/bin/env python3
"""Apply the v0.4 overhaul deterministically to the v0.3 base."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
MAIN=ROOT/"scripts/main.gd"
src=MAIN.read_text()
if 'const QuestRules = preload("res://scripts/quest_rules.gd")' in src:
    print("Already applied");raise SystemExit(0)
def replace_once(old,new):
    global src
    if src.count(old)!=1:
        raise RuntimeError(f"Expected one occurrence of {old[:80]!r}, found {src.count(old)}")
    src=src.replace(old,new,1)
def replace_func(name,block):
    global src
    m=re.search(r'(?m)^func '+re.escape(name)+r'\(',src)
    if not m:
        src += "\n\n" + block.rstrip() + "\n"
        return
    end=re.search(r'(?m)^func ',src[m.end():])
    e=m.end()+end.start() if end else len(src)
    src=src[:m.start()]+block.rstrip()+"\n\n"+src[e:]
def patches_from(name):
    data=(ROOT/"tools"/name).read_text()
    chunks=re.split(r'(?=^func [A-Za-z_]\w*\()',data,flags=re.M)
    for chunk in chunks:
        if not chunk.strip():continue
        m=re.match(r'func ([A-Za-z_]\w*)\(',chunk)
        if not m:raise RuntimeError("Bad patch block "+chunk[:60])
        replace_func(m.group(1),chunk)
    print("Replaced methods from",name)
replace_once('const Brand = preload("res://scripts/brand_config.gd")',
             'const Brand = preload("res://scripts/brand_config.gd")\nconst QuestRules = preload("res://scripts/quest_rules.gd")')
replace_once('const CELL := 78.0','const CELL := 72.0')
replace_once('const ORIGIN := Vector2(47, 481)','const ORIGIN := Vector2(72, 514)')
replace_once('var world_index := 0','var world_index := 0\nvar mode := "quest"\nvar start_gems := 0\nvar moves_used := 0\nvar undo_left := 3\nvar undo_history: Array[Dictionary] = []\nvar fall_ghosts: Array[Dictionary] = []\nvar fall_age := 1.0')
replace_once('    save.load_all()\n    ui_font',
             '    save.load_all()\n    mode = str(save.data.get("mode", "quest"))\n    if mode not in ["quest", "arcade"]:\n        mode = "quest"\n    ui_font')
replace_once('    for item in ["tap", "match", "win", "fail"]:',
             '    art["undo"] = load("res://assets/v04/undo.png") as Texture2D\n    art["stone"] = load("res://assets/v04/stone.png") as Texture2D\n    for item in ["tap", "match", "win", "fail"]:')
replace_once('    clock += delta\n    var tick',
             '    clock += delta\n    if fall_age < 1.0:\n        fall_age += delta\n        if fall_age >= 0.35:\n            fall_ghosts.clear()\n        queue_redraw()\n    var tick')
replace_once('                save.mark_tutorial()\n                state="playing"',
             '                save.data["tutorial_done_v04"] = true\n                save.mark_tutorial()\n                state="playing"')
replace_once('            if _inside(p,122,800,476,80):','            if _inside(p,122,840,476,76):')
replace_once('    _button(Rect2(116,843,488,78),"SAVE AND EXIT")',
             '    _button(Rect2(116,843,488,78),"SAVE & HOME")')
replace_once('    _label("NO LOGIN. YOUR ADVENTURE SAVES OFFLINE.",360,1163,18,CREAM,true)',
             '    _label("ARCADE BEST: %s" % int(save.data.get("arcade_best", 0)),360,1158,22,GOLD,true)\n    _label("NO LOGIN. YOUR ADVENTURE SAVES OFFLINE.",360,1204,17,CREAM,true)')
patches_from("v04_logic.gdpart")
patches_from("v04_ui.gdpart")
MAIN.write_text(src)
print("Updated game",MAIN,len(src))
savefile=ROOT/"scripts/save_data.gd"
s=savefile.read_text().replace('        "schema": 2,\n', '        "schema": 2,\n        "mode": "quest",\n        "arcade_best": 0,\n        "tutorial_done_v04": false,\n',1)
savefile.write_text(s)
brand=ROOT/"scripts/brand_config.gd"
s=brand.read_text().replace('const VERSION := "0.3.0"','const VERSION := "0.4.0"')
brand.write_text(s)
preset=ROOT/"export_presets.cfg"
s=preset.read_text().replace("v0.3.0-debug.apk","v0.4.0-debug.apk").replace("version/code=4","version/code=5").replace('version/name="0.3.0"','version/name="0.4.0"')
preset.write_text(s)
print("Updated save, metadata, and export preset.")
