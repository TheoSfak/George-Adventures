class_name IslandHighlands
extends Node3D
## The North Highlands of Agios Vlasis:
## A dramatic elevated mountain plateau rising to +14m height with winding stone paths,
## rock bluffs, the Eagle's Vista panoramic lookout, and an interactive mountain bell shrine.

const SUMMIT_POS := Vector3(82.0, 13.5, -155.0)
const TRAIL_START := Vector3(56.0, 0.1, -118.0)


func _ready() -> void:
	name = "IslandHighlands"
	_build_plateau_terraces()
	_build_mountain_trail()
	_build_summit_shrine()


# =========================================================================
# 1. LAYERED HIGHLAND TERRACES & BLUFFS (+4.5m, +9.0m, +13.5m)
# =========================================================================
func _build_plateau_terraces() -> void:
	var terr_holder := Node3D.new()
	terr_holder.name = "Terraces"
	add_child(terr_holder)

	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.36, 0.58, 0.22)   # alpine highland meadow green
	grass_mat.roughness = 0.9

	var cliff_mat := StandardMaterial3D.new()
	cliff_mat.albedo_color = Color(0.46, 0.44, 0.40)   # rugged mountain granite
	cliff_mat.roughness = 0.88

	# Terrace 1: Lower Shelf (Y = 4.5m)
	_make_terrace(Vector3(68.0, 2.25, -132.0), Vector3(26.0, 4.5, 20.0), grass_mat, cliff_mat, terr_holder)

	# Terrace 2: Mid Plateau (Y = 9.0m)
	_make_terrace(Vector3(76.0, 6.75, -145.0), Vector3(24.0, 9.0, 18.0), grass_mat, cliff_mat, terr_holder)

	# Terrace 3: Summit Plateau (Y = 13.5m)
	_make_terrace(Vector3(82.0, 11.25, -158.0), Vector3(22.0, 13.5, 18.0), grass_mat, cliff_mat, terr_holder)

	# Decorative pine trees and boulders around the cliffs
	var highland_props: Array[Vector3] = [
		Vector3(62.0, 4.5, -126.0), Vector3(72.0, 4.5, -138.0),
		Vector3(84.0, 9.0, -140.0), Vector3(68.0, 9.0, -150.0),
		Vector3(90.0, 13.5, -152.0), Vector3(74.0, 13.5, -164.0),
	]
	for p_pos in highland_props:
		var tree = _place_model("decoration/nature/tree_single_B.gltf", p_pos, randf() * 360.0, 9.5, terr_holder)


# =========================================================================
# 2. WINDING MOUNTAIN SWITCHBACK TRAIL & STAIRS
# =========================================================================
func _build_mountain_trail() -> void:
	var trail_holder := Node3D.new()
	trail_holder.name = "Trail"
	add_child(trail_holder)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.62, 0.60, 0.55)
	stone_mat.roughness = 0.8

	var wood_rail := StandardMaterial3D.new()
	wood_rail.albedo_color = Color(0.42, 0.28, 0.15)
	wood_rail.roughness = 0.85

	# Flight 1: Ascent from ground (Y=0) to Terrace 1 (Y=4.5)
	# 9 steps climbing up at angle
	for i in 9:
		var frac := float(i) / 9.0
		var pos := Vector3(lerpf(56.0, 62.0, frac), frac * 4.5, lerpf(-118.0, -126.0, frac))
		_make_stair_step(pos, Vector3(3.2, 0.35, 1.2), -52.0, stone_mat, trail_holder)

	# Flight 2: Ascent from Terrace 1 (Y=4.5) to Terrace 2 (Y=9.0)
	# 9 steps switchback
	for i in 9:
		var frac := float(i) / 9.0
		var pos := Vector3(lerpf(64.0, 72.0, frac), 4.5 + frac * 4.5, lerpf(-128.0, -138.0, frac))
		_make_stair_step(pos, Vector3(3.2, 0.35, 1.2), -52.0, stone_mat, trail_holder)

	# Flight 3: Ascent from Terrace 2 (Y=9.0) to Summit (Y=13.5)
	# 9 steps final approach to the Eagle's Vista
	for i in 9:
		var frac := float(i) / 9.0
		var pos := Vector3(lerpf(74.0, 80.0, frac), 9.0 + frac * 4.5, lerpf(-142.0, -152.0, frac))
		_make_stair_step(pos, Vector3(3.2, 0.35, 1.2), -55.0, stone_mat, trail_holder)

	# Signpost at the foot of the mountain trail
	_add_signpost("Μονοπάτι των Αετών  ↑\nΠρος το Οροπέδιο (14μ)", TRAIL_START + Vector3(2.5, 0.1, 1.5), 15.0, trail_holder)


