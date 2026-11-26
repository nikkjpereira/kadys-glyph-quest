extends SceneTree
func _initialize()->void:
    call_deferred("_run")
func snap(n:String)->bool:
    return root.get_texture().get_image().save_png("res://build/visual/v075_"+n+".png")==OK
func _run()->void:
    root.size=Vector2i(720,1440)
    root.content_scale_size=Vector2i(720,1440)
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    game.state="menu"
    for i in range(9):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("home_phone"):quit(1);return
    game.state="levels"
    for i in range(9):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("world_map_phone"):quit(1);return
    game.mode="quest"
    game._start_level(0,2)
    var enchanted:int=-1
    for idx in range(64):
        if game.board[idx]>=0 and game.locks[idx]==0:
            enchanted=idx
            break
    if enchanted<0:
        push_error("No gem for special screenshot");quit(1);return
    game.powers[enchanted]=3
    for i in range(9):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("special_gem_phone"):quit(1);return
    game.state="menu"
    game.save.record_victory(0,3,1500,2)
    if not game._offer_relic_reward("home"):
        push_error("Could not produce relic reveal")
        quit(1);return
    for i in range(9):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("relic_found_phone"):quit(1);return
    game._finish_relic_reward(true)
    for i in range(9):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("collection_phone"):quit(1);return
    game.state="achievements"
    for i in range(9):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("achievements_phone"):quit(1);return
    root.size=Vector2i(864,1536)
    root.content_scale_size=Vector2i(864,1536)
    game.state="menu"
    for i in range(14):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("home_tablet"):quit(1);return
    root.size=Vector2i(1920,1200)
    root.content_scale_size=Vector2i(1920,1200)
    for i in range(14):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("home_landscape"):quit(1);return
    game.state="levels"
    for i in range(10):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("map_landscape"):quit(1);return
    game.save.record_victory(0,6,1234,2)
    game._offer_relic_reward("home")
    for i in range(10):await process_frame
    await RenderingServer.frame_post_draw
    if not snap("relic_found_landscape"):quit(1);return
    game.save.reset_progress()
    print("PASS: V0.7.5 UI CAPTURE: phone/tablet Home, map, relic reveal")
    quit(0)
