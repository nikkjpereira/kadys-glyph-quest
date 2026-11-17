extends Node2D
## Runefall v0.6.2: responsive, finite match-3 with relics and world restoration.
## Keep play fully functional offline. No ads or billing in test releases.

const SaveData = preload("res://scripts/save_data.gd")
const Brand = preload("res://scripts/brand_config.gd")
const QuestRules = preload("res://scripts/quest_rules.gd")
const QuestProgress=preload("res://scripts/quest_progress.gd")
const COLS := 8
const ROWS := 8
var CELL := 82.0
var ORIGIN := Vector2(32, 429)
const BASE_SIZE := Vector2(720, 1440)
const LEVEL_COUNT := 12
const WORLD_NAMES := ["RUNIC HALL", "TEMPLE OF THE SUN", "JADE GARDENS", "ARCANE ARCHIVE"]
const WORLD_SHORT := ["RUNES", "EGYPT", "EAST ASIA", "MIXED"]
const WORLD_TAGLINES := [
    "The Viking Stones",
    "Mysteries of the Nile",
    "The Shrine of Symbols",
    "The Forgotten Library"
]
const SYMBOLS := [
    ["ᚠ", "ᚢ", "ᚦ", "ᚱ", "ᚹ", "ᛟ"],
    ["𓂀", "𓆣", "𓇳", "𓃭", "𓅓", "𓋹"],
    ["山", "水", "火", "月", "あ", "한"],
    ["ᚠ", "𓂀", "山", "ᚱ", "あ", "𓋹"]
]
const GEM_COLORS := [
    Color("#bc75ff"), Color("#ed76b8"), Color("#eec25e"),
    Color("#6fcaff"), Color("#72e2cf"), Color("#9dec7d")
]
const GOLD := Color("#f7d58f")
const CREAM := Color("#fff2d0")
const MUTED := Color("#d7c8dd")
const INK := Color("#30203d")
const NAVY := Color("#1d173f")
const VIOLET := Color("#46306f")
const TEAL := Color("#235b68")
const PANEL := Color("#33224d")

var save = SaveData.new()
var state := "menu"
var settings_return := "menu"
var previous_screen := "menu"
var world_index := 0
var mode := "quest"
var start_gems := 0
var moves_used := 0
var undo_left := 3
var undo_history: Array[Dictionary] = []
var fall_ghosts: Array[Dictionary] = []
var fall_age := 1.0
var level := 1
var board: Array[int] = []
var locks: Array[int] = []
var seal_types: Array[int] = []
var current_relic := ""
var album_world := 0
var victory_spark_age := 0.0
var draw_layout_landscape := false
var draw_layout_tablet_portrait := false
var reference_moves := 12
var boosters_used := 0
var impact_fx: Array[Dictionary] = []
var impact_flash := 0.0
var swap_ghosts: Array[Dictionary] = []
var swap_age := 1.0
var rejected_cells: Array[int] = []
var reject_age := 1.0
var music_alt_player: AudioStreamPlayer
var world_tracks: Array[AudioStream] = []
var music_track_id := -1

var score := 0
var moves_left := 24
var collected := 0
var objective_type := "collect"
var target_glyph := 0
var target_amount := 8
var score_target := 1600
var hints_left := 3
var shuffles_left := 2
var hammers_left := 2
var hammer_mode := false
var selected := -1
var hint_cells: Array[int] = []
var hint_until := 0
var last_action_at := 0
var status_message := "Match three or more identical glyphs!"
var earned_stars := 0
var recovery_used := false
var ui_font: Font
var display_font: Font
var art: Dictionary = {}
var render_tick := -1
var glyph_fonts: Array[Font] = []
var gems: Array[Texture2D] = []
var backgrounds: Array[Texture2D] = []
var scene_bg: Texture2D
var logo: Texture2D
var sound_players: Dictionary = {}
var music_player: AudioStreamPlayer
var touch_start := Vector2.ZERO
var touch_down := false
var sparkles: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var clock := 0.0
var next_auto_hint_at := 0
var settings_scroll := 0

func _ready() -> void:
    randomize()
    save.load_all()
    mode = str(save.data.get("mode", "quest"))
    if mode not in ["quest", "arcade"]:
        mode = "quest"
    ui_font = ThemeDB.fallback_font
    display_font = load("res://assets/v03/DejaVuSerif-Bold.ttf") as Font
    if display_font == null:
        display_font = ui_font
    for filename in [
        "NotoSansRunic-Regular.ttf",
        "NotoSansEgyptianHieroglyphs-Regular.ttf",
        "NotoSansJP.ttf",
        "NotoSansKR.ttf"
    ]:
        var f: Font = ui_font
        var path: String = "res://assets/fonts/" + str(filename)
        if ResourceLoader.exists(path):
            var loaded := load(path) as Font
            if loaded != null:
                f = loaded
        glyph_fonts.append(f)
    for i in range(6):
        gems.append(load("res://assets/v03/gem_%s.png" % i) as Texture2D)
    for item in ["runes", "egypt", "asia", "mixed"]:
        backgrounds.append(load("res://assets/v03/%s_scene.png" % item) as Texture2D)
    scene_bg = load("res://assets/v03/menu_scene.png") as Texture2D
    for item in ["title", "button", "ribbon", "parchment", "medallion", "spark"]:
        var file_name: String = "hud_medallion" if item == "medallion" else ("title_plaque" if item == "title" else ("button_plaque" if item == "button" else ("magic_spark" if item == "spark" else item)))
        art[item] = load("res://assets/v03/" + file_name + ".png") as Texture2D
    art["board_frame"] = load("res://assets/v05/board_frame.png") as Texture2D
    art["render_logo"] = load("res://assets/runefall/runefall_logo_header.png") as Texture2D
    art["logo_primary"] = load("res://assets/runefall/runefall_logo_primary.png") as Texture2D
    art["cracked"] = load("res://assets/v05/cracked.png") as Texture2D
    art["lock"] = load("res://assets/v05/lock.png") as Texture2D
    art["booster_plate"] = load("res://assets/v05/booster_plate.png") as Texture2D
    art["magic_glow"] = load("res://assets/v05/magic_glow.png") as Texture2D
    for wi in range(4):
        art["mural_%d" % wi] = load("res://assets/v06/mural_%d.png" % wi) as Texture2D
        for ri in range(4):
            art["relic_%d_%d" % [wi,ri]] = load("res://assets/v06/relic_%d_%d.png" % [wi,ri]) as Texture2D
    for i in range(4):
        art["world_%d" % i] = load("res://assets/v03/world_%d.png" % i) as Texture2D
    for i in range(3):
        art["booster_%d" % i] = load("res://assets/v03/booster_%d.png" % i) as Texture2D
    art["undo"] = load("res://assets/v04/undo.png") as Texture2D
    art["stone"] = load("res://assets/v04/stone.png") as Texture2D
    for item in ["tap", "match", "win", "fail", "stone", "seal", "combo", "relic", "land", "ice"]:
        var player := AudioStreamPlayer.new()
        var sound_path: String="res://assets/audio/v06/" + item + ".wav" if item in ["stone","seal","combo","relic","land","ice"] else "res://assets/audio/" + item + ".wav"
        player.stream = load(sound_path)
        player.volume_db = -7
        add_child(player)
        sound_players[item] = player
    music_player = AudioStreamPlayer.new()
    music_alt_player = AudioStreamPlayer.new()
    add_child(music_player)
    add_child(music_alt_player)
    for track in ["menu", "runes", "egypt", "asia", "mixed"]:
        var stream: AudioStream = load("res://assets/audio/worlds/" + track + ".ogg")
        if stream is AudioStreamOggVorbis:
            (stream as AudioStreamOggVorbis).loop = true
        world_tracks.append(stream)
    _music_state()
    var active: Dictionary = save.data.get("current", {})
    if active.has("world"):
        world_index = clampi(int(active.get("world", 0)), 0, 3)
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
        if state == "playing" or state == "paused" or state == "tutorial":
            _save_current()

func _process(delta: float) -> void:
    clock += delta
    if victory_spark_age>0.0:
        victory_spark_age=maxf(0.0,victory_spark_age-delta)
    if impact_flash > 0.0:
        impact_flash = maxf(0.0, impact_flash-delta*2.1)
        queue_redraw()
    if swap_age < 1.0:
        swap_age = minf(1.0,swap_age+delta/.21)
        if swap_age >= 1.0:swap_ghosts.clear()
        queue_redraw()
    if reject_age < 1.0:
        reject_age = minf(1.0,reject_age+delta/.25)
        if reject_age >= 1.0:rejected_cells.clear()
        queue_redraw()
    for i in range(impact_fx.size()-1,-1,-1):
        var hit: Dictionary = impact_fx[i]
        hit["life"] = float(hit["life"])-delta
        if float(hit["life"])<=0:
            impact_fx.remove_at(i)
        else:
            impact_fx[i] = hit
    if not impact_fx.is_empty():
        queue_redraw()
    if fall_age < 1.0:
        fall_age += delta
        if fall_age >= 0.35:
            fall_ghosts.clear()
        queue_redraw()
    var tick := int(clock * (12.0 if save.pref("reduce_motion") else 30.0))
    if tick != render_tick:
        render_tick = tick
        queue_redraw()
    if not hint_cells.is_empty() and Time.get_ticks_msec() >= hint_until:
        hint_cells.clear()
        queue_redraw()
    if state == "playing" and save.pref("auto_hints") and next_auto_hint_at > 0 and Time.get_ticks_msec() > next_auto_hint_at:
        hint_cells = _find_hint()
        hint_until = Time.get_ticks_msec() + 1700
        next_auto_hint_at = Time.get_ticks_msec() + 11000
    if not sparkles.is_empty():
        for idx in range(sparkles.size() - 1, -1, -1):
            var p: Dictionary = sparkles[idx]
            p["life"] = float(p["life"]) - delta
            p["pos"] = p["pos"] + p["vel"] * delta
            p["vel"] = p["vel"] + Vector2(0, 90 * delta)
            if float(p["life"]) <= 0:
                sparkles.remove_at(idx)
            else:
                sparkles[idx] = p
        queue_redraw()
    if not popups.is_empty():
        for idx in range(popups.size() - 1, -1, -1):
            var p: Dictionary = popups[idx]
            p["life"] = float(p["life"]) - delta
            if float(p["life"]) <= 0:
                popups.remove_at(idx)
            else:
                popups[idx] = p
        queue_redraw()

func _logical_size() -> Vector2:
    var v:=get_viewport_rect().size
    if v.x>v.y*1.25:return Vector2(1600,900)
    if v.x>v.y*.59:return Vector2(900,1440)
    return BASE_SIZE

func _scale() -> Vector2:
    var s := get_viewport_rect().size
    if s.x <= 0 or s.y <= 0:
        return Vector2.ONE
    var logical:=_logical_size()
    var uniform := minf(s.x / logical.x, s.y / logical.y)
    return Vector2(uniform,uniform)

func _offset() -> Vector2:
    var s := get_viewport_rect().size
    return (s - _logical_size() * _scale()) * 0.5

func _draw() -> void:
    var v:=get_viewport_rect().size
    draw_layout_landscape=v.x>v.y*1.25
    draw_layout_tablet_portrait=not draw_layout_landscape and v.x>v.y*.59
    if draw_layout_landscape:
        CELL=78.0
        ORIGIN=Vector2(42,143)
    elif draw_layout_tablet_portrait:
        CELL=98.0
        ORIGIN=Vector2(51,406)
    else:
        CELL=82.0
        ORIGIN=Vector2(32,429)
    var bg: Texture2D = scene_bg
    if state in ["playing","paused","victory","failure","recovery","tutorial"] and backgrounds.size()==4:
        bg=backgrounds[world_index]
    if bg!=null:
        draw_texture_rect(bg,Rect2(Vector2.ZERO,get_viewport_rect().size),false)
    var extra_x:=90.0 if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","recovery","tutorial"] else 0.0
    draw_set_transform(_offset()+Vector2(extra_x,0)*_scale(),0.0,_scale())
    if draw_layout_landscape:
        _background()
        match state:
            "playing","paused","victory","failure","recovery","tutorial":
                _draw_tablet_game()
                if state!="playing":_draw_tablet_overlay()
            "menu":_draw_tablet_menu()
            "levels":_draw_tablet_levels()
            "collection":_draw_tablet_collection()
            "settings","settings_fx":_draw_tablet_settings()
            "progress":_draw_tablet_progress()
            "reset_confirm":_draw_tablet_settings()
    elif draw_layout_tablet_portrait and state in ["playing","paused","victory","failure","recovery","tutorial"]:
        _background()
        _draw_portrait_tablet_game()
        if state!="playing":_draw_portrait_tablet_overlay()
    else:
        _background()
        match state:
            "menu":_draw_menu()
            "levels":_draw_levels()
            "settings":_draw_settings()
            "settings_fx":_draw_effects_settings()
            "progress":_draw_progress()
            "collection":_draw_collection()
            "playing","paused","victory","failure","recovery","tutorial":
                _draw_game()
                if state=="paused":_draw_pause()
                elif state=="victory":_draw_result(true)
                elif state=="failure":_draw_result(false)
                elif state=="recovery":_draw_recovery()
                elif state=="tutorial":_draw_tutorial()
            "reset_confirm":
                _draw_settings()
                _draw_reset_confirm()
    draw_set_transform(Vector2.ZERO)

