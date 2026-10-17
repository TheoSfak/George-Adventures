class_name PersonalStash
extends Node3D
## The personal storage stash chest inside George's cottage.
## Allows George to open the stash window to deposit/withdraw gear, fish, materials and potions.

var _model: Node3D

func _ready() -> void:
	name = "PersonalStash"
	add_to_group("interactables")
	add_to_group("personal_stash")
	_build_stash_mesh()


func _build_stash_mesh() -> void:
	_model = Node3D.new()
	_model.name = "StashVisual"
	add_child(_model)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.38, 0.22, 0.12) # polished oak
	wood_mat.roughness = 0.70

	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.92, 0.76, 0.32) # gold-brass trim
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.35

	# 1. Main Chest Base Box
	var chest_body := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(1.3, 0.65, 0.85)
	chest_body.mesh = b_box
	chest_body.material_override = wood_mat
	chest_body.position = Vector3(0.0, 0.325, 0.0)
	_model.add_child(chest_body)

	# 2. Curved Chest Lid Top
	var chest_lid := MeshInstance3D.new()
	var l_box := BoxMesh.new()
	l_box.size = Vector3(1.34, 0.22, 0.89)
	chest_lid.mesh = l_box
	chest_lid.material_override = wood_mat
	chest_lid.position = Vector3(0.0, 0.76, 0.0)
	_model.add_child(chest_lid)

	# 3. Gold Trim Bands
	for x in [-0.55, 0.0, 0.55]:
		var band := MeshInstance3D.new()
		var band_box := BoxMesh.new()
		band_box.size = Vector3(0.06, 0.88, 0.87)
		band.mesh = band_box
		band.material_override = brass_mat
		band.position = Vector3(x, 0.44, 0.0)
		_model.add_child(band)

	# Front Brass Latch & Keyhole Plate
	var latch := MeshInstance3D.new()
	var latch_box := BoxMesh.new()
	latch_box.size = Vector3(0.18, 0.24, 0.06)
	latch.mesh = latch_box
	latch.material_override = brass_mat
	latch.position = Vector3(0.0, 0.58, 0.44)
	_model.add_child(latch)

	# Warm Interior Glow Accent
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.82, 0.45)
	glow.light_energy = 0.85
	glow.omni_range = 3.2
	glow.position = Vector3(0.0, 0.9, 0.1)
	_model.add_child(glow)

	# Solid Collision
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(1.4, 0.9, 0.95)
	col.shape = cbox
	col.position = Vector3(0.0, 0.45, 0.0)
	body.add_child(col)
	add_child(body)


func interact_prompt() -> String:
	return "[R] Προσωπικό Μπαούλο Αποθήκευσης"


func interact_range() -> float:
	return 3.5


func interact(player: Player) -> void:
	if player == null or player.is_dead:
		return
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		tree.call_group("hud", "open_stash", player)
