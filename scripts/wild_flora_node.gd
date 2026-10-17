class_name WildFloraNode
extends Node3D
## Interactive wild flora node scattered across the island.
## Collects waterlilies, reeds, mountain herbs, and autumn pine cones
## used at Andreas' alchemy bench for blade coatings and elixirs.

signal harvested_reagent(flora_id: String, count: int)

@export var flora_id: String = "waterlily"
@export var respawn_time: float = 60.0

var flora_name := "Άγριο Νούφαρο"
var harvested := false
var _respawn_timer := 0.0
var _visual: Node3D
var _light: OmniLight3D
var _anim_clock := 0.0

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("flora")

	if ShopData.JUNK.has(flora_id):
		flora_name = ShopData.JUNK[flora_id].get("name", flora_name)

	_build_visuals()


func _build_visuals() -> void:
	_visual = Node3D.new()
	_visual.name = "FloraVisual"
	add_child(_visual)

	match flora_id:
		"waterlily":
			_build_waterlily_mesh()
		"reed":
			_build_reed_mesh()
		"mountain_herb":
			_build_mountain_herb_mesh()
		"autumn_cone":
			_build_autumn_cone_mesh()
		_:
			_build_mountain_herb_mesh()

	# Soft ambient glow so flora stands out in grass and water
	_light = OmniLight3D.new()
	_light.omni_range = 2.4
	_light.light_energy = 0.55
	var light_col := Color(0.4, 0.9, 1.0)
	if ShopData.JUNK.has(flora_id):
		light_col = ShopData.JUNK[flora_id].get("color", light_col)
	_light.light_color = light_col
	_light.position.y = 0.35
	_visual.add_child(_light)


func _build_waterlily_mesh() -> void:
	# Flat floating green lily pad
	var pad := MeshInstance3D.new()
	var pad_mesh := CylinderMesh.new()
	pad_mesh.top_radius = 0.45
	pad_mesh.bottom_radius = 0.45
	pad_mesh.height = 0.02
	pad.mesh = pad_mesh

	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = Color(0.12, 0.52, 0.22)
	pad_mat.roughness = 0.4
	pad.material_override = pad_mat
	pad.position.y = 0.01
	_visual.add_child(pad)

	# White and delicate pink blossom petals
	var flower_mat := StandardMaterial3D.new()
	flower_mat.albedo_color = Color(0.96, 0.88, 0.94)
	flower_mat.roughness = 0.3
	flower_mat.emission_enabled = true
	flower_mat.emission = Color(0.98, 0.85, 0.95)
	flower_mat.emission_energy_multiplier = 0.3

	for i in 6:
		var petal := MeshInstance3D.new()
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(0.08, 0.03, 0.22)
		petal.mesh = p_mesh
		petal.material_override = flower_mat
		petal.position = Vector3(0.0, 0.04, 0.07).rotated(Vector3.UP, float(i) * PI / 3.0)
		petal.rotation.y = float(i) * PI / 3.0
		petal.rotation.x = 0.25
		_visual.add_child(petal)

	# Golden center stamen
	var center := MeshInstance3D.new()
	var c_mesh := SphereMesh.new()
	c_mesh.radius = 0.06
	c_mesh.height = 0.08
	center.mesh = c_mesh
	var c_mat := StandardMaterial3D.new()
	c_mat.albedo_color = Color(1.0, 0.85, 0.2)
	c_mat.emission_enabled = true
	c_mat.emission = Color(1.0, 0.8, 0.1)
	c_mat.emission_energy_multiplier = 0.6
	center.material_override = c_mat
	center.position.y = 0.06
	_visual.add_child(center)


func _build_reed_mesh() -> void:
	var stalk_mat := StandardMaterial3D.new()
	stalk_mat.albedo_color = Color(0.24, 0.58, 0.18)
	stalk_mat.roughness = 0.6

	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.42, 0.26, 0.14)
	head_mat.roughness = 0.8

	var offsets := [
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.12, 0.0, -0.08),
		Vector3(-0.10, 0.0, 0.11),
		Vector3(0.08, 0.0, 0.14)
	]

	for i in offsets.size():
		var stalk := MeshInstance3D.new()
		var s_mesh := CylinderMesh.new()
		var h: float = 1.3 + float(i) * 0.15
		s_mesh.top_radius = 0.02
		s_mesh.bottom_radius = 0.03
		s_mesh.height = h
		stalk.mesh = s_mesh
		stalk.material_override = stalk_mat
		stalk.position = offsets[i] + Vector3(0.0, h * 0.5, 0.0)
		stalk.rotation.z = (float(i) - 1.5) * 0.05
		_visual.add_child(stalk)

		# Cattail brown top
		var top := MeshInstance3D.new()
		var t_mesh := CylinderMesh.new()
		t_mesh.top_radius = 0.045
		t_mesh.bottom_radius = 0.045
		t_mesh.height = 0.26
		top.mesh = t_mesh
		top.material_override = head_mat
		top.position = offsets[i] + Vector3(0.0, h - 0.15, 0.0)
		_visual.add_child(top)


