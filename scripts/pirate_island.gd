class_name PirateIsland
extends Node3D
## The Expansive Volcanic Pirate Island (Το Νησί των Πειρατών & το Ηφαίστειο):
## A massive, 4x enlarged tropical & volcanic island rising out of the southern ocean.
## Features:
## 1. Non-flat multi-tier topography: golden coastal beaches, lush emerald rolling hills,
##    highland jungle lake, and a towering central active volcano with a bubbling magma caldera.
## 2. Abundant wildlife: graceful wild deer roaming the green valleys and lake shores.
## 3. Dense forests: 60+ coastal pines, palms, and broadleaf tree groves with proper collision.
## 4. Pirate outposts: landing pier in the cove, lower camp, lake overlook, artillery watchtower,
##    with ALL mobs spawned strictly inland on dry elevated ground (never in the sea!).
## 5. Secret Smuggler's Grotto: hidden treasure cache with massive gold, gems, and ancient signpost.
## 6. Caldera Arena: Captain Dread («Αρχικουρσάρος Μαυροδόντης») guarding the Cursed Pirate Chest.

const ISLAND_CENTER := Vector3(-20.0, 0.0, 520.0)
const ISLAND_RADIUS := 145.0

# Strategic Landmark Coordinates
const DOCK_POS := Vector3(-20.0, 0.65, 385.0)          # Wooden pier in the northern cove
const DOCK_GATE_POS := Vector3(-20.0, 2.6, 408.0)      # Inland dock entrance terrace (safe dry land)
const LOWER_CAMP_POS := Vector3(-55.0, 6.8, 445.0)     # Lower green hillside outpost
const LAKE_CENTER := Vector3(-75.0, 7.5, 520.0)        # Highland jungle freshwater lake
const LAKE_CAMP_POS := Vector3(-42.0, 9.4, 490.0)      # Valley pass overlooking the lake
const LOOKOUT_POS := Vector3(25.0, 14.5, 480.0)        # Eastern artillery bluff with watchtower
const CRATER_POS := Vector3(-20.0, 17.0, 520.0)        # Volcanic caldera magma floor
const ALTAR_POS := Vector3(-20.0, 18.2, 520.0)         # Central obsidian boss platform
const SECRET_CACHE_POS := Vector3(35.0, 8.2, 535.0)    # Hidden Smuggler's Grotto

var _reached := false
var _magma_light: OmniLight3D
var _magma_phase := 0.0
var _boss_spawned := false


func _ready() -> void:
	name = "PirateVolcanoIsland"
	add_to_group("pirate_island")
	_build_island_terrain()
	_build_highland_lake()
	_build_caldera_volcano()
	_build_mountain_trails()
	_build_pirate_cove_and_dock()
	_build_forest_groves()
	_build_wildlife()
	_build_encampments()
	_build_secret_treasure_grotto()
	_build_crater_arena()


func _physics_process(delta: float) -> void:
	# Subtle magma pulse & flickering light inside the volcano crater
	if _magma_light != null:
		_magma_phase += delta * 2.5
		_magma_light.light_energy = 4.2 + sin(_magma_phase) * 0.85 + cos(_magma_phase * 1.7) * 0.4

	# Discovery / Quest Reach Trigger when player arrives at pirate island
	if not _reached:
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null and is_instance_valid(player):
			var dist: float = Vector2(player.global_position.x - ISLAND_CENTER.x, player.global_position.z - ISLAND_CENTER.z).length()
			if dist < 150.0:
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
			if dist < 175.0:
				_boss_spawned = true
				_spawn_pirate_enemies()


