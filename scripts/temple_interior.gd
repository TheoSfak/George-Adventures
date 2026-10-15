class_name TempleSanctum
extends Node3D
## The inner sanctum of the Temple of Flame ("Άδυτο της Φλόγας" - Story Part 5).
## A grand volcanic cathedral chamber deep beneath the Ash Valley.
## Home to the Cinder Guardians, the Cinder Archon (boss), and the Altar of the Eternal Flame.

const ORIGIN := Vector3(8000.0, 0.0, -6000.0)
const BOUNDS := Rect2(-24.0, -60.0, 48.0, 116.0)
const ENTRY := Vector2(0.0, 46.0)
const EXIT := Vector2(0.0, 52.0)
const ALTAR_POS := Vector2(0.0, -50.0)

const G := "res://assets/graveyard/"
const I := "res://assets/items/"
const W := "res://assets/world/"
const CHAR := "res://assets/characters/"

# [kind, x, z]
const SPAWNS := [
	# Entrance Hall
	["cinder_guardian", -8.0, 32.0], ["cinder_guardian", 8.0, 32.0],
	["ember_skeleton", -12.0, 24.0], ["ember_skeleton", 12.0, 24.0],
	# Middle Colonnade
	["cinder_guardian", -9.0, 12.0], ["cinder_guardian", 9.0, 12.0],
	["ash_caster", -10.0, 0.0], ["ash_caster", 10.0, 0.0],
	["ember_skeleton", -8.0, -10.0], ["ember_skeleton", 8.0, -10.0],
	# Boss Sanctum Arena
	["cinder_guardian", -10.0, -26.0], ["cinder_guardian", 10.0, -26.0],
	["cinder_archon", 0.0, -36.0],
]

const CHESTS := [
	[-14.0, 18.0, 90, true, 260, 450, 3],
	[14.0, -18.0, 270, true, 350, 600, 4],
]

var exit_action := Callable()

var _root: Node3D
var _stone: StandardMaterial3D
var _altar_fire: MeshInstance3D
var _altar_light: OmniLight3D
var _altar_cleansed := false
var _boss: Enemy = null


func _ready() -> void:
	add_to_group("temple_sanctum")


static func wp(x: float, z: float, h: float = 0.0) -> Vector3:
	return ORIGIN + Vector3(x, h, z)


func spawn_point() -> Vector3:
	return wp(ENTRY.x, ENTRY.y, 0.05)


func build() -> void:
	_root = Node3D.new()
	_root.name = "SanctumRoot"
	add_child(_root)

	_stone = StandardMaterial3D.new()
	_stone.albedo_color = Color(0.22, 0.16, 0.18)
	_stone.roughness = 0.92

	_build_hall()
	_build_altar()
	_build_chests()
	_spawn_creatures()


func _box(pos: Vector3, size: Vector3, mat: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_root.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var collider := BoxShape3D.new()
		collider.size = size
		shape.shape = collider
		body.add_child(shape)
		mi.add_child(body)
	return mi


func _prop(path: String, x: float, z: float, yaw_deg: float, scale_: float, lift: float = 0.0, solid: bool = false) -> Node3D:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	model.position = wp(x, z, lift)
	model.rotation_degrees.y = yaw_deg
	model.scale = Vector3.ONE * scale_
	_root.add_child(model)
	if solid:
		Interiors.collider_for(model)
	return model


func _build_hall() -> void:
	# Floor
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.18, 0.13, 0.14)
	floor_mat.roughness = 0.85
	_box(wp(0.0, -4.0, -0.1), Vector3(44.0, 0.2, 116.0), floor_mat, true)

	# Ceiling
	_box(wp(0.0, -4.0, 10.0), Vector3(44.0, 0.4, 116.0), _stone, false)

	# Perimeter Walls (height 10m)
	_box(wp(-22.0, -4.0, 5.0), Vector3(1.5, 10.0, 116.0), _stone, true)
	_box(wp(22.0, -4.0, 5.0), Vector3(1.5, 10.0, 116.0), _stone, true)
	_box(wp(0.0, -62.0, 5.0), Vector3(44.0, 10.0, 1.5), _stone, true)
	# South wall with entrance archway gap
	_box(wp(-14.0, 54.0, 5.0), Vector3(16.0, 10.0, 1.5), _stone, true)
	_box(wp(14.0, 54.0, 5.0), Vector3(16.0, 10.0, 1.5), _stone, true)

	# Exit Archway
	var arch := _prop(G + "arch_gate.gltf", EXIT.x, EXIT.y, 0.0, 3.8, 0.0, true)
	var exit_spot := InteractSpot.make(Strings.PROMPT_SANCTUM_EXIT, func(p: Player):
		if exit_action.is_valid():
			exit_action.call(p)
	, 4.5)
	exit_spot.position = wp(EXIT.x, EXIT.y - 1.5)
	_root.add_child(exit_spot)

	# Pillars with flaming braziers along both sides
	var pillar_z := [36.0, 20.0, 4.0, -12.0, -28.0]
	for z in pillar_z:
		for x in [-14.0, 14.0]:
			_pillar(x, z)
			_prop(I + "torch_lit.gltf.glb", x + (2.0 if x < 0 else -2.0), z, 0.0, 2.8)
			var light := OmniLight3D.new()
			light.position = wp(x + (2.0 if x < 0 else -2.0), z, 2.8)
			light.light_color = Color(1.0, 0.50, 0.15)
			light.light_energy = 2.0
			light.omni_range = 14.0
			_root.add_child(light)


