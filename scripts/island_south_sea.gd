class_name IslandSouthSea
extends Node3D
## The South Sea Coast of Agios Vlasis:
## Expansive open ocean, golden sandy beach, cliffside stone lighthouse with rotating beacon,
## wooden fishing pier with boats, and a sunken shipwreck with treasure.

const COAST_CENTER := Vector3(-45.0, 0.0, 140.0)
const LIGHTHOUSE_POS := Vector3(-115.0, 0.0, 138.0)
const PIER_POS := Vector3(-35.0, 0.0, 126.0)
const SHIPWRECK_POS := Vector3(-72.0, 0.0, 168.0)

var _beacon_light: SpotLight3D
var _beacon_beam: MeshInstance3D
var _beacon_yaw := 0.0


func _ready() -> void:
	name = "SouthSeaCoast"
	_build_ocean()
	_build_beach()
	_build_lighthouse()
	_build_pier()
	_build_shipwreck()


func _process(delta: float) -> void:
	# Rotate lighthouse beacon light smoothly 360 degrees
	if _beacon_light:
		_beacon_yaw += delta * 0.75
		_beacon_light.rotation.y = _beacon_yaw
		if _beacon_beam:
			_beacon_beam.rotation.y = _beacon_yaw


# =========================================================================
# 1. OCEAN & SEABED
# =========================================================================
func _build_ocean() -> void:
	var ocean_holder := Node3D.new()
	ocean_holder.name = "Ocean"
	add_child(ocean_holder)

	# Water material with ocean shader
	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water.gdshader") as Shader
	water_mat.set_shader_parameter("deep_color", Color(0.04, 0.18, 0.36))
	water_mat.set_shader_parameter("shallow_color", Color(0.16, 0.62, 0.68))
	water_mat.set_shader_parameter("sky_color", Color(0.72, 0.88, 1.0))

	# Vast sea plane
	var sea_mesh := PlaneMesh.new()
	sea_mesh.size = Vector2(700.0, 450.0)
	var sea := MeshInstance3D.new()
	sea.mesh = sea_mesh
	sea.material_override = water_mat
	sea.position = Vector3(0.0, 0.02, 310.0)
	ocean_holder.add_child(sea)

	# Sandy seabed underneath
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.74, 0.65, 0.44)
	sand_mat.roughness = 0.95

	var seabed_mesh := PlaneMesh.new()
	seabed_mesh.size = Vector2(700.0, 450.0)
	var seabed := MeshInstance3D.new()
	seabed.mesh = seabed_mesh
	seabed.material_override = sand_mat
	seabed.position = Vector3(0.0, -1.8, 310.0)
	ocean_holder.add_child(seabed)

	# Ocean boundary barrier so player can wade in shallows but not walk to infinity
	var barrier := StaticBody3D.new()
	barrier.position = Vector3(0.0, 5.0, 260.0)
	var b_shape := CollisionShape3D.new()
	var b_box := BoxShape3D.new()
	b_box.size = Vector3(800.0, 20.0, 6.0)
	b_shape.shape = b_box
	barrier.add_child(b_shape)
	ocean_holder.add_child(barrier)


# =========================================================================
# 2. SANDY BEACH & DUNES
# =========================================================================
func _build_beach() -> void:
	var beach_holder := Node3D.new()
	beach_holder.name = "Beach"
	add_child(beach_holder)

	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.86, 0.77, 0.52)   # warm Mediterranean golden sand
	sand_mat.roughness = 0.92

	# Main sandy shore terrace sloping from Z=95 (meadow border) to Z=135 (waterline)
	var beach_segments: Array[Dictionary] = [
		{"pos": Vector3(-45.0, -0.05, 108.0), "size": Vector3(175.0, 0.25, 26.0), "rot_x": 0.0},
		{"pos": Vector3(-45.0, -0.45, 126.0), "size": Vector3(185.0, 0.35, 22.0), "rot_x": -2.5},
		{"pos": Vector3(-45.0, -0.95, 142.0), "size": Vector3(195.0, 0.45, 24.0), "rot_x": -3.5},
	]

	for seg in beach_segments:
		var node := Node3D.new()
		node.position = seg["pos"]
		node.rotation_degrees.x = seg["rot_x"]
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = seg["size"]
		mi.mesh = bm
		mi.material_override = sand_mat
		node.add_child(mi)

		var sb := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = seg["size"]
		col.shape = bs
		sb.add_child(col)
		node.add_child(sb)
		beach_holder.add_child(node)

	# Scattered beach rocks and driftwood
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.52, 0.50, 0.46)
	rock_mat.roughness = 0.85

	var beach_rocks: Array[Vector3] = [
		Vector3(-12.0, 0.2, 116.0), Vector3(18.0, 0.1, 122.0), Vector3(-68.0, 0.15, 128.0),
		Vector3(32.0, 0.1, 134.0), Vector3(-88.0, 0.3, 120.0), Vector3(-2.0, 0.05, 132.0),
	]
	for r_pos in beach_rocks:
		var r_node := Node3D.new()
		r_node.position = r_pos
		var r_mesh := MeshInstance3D.new()
		var r_cyl := CylinderMesh.new()
		r_cyl.top_radius = 0.65 + randf() * 0.5
		r_cyl.bottom_radius = 0.95 + randf() * 0.6
		r_cyl.height = 0.7 + randf() * 0.4
		r_mesh.mesh = r_cyl
		r_mesh.material_override = rock_mat
		r_node.add_child(r_mesh)
		var sb := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = r_cyl.bottom_radius
		cs.height = r_cyl.height
		col.shape = cs
		sb.add_child(col)
		r_node.add_child(sb)
		beach_holder.add_child(r_node)


