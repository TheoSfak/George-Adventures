extends SceneTree
## Rain in the ambience mix (volumes follow the weather, indoors it is the roof loop):
##   godot --path . --headless --script tools/weather_sound_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func settle(w, seconds: int) -> void:
	for i in seconds:
		w.step(1.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	check("the new sounds are known", SfxIds.VARIANTS.has("thunder") and SfxIds.VARIANTS["thunder"] == 2 and SfxIds.LOOPS.has("amb_rain") and SfxIds.LOOPS.has("amb_rain_roof"))
	for f in ["amb_rain.wav", "amb_rain_roof.wav", "thunder_1.wav", "thunder_2.wav"]:
		check("the file %s exists" % f, FileAccess.file_exists("res://assets/audio/sfx/" + f))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var w = get_first_node_in_group("weather")
	var dn = get_first_node_in_group("daynight")
	var sm = get_first_node_in_group("sound_manager")
	var p := get_first_node_in_group("player") as Player
	var interiors = get_first_node_in_group("interiors")
	w.set_process(false)
	dn.running = false
	dn.set_time(12.0)
	await create_timer(3.0).timeout
	var day_clear: float = sm._ambient["amb_day"].volume_db
	check("clear: no rain sound (%.0f dB)" % sm._ambient["amb_rain"].volume_db, sm._ambient["amb_rain"].volume_db < -50.0)

	w.force(3)
	settle(w, 30)
	await create_timer(3.0).timeout
	check("storm outdoors: the rain loop is loud (%.1f dB)" % sm._ambient["amb_rain"].volume_db, sm._ambient["amb_rain"].volume_db > -8.0)
	check("storm: no roof loop outdoors", sm._ambient["amb_rain_roof"].volume_db < -50.0)
	check("storm: the birds are quieter (%.1f -> %.1f dB)" % [day_clear, sm._ambient["amb_day"].volume_db], sm._ambient["amb_day"].volume_db < day_clear - 12.0)

	w.force(2)
	settle(w, 30)
	await create_timer(3.0).timeout
	var light := float(sm._ambient["amb_rain"].volume_db)
	check("plain rain is quieter than the storm (%.1f dB)" % light, light < -5.0 and light > -20.0)

	interiors.enter("tavern_sound", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	for i in 60:
		await create_timer(0.1).timeout
		if interiors.is_inside() and not p.busy:
			break
	settle(w, 3)
	await create_timer(3.0).timeout
	check("inside: the roof loop plays (%.1f dB)" % sm._ambient["amb_rain_roof"].volume_db, sm._ambient["amb_rain_roof"].volume_db > -25.0)
	check("inside: the meadow loop is silent", sm._ambient["amb_rain"].volume_db < -50.0)
	quit(1 if failed else 0)
