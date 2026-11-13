extends SceneTree
## Capture actual Godot screens, not concept art.
const QuestRules = preload("res://scripts/quest_rules.gd")
func _initialize() -> void:
    call_deferred("_capture")

func _shot(name: String) -> bool:
    var frame := root.get_texture().get_image()
    var err := frame.save_png("res://build/visual/" + name + ".png")
    if err != OK:
        push_error("Could not save screenshot %s" % name)
        return false
    return true

func _capture() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    root.content_scale_size = Vector2i(720, 1440)
    game.save.reset_progress()
    game.mode = "quest"
    game.world_index = 0
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    if not _shot("menu"): quit(1);return
    game.save.data["tutorial_done_v04"] = true
    game._start_level(0, 1)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    if not _shot("runes"): quit(1);return
    game.state = "paused"
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    if not _shot("paused"): quit(1);return
    game.state = "settings"
    game.settings_return = "menu"
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    if not _shot("settings"): quit(1);return
    game.mode = "arcade"
    game._start_arcade(0)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    if not _shot("arcade"): quit(1);return
    game.mode = "quest"
    game._start_level(0, 1)
    var scene: Dictionary = QuestRules.generate(0, 1)
    var shift := int(scene["shift"])
    var rows := int(scene["rows"])
    for i in range(rows):
        var first := 7 * 8 + shift + 2
        game._attempt_swap(first, first + 1)
    if game.state != "victory":
        push_error("Visual test could not reach a proper victory")
        quit(1)
        return
    game.fall_ghosts.clear()
    game.fall_age = 1.0
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    if not _shot("victory"): quit(1);return
    game.save.reset_progress()
    print("VISUAL PASS: menu, runes, paused, settings, arcade, completed board")
    quit(0)
