extends Node2D
## Kady's Glyph Quest v0.2: storybook UI, level objectives, saves and effects.
## Keep play fully functional offline. No ads or billing in test releases.

const SaveData = preload("res://scripts/save_data.gd")
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
        gems.append(load("res://assets/art/gem_%s.png" % i) as Texture2D)
    for item in ["runes", "egypt", "asia", "mixed"]:
        backgrounds.append(load("res://assets/art/bg_%s.png" % item) as Texture2D)
    scene_bg = load("res://assets/art/storybook.png") as Texture2D
    logo = load("res://assets/art/logo.png") as Texture2D
    for item in ["tap", "match", "win", "fail"]:
        var player := AudioStreamPlayer.new()
        player.stream = load("res://assets/audio/" + item + ".wav")
        player.volume_db = -7
        add_child(player)
        sound_players[item] = player
    music_player = AudioStreamPlayer.new()
    var ambience := load("res://assets/audio/ambient.wav")
    if ambience is AudioStreamWAV:
        ambience.loop_mode = AudioStreamWAV.LOOP_FORWARD
    music_player.stream = ambience
    music_player.volume_db = -16
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

func _background() -> void:
    var tex: Texture2D = scene_bg
    if state in ["playing", "paused", "victory", "failure", "tutorial"]:
        tex = backgrounds[world_index]
    if tex != null:
        draw_texture_rect(tex, Rect2(0, 0, 720, 1440), false)
    else:
        draw_rect(Rect2(0, 0, 720, 1440), NAVY)
    draw_rect(Rect2(0, 0, 720, 1440), Color(0.03, 0.012, 0.085, 0.18))
    for i in range(18):
        var x := 15.0 + fposmod(float(i * 211 + 71), 690.0)
        var y := 30.0 + fposmod(float(i * 293 + 47), 1390.0)
        var light := 0.35 + 0.20 * sin(clock * 1.2 + float(i))
        draw_circle(Vector2(x, y), 2.1, Color(1, 0.87, 0.55, light))

func _rect(rect: Rect2, color: Color, radius: int = 16, border: Color = Color.TRANSPARENT, bw: int = 0) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(radius)
    if bw > 0:
        style.border_color = border
        style.set_border_width_all(bw)
    draw_style_box(style, rect)

func _panel(rect: Rect2, color: Color = PANEL, ornate: bool = true, fill_alpha: float = 0.94) -> void:
    _rect(Rect2(rect.position + Vector2(0, 7), rect.size), Color(0.02, 0.01, 0.03, 0.51), 23)
    var c := color
    c.a = fill_alpha
    _rect(rect, c, 22, Color("#d9ad62"), 4 if ornate else 2)
    _rect(rect.grow(-6), Color.TRANSPARENT, 17, Color("#766091"), 2)
    if ornate:
        var x := rect.position.x
        var y := rect.position.y
        var right := rect.end.x
        var bottom := rect.end.y
        for pt in [Vector2(x+19,y+19),Vector2(right-19,y+19),Vector2(x+19,bottom-19),Vector2(right-19,bottom-19)]:
            draw_arc(pt, 12, 0, TAU, 16, Color("#dfbd7e"), 2.5, true)
            draw_circle(pt, 3.0, Color("#ffdb91"))