# =========================================================================
# 1. 4X PROCEDURAL TOPOGRAPHY & ELEVATION
# =========================================================================
func _calc_island_height(lx: float, lz: float) -> float:
	var r := sqrt(lx * lx + lz * lz)
	if r >= ISLAND_RADIUS:
		return -2.5 # Deep ocean shelf surrounding the island

	var angle := atan2(lz, lx)
	var ridge_noise := sin(angle * 3.0) * 3.8 + cos(angle * 5.0 + 1.4) * 2.6 + sin(lx * 0.05 + lz * 0.04) * 2.0

	# 1. Northern Pirate Cove (Gentle natural slope to landing beach & dock)
	var is_north_cove := (lz < -70.0 and absf(lx) < 45.0)
	if is_north_cove:
		var cove_t := clampf((lz + 138.0) / 68.0, 0.0, 1.0)
		return lerpf(0.5, 6.5, cove_t)

	# 2. Central Volcano Caldera & Altar (r < 24.0m)
	if r < 7.0:
		# Central Obsidian Boss Platform
		return 18.2
	elif r < 16.5:
		# Sunken Molten Magma Lake floor
		return 17.0
	elif r <= 23.5:
		# Inner crater wall rising sharply to the rim
		var t := (r - 16.5) / 7.0
		return lerpf(17.0, 25.5, t)
	elif r <= 48.0:
		# Outer steep volcano cone
		var t := (r - 23.5) / 24.5
		return lerpf(25.5, 12.5 + ridge_noise * 0.6, t)

	# 3. Western Mountain Jungle Lake Basin (Hollow in the hills around lx = -55, lz = 0)
	var lake_dist := sqrt((lx + 55.0) * (lx + 55.0) + lz * lz)
	if lake_dist < 26.0:
		var lt := lake_dist / 26.0
		return lerpf(6.2, 8.8, lt)

	# 4. Lush Green Rolling Hills & Terraces (r in [48.0, 125.0])
	if r <= 125.0:
		var t := (r - 48.0) / 77.0
		var base_h := lerpf(12.5, 4.0, t)
		return maxf(base_h + ridge_noise, 3.2)

	# 5. Coastal Sand & Pebble Shorelines (r in [125.0, 145.0])
	var coast_t := (r - 125.0) / (ISLAND_RADIUS - 125.0)
	return lerpf(4.0, -2.5, coast_t)


func _build_island_terrain() -> void:
	var terrain_holder := Node3D.new()
	terrain_holder.name = "VolcanicTerrain"
	add_child(terrain_holder)

	var terrain_mat := StandardMaterial3D.new()
	terrain_mat.vertex_color_use_as_albedo = true
	terrain_mat.roughness = 0.92
	terrain_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var x_steps := 72
	var z_steps := 72
	var span := 152.0

	for zi in (z_steps + 1):
		var z_t := float(zi) / float(z_steps)
		var lz := lerpf(-span, span, z_t)
		for xi in (x_steps + 1):
			var x_t := float(xi) / float(x_steps)
			var lx := lerpf(-span, span, x_t)
			var ly := _calc_island_height(lx, lz)
			var r := sqrt(lx * lx + lz * lz)

			# Color zoning: lush green valleys, golden sand beaches, dark volcanic rock peak
			var col: Color
			if r > 125.0:
				# Golden Mediterranean coastal sand
				col = Color(0.86, 0.76, 0.54)
			elif r <= 125.0 and r > 48.0:
				# Check if near the jungle lake
				var lake_dist := sqrt((lx + 55.0) * (lx + 55.0) + lz * lz)
				if lake_dist < 32.0:
					col = Color(0.20, 0.48, 0.18) # rich lake marsh green
				else:
					# Vibrant emerald rolling hills
					var hill_shade := (sin(lx * 0.1) + cos(lz * 0.1)) * 0.05
					col = Color(0.24 + hill_shade, 0.53 + hill_shade, 0.17)
			elif r <= 48.0 and r > 24.0:
				# Volcanic ash & scorched rock slope
				col = Color(0.30, 0.25, 0.21)
			else:
				# Caldera basalt & obsidian rock
				col = Color(0.14, 0.13, 0.13)

			st.set_color(col)
			st.set_uv(Vector2(x_t * 18.0, z_t * 18.0))
			st.add_vertex(ISLAND_CENTER + Vector3(lx, ly, lz))

	for zi in z_steps:
		for xi in x_steps:
			var i0 := zi * (x_steps + 1) + xi
			var i1 := i0 + 1
			var i2 := (zi + 1) * (x_steps + 1) + xi
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
	mi.material_override = terrain_mat
	terrain_holder.add_child(mi)

	var sb := StaticBody3D.new()
	sb.name = "TerrainCollider"
	var col_shape := CollisionShape3D.new()
	col_shape.shape = mesh.create_trimesh_shape()
	sb.add_child(col_shape)
	terrain_holder.add_child(sb)


