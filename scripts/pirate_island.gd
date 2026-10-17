class_name PirateIsland
extends Node3D
## The Volcanic Pirate Island (Το Νησί των Πειρατών & το Ηφαίστειο):
## A towering, non-flat volcanic island rising out of the southern ocean.
## Features a pirate cove with a wooden landing pier, winding ascending mountain trails,
## rocky hills, pirate encampments and watchtowers, and a central active volcano with a glowing
## magma caldera, guarded by Captain Dread («Αρχικουρσάρος Μαυροδόντης») and the Cursed Pirate Chest.

const ISLAND_CENTER := Vector3(-25.0, 0.0, 465.0)
const DOCK_POS := Vector3(-25.0, 0.45, 396.0)
const COVE_POS := Vector3(-25.0, 0.8, 412.0)
const CAMP_POS := Vector3(-40.0, 3.8, 424.0)
const LOOKOUT_POS := Vector3(-8.0, 9.8, 446.0)
const CRATER_POS := Vector3(-25.0, 14.8, 465.0)
const ALTAR_POS := Vector3(-25.0, 15.8, 465.0)

var _reached := false
var _magma_light: OmniLight3D
var _magma_phase := 0.0
var _boss_spawned := false


func _ready() -> void:
	name = "PirateVolcanoIsland"
	add_to_group("pirate_island")
	_build_island_terrain()
	_build_caldera_lava()
	_build_mountain_trails()
	_build_pirate_cove()
	_build_encampments()
	_build_crater_arena()


func _physics_process(delta: float) -> void:
	# Subtle magma pulse & flickering light inside the volcano crater
	if _magma_light != null:
		_magma_phase += delta * 2.5
		_magma_light.light_energy = 3.6 + sin(_magma_phase) * 0.75 + cos(_magma_phase * 1.7) * 0.35

	# Discovery / Quest Reach Trigger when player arrives at pirate island
	if not _reached:
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null and is_instance_valid(player):
			var dist: float = Vector2(player.global_position.x - ISLAND_CENTER.x, player.global_position.z - ISLAND_CENTER.z).length()
			if dist < 75.0:
				_reached = true
				var quests = get_node_or_null("/root/Quests")
				if quests and quests.has_method("report_reach"):
					quests.report_reach("pirate_island")
				if player.has_signal("message"):
					player.message.emit("Ανακάλυψες: Το Νησί των Πειρατών & το Ηφαίστειο! 🌋")
				Sfx.ui("quest_new")

	# Spawn pirate mobs and Captain Dread when player approaches
	if not _boss_spawned:
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null and is_instance_valid(player):
			var dist: float = Vector2(player.global_position.x - ISLAND_CENTER.x, player.global_position.z - ISLAND_CENTER.z).length()
			if dist < 120.0:
				_boss_spawned = true
				_spawn_pirate_enemies()


# =========================================================================
# 1. PROCEDURAL VOLCANIC MOUNTAIN & UPHILL TERRAIN
# =========================================================================
func _calc_island_height(lx: float, lz: float) -> float:
	var r := sqrt(lx * lx + lz * lz)
	var max_r := 68.0
	if r >= max_r:
		# Sloping underwater seabed surrounding island
		return -1.8

	# Angle around center for asymmetric organic ridgelines
	var angle := atan2(lz, lx)
	var ridge_noise := sin(angle * 3.0) * 2.2 + cos(angle * 5.0 + 1.2) * 1.4

	# Northern Pirate Cove indentation (easy landing at dock/beach)
	var is_north_cove := (lz < -20.0 and absf(lx) < 22.0)
	if is_north_cove:
		var cove_t := clampf((lz + 45.0) / 25.0, 0.0, 1.0)
		return lerpf(-0.8, 1.8, cove_t)

	# Caldera Crater (Center r < 13.0m)
	if r < 5.2:
		# Central Obsidian Boss Platform
		return 15.8
	elif r < 12.5:
		# Sunken Lava Lake Caldera floor
		return 14.8
	elif r <= 16.0:
		# Inner crater lip ascending steeply up to rim
		var t := (r - 12.5) / 3.5
		return lerpf(14.8, 20.5 + ridge_noise * 0.4, t)
	elif r <= 28.0:
		# Outer steep volcano cone
		var t := (r - 16.0) / 12.0
		return lerpf(20.5 + ridge_noise * 0.4, 9.5 + ridge_noise, t)
	elif r <= 48.0:
		# Mid-elevation hills, ridges, and pirate outposts
		var t := (r - 28.0) / 20.0
		var base_h := lerpf(9.5, 3.2, t)
		return base_h + ridge_noise * 0.7
	else:
		# Coastal sand & rocky slope meeting sea level (Y = 0.0)
		var t := (r - 48.0) / (max_r - 48.0)
		return lerpf(3.2, -0.8, t)


