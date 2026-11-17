extends SceneTree
## Runefall v0.6.2 fair-quest regression tests. No network or billing required.
const Rules=preload("res://scripts/quest_rules.gd")
const Progress=preload("res://scripts/quest_progress.gd")

func _initialize() -> void:
    call_deferred("_run")

func fail(reason: String)->void:
    push_error("FAIR QUEST FAIL: "+reason)
    quit(1)

func _run() -> void:
    # Exact integer boundaries. Do not round fractional clear rates up.
    if Progress.stars(60,16)!=0 or Progress.stars(60,15)!=1:
        fail("75% threshold incorrect");return
    if Progress.stars(60,10)!=1 or Progress.stars(60,9)!=2:
        fail("85% threshold incorrect");return
    if Progress.stars(60,1)!=2 or Progress.stars(60,0)!=3:
        fail("100% threshold incorrect");return
    if Progress.stars(57,15)!=0 or Progress.stars(57,14)!=1:
        fail("57-gem integer threshold incorrect");return

    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    game.mode="quest"
    game._start_level(0,1)
    var puzzle:Dictionary=Rules.generate(0,1)
    var initial:Vector2i=Rules.solution_pair(puzzle,0)
    if game._find_hint()!=[initial.x,initial.y]:
        fail("Hint didn't recommend certified first move");return
    game._attempt_swap(initial.x,initial.y)
    var next:Vector2i=Rules.solution_pair(puzzle,1)
    if game._find_hint()!=[next.x,next.y]:
        fail("Hint didn't follow certified path");return
    if game.state!="playing":
        fail("Early move ended a playable level");return
    game._undo_last()
    if game.recovery_used or game.state!="playing":
        fail("Undo broke gameplay state");return

    # Walk the certified path only until 75% is reached, and verify manual
    # claiming works before a perfect clear without losing progress.
    game._start_level(0,2)
    puzzle=Rules.generate(0,2)
    var reached:=false
    for pair in puzzle["solution"]:
        game._attempt_swap(int(pair[0]),int(pair[1]))
        if Progress.stars(game.start_gems,Rules.remaining(game.board))>0 and game.state=="playing":
            reached=true
            break
    if not reached:
        fail("No claimable partial-clear state produced");return
    var before_stars:=Progress.stars(game.start_gems,Rules.remaining(game.board))
    game._claim_qualified()
    if game.state!="victory" or game.earned_stars!=before_stars or game.save.unlocked_level(0)<3:
        fail("75%+ manual claim failed to save and unlock");return

    # 85% partial win without playing any more moves.
    game._start_level(0,3)
    var stones:=0
    var allowed_left:=floori(float(game.start_gems)*0.15)
    for i in range(game.board.size()):
        if game.board[i]>=0:
            if stones>=allowed_left:
                game.board[i]=Rules.EMPTY
            stones+=1
    if Rules.remaining(game.board)!=allowed_left or Progress.stars(game.start_gems,allowed_left)!=2:
        fail("85% fixture incorrect");return
    game._claim_qualified()
    if game.state!="victory" or game.earned_stars!=2:
        fail("85% did not award two stars");return

    # Automatic qualification on a deadlocked board with >=75% cleared.
    game._start_level(0,4)
    for i in range(64):
        game.board[i]=Rules.EMPTY
        game.locks[i]=0
        game.seal_types[i]=0
    for r in range(5):
        for c in range(3):
            game.board[r*8+c]=(r+c)%6
    game.start_gems=60
    if Rules.remaining(game.board)!=15 or not Rules.legal_moves(game.board,game.locks).is_empty():
        fail("Automatic win fixture incorrect");return
    game._finish_or_save()
    if game.state!="victory" or game.earned_stars!=1:
        fail("Deadlock at 75% not accepted as victory");return

    # A deadlock below 75% offers one completely FREE recovery. No gems
    # appear from nowhere; the recovery cannot be claimed twice.
    game._start_level(0,5)
    for i in range(64):
        game.board[i]=Rules.EMPTY
        game.locks[i]=0
        game.seal_types[i]=0
    for r in range(8):
        for c in range(3):
            game.board[r*8+c]=(r+c)%6
    game.start_gems=60
    var before:=Rules.remaining(game.board)
    if before!=24 or not Rules.legal_moves(game.board,game.locks).is_empty():
        fail("Free recovery fixture incorrect");return
    game._finish_or_save()
    if game.state!="recovery" or game.recovery_used:
        fail("Deadlock before 75% didn't offer free recovery");return
    game._free_recovery()
    if not game.recovery_used:
        fail("Recovery wasn't recorded as used");return
    if Rules.remaining(game.board)>before:
        fail("Recovery spawned replacement gems");return
    if game.state=="playing" and Rules.legal_moves(game.board,game.locks).is_empty():
        fail("Free recovery returned an unplayable board");return
    game._free_recovery()
    if not game.recovery_used:
        fail("Second recovery became available");return

    # Full clear still grants 3 stars, and Arcade's objective remains intact.
    game._start_level(1,1)
    puzzle=Rules.generate(1,1)
    for pair in puzzle["solution"]:
        if game.state!="playing":
            fail("Canonical path prematurely ended");return
        game._attempt_swap(int(pair[0]),int(pair[1]))
    if game.state!="victory" or game.earned_stars!=3 or Rules.remaining(game.board)!=0:
        fail("Perfect clear didn't award three stars");return
    game.mode="arcade"
    game._start_arcade(0)
    if Rules.remaining(game.board)!=64:
        fail("Arcade refilling changed");return

    game.save.reset_progress()
    print("PASS: V0.6.2 FAIR QUEST: 75/85/100 stars, certified hints, claim, free rescue, automatic victory, full clear, arcade")
    quit(0)
