extends SceneTree
## Capture actual Godot-rendered screenshots in CI using a virtual display.
func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    root.content_scale_size = Vector2i(720,1440)
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var err := image.save_png("res://build/visual/menu.png")
    if err != OK:
        push_error("Menu screenshot could not be saved: " + str(err))
        quit(1)
        return
    game.save.data["tutorial_done"] = true
    game._start_level(0,1)
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    image = root.get_texture().get_image()
    err = image.save_png("res://build/visual/runes.png")
    if err != OK:
        push_error("Game screenshot could not be saved: " + str(err))
        quit(1)
        return
    print("VISUAL PASS: captured rendered menu and Runes gameplay screens")
    quit(0)