# =========================================================================
# 3. CLIFFSIDE STONE LIGHTHOUSE & ROTATING BEACON
# =========================================================================
func _build_lighthouse() -> void:
	var lh_holder := Node3D.new()
	lh_holder.name = "Lighthouse"
	add_child(lh_holder)

	var cliff_mat := StandardMaterial3D.new()
	cliff_mat.albedo_color = Color(0.42, 0.40, 0.37)
	cliff_mat.roughness = 0.9

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.78, 0.76, 0.70)   # white limestone tower
	stone_mat.roughness = 0.7

	var red_mat := StandardMaterial3D.new()
	red_mat.albedo_color = Color(0.75, 0.18, 0.15)    # maritime crimson stripes
	red_mat.roughness = 0.6

	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.18, 0.18, 0.20)
	iron_mat.metallic = 0.8
	iron_mat.roughness = 0.3

	var copper_mat := StandardMaterial3D.new()
	copper_mat.albedo_color = Color(0.24, 0.54, 0.44)  # verdigris copper dome
	copper_mat.metallic = 0.5
	copper_mat.roughness = 0.4

	# 1. High Rock Promontory / Cliff Base (Y = 0 to 5.2m)
	var cliff := StaticBody3D.new()
	cliff.position = LIGHTHOUSE_POS + Vector3(0.0, 2.6, 0.0)
	var cliff_mesh := MeshInstance3D.new()
	var c_cyl := CylinderMesh.new()
	c_cyl.top_radius = 7.5
	c_cyl.bottom_radius = 9.5
	c_cyl.height = 5.2
	cliff_mesh.mesh = c_cyl
	cliff_mesh.material_override = cliff_mat
	cliff.add_child(cliff_mesh)
	var c_col := CollisionShape3D.new()
	var c_shape := CylinderShape3D.new()
	c_shape.radius = 8.5
	c_shape.height = 5.2
	c_col.shape = c_shape
	cliff.add_child(c_col)
	lh_holder.add_child(cliff)

	# 2. Winding Stone Staircase from beach up to cliff top
	var stair_steps := 12
	for i in stair_steps:
		var frac := float(i) / stair_steps
		var s_angle := lerpf(PI * 0.4, -PI * 0.15, frac)
		var s_r := lerpf(9.8, 7.8, frac)
		var s_y := lerpf(0.2, 5.2, frac)
		var s_pos := LIGHTHOUSE_POS + Vector3(cos(s_angle) * s_r, s_y, sin(s_angle) * s_r)

		var step := StaticBody3D.new()
		step.position = s_pos
		step.rotation.y = s_angle + PI * 0.5
		var s_mesh := MeshInstance3D.new()
		var s_box := BoxMesh.new()
		s_box.size = Vector3(2.4, 0.35, 1.2)
		s_mesh.mesh = s_box
		s_mesh.material_override = stone_mat
		step.add_child(s_mesh)
		var s_col := CollisionShape3D.new()
		var sb_box := BoxShape3D.new()
		sb_box.size = Vector3(2.4, 0.35, 1.2)
		s_col.shape = sb_box
		step.add_child(s_col)
		lh_holder.add_child(step)

	# 3. Main Lighthouse Tower (3 Tapered Cylinders from Y = 5.2 to Y = 20.0m)
	var tower_base_y := 5.2
	var tier_height := 4.6

	# Tier 1: White stone base
	var t1 := StaticBody3D.new()
	t1.position = LIGHTHOUSE_POS + Vector3(0.0, tower_base_y + tier_height * 0.5, 0.0)
	var t1_mesh := MeshInstance3D.new()
	var c1 := CylinderMesh.new()
	c1.bottom_radius = 4.2
	c1.top_radius = 3.6
	c1.height = tier_height
	t1_mesh.mesh = c1
	t1_mesh.material_override = stone_mat
	t1.add_child(t1_mesh)
	var t1_col := CollisionShape3D.new()
	var cs1 := CylinderShape3D.new()
	cs1.radius = 3.9
	cs1.height = tier_height
	t1_col.shape = cs1
	t1.add_child(t1_col)
	lh_holder.add_child(t1)

	# Tier 2: Red stripe
	var t2 := StaticBody3D.new()
	t2.position = LIGHTHOUSE_POS + Vector3(0.0, tower_base_y + tier_height * 1.5, 0.0)
	var t2_mesh := MeshInstance3D.new()
	var c2 := CylinderMesh.new()
	c2.bottom_radius = 3.6
	c2.top_radius = 3.1
	c2.height = tier_height
	t2_mesh.mesh = c2
	t2_mesh.material_override = red_mat
	t2.add_child(t2_mesh)
	var t2_col := CollisionShape3D.new()
	var cs2 := CylinderShape3D.new()
	cs2.radius = 3.35
	cs2.height = tier_height
	t2_col.shape = cs2
	t2.add_child(t2_col)
	lh_holder.add_child(t2)

	# Tier 3: White stone upper tower
	var t3 := StaticBody3D.new()
	t3.position = LIGHTHOUSE_POS + Vector3(0.0, tower_base_y + tier_height * 2.5, 0.0)
	var t3_mesh := MeshInstance3D.new()
	var c3 := CylinderMesh.new()
	c3.bottom_radius = 3.1
	c3.top_radius = 2.7
	c3.height = tier_height
	t3_mesh.mesh = c3
	t3_mesh.material_override = stone_mat
	t3.add_child(t3_mesh)
	var t3_col := CollisionShape3D.new()
	var cs3 := CylinderShape3D.new()
	cs3.radius = 2.9
	cs3.height = tier_height
	t3_col.shape = cs3
	t3.add_child(t3_col)
	lh_holder.add_child(t3)

	# 4. Observation Balcony & Gallery Deck (Y = 19.0m)
	var balc_y := tower_base_y + tier_height * 3.0
	var balc := StaticBody3D.new()
	balc.position = LIGHTHOUSE_POS + Vector3(0.0, balc_y + 0.2, 0.0)
	var b_mesh := MeshInstance3D.new()
	var b_cyl := CylinderMesh.new()
	b_cyl.top_radius = 3.6
	b_cyl.bottom_radius = 3.6
	b_cyl.height = 0.4
	b_mesh.mesh = b_cyl
	b_mesh.material_override = stone_mat
	balc.add_child(b_mesh)
	var b_col := CollisionShape3D.new()
	var bc_shape := CylinderShape3D.new()
	bc_shape.radius = 3.6
	bc_shape.height = 0.4
	b_col.shape = bc_shape
	balc.add_child(b_col)
	lh_holder.add_child(balc)

	# Balcony Iron Railing
	for a in range(0, 360, 45):
		var rad := deg_to_rad(float(a))
		var rp := LIGHTHOUSE_POS + Vector3(cos(rad) * 3.4, balc_y + 0.9, sin(rad) * 3.4)
		var post := MeshInstance3D.new()
		var pc := CylinderMesh.new()
		pc.top_radius = 0.06
		pc.bottom_radius = 0.06
		pc.height = 1.0
		post.mesh = pc
		post.position = rp
		post.material_override = iron_mat
		lh_holder.add_child(post)

	# 5. Glass Lantern Room & Copper Dome Roof (Y = 19.4m to 23.5m)
	var lantern_room := Node3D.new()
	lantern_room.position = LIGHTHOUSE_POS + Vector3(0.0, balc_y + 1.6, 0.0)

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.35)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	glass_mat.metallic = 0.1

	var g_mesh := MeshInstance3D.new()
	var g_cyl := CylinderMesh.new()
	g_cyl.top_radius = 2.4
	g_cyl.bottom_radius = 2.4
	g_cyl.height = 2.4
	g_mesh.mesh = g_cyl
	g_mesh.material_override = glass_mat
	lantern_room.add_child(g_mesh)

	# Copper Dome
	var dome := MeshInstance3D.new()
	var d_cyl := CylinderMesh.new()
	d_cyl.top_radius = 0.2
	d_cyl.bottom_radius = 2.7
	d_cyl.height = 1.6
	dome.mesh = d_cyl
	dome.position = Vector3(0.0, 1.8, 0.0)
	dome.material_override = copper_mat
	lantern_room.add_child(dome)

	# 6. Rotating Beacon Light Source & Radiant Beam
	_beacon_light = SpotLight3D.new()
	_beacon_light.light_color = Color(1.0, 0.92, 0.65)
	_beacon_light.light_energy = 8.5
	_beacon_light.spot_range = 140.0
	_beacon_light.spot_angle = 32.0
	_beacon_light.spot_attenuation = 0.8
	_beacon_light.position = Vector3(0.0, 0.2, 0.0)
	lantern_room.add_child(_beacon_light)

	# Static omni glow inside the glass
	var inner_glow := OmniLight3D.new()
	inner_glow.light_color = Color(1.0, 0.90, 0.60)
	inner_glow.light_energy = 3.0
	inner_glow.omni_range = 18.0
	lantern_room.add_child(inner_glow)

	lh_holder.add_child(lantern_room)

	# 7. Lighthouse Keeper's Golden Chest on cliff overlook
	var chest = Chest.new()
	chest.golden = true
	chest.gold_min = 250
	chest.gold_max = 450
	chest.potions = 2
	chest.position = LIGHTHOUSE_POS + Vector3(3.5, 5.4, 2.5)
	chest.rotation_degrees.y = 135.0
	lh_holder.add_child(chest)

	# Signpost at cliff base
	_add_signpost("Φάρος του Ακρωτηρίου  ↑\nΠροσοχή στα Βράχια!", LIGHTHOUSE_POS + Vector3(8.5, 0.1, -2.0), -60.0, lh_holder)