func _pillar(x: float, z: float) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.5
	cyl.height = 10.0
	mi.mesh = cyl
	mi.material_override = _stone
	mi.position = wp(x, z, 5.0)
	_root.add_child(mi)

	var col := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 1.5
	cyl_shape.height = 10.0
	shape.shape = cyl_shape
	col.add_child(shape)
	mi.add_child(col)


func _build_altar() -> void:
	# Dais
	var dais_mat := StandardMaterial3D.new()
	dais_mat.albedo_color = Color(0.12, 0.08, 0.10)
	_box(wp(ALTAR_POS.x, ALTAR_POS.y, 0.4), Vector3(12.0, 0.8, 8.0), dais_mat, true)

	# Altar basin
	var basin := MeshInstance3D.new()
	var basin_cyl := CylinderMesh.new()
	basin_cyl.top_radius = 2.2
	basin_cyl.bottom_radius = 1.4
	basin_cyl.height = 1.5
	basin.mesh = basin_cyl
	basin.material_override = dais_mat
	basin.position = wp(ALTAR_POS.x, ALTAR_POS.y, 1.4)
	_root.add_child(basin)

	# Altar Eternal Flame
	_altar_fire = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.6
	cone.height = 3.8
	_altar_fire.mesh = cone
	var fire_mat := StandardMaterial3D.new()
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_mat.albedo_color = Color(1.0, 0.45, 0.08)
	_altar_fire.material_override = fire_mat
	_altar_fire.position = wp(ALTAR_POS.x, ALTAR_POS.y, 4.0)
	_root.add_child(_altar_fire)

	_altar_light = OmniLight3D.new()
	_altar_light.position = wp(ALTAR_POS.x, ALTAR_POS.y, 3.5)
	_altar_light.light_color = Color(1.0, 0.45, 0.12)
	_altar_light.light_energy = 3.5
	_altar_light.omni_range = 25.0
	_root.add_child(_altar_light)

	# Altar Interact Spot
	var spot := InteractSpot.make(Strings.PROMPT_SANCTUM_ALTAR, func(player: Player):
		_on_altar_interact(player)
	, 5.0)
	spot.position = wp(ALTAR_POS.x, ALTAR_POS.y + 3.2)
	_root.add_child(spot)


func _on_altar_interact(player: Player) -> void:
	if _boss != null and is_instance_valid(_boss) and not _boss.is_dead():
		player.message.emit("Ο Άρχοντας της Τέφρας φρουρεί τον Βωμό! Πρέπει πρώτα να τον νικήσεις.")
		return

	if _altar_cleansed:
		player.message.emit("Η Αιώνια Φλόγα λάμπει ήρεμη και καθαρή.")
		return

	_altar_cleansed = true
	Sfx.play("flame_altar")

	# Purify the flame colors
	var pure_mat := StandardMaterial3D.new()
	pure_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pure_mat.albedo_color = Color(0.40, 0.85, 1.0)
	_altar_fire.material_override = pure_mat
	_altar_light.light_color = Color(0.45, 0.85, 1.0)
	_altar_light.light_energy = 4.5

	player.message.emit(Strings.MSG_ALTAR_RESTORED)

	var quests_mgr = get_tree().root.get_node_or_null("Quests") if get_tree() else null
	if quests_mgr and quests_mgr.state.get("t_archon", 0) == 2:
		quests_mgr.progress["t_archon"][0] = 1
		quests_mgr.check_ready("t_archon")
		quests_mgr.changed.emit()


func _build_chests() -> void:
	for c in CHESTS:
		var chest := Chest.new()
		chest.golden = c[3]
		chest.gold_min = c[4]
		chest.gold_max = c[5]
		chest.potions = c[6]
		chest.position = wp(c[0], c[1])
		chest.rotation_degrees.y = c[2]
		_root.add_child(chest)
		if SaveGame.opened_chests.has(SaveGame.key_for(chest.position)):
			chest.mark_opened()


func _spawn_creatures() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		return
	for s in SPAWNS:
		var enemy: Enemy = spawner.spawn_extra(s[0], wp(s[1], s[2], 0.05))
		if enemy and s[0] == "cinder_archon":
			_boss = enemy
