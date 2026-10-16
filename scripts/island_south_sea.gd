class_name IslandSouthSea
extends Node3D
## The South Sea Coast of Agios Vlasis:
## Expansive open ocean, smooth golden sandy crescent bay, cliffside stone lighthouse with rotating beacon,
## wooden fishing pier with boats, and a sunken shipwreck with treasure.

const COAST_CENTER := Vector3(-55.0, 0.0, 135.0)
const LIGHTHOUSE_POS := Vector3(-115.0, 0.0, 138.0)
const PIER_POS := Vector3(-35.0, 0.0, 96.0)
const SHIPWRECK_POS := Vector3(-72.0, -0.6, 168.0)

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
	_build_southeast_cliffs()


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

	# 1. South Sea Bay Water: Strictly confined inside the bay opening (X in [-165, 55], Z in [106, 220]).
	# Placed at Y = -0.01 so water is just below the dry shore/meadow (Y = 0.0), completely preventing z-fighting.
	# It CANNOT enter the south-east forest (X > 55) or mountain (X < -165).
	var bay_sea_mesh := PlaneMesh.new()
	bay_sea_mesh.size = Vector2(220.0, 114.0)
	var bay_sea := MeshInstance3D.new()
	bay_sea.mesh = bay_sea_mesh
	bay_sea.material_override = water_mat
	bay_sea.position = Vector3(-55.0, -0.01, 163.0)
	ocean_holder.add_child(bay_sea)

	# 2. Open South Ocean Water: Extends across the southern horizon for Z >= 220.0.
	# At Z >= 220.0, all island terrain is discarded by ground.gdshader, so water spreads wide to infinity with zero overlap.
	var open_sea_mesh := PlaneMesh.new()
	open_sea_mesh.size = Vector2(900.0, 500.0)
	var open_sea := MeshInstance3D.new()
	open_sea.mesh = open_sea_mesh
	open_sea.material_override = water_mat
	open_sea.position = Vector3(0.0, -0.01, 470.0)
	ocean_holder.add_child(open_sea)

	# Continuous Sandy Seabed underneath the open ocean floor
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.70, 0.61, 0.42)   # Mediterranean marine sand
	sand_mat.roughness = 0.95

	# Bay seabed under the water
	var bay_seabed_mesh := PlaneMesh.new()
	bay_seabed_mesh.size = Vector2(220.0, 64.0)
	var bay_seabed := MeshInstance3D.new()
	bay_seabed.mesh = bay_seabed_mesh
	bay_seabed.material_override = sand_mat
	bay_seabed.position = Vector3(-55.0, -1.8, 190.0)
	ocean_holder.add_child(bay_seabed)

	# Open ocean seabed
	var open_seabed_mesh := PlaneMesh.new()
	open_seabed_mesh.size = Vector2(900.0, 500.0)
	var open_seabed := MeshInstance3D.new()
	open_seabed.mesh = open_seabed_mesh
	open_seabed.material_override = sand_mat
	open_seabed.position = Vector3(0.0, -1.8, 470.0)
	ocean_holder.add_child(open_seabed)

	# Solid seabed floor collider for the deep ocean
	var floor_body := StaticBody3D.new()
	# Bay deep floor (Z in [160, 225], X in [-165, 55])
	var f_shape_bay := CollisionShape3D.new()
	var f_box_bay := BoxShape3D.new()
	f_box_bay.size = Vector3(220.0, 2.0, 65.0)
	f_shape_bay.shape = f_box_bay
	f_shape_bay.position = Vector3(-55.0, -2.8, 192.5)
	floor_body.add_child(f_shape_bay)
	# Open ocean floor (Z in [220, 720], X in [-450, 450])
	var f_shape_open := CollisionShape3D.new()
	var f_box_open := BoxShape3D.new()
	f_box_open.size = Vector3(900.0, 2.0, 500.0)
	f_shape_open.shape = f_box_open
	f_shape_open.position = Vector3(0.0, -2.8, 470.0)
	floor_body.add_child(f_shape_open)
	ocean_holder.add_child(floor_body)

	# Ocean boundary barrier so player can wade in bay but not walk to infinity
	var barrier := StaticBody3D.new()
	barrier.position = Vector3(0.0, 5.0, 240.0)
	var b_shape := CollisionShape3D.new()
	var b_box := BoxShape3D.new()
	b_box.size = Vector3(900.0, 20.0, 6.0)
	b_shape.shape = b_box
	barrier.add_child(b_shape)
	ocean_holder.add_child(barrier)


