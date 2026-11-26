extends SceneTree
## v0.7.5 reward and navigation regression tests.
const SaveData=preload("res://scripts/save_data.gd")
func _initialize()->void:
    call_deferred("_check")
func fail(why:String)->void:
    push_error("V075 FAIL: "+why)
    quit(1)
func _check()->void:
    var game=load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game.save.reset_progress()
    game.save.data["tutorial_done_v06"]=true
    game.world_index=0
    game.mode="quest"
    if game.save.unseen_relic_count()!=0:
        fail("Fresh save started with relics");return
    if not game._map_rect(2).has_point(game._map_rect(2).get_center()):
        fail("World-map hit boxes invalid");return
    game.save.record_victory(0,3,1030,2)
    if not game.save.has_relic(0,0) or game.save.world_stage(0)!=1:
        fail("Level 3 did not award the Frost Rune and restoration");return
    var reward:Dictionary=game.save.next_relic_reward()
    if reward.is_empty() or reward.get("key","")!="0-0":
        fail("First-time reward was not queued");return
    if game.save.unseen_relic_count()!=1:
        fail("New badge was not marked");return
    # Replaying the level can't duplicate the reward.
    game.save.record_victory(0,3,1500,3)
    if game.save.data["pending_rewards"].size()!=1:
        fail("Duplicate reward queued on replay");return
    if not game._offer_relic_reward("home") or game.state!="relic_reveal":
        fail("Relic celebration wasn't displayed");return
    # Simulate interruption by loading the actual saved file.
    var restored=SaveData.new()
    restored.load_all()
    if restored.next_relic_reward().is_empty():
        fail("Relic celebration was lost after a restart");return
    game._finish_relic_reward(true)
    if game.state!="collection" or not game.save.next_relic_reward().is_empty():
        fail("Relic acknowledgement or collection navigation failed");return
    if game.save.unseen_relic_count()!=0:
        fail("Relic NEW badge didn't clear on acknowledgement");return
    game.save.record_victory(0,3,1800,3)
    if not game.save.next_relic_reward().is_empty():
        fail("Acknowledged relic replayed its animation");return
    game.save.record_victory(0,6,1200,1)
    if game.save.next_relic_reward().get("key","")!="0-1":
        fail("Next milestone relic not queued");return
    if not game.save.unlock_achievement("first_match"):
        fail("First achievement not granted");return
    if game.save.unlock_achievement("first_match"):
        fail("Achievement repeated its first unlock");return
    var saved_again=SaveData.new()
    saved_again.load_all()
    if not bool(saved_again.data["achievements"].get("first_match",false)):
        fail("Achievement didn't persist");return
    # Test migration from previous schema 3 in memory without destroying the current save.
    var legacy=SaveData.new()
    legacy.data.erase("relic_seen")
    legacy.data.erase("pending_rewards")
    legacy.data.erase("achievements")
    legacy.reset_defaults()
    if not legacy.data.has("pending_rewards") or int(legacy.data["schema"])!=4:
        fail("New default save schema lacks reward state");return
    game.save.reset_progress()
    print("PASS: V0.7.5 REWARDS: milestones, persistence, no duplicate, replay and achievements")
    quit(0)