# =========================================================================
# 2. HIGHLAND JUNGLE FRESHWATER LAKE
# =========================================================================
func _build_highland_lake() -> void:
	var lake_holder := Node3D.new()
	lake_holder.name = "HighlandLake"
	add_child(lake_holder)

	# 1. Azure Freshwater Lake Surface
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.14, 0.58, 0.68, 0.88)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.08
	water_mat.metallic = 0.15

	var lake_mesh := MeshInstance3D.new()
	var l_cyl := CylinderMesh.new()
	l_cyl.top_radius = 24.5
	l_cyl.bottom_radius = 24.5
	l_cyl.height = 0.3
	lake_mesh.mesh = l_cyl
	lake_mesh.material_override = water_mat
	lake_mesh.position = LAKE_CENTER + Vector3(0.0, 0.0, 0.0)
	lake_holder.add_child(lake_mesh)

	# 2. Water Flora: Waterlilies and Reeds
	var lily_models: Array[String] = [
		"res://assets/world/decoration/nature/waterlily_A.gltf",
		"res://assets/world/decoration/nature/waterlily_B.gltf",
	]
	var reed_models: Array[String] = [
		"res://assets/world/decoration/nature/waterplant_A.gltf",
		"res://assets/world/decoration/nature/waterplant_B.gltf",
	]

	# Floating water lilies
	for i in 12:
		var rad := randf() * TAU
		var dist := randf_range(4.0, 18.0)
		var lp := LAKE_CENTER + Vector3(cos(rad) * dist, 0.16, sin(rad) * dist)
		var l_path: String = lily_models[i % lily_models.size()]
		_place_prop(l_path, lp, randf() * 360.0, randf_range(1.4, 2.2), lake_holder)

	# Shoreline reeds
	for i in 14:
		var rad := (float(i) / 14.0) * TAU
		var rp := LAKE_CENTER + Vector3(cos(rad) * 22.5, 0.1, sin(rad) * 22.5)
		var r_path: String = reed_models[i % reed_models.size()]
		_place_prop(r_path, rp, randf() * 360.0, randf_range(1.6, 2.5), lake_holder)

	# 3. Wooden Footbridge crossing the lake channel
	var bridge := StaticBody3D.new()
	bridge.position = LAKE_CENTER + Vector3(0.0, 0.25, 0.0)
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.42, 0.28, 0.16)
	wood_mat.roughness = 0.85

	var b_mesh := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(3.2, 0.35, 18.0)
	b_mesh.mesh = b_box
	b_mesh.material_override = wood_mat
	bridge.add_child(b_mesh)

	var b_col := CollisionShape3D.new()
	var bc_box := BoxShape3D.new()
	bc_box.size = b_box.size
	b_col.shape = bc_box
	bridge.add_child(b_col)
	lake_holder.add_child(bridge)