# =========================================================================
# 2. SANDY BEACH & DUNES (Continuous Smooth Mesh via SurfaceTool)
# =========================================================================
func _calc_beach_height(x: float, z: float) -> float:
	# Bay curve: center around X = -55 is indented by ~6m
	var bay_curve := ((x + 55.0) / 120.0) * ((x + 55.0) / 120.0) * 6.0
	var eff_z := z + bay_curve

	# Base coastal slope from north dunes down to deep ocean
	var base_y: float
	if eff_z <= 88.0:
		base_y = 0.0
	elif eff_z <= 112.0:
		# Flat dry beach sand at Y = 0.0 matching mainland elevation
		base_y = 0.0
	elif eff_z <= 136.0:
		var t := (eff_z - 112.0) / 24.0
		base_y = lerpf(0.0, -0.8, t)
	else:
		var t := clampf((eff_z - 136.0) / 28.0, 0.0, 1.0)
		base_y = lerpf(-0.8, -1.8, t)

	# West bluff elevation: land rises on the west flank to support the cliffside lighthouse
	if x < -135.0:
		var side_t := clampf((-135.0 - x) / 50.0, 0.0, 1.0)
		base_y += side_t * 3.5
	elif x > 35.0:
		# East side: smoothly blend any underwater slope to 0.0 at X = 55.0, perfectly flush with mainland ground
		var east_t := clampf((x - 35.0) / 20.0, 0.0, 1.0)
		base_y = lerpf(base_y, 0.0, east_t)

	return base_y


