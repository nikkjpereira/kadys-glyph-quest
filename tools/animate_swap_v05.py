from pathlib import Path
p=Path(__file__).resolve().parents[1]/"scripts"/"main.gd"
s=p.read_text()
def rep(old,new):
    global s
    if s.count(old)!=1:raise Exception("Expected one replacement: "+old[:80])
    s=s.replace(old,new)
rep("var impact_fx: Array[Dictionary] = []\nvar impact_flash := 0.0",
"""var impact_fx: Array[Dictionary] = []
var impact_flash := 0.0
var swap_ghosts: Array[Dictionary] = []
var swap_age := 1.0
var rejected_cells: Array[int] = []
var reject_age := 1.0""")
rep("""    if impact_flash > 0.0:
        impact_flash = maxf(0.0, impact_flash-delta*2.1)
        queue_redraw()""",
"""    if impact_flash > 0.0:
        impact_flash = maxf(0.0, impact_flash-delta*2.1)
        queue_redraw()
    if swap_age < 1.0:
        swap_age = minf(1.0,swap_age+delta/.21)
        if swap_age >= 1.0:swap_ghosts.clear()
        queue_redraw()
    if reject_age < 1.0:
        reject_age = minf(1.0,reject_age+delta/.25)
        if reject_age >= 1.0:rejected_cells.clear()
        queue_redraw()""")
rep("""            if hint_cells.has(idx):
                _rect(rect.grow(3),Color("#d5fcff"),13)""",
"""            if rejected_cells.has(idx):
                _rect(rect.grow(3),Color(1,.24,.44,.58*(1.0-reject_age)),13)
            if hint_cells.has(idx):
                _rect(rect.grow(3),Color("#d5fcff"),13)""")
rep("""    for p in sparkles:
        var life: float=p["life"]""",
"""    if swap_age < 1.0:
        var eased:=swap_age*swap_age*(3.0-2.0*swap_age)
        for g in swap_ghosts:
            var pos: Vector2=(g["from"] as Vector2).lerp(g["to"] as Vector2,eased)
            var gem_rect:=Rect2(ORIGIN+pos*CELL+Vector2(1,1),Vector2(CELL-2,CELL-2))
            _draw_live_gem(gem_rect,int(g["value"]),int(g["target"]))
    for p in sparkles:
        var life: float=p["life"]""")
rep("""    if _find_matches().is_empty():
        _swap_values(a, b)
        status_message = "That swap didn't make a match."
        _reset_idle()
        return""",
"""    if _find_matches().is_empty():
        _swap_values(a, b)
        status_message = "That swap didn't make a match."
        if not save.pref("reduce_motion"):
            rejected_cells=[a,b]
            reject_age=0.0
        _reset_idle()
        return""")
rep("""    _swap_values(a, b)
    _push_undo()
    _swap_values(a, b)
    moves_used += 1""",
"""    _swap_values(a, b)
    _push_undo()
    if not save.pref("reduce_motion"):
        swap_ghosts=[
            {"from":Vector2(a%COLS,int(a/COLS)),"to":Vector2(b%COLS,int(b/COLS)),"value":board[a],"target":b},
            {"from":Vector2(b%COLS,int(b/COLS)),"to":Vector2(a%COLS,int(a/COLS)),"value":board[b],"target":a}
        ]
        swap_age=0.0
    _swap_values(a, b)
    moves_used += 1""")
rep("""    fall_ghosts.clear()
    fall_age = 1.0
    hint_cells.clear()""",
"""    fall_ghosts.clear()
    fall_age = 1.0
    swap_ghosts.clear()
    swap_age=1.0
    impact_fx.clear()
    hint_cells.clear()""")
p.write_text(s)
print("Animated swap overlay and invalid-swap feedback patched")
