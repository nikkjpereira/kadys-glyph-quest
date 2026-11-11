extends Node2D
## Kady's Glyph Quest v0.2: storybook UI, level objectives, saves and effects.
## Keep play fully functional offline. No ads or billing in test releases.

const SaveData = preload("res://scripts/save_data.gd")
const Brand = preload("res://scripts/brand_config.gd")
const COLS := 8
const ROWS := 8
const CELL := 78.0
const ORIGIN := Vector2(47, 481)
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
var level := 1
var board: Array[int] = []
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
    art["board_frame"] = load("res://assets/v03/board_gold_frame.png") as Texture2D
    for i in range(4):
        art["world_%d" % i] = load("res://assets/v03/world_%d.png" % i) as Texture2D
    for i in range(3):
        art["booster_%d" % i] = load("res://assets/v03/booster_%d.png" % i) as Texture2D
    for item in ["tap", "match", "win", "fail"]:
        var player := AudioStreamPlayer.new()
        player.stream = load("res://assets/audio/" + item + ".wav")
        player.volume_db = -7
        add_child(player)
        sound_players[item] = player
    music_player = AudioStreamPlayer.new()
    var ambience := load("res://assets/audio/enchanted_library.ogg")
    if ambience is AudioStreamOggVorbis:
        ambience.loop = true
    music_player.stream = ambience
    music_player.volume_db = -4
    add_child(music_player)
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
    var tick := int(clock * 17.0)
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

func _scale() -> Vector2:
    var s := get_viewport_rect().size
    if s.x <= 0 or s.y <= 0:
        return Vector2.ONE
    return Vector2(s.x / BASE_SIZE.x, s.y / BASE_SIZE.y)

func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0.0, _scale())
    _background()
    match state:
        "menu":
            _draw_menu()
        "levels":
            _draw_levels()
        "settings":
            _draw_settings()
        "progress":
            _draw_progress()
        "playing", "paused", "victory", "failure", "tutorial":
            _draw_game()
            if state == "paused":
                _draw_pause()
            elif state == "victory":
                _draw_result(true)
            elif state == "failure":
                _draw_result(false)
            elif state == "tutorial":
                _draw_tutorial()
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
        draw_texture_rect(tex, Rect2(0, 0, 720, 1440), false)
    else:
        draw_rect(Rect2(0, 0, 720, 1440), NAVY)
    draw_rect(Rect2(0, 0, 720, 1440), Color(0.03, 0.007, 0.05, 0.19))
    # Lightweight atmospheric dust, warm lens glow and cold rune shimmer.
    for i in range(34):
        var pos := Vector2(11.0 + fposmod(float(i * 211 + 71), 698.0), 22.0 + fposmod(float(i * 293 + 47), 1388.0))
        var movement := Vector2(sin(clock * 0.31 + float(i)) * 4.5, -fposmod(clock * float(3+i%4), 140.0))
        var alpha := 0.14 + 0.16 * (0.5 + 0.5*sin(clock * 1.8 + float(i)))
        draw_circle(pos + movement, 1.0 + float(i % 3) * 0.6, Color(1.0, 0.88, 0.56, alpha))

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
    _tex("title", Rect2(x,y,w,h))
    _fancy(Brand.TITLE_LINE_1,x+w*0.50,y+h*0.47,int(h*0.27))
    _fancy(Brand.TITLE_LINE_2,x+w*0.50,y+h*0.72,int(h*0.23))

