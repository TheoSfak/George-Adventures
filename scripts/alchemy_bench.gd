class_name AlchemyBench
extends Node3D
## Andreas' herbal alchemy crafting bench in the village square.
## Allows George to brew wild reagents into weapon blade coatings
## and resistance elixirs.

var bench_title := "Πάγκος Αλχημείας του Αντρέα"
var _model: Node3D
var _anim_clock := 0.0
var _liquid_flasks: Array[MeshInstance3D] = []

func _ready() -> void:
	name = "AlchemyBench"
	add_to_group("interactables")
	add_to_group("alchemy")

	_build_bench_visuals()


func _build_bench_visuals() -> void:
	_model = Node3D.new()
	_model.name = "BenchModel"
	add_child(_model)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.36, 0.22, 0.12)
	wood_mat.roughness = 0.8

	var copper_mat := StandardMaterial3D.new()
	copper_mat.albedo_color = Color(0.78, 0.45, 0.25)
	copper_mat.metallic = 0.85
	copper_mat.roughness = 0.35

	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.70, 0.28)
	brass_mat.metallic = 0.90
	brass_mat.roughness = 0.30

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.50, 0.52, 0.54)
	stone_mat.roughness = 0.9

	# 1. Main Workbench Table Top
	var tabletop := MeshInstance3D.new()
	var tt_mesh := BoxMesh.new()
	tt_mesh.size = Vector3(2.2, 0.14, 1.1)
	tabletop.mesh = tt_mesh
	tabletop.material_override = wood_mat
	tabletop.position = Vector3(0.0, 0.88, 0.0)
	_model.add_child(tabletop)

	# 4 Heavy Wooden Legs
	for x in [-0.95, 0.95]:
		for z in [-0.42, 0.42]:
			var leg := MeshInstance3D.new()
			var l_mesh := BoxMesh.new()
			l_mesh.size = Vector3(0.14, 0.88, 0.14)
			leg.mesh = l_mesh
			leg.material_override = wood_mat
			leg.position = Vector3(x, 0.44, z)
			_model.add_child(leg)

	# Lower shelf with ingredient crates
	var shelf := MeshInstance3D.new()
	var s_mesh := BoxMesh.new()
	s_mesh.size = Vector3(1.8, 0.08, 0.8)
	shelf.mesh = s_mesh
	shelf.material_override = wood_mat
	shelf.position = Vector3(0.0, 0.25, 0.0)
	_model.add_child(shelf)

	# 2. Copper Alembic Distiller / Retort Apparatus
	var alembic_pot := MeshInstance3D.new()
	var ap_mesh := SphereMesh.new()
	ap_mesh.radius = 0.24
	ap_mesh.height = 0.36
	alembic_pot.mesh = ap_mesh
	alembic_pot.material_override = copper_mat
	alembic_pot.position = Vector3(-0.65, 1.12, -0.15)
	_model.add_child(alembic_pot)

	# Alembic dome / swan neck
	var neck := MeshInstance3D.new()
	var n_mesh := CylinderMesh.new()
	n_mesh.top_radius = 0.03
	n_mesh.bottom_radius = 0.09
	n_mesh.height = 0.35
	neck.mesh = n_mesh
	neck.material_override = copper_mat
	neck.position = Vector3(-0.65, 1.40, -0.15)
	_model.add_child(neck)

	# Horizontal condensing pipe
	var pipe := MeshInstance3D.new()
	var pi_mesh := CylinderMesh.new()
	pi_mesh.top_radius = 0.02
	pi_mesh.bottom_radius = 0.02
	pi_mesh.height = 0.45
	pipe.mesh = pi_mesh
	pipe.material_override = brass_mat
	pipe.position = Vector3(-0.45, 1.50, -0.15)
	pipe.rotation.z = PI / 2.0
	_model.add_child(pipe)

	# Condenser receiving beaker
	var beaker := MeshInstance3D.new()
	var b_mesh := CylinderMesh.new()
	b_mesh.top_radius = 0.08
	b_mesh.bottom_radius = 0.11
	b_mesh.height = 0.24
	beaker.mesh = b_mesh
	beaker.material_override = copper_mat
	beaker.position = Vector3(-0.25, 1.05, -0.15)
	_model.add_child(beaker)

	# 3. Mortar and Pestle for grinding fresh flora
	var mortar := MeshInstance3D.new()
	var m_mesh := CylinderMesh.new()
	m_mesh.top_radius = 0.13
	m_mesh.bottom_radius = 0.08
	m_mesh.height = 0.16
	mortar.mesh = m_mesh
	mortar.material_override = stone_mat
	mortar.position = Vector3(0.55, 1.02, 0.2)
	_model.add_child(mortar)

	var pestle := MeshInstance3D.new()
	var pe_mesh := CylinderMesh.new()
	pe_mesh.top_radius = 0.025
	pe_mesh.bottom_radius = 0.035
	pe_mesh.height = 0.24
	pestle.mesh = pe_mesh
	pestle.material_override = stone_mat
	pestle.position = Vector3(0.57, 1.14, 0.22)
	pestle.rotation.z = 0.35
	_model.add_child(pestle)

	# 4. Colorful Glowing Liquid Flasks (Flame Oil, Poison, Frost Ward)
	var flask_configs := [
		{"color": Color(1.0, 0.4, 0.1), "pos": Vector3(0.12, 1.04, -0.25)},
		{"color": Color(0.3, 0.95, 0.3), "pos": Vector3(0.32, 1.04, -0.22)},
		{"color": Color(0.3, 0.7, 1.0), "pos": Vector3(0.50, 1.04, -0.26)},
	]

	for cfg in flask_configs:
		var flask := MeshInstance3D.new()
		var fl_mesh := SphereMesh.new()
		fl_mesh.radius = 0.075
		fl_mesh.height = 0.14
		flask.mesh = fl_mesh

		var glass_mat := StandardMaterial3D.new()
		glass_mat.albedo_color = cfg["color"]
		glass_mat.roughness = 0.2
		glass_mat.emission_enabled = true
		glass_mat.emission = cfg["color"]
		glass_mat.emission_energy_multiplier = 0.65
		flask.material_override = glass_mat
		flask.position = cfg["pos"]
		_model.add_child(flask)
		_liquid_flasks.append(flask)

	# 5. Open Herbalist Grimoire
	var book := MeshInstance3D.new()
	var bo_mesh := BoxMesh.new()
	bo_mesh.size = Vector3(0.32, 0.04, 0.24)
	book.mesh = bo_mesh
	var book_mat := StandardMaterial3D.new()
	book_mat.albedo_color = Color(0.92, 0.88, 0.75)
	book.material_override = book_mat
	book.position = Vector3(0.15, 0.97, 0.18)
	book.rotation.y = 0.2
	_model.add_child(book)

	# 6. Alchemical Warm Hearth Light
	var bench_light := OmniLight3D.new()
	bench_light.light_color = Color(1.0, 0.82, 0.5)
	bench_light.light_energy = 0.9
	bench_light.omni_range = 3.8
	bench_light.position = Vector3(0.0, 1.35, 0.0)
	_model.add_child(bench_light)

	# Collision Shape so player can't walk through the solid workbench
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.3, 1.4, 1.2)
	col.shape = box
	col.position = Vector3(0.0, 0.7, 0.0)
	body.add_child(col)
	add_child(body)


func _process(delta: float) -> void:
	_anim_clock += delta
	# Subtle mystical pulsing of the liquid flasks
	for i in _liquid_flasks.size():
		var flask := _liquid_flasks[i]
		if flask != null and flask.material_override is StandardMaterial3D:
			var mat := flask.material_override as StandardMaterial3D
			mat.emission_energy_multiplier = 0.55 + sin(_anim_clock * 2.8 + float(i)) * 0.25


func interact_prompt() -> String:
	return "[R] Πάγκος Αλχημείας του Αντρέα (Παρασκευή Ελιξιρίων)"


func interact_range() -> float:
	return 3.5


func interact(player: Player) -> void:
	if player == null:
		return
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		tree.call_group("hud", "open_shop", "andreas_alchemy", player)
