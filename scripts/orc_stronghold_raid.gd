class_name OrcStrongholdRaid
extends Node3D
## Story Part 6: The Siege of the Orc Stronghold (Fortress Dungeon Raid).
## Coordinates the assault on the ruined eastern fortress with Village Guards,
## breakable Warband Blood Totems, siege catapult sabotage, and the battle
## against Warlord Grom'gar (Orc Champion) in the inner keep sanctum.

signal siege_started
signal totem_destroyed(count: int)
signal catapult_sabotaged_signal
signal fortress_liberated

const GuardClass := preload("res://scripts/guard.gd")
const ChestClass := preload("res://scripts/chest.gd")

const FORTRESS_CENTER := Vector3(122.0, 0.0, 6.0)
const STAGING_POS := Vector3(98.0, 0.0, 6.0)
const CATAPULT_POS := Vector3(115.5, 0.0, 13.5)

var siege_active := false
var totems_destroyed := 0
var catapult_disabled := false
var warlord_slain := false

var _guards: Array = []
var _totems: Array = []
var _catapult_spot: Node3D
var _horn_spot: Node3D
var _victory_chest: Node3D
var _smoke_particles: Array[Node3D] = []

func _ready() -> void:
	name = "OrcStrongholdRaid"
	_build_warband_totems()
	_setup_catapult_sabotage()
	_setup_assault_horn()
	_listen_for_warlord()


# =========================================================================
# 1. WARBAND BLOOD TOTEMS
# =========================================================================
func _build_warband_totems() -> void:
	var totem_positions: Array[Vector3] = [
		FORTRESS_CENTER + Vector3(-3.5, 0.0, -5.0), # Northern courtyard totem (118.5, 0.0, 1.0)
		FORTRESS_CENTER + Vector3(4.0, 0.0, 0.0),   # Central ritual blood totem (126.0, 0.0, 6.0)
		FORTRESS_CENTER + Vector3(-3.5, 0.0, 5.0)   # Southern courtyard totem (118.5, 0.0, 11.0)
	]

	for i in totem_positions.size():
		var t_pos: Vector3 = totem_positions[i]
		var totem := _create_totem_node(t_pos, i + 1)
		add_child(totem)
		_totems.append(totem)


func _create_totem_node(pos: Vector3, index: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "WarbandTotem_%d" % index
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("breakables")
	body.add_to_group("totems")
	body.add_to_group("interactables")
	body.set_meta("raid_totem", true)
	body.set_meta("totem_hp", 85.0)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.25, 0.14, 0.08) # charred bloodwood
	wood_mat.roughness = 0.9

	var bone_mat := StandardMaterial3D.new()
	bone_mat.albedo_color = Color(0.85, 0.80, 0.72)
	bone_mat.roughness = 0.7

	var blood_glyph_mat := StandardMaterial3D.new()
	blood_glyph_mat.albedo_color = Color(0.9, 0.15, 0.05)
	blood_glyph_mat.emission_enabled = true
	blood_glyph_mat.emission = Color(1.0, 0.2, 0.05)
	blood_glyph_mat.emission_energy_multiplier = 2.0

	# 1. Main Spiked Post
	var post := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28
	cyl.bottom_radius = 0.42
	cyl.height = 3.2
	post.mesh = cyl
	post.position = Vector3(0.0, 1.6, 0.0)
	post.material_override = wood_mat
	body.add_child(post)

	# 2. Horned Skulls & Spikes
	for a: float in [-0.5, 0.5]:
		var horn := MeshInstance3D.new()
		var p := PrismMesh.new()
		p.size = Vector3(0.3, 0.9, 0.25)
		horn.mesh = p
		horn.position = Vector3(a * 0.7, 2.7, 0.0)
		horn.rotation_degrees.z = a * -35.0
		horn.material_override = bone_mat
		body.add_child(horn)

	# 3. Glowing Crimson Warband Runes
	var rune := MeshInstance3D.new()
	var r_box := BoxMesh.new()
	r_box.size = Vector3(0.65, 0.45, 0.65)
	rune.mesh = r_box
	rune.position = Vector3(0.0, 2.0, 0.0)
	rune.material_override = blood_glyph_mat
	body.add_child(rune)

	# 4. Red Ambient Pulsing Light
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.25, 0.1)
	light.light_energy = 2.2
	light.omni_range = 7.5
	light.position = Vector3(0.0, 2.2, 0.0)
	body.add_child(light)

	# 5. Collision Capsule
	var col := CollisionShape3D.new()
	var c_shape := CylinderShape3D.new()
	c_shape.radius = 0.55
	c_shape.height = 3.2
	col.shape = c_shape
	col.position = Vector3(0.0, 1.6, 0.0)
	body.add_child(col)

	# Interaction script methods attached dynamically
	body.set_script(_get_totem_script())
	return body


static func _get_totem_script() -> GDScript:
	return load("res://scripts/warband_totem_node.gd") if ResourceLoader.exists("res://scripts/warband_totem_node.gd") else null


# =========================================================================
# 2. SIEGE CATAPULT SABOTAGE
# =========================================================================
func _setup_catapult_sabotage() -> void:
	var spot := Node3D.new()
	spot.name = "CatapultSabotageSpot"
	spot.position = CATAPULT_POS
	spot.add_to_group("interactables")
	add_child(spot)

	var marker := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.15
	sph.height = 0.3
	marker.mesh = sph
	marker.position = Vector3(0.0, 0.8, 0.0)
	spot.add_child(marker)

	spot.set_script(_get_catapult_script())
	_catapult_spot = spot


static func _get_catapult_script() -> GDScript:
	return load("res://scripts/catapult_sabotage_node.gd") if ResourceLoader.exists("res://scripts/catapult_sabotage_node.gd") else null


