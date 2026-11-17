extends SceneTree
## Capture real v0.6 Godot renders at phone and tablet sizes.
const QuestRules=preload("res://scripts/quest_rules.gd")
func _initialize()->void:
    call_deferred("_capture")
func snap(name:String)->bool:
    var img:=root.get_texture().get_image()
    var status:=img.save_png("res://build/visual/"+name+".png")
    if status!=OK:
        push_error("Could not save actual v0.6 screen %s (%s)" % [name,status])
        return false
    return true
func settle()->void:
    pass
func pause_frames(n:int=5)->void:
    pass
func _capture()->void:
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    root.content_scale_size=Vector2i(720,1440)
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("menu"):quit(1);return
    game.mode="quest"
    game._start_level(0,8)
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("runes"):quit(1);return
    var scene:=QuestRules.generate(0,8)
    var move:=QuestRules.solution_pair(scene,0)
    game._attempt_swap(move.x,move.y)
    for i in range(4):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("match_effect"):quit(1);return
    for w in range(1,4):
        game._start_level(w,10)
        for i in range(7):await process_frame
        await RenderingServer.frame_post_draw
        if not snap(["runes","egypt","asia","mixed"][w]):quit(1);return
    game.state="paused"
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("paused"):quit(1);return
    game.state="settings"
    game.settings_return="menu"
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("settings"):quit(1);return
    game.mode="arcade"
    game._start_arcade(0)
    for i in range(6):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("arcade"):quit(1);return
    game.mode="quest"
    game._start_level(0,1)
    var finish_scene:=QuestRules.generate(0,1)
    for move_pair in finish_scene["solution"]:
        game._attempt_swap(int(move_pair[0]),int(move_pair[1]))
    if game.state!="victory":
        push_error("v0.6 victory capture failed after certified solution")
        quit(1);return
    game.fall_ghosts.clear()
    game.fall_age=1
    game.impact_fx.clear()
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("victory"):quit(1);return
    game.mode="quest"
    game._start_level(0,8)
    root.content_scale_size=Vector2i(1080,2400)
    for i in range(12):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("phone_tall"):quit(1);return
    root.content_scale_size=Vector2i(1200,1920)
    for i in range(12):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("tablet_portrait"):quit(1);return
    root.content_scale_size=Vector2i(1920,1200)
    for i in range(12):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("tablet_landscape"):quit(1);return
    game.state="menu"
    for i in range(6):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("tablet_landscape_menu"):quit(1);return
    game.state="collection"
    game.album_world=0
    for i in range(6):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("relic_collection"):quit(1);return
    game.save.reset_progress()
    print("VISUAL PASS: v0.6 phone and tablet, relics, all worlds, animated match")
    quit(0)