func _build_mountain_herb_mesh() -> void:
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.22, 0.48, 0.35)
	leaf_mat.roughness = 0.5

	var flower_mat := StandardMaterial3D.new()
	flower_mat.albedo_color = Color(0.70, 0.35, 0.90)
	flower_mat.emission_enabled = true
	flower_mat.emission = Color(0.65, 0.30, 0.85)
	flower_mat.emission_energy_multiplier = 0.4

	# Base foliage
	for i in 5:
		var leaf := MeshInstance3D.new()
		var l_mesh := BoxMesh.new()
		l_mesh.size = Vector3(0.08, 0.02, 0.28)
		leaf.mesh = l_mesh
		leaf.material_override = leaf_mat
		leaf.position = Vector3(0.0, 0.04, 0.09).rotated(Vector3.UP, float(i) * TAU / 5.0)
		leaf.rotation.y = float(i) * TAU / 5.0
		leaf.rotation.x = 0.3
		_visual.add_child(leaf)

	# Violet flower stems
	for i in 4:
		var stem := MeshInstance3D.new()
		var s_mesh := CylinderMesh.new()
		s_mesh.top_radius = 0.015
		s_mesh.bottom_radius = 0.02
		s_mesh.height = 0.38
		stem.mesh = s_mesh
		stem.material_override = leaf_mat
		var ang := float(i) * TAU / 4.0
		stem.position = Vector3(cos(ang) * 0.08, 0.19, sin(ang) * 0.08)
		_visual.add_child(stem)

		var head := MeshInstance3D.new()
		var h_mesh := SphereMesh.new()
		h_mesh.radius = 0.05
		h_mesh.height = 0.10
		head.mesh = h_mesh
		head.material_override = flower_mat
		head.position = Vector3(cos(ang) * 0.08, 0.38, sin(ang) * 0.08)
		_visual.add_child(head)


func _build_autumn_cone_mesh() -> void:
	var cone_mat := StandardMaterial3D.new()
	cone_mat.albedo_color = Color(0.48, 0.28, 0.12)
	cone_mat.roughness = 0.7

	var resin_mat := StandardMaterial3D.new()
	resin_mat.albedo_color = Color(1.0, 0.75, 0.25)
	resin_mat.emission_enabled = true
	resin_mat.emission = Color(1.0, 0.70, 0.20)
	resin_mat.emission_energy_multiplier = 0.4

	# Layered pine cone shape lying on the pine forest floor
	var base := MeshInstance3D.new()
	var b_mesh := CylinderMesh.new()
	b_mesh.top_radius = 0.12
	b_mesh.bottom_radius = 0.07
	b_mesh.height = 0.10
	base.mesh = b_mesh
	base.material_override = cone_mat
	base.position.y = 0.05
	_visual.add_child(base)

	var mid := MeshInstance3D.new()
	var m_mesh := CylinderMesh.new()
	m_mesh.top_radius = 0.09
	m_mesh.bottom_radius = 0.13
	m_mesh.height = 0.12
	mid.mesh = m_mesh
	mid.material_override = cone_mat
	mid.position.y = 0.14
	_visual.add_child(mid)

	var tip := MeshInstance3D.new()
	var t_mesh := SphereMesh.new()
	t_mesh.radius = 0.08
	t_mesh.height = 0.12
	tip.mesh = t_mesh
	tip.material_override = cone_mat
	tip.position.y = 0.22
	_visual.add_child(tip)

	# Glistening golden resin spots
	var drop := MeshInstance3D.new()
	var d_mesh := SphereMesh.new()
	d_mesh.radius = 0.03
	d_mesh.height = 0.04
	drop.mesh = d_mesh
	drop.material_override = resin_mat
	drop.position = Vector3(0.06, 0.16, 0.05)
	_visual.add_child(drop)


func _process(delta: float) -> void:
	_anim_clock += delta
	if harvested:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			harvested = false
			if _visual != null:
				_visual.visible = true
	elif _light != null:
		# Subtle gentle breathing pulse on the light
		_light.light_energy = 0.55 + sin(_anim_clock * 2.5) * 0.15


func interact_prompt() -> String:
	if harvested:
		return ""
	return "[R] Συγκομιδή: %s" % flora_name


func interact_range() -> float:
	return 3.2


func interact(player: Player) -> void:
	if harvested or player == null:
		return

	harvested = true
	if _visual != null:
		_visual.visible = false
	_respawn_timer = respawn_time

	var count := 1
	# Small bonus chance for extra herb
	if randf() < 0.25:
		count = 2

	player.junk[flora_id] = int(player.junk.get(flora_id, 0)) + count
	player.inventory_changed.emit(player.gold, player.potions)

	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null and tree.has_group("hud"):
		tree.call_group("hud", "show_banner", "🌿 Συγκομιδή: %s ×%d!" % [flora_name, count], 2.2)

	Sfx.ui("eat")
	harvested_reagent.emit(flora_id, count)