# =========================================================================
# 3. ASSAULT WAR HORN & SQUAD RALLY
# =========================================================================
func _setup_assault_horn() -> void:
	var horn := Node3D.new()
	horn.name = "AssaultWarHorn"
	horn.position = STAGING_POS
	horn.add_to_group("interactables")
	add_child(horn)

	# Visual Post & Brass War Horn
	var post := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.15
	cyl.height = 1.4
	post.mesh = cyl
	post.position = Vector3(0.0, 0.7, 0.0)
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	post.material_override = wood_mat
	horn.add_child(post)

	var brass := MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl2.top_radius = 0.25
	cyl2.bottom_radius = 0.08
	cyl2.height = 0.75
	brass.mesh = cyl2
	brass.position = Vector3(0.0, 1.45, 0.0)
	brass.rotation_degrees = Vector3(0.0, 0.0, 75.0)
	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.72, 0.25)
	brass_mat.metallic = 0.8
	brass_mat.roughness = 0.3
	brass.material_override = brass_mat
	horn.add_child(brass)

	horn.set_script(_get_horn_script())
	_horn_spot = horn


static func _get_horn_script() -> GDScript:
	return load("res://scripts/assault_horn_node.gd") if ResourceLoader.exists("res://scripts/assault_horn_node.gd") else null


# =========================================================================
# 4. RAID LOGIC & PROGRESSION
# =========================================================================
func start_assault(player: Player = null) -> void:
	if siege_active:
		if player != null:
			player.message.emit("Η πολιορκία είναι ήδη σε εξέλιξη! Προχωρήστε στην πύλη!")
		return

	siege_active = true
	Sfx.play("skill_shout", STAGING_POS)

	var guard_names: Array[String] = ["Φρουρός Λεωνίδας", "Φρουρός Μάρκος", "Φρουρός Στέφανος"]
	var guard_offsets: Array[Vector3] = [
		Vector3(0.0, 0.0, -1.8),
		Vector3(2.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 1.8)
	]

	for i in guard_names.size():
		var guard: Guard = GuardClass.new()
		guard.guard_name = guard_names[i]
		guard.damage = 20.0
		guard.follow_player = true
		guard.home = FORTRESS_CENTER
		var spawn_pos := STAGING_POS + guard_offsets[i]
		guard.position = spawn_pos
		add_child(guard)
		_guards.append(guard)

	if player != null:
		player.message.emit("Η Πολιορκία Ξεκίνησε! Οι Φρουροί Εφορμούν στο Προπύργιο!")

	siege_started.emit()


func on_totem_destroyed(totem_node: Node) -> void:
	totems_destroyed += 1
	var quests_singleton: Node = Engine.get_main_loop().root.get_node_or_null("Quests") if Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root else null
	if quests_singleton != null:
		quests_singleton.call("report_kill", "warband_totem")

	var player := get_tree().get_first_node_in_group("player") as Player if is_inside_tree() else null
	if player != null:
		player.message.emit("Τοτέμ Καταστράφηκε! (%d/3)" % totems_destroyed)
		if totems_destroyed >= 3:
			player.message.emit("Όλα τα Τοτέμ της Συμμορίας καταστράφηκαν! Οι δυνάμεις των Όρκ εξασθενούν!")

	totem_destroyed.emit(totems_destroyed)


func sabotage_catapult(player: Player = null) -> void:
	if catapult_disabled:
		return
	catapult_disabled = true

	var quests_singleton: Node = Engine.get_main_loop().root.get_node_or_null("Quests") if Engine.get_main_loop() and (Engine.get_main_loop() as SceneTree).root else null
	if quests_singleton != null:
		quests_singleton.call("report_kill", "orc_catapult")

	Sfx.play("wood_break", CATAPULT_POS)
	if player != null:
		player.message.emit("Ο πολιορκητικός καταπέλτης των Όρκ αχρηστεύτηκε!")

	# Smoke plume above disabled catapult
	var smoke := MeshInstance3D.new()
	var sm_box := BoxMesh.new()
	sm_box.size = Vector3(1.2, 2.5, 1.2)
	smoke.mesh = sm_box
	smoke.position = CATAPULT_POS + Vector3(0.0, 2.2, 0.0)
	var s_mat := StandardMaterial3D.new()
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.albedo_color = Color(0.2, 0.2, 0.2, 0.65)
	smoke.material_override = s_mat
	add_child(smoke)

	catapult_sabotaged_signal.emit()


func _listen_for_warlord() -> void:
	# Watch for orc_warlord defeat
	if not is_inside_tree():
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("kind_id") == "orc_warlord":
			e.connect("tree_exited", _on_warlord_vanquished)


func _on_warlord_vanquished() -> void:
	if warlord_slain:
		return
	warlord_slain = true

	# Victory Fanfare & Golden Chest
	Sfx.ui("quest_complete")
	var chest: Chest = ChestClass.new()
	chest.golden = true
	chest.gold_min = 1200
	chest.gold_max = 1800
	chest.potions = 5
	chest.position = FORTRESS_CENTER + Vector3(4.0, 0.0, 0.0)
	add_child(chest)
	_victory_chest = chest

	var player := get_tree().get_first_node_in_group("player") as Player if is_inside_tree() else null
	if player != null:
		player.message.emit("Ο Πολέμαρχος Γκρομ'γκαρ Έπεσε! Το Προπύργιο Ελευθερώθηκε!")

	for g in _guards:
		if is_instance_valid(g):
			# Guards celebrate
			var lbl := Label3D.new()
			lbl.text = "Ζήτω ο Γιώργος!"
			lbl.font_size = 32
			lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lbl.modulate = Color(1.0, 0.9, 0.3)
			lbl.position.y = 2.8
			g.add_child(lbl)

	fortress_liberated.emit()