func _draw_menu() -> void:
    _draw_logo(28,65,664,238)
    _panel(Rect2(52,329,616,318),Color("#2e1d4b"),true,0.92)
    _tex("world_%d" % world_index, Rect2(380,374,267,250),Color(1,1,1,0.89))
    _rect(Rect2(370,372,20,258),Color(0.06,0.03,0.13,0.55),4)
    _label("CURRENT ADVENTURE",242,379,22,GOLD,true)
    _label(_world_symbol(world_index),221,478,82,CREAM,true,_world_font(world_index))
    _fancy(WORLD_SHORT[world_index],239,522,27)
    _label("LEVEL %s / %s" % [save.unlocked_level(world_index),LEVEL_COUNT],238,569,22,CREAM,true)
    _label("THE JOURNEY AWAITS",236,607,17,MUTED,true)
    _button(Rect2(57,431,70,63),"<",false,29)
    _button(Rect2(593,431,70,63),">",false,29)
    var active: Dictionary = save.data.get("current",{})
    _button(Rect2(54,673,612,84),"CONTINUE JOURNEY" if not active.is_empty() else "BEGIN ADVENTURE",true,32)
    _fancy("CHOOSE YOUR WORLD",360,801,27)
    for i in range(4):
        var xx := 51 + (i % 2) * 314
        var yy := 829 + int(i / 2) * 112
        _tex("world_%d" % i,Rect2(xx+5,yy+5,100,84))
        _panel(Rect2(xx,yy,300,95),Color("#3d255a") if world_index==i else Color("#2b1b44"),false,0.12)
        _label(WORLD_SHORT[i],xx+199,yy+41,22,GOLD if i==world_index else CREAM,true)
        _label("LEVEL %s / %s" % [save.unlocked_level(i),LEVEL_COUNT],xx+199,yy+70,17,MUTED,true)
    _button(Rect2(53,1081,613,68),"CHOOSE A LEVEL",false,25)
    _button(Rect2(52,1173,299,73),"SETTINGS",false,25)
    _button(Rect2(369,1173,299,73),"PROGRESS",false,25)
    _label("STORYBOOK EDITION  •  v0.3.0",360,1343,17,CREAM,true)

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
    _label("NO LOGIN. YOUR ADVENTURE SAVES OFFLINE.",360,1163,18,CREAM,true)

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
    _button(Rect2(79,1107,559,73),"RESET SAVED PROGRESS",false,24)
    _label("Progress and settings are saved automatically.",360,1261,19,CREAM,true)
    _label("Ads and purchases are disabled in this test version.",360,1307,17,MUTED,true)

func _draw_game() -> void:
    _draw_logo(170,12,380,143)
    _tex("medallion",Rect2(24,166,201,103))
    _tex("medallion",Rect2(263,166,194,103))
    _tex("medallion",Rect2(495,166,202,103))
    _label("SCORE",126,195,17,GOLD,true)
    _fancy(str(score),126,250,39)
    _label("LEVEL",360,195,17,GOLD,true)
    _fancy(str(level),360,249,39)
    _label("MOVES",596,195,17,GOLD,true)
    _fancy(str(moves_left),596,249,39)
    _tex("ribbon", Rect2(59,282,602,61))
    _label("LEVEL %s  •  %s" % [level,WORLD_TAGLINES[world_index]],360,323,22,INK,true,display_font)
    _tex("parchment",Rect2(33,355,654,112))
    var goal := ""
    var amount := 0
    var wanted := 0
    if objective_type == "collect":
        goal = "COLLECT %s GLYPHS" % target_amount
        amount = collected
        wanted = target_amount
    else:
        goal = "REACH %s POINTS" % score_target
        amount = score
        wanted = score_target
    _label(goal,148,393,26,INK,false,display_font)
    _label("%s / %s" % [mini(amount,wanted),wanted],590,437,25,INK,true,display_font)
    _rect(Rect2(145,415,323,21),Color("#59475e"),11)
    _rect(Rect2(145,415,maxf(3,323.0*minf(1,float(amount)/maxf(1,float(wanted)))),21),Color("#46cfee"),11)
    draw_line(Vector2(153,419),Vector2(462,419),Color(1,1,1,0.27),2,true)
    if objective_type == "collect":
        _label(SYMBOLS[world_index][target_glyph],96,432,53,INK,true,_glyph_font(target_glyph))
    else:
        _label("★",96,429,48,Color("#a46a20"),true)
    # Dark inset board and original-render inspired gold/stone rim.
    _rect(Rect2(31,473,659,655),Color("#0d152e"),24,Color("#3c628a"),4)
    for row in range(ROWS):
        for col in range(COLS):
            var idx := row*COLS+col
            var xx := ORIGIN.x+float(col)*CELL
            var yy := ORIGIN.y+float(row)*CELL
            var tile := board[idx]
            var r := Rect2(xx+1,yy+1,76,76)
            if hint_cells.has(idx):
                _rect(r.grow(5),Color("#bcefff"),11)
                draw_arc(r.get_center(),38,0,TAU,36,Color(0.81,0.97,1.0,0.68+0.22*sin(clock*9)),4.0,true)
            elif selected==idx:
                _rect(r.grow(5),GOLD,13)
            if tile>=0 and tile<6:
                var gem: Texture2D = gems[tile]
                if gem != null:
                    draw_texture_rect(gem,r,false)
                else:
                    _rect(r,GEM_COLORS[tile],15)
                var glyph: String = SYMBOLS[world_index][tile]
                _label(glyph,r.get_center().x,r.position.y+56,48,Color("#fff9ed"),true,_glyph_font(tile))
                if save.pref("color_assist"):
                    _label(str(tile+1),xx+67,yy+19,14,Color("#ffea9a"),true)
    _tex("board_frame", Rect2(19,471,682,664))
    # Animated lilac combo flares do not obstruct touch targets.
    _label(status_message,360,1168,21,CREAM,true)
    for i in range(3):
        var bx := 40+i*225
        _tex("booster_%d" % i,Rect2(bx+31,1196,130,98))
        _label(str([hints_left,shuffles_left,hammers_left][i]),bx+162,1288,28,GOLD,true,display_font)
    _button(Rect2(217,1320,286,66),"PAUSE",false,25)
    _draw_fx()

