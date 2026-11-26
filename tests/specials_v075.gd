extends SceneTree
## Special gem powers are optional metadata; old certified Quest solutions unchanged.
const Rules=preload("res://scripts/quest_rules.gd")
func _initialize()->void:
    call_deferred("_run")
func fail(s:String)->void:
    push_error("V075 SPECIAL FAIL: "+s)
    quit(1)
func _run()->void:
    var tiles:Array[int]=[]
    tiles.resize(64)
    tiles.fill(Rules.EMPTY)
    for i in range(4):tiles[i]=2
    tiles[4]=1
    if Rules.special_kind(tiles)!=1 or Rules.special_anchor(tiles,[0,1,2,3])!=4:
        fail("horizontal four-match or surviving anchor");return
    tiles.fill(Rules.EMPTY)
    for i in range(4):tiles[i*8]=2
    if Rules.special_kind(tiles)!=2:
        fail("vertical four-match");return
    tiles.fill(Rules.EMPTY)
    for i in range(5):tiles[i]=2
    if Rules.special_kind(tiles)!=3:
        fail("five-match wildcard");return
    tiles.fill(Rules.EMPTY)
    for idx in [19,26,27,28,35]:tiles[idx]=4
    if Rules.special_kind(tiles)!=4:
        fail("cross/T area explosion");return
    tiles.fill(Rules.EMPTY)
    tiles[0]=1
    tiles[8]=2
    var powers:Array[int]=[]
    powers.resize(64)
    powers.fill(0)
    powers[0]=3
    Rules.settle(tiles,[],[],powers)
    if tiles[48]!=1 or tiles[56]!=2 or powers[48]!=3 or powers[56]!=0:
        fail("Gravity did not preserve special rune identity");return
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    game.mode="quest"
    game._start_level(0,2)
    var before:Array[int]=game.board.duplicate()
    var index: int=-1
    for i in range(64):
        if game.board[i]>=0 and game.locks[i]==0:
            index=i
            break
    if index<0:fail("No available test gem");return
    game.powers[index]=1
    game._save_current()
    var saved:Array=game.save.data["current"].get("powers",[])
    if saved.size()!=64 or saved[index]!=1:
        fail("Special not saved");return
    if not game._resume_saved() or game.powers[index]!=1:
        fail("Special not restored");return
    game._activate_special(index)
    if Rules.remaining(game.board)>=Rules.remaining(before):
        fail("Special failed to clear existing gems");return
    if Rules.remaining(game.board)>Rules.remaining(before):
        fail("Special created replacement gems in Quest");return
    game._undo_last()
    if game.board!=before or game.powers[index]!=1:
        fail("Undo failed to restore board and power");return
    if not Rules.certified_solution(0,2):
        fail("Original Quest solution is no longer valid");return
    game.save.reset_progress()
    print("PASS: V0.7.5 SPECIALS: match 4/5/cross, existing-cell powers, gravity, save, optional activation and Undo")
    quit(0)
