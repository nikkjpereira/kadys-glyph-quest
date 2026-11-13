from pathlib import Path
old = '''        _tex("world_%d" % i, Rect2(xx + 5, yy + 5, 100, 84))
        _panel(Rect2(xx, yy, 300, 95), Color("#3d255a") if world_index == i else Color("#2b1b44"), false, 0.12)'''
new = '''        _panel(Rect2(xx, yy, 300, 95), Color("#3d255a") if world_index == i else Color("#2b1b44"), false, 0.94)
        _tex("world_%d" % i, Rect2(xx + 16, yy + 12, 85, 71))'''
for name in ["scripts/main.gd","tools/v04_ui.gdpart"]:
    p=Path(name)
    s=p.read_text()
    assert old in s,name
    p.write_text(s.replace(old,new,1))
p=Path("scripts/quest_rules.gd")
s=p.read_text().replace("The row-gadget construction is intentionally solvable, not random luck:","The row/column gadget construction is intentionally solvable, not random luck:").replace("Clearing complete rows bottom-up always wins.","Clearing complete rows or columns along the certified path always wins.")
p.write_text(s)
print("Updated opaque world cards and puzzle docs.")