# =========================================================================
# 4. WOODEN FISHING PIER & HARBOR
# =========================================================================
func _build_pier() -> void:
	var pier_holder := Node3D.new()
	pier_holder.name = "FishingPier"
	add_child(pier_holder)

	var wood_deck := StandardMaterial3D.new()
	wood_deck.albedo_color = Color(0.48, 0.33, 0.18)
	wood_deck.roughness = 0.85

	var piling_mat := StandardMaterial3D.new()
	piling_mat.albedo_color = Color(0.28, 0.18, 0.10)
	piling_mat.roughness = 0.9

	# Main boardwalk extending south into the sea (Length: 22m, Width: 3.4m)
	var pier_len := 22.0
	var pier_w := 3.4
	var pier_deck := StaticBody3D.new()
	pier_deck.position = PIER_POS + Vector3(0.0, 0.55, pier_len * 0.5)

	var d_mesh := MeshInstance3D.new()
	var d_box := BoxMesh.new()
	d_box.size = Vector3(pier_w, 0.28, pier_len)
	d_mesh.mesh = d_box
	d_mesh.material_override = wood_deck
	pier_deck.add_child(d_mesh)

	var d_col := CollisionShape3D.new()
	var dc_box := BoxShape3D.new()
	dc_box.size = Vector3(pier_w, 0.28, pier_len)
	d_col.shape = dc_box
	pier_deck.add_child(d_col)
	pier_holder.add_child(pier_deck)

	# Crosshead T-platform at the end of the pier (Width: 8.0m, Depth: 4.2m)
	var t_deck := StaticBody3D.new()
	t_deck.position = PIER_POS + Vector3(0.0, 0.55, pier_len + 1.8)
	var t_mesh := MeshInstance3D.new()
	var t_box := BoxMesh.new()
	t_box.size = Vector3(8.0, 0.28, 4.2)
	t_mesh.mesh = t_box
	t_mesh.material_override = wood_deck
	t_deck.add_child(t_mesh)
	var t_col := CollisionShape3D.new()
	var tc_box := BoxShape3D.new()
	tc_box.size = Vector3(8.0, 0.28, 4.2)
	t_col.shape = tc_box
	t_deck.add_child(t_col)
	pier_holder.add_child(t_deck)

	# Timber Pilings driven into seabed
	for z_off in range(3, int(pier_len) + 4, 4):
		for x_off: float in [-pier_w * 0.45, pier_w * 0.45]:
			var pile := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.16
			pc.bottom_radius = 0.18
			pc.height = 3.6
			pile.mesh = pc
			pile.position = PIER_POS + Vector3(x_off, -0.6, float(z_off))
			pile.material_override = piling_mat
			pier_holder.add_child(pile)

	# Pier Lanterns on wooden posts
	var lantern_zs: Array[float] = [6.0, pier_len + 1.5]
	for lz: float in lantern_zs:
		var lp: Vector3 = PIER_POS + Vector3(-pier_w * 0.45 - 0.2, 0.6, lz)
		var _lantern_post = _place_prop("res://assets/graveyard/post_lantern.gltf", lp, 90.0, 1.2, pier_holder)

	# Moored Wooden Boat beside the pier
	var boat := Node3D.new()
	boat.position = PIER_POS + Vector3(2.8, -0.15, 12.0)
	boat.rotation_degrees = Vector3(3.0, -10.0, -4.0)
	var b_hull := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(1.8, 0.8, 4.5)
	b_hull.mesh = b_box
	b_hull.material_override = piling_mat
	boat.add_child(b_hull)
	pier_holder.add_child(boat)

	# Fishing spot interaction sign on pier head
	_add_signpost("Ψαρολίμανο Αγίου Βλάση  ⚓\nΑποβάθρα Ψαρέματος", PIER_POS + Vector3(2.4, 0.65, 1.5), 180.0, pier_holder)