# =========================================================================
# 3. EAGLE'S VISTA LOOKOUT & MOUNTAIN BELL SHRINE
# =========================================================================
func _build_summit_shrine() -> void:
	var shrine_holder := Node3D.new()
	shrine_holder.name = "SummitShrine"
	add_child(shrine_holder)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.72, 0.70, 0.65)
	stone_mat.roughness = 0.75

	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.25, 0.45, 0.65)   # Byzantine blue roof
	roof_mat.roughness = 0.6

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.82, 0.25)
	gold_mat.metallic = 0.8
	gold_mat.roughness = 0.3

	# 1. Circular Stone Vista Podium
	var podium := StaticBody3D.new()
	podium.position = SUMMIT_POS
	var p_mesh := MeshInstance3D.new()
	var p_cyl := CylinderMesh.new()
	p_cyl.top_radius = 5.2
	p_cyl.bottom_radius = 5.6
	p_cyl.height = 0.4
	p_mesh.mesh = p_cyl
	p_mesh.material_override = stone_mat
	podium.add_child(p_mesh)
	var p_col := CollisionShape3D.new()
	var pc_shape := CylinderShape3D.new()
	pc_shape.radius = 5.4
	pc_shape.height = 0.4
	p_col.shape = pc_shape
	podium.add_child(p_col)
	shrine_holder.add_child(podium)

	# 2. 4 Stone Columns supporting Bell Canopy
	var canopy_pos := SUMMIT_POS + Vector3(0.0, 0.2, -1.5)
	for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var col_p: Vector3 = canopy_pos + Vector3(cos(angle) * 1.8, 1.6, sin(angle) * 1.8)
		var col_inst := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.18
		cm.bottom_radius = 0.22
		cm.height = 3.2
		col_inst.mesh = cm
		col_inst.position = col_p
		col_inst.material_override = stone_mat
		shrine_holder.add_child(col_inst)

	# Canopy Roof
	var canopy := MeshInstance3D.new()
	var c_mesh := CylinderMesh.new()
	c_mesh.top_radius = 0.2
	c_mesh.bottom_radius = 2.4
	c_mesh.height = 1.4
	canopy.mesh = c_mesh
	canopy.position = canopy_pos + Vector3(0.0, 3.8, 0.0)
	canopy.material_override = roof_mat
	shrine_holder.add_child(canopy)

	# Golden Church Bell
	var bell := MeshInstance3D.new()
	var b_mesh := CylinderMesh.new()
	b_mesh.top_radius = 0.18
	b_mesh.bottom_radius = 0.42
	b_mesh.height = 0.75
	bell.mesh = b_mesh
	bell.position = canopy_pos + Vector3(0.0, 2.7, 0.0)
	bell.material_override = gold_mat
	shrine_holder.add_child(bell)

	# Interactive Bell Ringer Spot
	var bell_spot := InteractSpot.make("Χτύπησε την Καμπάνα της Κορυφής", func(_p = null):
		Sfx.play("bell_toll")
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("notify"):
			player.notify("Η καμπάνα της κορυφής αντηχεί σε όλο το νησί!")
	, 4.5)
	bell_spot.position = canopy_pos + Vector3(0.0, 0.2, 0.8)
	shrine_holder.add_child(bell_spot)

	# 3. Scenic Wooden Overlook Bench facing south toward the sea
	var bench_mat := StandardMaterial3D.new()
	bench_mat.albedo_color = Color(0.42, 0.28, 0.15)
	var bench := StaticBody3D.new()
	bench.position = SUMMIT_POS + Vector3(0.0, 0.4, 3.2)
	var bn_mesh := MeshInstance3D.new()
	var bn_box := BoxMesh.new()
	bn_box.size = Vector3(2.4, 0.45, 0.8)
	bn_mesh.mesh = bn_box
	bn_mesh.material_override = bench_mat
	bench.add_child(bn_mesh)
	var bn_col := CollisionShape3D.new()
	var bnc_box := BoxShape3D.new()
	bnc_box.size = Vector3(2.4, 0.45, 0.8)
	bn_col.shape = bnc_box
	bench.add_child(bn_col)
	shrine_holder.add_child(bench)

	# 4. Golden Summit Trophy Chest
	var chest = Chest.new()
	chest.golden = true
	chest.gold_min = 400
	chest.gold_max = 650
	chest.potions = 3
	chest.position = SUMMIT_POS + Vector3(3.2, 0.2, 0.0)
	chest.rotation_degrees.y = -90.0
	shrine_holder.add_child(chest)

	# Summit Signpost
	_add_signpost("Βίγλα των Αετών  ★\nΥψόμετρο: 14μ — Θέα σε όλο το Νησί", SUMMIT_POS + Vector3(-3.4, 0.2, 2.0), 35.0, shrine_holder)


# --- Helpers ---
func _make_terrace(pos: Vector3, size: Vector3, top_mat: Material, side_mat: Material, parent: Node) -> void:
	var body := StaticBody3D.new()
	body.position = pos

	# Rugged Granite Cliff Rock Body
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = side_mat
	body.add_child(mi)

	# Alpine Highland Grass Cap on top
	var top_mi := MeshInstance3D.new()
	var top_bm := BoxMesh.new()
	top_bm.size = Vector3(size.x + 0.1, 0.4, size.z + 0.1)
	top_mi.mesh = top_bm
	top_mi.position = Vector3(0.0, size.y * 0.5 - 0.15, 0.0)
	top_mi.material_override = top_mat
	body.add_child(top_mi)

	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	body.add_child(col)
	parent.add_child(body)


func _make_stair_step(pos: Vector3, size: Vector3, yaw_deg: float, mat: Material, parent: Node) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = yaw_deg
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
