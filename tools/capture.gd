extends SceneTree
## Capture actual Godot-rendered screens in CI using Xvfb.
func _initialize() -> void:
    call_deferred("_capture")

func _save_screenshot(name: String) -> bool:
    var image := root.get_texture().get_image()
    var err := image.save_png("res://build/visual/" + name + ".png")
    if err != OK:
        push_error("Screenshot could not be saved: %s err %s" % [name,err])
        return false
    return true

func _settle() -> void:
    pass

func _capture() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    root.content_scale_size = Vector2i(720,1440)
    # Tests run before screenshots, so clear CI-only test save data.
    game.save.reset_progress()
    game.world_index = 0
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save_screenshot("menu"):
        quit(1)
        return
    game.save.data["tutorial_done"] = true
    game._start_level(0,1)
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save_screenshot("runes"):
        quit(1)
        return
    game.state="settings"
    game.settings_return="menu"
    game.queue_redraw()
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save_screenshot("settings"):
        quit(1)
        return
    game._start_level(0,1)
    game.collected=game.target_amount
    game.score=2400
    game._finish_or_save()
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save_screenshot("victory"):
        quit(1)
        return
    print("VISUAL PASS: captured real menu, gameplay, settings, victory")
    quit(0)
