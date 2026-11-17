from pathlib import Path
p=Path("/root/kadys-glyph-quest/scripts/main.gd")
s=p.read_text()
def swap(a,b,n=1):
 global s
 k=s.count(a)
 if k!=n:raise ValueError((a[:85],k,n))
 s=s.replace(a,b)
swap('var draw_layout_landscape := false','var draw_layout_landscape := false\nvar draw_layout_tablet_portrait := false')
swap('''func _logical_size() -> Vector2:
    return Vector2(1600,900) if get_viewport_rect().size.x > get_viewport_rect().size.y*1.35 else BASE_SIZE''','''func _logical_size() -> Vector2:
    var v:=get_viewport_rect().size
    if v.x>v.y*1.25:return Vector2(1600,900)
    if v.x>v.y*.59:return Vector2(900,1440)
    return BASE_SIZE''')
swap('''    draw_layout_landscape=get_viewport_rect().size.x>get_viewport_rect().size.y*1.35
    if draw_layout_landscape:
        CELL=78.0
        ORIGIN=Vector2(42,143)
    else:
        CELL=82.0
        ORIGIN=Vector2(32,429)''','''    var v:=get_viewport_rect().size
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
        ORIGIN=Vector2(32,429)''')
swap('''    draw_set_transform(_offset(),0.0,_scale())
    if draw_layout_landscape:''','''    var extra_x:=90.0 if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","tutorial"] else 0.0
    draw_set_transform(_offset()+Vector2(extra_x,0)*_scale(),0.0,_scale())
    if draw_layout_landscape:''')
swap('''    else:
        _background()
        match state:''','''    elif draw_layout_tablet_portrait and state in ["playing","paused","victory","failure","tutorial"]:
        _background()
        _draw_portrait_tablet_game()
        if state!="playing":_draw_portrait_tablet_overlay()
    else:
        _background()
        match state:''')
swap('touch_start = (e.position-_offset())/_scale()','touch_start = (e.position-_offset())/_scale()-Vector2(90,0) if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","tutorial"] else (e.position-_offset())/_scale()',2)
swap('_gesture(touch_start,(e.position-_offset())/_scale())','_gesture(touch_start,(e.position-_offset())/_scale()-Vector2(90,0) if draw_layout_tablet_portrait and state not in ["playing","paused","victory","failure","tutorial"] else (e.position-_offset())/_scale())',2)
swap('''    match state:
        "menu": _touch_menu(p)''','''    if draw_layout_tablet_portrait and state in ["playing","paused","victory","failure","tutorial"]:
        _gesture_portrait_tablet(start,p)
        _music_state()
        queue_redraw()
        return
    match state:
        "menu": _touch_menu(p)''')
funcs=r'''func _draw_portrait_tablet_game() -> void:
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
    _label("CLEAR THE BOARD" if mode=="quest" else "ARCADE OBJECTIVE",177,347,25,INK,false,display_font)
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
        _label("CLEAR EVERY GEM TO COMPLETE THE LEVEL",450,675,20,GOLD,true)
        _button(Rect2(200,822,500,84),"LET'S PLAY!",true,27)
    else:
        _label("GEMS REMOVED: %s / %s" % [start_gems-QuestRules.remaining(board),start_gems],450,614,24,GOLD,true)
        _button(Rect2(200,733,500,84),"NEXT LEVEL" if state=="victory" else "RETRY",true,28)
        _button(Rect2(200,853,500,84),"HOME")

func _gesture_portrait_tablet(start:Vector2,p:Vector2)->void:
    if state=="playing":
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
    elif state in ["victory","failure"]:
        if _inside(p,200,733,500,84):
            if mode=="arcade":_start_arcade(world_index)
            elif state=="victory":_start_level(world_index,mini(12,level+1))
            else:_start_level(world_index,level)
        elif _inside(p,200,853,500,84):state="menu"

'''
where=s.index("func _draw_tablet_game() -> void:")
s=s[:where]+funcs+s[where:]
p.write_text(s)
print("ADAPTIVE TABLET PORTRAIT PATCH OK")
