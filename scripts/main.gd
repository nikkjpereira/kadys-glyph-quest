extends Node2D
## Kady's Glyph Quest: touch-first, single-scene match-three prototype.

const COLS := 7
const ROWS := 8
const CELL := 86.0
const ORIGIN := Vector2(59, 392)
const START_MOVES := 24
const TARGET := 2300
const WORLDS := ["RUNES", "EGYPT", "EAST ASIA", "MIXED"]
const DESCRIPTIONS := [
    "Discover the ancient runes",
    "Enter the hidden temples",
    "Journey through Eastern scripts",
    "A world of symbols together"
]
const SYMBOLS := [
    ["ᚠ", "ᚢ", "ᚦ", "ᚱ", "ᚹ", "ᛟ"],
    ["𓂀", "𓆣", "𓇳", "𓃭", "𓅓", "𓋹"],
    ["山", "水", "火", "月", "あ", "한"],
    ["ᚠ", "ᚱ", "𓂀", "𓆣", "山", "あ"]
]
const PALETTE := [
    Color("#7756c6"), Color("#b65a8d"), Color("#b78245"),
    Color("#387f9a"), Color("#4d9a84"), Color("#b9656a")
]
var board: Array[int] = []
var world_index := 0
var state := "menu"
var score := 0
var moves_left := START_MOVES
var shuffles_left := 2
var selected := -1
var hint_cells: Array[int] = []
var hint_until := 0
var status_message := "Match three identical symbols!"
var win := false
var ui_font: Font
var script_fonts: Array[Font] = []
var touch_start := Vector2.ZERO
var touching := false

func _ready() -> void:
    randomize()
    ui_font = ThemeDB.fallback_font
    var paths := [
        "res://assets/fonts/NotoSansRunic-Regular.ttf",
        "res://assets/fonts/NotoSansEgyptianHieroglyphs-Regular.ttf",
        "res://assets/fonts/NotoSansJP.ttf",
        "res://assets/fonts/NotoSansKR.ttf"
    ]
    for path in paths:
        var font: Font = ui_font
        if ResourceLoader.exists(path):
            var loaded := load(path) as Font
            if loaded != null:
                font = loaded
        script_fonts.append(font)
    queue_redraw()

func _process(_delta: float) -> void:
    if not hint_cells.is_empty() and Time.get_ticks_msec() >= hint_until:
        hint_cells.clear()
        queue_redraw()

func _rect(rect: Rect2, fill: Color, radius: int = 16, outline: Color = Color.TRANSPARENT, width: int = 0) -> void:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.set_corner_radius_all(radius)
    if width > 0:
        box.border_color = outline
        box.set_border_width_all(width)
    draw_style_box(box, rect)