# =========================================================================
# 3. VOLCANIC CALDERA & MOLTEN MAGMA
# =========================================================================
func _build_caldera_volcano() -> void:
	var caldera_holder := Node3D.new()
	caldera_holder.name = "CalderaMagma"
	add_child(caldera_holder)

	# Glowing Molten Lava Lake Material
	var lava_mat := StandardMaterial3D.new()
	lava_mat.albedo_color = Color(1.0, 0.38, 0.06)
	lava_mat.emission_enabled = true
	lava_mat.emission = Color(1.0, 0.32, 0.04)
	lava_mat.emission_energy_multiplier = 4.0
	lava_mat.roughness = 0.2

	# Circular Magma pool disk inside the crater floor (Y = 17.0m)
	var lava_mesh := CylinderMesh.new()
	lava_mesh.top_radius = 16.2
	lava_mesh.bottom_radius = 16.2
	lava_mesh.height = 0.4
	var mi := MeshInstance3D.new()
	mi.mesh = lava_mesh
	mi.material_override = lava_mat
	mi.position = CRATER_POS
	caldera_holder.add_child(mi)

	# Dynamic flickering volcanic illumination
	_magma_light = OmniLight3D.new()
	_magma_light.light_color = Color(1.0, 0.42, 0.12)
	_magma_light.light_energy = 4.8
	_magma_light.omni_range = 45.0
	_magma_light.position = CRATER_POS + Vector3(0.0, 3.5, 0.0)
	caldera_holder.add_child(_magma_light)

	# Obsidian Boss Altar Platform in the center of the magma
	var stone_dark := StandardMaterial3D.new()
	stone_dark.albedo_color = Color(0.12, 0.10, 0.11)
	stone_dark.roughness = 0.85

	var altar_body := StaticBody3D.new()
	altar_body.position = ALTAR_POS
	var a_mesh := MeshInstance3D.new()
	var a_cyl := CylinderMesh.new()
	a_cyl.top_radius = 6.8
	a_cyl.bottom_radius = 7.4
	a_cyl.height = 1.4
	a_mesh.mesh = a_cyl
	a_mesh.material_override = stone_dark
	altar_body.add_child(a_mesh)
	var a_col := CollisionShape3D.new()
	var ac_cyl := CylinderShape3D.new()
	ac_cyl.radius = 7.0
	ac_cyl.height = 1.4
	a_col.shape = ac_cyl
	altar_body.add_child(a_col)
	caldera_holder.add_child(altar_body)

	# Arched Stone Bridge across the magma: connecting north crater rim to altar
	var bridge_body := StaticBody3D.new()
	bridge_body.position = ISLAND_CENTER + Vector3(0.0, 21.5, -11.5)
	bridge_body.rotation_degrees.x = -17.0
	var b_mesh := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(4.0, 0.6, 14.5)
	b_mesh.mesh = b_box
	b_mesh.material_override = stone_dark
	bridge_body.add_child(b_mesh)
	var b_col := CollisionShape3D.new()
	var bc_box := BoxShape3D.new()
	bc_box.size = b_box.size
	b_col.shape = bc_box
	bridge_body.add_child(b_col)
	caldera_holder.add_child(bridge_body)


# =========================================================================
# 4. MOUNTAIN TRAILS & ASCENDING PATHWAYS
# =========================================================================
func _build_mountain_trails() -> void:
	var trail_holder := Node3D.new()
	trail_holder.name = "MountainTrails"
	add_child(trail_holder)

	var stone_trail_mat := StandardMaterial3D.new()
	stone_trail_mat.albedo_color = Color(0.48, 0.44, 0.38)
	stone_trail_mat.roughness = 0.95

	# Continuous walking ramp from dock gate terrace (Z=408, Y=2.6) up to Lower Camp (Z=445, Y=6.8)
	_build_ramp(DOCK_GATE_POS, LOWER_CAMP_POS, 4.2, stone_trail_mat, trail_holder)

	# Ramp from Lower Camp (Z=445, Y=6.8) past Lake Pass (Z=490, Y=9.4) to Eastern Lookout (Z=480, Y=14.5)
	_build_ramp(LOWER_CAMP_POS, LAKE_CAMP_POS, 4.0, stone_trail_mat, trail_holder)
	_build_ramp(LAKE_CAMP_POS, LOOKOUT_POS, 3.8, stone_trail_mat, trail_holder)

	# Steep final volcanic staircase from Lookout (Y=14.5) up to North Crater Rim (Z=501, Y=25.5)
	var rim_pos := ISLAND_CENTER + Vector3(0.0, 25.5, -19.0)
	_build_ramp(LOOKOUT_POS, rim_pos, 3.8, stone_trail_mat, trail_holder)