func _draw_fx() -> void:
    for p in sparkles:
        var life: float = p["life"]
        var tint: Color = p["color"]
        tint.a = clampf(life/0.6,0,1)
        var pos: Vector2 = p["pos"]
        _tex("spark",Rect2(pos-Vector2(20,20),Vector2(40,40)),tint)
    for p in popups:
        var life: float = p["life"]
        var pos: Vector2 = p["pos"]
        _fancy(str(p["text"]),pos.x,pos.y+(1-life)*(-58),37)

func _modal(dim: float = 0.77) -> void:
    draw_rect(Rect2(0,0,720,1440),Color(0.02,0.01,0.06,dim))

func _draw_pause() -> void:
    _modal()
    _panel(Rect2(69,428,582,568),Color("#302041"),true)
    _fancy("QUEST PAUSED",360,540,44)
    _label("Your progress is saved.",360,594,23,CREAM,true)
    _button(Rect2(116,635,488,78),"RESUME",true,30)
    _button(Rect2(116,738,488,78),"SETTINGS")
    _button(Rect2(116,843,488,78),"SAVE AND EXIT")

func _draw_result(victory: bool) -> void:
    _modal()
    _panel(Rect2(55,377,610,685),Color("#40294d"),true)
    _fancy("QUEST COMPLETE!" if victory else "OUT OF MOVES",360,498,39)
    if victory:
        _label("★".repeat(earned_stars),360,579,66,GOLD,true)
    else:
        _fancy("TRY AGAIN",360,565,41)
    _label("Level %s  •  %s" % [level,WORLD_SHORT[world_index]],360,635,23,CREAM,true)
    _fancy("SCORE  %s" % score,360,696,31)
    _label("Collected %s / %s" % [collected,target_amount] if objective_type=="collect" else "Target %s points" % score_target,360,741,22,CREAM,true)
    _button(Rect2(112,792,496,76),"NEXT LEVEL" if victory and level<LEVEL_COUNT else ("WORLD SELECT" if victory else "RETRY LEVEL"),true,27)
    _button(Rect2(112,889,496,76),"REPLAY" if victory else "SELECT LEVEL",false,26)
    _button(Rect2(112,984,496,60),"HOME",false,24)

func _draw_tutorial() -> void:
    _modal(0.73)
    _panel(Rect2(72,456,576,468),Color("#392853"),true)
    _fancy("HOW TO PLAY",360,543,40)
    _label("Swap neighboring jewels to match",360,612,23,CREAM,true)
    _label("three or more identical symbols.",360,648,23,CREAM,true)
    _label("Collect the target glyphs before",360,709,22,CREAM,true)
    _label("you run out of moves!",360,744,23,CREAM,true)
    _button(Rect2(122,800,476,80),"LET'S PLAY!",true,30)

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
            touch_start = e.position/_scale()
            touch_down = true
        elif touch_down:
            touch_down = false
            _gesture(touch_start,e.position/_scale())
    elif event is InputEventMouseButton and not OS.has_feature("mobile"):
        var e := event as InputEventMouseButton
        if e.button_index == MOUSE_BUTTON_LEFT:
            if e.pressed:
                touch_start = e.position/_scale()
                touch_down = true
            elif touch_down:
                touch_down = false
                _gesture(touch_start,e.position/_scale())
    elif event is InputEventKey:
        var e := event as InputEventKey
        if e.pressed and e.keycode in [KEY_ESCAPE,KEY_BACK]:
            _back()

