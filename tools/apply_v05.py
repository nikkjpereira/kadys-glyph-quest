#!/usr/bin/env python3
from pathlib import Path
p=Path(__file__).resolve().parents[1]/"scripts"/"main.gd"
s=p.read_text()
def swap(old,new,count=1):
    global s
    actual=s.count(old)
    if actual != count:raise ValueError(f"Replacement expected {count} hits, got {actual} for {old[:75]!r}")
    s=s.replace(old,new)

def replacefunc(name,next_name,new):
    global s
    first=s.index(f"func {name}(")
    second=s.index(f"func {next_name}(",first)
    s=s[:first]+new.rstrip()+"\n\n"+s[second:]
swap("const CELL := 72.0","const CELL := 82.0")
swap("const ORIGIN := Vector2(72, 514)","const ORIGIN := Vector2(32, 429)")
swap("var board: Array[int] = []","""var board: Array[int] = []
var locks: Array[int] = []
var reference_moves := 12
var boosters_used := 0
var impact_fx: Array[Dictionary] = []
var impact_flash := 0.0
var music_alt_player: AudioStreamPlayer
var world_tracks: Array[AudioStream] = []
var music_track_id := -1
""")
swap('art["board_frame"] = load("res://assets/v03/board_gold_frame.png") as Texture2D', '''art["board_frame"] = load("res://assets/v05/board_frame.png") as Texture2D
    art["render_logo"] = load("res://assets/v05/logo.png") as Texture2D
    art["cracked"] = load("res://assets/v05/cracked.png") as Texture2D
    art["lock"] = load("res://assets/v05/lock.png") as Texture2D
    art["booster_plate"] = load("res://assets/v05/booster_plate.png") as Texture2D''')
old='''    music_player = AudioStreamPlayer.new()
    var ambience := load("res://assets/audio/enchanted_library.ogg")
    if ambience is AudioStreamOggVorbis:
        ambience.loop = true
    music_player.stream = ambience
    music_player.volume_db = -4
    add_child(music_player)
    _music_state()'''
new='''    music_player = AudioStreamPlayer.new()
    music_alt_player = AudioStreamPlayer.new()
    add_child(music_player)
    add_child(music_alt_player)
    for track in ["menu", "runes", "egypt", "asia", "mixed"]:
        var stream: AudioStream = load("res://assets/audio/worlds/" + track + ".ogg")
        if stream is AudioStreamOggVorbis:
            (stream as AudioStreamOggVorbis).loop = true
        world_tracks.append(stream)
    _music_state()'''
swap(old,new)
swap('''    clock += delta
    if fall_age < 1.0:''','''    clock += delta
    if impact_flash > 0.0:
        impact_flash = maxf(0.0, impact_flash-delta*2.1)
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
    if fall_age < 1.0:''')
swap('''    _tex("title", Rect2(x,y,w,h))
    _fancy(Brand.TITLE_LINE_1,x+w*0.50,y+h*0.47,int(h*0.27))
    _fancy(Brand.TITLE_LINE_2,x+w*0.50,y+h*0.72,int(h*0.23))''','''    _tex("render_logo", Rect2(x,y,w,h))''')
# board, UI layout, objective & status reworked to reference composition
replacefunc("_draw_game","_draw_fx",'''func _draw_game() -> void:
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
    _label("LEVEL %s  •  %s" % [level, WORLD_TAGLINES[world_index]] if mode=="quest" else "ARCADE  •  %s" % WORLD_SHORT[world_index], 356, 232, 18, INK, true, display_font)
    # Compact parchment goal HUD with gem progress and fewer nested boxes.
    _tex("parchment", Rect2(42, 287, 636, 107))
    var amount := 0
    var goal := 0
    if mode == "quest":
        amount = start_gems-QuestRules.remaining(board)
        goal = start_gems
        _label("CLEAR THE BOARD", 170, 328, 25, INK, false, display_font)
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
                _rect(rect.grow(-13),Color(0.02,0.04,0.1,0.53),8)
                continue
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
                _tex("lock",rect)
    _label(status_message,360,1140,19,CREAM,true)
    _draw_booster(0,hints_left,"HINT","booster_0")
    _draw_booster(1,shuffles_left,"SHUFFLE","booster_2")
    _draw_booster(2,hammers_left,"HAMMER","booster_1")
    _draw_booster(3,undo_left,"UNDO","undo")
    _draw_fx()''')
