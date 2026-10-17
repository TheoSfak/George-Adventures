class_name CottageGarden
extends Node3D
## George's private herbal alchemy garden outside his cottage.
## Features raised soil planter boxes, fenced perimeter, and harvestable flora
## that yield alchemical reagents (mountain_herb, waterlily, reed, autumn_cone) once per in-game day.

const HARVEST_REAGENTS: Array[String] = ["mountain_herb", "waterlily", "reed", "autumn_cone"]

var last_harvest_day := -1
var _model: Node3D
var _planter_lights: Array[OmniLight3D] = []

func _ready() -> void:
	name = "CottageGarden"
	add_to_group("interactables")
	add_to_group("cottage_garden")
	_build_garden_mesh()


func _build_garden_mesh() -> void:
	_model = Node3D.new()
	_model.name = "GardenVisual"
	add_child(_model)

	var wood_fence := StandardMaterial3D.new()
	wood_fence.albedo_color = Color(0.42, 0.28, 0.16)
	wood_fence.roughness = 0.85

	var soil_mat := StandardMaterial3D.new()
	soil_mat.albedo_color = Color(0.22, 0.16, 0.11) # rich dark loam soil
	soil_mat.roughness = 0.95

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.55, 0.52, 0.48)
	stone_mat.roughness = 0.90

	# 1. 3 Raised Garden Planter Soil Beds
	for i in 3:
		var z_offset := (i - 1) * 2.2
		var bed := MeshInstance3D.new()
		var b_box := BoxMesh.new()
		b_box.size = Vector3(3.4, 0.35, 1.4)
		bed.mesh = b_box
		bed.material_override = soil_mat
		bed.position = Vector3(0.0, 0.175, z_offset)
		_model.add_child(bed)

		# Wooden perimeter border frame around each bed
		var frame := MeshInstance3D.new()
		var f_box := BoxMesh.new()
		f_box.size = Vector3(3.6, 0.40, 1.6)
		frame.mesh = f_box
		frame.material_override = wood_fence
		frame.position = Vector3(0.0, 0.16, z_offset)
		_model.add_child(frame)

		# Glowing Herb Sprout Indicators
		for x_spot: float in [-1.0, 0.0, 1.0]:
			var plant := MeshInstance3D.new()
			var pm := SphereMesh.new()
			pm.radius = 0.18
			pm.height = 0.32
			plant.mesh = pm
			var p_mat := StandardMaterial3D.new()
			p_mat.albedo_color = Color(0.3, 0.85, 0.4)
			p_mat.emission_enabled = true
			p_mat.emission = Color(0.2, 0.7, 0.3)
			p_mat.emission_energy_multiplier = 0.6
			plant.material_override = p_mat
			plant.position = Vector3(x_spot, 0.42, z_offset)
			_model.add_child(plant)

		# Soft magical garden light
		var omni := OmniLight3D.new()
		omni.light_color = Color(0.4, 0.9, 0.5)
		omni.light_energy = 0.8
		omni.omni_range = 3.5
		omni.position = Vector3(0.0, 0.8, z_offset)
		_model.add_child(omni)
		_planter_lights.append(omni)

	# 2. Rustic Post-and-Rail Fence Enclosure
	# North and South fence lines
	for z_pos in [-3.8, 3.8]:
		var fence := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(4.8, 0.85, 0.14)
		fence.mesh = fm
		fence.material_override = wood_fence
		fence.position = Vector3(0.0, 0.42, z_pos)
		_model.add_child(fence)

	# Solid Base Collider
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(4.8, 0.6, 7.8)
	col.shape = cbox
	col.position = Vector3(0.0, 0.3, 0.0)
	body.add_child(col)
	add_child(body)


func is_ready_to_harvest() -> bool:
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree == null:
		return true
	var daynight := tree.get_first_node_in_group("daynight") as DayNight
	var current_day := daynight.day_number if daynight != null else 1
	return last_harvest_day < current_day


func interact_prompt() -> String:
	if is_ready_to_harvest():
		return "[R] Συγκομιδή Βοτάνων Κήπου (Άγρια Αλχημεία)"
	return "Ο κήπος αναπτύσσει νέα βότανα (Αναμονή μέχρι αύριο)"


func interact_range() -> float:
	return 3.8


func interact(player: Player) -> void:
	if player == null or player.is_dead:
		return
	if not is_ready_to_harvest():
		player.message.emit("Ο κήπος χρειάζεται χρόνο. Επιστρέψτε την επόμενη ημέρα για νέα συγκομιδή!")
		return

	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var daynight := tree.get_first_node_in_group("daynight") as DayNight if tree != null else null
	last_harvest_day = daynight.day_number if daynight != null else 1

	# Pick 3 random alchemical reagents and add to junk
	var harvested_parts: Array[String] = []
	for i in 3:
		var reagent: String = HARVEST_REAGENTS.pick_random()
		player.junk[reagent] = int(player.junk.get(reagent, 0)) + 1
		harvested_parts.append(_reagent_display_name(reagent))

	player.message.emit("🌿 Συγκομιδή: 3x Βότανα (%s) προστέθηκαν στον σάκο σου!" % ", ".join(harvested_parts))
	Sfx.ui("quest_complete")


func _reagent_display_name(id: String) -> String:
	match id:
		"mountain_herb": return "Ορεινό Βότανο"
		"waterlily": return "Νούφαρο"
		"reed": return "Καλάμι"
		"autumn_cone": return "Χρυσό Κουκουνάρι"
		_: return id


func save_data() -> Dictionary:
	return {
		"last_harvest_day": last_harvest_day
	}


func load_data(d: Dictionary) -> void:
	last_harvest_day = int(d.get("last_harvest_day", -1))

