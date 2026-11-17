extends RefCounted
## Offline save store. No analytics, network calls, or SDK keys.
const PATH := "user://glyph_quest_v2.json"
const TEMP := "user://glyph_quest_v2.tmp"
const DEFAULT_PREFS := {
    "music": true,
    "sfx": true,
    "haptics": true,
    "reduce_motion": false,
    "color_assist": false,
    "auto_hints": true,
    "large_text": false,
    "music_volume": 85,
    "sfx_volume": 85,
    "ambient_motion": true,
    "gem_shimmer": true,
    "reactive_light": true,
    "screen_shake": false,
    "low_effects": false
}
var data: Dictionary = {}

func _init() -> void:
    reset_defaults()

func reset_defaults() -> void:
    data = {
        "schema": 3,
        "mode": "quest",
        "arcade_best": 0,
        "tutorial_done_v04": false,
        "levels": {},
        "relics": {},
        "restoration": [0,0,0,0],
        "tutorial_done_v06": false,
        "unlocked": [1, 1, 1, 1],
        "prefs": DEFAULT_PREFS.duplicate(true),
        "current": {},
        "tutorial_done": false,
        "lifetime_matches": 0,
        "total_stars": 0
    }

func load_all() -> void:
    reset_defaults()
    if not FileAccess.file_exists(PATH):
        return
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("Invalid save data; starting fresh")
        return
    if int(parsed.get("schema", 0)) not in [2,3]:
        return
    var incoming: Dictionary = parsed
    for key in data.keys():
        if incoming.has(key):
            data[key] = incoming[key]
    # Completed stars, unlocks and settings migrate; obsolete in-progress
    # boards are re-created when the player starts v0.6.
    data["schema"]=3
    if typeof(data["prefs"]) != TYPE_DICTIONARY:
        data["prefs"] = DEFAULT_PREFS.duplicate(true)
    for key in DEFAULT_PREFS:
        if not data["prefs"].has(key):
            data["prefs"][key] = DEFAULT_PREFS[key]
    if typeof(data["levels"]) != TYPE_DICTIONARY:
        data["levels"] = {}
    if typeof(data["current"]) != TYPE_DICTIONARY:
        data["current"] = {}
    if typeof(data["unlocked"]) != TYPE_ARRAY or data["unlocked"].size() != 4:
        data["unlocked"] = [1, 1, 1, 1]
    if typeof(data["relics"])!=TYPE_DICTIONARY:data["relics"]={}
    if typeof(data["restoration"])!=TYPE_ARRAY or data["restoration"].size()!=4:
        data["restoration"]=[0,0,0,0]
    for w in range(4):
        var completed:=0
        for lvl in range(1,13):
            if int(best_result(w,lvl).get("stars",0))>0:completed+=1
        data["restoration"][w]=maxi(int(data["restoration"][w]),mini(4,int(completed/3)))
        for k in range(int(completed/3)):
            data["relics"]["%s-%s" % [w,k]]=true

func save_all() -> bool:
    var file := FileAccess.open(TEMP, FileAccess.WRITE)
    if file == null:
        push_warning("Could not open save file: " + str(FileAccess.get_open_error()))
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    file.close()
    var temp_absolute := ProjectSettings.globalize_path(TEMP)
    var save_absolute := ProjectSettings.globalize_path(PATH)
    var result := DirAccess.rename_absolute(temp_absolute, save_absolute)
    if result != OK:
        push_warning("Could not replace saved progress: " + str(result))
        return false
    return true

func pref(name: String) -> bool:
    return bool(data["prefs"].get(name, DEFAULT_PREFS.get(name, false)))

func toggle_pref(name: String) -> void:
    if not DEFAULT_PREFS.has(name):
        return
    data["prefs"][name] = not pref(name)
    save_all()

func setting_int(name: String, fallback: int = 85) -> int:
    return clampi(int(data["prefs"].get(name, fallback)), 0, 100)

func set_int(name: String, value: int) -> void:
    if name in ["music_volume", "sfx_volume"]:
        data["prefs"][name] = clampi(value, 0, 100)
        save_all()

func unlocked_level(world: int) -> int:
    return clampi(int(data["unlocked"][world]), 1, 12)

func best_result(world: int, level: int) -> Dictionary:
    return data["levels"].get("%s-%s" % [world, level], {})

func record_victory(world: int, level: int, score: int, stars: int) -> void:
    var key := "%s-%s" % [world, level]
    var old: Dictionary = best_result(world, level)
    data["levels"][key] = {
        "score": maxi(int(old.get("score", 0)), score),
        "stars": maxi(int(old.get("stars", 0)), stars)
    }
    data["unlocked"][world] = maxi(unlocked_level(world), mini(12, level + 1))
    # Four illustrated artifact milestones per world (3, 6, 9, 12).
    var milestones := 0
    for lvl in range(1,13):
        if int(best_result(world,lvl).get("stars",0))>0:milestones+=1
    var stage:=mini(4,int(milestones/3))
    data["restoration"][world]=maxi(int(data["restoration"][world]),stage)
    for k in range(stage):
        data["relics"]["%s-%s" % [world,k]]=true
    data["total_stars"] = total_stars()
    data["current"] = {}
    save_all()

func world_stage(world:int)->int:
    return clampi(int(data.get("restoration",[0,0,0,0])[world]),0,4)

func has_relic(world:int,slot:int)->bool:
    return bool(data.get("relics",{}).get("%s-%s" % [world,slot],false))

func relic_total()->int:
    return data.get("relics",{}).size()

func total_stars() -> int:
    var sum := 0
    for entry in data["levels"].values():
        if typeof(entry) == TYPE_DICTIONARY:
            sum += int(entry.get("stars", 0))
    return sum

func set_current(current: Dictionary) -> void:
    data["current"] = current.duplicate(true)
    save_all()

func clear_current() -> void:
    data["current"] = {}
    save_all()

func mark_tutorial() -> void:
    data["tutorial_done"] = true
    save_all()

func reset_progress() -> void:
    var old_prefs: Dictionary = data["prefs"].duplicate(true)
    reset_defaults()
    data["prefs"] = old_prefs
    save_all()