func _build_beach() -> void:
	var beach_holder := Node3D.new()
	beach_holder.name = "Beach"
	add_child(beach_holder)

	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.85, 0.74, 0.52)   # warm Mediterranean golden sand
	sand_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sand_mat.roughness = 0.92

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var x_steps := 36
	var z_steps := 30
	var x_min := -190.0
	var x_max := 55.0
	var z_min := 84.0
	var z_max := 165.0

	for zi in (z_steps + 1):
		var z_t := float(zi) / float(z_steps)
		var z := lerpf(z_min, z_max, z_t)
		for xi in (x_steps + 1):
			var x_t := float(xi) / float(x_steps)
			var x := lerpf(x_min, x_max, x_t)
			var y := _calc_beach_height(x, z)

			st.set_uv(Vector2(x_t * 12.0, z_t * 10.0))
			st.add_vertex(Vector3(x, y, z))

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
	mi.material_override = sand_mat
	beach_holder.add_child(mi)

	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = mesh.create_trimesh_shape()
	sb.add_child(col)

	# Watertight continuous floor colliders guaranteeing zero void gap across the entire beach and bay
	# 1. Upper dunes & transition zone: Z in [82, 114], overlaps village ground (ends at Z=86)
	var col_dunes := CollisionShape3D.new()
	var box_dunes := BoxShape3D.new()
	box_dunes.size = Vector3(245.0, 2.0, 32.0)
	col_dunes.shape = box_dunes
	col_dunes.position = Vector3(-67.5, -1.0, 98.0) # top at Y = 0.0
	sb.add_child(col_dunes)

	# 2. Shallow wading surf & pier approach: Z in [110, 142]
	var col_surf := CollisionShape3D.new()
	var box_surf := BoxShape3D.new()
	box_surf.size = Vector3(245.0, 2.0, 32.0)
	col_surf.shape = box_surf
	col_surf.position = Vector3(-67.5, -1.45, 126.0) # top at Y = -0.45
	sb.add_child(col_surf)

	# 3. Bay seabed floor & pier end / shipwreck approach: Z in [138, 172], overlaps ocean floor (starts at Z=160)
	var col_bay := CollisionShape3D.new()
	var box_bay := BoxShape3D.new()
	box_bay.size = Vector3(245.0, 2.0, 34.0)
	col_bay.shape = box_bay
	col_bay.position = Vector3(-67.5, -2.1, 155.0) # top at Y = -1.1
	sb.add_child(col_bay)

	beach_holder.add_child(sb)

	# Coastal headland rocks on the west (lighthouse flank) and east (quarry flank)
	var rock_models: Array[String] = [
		"res://assets/world/decoration/nature/rock_single_A.gltf",
		"res://assets/world/decoration/nature/rock_single_B.gltf",
		"res://assets/world/decoration/nature/rock_single_C.gltf",
		"res://assets/world/decoration/nature/rock_single_D.gltf",
		"res://assets/world/decoration/nature/rock_single_E.gltf",
	]
	var beach_rocks: Array[Vector3] = [
		Vector3(-14.0, 0.0, 102.0), Vector3(16.0, 0.0, 106.0), Vector3(-68.0, 0.0, 104.0),
		Vector3(34.0, 0.0, 114.0), Vector3(-88.0, 0.0, 110.0), Vector3(-2.0, 0.0, 112.0),
		Vector3(-138.0, 0.0, 120.0), Vector3(-144.0, 0.0, 134.0), Vector3(-132.0, 0.0, 148.0),
		Vector3(42.0, 0.0, 118.0), Vector3(48.0, 0.0, 132.0), Vector3(52.0, 0.0, 146.0),
	]
	for i in beach_rocks.size():
		var r_pos := beach_rocks[i]
		var surface_y := _calc_beach_height(r_pos.x, r_pos.z)
		var model_path: String = rock_models[i % rock_models.size()]
		var sc := randf_range(6.5, 10.5)
		var rock_inst := _place_prop(model_path, Vector3(r_pos.x, surface_y, r_pos.z), randf() * 360.0, sc, beach_holder)
		if rock_inst:
			_add_rock_collider(rock_inst)


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

	# 1. High Rock Promontory / Cliff Base anchored into seabed (Y = -2.0 to 5.2m)
	var cliff := StaticBody3D.new()
	cliff.position = LIGHTHOUSE_POS + Vector3(0.0, 1.6, 0.0)
	var cliff_mesh := MeshInstance3D.new()
	var c_cyl := CylinderMesh.new()
	c_cyl.top_radius = 7.5
	c_cyl.bottom_radius = 9.8
	c_cyl.height = 7.2
	cliff_mesh.mesh = c_cyl
	cliff_mesh.material_override = cliff_mat
	cliff.add_child(cliff_mesh)
	var c_col := CollisionShape3D.new()
	var c_shape := CylinderShape3D.new()
	c_shape.radius = 8.6
	c_shape.height = 7.2
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
	lantern_room.name = "LanternRoom"
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
	_add_signpost("Φάρος του Ακρωτηρίου  ↑\nΠροσοχή στα Βράχια!", LIGHTHOUSE_POS + Vector3(8.5, 0.2, -2.0), -60.0, lh_holder)


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

	# Boardwalk connects from the dry golden sand (Z=96) out over the water to Z=144
	# Length: 48m, Width: 3.4m, Deck height: Y = 0.65m
	var pier_len := 48.0
	var pier_w := 3.4
	var pier_deck := StaticBody3D.new()
	pier_deck.position = PIER_POS + Vector3(0.0, 0.65, pier_len * 0.5)

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

	# Smooth wooden approach ramp connecting sand to pier deck
	var ramp := StaticBody3D.new()
	ramp.position = PIER_POS + Vector3(0.0, 0.33, -2.5)
	ramp.rotation.x = -atan2(0.62, 5.0)
	var r_mesh := MeshInstance3D.new()
	var r_box := BoxMesh.new()
	r_box.size = Vector3(pier_w, 0.24, 5.2)
	r_mesh.mesh = r_box
	r_mesh.material_override = wood_deck
	ramp.add_child(r_mesh)
	var r_col := CollisionShape3D.new()
	var rc_box := BoxShape3D.new()
	rc_box.size = Vector3(pier_w, 0.24, 5.2)
	r_col.shape = rc_box
	ramp.add_child(r_col)
	pier_holder.add_child(ramp)

	# Crosshead T-platform at the end of the pier (Width: 8.4m, Depth: 4.8m)
	var t_deck := StaticBody3D.new()
	t_deck.position = PIER_POS + Vector3(0.0, 0.65, pier_len + 2.2)
	var t_mesh := MeshInstance3D.new()
	var t_box := BoxMesh.new()
	t_box.size = Vector3(8.4, 0.28, 4.8)
	t_mesh.mesh = t_box
	t_mesh.material_override = wood_deck
	t_deck.add_child(t_mesh)
	var t_col := CollisionShape3D.new()
	var tc_box := BoxShape3D.new()
	tc_box.size = Vector3(8.4, 0.28, 4.8)
	t_col.shape = tc_box
	t_deck.add_child(t_col)
	pier_holder.add_child(t_deck)

	# Timber Pilings driven into seabed (from Y = -1.8 up to pier deck)
	for z_off in range(4, int(pier_len) + 5, 4):
		for x_off: float in [-pier_w * 0.45, pier_w * 0.45]:
			var pile := MeshInstance3D.new()
			var pc := CylinderMesh.new()
			pc.top_radius = 0.16
			pc.bottom_radius = 0.18
			pc.height = 3.2
			pile.mesh = pc
			pile.position = PIER_POS + Vector3(x_off, -0.6, float(z_off))
			pile.material_override = piling_mat
			pier_holder.add_child(pile)

	# Pier Lanterns on wooden posts
	var lantern_zs: Array[float] = [12.0, pier_len + 2.0]
	for lz: float in lantern_zs:
		var lp: Vector3 = PIER_POS + Vector3(-pier_w * 0.45 - 0.2, 0.7, lz)
		var _lantern_post = _place_prop("res://assets/graveyard/post_lantern.gltf", lp, 90.0, 1.2, pier_holder)

	# Moored Wooden Boat beside the pier
	var boat := Node3D.new()
	boat.position = PIER_POS + Vector3(2.8, -0.15, 26.0)
	boat.rotation_degrees = Vector3(3.0, -10.0, -4.0)
	var b_hull := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(1.8, 0.8, 4.5)
	b_hull.mesh = b_box
	b_hull.material_override = piling_mat
	boat.add_child(b_hull)
	pier_holder.add_child(boat)

	# Fishing spot interaction sign on dry sand at pier entrance
	_add_signpost("Ψαρολίμανο Αγίου Βλάση  ⚓\nΑποβάθρα Ψαρέματος", PIER_POS + Vector3(2.8, 0.05, -2.0), -20.0, pier_holder)


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

	# Ship Hull resting on seabed (Y = -1.8) and listing 20 degrees in the azure bay
	var hull := StaticBody3D.new()
	hull.position = SHIPWRECK_POS
	hull.rotation_degrees = Vector3(10.0, 32.0, -20.0)

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
	mast.position = SHIPWRECK_POS + Vector3(0.8, 3.2, -1.0)
	mast.rotation_degrees = Vector3(25.0, 15.0, -35.0)
	mast.material_override = wood_old
	wreck_holder.add_child(mast)

	# Sunken Treasure Chest resting on the tilted deck above water!
	var wreck_chest = Chest.new()
	wreck_chest.golden = true
	wreck_chest.gold_min = 350
	wreck_chest.gold_max = 600
	wreck_chest.potions = 3
	wreck_chest.position = SHIPWRECK_POS + Vector3(0.5, 1.2, 1.2)
	wreck_chest.rotation_degrees.y = 45.0
	wreck_holder.add_child(wreck_chest)


