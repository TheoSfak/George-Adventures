extends SceneTree
## The weather reaches the sky, the light, the fog, the clouds and the ground shaders:
##   godot --path . --headless --script tools/weather_look_test.gd
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
	# --- files and settings
	var sky := FileAccess.get_file_as_string("res://shaders/sky.gdshader")
	check("the sky shader has the overcast and flash uniforms", sky.contains("uniform float overcast") and sky.contains("uniform float flash"))
	for f in ["ground", "path", "patch"]:
		check("%s.gdshader reads the global wetness" % f, FileAccess.get_file_as_string("res://shaders/%s.gdshader" % f).contains("global uniform float wetness"))
	check("project.godot declares the wetness global", ProjectSettings.has_setting("shader_globals/wetness"))

	# --- the world
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var w = get_first_node_in_group("weather")
	var dn = get_first_node_in_group("daynight")
	var sun := main.get_node("Sun") as DirectionalLight3D
	w.set_process(false)
	dn.running = false
	dn.set_time(12.0)
	await create_timer(0.3).timeout
	var env: Environment = dn._env
	var base_fog := env.fog_density
	var base_sun := sun.light_energy
	var base_ambient := env.ambient_light_energy
	check("noon, clear: the sun is bright (%.2f)" % base_sun, base_sun > 0.9)

	# --- fog
	w.force(1)
	settle(w, 30)
	await create_timer(0.3).timeout
	check("fog: the fog is much thicker (%.4f -> %.4f)" % [base_fog, env.fog_density], env.fog_density > base_fog + 0.003)
	check("fog: the sun is dimmer", sun.light_energy < base_sun * 0.85)
	check("fog: the sky is greyer (no blue)", dn._sky_mat.get_shader_parameter("overcast") > 0.4)

	# --- storm
	w.force(3)
	settle(w, 30)
	await create_timer(0.3).timeout
	check("storm: sun at 35%% (%.2f of %.2f)" % [sun.light_energy, base_sun], sun.light_energy < base_sun * 0.5)
	check("storm: sky uniform overcast is 1", is_equal_approx(float(dn._sky_mat.get_shader_parameter("overcast")), 1.0))
	var sky_top: Color = dn._sky_mat.get_shader_parameter("top_color")
	check("storm: the sky top colour is mostly grey (r %.2f, b %.2f; the clear sky is 0.22 and 0.86)" % [sky_top.r, sky_top.b], absf(sky_top.r - sky_top.b) < 0.15)
	w._start_bolt()
	await create_timer(0.1).timeout
	w.step(0.0)
	await create_timer(0.1).timeout
	check("a lightning flash lights the sky and the ambient light (flash %.2f)" % w.flash, w.flash > 0.5 and float(dn._sky_mat.get_shader_parameter("flash")) > 0.5 and env.ambient_light_energy > base_ambient + 0.5)

	# --- the clouds turn dark in the storm and come back
	var clouds := main.get_node("Village/Clouds")
	var meshes := clouds.find_children("*", "MeshInstance3D", true, false)
	check("there are cloud meshes", meshes.size() > 0)
	w.apply_effects()
	var tinted := true
	for m in meshes:
		var mat := (m as MeshInstance3D).material_override as StandardMaterial3D
		if mat == null or mat.albedo_color.get_luminance() > 0.45:
			tinted = false
	check("in the storm every cloud has the dark grey material", tinted)

	# --- back to clear: everything as before
	w.force(0)
	settle(w, 35)
	w.step(1.0)
	w.apply_effects()
	await create_timer(0.3).timeout
	check("clear again: the fog is as before (%.4f)" % env.fog_density, absf(env.fog_density - base_fog) < 0.0001)
	check("clear again: the sun is as before", absf(sun.light_energy - base_sun) < 0.02)
	var restored := true
	for m in meshes:
		if (m as MeshInstance3D).material_override != null:
			restored = false
	check("clear again: the clouds have their own look back", restored)
	quit(1 if failed else 0)