func _label(value: String, x: float, y: float, size: int, color: Color = CREAM, center: bool = false, font_override: Font = null) -> void:
    var f: Font = ui_font if font_override == null else font_override
    var s := size + (2 if save.pref("large_text") and font_override == null else 0)
    if center:
        x -= f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x / 2
    draw_string(f, Vector2(x,y+2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color(0.02,0,0.07,0.8))
    draw_string(f, Vector2(x,y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, s, color)

func _button(rect: Rect2, value: String, selected_style: bool = false, size: int = 24) -> void:
    var base := Color("#eac67c") if selected_style else Color("#3d2b68")
    var edge := Color("#fff0bf") if selected_style else Color("#cda567")
    _rect(Rect2(rect.position + Vector2(0, 4), rect.size), Color("#14102a"), 16)
    _rect(rect, base, 17, edge, 3)
    _rect(Rect2(rect.position + Vector2(6, 6), Vector2(rect.size.x-12,8)), Color(1,1,1,0.13), 4)
    _label(value, rect.get_center().x, rect.position.y + rect.size.y / 2 + size / 3, size, INK if selected_style else CREAM, true)

func _title(value: String, subtitle: String = "") -> void:
    _panel(Rect2(47,72,626,121),Color("#302045"),true,0.97)
    _label(value, 360, 124, 39, GOLD, true)
    if not subtitle.is_empty():
        _label(subtitle, 360, 165, 21, MUTED, true)

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
    if logo != null:
        draw_texture_rect(logo,Rect2(x,y,w,h),false)
    else:
        _label("GLYPH QUEST", x+w/2, y+h/2, 49, GOLD, true)

func _draw_menu() -> void:
    _draw_logo(28,65,664,238)
    _panel(Rect2(52,329,616,318),Color("#37234b"),true,0.92)
    _label("CURRENT ADVENTURE",360,365,20,GOLD,true)
    draw_circle(Vector2(360,458),70,Color("#564184"))
    draw_arc(Vector2(360,458),73,0,TAU,75,Color("#f6d08f"),4,true)
    _label(_world_symbol(world_index),360,486,83,CREAM,true,_world_font(world_index))
    _label(WORLD_NAMES[world_index],360,559,31,GOLD,true)
    _label(WORLD_TAGLINES[world_index],360,592,20,MUTED,true)
    _label("LEVEL %s / %s" % [save.unlocked_level(world_index),LEVEL_COUNT],360,627,19,CREAM,true)
    _button(Rect2(57,431,70,63),"<",false,31)
    _button(Rect2(593,431,70,63),">",false,31)
    var active: Dictionary = save.data.get("current",{})
    _button(Rect2(54,673,612,84),"CONTINUE ADVENTURE" if not active.is_empty() else "BEGIN ADVENTURE",true,31)
    _label("EXPLORE THE WORLDS",360,804,27,GOLD,true)
    for i in range(4):
        var xx := 51 + (i % 2) * 314
        var yy := 829 + int(i / 2) * 112
        var chosen := world_index == i
        _panel(Rect2(xx,yy,300,95),Color("#554076") if chosen else Color("#31254b"),false,0.95)
        _label(_world_symbol(i),xx+55,yy+64,49,CREAM,true,_world_font(i))
        _label(WORLD_SHORT[i],xx+184,yy+41,21,GOLD if chosen else CREAM,true)
        _label("%s / %s" % [save.unlocked_level(i),LEVEL_COUNT],xx+184,yy+71,16,MUTED,true)
    _button(Rect2(53,1081,613,68),"SELECT LEVEL",false,24)
    _button(Rect2(52,1173,299,73),"SETTINGS",false,26)
    _button(Rect2(369,1173,299,73),"PROGRESS",false,26)
    _label("STORYBOOK BUILD  •  v0.2.0",360,1339,17,CREAM,true)

func _draw_levels() -> void:
    _title("CHOOSE A LEVEL",WORLD_NAMES[world_index])
    _button(Rect2(48,225,144,63),"BACK")
    _label("Complete levels to earn up to 3 stars each.",361,331,22,CREAM,true)
    for idx in range(LEVEL_COUNT):
        var lvl := idx+1
        var xx := 47 + (idx % 4) * 159
        var yy := 390 + int(idx / 4) * 174
        var unlocked := lvl <= save.unlocked_level(world_index)
        _panel(Rect2(xx,yy,146,149),Color("#50396c") if unlocked else Color("#252137"),false,0.96)
        _label(str(lvl) if unlocked else "LOCK",xx+73,yy+83,45,GOLD if unlocked else Color("#a49aad"),true)
        var entry: Dictionary = save.best_result(world_index,lvl)
        if unlocked:
            _label(("★".repeat(int(entry.get("stars",0))) if int(entry.get("stars",0))>0 else "NEW"),xx+73,yy+122,20,Color("#f8d273"),true)
    _label("WORLD PROGRESS",360,1060,25,GOLD,true)
    _label("Earn stars and unlock the next challenge.",360,1110,22,CREAM,true)
    _button(Rect2(100,1192,520,77),"PLAY HIGHEST LEVEL",true,27)

func _draw_progress() -> void:
    _title("YOUR ADVENTURE","Saved right here on your device")
    _button(Rect2(52,225,154,64),"BACK")
    _panel(Rect2(44,330,632,725),Color("#302344"),true)
    _label(str(save.total_stars()),360,452,82,GOLD,true)
    _label("STARS EARNED",360,502,29,CREAM,true)
    for i in range(4):
        var yy := 551 + i * 112
        _label(_world_symbol(i),108,yy+25,44,GOLD,true,_world_font(i))
        _label(WORLD_SHORT[i],169,yy+5,26,CREAM)
        _label("LEVEL %s / %s" % [save.unlocked_level(i),LEVEL_COUNT],169,yy+37,20,MUTED)
        _rect(Rect2(169,yy+51,450,13),Color("#584467"),6)
        _rect(Rect2(169,yy+51,maxf(12,450.0*float(save.unlocked_level(i)-1)/float(LEVEL_COUNT)),13),GOLD,6)
    _label("NO ACCOUNT REQUIRED. PROGRESS SAVES OFFLINE.",360,1150,18,CREAM,true)

func _draw_settings() -> void:
    _title("SETTINGS","Personalize your adventure")
    _button(Rect2(49,217,153,65),"BACK")
    _panel(Rect2(46,303,628,891),Color("#302243"),true)
    var rows := [
        ["Music","music"],["Sound effects","sfx"],["Vibration","haptics"],
        ["Reduce animations","reduce_motion"],["High-contrast gems","color_assist"],
        ["Automatic hints","auto_hints"],["Larger text","large_text"]
    ]
    for i in range(rows.size()):
        var item: Array = rows[i]
        var yy := 345 + i * 101
        _label(str(item[0]),79,yy+28,25,CREAM)
        _rect(Rect2(501,yy-11,123,62),Color("#375e60") if save.pref(str(item[1])) else Color("#58415c"),16,Color("#d4af79"),2)
        _label("ON" if save.pref(str(item[1])) else "OFF",562,yy+29,22,Color("#b9f7dc") if save.pref(str(item[1])) else CREAM,true)
        if i != rows.size()-1:
            draw_line(Vector2(80,yy+61),Vector2(632,yy+61),Color("#7b6480"),1.5)
    _button(Rect2(79,1070,559,77),"RESET SAVED PROGRESS")
    _label("Saves automatically after every move and completed level.",360,1258,19,CREAM,true)
    _label("Purchases and ads are not enabled in this test build.",360,1305,18,MUTED,true)

func _draw_game() -> void:
    _draw_logo(183,28,354,133)
    _panel(Rect2(39,170,205,96),Color("#352349"),true)
    _panel(Rect2(253,170,215,96),Color("#352349"),true)
    _panel(Rect2(479,170,202,96),Color("#352349"),true)
    _label("SCORE",140,199,18,GOLD,true)
    _label(str(score),140,246,42,CREAM,true)
    _label("LEVEL",361,199,18,GOLD,true)
    _label(str(level),361,247,42,CREAM,true)
    _label("MOVES",577,199,18,GOLD,true)
    _label(str(moves_left),577,247,42,CREAM,true)
    _panel(Rect2(49,284,622,57),Color("#d5b58a"),true,1.0)
    _label("LEVEL %s  •  %s" % [level,WORLD_TAGLINES[world_index]],360,322,22,INK,true)
    _panel(Rect2(43,357,634,106),Color("#e3c59c"),true,1.0)
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
    _label(goal,145,393,24,INK)
    _label("%s / %s" % [mini(amount,wanted),wanted],590,436,23,INK,true)
    _rect(Rect2(144,411,339,20),Color("#614d60"),9)
    _rect(Rect2(144,411,maxf(3.0,339.0*minf(1.0,float(amount)/maxf(1.0,float(wanted)))),20),Color("#27bbd0"),9)
    if objective_type=="collect":
        _label(SYMBOLS[world_index][target_glyph],99,432,55,INK,true,_glyph_font(target_glyph))
    else:
        _label("★",97,426,43,Color("#8e6231"),true)
    _panel(Rect2(35,474,650,650),Color("#1c1c3e"),true,0.97)
    for row in range(ROWS):
        for col in range(COLS):
            var idx := row*COLS+col
            var xx := ORIGIN.x + float(col)*CELL
            var yy := ORIGIN.y + float(row)*CELL
            var tile := board[idx]
            var r := Rect2(xx+1,yy+1,76,76)
            if hint_cells.has(idx):
                _rect(r.grow(4),Color("#cfffe2"),15)
            elif selected == idx or (hammer_mode and selected == idx):
                _rect(r.grow(4),GOLD,15)
            elif save.pref("color_assist"):
                _rect(r.grow(2),CREAM,13)
            if tile >= 0 and tile < 6:
                if gems[tile] != null:
                    draw_texture_rect(gems[tile],r,false)
                else:
                    _rect(r,GEM_COLORS[tile],15)
                _label(SYMBOLS[world_index][tile],r.get_center().x,r.position.y+55,48,CREAM,true,_glyph_font(tile))
            if save.pref("color_assist"):
                _label(str(tile+1),xx+68,yy+19,14,Color("#ffedbf"),true)
    _label(status_message,360,1164,20,CREAM,true)
    _button(Rect2(34,1191,201,100),"HINT   %s" % hints_left)
    _button(Rect2(257,1191,201,100),"SHUFFLE %s" % shuffles_left)
    _button(Rect2(480,1191,201,100),"HAMMER %s" % hammers_left,hammer_mode)
    _button(Rect2(217,1320,286,66),"PAUSE",false,25)
    _draw_fx()

func _draw_fx() -> void:
    for p in sparkles:
        var life: float = p["life"]
        var t: float = clampf(life/0.6,0.0,1.0)
        var pos: Vector2 = p["pos"]
        var color: Color = p["color"]
        color.a = t
        var rad := 2.0 + t * 4.0
        draw_line(pos-Vector2(rad,0),pos+Vector2(rad,0),color,2,true)
        draw_line(pos-Vector2(0,rad),pos+Vector2(0,rad),color,2,true)
    for p in popups:
        var life: float = p["life"]
        var pos: Vector2 = p["pos"]
        _label(str(p["text"]),pos.x,pos.y+(1.0-life)*(-60.0),31,GOLD,true)

func _modal(dim: float = 0.77) -> void:
    draw_rect(Rect2(0,0,720,1440),Color(0.03,0.016,0.07,dim))

func _draw_pause() -> void:
    _modal()
    _panel(Rect2(69,428,582,568),Color("#36274b"),true)
    _label("QUEST PAUSED",360,535,43,GOLD,true)
    _label("Your progress is safe.",360,591,23,CREAM,true)
    _button(Rect2(116,635,488,78),"RESUME",true,29)
    _button(Rect2(116,738,488,78),"SETTINGS")
    _button(Rect2(116,843,488,78),"SAVE AND EXIT")

func _draw_result(victory: bool) -> void:
    _modal()
    _panel(Rect2(55,377,610,685),Color("#40294d"),true)
    _label("QUEST COMPLETE!" if victory else "OUT OF MOVES",360,491,44,GOLD,true)
    if victory:
        _label("★".repeat(earned_stars),360,570,66,GOLD,true)
    else:
        _label("TRY AGAIN",360,562,42,CREAM,true)
    _label("Level %s  •  %s" % [level,WORLD_SHORT[world_index]],360,634,23,CREAM,true)
    _label("Final score  %s" % score,360,691,33,GOLD,true)
    _label("Collected  %s / %s" % [collected,target_amount] if objective_type=="collect" else "Target  %s points" % score_target,360,736,22,CREAM,true)
    _button(Rect2(112,792,496,76),"NEXT LEVEL" if victory and level < LEVEL_COUNT else ("WORLD SELECT" if victory else "RETRY LEVEL"),true,25)
    _button(Rect2(112,889,496,76),"REPLAY" if victory else "SELECT LEVEL",false,25)
    _button(Rect2(112,984,496,60),"HOME",false,24)

func _draw_tutorial() -> void:
    _modal(0.67)
    _panel(Rect2(72,456,576,468),Color("#392853"),true)
    _label("HOW TO PLAY",360,545,43,GOLD,true)
    _label("Swipe a jewel to swap it with",360,613,25,CREAM,true)
    _label("its neighbor. Match 3 or more!",360,647,25,CREAM,true)
    _label("Collect the target symbols",360,705,24,CREAM,true)
    _label("before you run out of moves.",360,739,24,CREAM,true)
    _button(Rect2(122,800,476,80),"LET'S PLAY!",true,30)

func _draw_reset_confirm() -> void:
    _modal()
    _panel(Rect2(64,468,592,464),Color("#35284f"),true)
    _label("RESET PROGRESS?",360,569,39,GOLD,true)
    _label("This deletes levels, stars and",360,635,24,CREAM,true)
    _label("the current quest. Settings stay.",360,675,24,CREAM,true)
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
                state="settings"
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
        if _inside(p,74,345+idx*101-11,558,72):
            save.toggle_pref(pref_keys[idx])
            _music_state()
            return
    if _inside(p,79,1070,559,77):
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
        var player: AudioStreamPlayer=sound_players[name]
        player.play()

func _music_state() -> void:
    if music_player==null:
        return
    if save.pref("music"):
        if not music_player.playing:
            music_player.play()
    elif music_player.playing:
        music_player.stop()
