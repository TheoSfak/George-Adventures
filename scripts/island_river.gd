class_name IslandRiver
extends Node3D
## The River & Waterfall System of Agios Vlasis:
## Originates from a cascading cliff waterfall in the northern hills, winds across
## the valley through two arched bridges, and flows into the Great Tree Lake.
## Includes a secret walk-in cave behind the waterfall with a treasure chest!

const WATERFALL_POS := Vector3(48.0, 0.0, -132.0)
const BRIDGE_1_POS := Vector3(70.0, 0.1, -66.0)
const BRIDGE_2_POS := Vector3(114.0, 0.1, -22.0)

# River centerline waypoints from waterfall down to the Great Tree lake
const RIVER_WAYPOINTS: Array[Vector2] = [
	Vector2(48.0, -130.0),   # Waterfall plunge pool
	Vector2(54.0, -112.0),
	Vector2(60.0, -92.0),
	Vector2(70.0, -66.0),    # Bridge 1
	Vector2(84.0, -48.0),
	Vector2(98.0, -34.0),
	Vector2(114.0, -22.0),   # Bridge 2
	Vector2(132.0, -24.0),
	Vector2(146.0, -32.0),   # Estuary into Great Tree Lake
]


func _ready() -> void:
	name = "IslandRiver"
	_build_waterfall()
	_build_river_channel()
	_build_bridges()
	_build_secret_cave()
	_build_river_flora()


# =========================================================================
# 1. CASCADING WATERFALL OF THE NYMPHS
# =========================================================================
func _build_waterfall() -> void:
	var wf_holder := Node3D.new()
	wf_holder.name = "Waterfall"
	add_child(wf_holder)

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.44, 0.42, 0.38)
	rock_mat.roughness = 0.9

	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water.gdshader") as Shader
	water_mat.set_shader_parameter("deep_color", Color(0.12, 0.45, 0.65))
	water_mat.set_shader_parameter("shallow_color", Color(0.65, 0.88, 0.95))
	water_mat.set_shader_parameter("sky_color", Color(0.85, 0.95, 1.0))

	# Stepped Cliff Bluff Terraces behind and beside the waterfall
	var cliff_tiers: Array[Dictionary] = [
		{"pos": WATERFALL_POS + Vector3(0.0, 3.0, -6.0), "size": Vector3(18.0, 6.0, 8.0)},
		{"pos": WATERFALL_POS + Vector3(0.0, 7.5, -9.0), "size": Vector3(16.0, 7.0, 7.0)},
		{"pos": WATERFALL_POS + Vector3(0.0, 11.5, -12.0), "size": Vector3(14.0, 5.0, 6.0)},
		{"pos": WATERFALL_POS + Vector3(-8.5, 5.0, -4.0), "size": Vector3(6.0, 10.0, 8.0)},
		{"pos": WATERFALL_POS + Vector3(8.5, 5.0, -4.0), "size": Vector3(6.0, 10.0, 8.0)},
	]

	for tier in cliff_tiers:
		var cliff := StaticBody3D.new()
		cliff.position = tier["pos"]
		var c_mesh := MeshInstance3D.new()
		var c_box := BoxMesh.new()
		c_box.size = tier["size"]
		c_mesh.mesh = c_box
		c_mesh.material_override = rock_mat
		cliff.add_child(c_mesh)
		var c_col := CollisionShape3D.new()
		var cs_box := BoxShape3D.new()
		cs_box.size = tier["size"]
		c_col.shape = cs_box
		cliff.add_child(c_col)
		wf_holder.add_child(cliff)

	# Cascading Vertical Falling Water Mesh Curtain
	var wf_mesh := MeshInstance3D.new()
	var w_box := BoxMesh.new()
	w_box.size = Vector3(6.8, 12.0, 0.4)
	wf_mesh.mesh = w_box
	wf_mesh.position = WATERFALL_POS + Vector3(0.0, 6.0, -1.8)
	wf_mesh.material_override = water_mat
	wf_holder.add_child(wf_mesh)

	# Plunge Pool Water Basin
	var pool := StaticBody3D.new()
	pool.position = WATERFALL_POS + Vector3(0.0, 0.04, 2.0)
	var p_mesh := MeshInstance3D.new()
	var p_cyl := CylinderMesh.new()
	p_cyl.top_radius = 5.5
	p_cyl.bottom_radius = 5.5
	p_cyl.height = 0.2
	p_mesh.mesh = p_cyl
	p_mesh.material_override = water_mat
	pool.add_child(p_mesh)
	wf_holder.add_child(pool)

	# Waterfall Signpost
	_add_signpost("Καταρράκτης των Νυμφών  ↑\nΠηγή του Ποταμού", WATERFALL_POS + Vector3(-6.5, 0.1, 4.0), 30.0, wf_holder)