func _build_island_terrain() -> void:
	var terrain_holder := Node3D.new()
	terrain_holder.name = "VolcanicTerrain"
	add_child(terrain_holder)

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.22, 0.19, 0.18) # dark volcanic basalt rock
	rock_mat.roughness = 0.94
	rock_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var steps := 44
	var extent := 68.0

	for zi in (steps + 1):
		var z_t := float(zi) / float(steps)
		var lz := lerpf(-extent, extent, z_t)
		for xi in (steps + 1):
			var x_t := float(xi) / float(steps)
			var lx := lerpf(-extent, extent, x_t)
			var ly := _calc_island_height(lx, lz)
			var wpos := ISLAND_CENTER + Vector3(lx, ly, lz)

			st.set_uv(Vector2(x_t * 14.0, z_t * 14.0))
			st.add_vertex(wpos)

	for zi in steps:
		for xi in steps:
			var i0 := zi * (steps + 1) + xi
			var i1 := i0 + 1
			var i2 := (zi + 1) * (steps + 1) + xi
			var i3 := i2 + 1
			st.add_index(i0)
			st.add_index(i1)
			st.add_index(i2)

			st.add_index(i1)
			st.add_index(i3)
			st.add_index(i2)

	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = rock_mat
	terrain_holder.add_child(mi)

	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = mesh.create_trimesh_shape()
	sb.add_child(col)
	terrain_holder.add_child(sb)


# =========================================================================
# 2. CALDERA MAGMA POOL & ERUPTIVE GLOW
# =========================================================================
func _build_caldera_lava() -> void:
	var caldera_holder := Node3D.new()
	caldera_holder.name = "CalderaMagma"
	add_child(caldera_holder)

	var lava_mat := StandardMaterial3D.new()
	lava_mat.albedo_color = Color(1.0, 0.38, 0.06)
	lava_mat.emission_enabled = true
	lava_mat.emission = Color(1.0, 0.32, 0.04)
	lava_mat.emission_energy_multiplier = 3.6
	lava_mat.roughness = 0.22

	# Circular Magma pool disk inside the crater floor (Y = 14.8m)
	var lava_mesh := CylinderMesh.new()
	lava_mesh.top_radius = 12.2
	lava_mesh.bottom_radius = 12.2
	lava_mesh.height = 0.4
	var mi := MeshInstance3D.new()
	mi.mesh = lava_mesh
	mi.material_override = lava_mat
	mi.position = CRATER_POS + Vector3(0.0, 0.0, 0.0)
	caldera_holder.add_child(mi)

	# Dynamic flickering volcanic illumination
	_magma_light = OmniLight3D.new()
	_magma_light.light_color = Color(1.0, 0.42, 0.12)
	_magma_light.light_energy = 4.2
	_magma_light.omni_range = 38.0
	_magma_light.position = CRATER_POS + Vector3(0.0, 2.5, 0.0)
	caldera_holder.add_child(_magma_light)

	# Obsidian Boss Altar Platform in the center of the magma
	var stone_dark := StandardMaterial3D.new()
	stone_dark.albedo_color = Color(0.12, 0.10, 0.11)
	stone_dark.roughness = 0.85

	var altar_body := StaticBody3D.new()
	altar_body.position = ALTAR_POS
	var a_mesh := MeshInstance3D.new()
	var a_cyl := CylinderMesh.new()
	a_cyl.top_radius = 5.2
	a_cyl.bottom_radius = 5.8
	a_cyl.height = 1.4
	a_mesh.mesh = a_cyl
	a_mesh.material_override = stone_dark
	altar_body.add_child(a_mesh)
	var a_col := CollisionShape3D.new()
	var ac_cyl := CylinderShape3D.new()
	ac_cyl.radius = 5.4
	ac_cyl.height = 1.4
	a_col.shape = ac_cyl
	altar_body.add_child(a_col)
	caldera_holder.add_child(altar_body)

	# Arched Stone Bridge across the magma: connecting north crater rim (Z = 452) to altar (Z = 460)
	var bridge_body := StaticBody3D.new()
	bridge_body.position = ISLAND_CENTER + Vector3(0.0, 16.8, -8.5)
	bridge_body.rotation_degrees.x = -15.0 # sloping down from rim to altar
	var b_mesh := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(3.4, 0.6, 9.5)
	b_mesh.mesh = b_box
	b_mesh.material_override = stone_dark
	bridge_body.add_child(b_mesh)
	var b_col := CollisionShape3D.new()
	var bc_box := BoxShape3D.new()
	bc_box.size = Vector3(3.4, 0.6, 9.5)
	b_col.shape = bc_box
	bridge_body.add_child(b_col)
	caldera_holder.add_child(bridge_body)

	# Decorative Basalt Pillars & Skull posts around the caldera rim
	for i in 6:
		var rad := float(i) * PI / 3.0
		var px := ISLAND_CENTER.x + cos(rad) * 13.8
		var pz := ISLAND_CENTER.z + sin(rad) * 13.8
		var py := 19.8
		_place_prop("res://assets/graveyard/post_skull.gltf", Vector3(px, py, pz), rad_to_deg(rad), 1.3, caldera_holder)


