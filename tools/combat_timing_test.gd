extends SceneTree
## The combo table, the swing speed and the upper-body filter:
##   godot --path . --headless --script tools/combat_timing_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	check("five hits in the combo", CombatTiming.COMBO.size() == 5)
	check("the last hit is the heaviest and hits all around", CombatTiming.COMBO[4]["around"] and CombatTiming.COMBO[4]["damage"] == 1.8)
	check("the third hit is a stab that steps forward", CombatTiming.COMBO[2]["anim"] == "1H_Melee_Attack_Stab" and CombatTiming.COMBO[2]["lunge"] > 1.0)
	var rising := true
	for i in range(1, 5):
		rising = rising and CombatTiming.COMBO[i]["damage"] >= CombatTiming.COMBO[i - 1]["damage"]
	check("the damage never drops along the combo", rising)
	for step in CombatTiming.COMBO:
		check("%s: it lands before George may move on" % step["anim"], step["hit"] < step["commit"])
	check("swings play at 1.7x", is_equal_approx(CombatTiming.speed(0.0), 1.7))
	check("attack speed +20% makes it 2.04x", is_equal_approx(CombatTiming.speed(0.2), 1.7 * 1.2))
	check("a hit lands after about 0.16 s (diagonal slice)", CombatTiming.hit_delay(CombatTiming.COMBO[0], 1.7) < 0.17)
	check("George may act again after about a third of a second", CombatTiming.commit_delay(CombatTiming.COMBO[0], 1.7) < 0.35)
	check("the next hit wraps around after the fifth", CombatTiming.next_index(4) == 0 and CombatTiming.next_index(0) == 1)
	check("the layer copies the combo animations and the power strike", CombatTiming.animations().has("2H_Melee_Attack_Spinning") and CombatTiming.animations().has("1H_Melee_Attack_Chop"))

	# the filter
	check("hips are lower body", UpperBodyLayer.is_lower_body("Rig/Skeleton3D:hips"))
	check("legs and feet are lower body", UpperBodyLayer.is_lower_body("Rig/Skeleton3D:upperleg.l") and UpperBodyLayer.is_lower_body("Rig/Skeleton3D:foot.r") and UpperBodyLayer.is_lower_body("Rig/Skeleton3D:toes.l"))
	check("the foot IK controls are lower body", UpperBodyLayer.is_lower_body("Rig/Skeleton3D:IK-foot.l") and UpperBodyLayer.is_lower_body("Rig/Skeleton3D:kneeIK.r") and UpperBodyLayer.is_lower_body("Rig/Skeleton3D:heelIK.l"))
	check("spine, arms, hands and head are upper body", not UpperBodyLayer.is_lower_body("Rig/Skeleton3D:spine") and not UpperBodyLayer.is_lower_body("Rig/Skeleton3D:chest") and not UpperBodyLayer.is_lower_body("Rig/Skeleton3D:upperarm.r")
			and not UpperBodyLayer.is_lower_body("Rig/Skeleton3D:handslot.r") and not UpperBodyLayer.is_lower_body("Rig/Skeleton3D:head"))
	check("the arm IK controls stay", not UpperBodyLayer.is_lower_body("Rig/Skeleton3D:handIK.l") and not UpperBodyLayer.is_lower_body("Rig/Skeleton3D:elbowIK.r"))

	var model := (load("res://assets/characters/Knight.glb") as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var base := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var layer := UpperBodyLayer.new()
	layer.setup(base, CombatTiming.animations())
	for n in CombatTiming.animations():
		var orig := base.get_animation(n)
		var cut := layer.player.get_animation(n)
		var lower_left := 0
		for i in cut.get_track_count():
			if UpperBodyLayer.is_lower_body(str(cut.track_get_path(i))):
				lower_left += 1
		check("%s: %d of %d tracks kept, no leg track left" % [n, cut.get_track_count(), orig.get_track_count()], lower_left == 0 and cut.get_track_count() > 0 and cut.get_track_count() < orig.get_track_count())
	check("the layer is a sibling of the base player (processed after it)", layer.player.get_parent() == base.get_parent() and layer.player.get_index() > base.get_index())
	layer.play("1H_Melee_Attack_Chop", 0.05, 1.7)
	check("it plays at the asked speed", layer.player.is_playing() and layer.player.current_animation == "1H_Melee_Attack_Chop")
	layer.stop()
	check("and stops", not layer.player.is_playing())
	quit(1 if failed else 0)