# =========================================================================
# 5. SUNKEN SHIPWRECK & TREASURE
# =========================================================================
func _build_shipwreck() -> void:
	var wreck_holder := Node3D.new()
	wreck_holder.name = "Shipwreck"
	add_child(wreck_holder)

	var wood_old := StandardMaterial3D.new()
	wood_old.albedo_color = Color(0.24, 0.20, 0.16)   # waterlogged weathered oak
	wood_old.roughness = 0.95

	# Ship Hull listing 22 degrees in the azure bay
	var hull := StaticBody3D.new()
	hull.position = SHIPWRECK_POS
	hull.rotation_degrees = Vector3(12.0, 35.0, -22.0)

	var h_mesh := MeshInstance3D.new()
	var h_box := BoxMesh.new()
	h_box.size = Vector3(4.8, 3.2, 12.5)
	h_mesh.mesh = h_box
	h_mesh.material_override = wood_old
	hull.add_child(h_mesh)

	var h_col := CollisionShape3D.new()
	var hc_box := BoxShape3D.new()
	hc_box.size = Vector3(4.8, 3.2, 12.5)
	h_col.shape = hc_box
	hull.add_child(h_col)
	wreck_holder.add_child(hull)

	# Broken Mainmast jutting out of water
	var mast := MeshInstance3D.new()
	var m_cyl := CylinderMesh.new()
	m_cyl.top_radius = 0.18
	m_cyl.bottom_radius = 0.28
	m_cyl.height = 7.5
	mast.mesh = m_cyl
	mast.position = SHIPWRECK_POS + Vector3(0.8, 2.8, -1.0)
	mast.rotation_degrees = Vector3(25.0, 15.0, -35.0)
	mast.material_override = wood_old
	wreck_holder.add_child(mast)

	# Sunken Treasure Chest resting on the tilted deck!
	var wreck_chest = Chest.new()
	wreck_chest.golden = true
	wreck_chest.gold_min = 350
	wreck_chest.gold_max = 600
	wreck_chest.potions = 3
	wreck_chest.position = SHIPWRECK_POS + Vector3(0.5, 0.8, 1.2)
	wreck_chest.rotation_degrees.y = 45.0
	wreck_holder.add_child(wreck_chest)


# --- Helper Methods ---
func _place_prop(path: String, pos: Vector3, rot_deg: float, sc: float, parent: Node) -> Node3D:
	var res := load(path) as PackedScene
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
	var post_mesh := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(0.18, 1.5, 0.18)
	post_mesh.mesh = p_box
	post_mesh.position = Vector3(0.0, 0.75, 0.0)
	post_mesh.material_override = post_mat
	sign_node.add_child(post_mesh)

	var board := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(1.4, 0.55, 0.1)
	board.mesh = b_box
	board.position = Vector3(0.0, 1.25, 0.0)
	board.material_override = post_mat
	sign_node.add_child(board)

	var label := Label3D.new()
	label.text = text
	label.font_size = 32
	label.outline_size = 8
	label.position = Vector3(0.0, 1.25, 0.06)
	sign_node.add_child(label)
	parent.add_child(sign_node)
