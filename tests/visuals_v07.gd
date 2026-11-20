extends SceneTree
## Offline v0.7 visual asset and animation-mode regression checks.
const Visuals=preload("res://scripts/v07_visual_math.gd")
const Progress=preload("res://scripts/quest_progress.gd")
const Rules=preload("res://scripts/quest_rules.gd")
func _initialize() -> void:
    call_deferred("_run")
func failed(why: String) -> void:
    push_error("V07 VISUAL FAIL: "+why)
    quit(1)
func _run() -> void:
    if Visuals.frame_rate(false,false)<40 or Visuals.frame_rate(true,false)>12 or Visuals.frame_rate(false,true)>22:
        failed("motion frame caps invalid");return
    if Visuals.gem_specular(1.2,4,false,true)!=0 or Visuals.gem_specular(1.2,4,true,false)!=0:
        failed("Reduce Motion or Low Effects didn't disable sheen animation");return
    if Visuals.debris_count(false,true,3)!=0 or Visuals.debris_count(true,false,3)>2:
        failed("Reduce Motion or Low Effects didn't cap debris");return
    if Visuals.parallax(3.0,0,true)!=Vector2.ZERO:
        failed("Reduce Motion didn't disable parallax");return
    if not is_equal_approx(Visuals.gravity_ease(0,false),0) or not is_equal_approx(Visuals.gravity_ease(1,false),1):
        failed("gravity animation endpoints");return
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    if not (game.ui_font is FontFile and (game.ui_font as FontFile).multichannel_signed_distance_field):
        failed("Latin interface font is not MSDF");return
    if not (game.display_font is FontFile and (game.display_font as FontFile).multichannel_signed_distance_field):
        failed("Fantasy headings are not MSDF");return
    for font in game.glyph_fonts:
        if font is FontFile and not (font as FontFile).multichannel_signed_distance_field:
            failed("At least one ancient glyph font isn't MSDF");return
    game.save.data["tutorial_done_v06"]=true
    game.mode="quest"
    if game.gems.size()!=6:
        failed("missing gem types");return
    for i in range(6):
        if game.gems[i]==null or game.gems[i].get_width()!=256:
            failed("missing 256px gem materials at index %s" % i);return
    for effect in ["spark_star","crystal_shard","magic_ring","light_ray","gem_glint"]:
        if not game.art.has(effect) or game.art[effect]==null:
            failed("missing graphical FX: "+effect);return
    for world in range(4):
        for stage in range(5):
            var key: String="world_%s_stage_%s" % [world,stage]
            if not game.art.has(key) or game.art[key]==null:
                failed("missing restoration scene "+key);return
        game._start_level(world,1)
        var current: Array[int]=game.board.duplicate()
        game.save.data["restoration"][world]=4
        game.queue_redraw() # Draw happens on the main loop, not in an offscreen test call.
        if game.board!=current or game.save.world_stage(world)!=4:
            failed("restoration visuals changed gameplay");return
        # No active FX should be saved as part of core game board state.
        game.save.data["prefs"]["reduce_motion"]=true
        game.save.data["prefs"]["low_effects"]=true
        var solved:=Rules.generate(world,1)
        var first:=Rules.solution_pair(solved,0)
        game._attempt_swap(first.x,first.y)
        if game.moves_used!=1:
            failed("low FX disabled input or matching");return
        game.save.data["prefs"]["reduce_motion"]=false
        game.save.data["prefs"]["low_effects"]=false
    game.save.reset_progress()
    print("PASS: V0.7 VISUAL FX: 6x 256px gems, 20 restoration states, 5 magical FX assets, quality profiles and gameplay isolation")
    quit(0)
