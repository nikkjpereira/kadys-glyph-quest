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
        "schema": 4,
        "mode": "quest",
        "arcade_best": 0,
        "tutorial_done_v04": false,
        "levels": {},
        "relics": {},
        "relic_seen": {},
        "pending_rewards": [],
        "achievements": {},
        "achievement_seen": {},
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
    if int(parsed.get("schema", 0)) not in [2,3,4]:
        return
    var incoming: Dictionary = parsed
    for key in data.keys():
        if incoming.has(key):
            data[key] = incoming[key]
    # Completed stars, unlocks and settings migrate; obsolete in-progress
    # boards are re-created when the player starts v0.6.
    data["schema"]=4
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
    if typeof(data["relic_seen"])!=TYPE_DICTIONARY:data["relic_seen"]={}
    if typeof(data["achievements"])!=TYPE_DICTIONARY:data["achievements"]={}
    if typeof(data["achievement_seen"])!=TYPE_DICTIONARY:data["achievement_seen"]={}
    if typeof(data["pending_rewards"])!=TYPE_ARRAY:data["pending_rewards"]=[]
    if typeof(data["restoration"])!=TYPE_ARRAY or data["restoration"].size()!=4:
        data["restoration"]=[0,0,0,0]
    for w in range(4):
        for k in range(4):
            if int(best_result(w,(k+1)*3).get("stars",0))>0:
                data["relics"]["%s-%s" % [w,k]]=true
        var stage:=0
        for k in range(4):
            if bool(data["relics"].get("%s-%s" % [w,k],false)):
                stage=k+1
        data["restoration"][w]=maxi(int(data["restoration"][w]),stage)

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
    # Relics unlock at levels 3, 6, 9 and 12 (not just any three wins).
    if level in [3,6,9,12]:
        var slot:=int(level/3)-1
        var relic_key: String="%s-%s" % [world,slot]
        var first_unlock: bool=not bool(data["relics"].get(relic_key,false))
        data["relics"][relic_key]=true
        data["restoration"][world]=maxi(int(data["restoration"][world]),slot+1)
        if first_unlock:
            data["pending_rewards"].append({"kind":"relic","world":world,"slot":slot,"key":relic_key})
    unlock_achievement("first_victory",false)
    if stars==3:unlock_achievement("perfect_clear",false)
    if relic_total()>=1:unlock_achievement("first_relic",false)
    if world_stage(world)==4:unlock_achievement("restored_world",false)
    if completion_count()>=10:unlock_achievement("ten_quests",false)
    var explored:int=0
    for w in range(4):
        for check_level in range(1,13):
            if int(best_result(w,check_level).get("stars",0))>0:
                explored+=1
                break
    if explored>=4:unlock_achievement("all_worlds",false)
    data["total_stars"] = total_stars()
    data["current"] = {}
    save_all()

func next_relic_reward() -> Dictionary:
    for event in data.get("pending_rewards",[]):
        if typeof(event)==TYPE_DICTIONARY and str(event.get("kind",""))=="relic":
            return event.duplicate(true)
    return {}

func acknowledge_relic(world:int,slot:int) -> void:
    var key: String="%s-%s" % [world,slot]
    data["relic_seen"][key]=true
    var remaining: Array=[]
    for item in data.get("pending_rewards",[]):
        if typeof(item)==TYPE_DICTIONARY and str(item.get("key",""))==key and str(item.get("kind",""))=="relic":
            continue
        remaining.append(item)
    data["pending_rewards"]=remaining
    save_all()

func relic_is_new(world:int,slot:int) -> bool:
    return has_relic(world,slot) and not bool(data.get("relic_seen",{}).get("%s-%s" % [world,slot],false))

func unseen_relic_count()->int:
    var count:=0
    for world in range(4):
        for slot in range(4):
            if relic_is_new(world,slot):count+=1
    return count

func unlock_achievement(id:String,persist:bool=true)->bool:
    if bool(data["achievements"].get(id,false)):return false
    data["achievements"][id]=true
    if persist:save_all()
    return true

func unseen_achievement_count()->int:
    var count:int=0
    for id in data.get("achievements",{}):
        if not bool(data.get("achievement_seen",{}).get(id,false)):count+=1
    return count

func mark_achievements_seen()->void:
    for id in data.get("achievements",{}):
        data["achievement_seen"][id]=true
    save_all()

func completion_count() -> int:
    return data.get("levels",{}).size()

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