# --- Helper Methods ---
func _relative_transform(child: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var curr: Node = child
	while curr and curr != ancestor and curr is Node3D:
		t = (curr as Node3D).transform * t
		curr = curr.get_parent()
	return t


func _add_rock_collider(root: Node3D) -> void:
	var visual: Node3D = root.get_node_or_null("Visual")
	var node_to_scan := visual if visual else root
	var have := false
	var box := AABB()
	for mi in node_to_scan.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		var t := _relative_transform(mesh_inst, node_to_scan)
		var a: AABB = t * mesh_inst.get_aabb()
		box = a if not have else box.merge(a)
		have = true
	if box.size == Vector3.ZERO:
		return
	if visual:
		var s := visual.scale
		box = AABB(box.position * s, box.size * s)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	var h := maxf(box.size.y, 2.2)
	bs.size = Vector3(box.size.x * 1.02, h, box.size.z * 1.02)
	shape.shape = bs
	var center := box.get_center()
	shape.position = Vector3(center.x, h * 0.5, center.z)
	body.add_child(shape)
	root.add_child(body)


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


# =========================================================================
# 6. SOUTH-EAST SEA CLIFFS (Γκρεμοί στη συνάντηση θάλασσας - δάσους)
# =========================================================================
func _build_southeast_cliffs() -> void:
	var cliff_holder := Node3D.new()
	cliff_holder.name = "SoutheastCliffs"
	add_child(cliff_holder)

	var cliff_mat := StandardMaterial3D.new()
	cliff_mat.albedo_color = Color(0.42, 0.40, 0.37)
	cliff_mat.roughness = 0.92

	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.36, 0.58, 0.28)
	grass_mat.roughness = 0.85

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.55, 0.52, 0.48)
	stone_mat.roughness = 0.88

	# 1. Main Promontory Cliff Tiers running south along X in [52, 74], Z in [112, 208]
	# Rising from seabed (Y = -2.0) up to high panoramic shelf (Y = 5.2 - 6.8m)
	var cliff_sections: Array[Dictionary] = [
		{"pos": Vector3(62.0, 1.8, 130.0), "size": Vector3(20.0, 7.6, 38.0), "grass": true},  # North promontory (Z: 111 - 149)
		{"pos": Vector3(64.0, 2.3, 165.0), "size": Vector3(22.0, 8.6, 34.0), "grass": true},  # Mid lookout cape (Z: 148 - 182)
		{"pos": Vector3(61.0, 1.9, 195.0), "size": Vector3(20.0, 7.8, 30.0), "grass": true},  # South cape bluff (Z: 180 - 210)
		# Lower wave-cut rocky shelves along the water line (X ~ 53)
		{"pos": Vector3(53.0, -0.3, 138.0), "size": Vector3(7.0, 3.4, 28.0), "grass": false}, # Low surf bench north
		{"pos": Vector3(53.5, -0.2, 172.0), "size": Vector3(6.5, 3.6, 32.0), "grass": false}, # Low surf bench mid
		{"pos": Vector3(52.5, -0.4, 198.0), "size": Vector3(6.0, 3.2, 22.0), "grass": false}, # Low surf bench south
	]

	for sec in cliff_sections:
		var pos: Vector3 = sec["pos"]
		var size: Vector3 = sec["size"]
		var has_grass: bool = sec["grass"]

		var body := StaticBody3D.new()
		body.position = pos
		body.collision_layer = 1
		body.collision_mask = 0

		# Granite rock cliff body
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = cliff_mat
		body.add_child(mi)

		# Grass cap on top of elevated walking tiers
		if has_grass:
			var g_mi := MeshInstance3D.new()
			var g_bm := BoxMesh.new()
			g_bm.size = Vector3(size.x + 0.1, 0.4, size.z + 0.1)
			g_mi.mesh = g_bm
			g_mi.position = Vector3(0.0, size.y * 0.5 - 0.15, 0.0)
			g_mi.material_override = grass_mat
			body.add_child(g_mi)

		# Solid collision box
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		col.shape = bs
		body.add_child(col)
		cliff_holder.add_child(body)

	# 2. Stepped Natural Stone Stair / Ramp from beach (Z = 106, Y = 0.0) up to cliff top (Z = 118, Y = 5.6)
	var stair_steps := 10
	for i in stair_steps:
		var frac := float(i) / float(stair_steps)
		var step_pos := Vector3(lerpf(53.0, 56.0, frac), lerpf(0.3, 5.4, frac), lerpf(108.0, 118.0, frac))
		var step_body := StaticBody3D.new()
		step_body.position = step_pos
		step_body.collision_layer = 1
		step_body.collision_mask = 0

		var s_mi := MeshInstance3D.new()
		var s_bm := BoxMesh.new()
		s_bm.size = Vector3(5.5, 0.6, 2.0)
		s_mi.mesh = s_bm
		s_mi.material_override = stone_mat
		step_body.add_child(s_mi)

		var s_col := CollisionShape3D.new()
		var s_bs := BoxShape3D.new()
		s_bs.size = Vector3(5.5, 0.6, 2.0)
		s_col.shape = s_bs
		step_body.add_child(s_col)
		cliff_holder.add_child(step_body)

	# 3. Dramatic Sea Stacks & Boulders standing in the coastal waters at the cliff foot
	var sea_stacks: Array[Dictionary] = [
		{"model": "decoration/nature/mountain_B_grass.gltf", "pos": Vector3(48.0, -1.2, 128.0), "rot": 45.0, "sc": 12.0},
		{"model": "decoration/nature/rock_single_E.gltf", "pos": Vector3(45.0, -1.0, 146.0), "rot": 120.0, "sc": 16.0},
		{"model": "decoration/nature/rock_single_C.gltf", "pos": Vector3(47.0, -0.8, 162.0), "rot": 80.0, "sc": 15.0},
		{"model": "decoration/nature/mountain_A_grass.gltf", "pos": Vector3(44.0, -1.2, 182.0), "rot": -35.0, "sc": 13.0},
		{"model": "decoration/nature/rock_single_D.gltf", "pos": Vector3(46.0, -1.0, 202.0), "rot": 15.0, "sc": 14.0},
		{"model": "decoration/nature/rock_single_B.gltf", "pos": Vector3(50.0, -0.6, 136.0), "rot": 210.0, "sc": 10.0},
		{"model": "decoration/nature/rock_single_A.gltf", "pos": Vector3(48.5, -0.7, 172.0), "rot": 95.0, "sc": 11.0},
	]

	for stk in sea_stacks:
		var p_node := _place_prop("res://assets/world/" + stk["model"], stk["pos"], stk["rot"], stk["sc"], cliff_holder)
		if p_node:
			_add_rock_collider(p_node)

	# 4. Coastal Pines & Scenic Vista Lookout Bench
	var cliff_trees: Array[Vector3] = [
		Vector3(65.0, 5.6, 125.0),
		Vector3(68.0, 5.6, 138.0),
		Vector3(66.0, 6.5, 150.0),
		Vector3(69.0, 6.5, 168.0),
		Vector3(65.0, 6.5, 178.0),
		Vector3(64.0, 5.8, 192.0),
		Vector3(66.0, 5.8, 204.0),
	]
	var tree_models := [
		"res://assets/world/decoration/nature/tree_single_A.gltf",
		"res://assets/world/decoration/nature/tree_single_B.gltf",
		"res://assets/world/decoration/nature/trees_A_small.gltf",
	]
	for i in cliff_trees.size():
		var t_pos := cliff_trees[i]
		var model_path: String = tree_models[i % tree_models.size()]
		var t_node := _place_prop(model_path, t_pos, randf() * 360.0, randf_range(8.5, 12.0), cliff_holder)
		if t_node:
			var t_body := StaticBody3D.new()
			t_body.collision_layer = 1
			t_body.collision_mask = 0
			var t_col := CollisionShape3D.new()
			var t_cyl := CylinderShape3D.new()
			t_cyl.radius = 0.75
			t_cyl.height = 8.0
			t_col.shape = t_cyl
			t_col.position.y = 4.0
			t_body.add_child(t_col)
			t_node.add_child(t_body)

	# Scenic Lookout Bench facing west toward the sunset and lighthouse
	var bench := _place_prop("res://assets/graveyard/bench_decorated.gltf", Vector3(59.0, 6.5, 158.0), 90.0, 1.4, cliff_holder)
	if bench:
		var b_body := StaticBody3D.new()
		b_body.collision_layer = 1
		b_body.collision_mask = 0
		var b_col := CollisionShape3D.new()
		var b_box := BoxShape3D.new()
		b_box.size = Vector3(2.5, 0.8, 1.2)
		b_col.shape = b_box
		b_col.position.y = 0.4
		b_body.add_child(b_col)
		bench.add_child(b_body)

	# Coastal Signpost at the foot of the cliff trail
	_add_signpost("Νότιοι Γκρεμοί", Vector3(51.0, 0.0, 107.0), 15.0, cliff_holder)