# =========================================================================
# 2. THE SECRET CAVE BEHIND THE WATERFALL
# =========================================================================
func _build_secret_cave() -> void:
	var cave_holder := Node3D.new()
	cave_holder.name = "SecretWaterfallCave"
	add_child(cave_holder)

	var cavern_pos := WATERFALL_POS + Vector3(0.0, 0.1, -4.5)

	# Hidden treasure chest tucked in the dry rock grotto behind the falls
	var chest = Chest.new()
	chest.golden = true
	chest.gold_min = 300
	chest.gold_max = 550
	chest.potions = 2
	chest.position = cavern_pos
	chest.rotation_degrees.y = 180.0
	cave_holder.add_child(chest)

	# Mystical glowing crystal light in the cavern
	var omni := OmniLight3D.new()
	omni.light_color = Color(0.35, 0.85, 1.0)
	omni.light_energy = 2.4
	omni.omni_range = 9.0
	omni.position = cavern_pos + Vector3(0.0, 1.5, 0.0)
	cave_holder.add_child(omni)


# =========================================================================
# 3. RIVER CHANNEL WATER RIBBON & EMBANKMENTS
# =========================================================================
func _build_river_channel() -> void:
	var river_holder := Node3D.new()
	river_holder.name = "Channel"
	add_child(river_holder)

	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water.gdshader") as Shader
	water_mat.set_shader_parameter("deep_color", Color(0.08, 0.32, 0.48))
	water_mat.set_shader_parameter("shallow_color", Color(0.24, 0.65, 0.72))
	water_mat.set_shader_parameter("sky_color", Color(0.75, 0.88, 1.0))

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.48, 0.46, 0.42)
	stone_mat.roughness = 0.88

	var river_width := 5.4

	# Build water segments connecting consecutive waypoints
	for i in RIVER_WAYPOINTS.size() - 1:
		var p1 := RIVER_WAYPOINTS[i]
		var p2 := RIVER_WAYPOINTS[i + 1]
		var seg_len := p1.distance_to(p2)
		var seg_center := (p1 + p2) * 0.5
		var seg_dir := (p2 - p1).normalized()
		var yaw := atan2(seg_dir.x, seg_dir.y)

		var seg_node := StaticBody3D.new()
		seg_node.position = Vector3(seg_center.x, 0.03, seg_center.y)
		seg_node.rotation.y = yaw

		# Water surface mesh
		var w_mesh := MeshInstance3D.new()
		var w_box := BoxMesh.new()
		w_box.size = Vector3(river_width, 0.12, seg_len + 0.6)
		w_mesh.mesh = w_box
		w_mesh.material_override = water_mat
		seg_node.add_child(w_mesh)

		# Subtle submerged bed collider (player can walk/splash through)
		var s_col := CollisionShape3D.new()
		var sb_box := BoxShape3D.new()
		sb_box.size = Vector3(river_width, 0.12, seg_len + 0.6)
		s_col.shape = sb_box
		seg_node.add_child(s_col)
		river_holder.add_child(seg_node)

		# Riverbank stone props along the edges
		for side: float in [-1.0, 1.0]:
			var bank_pos: Vector3 = Vector3(seg_center.x, 0.1, seg_center.y) + Vector3(-seg_dir.y, 0.0, seg_dir.x) * (river_width * 0.55 * side)
			var r_mesh := MeshInstance3D.new()
			var r_cyl := CylinderMesh.new()
			r_cyl.top_radius = 0.45 + randf() * 0.3
			r_cyl.bottom_radius = 0.65 + randf() * 0.3
			r_cyl.height = 0.45 + randf() * 0.25
			r_mesh.mesh = r_cyl
			r_mesh.position = bank_pos
			r_mesh.material_override = stone_mat
			river_holder.add_child(r_mesh)