func _inside(point: Vector2, x: float, y: float, w: float, h: float) -> bool:
    return Rect2(x,y,w,h).has_point(point)

func _gesture(start: Vector2, finish: Vector2) -> void:
    var p := finish
    _play_sound("tap")
    match state:
        "menu": _touch_menu(p)
        "levels": _touch_levels(p)
        "settings": _touch_settings(p)
        "progress":
            if _inside(p,48,225,154,64):
                state="menu"
        "playing": _touch_game(start,p)
        "paused": _touch_pause(p)
        "victory","failure": _touch_result(p)
        "tutorial":
            if _inside(p,122,800,476,80):
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
    queue_redraw()

func _back() -> void:
    match state:
        "playing","tutorial":
            state="paused"
            _save_current()
        "paused":
            state="playing"
        "levels","progress":
            state="menu"
        "settings":
            state=settings_return
        "reset_confirm":
            state="settings"
        "victory","failure":
            state="menu"
        _:
            state="menu"
    _music_state()
    queue_redraw()

func _touch_menu(p: Vector2) -> void:
    if _inside(p,52,431,80,63):
        world_index=(world_index+3)%4
    elif _inside(p,588,431,80,63):
        world_index=(world_index+1)%4
    elif _inside(p,54,673,612,84):
        var active: Dictionary = save.data.get("current",{})
        if not active.is_empty() and _resume_saved():
            return
        _start_level(world_index,save.unlocked_level(world_index))
    else:
        for i in range(4):
            var xx := 51+(i%2)*314
            var yy := 829+int(i/2)*112
            if _inside(p,xx,yy,300,95):
                world_index=i
                return
        if _inside(p,53,1081,613,68):
            state="levels"
        elif _inside(p,52,1173,299,73):
            settings_return="menu"
            state="settings"
        elif _inside(p,369,1173,299,73):
            state="progress"

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
    if _inside(p,79,1107,559,73):
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
    var was_win := state=="victory"
    if _inside(p,112,792,496,76):
        if was_win and level < LEVEL_COUNT:
            _start_level(world_index,level+1)
        elif was_win:
            state="menu"
        else:
            _start_level(world_index,level)
    elif _inside(p,112,889,496,76):
        if was_win:
            _start_level(world_index,level)
        else:
            state="levels"
    elif _inside(p,112,984,496,60):
        state="menu"

func _touch_game(start: Vector2,p: Vector2) -> void:
    if _inside(p,217,1320,286,66):
        _save_current()
        state="paused"
        return
    if _inside(p,34,1191,201,100):
        if hints_left>0:
            hints_left-=1
            _show_hint()
            _save_current()
        else:
            status_message="No hints remaining on this quest."
        return
    if _inside(p,257,1191,201,100):
        _shuffle()
        return
    if _inside(p,480,1191,201,100):
        if hammers_left>0:
            hammer_mode=not hammer_mode
            status_message="Tap a gem to break it!" if hammer_mode else "Hammer cancelled."
        else:
            status_message="No hammers remaining."
        return
    var first := _board_index(start)
    if first<0:
        return
    if hammer_mode:
        hammer_mode=false
        _hammer(first)
        return
    var second := _board_index(p)
    var delta := p-start
    if delta.length() >= 25.0 and (second==first or second<0):
        if absf(delta.x)>absf(delta.y):
            second=_neighbor(first,1 if delta.x>0 else -1,0)
        else:
            second=_neighbor(first,0,1 if delta.y>0 else -1)
    if second>=0 and second!=first and _adjacent(first,second):
        selected=-1
        _attempt_swap(first,second)
    elif selected>=0 and selected!=first and _adjacent(selected,first):
        _attempt_swap(selected,first)
        selected=-1
    else:
        selected=-1 if selected==first else first

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