func _label(text_value: String, x: float, y: float, size: int, color: Color, center: bool = false, custom_font: Font = null) -> void:
    var font := ui_font if custom_font == null else custom_font
    if center:
        x -= font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0
    draw_string(font, Vector2(x, y), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _glyph_font(tile: int) -> Font:
    if world_index == 0:
        return script_fonts[0]
    if world_index == 1:
        return script_fonts[1]
    if world_index == 2:
        return script_fonts[3] if tile == 5 else script_fonts[2]
    if tile < 2:
        return script_fonts[0]
    if tile < 4:
        return script_fonts[1]
    return script_fonts[2]

func _draw() -> void:
    var upper := Color("#10132e")
    var lower := Color("#29234e")
    for n in range(48):
        var t := float(n) / 47.0
        draw_rect(Rect2(0, n * 30, 720, 31), upper.lerp(lower, t))
    for n in range(43):
        var x := 20.0 + fposmod(float(n * 211 + 71), 680.0)
        var y := 25.0 + fposmod(float(n * 397 + 47), 1380.0)
        draw_circle(Vector2(x, y), 1.5 + float(n % 3), Color(0.9, 0.8, 1.0, 0.08 + float(n % 3) * 0.05))
    draw_circle(Vector2(730, 220), 220, Color(0.5, 0.3, 0.8, 0.08))
    if state == "menu":
        _draw_menu()
    else:
        _draw_game()

func _draw_menu() -> void:
    _label("KADY'S", 360, 167, 68, Color("#ffe2a4"), true)
    _label("GLYPH QUEST", 360, 239, 62, Color("#ffffff"), true)
    _label("Match the symbols. Reveal the world.", 360, 298, 25, Color("#c9c2e7"), true)

    _rect(Rect2(62, 357, 596, 345), Color("#272246"), 36, Color("#675889"), 2)
    draw_circle(Vector2(360, 515), 125, Color("#493774"))
    draw_arc(Vector2(360, 515), 126, 0.0, TAU, 96, Color("#e7c883"), 4)
    draw_arc(Vector2(360, 515), 90, 0.0, TAU, 96, Color("#9d91d8"), 2)
    _label("ᚠ", 360, 568, 148, Color("#ffe9b5"), true, script_fonts[0])
    for i in range(6):
        var glyph: String = SYMBOLS[3][i]
        var font: Font = script_fonts[0] if i < 2 else (script_fonts[1] if i < 4 else script_fonts[2])
        _label(glyph, 148 + i * 85, 679, 36, Color("#dbd0f4"), true, font)

    _label("CHOOSE YOUR WORLD", 360, 787, 27, Color("#f5dca9"), true)
    for i in range(4):
        var col := i % 2
        var row := int(i / 2)
        var tile_rect := Rect2(59 + col * 310, 818 + row * 112, 292, 91)
        var active := world_index == i
        _rect(tile_rect, Color("#514178") if active else Color("#302a4d"), 21, Color("#f0d392") if active else Color("#625579"), 3 if active else 1)
        _label(WORLDS[i], tile_rect.position.x + 146, tile_rect.position.y + 57, 26, Color.WHITE, true)
    _rect(Rect2(78, 1098, 564, 101), Color("#ecc67d"), 30)
    _label("BEGIN QUEST", 360, 1164, 41, Color("#292039"), true)
    _label(DESCRIPTIONS[world_index], 360, 1258, 27, Color("#cbc4ec"), true)
    _label("PLAY OFFLINE  •  NO ADS  •  VERSION 0.1.0", 360, 1363, 19, Color("#aaa3cf"), true)

func _draw_game() -> void:
    _label("GLYPH QUEST", 54, 124, 48, Color("#fbe1aa"))
    _label(WORLDS[world_index], 56, 166, 24, Color("#a7e4d2"))
    _rect(Rect2(563, 84, 110, 64), Color("#353052"), 18, Color("#72628f"), 2)
    _label("HOME", 618, 125, 23, Color("#f0ebff"), true)

    _rect(Rect2(48, 193, 302, 130), Color("#292547"), 26)
    _rect(Rect2(370, 193, 302, 130), Color("#292547"), 26)
    _label("SCORE", 76, 230, 21, Color("#bab3d4"))
    _label(str(score), 76, 291, 57, Color("#ffe0a2"))
    _label("MOVES LEFT", 401, 230, 21, Color("#bab3d4"))
    _label(str(moves_left), 401, 291, 57, Color("#a8e6d4"))
    _rect(Rect2(53, 342, 614, 15), Color("#49425f"), 7)
    _rect(Rect2(53, 342, maxf(0.1, 614.0 * minf(1.0, float(score) / float(TARGET))), 15), Color("#eaca87"), 7)
    _label("TARGET  " + str(TARGET), 659, 378, 19, Color("#d2cbe9"), true)

    _rect(Rect2(42, 383, 636, 705), Color("#1d1c38"), 28, Color("#665780"), 2)
    for row in range(ROWS):
        for col in range(COLS):
            var idx := row * COLS + col
            var tile := board[idx]
            var tile_rect := Rect2(ORIGIN + Vector2(col * CELL + 4, row * CELL + 4), Vector2(78, 78))
            if idx == selected:
                _rect(tile_rect.grow(3), Color("#f9e3a9"), 20)
            if hint_cells.has(idx):
                _rect(tile_rect.grow(3), Color("#9cffde"), 20)
            _rect(tile_rect, PALETTE[tile].darkened(0.22), 18)
            _rect(Rect2(tile_rect.position + Vector2(2, 2), tile_rect.size - Vector2(4, 9)), PALETTE[tile], 16)
            var symbol: String = SYMBOLS[world_index][tile]
            _label(symbol, tile_rect.position.x + 39, tile_rect.position.y + 59, 51, Color("#fff8e9"), true, _glyph_font(tile))
    _label(status_message, 360, 1142, 23, Color("#e2d9f4"), true)
    _rect(Rect2(53, 1170, 298, 91), Color("#594583"), 24)
    _label("HINT", 202, 1228, 32, Color.WHITE, true)
    _rect(Rect2(368, 1170, 298, 91), Color("#376d72") if shuffles_left > 0 else Color("#37374c"), 24)
    _label("SHUFFLE (" + str(shuffles_left) + ")", 517, 1228, 30, Color.WHITE, true)
    _label("SWIPE OR TAP TWO ADJACENT TILES", 360, 1351, 20, Color("#b4abd3"), true)

    if state == "finished":
        draw_rect(Rect2(0, 0, 720, 1440), Color(0.03, 0.02, 0.10, 0.82))
        _rect(Rect2(62, 500, 596, 443), Color("#352b59"), 34, Color("#f0cf88"), 3)
        _label("QUEST COMPLETE!" if win else "OUT OF MOVES", 360, 610, 48, Color("#ffe2a6"), true)
        _label("Final score: " + str(score), 360, 695, 39, Color.WHITE, true)
        _label("The glyphs await another adventure.", 360, 760, 24, Color("#d7cde8"), true)
        _rect(Rect2(110, 806, 500, 87), Color("#ecc77e"), 25)
        _label("PLAY AGAIN", 360, 864, 34, Color("#251e3c"), true)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            touch_start = touch.position
            touching = true
        elif touching:
            touching = false
            _gesture(touch_start, touch.position)
    elif event is InputEventMouseButton and not OS.has_feature("mobile"):
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                touch_start = mouse.position
                touching = true
            elif touching:
                touching = false
                _gesture(touch_start, mouse.position)
    elif event is InputEventKey:
        var key := event as InputEventKey
        if key.pressed and key.keycode == KEY_ESCAPE:
            state = "menu"
            selected = -1
            queue_redraw()

func _gesture(start: Vector2, finish: Vector2) -> void:
    if state == "menu":
        for idx in range(4):
            if Rect2(59 + (idx % 2) * 310, 818 + int(idx / 2) * 112, 292, 91).has_point(finish):
                world_index = idx
                queue_redraw()
                return
        if Rect2(78, 1098, 564, 101).has_point(finish):
            _start_game()
        return
    if state == "finished":
        if Rect2(110, 806, 500, 87).has_point(finish):
            _start_game()
        return
    if Rect2(563, 84, 110, 64).has_point(finish):
        state = "menu"
        selected = -1
    elif Rect2(53, 1170, 298, 91).has_point(finish):
        _show_hint()
    elif Rect2(368, 1170, 298, 91).has_point(finish):
        _shuffle()
    else:
        var first := _board_index(start)
        if first < 0:
            return
        var second := _board_index(finish)
        var delta := finish - start
        if delta.length() >= 28 and (second == first or second < 0):
            if absf(delta.x) > absf(delta.y):
                second = _neighbor(first, 1 if delta.x > 0 else -1, 0)
            else:
                second = _neighbor(first, 0, 1 if delta.y > 0 else -1)
        if second >= 0 and second != first and _adjacent(first, second):
            selected = -1
            _swap_attempt(first, second)
        elif selected >= 0 and selected != first and _adjacent(selected, first):
            _swap_attempt(selected, first)
            selected = -1
        else:
            selected = -1 if selected == first else first
    queue_redraw()

func _board_index(point: Vector2) -> int:
    var offset := point - ORIGIN
    if offset.x < 0 or offset.y < 0:
        return -1
    var col := int(offset.x / CELL)
    var row := int(offset.y / CELL)
    if col >= COLS or row >= ROWS:
        return -1
    return row * COLS + col

func _neighbor(index: int, dx: int, dy: int) -> int:
    var col := (index % COLS) + dx
    var row := int(index / COLS) + dy
    if col < 0 or col >= COLS or row < 0 or row >= ROWS:
        return -1
    return row * COLS + col

func _adjacent(a: int, b: int) -> bool:
    return abs(a % COLS - b % COLS) + abs(int(a / COLS) - int(b / COLS)) == 1

func _start_game() -> void:
    state = "playing"
    win = false
    score = 0
    moves_left = START_MOVES
    shuffles_left = 2
    selected = -1
    hint_cells.clear()
    status_message = "Match three identical symbols!"
    _new_board()
    queue_redraw()

func _new_board() -> void:
    # Construct a board without pre-existing matches, and with at least one valid move.
    for tries in range(250):
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
        if _find_hint().size() == 2:
            return
    push_warning("Could not generate a board with available matches.")

func _matches() -> Array[int]:
    var found: Array[int] = []
    for row in range(ROWS):
        var start_col := 0
        for col in range(1, COLS + 1):
            if col == COLS or board[row * COLS + col] != board[row * COLS + start_col]:
                if col - start_col >= 3 and board[row * COLS + start_col] >= 0:
                    for c in range(start_col, col):
                        var idx := row * COLS + c
                        if not found.has(idx):
                            found.append(idx)
                start_col = col
    for col in range(COLS):
        var start_row := 0
        for row in range(1, ROWS + 1):
            if row == ROWS or board[row * COLS + col] != board[start_row * COLS + col]:
                if row - start_row >= 3 and board[start_row * COLS + col] >= 0:
                    for r in range(start_row, row):
                        var idx := r * COLS + col
                        if not found.has(idx):
                            found.append(idx)
                start_row = row
    return found

func _find_matches() -> Array[int]:
    return _matches()

func _swap_values(a: int, b: int) -> void:
    var value := board[a]
    board[a] = board[b]
    board[b] = value

func _find_hint() -> Array[int]:
    for idx in range(ROWS * COLS):
        for other in [_neighbor(idx, 1, 0), _neighbor(idx, 0, 1)]:
            if other < 0 or board[idx] == board[other]:
                continue
            _swap_values(idx, other)
            var matched := not _matches().is_empty()
            _swap_values(idx, other)
            if matched:
                return [idx, other]
    return []

func _swap_attempt(a: int, b: int) -> void:
    if state != "playing" or a < 0 or b < 0 or not _adjacent(a, b):
        return
    _swap_values(a, b)
    if _matches().is_empty():
        _swap_values(a, b)
        status_message = "That swap didn't make a match!"
        return
    moves_left -= 1
    hint_cells.clear()
    _resolve()
    if score >= TARGET:
        state = "finished"
        win = true
    elif moves_left <= 0:
        state = "finished"
        win = false
    elif _find_hint().is_empty():
        _new_board()
        status_message = "No moves available. New board!"
    queue_redraw()

func _attempt_swap(a: int, b: int) -> void:
    _swap_attempt(a, b)

func _resolve() -> void:
    var combo := 0
    var cleared := 0
    while combo < 30:
        var matched := _matches()
        if matched.is_empty():
            break
        combo += 1
        cleared += matched.size()
        score += matched.size() * 65 * combo
        for idx in matched:
            board[idx] = -1
        for col in range(COLS):
            var dest := ROWS - 1
            for row in range(ROWS - 1, -1, -1):
                var value := board[row * COLS + col]
                if value >= 0:
                    board[dest * COLS + col] = value
                    dest -= 1
            while dest >= 0:
                board[dest * COLS + col] = randi_range(0, 5)
                dest -= 1
    status_message = ("COMBO x" + str(combo) + "! " if combo > 1 else "") + str(cleared) + " symbols matched!"

func _show_hint() -> void:
    hint_cells = _find_hint()
    hint_until = Time.get_ticks_msec() + 2400
    status_message = "Swap the highlighted symbols!" if hint_cells.size() == 2 else "No moves. Shuffle the board!"
    queue_redraw()

func _shuffle() -> void:
    if shuffles_left <= 0:
        status_message = "No shuffles left this game."
        queue_redraw()
        return
    shuffles_left -= 1
    selected = -1
    hint_cells.clear()
    _new_board()
    status_message = "Fresh symbols. New possibilities!"
    queue_redraw()