# =========================================================================
# 3. MOUNTAIN TRAILS & ASCENT RAMPS
# =========================================================================
func _build_mountain_trails() -> void:
	var trail_holder := Node3D.new()
	trail_holder.name = "MountainTrails"
	add_child(trail_holder)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.42, 0.30, 0.18)
	wood_mat.roughness = 0.88

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.35, 0.32, 0.30)
	stone_mat.roughness = 0.90

	# 1. Lower Trail Ramp: from Dock Landing (Z=398, Y=0.6) to Cove Camp (Z=418, Y=2.8)
	_make_ramp(ISLAND_CENTER + Vector3(-5.0, 1.7, -57.0), Vector3(3.8, 0.3, 22.0), -6.0, trail_holder, wood_mat)

	# 2. Mid Switchback Ramp: from Cove Camp (Z=418, Y=2.8) to Western Outpost (Z=432, Y=6.5)
	_make_ramp(ISLAND_CENTER + Vector3(-16.0, 4.6, -40.0), Vector3(3.6, 0.3, 18.0), -12.0, trail_holder, stone_mat)

	# 3. Upper Mountain Ridge Ramp: from Outpost (Z=432, Y=6.5) up to Lookout & Crater Lip (Z=451, Y=18.5)
	_make_ramp(ISLAND_CENTER + Vector3(-8.0, 12.5, -22.0), Vector3(3.6, 0.3, 24.0), -28.0, trail_holder, stone_mat)

	# Trail wayfinding torches
	var torch_coords: Array[Vector3] = [
		ISLAND_CENTER + Vector3(-2.0, 1.2, -64.0),
		ISLAND_CENTER + Vector3(-8.0, 3.2, -50.0),
		ISLAND_CENTER + Vector3(-20.0, 5.8, -34.0),
		ISLAND_CENTER + Vector3(-12.0, 10.5, -26.0),
		ISLAND_CENTER + Vector3(-2.0, 15.2, -18.0),
		ISLAND_CENTER + Vector3(-25.0, 19.8, -14.0),
	]
	for tpos in torch_coords:
		_add_maritime_torch(tpos, trail_holder)


func _make_ramp(pos: Vector3, size: Vector3, pitch_deg: float, parent: Node, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.x = pitch_deg
	body.collision_layer = 1
	body.collision_mask = 0

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	body.add_child(col)

	parent.add_child(body)
	return body


func _add_maritime_torch(pos: Vector3, parent: Node) -> void:
	var post := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.08
	pc.bottom_radius = 0.1
	pc.height = 1.6
	post.mesh = pc
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	post.material_override = wood_mat
	post.position = pos + Vector3(0.0, 0.8, 0.0)
	parent.add_child(post)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.25)
	light.light_energy = 2.2
	light.omni_range = 9.0
	light.position = pos + Vector3(0.0, 1.7, 0.0)
	parent.add_child(light)


