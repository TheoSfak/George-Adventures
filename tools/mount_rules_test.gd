extends SceneTree
## The rules of the horse (no world needed):
##   godot --path . --headless --script tools/mount_rules_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	check("price 350, level 5, speed x1.8", MountRules.PRICE == 350 and MountRules.MIN_LEVEL == 5 and is_equal_approx(MountRules.SPEED_FACTOR, 1.8))
	check("can buy with level and gold", MountRules.can_buy(5, 350, false))
	check("cannot buy below level 5", not MountRules.can_buy(4, 9999, false))
	check("cannot buy without 350 gold", not MountRules.can_buy(10, 349, false))
	check("cannot buy twice", not MountRules.can_buy(10, 9999, true))
	check("free to mount", MountRules.block_reason(true, false, false, false, false, false) == "")
	check("not owned", MountRules.block_reason(false, false, false, false, false, false) == "not_owned")
	check("indoors", MountRules.block_reason(true, true, false, false, false, false) == "indoors")
	check("busy", MountRules.block_reason(true, false, true, false, false, false) == "busy")
	check("dead", MountRules.block_reason(true, false, false, true, false, false) == "dead")
	check("stunned", MountRules.block_reason(true, false, false, false, true, false) == "stunned")
	check("chased", MountRules.block_reason(true, false, false, false, false, true) == "chased")
	check("not owned wins over the others", MountRules.block_reason(false, true, true, true, true, true) == "not_owned")
	check("the state numbers match Enemy.State", MountRules.CHASE == Enemy.State.CHASE and MountRules.ATTACK == Enemy.State.ATTACK)
	check("a chasing skeleton 10 m away counts", MountRules.chased([Enemy.State.CHASE], [10.0]))
	check("an attacking skeleton counts", MountRules.chased([Enemy.State.ATTACK], [3.0]))
	check("a chasing skeleton 40 m away does not", not MountRules.chased([Enemy.State.CHASE], [40.0]))
	check("a patrolling or marching skeleton does not", not MountRules.chased([Enemy.State.PATROL, Enemy.State.MARCH], [5.0, 5.0]))
	check("a hurt or dead one does not", not MountRules.chased([Enemy.State.HURT, Enemy.State.DEAD], [5.0, 5.0]))
	check("nobody around", not MountRules.chased([], []))
	for reason in ["not_owned", "indoors", "busy", "stunned", "chased"]:
		check("a Greek message for '%s'" % reason, Strings.MOUNT_BLOCKED.has(reason) and String(Strings.MOUNT_BLOCKED[reason]) != "")
	check("dead needs no message", Strings.MOUNT_BLOCKED.has("dead"))
	check("the other strings exist", Strings.MOUNT_ON != "" and Strings.MOUNT_OFF != "" and Strings.MOUNT_BOUGHT != "" and Strings.SHOP_HORSE_TITLE != "" and Strings.SHOP_HORSE_DESC != "" and Strings.SHOP_HORSE_OWNED != "" and Strings.MAP_PLACES.has("stable"))
	quit(1 if failed else 0)
