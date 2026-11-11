extends SceneTree

const SaveData = preload("res://scripts/save_data.gd")
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    if not ResourceLoader.exists("res://assets/v03/board_gold_frame.png"):
        push_error("v0.3 render artwork missing")
        quit(1)
        return
    if not ResourceLoader.exists("res://assets/audio/enchanted_library.ogg"):
        push_error("v0.3 audible music missing")
        quit(1)
        return
    if game.music_player == null or game.music_player.stream == null:
        push_error("v0.3 soundtrack not assigned")
        quit(1)
        return
    game.save.set_int("music_volume",70)
    game.save.set_int("sfx_volume",40)
    if game.save.setting_int("music_volume") != 70 or game.save.setting_int("sfx_volume") != 40:
        push_error("Volume settings are not persisted")
        quit(1)
        return
    game.save.data["tutorial_done"] = true
    for world in range(4):
        game._start_level(world,1)
        if game.state!="playing":
            _fail("Did not enter gameplay",world)
            return
        if game.board.size()!=64 or not game._find_matches().is_empty():
            _fail("Board has wrong size or pre-existing matches",world)
            return
        var move: Array = game._find_hint()
        if move.size()!=2 or not game._adjacent(move[0],move[1]):
            _fail("No playable swap",world)
            return
        game._attempt_swap(move[0],move[1])
        if game.moves_left!=24 or game.score<=0:
            _fail("Swapping did not consume one move and score",world)
            return
        if game.save.data["current"].is_empty():
            _fail("Successful move did not autosave",world)
            return
        game.collected=game.target_amount
        game.objective_type="collect"
        game._finish_or_save()
        if game.state!="victory" or game.earned_stars<1:
            _fail("Victory did not end game",world)
            return
        if game.save.unlocked_level(world)<2:
            _fail("Victory did not unlock level 2",world)
            return
        if not game.save.data["current"].is_empty():
            _fail("Victory did not clear active game",world)
            return
    game._start_level(0,1)
    game.moves_left=0
    game.collected=0
    game.state="playing"
    game._finish_or_save()
    if game.state!="failure":
        _fail("Move exhaustion did not trigger failure",0)
        return
    var progress := SaveData.new()
    progress.load_all()
    if progress.unlocked_level(0)<2:
        _fail("Saved progress did not survive reload",0)
        return
    progress.toggle_pref("reduce_motion")
    var check := SaveData.new()
    check.load_all()
    if check.pref("reduce_motion")!=progress.pref("reduce_motion"):
        _fail("Settings did not persist",0)
        return
    print("PASS: 8x8 match-three, 4 worlds, victory, failure, autosave, settings persistence")
    quit(0)

func _fail(reason: String, world: int) -> void:
    push_error("SMOKE FAIL world %s: %s" % [world,reason])
    quit(1)
