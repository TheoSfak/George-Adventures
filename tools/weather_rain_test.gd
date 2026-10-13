extends SceneTree
## The rain particles follow George and scale with the rain; the storm throws lightning and thunder:
##   godot --path . --headless --script tools/weather_rain_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var w = get_first_node_in_group("weather")
	var p := get_first_node_in_group("player") as Player
	w.set_process(false)
	var rain := w.get_node_or_null("Rain") as GPUParticles3D
	check("the Rain particles exist", rain != null)
	if rain == null:
		quit(1)
		return
	check("it is a one-draw-call system with a fixed amount", rain.amount >= 1500 and rain.process_material != null and rain.draw_pass_1 != null)
	check("no rain when it is clear", not rain.emitting)

	# --- rain follows George and scales
	w.force(2)
	for i in 30:
		w.step(1.0)
	w._player = p
	w.apply_effects()
	check("it rains: the particles emit", rain.emitting)
	check("the amount ratio is the rain (%.2f)" % rain.amount_ratio, absf(rain.amount_ratio - 0.7) < 0.01)
	check("the rain hangs 14 m above George", rain.global_position.distance_to(p.global_position + Vector3(0, 14, 0)) < 0.01)
	p.teleport(Vector3(50.0, 0.05, 60.0), 0.0)
	w.apply_effects()
	check("it follows him when he moves", rain.global_position.distance_to(p.global_position + Vector3(0, 14, 0)) < 0.01)
	w.force(3)
	for i in 30:
		w.step(1.0)
	w.apply_effects()
	check("in the storm the ratio is 1", absf(rain.amount_ratio - 1.0) < 0.01)
	w.force(0)
	for i in 30:
		w.step(1.0)
	w.apply_effects()
	check("clear again: the particles stop", not rain.emitting)

	# --- lightning and thunder
	w.force(3)
	for i in 30:
		w.step(1.0)
	var bolts_before: int = w.bolts
	var thunder_before: int = w.thunders
	var max_flash := 0.0
	var dark_between := false
	for i in 5000:
		w.step(0.02)                      # 100 s in steps of 0.02 s so the 0.06 s flashes are seen
		max_flash = maxf(max_flash, w.flash)
		if w.flash == 0.0 and max_flash > 0.9:
			dark_between = true
	var bolts: int = w.bolts - bolts_before
	var thunders: int = w.thunders - thunder_before
	check("a storm throws several lightning bolts in 100 s (%d)" % bolts, bolts >= 4)
	check("the flash is bright (%.2f) and goes dark again" % max_flash, max_flash > 0.95 and dark_between)
	check("each bolt is followed by thunder (%d of %d)" % [thunders, bolts], thunders >= bolts - 1 and thunders > 0)
	w.force(2)
	for i in 30:
		w.step(1.0)
	var calm_bolts: int = w.bolts
	for i in 1000:
		w.step(0.02)
	check("no lightning in plain rain", w.bolts == calm_bolts)
	quit(1 if failed else 0)