func _tex(key: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
    var tex: Texture2D = art.get(key, null) as Texture2D
    if tex != null:
        draw_texture_rect(tex, rect, false, tint)

func _background() -> void:
    var tex: Texture2D = scene_bg
    if state in ["playing", "paused", "victory", "failure", "tutorial"]:
        tex = backgrounds[world_index]
    if tex != null:
        draw_texture_rect(tex, Rect2(Vector2.ZERO,_logical_size()), false)
    else:
        draw_rect(Rect2(Vector2.ZERO,_logical_size()), NAVY)
    var restoration:=save.world_stage(world_index)
    var darkening:=maxf(.05,.32-float(restoration)*.065) if state in ["playing","paused","victory","failure","recovery","tutorial"] else .11
    draw_rect(Rect2(Vector2.ZERO,_logical_size()),Color(.03,.007,.05,darkening))
    # Lightweight atmospheric dust, warm lens glow and cold rune shimmer.
    if save.pref("ambient_motion") and not save.pref("reduce_motion"):
        for i in range(34):
            var bounds:=_logical_size()
            var pos := Vector2(11.0 + fposmod(float(i * 211 + 71), bounds.x-20.0), 22.0 + fposmod(float(i * 293 + 47), bounds.y-30.0))
            var movement := Vector2(sin(clock * 0.31 + float(i)) * 4.5, -fposmod(clock * float(3+i%4), 140.0))
            var alpha := 0.10 + 0.12*(.5+.5*sin(clock * 1.8+float(i)))
            var world_color: Color=GEM_COLORS[(i+world_index)%6] if world_index==3 else Color(1,.88,.59) if world_index==1 else Color(.72,1,.82) if world_index==2 else Color(.7,.85,1)
            draw_circle(pos+movement,1.0+float(i%3)*.6,Color(world_color.r,world_color.g,world_color.b,alpha))

func _rect(rect: Rect2, color: Color, radius: int = 16, border: Color = Color.TRANSPARENT, bw: int = 0) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(radius)
    if bw > 0:
        style.border_color = border
        style.set_border_width_all(bw)
    draw_style_box(style, rect)

func _panel(rect: Rect2, color: Color = PANEL, ornate: bool = true, fill_alpha: float = 0.94) -> void:
    _rect(Rect2(rect.position + Vector2(0, 8), rect.size), Color(0.015, 0.008, 0.032, 0.76), 22)
    var fill := color
    fill.a = fill_alpha
    _rect(rect, fill, 22, Color("#bd7935"), 5 if ornate else 3)
    _rect(rect.grow(-4), Color.TRANSPARENT, 19, Color("#f3d48a"), 2)
    _rect(rect.grow(-9), Color.TRANSPARENT, 17, Color("#8c5e40"), 1)
    if ornate:
        for pt in [rect.position+Vector2(23,23),Vector2(rect.end.x-23,rect.position.y+23),Vector2(rect.position.x+23,rect.end.y-23),rect.end-Vector2(23,23)]:
            draw_arc(pt, 15, 0, TAU, 24, Color("#f4dc9c"), 3.0, true)
            draw_circle(pt, 5, Color("#8153b6"))
            draw_circle(pt, 2, Color("#debdff"))

func _label(value: String, x: float, y: float, size: int, color: Color = CREAM, center: bool = false, font_override: Font = null) -> void:
    var f: Font = ui_font if font_override == null else font_override
    var point_size := size + (2 if save.pref("large_text") and font_override == null else 0)
    var draw_x := x
    if center:
        draw_x -= f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x / 2.0
    draw_string(f, Vector2(draw_x+1,y+3), value, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size, Color(0.016,0.008,0.03,0.97))
    draw_string(f, Vector2(draw_x,y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size, color)

func _fancy(value: String, x: float, y: float, size: int, center: bool = true) -> void:
    _label(value, x, y, size, Color("#ffdb85"), center, display_font)

func _button(rect: Rect2, value: String, selected_style: bool = false, size: int = 24) -> void:
    _tex("button", rect, Color("#f8d6a1") if selected_style else Color.WHITE)
    if selected_style:
        _rect(rect.grow(-11), Color(0.95,0.66,0.22,0.09), 12)
    _label(value, rect.get_center().x, rect.get_center().y + float(size)*0.35, size, Color("#ffe7ae") if selected_style else Color("#fff1d7"), true, display_font)

func _title(value: String, subtitle: String = "") -> void:
    _tex("title", Rect2(38,65,644,142))
    _fancy(value, 360, 134, 37)
    if not subtitle.is_empty():
        _label(subtitle, 360, 173, 21, MUTED, true)

func _glyph_font(tile: int) -> Font:
    if world_index == 0: return glyph_fonts[0]
    if world_index == 1: return glyph_fonts[1]
    if world_index == 2: return glyph_fonts[3] if tile == 5 else glyph_fonts[2]
    if tile in [0, 3]: return glyph_fonts[0]
    if tile in [1, 5]: return glyph_fonts[1]
    return glyph_fonts[2]

func _world_symbol(world: int) -> String:
    return ["ᚠ","𓂀","山","ᛟ"][world]

func _world_font(world: int) -> Font:
    return [glyph_fonts[0],glyph_fonts[1],glyph_fonts[2],glyph_fonts[0]][world]

func _draw_logo(x: float, y: float, w: float, h: float) -> void:
    # Preserve the proportions of the approved golden Runefall artwork.
    var logo: Texture2D=art.get("render_logo")
    if logo==null:return
    var natural_size: Vector2=logo.get_size()
    var scale_factor:=minf(w/natural_size.x,h/natural_size.y)
    var size:=natural_size*scale_factor
    var anchor:=Vector2(x+(w-size.x)*.5,y+(h-size.y)*.5)
    draw_texture_rect(logo,Rect2(anchor,size),false)

func _draw_menu() -> void:
    _draw_logo(28, 76, 664, 186)
    _label("MATCH. DISCOVER. AWAKEN.",360,294,23,GOLD,true,display_font)
    _panel(Rect2(52, 329, 616, 318), Color("#2e1d4b"), true, 0.92)
    _tex("world_%d" % world_index, Rect2(380, 374, 267, 207), Color(1, 1, 1, 0.93))
    _rect(Rect2(370, 372, 16, 200), Color(0.06, 0.03, 0.13, 0.55), 4)
    _label("CURRENT ADVENTURE", 243, 379, 22, GOLD, true)
    _label(_world_symbol(world_index), 221, 478, 82, CREAM, true, _world_font(world_index))
    _fancy(WORLD_SHORT[world_index], 239, 524, 27)
    if mode == "quest":
        _label("LEVEL %s / %s" % [save.unlocked_level(world_index), LEVEL_COUNT], 238, 566, 21, CREAM, true)
    else:
        _label("UNLIMITED MATCHES", 238, 566, 19, CREAM, true)
    _button(Rect2(57, 431, 70, 63), "<", false, 29)
    _button(Rect2(593, 431, 70, 63), ">", false, 29)
    _button(Rect2(85, 583, 252, 61), "QUEST", mode == "quest", 22)
    _button(Rect2(374, 583, 252, 61), "ARCADE", mode == "arcade", 22)
    var current: Dictionary = save.data.get("current", {})
    var same_mode: bool = str(current.get("mode", "")) == mode
    var same_world: bool = int(current.get("world", -1)) == world_index
    var button_label := "CONTINUE GAME" if same_mode and same_world else ("BEGIN QUEST" if mode == "quest" else "PLAY ARCADE")
    _button(Rect2(54, 673, 612, 84), button_label, true, 32)
    _fancy("CHOOSE YOUR WORLD", 360, 801, 27)
    for i in range(4):
        var xx := 51 + (i % 2) * 314
        var yy := 829 + int(i / 2) * 112
        _panel(Rect2(xx, yy, 300, 95), Color("#3d255a") if world_index == i else Color("#2b1b44"), false, 0.94)
        _tex("world_%d" % i, Rect2(xx + 16, yy + 12, 85, 71))
        _label(WORLD_SHORT[i], xx + 199, yy + 41, 21, GOLD if world_index == i else CREAM, true)
        _label("LEVEL %s / %s" % [save.unlocked_level(i), LEVEL_COUNT], xx + 199, yy + 70, 17, MUTED, true)
    _button(Rect2(53, 1081, 613, 68), "CHOOSE A LEVEL", false, 25)
    _button(Rect2(52, 1173, 299, 73), "SETTINGS", false, 25)
    _button(Rect2(369, 1173, 299, 73), "PROGRESS", false, 25)
    _button(Rect2(172, 1267, 376, 70), "RELIC COLLECTION", false, 22)
    _label("RUNEFALL  •  MATCH. DISCOVER. AWAKEN.  •  v0.6.1", 360, 1368, 16, CREAM, true)

func _draw_levels() -> void:
    _title("CHOOSE A LEVEL",WORLD_NAMES[world_index])
    _button(Rect2(48,225,144,63),"BACK")
    _label("Each victory earns stars and unlocks new challenges.",360,328,20,CREAM,true)
    for idx in range(LEVEL_COUNT):
        var lvl := idx+1
        var xx := 47 + (idx % 4) * 159
        var yy := 390 + int(idx / 4) * 174
        var unlocked := lvl <= save.unlocked_level(world_index)
        _panel(Rect2(xx,yy,146,149),Color("#4f296c") if unlocked else Color("#262039"),true,0.96)
        if unlocked:
            _fancy(str(lvl),xx+73,yy+82,45)
        else:
            _label("LOCKED",xx+73,yy+79,18,MUTED,true)
        var entry: Dictionary = save.best_result(world_index,lvl)
        if unlocked:
            _label("★".repeat(int(entry.get("stars",0))) if int(entry.get("stars",0))>0 else "NEW",xx+73,yy+121,18,GOLD,true)
    _fancy("WORLD PROGRESS",360,1060,28)
    _label("Complete quests to illuminate the map.",360,1110,21,CREAM,true)
    _button(Rect2(100,1192,520,77),"PLAY HIGHEST LEVEL",true,26)

func _draw_progress() -> void:
    _title("YOUR ADVENTURE","Every star is saved on this device")
    _button(Rect2(52,225,154,64),"BACK")
    _panel(Rect2(44,330,632,725),Color("#33234b"),true)
    _fancy(str(save.total_stars()),360,453,80)
    _label("STARS EARNED",360,507,28,CREAM,true)
    for i in range(4):
        var yy := 545 + i * 112
        _tex("world_%d" % i, Rect2(79,yy-26,83,77))
        _label(WORLD_SHORT[i],178,yy+5,25,CREAM)
        _label("LEVEL %s / %s" % [save.unlocked_level(i),LEVEL_COUNT],178,yy+34,19,MUTED)
        _rect(Rect2(178,yy+46,447,14),Color("#483d60"),7)
        _rect(Rect2(178,yy+46,maxf(11,447.0*float(save.unlocked_level(i)-1)/float(LEVEL_COUNT)),14),Color("#f0c067"),7)
    _label("ARCADE BEST: %s" % int(save.data.get("arcade_best", 0)),360,1158,22,GOLD,true)
    _label("NO LOGIN. YOUR ADVENTURE SAVES OFFLINE.",360,1204,17,CREAM,true)

func _draw_settings() -> void:
    _title("SETTINGS","The way you like to play")
    _button(Rect2(49,217,153,65),"BACK")
    _panel(Rect2(46,303,628,910),Color("#312348"),true,0.98)
    var rows := [
        ["Music","music"],["Sound effects","sfx"],["Vibration","haptics"],
        ["Reduce animations","reduce_motion"],["High-contrast gems","color_assist"],
        ["Automatic hints","auto_hints"],["Larger text","large_text"]
    ]
    for i in range(rows.size()):
        var item: Array = rows[i]
        var yy := 341 + i * 82
        _label(str(item[0]),80,yy+28,23,CREAM)
        _rect(Rect2(504,yy-10,125,57),Color("#345c59") if save.pref(str(item[1])) else Color("#513551"),17,Color("#edc481"),3)
        _label("ON" if save.pref(str(item[1])) else "OFF",566,yy+27,23,Color("#d4ffe7") if save.pref(str(item[1])) else CREAM,true)
        if i < rows.size()-1:
            draw_line(Vector2(80,yy+60),Vector2(627,yy+60),Color("#776083"),1.5)
    for i in range(2):
        var name := "Music volume" if i == 0 else "Effects volume"
        var key := "music_volume" if i == 0 else "sfx_volume"
        var yy := 944 + i*74
        _label(name,79,yy,22,CREAM)
        var val := save.setting_int(key,80)
        _rect(Rect2(300,yy-15,292,17),Color("#1a1530"),8,Color("#c7a464"),2)
        _rect(Rect2(300,yy-15,maxf(2,292.0*val/100.0),17),Color("#d6a7f9"),8)
        draw_circle(Vector2(300+292.0*val/100.0,yy-7),15,Color("#ffe2a1"))
        _label("%s%%" % val,629,yy+5,17,CREAM,true)
    _button(Rect2(79,1090,559,68),"VISUAL EFFECTS & ACCESSIBILITY",false,22)
    _button(Rect2(79,1172,559,68),"RESET SAVED PROGRESS",false,22)
    _label("Progress and settings are saved automatically.",360,1282,18,CREAM,true)
    _label("Ads and purchases are disabled in this test version.",360,1307,17,MUTED,true)

func _draw_game() -> void:
    _draw_logo(145, 1, 430, 163)
    _draw_nav_icons()
    # Reference-style stat badges flank a single parchment level ribbon.
    _tex("medallion", Rect2(14, 176, 183, 88))
    _tex("ribbon", Rect2(197, 190, 320, 66))
    _tex("medallion", Rect2(520, 176, 119, 88))
    _label("SCORE", 105, 197, 15, GOLD, true)
    _fancy(str(score), 105, 245, 35)
    _label("MOVES", 580, 198, 15, GOLD, true)
    _fancy(str(moves_used) if mode=="quest" else str(moves_left), 580, 245, 32)
    _label("LEVEL %s  •  %s" % [level, WORLD_SHORT[world_index]] if mode=="quest" else "ARCADE  •  %s" % WORLD_SHORT[world_index], 356, 232, 18, INK, true, display_font)
    # Compact parchment goal HUD with gem progress and fewer nested boxes.
    _tex("parchment", Rect2(42, 287, 636, 107))
    var amount := 0
    var goal := 0
    if mode == "quest":
        amount = start_gems-QuestRules.remaining(board)
        goal = start_gems
        _label("CLEAR 75% TO PASS", 170, 328, 25, INK, false, display_font)
        _label("%s / %s" % [amount,goal], 592, 375, 22, INK, true, display_font)
        _label("✦", 101, 366, 41, Color("#8d5d2a"), true)
    elif objective_type=="collect":
        amount=collected
        goal=target_amount
        _label("COLLECT %s GLYPHS" % target_amount, 168, 328, 23, INK, false, display_font)
        _label("%s / %s" % [mini(amount,goal),goal],592,375,22,INK,true,display_font)
        _label(SYMBOLS[world_index][target_glyph],101,367,44,INK,true,_glyph_font(target_glyph))
    else:
        amount=score
        goal=score_target
        _label("REACH %s POINTS" % goal,168,328,23,INK,false,display_font)
        _label("%s / %s" % [mini(amount,goal),goal],592,375,22,INK,true,display_font)
    _rect(Rect2(176, 347, 336, 22), Color("#473e4c"), 12)
    _rect(Rect2(178, 349, maxf(3.0, 332.0*minf(1.0,float(amount)/maxf(1.0,float(goal)))), 18), Color("#40d6f0"), 9)
    draw_line(Vector2(181,351),Vector2(510,351),Color(1,1,1,.20),2,true)
    # The rim is behind ALL playable gems; the top row is fully visible.
    _tex("board_frame", Rect2(15, 402, 690, 707))
    _tex("mural_%d" % world_index,Rect2(ORIGIN,CELL*Vector2(8,8)),Color(1,1,1,.55))
    _draw_tiles()
    _label(status_message,360,1140,19,CREAM,true)
    _draw_booster(0,hints_left,"HINT","booster_0")
    _draw_booster(1,shuffles_left,"SHUFFLE","booster_2")
    _draw_booster(2,hammers_left,"HAMMER","booster_1")
    _draw_booster(3,undo_left,"UNDO","undo")
    if state=="playing" and _eligible_stars()>0:
        _button(Rect2(175,1346,370,65),"CLAIM %s ★ NOW" % _eligible_stars(),true,24)
    _draw_fx()

func _draw_tiles() -> void:
    for row in range(ROWS):
        for col in range(COLS):
            var idx:=row*COLS+col
            var xx:=ORIGIN.x+float(col)*CELL
            var yy:=ORIGIN.y+float(row)*CELL
            var tile:=board[idx]
            var rect:=Rect2(xx+1,yy+1,CELL-2,CELL-2)
            _rect(rect.grow(-3),Color(0.02,0.04,0.12,0.90),10,Color("#304e7f"),1)
            if tile==QuestRules.WALL:
                _tex("stone",rect)
                continue
            if tile==QuestRules.CRACK:
                _tex("cracked",rect)
                continue
            if tile==QuestRules.EMPTY:
                _rect(rect.grow(-9),Color(.06,.08,.22,.37),8)
                continue
            if rejected_cells.has(idx):
                _rect(rect.grow(3),Color(1,.24,.44,.58*(1.0-reject_age)),13)
            if hint_cells.has(idx):
                _rect(rect.grow(3),Color("#d5fcff"),13)
                draw_arc(rect.get_center(),37,0,TAU,42,Color(.78,.95,1,.59+.3*sin(clock*9.0)),4,true)
            elif selected==idx:
                _rect(rect.grow(3),GOLD,13)
            var hidden:=false
            if fall_age<0.31:
                for ghost in fall_ghosts:
                    if int(ghost["target"])==idx:
                        hidden=true
                        break
            if not hidden:
                _draw_live_gem(rect,tile,idx)
            if locks.size()==64 and locks[idx]>0:
                _draw_seal(rect,idx)

func _draw_fx() -> void:
    var calm := save.pref("reduce_motion")
    # The render's purple-white matching glow, expanding halo and gold sparks.
    for burst in impact_fx:
        var p: Vector2=burst["pos"]
        var t:=clampf(float(burst["life"])/.72,0.0,1.0)
        var color: Color=burst["color"]
        var radius:=26.0+(1.0-t)*58.0
        # Hold the matched gem momentarily in a purple-white flash before it pops.
        if t>.53 and burst.has("tile"):
            var old_rect:=Rect2(p-Vector2(CELL*.5,CELL*.5),Vector2(CELL-2,CELL-2))
            _draw_live_gem(old_rect,int(burst["tile"]),int(burst["index"]))
            _rect(old_rect.grow(-8),Color(.99,.63,1.0,(t-.53)*.34),11)
        _tex("magic_glow",Rect2(p-Vector2(86,86),Vector2(172,172)),Color(1,1,1,t*.96))
        draw_circle(p,50*t,Color(color.r,color.g,color.b,.11*t))
        draw_arc(p,radius,0,TAU,48,Color(.97,.79,1,.63*t),3.5,true)
        draw_arc(p,radius*.72,0,TAU,48,Color(.61,.32,1,.45*t),3,true)
        if not calm:
            for j in range(8):
                var a:=float(j)*TAU/8.0+clock*.52
                var outer:=p+Vector2(cos(a),sin(a))*(18+(1-t)*56)
                var inner:=p+Vector2(cos(a),sin(a))*(10+(1-t)*35)
                draw_line(inner,outer,Color(1,.86,.48,.75*t),2,true)
                _tex("spark",Rect2(outer-Vector2(8,8),Vector2(16,16)),Color(.95,.75,1,t))
    if swap_age < 1.0:
        var eased:=swap_age*swap_age*(3.0-2.0*swap_age)
        for g in swap_ghosts:
            var pos: Vector2=(g["from"] as Vector2).lerp(g["to"] as Vector2,eased)
            var gem_rect:=Rect2(ORIGIN+pos*CELL+Vector2(1,1),Vector2(CELL-2,CELL-2))
            _draw_live_gem(gem_rect,int(g["value"]),int(g["target"]))
    for p in sparkles:
        var life: float=p["life"]
        var tint: Color=p["color"]
        tint.a=clampf(life/.7,0.0,1.0)
        var pos: Vector2=p["pos"]
        var vel: Vector2=p["vel"]
        if not calm:draw_line(pos,pos-vel*.06,Color(tint.r,tint.g,tint.b,tint.a*.6),2,true)
        _tex("spark",Rect2(pos-Vector2(15,15),Vector2(30,30)),tint)
    if fall_age<.31:
        var t:=clampf(fall_age/.31,0.0,1.0)
        var eased:=1.0-pow(1.0-t,3.0)
        for ghost in fall_ghosts:
            var pos: Vector2=(ghost["from"] as Vector2).lerp(ghost["to"] as Vector2,eased)
            var rect:=Rect2(ORIGIN+pos*CELL+Vector2(1,1),Vector2(CELL-2,CELL-2))
            _draw_live_gem(rect,int(ghost["value"]),int(ghost["target"]))
    for p in popups:
        var t:=clampf(float(p["life"]),0.0,1.0)
        var pos: Vector2=p["pos"]
        var yy:=pos.y+(1.0-t)*(-58.0)
        var text_value:=str(p["text"])
        var font_size:=39 if not text_value.begins_with("COMBO") else 30
        _label(text_value,pos.x+2,yy+3,font_size,Color(.18,.03,.24,t),true,display_font)
        _label(text_value,pos.x,yy,font_size,Color(1,.86,.57,t),true,display_font)

func _modal(dim: float = 0.77) -> void:
    draw_rect(Rect2(0,0,720,1440),Color(0.02,0.01,0.06,dim))

func _draw_pause() -> void:
    _modal()
    _panel(Rect2(69,428,582,568),Color("#302041"),true)
    _fancy("QUEST PAUSED",360,540,44)
    _label("Your progress is saved.",360,594,23,CREAM,true)
    _button(Rect2(116,635,488,78),"RESUME",true,30)
    _button(Rect2(116,738,488,78),"SETTINGS")
    _button(Rect2(116,843,488,78),"SAVE & HOME")

func _draw_result(victory: bool) -> void:
    _modal()
    _panel(Rect2(55, 377, 610, 685), Color("#40294d"), true)
    if mode == "quest":
        var remaining := QuestRules.remaining(board)
        var percent := 100.0 * float(start_gems - remaining) / float(maxi(1, start_gems))
        _fancy("PERFECT CLEAR!" if remaining == 0 else ("LEVEL COMPLETE!" if victory else "NO MATCHES LEFT"), 360, 498, 35)
        _label("★".repeat(earned_stars) if earned_stars > 0 else "TRY AGAIN", 360, 580, 56, GOLD, true)
        _label("CLEAR RATE: %.0f%%" % percent, 360, 637, 27, CREAM, true)
        _label("%s of %s gems cleared" % [start_gems - remaining, start_gems], 360, 694, 23, CREAM, true)
        _label("MOVES: %s   •   SCORE: %s" % [moves_used, score], 360, 743, 22, GOLD, true)
    else:
        _fancy("ARCADE WIN!" if victory else "OUT OF MOVES", 360, 498, 38)
        _label("★".repeat(earned_stars) if victory else "TRY AGAIN", 360, 580, 55, GOLD, true)
        _label("Arcade high score: %s" % int(save.data.get("arcade_best", 0)), 360, 638, 23, CREAM, true)
        _fancy("SCORE %s" % score, 360, 696, 32)
        _label("Keep matching for your next record!", 360, 741, 21, CREAM, true)
    _button(Rect2(112, 792, 496, 76), "NEXT LEVEL" if victory and mode == "quest" and level < LEVEL_COUNT else ("PLAY AGAIN" if mode == "arcade" else ("WORLD SELECT" if victory else "RETRY")), true, 27)
    _button(Rect2(112, 889, 496, 76), "REPLAY" if victory else "SELECT LEVEL", false, 26)
    _button(Rect2(112, 984, 496, 60), "HOME", false, 24)

func _draw_recovery() -> void:
    _modal()
    _panel(Rect2(64,430,592,546),Color("#38234f"),true)
    _fancy("NO MATCHES REMAIN",360,520,34)
    _label("You've cleared %.0f%% of the gems." % QuestProgress.clear_rate(start_gems,QuestRules.remaining(board)),360,596,24,CREAM,true)
    _label("Reach 75% to complete the level.",360,651,21,GOLD,true)
    _label("Your first recovery is FREE. No ads.",360,695,20,CREAM,true)
    _button(Rect2(109,751,502,82),"FREE RESCUE",true,29)
    _button(Rect2(109,856,502,73),"RETRY LEVEL",false,25)

func _draw_tutorial() -> void:
    _modal(0.73)
    _panel(Rect2(72, 445, 576, 505), Color("#392853"), true)
    _fancy("HOW TO PLAY", 360, 536, 38)
    if mode == "quest":
        _label("SWAP ADJACENT GEMS TO MAKE 3+.", 360, 608, 19, CREAM, true)
        _label("Matched gems disappear and fall.", 360, 650, 22, CREAM, true)
        _label("NO NEW GEMS will replace them.", 360, 688, 21, GOLD, true)
        _label("75% = PASS  •  85% = 2 ★  •  100% = 3 ★", 360, 727, 19, CREAM, true)
        _label("Claim victory after 75% or play on.", 360, 763, 20, CREAM, true)
        _label("One free rescue if you get stuck.", 360, 794, 19, CREAM, true)
    else:
        _label("ARCADE MODE", 360, 615, 24, GOLD, true)
        _label("Swap adjacent gems to match 3+.", 360, 668, 23, CREAM, true)
        _label("Fresh gems fall after each match.", 360, 711, 21, CREAM, true)
        _label("Reach your target before moves run out.", 360, 754, 19, CREAM, true)
    _button(Rect2(122, 840, 476, 76), "LET'S PLAY!", true, 30)

func _draw_reset_confirm() -> void:
    _modal()
    _panel(Rect2(64,468,592,464),Color("#35284f"),true)
    _fancy("RESET PROGRESS?",360,573,35)
    _label("This deletes stars and the current quest.",360,644,22,CREAM,true)
    _label("Your sound and display settings remain.",360,683,20,CREAM,true)
    _button(Rect2(111,723,498,70),"KEEP PROGRESS",true)
    _button(Rect2(111,820,498,70),"DELETE SAVES")

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var e := event as InputEventScreenTouch
        if e.pressed:
            touch_start = (e.position-_offset())/_scale()-Vector2(90,0) if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","recovery","tutorial"] else (e.position-_offset())/_scale()
            touch_down = true
        elif touch_down:
            touch_down = false
            _gesture(touch_start,(e.position-_offset())/_scale()-Vector2(90,0) if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","recovery","tutorial"] else (e.position-_offset())/_scale())
    elif event is InputEventMouseButton and not OS.has_feature("mobile"):
        var e := event as InputEventMouseButton
        if e.button_index == MOUSE_BUTTON_LEFT:
            if e.pressed:
                touch_start = (e.position-_offset())/_scale()-Vector2(90,0) if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","recovery","tutorial"] else (e.position-_offset())/_scale()
                touch_down = true
            elif touch_down:
                touch_down = false
                _gesture(touch_start,(e.position-_offset())/_scale()-Vector2(90,0) if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","recovery","tutorial"] else (e.position-_offset())/_scale())
    elif event is InputEventKey:
        var e := event as InputEventKey
        if e.pressed and e.keycode in [KEY_ESCAPE,KEY_BACK]:
            _back()

func _inside(point: Vector2, x: float, y: float, w: float, h: float) -> bool:
    return Rect2(x,y,w,h).has_point(point)

func _gesture(start: Vector2, finish: Vector2) -> void:
    var p := finish
    _play_sound("tap")
    if draw_layout_landscape:
        _gesture_tablet(start,finish)
        _music_state()
        queue_redraw()
        return
    if draw_layout_tablet_portrait and state in ["playing","paused","victory","failure","recovery","tutorial"]:
        _gesture_portrait_tablet(start,p)
        _music_state()
        queue_redraw()
        return
    match state:
        "menu": _touch_menu(p)
        "levels": _touch_levels(p)
        "settings": _touch_settings(p)
        "settings_fx":_touch_effects_settings(p)
        "progress":
            if _inside(p,48,225,154,64):
                state="menu"
        "collection":
            if _inside(p,48,225,154,64):
                state="menu"
            else:
                for w in range(4):
                    if _inside(p,55+w*155,320,148,78):
                        album_world=w
        "playing": _touch_game(start,p)
        "recovery":_touch_recovery(p)
        "paused": _touch_pause(p)
        "victory","failure": _touch_result(p)
        "tutorial":
            if _inside(p,122,840,476,76):
                save.data["tutorial_done_v06"] = true
                save.mark_tutorial()
                state="playing"
                _save_current()
        "reset_confirm":
            if _inside(p,111,723,498,70):
                state="settings"
            elif _inside(p,111,820,498,70):
                save.reset_progress()
                board.clear()
                world_index=0
                settings_return="menu"
                state="menu"
    _music_state()
    queue_redraw()

func _back() -> void:
    match state:
        "playing","tutorial":
            state="paused"
            _save_current()
        "recovery":
            _skip_recovery()
        "paused":
            state="playing"
        "levels","progress","collection":
            state="menu"
        "settings":
            state=settings_return
        "settings_fx":
            state="settings"
        "reset_confirm":
            state="settings"
        "victory","failure":
            state="menu"
        _:
            state="menu"
    _music_state()
    queue_redraw()

func _touch_menu(p: Vector2) -> void:
    if _inside(p, 52, 431, 80, 63):
        world_index = (world_index + 3) % 4
    elif _inside(p, 588, 431, 80, 63):
        world_index = (world_index + 1) % 4
    elif _inside(p, 85, 583, 252, 61):
        mode = "quest"
        save.data["mode"] = mode
        save.save_all()
    elif _inside(p, 374, 583, 252, 61):
        mode = "arcade"
        save.data["mode"] = mode
        save.save_all()
    elif _inside(p, 54, 673, 612, 84):
        var current: Dictionary = save.data.get("current", {})
        if current.get("mode", "") == mode and int(current.get("world", -1)) == world_index and _resume_saved():
            return
        _start_level(world_index, save.unlocked_level(world_index) if mode == "quest" else 1)
    else:
        for i in range(4):
            var xx := 51 + (i % 2) * 314
            var yy := 829 + int(i / 2) * 112
            if _inside(p, xx, yy, 300, 95):
                world_index = i
                return
        if _inside(p, 53, 1081, 613, 68):
            mode = "quest"
            save.data["mode"] = mode
            save.save_all()
            state = "levels"
        elif _inside(p, 52, 1173, 299, 73):
            settings_return = "menu"
            state = "settings"
        elif _inside(p, 369, 1173, 299, 73):
            state = "progress"
        elif _inside(p,172,1267,376,70):
            album_world=world_index
            state="collection"

func _touch_levels(p: Vector2) -> void:
    if _inside(p,48,225,144,63):
        state="menu"
        return
    for idx in range(LEVEL_COUNT):
        var xx := 47+(idx%4)*159
        var yy := 390+int(idx/4)*174
        if _inside(p,xx,yy,146,149):
            if idx+1 <= save.unlocked_level(world_index):
                _start_level(world_index,idx+1)
            return
    if _inside(p,100,1192,520,77):
        _start_level(world_index,save.unlocked_level(world_index))

func _touch_settings(p: Vector2) -> void:
    if _inside(p,49,217,153,65):
        state=settings_return
        _music_state()
        return
    var pref_keys := ["music","sfx","haptics","reduce_motion","color_assist","auto_hints","large_text"]
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
    if _inside(p,79,1090,559,68):
        state="settings_fx"
    elif _inside(p,79,1172,559,68):
        state="reset_confirm"

func _touch_pause(p: Vector2) -> void:
    if _inside(p,116,635,488,78):
        state="playing"
    elif _inside(p,116,738,488,78):
        settings_return="paused"
        state="settings"
    elif _inside(p,116,843,488,78):
        _save_current()
        state="menu"

func _touch_result(p: Vector2) -> void:
    var was_win := state == "victory"
    if _inside(p, 112, 792, 496, 76):
        if mode == "arcade":
            _start_arcade(world_index)
        elif was_win and level < LEVEL_COUNT:
            _start_level(world_index, level + 1)
        elif was_win:
            state = "menu"
        else:
            _start_level(world_index, level)
    elif _inside(p, 112, 889, 496, 76):
        if was_win:
            _start_level(world_index, level)
        else:
            state = "levels" if mode == "quest" else "menu"
    elif _inside(p, 112, 984, 496, 60):
        state = "menu"

func _touch_recovery(p: Vector2) -> void:
    if _inside(p,109,751,502,82):
        _free_recovery()
    elif _inside(p,109,856,502,73):
        _start_level(world_index,level)

func _touch_game(start: Vector2, p: Vector2) -> void:
    if mode=="quest" and _eligible_stars()>0 and _inside(p,175,1346,370,65):
        _claim_qualified()
        return
    if _inside(p, 10, 55, 77, 76):
        _save_current()
        state = "menu"
        return
    if _inside(p, 638, 176, 82, 86):
        _save_current()
        state = "paused"
        return
    for i in range(4):
        var x := 13 + i * 175
        if _inside(p, x, 1162, 168, 156):
            match i:
                0:
                    if hints_left > 0:
                        hints_left -= 1
                        boosters_used+=1
                        _show_hint()
                        _save_current()
                    else:
                        status_message = "No hints left."
                1:
                    _shuffle()
                2:
                    if hammers_left > 0:
                        hammer_mode = not hammer_mode
                        status_message = "Tap a gem to break it!" if hammer_mode else "Hammer cancelled."
                    else:
                        status_message = "No hammers left."
                3:
                    _undo_last()
            return
    if fall_age < 0.26:
        return
    var first := _board_index(start)
    if first < 0:
        return
    if hammer_mode:
        hammer_mode = false
        _hammer(first)
        return
    var second := _board_index(p)
    var delta := p - start
    if delta.length() >= 25.0 and (second == first or second < 0):
        if absf(delta.x) > absf(delta.y):
            second = _neighbor(first, 1 if delta.x > 0 else -1, 0)
        else:
            second = _neighbor(first, 0, 1 if delta.y > 0 else -1)
    if second >= 0 and second != first and _adjacent(first, second):
        selected = -1
        _attempt_swap(first, second)
    elif selected >= 0 and selected != first and _adjacent(selected, first):
        _attempt_swap(selected, first)
        selected = -1
    else:
        selected = -1 if selected == first else first

func _board_index(p: Vector2) -> int:
    var delta := p-ORIGIN
    if delta.x<0 or delta.y<0:
        return -1
    var c:=int(delta.x/CELL)
    var r:=int(delta.y/CELL)
    if c>=COLS or r>=ROWS:
        return -1
    return r*COLS+c

func _neighbor(i: int,dx: int,dy: int) -> int:
    var c:=i%COLS+dx
    var r:=int(i/COLS)+dy
    if c<0 or c>=COLS or r<0 or r>=ROWS:
        return -1
    return r*COLS+c

func _adjacent(a: int,b: int) -> bool:
    return abs(a%COLS-b%COLS)+abs(int(a/COLS)-int(b/COLS))==1

func _configure_level(w: int, lvl: int) -> void:
    world_index = w
    level = lvl
    score_target = 1400 + lvl * 410
    target_glyph = (lvl - 1 + w) % 6
    target_amount = 8 + (lvl - 1) % 5 * 2
    objective_type = "clear" if mode == "quest" else ("score" if lvl % 3 == 0 else "collect")
    moves_left = 25
    moves_used = 0
    score = 0
    collected = 0
    hints_left = 3
    shuffles_left = 2
    hammers_left = 2
    undo_left = 3
    undo_history.clear()
    boosters_used=0
    locks.clear()
    seal_types.clear()
    current_relic=""
    impact_fx.clear()
    hammer_mode = false
    selected = -1
    hint_cells.clear()
    status_message = "Clear the stones! No new gems will appear." if mode == "quest" else "Match 3 or more gems for points!"
    earned_stars = 0
    recovery_used=false
    sparkles.clear()
    popups.clear()
    fall_ghosts.clear()
    fall_age = 1.0

func _start_level(w: int, lvl: int) -> void:
    _configure_level(w, clampi(lvl, 1, LEVEL_COUNT))
    _create_board()
    start_gems = QuestRules.remaining(board)
    state = "playing" if bool(save.data.get("tutorial_done_v06", false)) else "tutorial"
    _save_current()
    _reset_idle()
    _music_state()
    queue_redraw()

func _start_game() -> void:
    _start_level(world_index, 1)

func _resume_saved() -> bool:
    var current: Dictionary = save.data.get("current", {})
    var restored: Array = current.get("board", [])
    if restored.size() != ROWS * COLS:
        return false
    if int(current.get("board_version", 0)) != 6:
        # Preserve completed stars, but do not reinterpret old puzzle layouts.
        save.clear_current()
        return false
    mode = str(current.get("mode", "quest"))
    if mode != "arcade":
        mode = "quest"
    _configure_level(clampi(int(current.get("world", 0)), 0, 3), clampi(int(current.get("level", 1)), 1, LEVEL_COUNT))
    board.clear()
    for value in restored:
        board.append(clampi(int(value), QuestRules.CRACK, 5))
    locks.clear()
    for value in current.get("locks", []):
        locks.append(clampi(int(value),0,2))
    if locks.size()!=64:locks.resize(64);locks.fill(0)
    seal_types.clear()
    for value in current.get("seal_types",[]):
        seal_types.append(clampi(int(value),0,3))
    if seal_types.size()!=64:seal_types.resize(64);seal_types.fill(0)
    current_relic=str(current.get("relic",""))
    reference_moves=maxi(1,int(current.get("reference_moves",12)))
    boosters_used=maxi(0,int(current.get("boosters_used",0)))
    recovery_used=bool(current.get("recovery_used",false))
    score = maxi(0, int(current.get("score", 0)))
    moves_left = maxi(0, int(current.get("moves", 25)))
    moves_used = maxi(0, int(current.get("moves_used", 0)))
    start_gems = maxi(1, int(current.get("start_gems", QuestRules.remaining(board))))
    collected = maxi(0, int(current.get("collected", 0)))
    hints_left = clampi(int(current.get("hints", 3)), 0, 3)
    shuffles_left = clampi(int(current.get("shuffles", 2)), 0, 2)
    hammers_left = clampi(int(current.get("hammers", 2)), 0, 2)
    undo_left = clampi(int(current.get("undo_left", 3)), 0, 3)
    undo_history.clear()
    var prior: Array = current.get("undo_history", [])
    for item in prior:
        if typeof(item) == TYPE_DICTIONARY and item.get("board", []).size() == 64:
            undo_history.append(item)
    state = "playing" if bool(save.data.get("tutorial_done_v06", false)) else "tutorial"
    _reset_idle()
    if mode=="quest" and QuestRules.legal_moves(board,locks).is_empty():
        _finish_or_save()
    queue_redraw()
    return true

func _save_current() -> void:
    if board.size() != ROWS * COLS:
        return
    save.set_current({
        "mode": mode,"board_version":6,"world": world_index, "level": level, "board": board.duplicate(),
        "locks":locks.duplicate(),"seal_types":seal_types.duplicate(),"relic":current_relic,
        "reference_moves":reference_moves,"boosters_used":boosters_used,
        "recovery_used":recovery_used,
        "score": score, "moves": moves_left, "moves_used": moves_used,
        "start_gems": start_gems, "collected": collected,
        "hints": hints_left, "shuffles": shuffles_left, "hammers": hammers_left,
        "undo_left": undo_left, "undo_history": undo_history.duplicate(true)
    })

func _create_board() -> void:
    if mode == "quest":
        var scene: Dictionary = QuestRules.generate(world_index, level)
        board = scene["board"].duplicate()
        locks = scene["locks"].duplicate()
        seal_types=scene["seal_types"].duplicate()
        current_relic=str(scene["relic"])
        reference_moves = int(scene["min_certified_moves"])
        if not QuestRules.certified_solution(world_index, level):
            push_error("Quest puzzle did not pass the clearing proof.")
        return
    # Preserve the original refill-based match-three for optional Arcade Mode.
    locks.resize(64)
    locks.fill(0)
    seal_types.resize(64)
    seal_types.fill(0)
    current_relic=""
    for attempt in range(350):
        board.resize(ROWS * COLS)
        for row in range(ROWS):
            for col in range(COLS):
                var idx := row * COLS + col
                var options: Array[int] = [0, 1, 2, 3, 4, 5]
                if col >= 2 and board[idx - 1] == board[idx - 2]:
                    options.erase(board[idx - 1])
                if row >= 2 and board[idx - COLS] == board[idx - 2 * COLS]:
                    options.erase(board[idx - COLS])
                board[idx] = options.pick_random()
        if not _find_hint().is_empty():
            return
    push_warning("No playable starting arcade board generated.")

func _find_matches() -> Array[int]:
    return QuestRules.scan(board)

func _swap_values(a: int, b: int) -> void:
    var v := board[a]
    board[a] = board[b]
    board[b] = v

func _find_hint() -> Array[int]:
    var suggestion:=QuestRules.recommend_move(world_index,level,board,locks,seal_types,mode=="quest")
    if suggestion.x<0:return []
    return [suggestion.x,suggestion.y]

func _attempt_swap(a: int, b: int) -> void:
    if state != "playing" or a < 0 or b < 0 or not _adjacent(a, b):
        return
    if board[a] < 0 or board[b] < 0:
        status_message = "Obstacles and empty sockets cannot be swapped."
        return
    if locks.size()==64 and (locks[a]>0 or locks[b]>0):
        status_message="A locked gem must be freed by a neighboring match!"
        _play_sound("fail")
        return
    _swap_values(a, b)
    if _find_matches().is_empty():
        _swap_values(a, b)
        status_message = "That swap didn't make a match."
        if not save.pref("reduce_motion"):
            rejected_cells=[a,b]
            reject_age=0.0
        _reset_idle()
        return
    # Record the original board, not the already-swapped one.
    _swap_values(a, b)
    _push_undo()
    if not save.pref("reduce_motion"):
        swap_ghosts=[
            {"from":Vector2(a%COLS,int(a/COLS)),"to":Vector2(b%COLS,int(b/COLS)),"value":board[a],"target":b},
            {"from":Vector2(b%COLS,int(b/COLS)),"to":Vector2(a%COLS,int(a/COLS)),"value":board[b],"target":a}
        ]
        swap_age=0.0
    _swap_values(a, b)
    moves_used += 1
    if mode == "arcade":
        moves_left -= 1
    hint_cells.clear()
    _resolve()
    _finish_or_save()
    _reset_idle()
    queue_redraw()

func _resolve() -> void:
    var combo := 0
    var total := 0
    var points := 0
    for step in range(24):
        var hits := _find_matches()
        if hits.is_empty():
            break
        combo += 1
        total += hits.size()
        var gain := hits.size() * 65 * combo
        points += gain
        score += gain
        var hit_map := {}
        if not save.pref("reduce_motion"):
            impact_flash=1.0
        for idx in hits:
            hit_map[idx] = true
            if objective_type == "collect" and board[idx] == target_glyph:
                collected += 1
            if sparkles.size() < 350:
                _emit_fx(idx, GEM_COLORS[board[idx]])
            if impact_fx.size()<(40 if save.pref("low_effects") else 96):
                impact_fx.append({"pos":ORIGIN+Vector2((idx%COLS)*CELL+CELL*.5,int(idx/COLS)*CELL+CELL*.5),"life":.72,"color":GEM_COLORS[board[idx]],"tile":board[idx],"index":idx})
        var result: Dictionary = QuestRules.adjacent_obstacles(board,locks,hits,seal_types)
        for cracked in result["cracked"]:
            _emit_fx(int(cracked),GOLD)
        if not result["cracked"].is_empty():_play_sound("stone")
        for unlocked in result["unlocked"]:
            _emit_fx(int(unlocked),Color("#a5edff"))
        if not result["unlocked"].is_empty():_play_sound("seal")
        _start_fall_animation(hit_map)
        for idx in hits:
            board[idx] = QuestRules.EMPTY
        QuestRules.settle(board,locks,seal_types)
        if mode == "arcade":
            # The refill mechanic is exclusive to Arcade.
            for col in range(COLS):
                for row in range(ROWS):
                    var idx := row * COLS + col
                    if board[idx] == QuestRules.EMPTY:
                        board[idx] = randi_range(0, 5)
    if total > 0:
        status_message = ("%s COMBO!  " % combo if combo > 1 else "") + "+%s POINTS" % points
        popups.append({"text": "+%s" % points, "life": 1.0, "pos": Vector2(360, 735)})
        if combo > 1:
            popups.append({"text":"COMBO x%s!" % combo,"life":1.0,"pos":Vector2(360,790)})
            _play_sound("combo")
        else:
            _play_sound("match")
        _vibrate(22)
        save.data["lifetime_matches"] = int(save.data.get("lifetime_matches", 0)) + total

func _emit_fx(idx: int,clr: Color) -> void:
    if save.pref("reduce_motion"):
        return
    var center:=ORIGIN+Vector2((idx%COLS)*CELL+CELL*.5,int(idx/COLS)*CELL+CELL*.5)
    for j in range(4 if save.pref("low_effects") else 10):
        var angle:=randf()*TAU
        sparkles.append({
            "pos":center,"vel":Vector2(cos(angle),sin(angle))*randf_range(75,200),
            "life":randf_range(.35,.72),"color":clr
        })

func _hammer(idx: int) -> void:
    if state != "playing" or hammers_left <= 0 or idx < 0 or board[idx] < 0:
        status_message = "Select a real gem to break."
        return
    _push_undo()
    hammers_left -= 1
    if board[idx] == target_glyph and objective_type == "collect":
        collected += 1
    var old_color := board[idx]
    _emit_fx(idx, GEM_COLORS[old_color])
    board[idx] = QuestRules.EMPTY
    score += 75
    if locks.size()==64:locks[idx]=0
    if seal_types.size()==64:seal_types[idx]=0
    QuestRules.settle(board,locks,seal_types)
    boosters_used+=1
    if mode == "arcade":
        for row in range(ROWS):
            for col in range(COLS):
                var cell := row * COLS + col
                if board[cell] == QuestRules.EMPTY:
                    board[cell] = randi_range(0, 5)
    _resolve()
    status_message = "HAMMER SMASH! +75"
    _finish_or_save()
    queue_redraw()

func _shuffle() -> void:
    if state != "playing" or shuffles_left <= 0:
        status_message = "No shuffles remaining."
        return
    var positions: Array[int] = []
    var colors: Array[int] = []
    for idx in range(board.size()):
        if board[idx] >= 0 and (locks.is_empty() or locks[idx]==0):
            positions.append(idx)
            colors.append(board[idx])
    if positions.size() < 3:
        status_message = "Not enough gems to shuffle."
        return
    var original: Array[int] = board.duplicate()
    var new_board: Array[int] = original.duplicate()
    var found := false
    for attempt in range(120):
        colors.shuffle()
        for i in range(positions.size()):
            new_board[positions[i]] = colors[i]
        if QuestRules.scan(new_board).is_empty() and not QuestRules.legal_moves(new_board,locks).is_empty():
            found = true
            break
    if not found:
        status_message = "No safe shuffle found. Charge was not used."
        return
    _push_undo()
    board = new_board
    shuffles_left -= 1
    boosters_used+=1
    selected = -1
    hint_cells.clear()
    status_message = "Remaining gems rearranged. No new gems added!"
    _save_current()
    _reset_idle()
    queue_redraw()

func _show_hint() -> void:
    hint_cells = _find_hint()
    hint_until = Time.get_ticks_msec() + 2400
    status_message = "Swap the glowing gems!" if hint_cells.size() == 2 else "No matching moves remain."
    _reset_idle()

func _reset_idle() -> void:
    next_auto_hint_at = Time.get_ticks_msec() + 11000

func _finish_or_save() -> void:
    if mode == "quest":
        var left:=QuestRules.remaining(board)
        var stars:=QuestProgress.stars(start_gems,left)
        if left==0:
            _complete_quest()
        elif QuestRules.legal_moves(board,locks).is_empty():
            if stars>0:
                _complete_quest()
            elif not recovery_used:
                state="recovery"
                status_message="No legal matches remain. One FREE rescue is available."
                _save_current()
            else:
                state="failure"
                status_message="No matches left; less than 75% cleared."
                save.clear_current()
                _play_sound("fail")
        else:
            if stars>0:
                status_message="LEVEL QUALIFIED! Claim %s star(s) or keep playing." % stars
            _save_current()
        return
    var won := collected >= target_amount if objective_type == "collect" else score >= score_target
    if won:
        earned_stars = 1 + (1 if moves_left >= 5 else 0) + (1 if score >= score_target * 1.2 else 0)
        state = "victory"
        save.data["arcade_best"] = maxi(int(save.data.get("arcade_best", 0)), score)
        save.clear_current()
        _play_sound("win")
        _vibrate(70)
    elif moves_left <= 0:
        state = "failure"
        save.clear_current()
        _play_sound("fail")
    else:
        if _find_hint().is_empty():
            _create_board()
            status_message = "Arcade board refreshed."
        _save_current()

func _complete_quest() -> void:
    if mode!="quest" or state=="victory":
        return
    earned_stars=QuestProgress.stars(start_gems,QuestRules.remaining(board))
    if earned_stars==0:return
    state="victory"
    status_message="PERFECT CLEAR!" if earned_stars==3 else "LEVEL COMPLETE!"
    save.record_victory(world_index,level,score,earned_stars)
    victory_spark_age=1.2
    _play_sound("win")
    if level%3==0:_play_sound("relic")
    _vibrate(70)
    queue_redraw()

func _claim_qualified() -> void:
    if state=="playing" and mode=="quest" and QuestProgress.qualifies(start_gems,QuestRules.remaining(board)):
        _complete_quest()

func _free_recovery() -> void:
    if state!="recovery" or mode!="quest" or recovery_used:
        return
    recovery_used=true
    boosters_used+=1
    # Free, no ads, no gems purchased. Prefer reshuffle that creates a legal
    # match without introducing any new gems or changing sealed states.
    var candidate:=QuestRules.recovery_shuffle(board,locks)
    if not candidate.is_empty():
        board=candidate
        state="playing"
        status_message="FREE RESCUE! A new match is available."
        hint_cells.clear()
        _reset_idle()
        _save_current()
    else:
        # When no legal reshuffle exists (e.g. only pairs remain), remove
        # up to three existing gems. This never creates replacement gems.
        var removed:=0
        for idx in range(board.size()):
            if board[idx]>=0 and (locks.is_empty() or locks[idx]==0):
                board[idx]=QuestRules.EMPTY
                if locks.size()==64:locks[idx]=0
                if seal_types.size()==64:seal_types[idx]=0
                removed+=1
                if removed==3:break
        if removed<3:
            for idx in range(board.size()):
                if board[idx]>=0:
                    board[idx]=QuestRules.EMPTY
                    if locks.size()==64:locks[idx]=0
                    if seal_types.size()==64:seal_types[idx]=0
                    removed+=1
                    if removed==3:break
        QuestRules.settle(board,locks,seal_types)
        state="playing"
        status_message="FREE RESCUE removed %d gems." % removed
        _finish_or_save()
    queue_redraw()

func _skip_recovery() -> void:
    if state=="recovery":
        state="failure"
        status_message="Retry the puzzle for a better result."
        save.clear_current()

func _eligible_stars() -> int:
    if mode!="quest" or board.is_empty():return 0
    return QuestProgress.stars(start_gems,QuestRules.remaining(board))

func _vibrate(duration: int) -> void:
    if save.pref("haptics") and OS.has_feature("mobile"):
        Input.vibrate_handheld(duration)

func _play_sound(name: String) -> void:
    if save.pref("sfx") and sound_players.has(name):
        var player: AudioStreamPlayer = sound_players[name]
        player.volume_db = linear_to_db(maxf(0.001,float(save.setting_int("sfx_volume",85))/100.0)) - 2.0
        player.play()

func _music_state() -> void:
    if music_player == null or world_tracks.size()!=5:
        return
    var game_context:=state in ["playing","paused","victory","failure","recovery","tutorial"] or (state=="settings" and settings_return=="paused")
    var target_index:=world_index+1 if game_context else 0
    var volume_linear:=float(save.setting_int("music_volume",85))/100.0
    var target_db:=linear_to_db(maxf(.001,volume_linear))-2.0
    if not save.pref("music") or volume_linear<=0:
        music_player.stop()
        music_alt_player.stop()
        return
    if music_track_id!=target_index:
        var old_player: AudioStreamPlayer=music_player
        var new_player: AudioStreamPlayer=music_alt_player
        new_player.stop()
        new_player.stream=world_tracks[target_index]
        new_player.volume_db=-46.0
        new_player.play()
        music_player=new_player
        music_alt_player=old_player
        music_track_id=target_index
        var transition:=create_tween().set_parallel(true)
        transition.tween_property(new_player,"volume_db",target_db,.75)
        if old_player.playing:
            transition.tween_property(old_player,"volume_db",-48.0,.75)
        transition.set_parallel(false)
        transition.tween_callback(old_player.stop)
    else:
        music_player.volume_db=target_db
        if not music_player.playing:music_player.play()

func _start_arcade(w: int) -> void:
    mode = "arcade"
    _start_level(w, 1)


func _snapshot() -> Dictionary:
    return {
        "board": board.duplicate(),"locks":locks.duplicate(),"seal_types":seal_types.duplicate(),
        "boosters_used":boosters_used,
        "score": score, "moves": moves_left, "moves_used": moves_used,
        "collected": collected, "hints": hints_left,
        "shuffles": shuffles_left, "hammers": hammers_left
    }


func _push_undo() -> void:
    undo_history.append(_snapshot())
    if undo_history.size() > 3:
        undo_history.pop_front()


func _undo_last() -> void:
    if state != "playing":
        return
    if undo_left <= 0 or undo_history.is_empty():
        status_message = "No Undo charges or moves to restore."
        return
    var last: Dictionary = undo_history.pop_back()
    var restored: Array = last["board"]
    board.clear()
    for item in restored:
        board.append(int(item))
    locks.clear()
    for item in last.get("locks",[]):
        locks.append(int(item))
    if locks.size()!=64:locks.resize(64);locks.fill(0)
    seal_types.clear()
    for item in last.get("seal_types",[]):
        seal_types.append(int(item))
    if seal_types.size()!=64:seal_types.resize(64);seal_types.fill(0)
    boosters_used=int(last.get("boosters_used",0))
    score = int(last["score"])
    moves_left = int(last["moves"])
    moves_used = int(last["moves_used"])
    collected = int(last["collected"])
    hints_left = int(last["hints"])
    shuffles_left = int(last["shuffles"])
    hammers_left = int(last["hammers"])
    undo_left -= 1
    fall_ghosts.clear()
    fall_age = 1.0
    swap_ghosts.clear()
    swap_age=1.0
    impact_fx.clear()
    hint_cells.clear()
    hammer_mode = false
    status_message = "Last move restored. Choose carefully!"
    _reset_idle()
    _save_current()
    _play_sound("tap")
    queue_redraw()


func _start_fall_animation(hits: Dictionary) -> void:
    if save.pref("reduce_motion"):
        return
    # Animate surviving gems falling into their final sockets.
    fall_ghosts.clear()
    for col in range(COLS):
        var bottom := ROWS - 1
        while bottom >= 0:
            if board[bottom * COLS + col] in [QuestRules.WALL,QuestRules.CRACK]:
                bottom -= 1
                continue
            var top := bottom
            while top >= 0 and board[top * COLS + col] not in [QuestRules.WALL,QuestRules.CRACK]:
                top -= 1
            var active: Array[int] = []
            for row in range(top + 1, bottom + 1):
                var idx := row * COLS + col
                if board[idx] >= 0 and not hits.has(idx):
                    active.append(row)
            for k in range(active.size()):
                var from_row := active[k]
                var to_row := bottom - active.size() + k + 1
                if from_row != to_row:
                    fall_ghosts.append({
                        "from": Vector2(col, from_row),
                        "to": Vector2(col, to_row),
                        "value": board[from_row * COLS + col],
                        "target": to_row * COLS + col
                    })
            bottom = top - 1
    fall_age = 0.0 if not fall_ghosts.is_empty() else 1.0
    if not fall_ghosts.is_empty():_play_sound("land")


func _draw_nav_icons() -> void:
    # Minimal buttons are separated from the illustrated title.
    _rect(Rect2(14,65,63,59),Color("#352151"),12,Color("#ecc780"),3)
    draw_line(Vector2(25,93),Vector2(44,75),CREAM,4,true)
    draw_line(Vector2(44,75),Vector2(64,93),CREAM,4,true)
    draw_line(Vector2(31,91),Vector2(31,110),CREAM,3,true)
    draw_line(Vector2(56,91),Vector2(56,110),CREAM,3,true)
    draw_line(Vector2(31,110),Vector2(56,110),CREAM,3,true)
    _rect(Rect2(645,183,65,72),Color("#38204d"),15,Color("#efc983"),4)
    draw_line(Vector2(666,201),Vector2(666,236),CREAM,7,true)
    draw_line(Vector2(689,201),Vector2(689,236),CREAM,7,true)

func _draw_booster(index: int,count: int,label: String,key: String) -> void:
    var x:=12.0+float(index)*175.0
    _tex("booster_plate",Rect2(x,1165,164,156),Color.WHITE if count>0 else Color(.55,.55,.63,.8))
    _tex(key,Rect2(x+34,1177,98,91))
    _rect(Rect2(x+115,1180,38,34),Color("#281940"),15,GOLD,2)
    _label(str(count),x+134,1203,19,GOLD,true)
    _label(label,x+81,1303,18,CREAM,true,display_font)
    if index==2 and hammer_mode:
        _rect(Rect2(x+5,1170,154,145),Color.TRANSPARENT,18,Color("#b4fff9"),3)

func _draw_live_gem(rect: Rect2, tile: int, index: int) -> void:
    if tile < 0 or tile >= 6:
        return
    var gem: Texture2D = gems[tile]
    var colored := Color.WHITE
    # Small world-specific tint; preserve the original gem colors.
    var world_tints := [
        Color(0.96, 0.96, 1.0),
        Color(1.0, 0.95, 0.87),
        Color(0.92, 1.0, 0.96),
        Color(1.0, 0.94, 1.0)
    ]
    colored = world_tints[world_index]
    if gem != null:
        draw_texture_rect(gem, rect, false, colored)
    else:
        _rect(rect, GEM_COLORS[tile], 12)
    # Avoid unreadable small numbers in the normal view.
    var glyph: String = SYMBOLS[world_index][tile]
    _label(glyph, rect.get_center().x, rect.position.y + 50, 41, Color("#fff9ec"), true, _glyph_font(tile))
    if save.pref("color_assist"):
        _label(str(tile + 1), rect.position.x + rect.size.x - 13, rect.position.y + 18, 14, Color("#ffedac"), true)
    if save.pref("gem_shimmer") and not save.pref("reduce_motion") and not save.pref("low_effects"):
        var shimmer:=pow(maxf(0.0,sin(clock*.95+float(index)*2.37)),9)
        if shimmer>.12:
            draw_line(rect.position+Vector2(12,15),rect.position+Vector2(rect.size.x*.55,15),
                Color(1,.96,.88,shimmer*.43),2.0,true)
            draw_arc(rect.get_center(),rect.size.x*.43,-.75,.25,18,
                Color(1,.92,1,shimmer*.34),2.0,true)


func _draw_seal(rect: Rect2,idx: int) -> void:
    var kind: int=seal_types[idx] if seal_types.size()==64 else 1
    if kind==3:
        # Frozen rune: solid frosted blue overlay + crystalline fractures.
        _rect(rect.grow(-4),Color(.45,.88,1,.27),13,Color(.75,.96,1,.85),3)
        draw_line(rect.position+Vector2(11,10),rect.get_center(),Color(.8,1,1,.75),3,true)
        draw_line(rect.get_center(),rect.end-Vector2(10,14),Color(.8,1,1,.75),2,true)
    elif kind==2:
        # Two-hit chain: crossing gold runic bindings, plus remaining charge.
        draw_line(rect.position+Vector2(12,10),rect.end-Vector2(12,10),GOLD,5,true)
        draw_line(rect.position+Vector2(12,rect.size.y-10),rect.position+Vector2(rect.size.x-12,10),GOLD,4,true)
        _label(str(locks[idx]),rect.end.x-12,rect.position.y+25,18,GOLD,true)
    else:
        _tex("lock",rect)

func _draw_collection() -> void:
    _title("RELIC COLLECTION","Restore each world by completing its quests")
    _button(Rect2(48,225,154,64),"BACK")
    for w in range(4):
        var xx:=47+w*158
        _button(Rect2(xx,320,146,72),WORLD_SHORT[w],album_world==w,18)
    _panel(Rect2(40,422,640,785),Color("#2c2048"),true)
    _fancy(WORLD_NAMES[album_world],360,505,29)
    var stage: int=save.world_stage(album_world)
    _label("WORLD RESTORATION: %s / 4" % stage,360,558,23,CREAM,true)
    _rect(Rect2(100,578,520,18),Color("#322745"),8)
    _rect(Rect2(100,578,130.0*stage,18),Color("#4adbef"),8)
    for i in range(4):
        var xx:=88+(i%2)*284
        var yy:=635+int(i/2)*242
        var owned: bool=save.has_relic(album_world,i)
        var tint:=Color.WHITE if owned else Color(.2,.18,.32,.7)
        _tex("relic_%d_%d" % [album_world,i],Rect2(xx,yy,190,176),tint)
        var entries: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels_v06.json")).get("relics",[])
        var title: String=str(entries[album_world][i]) if entries.size()>album_world else "ANCIENT RELIC"
        _label(title if owned else "MISSING RELIC",xx+93,yy+193,17,GOLD if owned else MUTED,true)
        _label("COMPLETE LEVEL %s" % ((i+1)*3),xx+93,yy+217,16,CREAM,true)
    _label("RELICS: %s / 16  •  COMPLETION RESTORES THE WORLD" % save.relic_total(),360,1314,18,GOLD,true)

func _draw_portrait_tablet_game() -> void:
    _draw_logo(180,14,540,161)
    _rect(Rect2(15,98,82,72),Color("#302046"),13,GOLD,3)
    _label("HOME",56,145,18,CREAM,true)
    _rect(Rect2(803,187,82,72),Color("#302046"),13,GOLD,3)
    _label("II",844,241,35,CREAM,true)
    _tex("medallion",Rect2(33,190,194,88))
    _tex("ribbon",Rect2(238,191,413,77))
    _tex("medallion",Rect2(662,190,134,88))
    _label("SCORE",130,215,19,GOLD,true)
    _fancy(str(score),130,262,33)
    _label("MOVES",728,215,19,GOLD,true)
    _fancy(str(moves_used) if mode=="quest" else str(moves_left),728,262,32)
    _label("LEVEL %s • %s" % [level,WORLD_SHORT[world_index]],448,246,24,INK,true,display_font)
    _tex("parchment",Rect2(30,299,840,104))
    var amount:=start_gems-QuestRules.remaining(board) if mode=="quest" else score
    var goal:=start_gems if mode=="quest" else score_target
    _label("CLEAR 75% TO PASS" if mode=="quest" else "ARCADE OBJECTIVE",177,347,25,INK,false,display_font)
    _rect(Rect2(195,357,481,20),Color("#4e4356"),9)
    _rect(Rect2(195,357,maxf(4,481.0*float(amount)/maxf(1.0,float(goal))),20),Color("#43d4f3"),9)
    _label("%s / %s" % [amount,goal],764,378,23,INK,true)
    _tex("board_frame",Rect2(24,376,854,844))
    _tex("mural_%d" % world_index,Rect2(ORIGIN,CELL*Vector2(8,8)),Color(1,1,1,.63))
    _draw_tiles()
    _label(status_message,450,1223,21,CREAM,true)
    for i in range(4):
        var x:=27+i*215
        _tex("booster_plate",Rect2(x,1240,198,149))
        _tex(["booster_0","booster_2","booster_1","undo"][i],Rect2(x+49,1248,100,89))
        _label(str([hints_left,shuffles_left,hammers_left,undo_left][i]),x+172,1274,20,GOLD,true)
        _label(["HINT","SHUFFLE","HAMMER","UNDO"][i],x+99,1373,18,CREAM,true,display_font)
    if state=="playing" and _eligible_stars()>0:
        _button(Rect2(263,1391,374,46),"CLAIM %s ★ NOW" % _eligible_stars(),true,19)
    _draw_fx()

func _draw_portrait_tablet_overlay()->void:
    _rect(Rect2(0,0,900,1440),Color(.02,.01,.07,.75),0)
    _panel(Rect2(111,390,678,624),Color("#37214c"),true)
    _fancy("QUEST PAUSED" if state=="paused" else "PERFECT CLEAR" if state=="victory" else "NO MOVES LEFT" if state=="failure" else "HOW TO PLAY",450,482,40)
    if state=="paused":
        _button(Rect2(200,564,500,85),"RESUME",true,28)
        _button(Rect2(200,693,500,85),"SETTINGS")
        _button(Rect2(200,823,500,85),"SAVE & HOME")
    elif state=="tutorial":
        _label("MATCH THREE GEMS • NO REFILLS",450,608,22,CREAM,true)
        _label("CLEAR 75% TO PASS, 85% FOR 2 ★, ALL FOR 3 ★",450,675,18,GOLD,true)
        _button(Rect2(200,822,500,84),"LET'S PLAY!",true,27)
    elif state=="recovery":
        _fancy("FREE RESCUE AVAILABLE",450,527,30)
        _label("CLEAR RATE: %.0f%%  •  TARGET: 75%%" % QuestProgress.clear_rate(start_gems,QuestRules.remaining(board)),450,630,22,CREAM,true)
        _button(Rect2(200,733,500,84),"FREE RESCUE",true,28)
        _button(Rect2(200,853,500,84),"RETRY LEVEL")
    else:
        _label("GEMS REMOVED: %s / %s" % [start_gems-QuestRules.remaining(board),start_gems],450,614,24,GOLD,true)
        _button(Rect2(200,733,500,84),"NEXT LEVEL" if state=="victory" else "RETRY",true,28)
        _button(Rect2(200,853,500,84),"HOME")

func _gesture_portrait_tablet(start:Vector2,p:Vector2)->void:
    if state=="playing":
        if mode=="quest" and _eligible_stars()>0 and _inside(p,263,1391,374,46):
            _claim_qualified()
            return
        if _inside(p,15,98,82,72):_save_current();state="menu";return
        if _inside(p,803,187,82,72):_save_current();state="paused";return
        for i in range(4):
            if _inside(p,27+i*215,1240,198,149):
                match i:
                    0:
                        if hints_left>0:
                            hints_left-=1
                            boosters_used+=1
                            _show_hint()
                            _save_current()
                    1:_shuffle()
                    2:hammer_mode=not hammer_mode
                    3:_undo_last()
                return
        _tablet_touch_board(start,p)
    elif state=="paused":
        if _inside(p,200,564,500,85):state="playing"
        elif _inside(p,200,693,500,85):settings_return="paused";state="settings"
        elif _inside(p,200,823,500,85):_save_current();state="menu"
    elif state=="tutorial":
        if _inside(p,200,822,500,84):
            save.data["tutorial_done_v06"]=true
            save.mark_tutorial()
            state="playing"
            _save_current()
    elif state=="recovery":
        if _inside(p,200,733,500,84):_free_recovery()
        elif _inside(p,200,853,500,84):_start_level(world_index,level)
    elif state in ["victory","failure"]:
        if _inside(p,200,733,500,84):
            if mode=="arcade":_start_arcade(world_index)
            elif state=="victory":_start_level(world_index,mini(12,level+1))
            else:_start_level(world_index,level)
        elif _inside(p,200,853,500,84):state="menu"

func _draw_tablet_game() -> void:
    _tex("board_frame",Rect2(17,111,679,697))
    _tex("mural_%d" % world_index,Rect2(ORIGIN,Vector2(CELL*8,CELL*8)),Color(1,1,1,.62))
    _draw_tiles()
    # Landscape HUD independent from board scale, with a usable right column.
    _draw_logo(855,7,600,188)
    _rect(Rect2(705,121,88,69),Color("#352151"),12,GOLD,3)
    _label("HOME",749,165,19,CREAM,true)
    _rect(Rect2(1470,124,87,69),Color("#352151"),12,GOLD,3)
    _label("II",1514,166,28,CREAM,true)
    _tex("ribbon",Rect2(825,198,611,78))
    _label("LEVEL %s  •  %s" % [level,WORLD_SHORT[world_index]] if mode=="quest" else "ARCADE  •  %s" % WORLD_SHORT[world_index],1136,248,26,INK,true,display_font)
    _tex("medallion",Rect2(799,289,282,90))
    _tex("medallion",Rect2(1152,289,282,90))
    _label("SCORE",940,317,19,CREAM,true)
    _fancy(str(score),940,356,32)
    _label("MOVES",1290,317,19,CREAM,true)
    _fancy(str(moves_used) if mode=="quest" else str(moves_left),1290,356,32)
    _tex("parchment",Rect2(803,387,638,137))
    _label("CLEAR 75% TO PASS" if mode=="quest" else "ARCADE OBJECTIVE",1119,441,27,INK,true,display_font)
    var amount:=start_gems-QuestRules.remaining(board) if mode=="quest" else score
    var target:=start_gems if mode=="quest" else score_target
    _rect(Rect2(885,466,397,21),Color("#3b3852"),12)
    _rect(Rect2(885,466,maxf(4.0,397.0*float(amount)/maxf(1.0,float(target))),21),Color("#41d7f3"),12)
    _label("%s / %s" % [amount,target],1373,484,20,INK,true)
    _label(status_message,1159,577,19,CREAM,true)
    for i in range(4):
        var bx:=801+(i%4)*174
        _tex("booster_plate",Rect2(bx,630,159,167))
        var key: String=["booster_0","booster_2","booster_1","undo"][i]
        var count: int=[hints_left,shuffles_left,hammers_left,undo_left][i]
        _tex(key,Rect2(bx+33,640,95,94),Color.WHITE if count>0 else Color(.5,.5,.5,.85))
        _label(str(count),bx+138,666,22,GOLD,true)
        _label(["HINT","SHUFFLE","HAMMER","UNDO"][i],bx+79,777,16,CREAM,true)
    if state=="playing" and _eligible_stars()>0:
        _button(Rect2(952,813,383,69),"CLAIM %s ★ NOW" % _eligible_stars(),true,25)
    else:
        _label("WORLD RESTORED: %s / 4   •   RELICS: %s / 16" % [save.world_stage(world_index),save.relic_total()],1120,858,19,GOLD,true)
    _draw_fx()

func _draw_tablet_menu() -> void:
    _draw_logo(490,12,620,200)
    _label("MATCH. DISCOVER. AWAKEN.",800,223,23,GOLD,true,display_font)
    _fancy("CHOOSE YOUR WORLD",800,274,32)
    for i in range(4):
        var xx:=50+i*384
        _panel(Rect2(xx,305,356,323),Color("#392551") if i==world_index else Color("#261b45"),true)
        _tex("world_%d" % i,Rect2(xx+42,337,269,191))
        _fancy(WORLD_SHORT[i],xx+178,567,26)
        _label("LEVEL %s/12 • RESTORED %s/4" % [save.unlocked_level(i),save.world_stage(i)],xx+178,603,17,CREAM,true)
    _button(Rect2(390,664,400,67),"QUEST MODE",mode=="quest",26)
    _button(Rect2(818,664,400,67),"ARCADE MODE",mode=="arcade",26)
    _button(Rect2(384,748,834,78),"CONTINUE ADVENTURE",true,33)
    _button(Rect2(57,820,350,63),"LEVELS",false,22)
    _button(Rect2(431,820,350,63),"SETTINGS",false,22)
    _button(Rect2(805,820,350,63),"PROGRESS",false,22)
    _button(Rect2(1178,820,350,63),"RELICS",false,22)

func _draw_tablet_levels() -> void:
    _title("CHOOSE A LEVEL",WORLD_SHORT[world_index])
    _button(Rect2(40,28,200,72),"BACK",false,24)
    for lvl in range(1,13):
        var xx:=275+((lvl-1)%6)*206
        var yy:=190+int((lvl-1)/6)*280
        var unlocked:=lvl<=save.unlocked_level(world_index)
        _panel(Rect2(xx,yy,180,215),Color("#402a62") if unlocked else Color("#272039"),true)
        _fancy(str(lvl),xx+90,yy+116,56)
        _label("★".repeat(int(save.best_result(world_index,lvl).get("stars",0))) if unlocked else "LOCKED",xx+90,yy+174,19,GOLD,true)

func _draw_tablet_collection() -> void:
    _fancy("THE RELIC COLLECTION",800,82,48)
    _button(Rect2(50,30,200,75),"BACK")
    for w in range(4):
        _button(Rect2(360+w*288,129,269,72),WORLD_SHORT[w],w==album_world,20)
    _label("WORLD RESTORATION: %s / 4" % save.world_stage(album_world),800,254,30,GOLD,true)
    for i in range(4):
        var xx:=125+i*375
        var owned:=save.has_relic(album_world,i)
        _tex("relic_%d_%d" % [album_world,i],Rect2(xx,324,305,315),Color.WHITE if owned else Color(.3,.3,.4,.75))
        _label("RESTORED" if owned else "LOCKED",xx+153,685,25,GOLD if owned else MUTED,true)
        _label("LEVEL %s" % ((i+1)*3),xx+153,736,22,CREAM,true)

func _draw_tablet_progress() -> void:
    _fancy("YOUR ADVENTURE",800,93,47)
    _button(Rect2(50,30,200,75),"BACK")
    for w in range(4):
        var x:=80+w*375
        _tex("world_%d" % w,Rect2(x,240,308,280))
        _fancy(WORLD_SHORT[w],x+153,569,26)
        _label("LEVEL %s / 12" % save.unlocked_level(w),x+153,615,21,CREAM,true)
        _label("RESTORATION %s / 4" % save.world_stage(w),x+153,666,20,GOLD,true)
    _label("TOTAL STARS: %s     •     RELICS: %s / 16" % [save.total_stars(),save.relic_total()],800,808,30,GOLD,true)

func _draw_tablet_settings() -> void:
    _fancy("SETTINGS",800,85,49)
    _button(Rect2(50,26,205,75),"BACK")
    var keys:=["music","sfx","haptics","reduce_motion","color_assist","auto_hints","large_text",
    "ambient_motion","gem_shimmer","reactive_light","screen_shake","low_effects"]
    var labels:=["MUSIC","SOUND EFFECTS","VIBRATION","REDUCE MOTION","HIGH CONTRAST","AUTO HINTS","LARGE TEXT",
    "AMBIENT MOTION","GEM SHIMMER","REACTIVE LIGHT","SCREEN SHAKE","LOW EFFECTS"]
    for i in range(keys.size()):
        var x:=110+int(i/6)*720
        var y:=168+(i%6)*111
        _panel(Rect2(x,y,665,92),Color("#33214d"),false)
        _label(labels[i],x+31,y+56,22,CREAM)
        _rect(Rect2(x+522,y+17,119,61),Color("#396c59") if save.pref(keys[i]) else Color("#4c3450"),17,GOLD,2)
        _label("ON" if save.pref(keys[i]) else "OFF",x+582,y+56,21,CREAM,true)
    _label("MUSIC VOLUME: %s%%       EFFECTS VOLUME: %s%%" % [save.setting_int("music_volume"),save.setting_int("sfx_volume")],800,864,22,GOLD,true)

func _draw_tablet_overlay() -> void:
    _rect(Rect2(0,0,1600,900),Color(.02,.01,.07,.78),0)
    _panel(Rect2(457,107,686,705),Color("#32214c"),true)
    if state=="paused":
        _fancy("QUEST PAUSED",800,214,45)
        _button(Rect2(555,270,490,92),"RESUME",true,31)
        _button(Rect2(555,391,490,92),"SETTINGS",false,29)
        _button(Rect2(555,512,490,92),"SAVE & HOME",false,29)
    elif state=="tutorial":
        _fancy("HOW TO PLAY",800,214,41)
        _label("MATCH THREE. CLEAR 75% TO PASS.",800,310,25,CREAM,true)
        _label("85% = 2 ★  •  100% = 3 ★",800,367,24,GOLD,true)
        _label("WATCH FOR CRACKED STONES AND SEALED GEMS.",800,423,21,CREAM,true)
        _button(Rect2(560,548,480,93),"BEGIN QUEST",true,29)
    elif state=="recovery":
        _fancy("ONE FREE RESCUE",800,215,43)
        _label("NO LEGAL MATCHES REMAIN",800,302,25,CREAM,true)
        _label("CLEAR RATE: %.0f%%  •  TARGET: 75%%" % QuestProgress.clear_rate(start_gems,QuestRules.remaining(board)),800,380,23,GOLD,true)
        _button(Rect2(550,438,500,88),"FREE RESCUE",true,29)
        _button(Rect2(550,547,500,88),"RETRY",false,26)
    else:
        _fancy("PERFECT CLEAR!" if earned_stars==3 else "LEVEL COMPLETE!" if state=="victory" else "NO MATCHES LEFT",800,215,39)
        _label("★".repeat(earned_stars) if state=="victory" else "TRY AGAIN",800,302,48,GOLD,true)
        _label("CLEAR RATE: %.0f%%" % QuestProgress.clear_rate(start_gems,QuestRules.remaining(board)) if mode=="quest" else "SCORE: %s" % score,800,380,23,CREAM,true)
        _button(Rect2(550,438,500,88),"NEXT LEVEL" if state=="victory" else "RETRY",true,29)
        _button(Rect2(550,547,500,88),"HOME",false,26)

func _gesture_tablet(start:Vector2,p:Vector2) -> void:
    match state:
        "menu":
            for i in range(4):
                if _inside(p,50+i*384,305,356,323):
                    world_index=i
                    return
            if _inside(p,390,664,400,67):
                mode="quest";save.data["mode"]=mode;save.save_all()
            elif _inside(p,818,664,400,67):
                mode="arcade";save.data["mode"]=mode;save.save_all()
            elif _inside(p,384,748,834,78):
                var current:Dictionary=save.data.get("current",{})
                if current.get("mode","")==mode and int(current.get("world",-1))==world_index and _resume_saved():
                    return
                _start_level(world_index,save.unlocked_level(world_index) if mode=="quest" else 1)
            elif _inside(p,57,820,350,63):
                state="levels"
            elif _inside(p,431,820,350,63):
                settings_return="menu";state="settings"
            elif _inside(p,805,820,350,63):
                state="progress"
            elif _inside(p,1178,820,350,63):
                album_world=world_index;state="collection"
        "playing":
            if mode=="quest" and _eligible_stars()>0 and _inside(p,952,813,383,69):
                _claim_qualified()
                return
            if _inside(p,705,121,88,69):
                _save_current();state="menu";return
            if _inside(p,1470,124,87,69):
                _save_current();state="paused";return
            for i in range(4):
                if _inside(p,801+i*174,630,159,167):
                    match i:
                        0:
                            if hints_left>0:
                                hints_left-=1;boosters_used+=1;_show_hint();_save_current()
                        1:_shuffle()
                        2:
                            hammer_mode=not hammer_mode
                            status_message="Select a gem to smash" if hammer_mode else "Hammer cancelled"
                        3:_undo_last()
                    return
            _tablet_touch_board(start,p)
        "recovery":
            if _inside(p,550,438,500,88):_free_recovery()
            elif _inside(p,550,547,500,88):_start_level(world_index,level)
        "paused":
            if _inside(p,555,270,490,92):state="playing"
            elif _inside(p,555,391,490,92):settings_return="paused";state="settings"
            elif _inside(p,555,512,490,92):_save_current();state="menu"
        "victory","failure":
            if _inside(p,550,438,500,88):
                if mode=="arcade":_start_arcade(world_index)
                elif state=="victory":_start_level(world_index,mini(12,level+1))
                else:_start_level(world_index,level)
            elif _inside(p,550,547,500,88):state="menu"
        "tutorial":
            if _inside(p,560,548,480,93):
                save.data["tutorial_done_v06"]=true
                save.mark_tutorial()
                state="playing"
                _save_current()
        "levels":
            if _inside(p,40,28,200,72):state="menu";return
            for i in range(12):
                var xx:=275+(i%6)*206
                var yy:=190+int(i/6)*280
                if _inside(p,xx,yy,180,215) and i+1<=save.unlocked_level(world_index):
                    _start_level(world_index,i+1);return
        "collection":
            if _inside(p,50,30,200,75):state="menu"
            else:
                for w in range(4):
                    if _inside(p,360+w*288,129,269,72):album_world=w
        "progress":
            if _inside(p,50,30,200,75):state="menu"
        "settings","settings_fx":
            if _inside(p,50,26,205,75):
                state=settings_return
            else:
                var keys:=["music","sfx","haptics","reduce_motion","color_assist","auto_hints","large_text",
                    "ambient_motion","gem_shimmer","reactive_light","screen_shake","low_effects"]
                for i in range(keys.size()):
                    var x:=110+int(i/6)*720
                    var y:=168+(i%6)*111
                    if _inside(p,x,y,665,92):
                        save.toggle_pref(keys[i]);return
        "reset_confirm":
            state="settings"

func _tablet_touch_board(start:Vector2,p:Vector2) -> void:
    if fall_age<.26:return
    var first:=_board_index(start)
    if first<0:return
    if hammer_mode:
        hammer_mode=false
        _hammer(first)
        return
    var second:=_board_index(p)
    var delta:=p-start
    if delta.length()>=25 and (second==first or second<0):
        if absf(delta.x)>absf(delta.y):
            second=_neighbor(first,1 if delta.x>0 else -1,0)
        else:
            second=_neighbor(first,0,1 if delta.y>0 else -1)
    if second>=0 and second!=first and _adjacent(first,second):
        selected=-1;_attempt_swap(first,second)
    elif selected>=0 and selected!=first and _adjacent(selected,first):
        _attempt_swap(selected,first);selected=-1
    else:selected=-1 if selected==first else first

func _draw_effects_settings() -> void:
    _title("MAGICAL EFFECTS","Choose how much motion and lighting you want")
    _button(Rect2(48,223,154,67),"BACK")
    _panel(Rect2(53,310,614,835),Color("#312348"),true)
    var keys:=["ambient_motion","gem_shimmer","reactive_light","screen_shake","low_effects"]
    var labels:=["AMBIENT WORLD MOTION","GEMSTONE SHIMMER","MATCH REACTIVE LIGHT","SCREEN SHAKE","LOW EFFECTS PROFILE"]
    for i in range(keys.size()):
        var yy:=370+i*135
        _label(labels[i],83,yy,21,CREAM)
        _rect(Rect2(503,yy-38,121,56),Color("#396c59") if save.pref(keys[i]) else Color("#513551"),16,GOLD,2)
        _label("ON" if save.pref(keys[i]) else "OFF",563,yy-1,22,CREAM,true)
        draw_line(Vector2(84,yy+51),Vector2(623,yy+51),Color("#97749f"),1)
    _label("Reduce Motion overrides extra animation.",360,1072,19,GOLD,true)

func _touch_effects_settings(p:Vector2) -> void:
    if _inside(p,48,223,154,67):
        state="settings";return
    var keys:=["ambient_motion","gem_shimmer","reactive_light","screen_shake","low_effects"]
    for i in range(keys.size()):
        if _inside(p,75,326+i*135,565,101):
            save.toggle_pref(keys[i]);return