func _configure_level(w: int,lvl: int) -> void:
    world_index=w
    level=lvl
    score_target=1400+lvl*410
    target_glyph=(lvl-1+w)%6
    target_amount=8+(lvl-1)%5*2
    objective_type="score" if lvl%3==0 else "collect"
    moves_left=maxi(18,25-int((lvl-1)/3))
    score=0
    collected=0
    hints_left=3
    shuffles_left=2
    hammers_left=2
    hammer_mode=false
    selected=-1
    hint_cells.clear()
    status_message="Match 3 or more gems!"
    earned_stars=0
    sparkles.clear()
    popups.clear()

func _start_level(w: int,lvl: int) -> void:
    _configure_level(w,clampi(lvl,1,LEVEL_COUNT))
    _create_board()
    state="playing" if bool(save.data.get("tutorial_done",false)) else "tutorial"
    _save_current()
    _reset_idle()
    _music_state()
    queue_redraw()

func _start_game() -> void:
    _start_level(world_index,1)

func _resume_saved() -> bool:
    var current: Dictionary = save.data.get("current",{})
    var restored: Array = current.get("board",[])
    if restored.size()!=ROWS*COLS:
        return false
    _configure_level(clampi(int(current.get("world",0)),0,3),clampi(int(current.get("level",1)),1,LEVEL_COUNT))
    board.clear()
    for value in restored:
        board.append(clampi(int(value),0,5))
    score=maxi(0,int(current.get("score",0)))
    moves_left=clampi(int(current.get("moves",24)),1,80)
    collected=maxi(0,int(current.get("collected",0)))
    hints_left=clampi(int(current.get("hints",3)),0,3)
    shuffles_left=clampi(int(current.get("shuffles",2)),0,2)
    hammers_left=clampi(int(current.get("hammers",2)),0,2)
    state="playing" if bool(save.data.get("tutorial_done",false)) else "tutorial"
    _reset_idle()
    queue_redraw()
    return true

func _save_current() -> void:
    if board.size()!=ROWS*COLS:
        return
    save.set_current({
        "world":world_index,"level":level,"board":board.duplicate(),
        "score":score,"moves":moves_left,"collected":collected,
        "hints":hints_left,"shuffles":shuffles_left,"hammers":hammers_left
    })

func _create_board() -> void:
    for attempt in range(350):
        board.resize(ROWS*COLS)
        for r in range(ROWS):
            for c in range(COLS):
                var idx:=r*COLS+c
                var choices: Array[int] = [0,1,2,3,4,5]
                if c>=2 and board[idx-1]==board[idx-2]:
                    choices.erase(board[idx-1])
                if r>=2 and board[idx-COLS]==board[idx-2*COLS]:
                    choices.erase(board[idx-COLS])
                board[idx]=choices.pick_random()
        if _find_hint().size()==2:
            return
    push_warning("Could not create a board with a legal match.")

func _find_matches() -> Array[int]:
    var found: Array[int]=[]
    for r in range(ROWS):
        var start:=0
        for c in range(1,COLS+1):
            if c==COLS or board[r*COLS+c]!=board[r*COLS+start]:
                if c-start>=3 and board[r*COLS+start]>=0:
                    for x in range(start,c):
                        var idx:=r*COLS+x
                        if not found.has(idx):
                            found.append(idx)
                start=c
    for c in range(COLS):
        var start:=0
        for r in range(1,ROWS+1):
            if r==ROWS or board[r*COLS+c]!=board[start*COLS+c]:
                if r-start>=3 and board[start*COLS+c]>=0:
                    for y in range(start,r):
                        var idx:=y*COLS+c
                        if not found.has(idx):
                            found.append(idx)
                start=r
    return found

func _swap_values(a: int,b: int) -> void:
    var v:=board[a]
    board[a]=board[b]
    board[b]=v

func _find_hint() -> Array[int]:
    for i in range(ROWS*COLS):
        for j in [_neighbor(i,1,0),_neighbor(i,0,1)]:
            if j<0 or board[i]==board[j]:
                continue
            _swap_values(i,j)
            var valid:=not _find_matches().is_empty()
            _swap_values(i,j)
            if valid:
                return [i,j]
    return []