replacefunc("_draw_fx","_modal",'''func _draw_fx() -> void:
    var calm := save.pref("reduce_motion")
    # The render's purple-white matching glow, expanding halo and gold sparks.
    for burst in impact_fx:
        var p: Vector2=burst["pos"]
        var t:=clampf(float(burst["life"])/.72,0.0,1.0)
        var color: Color=burst["color"]
        var radius:=26.0+(1.0-t)*58.0
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
        var font_size:=34 if not text_value.begins_with("COMBO") else 25
        _label(text_value,pos.x+2,yy+3,font_size,Color(.18,.03,.24,t),true,display_font)
        _label(text_value,pos.x,yy,font_size,Color(1,.77,.35,t),true,display_font)''')
# FX events in match resolve
swap('''        var hit_map := {}
        for idx in hits:''','''        var hit_map := {}
        if not save.pref("reduce_motion"):
            impact_flash=1.0
        for idx in hits:''')
swap('''            if sparkles.size() < 150:
                _emit_fx(idx, GEM_COLORS[board[idx]])
        _start_fall_animation(hit_map)''','''            if sparkles.size() < 350:
                _emit_fx(idx, GEM_COLORS[board[idx]])
            if impact_fx.size()<96:
                impact_fx.append({"pos":ORIGIN+Vector2((idx%COLS)*CELL+CELL*.5,int(idx/COLS)*CELL+CELL*.5),"life":.72,"color":GEM_COLORS[board[idx]]})
        var result: Dictionary = QuestRules.adjacent_obstacles(board,locks,hits)
        for cracked in result["cracked"]:
            _emit_fx(int(cracked),GOLD)
        for unlocked in result["unlocked"]:
            _emit_fx(int(unlocked),Color("#a5edff"))
        _start_fall_animation(hit_map)''')
swap('''        QuestRules.settle(board)
        if mode == "arcade":''','''        QuestRules.settle(board,locks)
        if mode == "arcade":''',1)
swap('''        popups.append({"text": "+%s" % points, "life": 1.0, "pos": Vector2(360, 720)})''','''        popups.append({"text": "+%s" % points, "life": 1.0, "pos": Vector2(360, 735)})
        if combo > 1:
            popups.append({"text":"COMBO x%s!" % combo,"life":1.0,"pos":Vector2(360,790)})''')
swap('''    var center:=ORIGIN+Vector2((idx%COLS)*CELL+39,int(idx/COLS)*CELL+39)
    for j in range(5):''','''    var center:=ORIGIN+Vector2((idx%COLS)*CELL+CELL*.5,int(idx/COLS)*CELL+CELL*.5)
    for j in range(10):''')
swap('''            "life":randf_range(.3,.62),"color":clr''','''            "life":randf_range(.35,.72),"color":clr''')
# add lock_states to session/persistence and reject old board layouts
swap('''    undo_history.clear()
    hammer_mode = false''','''    undo_history.clear()
    boosters_used=0
    locks.clear()
    impact_fx.clear()
    hammer_mode = false''')
swap('''    _create_board()
    start_gems = QuestRules.remaining(board)
    state = "playing" if bool(save.data.get("tutorial_done_v04", false)) else "tutorial"''','''    _create_board()
    start_gems = QuestRules.remaining(board)
    state = "playing" if bool(save.data.get("tutorial_done_v05", false)) else "tutorial"''')
swap('''    if not current.has("mode"):
        # Never reinterpret a v0.3 refilling board as a v0.4 finite puzzle.''','''    if int(current.get("board_version", 0)) != 5:
        # Preserve completed stars, but do not reinterpret old puzzle layouts.''')
