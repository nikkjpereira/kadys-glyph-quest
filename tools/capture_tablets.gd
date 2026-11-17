extends SceneTree
## Capture real landscape and portrait tablet layouts in the Godot engine.
func _initialize() -> void:
    call_deferred("_run")

func _grab(path: String) -> bool:
    var image := root.get_texture().get_image()
    var code := image.save_png("res://build/visual/" + path)
    return code==OK

func _run() -> void:
    root.size=Vector2i(1920,1200)
    root.content_scale_size=Vector2i(1920,1200)
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.data["tutorial_done_v06"]=true
    game.mode="quest"
    game._start_level(0,7)
    for i in range(13):
        await process_frame
    await RenderingServer.frame_post_draw
    if not game.draw_layout_landscape:
        push_error("Tablet landscape layout wasn't selected.")
        quit(1)
        return
    if not _grab("tablet_landscape.png"):
        push_error("Couldn't capture landscape.")
        quit(1)
        return
    # Verify the tablet-specific pause control and that the board is unchanged.
    var old: Array[int]=game.board.duplicate()
    game._gesture_tablet(Vector2(1510,145),Vector2(1510,145))
    if game.state!="paused" or game.board!=old:
        push_error("Tablet pause changed gameplay state incorrectly.")
        quit(1)
        return
    game._gesture_tablet(Vector2(800,310),Vector2(800,310))
    if game.state!="playing":
        push_error("Tablet resume failed.")
        quit(1)
        return
    root.size=Vector2i(1200,1920)
    root.content_scale_size=Vector2i(1200,1920)
    for i in range(14):
        await process_frame
    await RenderingServer.frame_post_draw
    if not game.draw_layout_tablet_portrait:
        push_error("Tablet portrait layout wasn't selected.")
        quit(1)
        return
    if not _grab("tablet_portrait.png"):
        push_error("Couldn't capture portrait.")
        quit(1)
        return
    if old!=game.board:
        push_error("Resizing changed the board.")
        quit(1)
        return
    game.save.reset_progress()
    print("TABLET PASS: actual landscape and portrait layouts; pause/resume and resize preserve board")
    quit(0)
