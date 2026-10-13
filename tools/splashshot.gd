extends SceneTree
## Renders the splash image (the village with the title on top) in several candidate views:
##   godot --path . --resolution 1920x1080 --script tools/splashshot.gd -- <outdir>
## Pick one and copy it to assets/ui/splash.png (the boot splash in project.godot).
var out := "."


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


## Dark gradients at the top and bottom keep the text readable over any picture.
func _fade(top: bool) -> TextureRect:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.02, 0.03, 0.08, 0.78), Color(0.02, 0.03, 0.08, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 4
	t.height = 128
	t.fill_from = Vector2(0, 0) if top else Vector2(0, 1)
	t.fill_to = Vector2(0, 1) if top else Vector2(0, 0)
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left = 0.0
	r.anchor_right = 1.0
	r.anchor_top = 0.0 if top else 0.62
	r.anchor_bottom = 0.38 if top else 1.0
	return r


func _overlay() -> CanvasLayer:
	UiKit.install_font()
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	layer.add_child(_fade(true))
	layer.add_child(_fade(false))
	var title := UiKit.label(Strings.TITLE, 50, UiKit.GOLD_TEXT)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.offset_top = 52.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 12)
	layer.add_child(title)
	var loading := UiKit.label("Φόρτωση…", 26, Color(0.93, 0.9, 0.82))
	loading.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	loading.grow_horizontal = Control.GROW_DIRECTION_BOTH
	loading.grow_vertical = Control.GROW_DIRECTION_BEGIN
	loading.offset_bottom = -34.0
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(loading)
	return layer


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	get_first_node_in_group("hud").visible = false
	var dn := get_first_node_in_group("daynight") as DayNight
	dn.running = false
	var w = get_first_node_in_group("weather")
	if w != null:
		w.set_process(false)
	var layer := _overlay()
	layer.visible = false
	# no floating name tags or speech bubbles
	for n in main.find_children("*", "Label3D", true, false):
		(n as Label3D).visible = false
	# [name, time of day, George position, yaw, pitch, camera distance]
	var views := [
		["splash_e", 18.5, Vector3(0, 0.05, 30), PI + 0.10, -0.10, 13.0],
		["splash_f", 18.5, Vector3(5, 0.05, 31), PI - 0.14, -0.08, 12.0],
		["splash_g", 18.7, Vector3(-4, 0.05, 31), PI + 0.20, -0.12, 12.0],
	]
	for v in views:
		dn.set_time(v[1])
		p.teleport(v[2], v[3])
		p._pitch = v[4]
		p._arm.spring_length = v[5]
		# other characters near George (they read as a second hero) are hidden
		for c in main.find_children("*", "CharacterBody3D", true, false):
			if c != p:
				(c as Node3D).visible = (c as Node3D).global_position.distance_to(v[2]) > 16.0
		await create_timer(1.4).timeout
		layer.visible = true
		await shot(v[0])
		layer.visible = false
	quit()
