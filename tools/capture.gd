extends SceneTree
## Capture actual Godot-rendered v0.5 game scenes; source screenshots,
## not a pasted image of the static reference illustration.
const QuestRules=preload("res://scripts/quest_rules.gd")
func _initialize()->void:
    call_deferred("_capture")
func snap(name:String)->bool:
    var img:=root.get_texture().get_image()
    var e:=img.save_png("res://build/visual/"+name+".png")
    if e!=OK:
        push_error("Could not save v0.5 screen: "+name)
        return false
    return true
func wait_frames()->void:
    pass
func _capture()->void:
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    root.content_scale_size=Vector2i(720,1440)
    game.save.reset_progress()
    game.save.data["tutorial_done_v05"]=true
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
    game._start_level(1,10)
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("egypt"):quit(1);return
    game._start_level(2,10)
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("asia"):quit(1);return
    game._start_level(3,10)
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("mixed"):quit(1);return
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
    var last_scene:=QuestRules.generate(0,1)
    for pair in last_scene["solution"]:
        game._attempt_swap(int(pair[0]),int(pair[1]))
    if game.state!="victory":
        push_error("v0.5 visual capture could not reach victory")
        quit(1);return
    game.fall_ghosts.clear()
    game.fall_age=1
    game.impact_fx.clear()
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("victory"):quit(1);return
    game.save.reset_progress()
    print("VISUAL PASS: v0.5 all worlds, live match FX, menu, pause, settings, victory")
    quit(0)