swap('''    board.clear()
    for value in restored:
        board.append(clampi(int(value), QuestRules.WALL, 5))''','''    board.clear()
    for value in restored:
        board.append(clampi(int(value), QuestRules.CRACK, 5))
    locks.clear()
    for value in current.get("locks", []):
        locks.append(clampi(int(value),0,2))
    if locks.size()!=64:locks.resize(64);locks.fill(0)
    reference_moves=maxi(1,int(current.get("reference_moves",12)))
    boosters_used=maxi(0,int(current.get("boosters_used",0)))''')
swap('''    state = "playing" if bool(save.data.get("tutorial_done_v04", false)) else "tutorial"''','''    state = "playing" if bool(save.data.get("tutorial_done_v05", false)) else "tutorial"''')
swap('''        "mode": mode, "world": world_index, "level": level, "board": board.duplicate(),''','''        "mode": mode,"board_version":5,"world": world_index, "level": level, "board": board.duplicate(),
        "locks":locks.duplicate(),"reference_moves":reference_moves,"boosters_used":boosters_used,''')
swap('''        board = scene["board"].duplicate()
        if not QuestRules.certified_solution(world_index, level):''','''        board = scene["board"].duplicate()
        locks = scene["locks"].duplicate()
        reference_moves = int(scene["min_certified_moves"])
        if not QuestRules.certified_solution(world_index, level):''')
swap('''    # Preserve the original refill-based match-three for optional Arcade Mode.
    for attempt in range(350):''','''    # Preserve the original refill-based match-three for optional Arcade Mode.
    locks.resize(64)
    locks.fill(0)
    for attempt in range(350):''')
swap('''    var options := QuestRules.legal_moves(board)''','''    var options := QuestRules.legal_moves(board,locks)''')
swap('''    if board[a] < 0 or board[b] < 0:
        status_message = "Stone walls and empty sockets cannot be swapped."
        return''','''    if board[a] < 0 or board[b] < 0:
        status_message = "Obstacles and empty sockets cannot be swapped."
        return
    if locks.size()==64 and (locks[a]>0 or locks[b]>0):
        status_message="A locked gem must be freed by a neighboring match!"
        _play_sound("fail")
        return''')
swap('''    QuestRules.settle(board)
    if mode == "arcade":''','''    if locks.size()==64:locks[idx]=0
    QuestRules.settle(board,locks)
    boosters_used+=1
    if mode == "arcade":''',1)
swap('''        if board[idx] >= 0:
            positions.append(idx)
            colors.append(board[idx])''','''        if board[idx] >= 0 and (locks.is_empty() or locks[idx]==0):
            positions.append(idx)
            colors.append(board[idx])''')
swap('''        if QuestRules.scan(new_board).is_empty() and not QuestRules.legal_moves(new_board).is_empty():''','''        if QuestRules.scan(new_board).is_empty() and not QuestRules.legal_moves(new_board,locks).is_empty():''')
swap('''    shuffles_left -= 1
    selected = -1''','''    shuffles_left -= 1
    boosters_used+=1
    selected = -1''')
swap('''                        hints_left -= 1
                        _show_hint()''','''                        hints_left -= 1
                        boosters_used+=1
                        _show_hint()''')
swap('''                save.data["tutorial_done_v04"] = true''','''                save.data["tutorial_done_v05"] = true''')
swap('''        "board": board.duplicate(),
        "score": score, "moves": moves_left, "moves_used": moves_used,''','''        "board": board.duplicate(),"locks":locks.duplicate(),"boosters_used":boosters_used,
        "score": score, "moves": moves_left, "moves_used": moves_used,''')
swap('''    for item in restored:
        board.append(int(item))
    score = int(last["score"])''','''    for item in restored:
        board.append(int(item))
    locks.clear()
    for item in last.get("locks",[]):
        locks.append(int(item))
    if locks.size()!=64:locks.resize(64);locks.fill(0)
    boosters_used=int(last.get("boosters_used",0))
    score = int(last["score"])''')
