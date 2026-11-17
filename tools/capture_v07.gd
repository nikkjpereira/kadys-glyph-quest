extends SceneTree
## Actual Godot 4.7 screenshot verification of the new v0.7 world and gem renderer.
const Rules=preload("res://scripts/quest_rules.gd")
func _initialize() -> void:
    call_deferred("_run")
func _snap(name:String)->bool:
    var path: String="res://build/visual/"+name+".png"
    return root.get_texture().get_image().save_png(path)==OK
func _frames(n:int=8)->void:
    pass
func _run()->void:
    root.size=Vector2i(720,1440)
    root.content_scale_size=Vector2i(720,1440)
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    game.save.data["prefs"]["gem_shimmer"]=true
    game.save.data["prefs"]["reactive_light"]=true
    game.save.data["prefs"]["ambient_motion"]=true
    game.mode="quest"
    for w in range(4):
        game.save.data["restoration"][w]=4
        game._start_level(w,9)
        for i in range(10):await process_frame
        await RenderingServer.frame_post_draw
        if not _snap(["v07_runes_restored","v07_egypt_restored","v07_asia_restored","v07_mixed_restored"][w]):
            push_error("Couldn't capture v0.7 restored world");quit(1);return
    game.save.data["restoration"][0]=4
    game._start_level(0,9)
    var scene:Dictionary=Rules.generate(0,9)
    var pair:Vector2i=Rules.solution_pair(scene,0)
    game._attempt_swap(pair.x,pair.y)
    for i in range(4):await process_frame
    await RenderingServer.frame_post_draw
    if not _snap("v07_shards_and_match"):
        push_error("Couldn't capture crystal shard FX");quit(1);return
    game.save.data["prefs"]["reduce_motion"]=true
    game.save.data["prefs"]["low_effects"]=true
    game._start_level(0,9)
    for i in range(12):await process_frame
    await RenderingServer.frame_post_draw
    if not _snap("v07_low_fx"):
        push_error("Couldn't capture low effects profile");quit(1);return
    game.save.data["prefs"]["reduce_motion"]=false
    game.save.data["prefs"]["low_effects"]=false
    root.size=Vector2i(1920,1200)
    root.content_scale_size=Vector2i(1920,1200)
    for i in range(15):await process_frame
    await RenderingServer.frame_post_draw
    if not game.draw_layout_landscape or not _snap("v07_tablet_landscape_restored"):
        push_error("Couldn't capture v0.7 landscape");quit(1);return
    root.size=Vector2i(1200,1920)
    root.content_scale_size=Vector2i(1200,1920)
    for i in range(15):await process_frame
    await RenderingServer.frame_post_draw
    if not game.draw_layout_tablet_portrait or not _snap("v07_tablet_portrait_restored"):
        push_error("Couldn't capture v0.7 portrait");quit(1);return
    game.save.reset_progress()
    print("PASS: V0.7 RENDER: four fully-restored worlds, match shards, low FX, both tablet layouts")
    quit(0)