# =========================================================================
# 4. TWO ARCHED STONE BRIDGES
# =========================================================================
func _build_bridges() -> void:
	var bridge_holder := Node3D.new()
	bridge_holder.name = "Bridges"
	add_child(bridge_holder)

	# Bridge 1: Arched Stone Bridge across the Church & Meadow crossing (X=70, Z=-66)
	var b1 = _place_model("buildings/neutral/building_bridge_A.gltf", BRIDGE_1_POS, 65.0, 7.8, bridge_holder)
	if b1:
		_add_trimesh_collider(b1)

	# Bridge 2: Eastern Timber Bridge across the Great Tree Lake trail (X=114, Z=-22)
	var b2 = _place_model("buildings/neutral/building_bridge_B.gltf", BRIDGE_2_POS, 8.0, 7.8, bridge_holder)
	if b2:
		_add_trimesh_collider(b2)

	# Directional signposts by the bridges
	_add_signpost("Πέτρινο Γεφύρι  ←\nΠρος το Χωριό", BRIDGE_1_POS + Vector3(4.5, 0.1, -4.5), -45.0, bridge_holder)
	_add_signpost("Γέφυρα του Αιωνόβιου  →\nΠρος τη Μεγάλη Λίμνη", BRIDGE_2_POS + Vector3(-4.5, 0.1, -4.5), 45.0, bridge_holder)


# =========================================================================
# 5. RIVER FLORA: WATERLILIES & REEDS
# =========================================================================
func _build_river_flora() -> void:
	var flora_holder := Node3D.new()
	flora_holder.name = "RiverFlora"
	add_child(flora_holder)

	# Waterlilies floating on calm pools and bends
	var waterlilies: Array[Dictionary] = [
		{"model": "waterlily_A.gltf", "pos": WATERFALL_POS + Vector3(-2.2, 0.08, 4.2), "rot": 40.0, "sc": 1.4},
		{"model": "waterlily_B.gltf", "pos": WATERFALL_POS + Vector3(2.5, 0.08, 5.0), "rot": -70.0, "sc": 1.5},
		{"model": "waterlily_A.gltf", "pos": WATERFALL_POS + Vector3(0.5, 0.08, 6.8), "rot": 110.0, "sc": 1.3},
		{"model": "waterlily_B.gltf", "pos": Vector3(56.5, 0.08, -104.0), "rot": 25.0, "sc": 1.4},
		{"model": "waterlily_A.gltf", "pos": Vector3(64.0, 0.08, -78.0), "rot": -45.0, "sc": 1.5},
		{"model": "waterlily_B.gltf", "pos": Vector3(73.5, 0.08, -58.0), "rot": 80.0, "sc": 1.6},
		{"model": "waterlily_A.gltf", "pos": Vector3(88.0, 0.08, -42.0), "rot": -15.0, "sc": 1.5},
		{"model": "waterlily_B.gltf", "pos": Vector3(104.0, 0.08, -28.0), "rot": 60.0, "sc": 1.4},
		{"model": "waterlily_A.gltf", "pos": Vector3(122.0, 0.08, -21.0), "rot": -100.0, "sc": 1.6},
		{"model": "waterlily_B.gltf", "pos": Vector3(138.0, 0.08, -25.5), "rot": 45.0, "sc": 1.7},
		{"model": "waterlily_A.gltf", "pos": Vector3(143.0, 0.08, -30.0), "rot": -130.0, "sc": 1.6},
	]
	for wl in waterlilies:
		_place_model("decoration/nature/" + wl["model"], wl["pos"], wl["rot"], wl["sc"], flora_holder)

	# Tall reeds and waterplants along riverbanks and bridge footings
	var reeds: Array[Dictionary] = [
		{"model": "waterplant_A.gltf", "pos": WATERFALL_POS + Vector3(-5.2, 0.08, 3.0), "rot": 15.0, "sc": 1.4},
		{"model": "waterplant_C.gltf", "pos": WATERFALL_POS + Vector3(5.4, 0.08, 3.5), "rot": -40.0, "sc": 1.6},
		{"model": "waterplant_B.gltf", "pos": Vector3(51.0, 0.08, -114.0), "rot": 65.0, "sc": 1.5},
		{"model": "waterplant_A.gltf", "pos": Vector3(58.0, 0.08, -98.0), "rot": -80.0, "sc": 1.4},
		{"model": "waterplant_C.gltf", "pos": Vector3(66.5, 0.08, -70.0), "rot": 30.0, "sc": 1.6},
		{"model": "waterplant_B.gltf", "pos": Vector3(74.0, 0.08, -62.0), "rot": -120.0, "sc": 1.5},
		{"model": "waterplant_A.gltf", "pos": Vector3(81.0, 0.08, -51.0), "rot": 45.0, "sc": 1.3},
		{"model": "waterplant_C.gltf", "pos": Vector3(92.0, 0.08, -39.0), "rot": -35.0, "sc": 1.7},
		{"model": "waterplant_B.gltf", "pos": Vector3(110.5, 0.08, -26.0), "rot": 95.0, "sc": 1.5},
		{"model": "waterplant_A.gltf", "pos": Vector3(118.0, 0.08, -18.0), "rot": -75.0, "sc": 1.4},
		{"model": "waterplant_C.gltf", "pos": Vector3(134.0, 0.08, -21.0), "rot": 20.0, "sc": 1.8},
		{"model": "waterplant_B.gltf", "pos": Vector3(146.5, 0.08, -34.0), "rot": -110.0, "sc": 1.6},
	]
	for rd in reeds:
		_place_model("decoration/nature/" + rd["model"], rd["pos"], rd["rot"], rd["sc"], flora_holder)