swap('''if board[bottom * COLS + col] == QuestRules.WALL:''','''if board[bottom * COLS + col] in [QuestRules.WALL,QuestRules.CRACK]:''')
swap('''while top >= 0 and board[top * COLS + col] != QuestRules.WALL:''','''while top >= 0 and board[top * COLS + col] not in [QuestRules.WALL,QuestRules.CRACK]:''')
# Success only after complete clearing; targets based on certified solution length.
old='''        if left == 0 or _find_hint().is_empty():
            var percent := float(cleared) / float(maxi(1, start_gems))
            earned_stars = 3 if left == 0 else (2 if percent >= 0.85 else (1 if percent >= 0.65 else 0))
            if earned_stars > 0:
                state = "victory"
                status_message = "PERFECT CLEAR!" if left == 0 else "BOARD COMPLETE!"
                save.record_victory(world_index, level, score, earned_stars)
                _play_sound("win")
                _vibrate(70)
            else:
                state = "failure"
                status_message = "No legal matches remain."
                save.clear_current()
                _play_sound("fail")'''
new='''        if left == 0:
            earned_stars=1
            if moves_used<=ceili(float(reference_moves)*1.20):earned_stars+=1
            if moves_used<=reference_moves and boosters_used==0:earned_stars+=1
            state="victory"
            status_message="PERFECT CLEAR!"
            save.record_victory(world_index,level,score,earned_stars)
            _play_sound("win")
            _vibrate(70)
        elif _find_hint().is_empty():
            state="failure"
            status_message="No legal matches remain. Try a different strategy!"
            save.clear_current()
            _play_sound("fail")'''
swap(old,new)
# world soundtrack management with 0.75-second crossfade
replacefunc("_music_state","_start_arcade",'''func _music_state() -> void:
    if music_player == null or world_tracks.size()!=5:
        return
    var game_context:=state in ["playing","paused","victory","failure","tutorial"] or (state=="settings" and settings_return=="paused")
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
        if not music_player.playing:music_player.play()''')
# logo controls in reference screenshot, adjust touch
replacefunc("_draw_nav_icons","_draw_booster",'''func _draw_nav_icons() -> void:
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
''')
replacefunc("_draw_booster","_draw_live_gem",'''func _draw_booster(index: int,count: int,label: String,key: String) -> void:
    var x:=12.0+float(index)*175.0
    _tex("booster_plate",Rect2(x,1165,164,156),Color.WHITE if count>0 else Color(.55,.55,.63,.8))
    _tex(key,Rect2(x+34,1177,98,91))
    _rect(Rect2(x+115,1180,38,34),Color("#281940"),15,GOLD,2)
    _label(str(count),x+134,1203,19,GOLD,true)
    _label(label,x+81,1303,18,CREAM,true,display_font)
    if index==2 and hammer_mode:
        _rect(Rect2(x+5,1170,154,145),Color.TRANSPARENT,18,Color("#b4fff9"),3)
''')
swap('''    if save.pref("color_assist"):
        _label(str(tile + 1), rect.position.x + rect.size.x - 12, rect.position.y + 18, 13, Color("#ffedac"), true)''','''    if save.pref("color_assist"):
        _label(str(tile + 1), rect.position.x + rect.size.x - 13, rect.position.y + 18, 14, Color("#ffedac"), true)''')
swap('''    if _inside(p, 18, 50, 88, 85):''','''    if _inside(p, 10, 55, 77, 76):''')
swap('''    if _inside(p, 619, 50, 89, 85):''','''    if _inside(p, 638, 176, 82, 86):''')
swap('''        if _inside(p, x, 1186, 168, 132):''','''        if _inside(p, x, 1162, 168, 156):''')
# use settings return and menu state changes to switch music
swap('''    queue_redraw()

func _back() -> void:''','''    _music_state()
    queue_redraw()

func _back() -> void:''')
# update text
swap('''        _label("Clear the board for three stars!", 360, 727, 21, CREAM, true)''','''        _label("Finish using few moves for extra stars!", 360, 727, 20, CREAM, true)''')
swap('''        _label("remain or the board is empty.", 360, 794, 21, CREAM, true)''','''        _label("remain or the board is empty.", 360, 794, 21, CREAM, true)''')
# fix duplicated title text in UI footer
s=s.replace('v0.4.0"','v0.5.0"')
p.write_text(s)
print("Patched",p,"bytes",len(s))
