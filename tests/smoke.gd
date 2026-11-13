extends SceneTree

const QuestRules = preload("res://scripts/quest_rules.gd")
const SaveData = preload("res://scripts/save_data.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String, world: int = -1, level: int = -1) -> void:
    push_error("SMOKE FAIL: %s (world=%s level=%s)" % [reason,world,level])
    quit(1)

func _run() -> void:
    # Every curated quest board must have no premature matches, a first legal
    # move, and a constructive proof that it clears completely without refill.
    for world in range(4):
        for level in range(1,13):
            var scene: Dictionary = QuestRules.generate(world,level)
            var tiles: Array[int] = scene["board"]
            if tiles.size() != 64 or QuestRules.remaining(tiles) != int(scene["gem_count"]):
                _fail("Generator count mismatch",world,level)
                return
            if not QuestRules.scan(tiles).is_empty() or QuestRules.legal_moves(tiles).is_empty():
                _fail("Preexisting match or no first move",world,level)
                return
            if not QuestRules.certified_solution(world,level):
                _fail("Puzzle is not provably solvable",world,level)
                return
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v04"] = true
    game.mode = "quest"
    for world in range(4):
        game._start_level(world,1)
        var before: Array[int] = game.board.duplicate()
        var total: int = QuestRules.remaining(game.board)
        var hint: Array = game._find_hint()
        if hint.size()!=2 or not QuestRules.can_match(game.board,hint[0],hint[1]):
            _fail("Invalid hint",world,1);return
        game._attempt_swap(hint[0],hint[1])
        if game.mode != "quest" or QuestRules.remaining(game.board) >= total or game.moves_used != 1:
            _fail("Quest didn't consume gems",world,1);return
        if game.moves_left != 25:
            _fail("Quest wrongly uses arcade move limit",world,1);return
        if game.save.data["current"].get("mode","")!="quest":
            _fail("Quest autosave missing",world,1);return
        if game.state != "playing":
            _fail("Quest ended prematurely after one match",world,1);return
        game._undo_last()
        if game.board != before or game.moves_used != 0 or game.undo_left != 2:
            _fail("Undo did not restore exact board and score",world,1);return
        if game.save.data["current"].get("undo_left",-1) != 2:
            _fail("Undo was not persisted",world,1);return
        # Complete known scripted path: bottom gadget clears one full row at
        # a time. No refills, no reliance on paid boosters, no dead-end.
        var scene: Dictionary = QuestRules.generate(world,1)
        var shift: int = int(scene["shift"])
        var rows: int = int(scene["rows"])
        for _r in range(rows):
            if game.state != "playing":
                _fail("Scripted solution ended before board empty",world,1);return
            var i := (QuestRules.ROWS - 1) * QuestRules.COLS + shift + 2
            game._attempt_swap(i,i+1)
        if game.state != "victory" or QuestRules.remaining(game.board) != 0:
            _fail("Quest did not finish on empty board",world,1);return
        if game.earned_stars != 3 or game.save.unlocked_level(world) < 2:
            _fail("Perfect clear stars/unlock failed",world,1);return
        if not game.save.data["current"].is_empty():
            _fail("Victory didn't clear active save",world,1);return
    game.mode = "quest"
    game._start_level(0,2)
    game.collected = 9999
    game.score = 999999
    game._finish_or_save()
    if game.state != "playing":
        _fail("Quest ended early on legacy collection/score target");return
    # Valid progress and settings must survive save reload.
    var progress = SaveData.new()
    progress.load_all()
    if progress.unlocked_level(0)<2:
        _fail("Unlocked levels did not persist");return
    progress.toggle_pref("reduce_motion")
    var check = SaveData.new()
    check.load_all()
    if check.pref("reduce_motion") != progress.pref("reduce_motion"):
        _fail("Settings did not persist");return
    game._start_level(0,1)
    var count_before := QuestRules.remaining(game.board)
    var all_positions: Array[int] = []
    for i in range(64):
        if game.board[i] >= 0:
            all_positions.append(i)
    game.hammers_left = 3
    game._hammer(all_positions[0])
    if QuestRules.remaining(game.board) >= count_before:
        _fail("Hammer refilled the finite board");return
    game.mode = "arcade"
    game._start_level(0,1)
    if QuestRules.remaining(game.board) != 64:
        _fail("Arcade started with empty slots");return
    var h: Array = game._find_hint()
    if h.size() != 2:
        _fail("Arcade has no playable swap");return
    game._attempt_swap(h[0],h[1])
    if QuestRules.remaining(game.board) != 64:
        _fail("Arcade did not replenish matched gems");return
    game.save.reset_progress()
    print("PASS: V0.4 FINITE QUEST, 48 certified puzzles, no refill, cleared-only victory, undo, boosters, arcade, autosave")
    quit(0)
