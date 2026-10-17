class_name BountyBoard
extends Node3D
## The Village Bounty Board outside the Tavern in Agios Vlasis.
## A rustic wooden notice board with a shingled roof, pinned parchments with wax seals,
## and a hanging brass lantern. Players can inspect and accept active hunting contracts.

var _model: Node3D
var _lantern_light: OmniLight3D
var _lantern_post: Node3D
var _anim_clock := 0.0

func _ready() -> void:
	name = "BountyBoard"
	add_to_group("interactables")
	add_to_group("bounty_board")
	_build_board_mesh()


func _build_board_mesh() -> void:
	_model = Node3D.new()
	_model.name = "BoardVisual"
	add_child(_model)

	var wood_dark := StandardMaterial3D.new()
	wood_dark.albedo_color = Color(0.32, 0.20, 0.12) # weathered dark oak
	wood_dark.roughness = 0.85

	var wood_light := StandardMaterial3D.new()
	wood_light.albedo_color = Color(0.48, 0.34, 0.22) # notice backboard
	wood_light.roughness = 0.80

	var roof_tiles := StandardMaterial3D.new()
	roof_tiles.albedo_color = Color(0.24, 0.16, 0.10) # dark roof shingles
	roof_tiles.roughness = 0.90

	var parchment_mat := StandardMaterial3D.new()
	parchment_mat.albedo_color = Color(0.92, 0.86, 0.72) # aged parchment paper
	parchment_mat.roughness = 0.95

	var wax_red := StandardMaterial3D.new()
	wax_red.albedo_color = Color(0.82, 0.16, 0.12) # crimson wax seal
	wax_red.roughness = 0.40

	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.68, 0.26)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.35

	# 1. Two Main Vertical Support Posts
	for x_pos: float in [-1.05, 1.05]:
		var post := MeshInstance3D.new()
		var p_box := BoxMesh.new()
		p_box.size = Vector3(0.18, 2.3, 0.18)
		post.mesh = p_box
		post.material_override = wood_dark
		post.position = Vector3(x_pos, 1.15, 0.0)
		_model.add_child(post)

		# Stone support base footer
		var footer := MeshInstance3D.new()
		var f_box := BoxMesh.new()
		f_box.size = Vector3(0.28, 0.22, 0.28)
		footer.mesh = f_box
		var stone_mat := StandardMaterial3D.new()
		stone_mat.albedo_color = Color(0.45, 0.45, 0.46)
		footer.material_override = stone_mat
		footer.position = Vector3(x_pos, 0.11, 0.0)
		_model.add_child(footer)

	# 2. Wooden Notice Backboard
	var board := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(2.1, 1.35, 0.08)
	board.mesh = b_box
	board.material_override = wood_light
	board.position = Vector3(0.0, 1.45, 0.0)
	_model.add_child(board)

	# Board framing border
	var top_bar := MeshInstance3D.new()
	var tb_box := BoxMesh.new()
	tb_box.size = Vector3(2.26, 0.10, 0.12)
	top_bar.mesh = tb_box
	top_bar.material_override = wood_dark
	top_bar.position = Vector3(0.0, 2.15, 0.0)
	_model.add_child(top_bar)

	var bot_bar := MeshInstance3D.new()
	var bb_box := BoxMesh.new()
	bb_box.size = Vector3(2.26, 0.10, 0.12)
	bot_bar.mesh = bb_box
	bot_bar.material_override = wood_dark
	bot_bar.position = Vector3(0.0, 0.75, 0.0)
	_model.add_child(bot_bar)

	# 3. Gabled Shingle Canopy / Roof
	var roof_left := MeshInstance3D.new()
	var rl_box := BoxMesh.new()
	rl_box.size = Vector3(2.4, 0.06, 0.45)
	roof_left.mesh = rl_box
	roof_left.material_override = roof_tiles
	roof_left.position = Vector3(0.0, 2.38, 0.16)
	roof_left.rotation_degrees.x = 25.0
	_model.add_child(roof_left)

	var roof_right := MeshInstance3D.new()
	var rr_box := BoxMesh.new()
	rr_box.size = Vector3(2.4, 0.06, 0.45)
	roof_right.mesh = rr_box
	roof_right.material_override = roof_tiles
	roof_right.position = Vector3(0.0, 2.38, -0.16)
	roof_right.rotation_degrees.x = -25.0
	_model.add_child(roof_right)

	# Roof crest cap
	var crest := MeshInstance3D.new()
	var cr_box := BoxMesh.new()
	cr_box.size = Vector3(2.46, 0.08, 0.12)
	crest.mesh = cr_box
	crest.material_override = wood_dark
	crest.position = Vector3(0.0, 2.48, 0.0)
	_model.add_child(crest)

	# 4. Pinned Parchment Contract Notices
	var parchment_configs := [
		{"pos": Vector3(-0.62, 1.45, 0.05), "rot_z": 2.5, "scale": Vector2(0.52, 0.78)},
		{"pos": Vector3(0.0, 1.48, 0.05), "rot_z": -1.2, "scale": Vector2(0.55, 0.85)},
		{"pos": Vector3(0.62, 1.44, 0.05), "rot_z": 3.0, "scale": Vector2(0.50, 0.75)},
	]

	for cfg in parchment_configs:
		var p_mesh := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(cfg["scale"].x, cfg["scale"].y, 0.015)
		p_mesh.mesh = pm
		p_mesh.material_override = parchment_mat
		p_mesh.position = cfg["pos"]
		p_mesh.rotation_degrees.z = cfg["rot_z"]
		_model.add_child(p_mesh)

		# Top wax seal pin
		var wax := MeshInstance3D.new()
		var wm := SphereMesh.new()
		wm.radius = 0.035
		wm.height = 0.035
		wax.mesh = wm
		wax.material_override = wax_red
		wax.position = cfg["pos"] + Vector3(0.0, cfg["scale"].y * 0.45, 0.012)
		_model.add_child(wax)

	# 5. Carved Title Signboard on top
	var title_sign := MeshInstance3D.new()
	var ts_box := BoxMesh.new()
	ts_box.size = Vector3(1.6, 0.22, 0.04)
	title_sign.mesh = ts_box
	title_sign.material_override = wood_dark
	title_sign.position = Vector3(0.0, 2.22, 0.08)
	_model.add_child(title_sign)

	# 6. Hanging Brass Lantern
	_lantern_post = Node3D.new()
	_lantern_post.position = Vector3(0.0, 2.28, 0.28)
	_model.add_child(_lantern_post)

	var hook := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.015
	hm.bottom_radius = 0.015
	hm.height = 0.16
	hook.mesh = hm
	hook.material_override = brass_mat
	hook.position = Vector3(0.0, -0.08, 0.0)
	_lantern_post.add_child(hook)

	var lantern := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.18, 0.26, 0.18)
	lantern.mesh = lm
	var lantern_mat := StandardMaterial3D.new()
	lantern_mat.albedo_color = Color(1.0, 0.85, 0.50)
	lantern_mat.emission_enabled = true
	lantern_mat.emission = Color(1.0, 0.78, 0.40)
	lantern_mat.emission_energy_multiplier = 1.2
	lantern.material_override = lantern_mat
	lantern.position = Vector3(0.0, -0.25, 0.0)
	_lantern_post.add_child(lantern)

	_lantern_light = OmniLight3D.new()
	_lantern_light.light_color = Color(1.0, 0.80, 0.45)
	_lantern_light.light_energy = 1.5
	_lantern_light.omni_range = 6.0
	_lantern_light.position = Vector3(0.0, -0.25, 0.0)
	_lantern_post.add_child(_lantern_light)

	# 7. Solid Collision Box Collider
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var c_box := BoxShape3D.new()
	c_box.size = Vector3(2.4, 2.4, 0.6)
	col.shape = c_box
	col.position = Vector3(0.0, 1.2, 0.0)
	body.add_child(col)
	add_child(body)


func _process(delta: float) -> void:
	_anim_clock += delta
	# Subtle atmospheric lantern sway
	if _lantern_post != null:
		_lantern_post.rotation.z = sin(_anim_clock * 1.6) * 0.04
		_lantern_post.rotation.x = cos(_anim_clock * 1.3) * 0.03


func interact_prompt() -> String:
	return "[R] Πίνακας Επικηρύξεων & Συμβόλαια"


func interact_range() -> float:
	return 3.6


func interact(player: Player) -> void:
	if player == null or player.is_dead:
		return
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		tree.call_group("hud", "open_bounty_board", player)
		Sfx.ui("window_open")