func _build_ramp(p1: Vector3, p2: Vector3, width: float, mat: Material, parent: Node) -> void:
	var body := StaticBody3D.new()
	var mid := (p1 + p2) * 0.5
	var diff := p2 - p1
	var length := diff.length()
	body.position = mid
	if length > 0.001:
		body.basis = Basis.looking_at(diff.normalized(), Vector3.UP)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.4, length)
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = box.size
	col.shape = col_box
	body.add_child(col)

	parent.add_child(body)


# =========================================================================
# 5. PIRATE COVE & EXTENDED WOODEN PIER
# =========================================================================
func _build_pirate_cove_and_dock() -> void:
	var cove_holder := Node3D.new()
	cove_holder.name = "PirateCove"
	add_child(cove_holder)

	var wood_deck := StandardMaterial3D.new()
	wood_deck.albedo_color = Color(0.42, 0.28, 0.16)
	wood_deck.roughness = 0.85

	# Long wooden landing pier (Length: 36m, Width: 4.2m)
	var pier_body := StaticBody3D.new()
	pier_body.position = DOCK_POS + Vector3(0.0, 0.35, 12.0)
	var p_mesh := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(4.2, 0.35, 36.0)
	p_mesh.mesh = p_box
	p_mesh.material_override = wood_deck
	pier_body.add_child(p_mesh)

	var p_col := CollisionShape3D.new()
	var pc_box := BoxShape3D.new()
	pc_box.size = p_box.size
	p_col.shape = pc_box
	pier_body.add_child(p_col)
	cove_holder.add_child(pier_body)

	# Crosshead T-platform at the seaward head of the dock
	var head_body := StaticBody3D.new()
	head_body.position = DOCK_POS + Vector3(0.0, 0.35, -6.0)
	var h_mesh := MeshInstance3D.new()
	var h_box := BoxMesh.new()
	h_box.size = Vector3(10.5, 0.35, 5.5)
	h_mesh.mesh = h_box
	h_mesh.material_override = wood_deck
	head_body.add_child(h_mesh)

	var h_col := CollisionShape3D.new()
	var hc_box := BoxShape3D.new()
	hc_box.size = h_box.size
	h_col.shape = hc_box
	head_body.add_child(h_col)
	cove_holder.add_child(head_body)

	# Pier pilings driven into the seabed
	var pile_mat := StandardMaterial3D.new()
	pile_mat.albedo_color = Color(0.24, 0.15, 0.08)
	for z_off in range(-6, 32, 6):
		for x_off in [-2.0, 2.0]:
			var pile := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.2
			pc.bottom_radius = 0.2
			pc.height = 4.5
			pile.mesh = pc
			pile.position = DOCK_POS + Vector3(x_off, -1.2, float(z_off))
			pile.material_override = pile_mat
			cove_holder.add_child(pile)

	# Skull poles & maritime lanterns at the pier entrance
	_place_prop("res://assets/graveyard/post_skull.gltf", DOCK_POS + Vector3(-2.6, 0.5, 2.0), 30.0, 1.4, cove_holder)
	_place_prop("res://assets/graveyard/post_skull.gltf", DOCK_POS + Vector3(2.6, 0.5, 2.0), -30.0, 1.4, cove_holder)
	_place_prop("res://assets/graveyard/post_lantern.gltf", DOCK_POS + Vector3(-2.6, 0.5, -4.0), 90.0, 1.3, cove_holder)
	_place_prop("res://assets/graveyard/post_lantern.gltf", DOCK_POS + Vector3(2.6, 0.5, -4.0), -90.0, 1.3, cove_holder)

	# Welcome sign on the dry sand path
	_add_signpost("Νησί των Πειρατών  🏴‍☠️\nΌρμος των Κουρσάρων", DOCK_GATE_POS + Vector3(3.2, 0.0, -2.5), -25.0, cove_holder)


