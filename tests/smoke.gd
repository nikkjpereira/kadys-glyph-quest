extends SceneTree
const QuestRules=preload("res://scripts/quest_rules.gd")
const SaveData=preload("res://scripts/save_data.gd")
func _initialize() -> void:
    call_deferred("_run")
func fail(reason:String,world:int=-1,level:int=-1) -> void:
    push_error("SMOKE FAIL: %s (%s-%s)" % [reason,world,level])
    quit(1)
func _run() -> void:
    var ice_count:=0
    var chain_count:=0
    var min_steps:=999
    var max_steps:=0
    var cracked_levels:=0
    var locked_levels:=0
    for world in range(4):
        for level in range(1,13):
            var scene:Dictionary=QuestRules.generate(world,level)
            var tiles:Array[int]=scene["board"]
            var seals:Array[int]=scene["locks"]
            if tiles.size()!=64 or seals.size()!=64:
                fail("Puzzle dimensions invalid",world,level);return
            if QuestRules.remaining(tiles)!=int(scene["gem_count"]) or not QuestRules.scan(tiles).is_empty():
                fail("Puzzle count mismatch/pre-matches",world,level);return
            var types: Array[int]=scene["seal_types"]
            if types.size()!=64:
                fail("Seal type array malformed",world,level);return
            if QuestRules.remaining(tiles)<54 or QuestRules.remaining(tiles)>60:
                fail("Starting board not dense",world,level);return
            var count_top:=0
            for v in tiles.slice(0,8):
                if v>=0:count_top+=1
            if count_top<2:
                fail("Too many empty cells at top",world,level);return
            if QuestRules.legal_moves(tiles,seals).is_empty():
                fail("Puzzle has no initial legal move",world,level);return
            if not QuestRules.certified_solution(world,level):
                fail("Booster-free full clear not certified",world,level);return
            var steps:=int(scene["min_certified_moves"])
            if steps<18:
                fail("Puzzle is still trivially short",world,level);return
            min_steps=mini(min_steps,steps)
            max_steps=maxi(max_steps,steps)
            var obstacles:=0
            for v in tiles:
                if v in [QuestRules.WALL,QuestRules.CRACK]:obstacles+=1
                if v==QuestRules.CRACK:cracked_levels+=1
            if obstacles>5:
                fail("Too many stone blockers",world,level);return
            for i in range(types.size()):
                if seals[i]>0:locked_levels+=1
                if types[i]==2:chain_count+=1
                if types[i]==3:ice_count+=1
    if max_steps<19 or locked_levels<10 or cracked_levels<2 or chain_count<4 or ice_count<4:
        fail("Missing advanced layouts/obstacles");return
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    game.mode="quest"
    if game.world_tracks.size()!=5:
        fail("Missing original world soundtracks");return
    for world in range(4):
        game._start_level(world,1)
        var before:Array[int]=game.board.duplicate()
        var original_locks:Array[int]=game.locks.duplicate()
        var scene:Dictionary=QuestRules.generate(world,1)
        var path:Array=scene["solution"]
        var pair=QuestRules.solution_pair(scene,0)
        if not QuestRules.can_match(game.board,pair.x,pair.y,game.locks):
            fail("First certified move blocked",world,1);return
        game._attempt_swap(pair.x,pair.y)
        if game.moves_used!=1 or QuestRules.remaining(game.board)>=int(scene["gem_count"]):
            fail("Move did not reduce finite gems",world,1);return
        if game.state!="playing":
            fail("Ended after first move",world,1);return
        game._undo_last()
        if game.board!=before or game.locks!=original_locks or game.moves_used!=0:
            fail("Undo did not restore tile/lock states",world,1);return
        if game.undo_left!=2:
            fail("Undo charge missing",world,1);return
        for k in range(path.size()):
            var move:Vector2i=QuestRules.solution_pair(scene,k)
            if game.state!="playing":
                fail("Quest ended before puzzle was cleared",world,1);return
            game._attempt_swap(move.x,move.y)
        if game.state!="victory" or QuestRules.remaining(game.board)!=0:
            fail("Quest failed full board clear",world,1);return
        if game.earned_stars!=3 or game.save.unlocked_level(world)<2:
            fail("Certified perfect clear did not earn three stars",world,1);return
    game._start_level(0,2)
    game.score=999999
    game.collected=999
    game._finish_or_save()
    if game.state!="playing":
        fail("Quest erroneously completed on score");return
    # Stalemate must fail even at high percentage; game is about empty boards.
    var occupied:Array[int]=[]
    for i in range(64):
        if game.board[i]>=0:occupied.append(i)
    for i in range(occupied.size()):
        game.board[occupied[i]]=QuestRules.EMPTY if i>=2 else i
    game._finish_or_save()
    if game.state!="failure":
        fail("Remaining gems at stalemate counted as victory");return
    game._start_level(0,2)
    var count_start:=QuestRules.remaining(game.board)
    game._shuffle()
    if QuestRules.remaining(game.board)!=count_start:
        fail("Quest shuffle changed gem count");return
    game._start_level(0,2)
    count_start=QuestRules.remaining(game.board)
    var chosen:=-1
    for idx in range(64):
        if game.board[idx]>=0 and game.locks[idx]==0:
            chosen=idx;break
    game._hammer(chosen)
    if QuestRules.remaining(game.board)>=count_start:
        fail("Hammer refilled a gem");return
    # Locked tiles must be inaccessible until adjacent match.
    game._start_level(0,9)
    var seal:=-1
    for idx in range(64):
        if game.locks[idx]>0:seal=idx;break
    if seal>=0:
        var nbr:=QuestRules.neighbors(seal)
        for other in nbr:
            if game.board[other]>=0 and game.board[other]!=game.board[seal]:
                var original_move_count:int=game.moves_used
                game._attempt_swap(seal,other)
                if game.moves_used!=original_move_count:
                    fail("Swapped a locked gem");return
                break
    var progress=SaveData.new()
    progress.load_all()
    if progress.unlocked_level(0)<2:
        fail("Completed levels not persisted");return
    progress.toggle_pref("reduce_motion")
    var check=SaveData.new()
    check.load_all()
    if progress.pref("reduce_motion")!=check.pref("reduce_motion"):
        fail("Setting failed persistence");return
    game.mode="arcade"
    game._start_arcade(0)
    if QuestRules.remaining(game.board)!=64:
        fail("Arcade board not full");return
    var hint:Array=game._find_hint()
    game._attempt_swap(hint[0],hint[1])
    if QuestRules.remaining(game.board)!=64:
        fail("Arcade no longer replenishes");return
    game.save.record_victory(0,3,1200,3)
    if not game.save.has_relic(0,0) or game.save.world_stage(0)<1:
        fail("Relic and world restoration milestones failed");return
    if game.save.relic_total()<1:
        fail("Relic count failed");return
    game.save.toggle_pref("ambient_motion")
    var loaded_settings=SaveData.new()
    loaded_settings.load_all()
    if loaded_settings.pref("ambient_motion")!=game.save.pref("ambient_motion"):
        fail("Visual effects setting not persisted");return
    game.save.reset_progress()
    print("PASS: V0.6 DENSE WORLDS: 48 levels, %s-%s certified moves, ice/chain/cracked stone, artifacts, restoration, FX prefs, no refill, undo, saves, arcade" % [min_steps,max_steps])
    quit(0)
