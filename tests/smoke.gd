extends SceneTree
const QuestRules=preload("res://scripts/quest_rules.gd")
const SaveData=preload("res://scripts/save_data.gd")
func _initialize() -> void:
    call_deferred("_run")
func fail(reason:String,world:int=-1,level:int=-1)->void:
    push_error("SMOKE FAIL: %s at %s-%s" % [reason,world,level])
    quit(1)
func _run()->void:
    var gem_floor:=999
    var max_gems:=0
    var locked_total:=0
    var ice_total:=0
    var chain_total:=0
    var cracked_total:=0
    var path_lengths: Array[int]=[]
    for w in range(4):
        for lvl in range(1,13):
            var d:Dictionary=QuestRules.generate(w,lvl)
            var board:Array[int]=d["board"]
            var seals:Array[int]=d["locks"]
            var types:Array[int]=d["seal_types"]
            if board.size()!=64 or seals.size()!=64 or types.size()!=64:
                fail("invalid board dimensions",w,lvl);return
            var n:=QuestRules.remaining(board)
            gem_floor=mini(gem_floor,n)
            max_gems=maxi(max_gems,n)
            if n<54 or n>60 or not board.slice(0,8).any(func(x):return x>=0):
                fail("board too sparse or entire top row empty",w,lvl);return
            if not QuestRules.scan(board).is_empty():
                fail("prematched starting gems",w,lvl);return
            if QuestRules.legal_moves(board,seals).is_empty():
                fail("no starting legal move",w,lvl);return
            var proof_steps:=int(d["min_certified_moves"])
            path_lengths.append(proof_steps)
            if proof_steps<18:
                fail("too-short certified solution",w,lvl);return
            if not QuestRules.certified_solution(w,lvl):
                fail("puzzle certificate failed replay",w,lvl);return
            for k in range(64):
                if board[k]==QuestRules.CRACK:cracked_total+=1
                if types[k]==1:locked_total+=1
                if types[k]==2:chain_total+=1
                if types[k]==3:ice_total+=1
    if ice_total<8 or chain_total<6 or cracked_total<6:
        fail("new obstacles missing");return
    var brand=load("res://scripts/brand_config.gd")
    if brand.DISPLAY_NAME!="Runefall" or brand.VERSION!="0.6.2":
        fail("Runefall branding metadata mismatch");return
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    game.mode="quest"
    if game.world_tracks.size()!=5:
        fail("world-specific audio missing");return
    for w in range(4):
        game._start_level(w,1)
        var d:Dictionary=QuestRules.generate(w,1)
        var old:Array[int]=game.board.duplicate()
        var old_seals:Array[int]=game.locks.duplicate()
        var old_types:Array[int]=game.seal_types.duplicate()
        var first:Vector2i=QuestRules.solution_pair(d,0)
        game._attempt_swap(first.x,first.y)
        if game.moves_used!=1 or QuestRules.remaining(game.board)>=int(d["gem_count"]):
            fail("matching failed to clear",w,1);return
        game._undo_last()
        if game.board!=old or game.locks!=old_seals or game.seal_types!=old_types:
            fail("Undo didn't restore sealed gem state",w,1);return
        for step in d["solution"]:
            if game.state!="playing":
                fail("premature level end",w,1);return
            game._attempt_swap(int(step[0]),int(step[1]))
        if game.state!="victory" or QuestRules.remaining(game.board)!=0:
            fail("failed certified empty-board victory",w,1);return
        if game.save.unlocked_level(w)<2:
            fail("completed level didn't unlock next",w,1);return
    game._start_level(0,2)
    game.score=999999
    game._finish_or_save()
    if game.state!="playing":
        fail("quest incorrectly completed on score");return
    # Test that a stalemate with gems remaining is a failure.
    for i in range(64):
        if game.board[i]>=0:game.board[i]=i%2
    if QuestRules.legal_moves(game.board,game.locks).is_empty():
        game._finish_or_save()
        if game.state!="recovery":
            fail("stalemate before 75% didn't offer rescue");return
    game._start_level(0,2)
    var before:=QuestRules.remaining(game.board)
    game._shuffle()
    if QuestRules.remaining(game.board)!=before:
        fail("shuffle added/removed gems");return
    game._start_level(0,2)
    var idx:=-1
    for i in range(64):
        if game.board[i]>=0 and game.locks[i]==0:idx=i;break
    if idx>=0:
        before=QuestRules.remaining(game.board)
        game._hammer(idx)
        if QuestRules.remaining(game.board)>=before:
            fail("hammer didn't remove a gem");return
    var prior=SaveData.new()
    prior.load_all()
    if prior.unlocked_level(0)<2:
        fail("progress not saved");return
    if prior.data["schema"]!=3:
        fail("save schema not migrated");return
    prior.toggle_pref("gem_shimmer")
    var restored=SaveData.new()
    restored.load_all()
    if prior.pref("gem_shimmer")!=restored.pref("gem_shimmer"):
        fail("effect setting didn't persist");return
    game.mode="arcade"
    game._start_arcade(0)
    if QuestRules.remaining(game.board)!=64:
        fail("Arcade board isn't full");return
    var hint:Array=game._find_hint()
    game._attempt_swap(hint[0],hint[1])
    if QuestRules.remaining(game.board)!=64:
        fail("Arcade no longer refills");return
    game.save.reset_progress()
    print("PASS: V0.6 DENSE CERTIFIED PUZZLES: 48 boards %s-%s gems, solutions %s-%s, %s locks, %s ice, %s chains, %s cracked; save, undo, no-refill, arcade" % [gem_floor,max_gems,path_lengths.min(),path_lengths.max(),locked_total,ice_total,chain_total,cracked_total])
    quit(0)