# =========================================================================
# 6. DENSE FOREST GROVES & ISLAND FLORA
# =========================================================================
func _build_forest_groves() -> void:
	var forest_holder := Node3D.new()
	forest_holder.name = "IslandForest"
	add_child(forest_holder)

	var tree_models: Array[String] = [
		"res://assets/world/decoration/nature/trees_A_large.gltf",
		"res://assets/world/decoration/nature/trees_A_medium.gltf",
		"res://assets/world/decoration/nature/trees_B_large.gltf",
		"res://assets/world/decoration/nature/trees_B_medium.gltf",
		"res://assets/world/decoration/nature/tree_single_A.gltf",
		"res://assets/world/decoration/nature/tree_single_B.gltf",
	]

	# Scatter 65 trees across the lush green hills and lake valleys (radius 48m to 120m)
	var tree_offsets: Array[Vector2] = []
	for i in 65:
		var angle := (float(i) / 65.0) * TAU + randf_range(-0.08, 0.08)
		var dist := randf_range(52.0, 118.0)
		var lx := cos(angle) * dist
		var lz := sin(angle) * dist

		# Don't place trees in the lake center
		var lake_d := sqrt((lx + 55.0) * (lx + 55.0) + lz * lz)
		if lake_d < 24.0:
			continue
		# Don't place trees in the north cove trail
		if lz < -80.0 and absf(lx) < 30.0:
			continue

		var ly := _calc_island_height(lx, lz)
		if ly > 2.5: # only on solid ground above sea
			var t_pos := ISLAND_CENTER + Vector3(lx, ly, lz)
			var m_path: String = tree_models[i % tree_models.size()]
			var sc := randf_range(1.1, 1.7)
			var t_inst := _place_prop(m_path, t_pos, randf() * 360.0, sc, forest_holder)
			if t_inst:
				_add_tree_collider(t_inst)


# =========================================================================
# 7. WILDLIFE: GRACEFUL ISLAND DEER
# =========================================================================
func _build_wildlife() -> void:
	var wildlife_holder := Node3D.new()
	wildlife_holder.name = "IslandWildlife"
	add_child(wildlife_holder)

	# 5 wild deer roaming the green valleys and drinking near the lake
	var deer_offsets: Array[Vector2] = [
		Vector2(-85.0, -25.0), # Western glade
		Vector2(-68.0, 28.0),  # Lake south bank
		Vector2(-48.0, -65.0), # Northern forest clearing
		Vector2(65.0, -35.0),  # Eastern green hillside
		Vector2(75.0, 42.0),   # Southeastern meadow
	]

	for off in deer_offsets:
		var deer := VillageDeer.new()
		var dy := _calc_island_height(off.x, off.y)
		deer.position = ISLAND_CENTER + Vector3(off.x, dy, off.y)
		deer.rotation.y = randf() * TAU
		wildlife_holder.add_child(deer)