# =========================================================================
# 4. PIRATE COVE & LANDING DOCK
# =========================================================================
func _build_pirate_cove() -> void:
	var cove_holder := Node3D.new()
	cove_holder.name = "PirateCove"
	add_child(cove_holder)

	var wood_dock := StandardMaterial3D.new()
	wood_dock.albedo_color = Color(0.42, 0.28, 0.16)
	wood_dock.roughness = 0.85

	# 1. Main Landing Pier (Width: 4.8m, Length: 20m, Y = 0.45m)
	var pier := StaticBody3D.new()
	pier.position = DOCK_POS
	pier.collision_layer = 1
	pier.collision_mask = 0

	var p_mesh := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(4.8, 0.35, 20.0)
	p_mesh.mesh = p_box
	p_mesh.material_override = wood_dock
	pier.add_child(p_mesh)

	var p_col := CollisionShape3D.new()
	var pc_box := BoxShape3D.new()
	pc_box.size = Vector3(4.8, 0.35, 20.0)
	p_col.shape = pc_box
	pier.add_child(p_col)
	cove_holder.add_child(pier)

	# Pilings under pier
	for z_off in range(-8, 9, 4):
		for x_off in [-2.2, 2.2]:
			var pile := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.15
			pc.bottom_radius = 0.18
			pc.height = 3.4
			pile.mesh = pc
			pile.material_override = wood_dock
			pile.position = DOCK_POS + Vector3(x_off, -0.9, float(z_off))
			cove_holder.add_child(pile)

	# Dock signpost and lanterns
	_place_prop("res://assets/world/decoration/props/barrel.gltf", DOCK_POS + Vector3(1.8, 0.25, 4.0), 15.0, 1.2, cove_holder)
	_place_prop("res://assets/world/decoration/props/crate_A_big.gltf", DOCK_POS + Vector3(-1.8, 0.25, 2.0), 30.0, 1.1, cove_holder)
	_place_prop("res://assets/world/decoration/props/crate_A_small.gltf", DOCK_POS + Vector3(-1.7, 0.85, 2.0), -15.0, 1.0, cove_holder)
	_place_prop("res://assets/graveyard/post_skull.gltf", DOCK_POS + Vector3(2.6, 0.2, 8.0), -20.0, 1.3, cove_holder)
	_place_prop("res://assets/graveyard/post_skull.gltf", DOCK_POS + Vector3(-2.6, 0.2, 8.0), 20.0, 1.3, cove_holder)

	_add_signpost("Όρμος των Πειρατών  ☠\nΝησί του Ηφαιστείου", DOCK_POS + Vector3(3.2, 0.2, -6.0), -25.0, cove_holder)


# =========================================================================
# 5. PIRATE ENCAMPMENTS & LOOKOUTS
# =========================================================================
func _build_encampments() -> void:
	var camp_holder := Node3D.new()
	camp_holder.name = "PirateEncampments"
	add_child(camp_holder)

	# 1. Lower Outpost at CAMP_POS (Z=424, Y=3.8)
	_place_prop("res://assets/world/decoration/props/tent.gltf", CAMP_POS + Vector3(-3.5, 0.0, 0.0), 45.0, 1.3, camp_holder)
	_place_prop("res://assets/world/decoration/props/tent.gltf", CAMP_POS + Vector3(3.2, 0.0, 2.5), -70.0, 1.2, camp_holder)
	_place_prop("res://assets/world/decoration/props/weaponrack.gltf", CAMP_POS + Vector3(0.5, 0.0, -3.2), 10.0, 1.2, camp_holder)
	_place_prop("res://assets/world/decoration/props/barrel.gltf", CAMP_POS + Vector3(-1.8, 0.0, 3.2), 0.0, 1.2, camp_holder)
	_place_prop("res://assets/world/decoration/props/crate_A_big.gltf", CAMP_POS + Vector3(-2.6, 0.0, 2.8), 25.0, 1.1, camp_holder)

	# Campfire
	var c_light := OmniLight3D.new()
	c_light.light_color = Color(1.0, 0.6, 0.2)
	c_light.light_energy = 2.4
	c_light.omni_range = 10.0
	c_light.position = CAMP_POS + Vector3(0.0, 0.7, 0.0)
	camp_holder.add_child(c_light)

	# 2. Mid-Mountain Artillery Lookout Tower at LOOKOUT_POS (Z=446, Y=9.8)
	var tower := StaticBody3D.new()
	tower.position = LOOKOUT_POS
	tower.collision_layer = 1
	tower.collision_mask = 0

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.38, 0.25, 0.14)

	var t_mesh := MeshInstance3D.new()
	var t_box := BoxMesh.new()
	t_box.size = Vector3(5.2, 0.4, 5.2)
	t_mesh.mesh = t_box
	t_mesh.material_override = wood_mat
	tower.add_child(t_mesh)

	var t_col := CollisionShape3D.new()
	var tc_box := BoxShape3D.new()
	tc_box.size = Vector3(5.2, 0.4, 5.2)
	t_col.shape = tc_box
	tower.add_child(t_col)
	camp_holder.add_child(tower)

	# Lookout tower stilts
	for ox in [-2.2, 2.2]:
		for oz in [-2.2, 2.2]:
			var stilt := MeshInstance3D.new()
			var sc := CylinderMesh.new()
			sc.top_radius = 0.16
			sc.bottom_radius = 0.2
			sc.height = 4.2
			stilt.mesh = sc
			stilt.material_override = wood_mat
			stilt.position = LOOKOUT_POS + Vector3(ox, -2.1, oz)
			camp_holder.add_child(stilt)

	_place_prop("res://assets/world/decoration/props/ladder.gltf", LOOKOUT_POS + Vector3(-2.6, -1.8, 0.0), 90.0, 1.4, camp_holder)
	_place_prop("res://assets/items/banner_red.gltf.glb", LOOKOUT_POS + Vector3(2.0, 0.2, -2.0), 0.0, 1.4, camp_holder)
	_place_prop("res://assets/world/decoration/props/crate_A_big.gltf", LOOKOUT_POS + Vector3(1.6, 0.2, 1.6), 20.0, 1.1, camp_holder)


