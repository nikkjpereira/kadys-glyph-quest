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
    "large_text": false
}
var data: Dictionary = {}

func _init() -> void:
    reset_defaults()

func reset_defaults() -> void:
    data = {
        "schema": 2,
        "levels": {},
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
    if int(parsed.get("schema", 0)) != 2:
        return
    var incoming: Dictionary = parsed
    for key in data.keys():
        if incoming.has(key):
            data[key] = incoming[key]
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
    data["total_stars"] = total_stars()
    data["current"] = {}
    save_all()

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