# =========================================================================
# 8. PIRATE ENCAMPMENTS & OUTPOSTS
# =========================================================================
func _build_encampments() -> void:
	var camps_holder := Node3D.new()
	camps_holder.name = "PirateEncampments"
	add_child(camps_holder)

	# 1. Lower Hillside Camp at LOWER_CAMP_POS (Y = 6.8m)
	_place_prop("res://assets/world/decoration/props/tent.gltf", LOWER_CAMP_POS + Vector3(-4.5, 0.0, -1.0), 45.0, 1.4, camps_holder)
	_place_prop("res://assets/world/decoration/props/tent.gltf", LOWER_CAMP_POS + Vector3(3.5, 0.0, 2.5), -60.0, 1.3, camps_holder)
	_place_prop("res://assets/world/decoration/props/weaponrack.gltf", LOWER_CAMP_POS + Vector3(1.2, 0.0, -3.5), 10.0, 1.3, camps_holder)
	_place_prop("res://assets/items/barrel_large.gltf.glb", LOWER_CAMP_POS + Vector3(-2.2, 0.0, 3.5), 15.0, 1.2, camps_holder)
	_place_prop("res://assets/items/crates_stacked.gltf.glb", LOWER_CAMP_POS + Vector3(-3.2, 0.0, 2.8), -20.0, 1.2, camps_holder)

	var c1_light := OmniLight3D.new()
	c1_light.light_color = Color(1.0, 0.6, 0.2)
	c1_light.light_energy = 2.4
	c1_light.omni_range = 10.0
	c1_light.position = LOWER_CAMP_POS + Vector3(0.0, 0.8, 0.0)
	camps_holder.add_child(c1_light)

	# 2. Lake Valley Outpost at LAKE_CAMP_POS (Y = 9.4m)
	_place_prop("res://assets/world/decoration/props/tent.gltf", LAKE_CAMP_POS + Vector3(-3.0, 0.0, 2.0), -30.0, 1.3, camps_holder)
	_place_prop("res://assets/items/barrel_small.gltf.glb", LAKE_CAMP_POS + Vector3(2.5, 0.0, -1.5), 0.0, 1.2, camps_holder)
	_place_prop("res://assets/graveyard/post_skull.gltf", LAKE_CAMP_POS + Vector3(3.2, 0.0, 2.0), -45.0, 1.4, camps_holder)

	# 3. Eastern Artillery Lookout Tower at LOOKOUT_POS (Y = 14.5m)
	var tower := StaticBody3D.new()
	tower.position = LOOKOUT_POS
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.38, 0.25, 0.14)

	var t_mesh := MeshInstance3D.new()
	var t_box := BoxMesh.new()
	t_box.size = Vector3(6.5, 0.5, 6.5)
	t_mesh.mesh = t_box
	t_mesh.material_override = wood_mat
	tower.add_child(t_mesh)

	var t_col := CollisionShape3D.new()
	var tc_box := BoxShape3D.new()
	tc_box.size = t_box.size
	t_col.shape = tc_box
	tower.add_child(t_col)

	# 4 Heavy Support Posts
	for cx in [-2.8, 2.8]:
		for cz in [-2.8, 2.8]:
			var post := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.22
			cyl.bottom_radius = 0.25
			cyl.height = 4.5
			post.mesh = cyl
			post.position = Vector3(cx, -2.2, cz)
			post.material_override = wood_mat
			tower.add_child(post)

	camps_holder.add_child(tower)
	_place_prop("res://assets/items/crates_stacked.gltf.glb", LOOKOUT_POS + Vector3(-1.8, 0.5, -1.5), 15.0, 1.1, camps_holder)
	_place_prop("res://assets/items/barrel_large.gltf.glb", LOOKOUT_POS + Vector3(1.8, 0.5, 1.2), -30.0, 1.1, camps_holder)


# =========================================================================
# 9. SECRET SMUGGLER'S GROTTO & HIDDEN TREASURE
# =========================================================================
func _build_secret_treasure_grotto() -> void:
	var grotto_holder := Node3D.new()
	grotto_holder.name = "SecretSmugglersGrotto"
	add_child(grotto_holder)

	var grotto_pos := SECRET_CACHE_POS

	# Ring of massive mossy boulders concealing the alcove
	var rock_models: Array[String] = [
		"res://assets/world/decoration/nature/rock_single_E.gltf",
		"res://assets/world/decoration/nature/rock_single_C.gltf",
		"res://assets/world/decoration/nature/rock_single_D.gltf",
	]
	for i in 6:
		var rad := (float(i) / 6.0) * TAU
		if i == 0:
			continue # Leave a narrow entrance gap to walk inside!
		var rp := grotto_pos + Vector3(cos(rad) * 4.5, 0.0, sin(rad) * 4.5)
		var r_path: String = rock_models[i % rock_models.size()]
		_place_prop(r_path, rp, randf() * 360.0, randf_range(7.5, 10.5), grotto_holder)

	# Overhanging ancient tree
	_place_prop("res://assets/world/decoration/nature/trees_A_large.gltf", grotto_pos + Vector3(3.2, 0.0, -3.2), 40.0, 1.5, grotto_holder)

	# The Hidden Golden Pirate Treasure Cache
	var secret_chest := Chest.new()
	secret_chest.golden = true
	secret_chest.gold_min = 850
	secret_chest.gold_max = 1500
	secret_chest.potions = 5
	secret_chest.position = grotto_pos + Vector3(0.0, 0.2, 0.0)
	secret_chest.rotation_degrees.y = -35.0
	grotto_holder.add_child(secret_chest)

	# Coin Stacks & Booty Crates
	_place_prop("res://assets/items/coin_stack_medium.gltf.glb", grotto_pos + Vector3(1.4, 0.2, -0.6), 25.0, 1.3, grotto_holder)
	_place_prop("res://assets/items/coin_stack_small.gltf.glb", grotto_pos + Vector3(-1.2, 0.2, 0.8), -40.0, 1.2, grotto_holder)
	_place_prop("res://assets/items/crates_stacked.gltf.glb", grotto_pos + Vector3(-1.8, 0.2, -1.2), 15.0, 1.1, grotto_holder)
	_place_prop("res://assets/items/barrel_large.gltf.glb", grotto_pos + Vector3(1.8, 0.2, 1.2), -20.0, 1.1, grotto_holder)

	# Emerald Mystic Glow
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.2, 0.95, 0.65)
	glow.light_energy = 2.8
	glow.omni_range = 12.0
	glow.position = grotto_pos + Vector3(0.0, 1.8, 0.0)
	grotto_holder.add_child(glow)

	# Inscribed Ancient Stone Slab
	_add_signpost("Κρυφή Κρύπτη του Μαυροδόντη  💎\nΜυστικός Θησαυρός των Επτά Θαλασσών", grotto_pos + Vector3(0.0, 0.2, 2.6), 180.0, grotto_holder)