# =========================================================================
# 6. CRATER ARENA, BOSS & CURSED CHEST
# =========================================================================
func _build_crater_arena() -> void:
	var arena_holder := Node3D.new()
	arena_holder.name = "CraterArena"
	add_child(arena_holder)

	# The Cursed Pirate Chest of the Volcano
	var chest = Chest.new()
	chest.golden = true
	chest.gold_min = 400
	chest.gold_max = 650
	chest.potions = 3
	chest.quest_item = "pirate_treasure"
	chest.position = ALTAR_POS + Vector3(0.0, 0.7, 1.8)
	chest.rotation_degrees.y = 180.0
	arena_holder.add_child(chest)

	# Pedestal skull guardians around the treasure
	_place_prop("res://assets/graveyard/post_skull.gltf", ALTAR_POS + Vector3(-2.2, 0.7, 1.8), 45.0, 1.2, arena_holder)
	_place_prop("res://assets/graveyard/post_skull.gltf", ALTAR_POS + Vector3(2.2, 0.7, 1.8), -45.0, 1.2, arena_holder)


func _spawn_pirate_enemies() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner != null and spawner.has_method("spawn_extra"):
		# 1. Captain Dread in the Caldera
		spawner.spawn_extra("pirate_captain", ALTAR_POS + Vector3(0.0, 0.7, -1.0))

		# 2. Lookout tower guards
		spawner.spawn_extra("pirate_corsair", LOOKOUT_POS + Vector3(0.0, 0.3, 0.0))
		spawner.spawn_extra("pirate_corsair", LOOKOUT_POS + Vector3(4.0, -1.0, 2.0))

		# 3. Lower Outpost camp guards
		spawner.spawn_extra("pirate_corsair", CAMP_POS + Vector3(-2.0, 0.1, -1.5))
		spawner.spawn_extra("pirate_corsair", CAMP_POS + Vector3(2.5, 0.1, 1.0))
		spawner.spawn_extra("pirate_corsair", COVE_POS + Vector3(0.0, 0.1, 0.0))


# --- Helpers ---
func _place_prop(path: String, pos: Vector3, rot_deg: float, sc: float, parent: Node) -> Node3D:
	var res := load(path) as PackedScene
	if res:
		var root := Node3D.new()
		var base := path.get_file().get_basename()
		root.name = base if not parent.has_node(base) else "%s_%d" % [base, parent.get_child_count()]
		root.position = pos
		root.rotation_degrees.y = rot_deg
		var visual := res.instantiate() as Node3D
		visual.name = "Visual"
		visual.scale = Vector3.ONE * sc
		root.add_child(visual)
		parent.add_child(root)
		return root
	return null


func _add_signpost(text: String, pos: Vector3, rot_deg: float, parent: Node) -> void:
	var sign_node := Node3D.new()
	sign_node.position = pos
	sign_node.rotation_degrees.y = rot_deg

	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.38, 0.22, 0.12)
	post_mat.roughness = 0.85

	var board_y := 1.45
	var board_h := 0.85
	var board_w := 2.8
	var board_d := 0.12
	var board_bottom := board_y - board_h * 0.5

	var board := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(board_w, board_h, board_d)
	board.mesh = b_box
	board.position = Vector3(0.0, board_y, 0.0)
	board.material_override = post_mat
	sign_node.add_child(board)

	var post_mesh := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(0.18, board_bottom, 0.18)
	post_mesh.mesh = p_box
	post_mesh.position = Vector3(0.0, board_bottom * 0.5, 0.0)
	post_mesh.material_override = post_mat
	sign_node.add_child(post_mesh)

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

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(0.4, 1.9, 0.4)
	col.shape = cbox
	col.position.y = 0.95
	body.add_child(col)
	sign_node.add_child(body)

	parent.add_child(sign_node)
