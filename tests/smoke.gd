extends SceneTree

func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    for world in range(4):
        game.world_index = world
        game._start_game()
        if game.board.size() != 56 or not game._find_matches().is_empty():
            push_error("Broken starting board for world " + str(world))
            quit(1)
            return
        var swap: Array = game._find_hint()
        if swap.size() != 2:
            push_error("No moves available in world " + str(world))
            quit(1)
            return
        game._attempt_swap(swap[0], swap[1])
        if game.moves_left != 23 or game.score <= 0:
            push_error("Scoring/swap failed in world " + str(world))
            quit(1)
            return
    print("PASS: four worlds, valid board and scoring")
    quit(0)