# =========================================================================
# 10. CRATER ARENA, BOSS & CURSED CHEST
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
	chest.position = ALTAR_POS + Vector3(0.0, 0.7, 2.2)
	chest.rotation_degrees.y = 180.0
	arena_holder.add_child(chest)

	# Pedestal skull guardians around the treasure
	_place_prop("res://assets/graveyard/post_skull.gltf", ALTAR_POS + Vector3(-2.8, 0.7, 2.2), 45.0, 1.3, arena_holder)
	_place_prop("res://assets/graveyard/post_skull.gltf", ALTAR_POS + Vector3(2.8, 0.7, 2.2), -45.0, 1.3, arena_holder)


func _spawn_pirate_enemies() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner != null and spawner.has_method("spawn_extra"):
		# 1. Captain Dread in the Caldera Altar (SOLID GROUND, Y = 18.2m)
		spawner.spawn_extra("pirate_captain", ALTAR_POS + Vector3(0.0, 0.7, -1.0))

		# 2. Dock Security Outpost guards (SOLID DRY GROUND, Y = 2.6m, Z = 408)
		spawner.spawn_extra("pirate_corsair", DOCK_GATE_POS + Vector3(-2.5, 0.2, 0.0))
		spawner.spawn_extra("pirate_corsair", DOCK_GATE_POS + Vector3(2.5, 0.2, 0.0))

		# 3. Lower Outpost camp guards (SOLID HIGH HILLSIDE, Y = 6.8m, Z = 445)
		spawner.spawn_extra("pirate_corsair", LOWER_CAMP_POS + Vector3(-2.0, 0.2, -1.5))
		spawner.spawn_extra("pirate_corsair", LOWER_CAMP_POS + Vector3(2.5, 0.2, 1.0))

		# 4. Lake valley pass guards (SOLID DRY TRAIL, Y = 9.4m, Z = 490)
		spawner.spawn_extra("pirate_corsair", LAKE_CAMP_POS + Vector3(-1.5, 0.2, 0.0))
		spawner.spawn_extra("pirate_corsair", LAKE_CAMP_POS + Vector3(2.0, 0.2, 1.5))

		# 5. Artillery Lookout tower guards (SOLID HIGH BLUFF, Y = 14.5m, Z = 480)
		spawner.spawn_extra("pirate_corsair", LOOKOUT_POS + Vector3(0.0, 0.6, 0.0))
		spawner.spawn_extra("pirate_corsair", LOOKOUT_POS + Vector3(3.5, 0.1, 2.0))


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


func _add_tree_collider(root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.45
	cyl.height = 3.5
	col.shape = cyl
	col.position.y = 1.75
	body.add_child(col)
	root.add_child(body)


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