func _attempt_swap(a: int,b: int) -> void:
    if state!="playing" or a<0 or b<0 or not _adjacent(a,b):
        return
    _swap_values(a,b)
    if _find_matches().is_empty():
        _swap_values(a,b)
        status_message="That swap didn't make a match."
        _reset_idle()
        return
    moves_left-=1
    hint_cells.clear()
    _resolve()
    _finish_or_save()
    _reset_idle()
    queue_redraw()

func _resolve() -> void:
    var combo:=0
    var total:=0
    var points:=0
    while combo<30:
        var hits:=_find_matches()
        if hits.is_empty():
            break
        combo+=1
        total+=hits.size()
        var gain:=hits.size()*65*combo
        points+=gain
        score+=gain
        for idx in hits:
            if objective_type=="collect" and board[idx]==target_glyph:
                collected+=1
            if sparkles.size()<150:
                _emit_fx(idx,GEM_COLORS[board[idx]])
            board[idx]=-1
        for col in range(COLS):
            var dest:=ROWS-1
            for row in range(ROWS-1,-1,-1):
                var value:=board[row*COLS+col]
                if value>=0:
                    board[dest*COLS+col]=value
                    dest-=1
            while dest>=0:
                board[dest*COLS+col]=randi_range(0,5)
                dest-=1
    if total>0:
        status_message=("%s COMBO!  " % combo if combo>1 else "") + "+%s POINTS" % points
        popups.append({"text":"+%s" % points,"life":1.0,"pos":Vector2(360,742)})
        _play_sound("match")
        _vibrate(22)
        save.data["lifetime_matches"]=int(save.data.get("lifetime_matches",0))+total

func _emit_fx(idx: int,clr: Color) -> void:
    if save.pref("reduce_motion"):
        return
    var center:=ORIGIN+Vector2((idx%COLS)*CELL+39,int(idx/COLS)*CELL+39)
    for j in range(5):
        var angle:=randf()*TAU
        sparkles.append({
            "pos":center,"vel":Vector2(cos(angle),sin(angle))*randf_range(75,200),
            "life":randf_range(.3,.62),"color":clr
        })

func _hammer(idx: int) -> void:
    if state!="playing" or hammers_left<=0:
        return
    hammers_left-=1
    if board[idx]==target_glyph and objective_type=="collect":
        collected+=1
    _emit_fx(idx,GOLD)
    board[idx]=-1
    score+=75
    var col:=idx%COLS
    var dest:=int(idx/COLS)
    while dest>0:
        board[dest*COLS+col]=board[(dest-1)*COLS+col]
        dest-=1
    board[col]=randi_range(0,5)
    _resolve()
    status_message="HAMMER SMASH! +75"
    _finish_or_save()

func _shuffle() -> void:
    if state!="playing":
        return
    if shuffles_left<=0:
        status_message="No shuffles remaining."
        return
    shuffles_left-=1
    hint_cells.clear()
    selected=-1
    _create_board()
    status_message="The glyphs have shifted!"
    _save_current()
    _reset_idle()

func _show_hint() -> void:
    hint_cells=_find_hint()
    hint_until=Time.get_ticks_msec()+2500
    status_message="Swap the glowing gems!" if hint_cells.size()==2 else "No moves. Use Shuffle!"
    _reset_idle()

func _reset_idle() -> void:
    next_auto_hint_at=Time.get_ticks_msec()+11000

func _finish_or_save() -> void:
    var won:=collected>=target_amount if objective_type=="collect" else score>=score_target
    if won:
        earned_stars=1+(1 if moves_left>=5 else 0)+(1 if score>=score_target*1.2 else 0)
        state="victory"
        save.record_victory(world_index,level,score,earned_stars)
        _play_sound("win")
        _vibrate(70)
    elif moves_left<=0:
        state="failure"
        save.clear_current()
        _play_sound("fail")
    else:
        if _find_hint().is_empty():
            _create_board()
            status_message="New gems appeared. Keep going!"
        _save_current()

func _vibrate(duration: int) -> void:
    if save.pref("haptics") and OS.has_feature("mobile"):
        Input.vibrate_handheld(duration)

func _play_sound(name: String) -> void:
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
        music_player.stop()
