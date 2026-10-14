extends SceneTree
## The Horse node: size, feet on the ground, animations found:
##   godot --path . --headless --script tools/horse_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var horse := Horse.new()
	root.add_child(horse)
	await process_frame
	check("it is about 2.5 m long", absf(horse.length_m - Horse.TARGET_LENGTH) < 0.05)
	check("it is between 1.5 m and 3 m tall", horse.height_m > 1.5 and horse.height_m < 3.0)
	check("the hooves stand on the ground", absf(horse.feet_y()) < 0.05)
	for kind in ["idle", "walk", "run"]:
		check("it has a '%s' animation" % kind, horse.animation_for(kind) != "")
	horse.set_motion(0.0, true)
	await process_frame
	check("standing still plays the idle animation", horse.current_kind() == "idle")
	horse.set_motion(9.0, true)
	await process_frame
	check("9 m/s is a walk", horse.current_kind() == "walk")
	horse.set_motion(16.0, true)
	await process_frame
	check("16 m/s is a run", horse.current_kind() == "run")
	horse.set_motion(16.0, false)
	await process_frame
	check("in the air it jumps (or keeps running if the model has no jump)", horse.current_kind() == ("jump" if horse.animation_for("jump") != "" else "run"))
	horse.stand()
	horse.set_motion(16.0, true)
	await process_frame
	check("a standing horse ignores motion", horse.current_kind() == "idle")
	quit(1 if failed else 0)