# --- Helpers ---
func _add_trimesh_collider(root: Node3D) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		if mesh_inst and mesh_inst.mesh:
			mesh_inst.create_trimesh_collision()


func _place_model(path: String, pos: Vector3, rot_deg: float, sc: float, parent: Node) -> Node3D:
	var full := "res://assets/world/" + path
	var res := load(full) as PackedScene
	if res:
		var inst := res.instantiate() as Node3D
		inst.position = pos
		inst.rotation_degrees.y = rot_deg
		inst.scale = Vector3.ONE * sc
		parent.add_child(inst)
		return inst
	return null


func _add_signpost(text: String, pos: Vector3, rot_deg: float, parent: Node) -> void:
	var sign_node := Node3D.new()
	sign_node.position = pos
	sign_node.rotation_degrees.y = rot_deg

	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.40, 0.25, 0.12)
	post_mat.roughness = 0.85

	# Board: Width 2.9m, Height 0.85m, Depth 0.12m, Center Y = 1.45m
	# Board bottom is at Y = 1.45 - 0.425 = 1.025m
	var board_y := 1.45
	var board_h := 0.85
	var board_w := 2.9
	var board_d := 0.12
	var board_bottom := board_y - board_h * 0.5   # 1.025m

	var board := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(board_w, board_h, board_d)
	board.mesh = b_box
	board.position = Vector3(0.0, board_y, 0.0)
	board.material_override = post_mat
	sign_node.add_child(board)

	# Post: stops exactly at the bottom of the board (Y = 1.025m)
	var post_mesh := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(0.18, board_bottom, 0.18)
	post_mesh.mesh = p_box
	post_mesh.position = Vector3(0.0, board_bottom * 0.5, 0.0)
	post_mesh.material_override = post_mat
	sign_node.add_child(post_mesh)

	# Front Label: single-sided, centered, sharp outline
	var label := Label3D.new()
	label.text = text
	label.font_size = 36
	label.pixel_size = 0.0044
	label.outline_size = 8
	label.outline_modulate = Color(0.12, 0.08, 0.04)
	label.modulate = Color(0.98, 0.94, 0.82)
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector3(0.0, board_y, board_d * 0.5 + 0.015)
	sign_node.add_child(label)

	# Back Label
	var back := Label3D.new()
	back.text = text
	back.font_size = 36
	back.pixel_size = 0.0044
	back.outline_size = 8
	back.outline_modulate = Color(0.12, 0.08, 0.04)
	back.modulate = Color(0.98, 0.94, 0.82)
	back.double_sided = false
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.position = Vector3(0.0, board_y, -board_d * 0.5 - 0.015)
	back.rotation_degrees.y = 180.0
	sign_node.add_child(back)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(0.4, 1.9, 0.4)
	col.shape = cbox
	col.position.y = 0.95
	body.add_child(col)
	sign_node.add_child(body)

	parent.add_child(sign_node)
