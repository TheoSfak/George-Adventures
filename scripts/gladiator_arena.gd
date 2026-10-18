class_name GladiatorArena
extends Node3D
## Gladiator Arena & Proving Grounds of Agios Vlasis (Αρένα Μονομάχων).
## A grand circular stone arena featuring tiered spectator stands, cheering crowds,
## burning perimeter torches, iron portcullis gate, Arena Master Kassandros,
## 5 trial tiers of wave combat, and legendary championship rewards.

signal trial_started(trial_id: String)
signal wave_started(wave_index: int, total_waves: int)
signal mob_count_changed(alive_count: int)
signal trial_finished(trial_id: String, success: bool)

const ArenaDataClass := preload("res://scripts/arena_data.gd")
const ChestClass := preload("res://scripts/chest.gd")

const CENTER := Vector3(122.0, 0.0, -75.0)
const ARENA_RADIUS := 13.5
const WALL_HEIGHT := 3.2
const GATE_POS := Vector3(108.5, 0.0, -75.0)
const MASTER_POS := Vector3(104.5, 0.0, -71.5)
const SIGN_POS := Vector3(103.0, 0.0, -78.5)

var completed_trials: Array = []
var trial_active := false
var current_trial_id := ""
var current_wave := 0
var total_waves := 3

var _active_mobs: Array[Enemy] = []
var _portcullis: Node3D
var _portcullis_body: StaticBody3D
var _gate_open := true
var _player: Player
var _master_npc: Node3D
var _victory_chest: Node3D
var _torch_lights: Array[OmniLight3D] = []
var _anim_clock := 0.0

func _ready() -> void:
	name = "GladiatorArena"
	add_to_group("gladiator_arena")
	_build_arena_structure()
	_build_approach_and_master()
	_open_gate(true)


# =========================================================================
# 1. 3D ARENA STRUCTURE (SAND PIT, POLYGONAL STONE WALLS, STANDS, TORCHES)
# =========================================================================
func _build_arena_structure() -> void:
	var holder := Node3D.new()
	holder.name = "ArenaVisuals"
	add_child(holder)

	# 1. Fighting Sand Disc
	var sand_mesh := CylinderMesh.new()
	sand_mesh.top_radius = ARENA_RADIUS
	sand_mesh.bottom_radius = ARENA_RADIUS
	sand_mesh.height = 0.06
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.82, 0.72, 0.52) # warm fighting sand
	sand_mat.roughness = 0.95
	var sand_inst := MeshInstance3D.new()
	sand_inst.mesh = sand_mesh
	sand_inst.material_override = sand_mat
	sand_inst.position = CENTER + Vector3(0.0, 0.03, 0.0)
	holder.add_child(sand_inst)

	# 2. Circular Stone Curb / Ring
	var curb_mesh := TorusMesh.new()
	curb_mesh.inner_radius = ARENA_RADIUS - 0.25
	curb_mesh.outer_radius = ARENA_RADIUS + 0.35
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.42, 0.40, 0.38) # weathered limestone
	stone_mat.roughness = 0.88
	var curb_inst := MeshInstance3D.new()
	curb_inst.mesh = curb_mesh
	curb_inst.material_override = stone_mat
	curb_inst.position = CENTER + Vector3(0.0, 0.08, 0.0)
	holder.add_child(curb_inst)

	# 3. 12-Sided Polygonal Stone Wall with Battlements and Colliders
	var num_segments := 12
	var angle_step := TAU / float(num_segments)
	var segment_width := 2.0 * ARENA_RADIUS * sin(angle_step * 0.5)

	var wall_body := StaticBody3D.new()
	wall_body.name = "ArenaWallColliders"
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0
	add_child(wall_body)

	for i in num_segments:
		var angle := float(i) * angle_step
		# West side (angle closest to PI) is the entrance gate
		var is_gate := absf(wrapf(angle - PI, -PI, PI)) < (angle_step * 0.6)
		var wall_center := CENTER + Vector3(cos(angle), 0.0, sin(angle)) * ARENA_RADIUS

		if is_gate:
			_build_gate_portal(holder, wall_center, angle)
			continue

		# Stone Wall Segment
		var seg := MeshInstance3D.new()
		var seg_box := BoxMesh.new()
		seg_box.size = Vector3(segment_width * 1.04, WALL_HEIGHT, 1.1)
		seg.mesh = seg_box
		seg.material_override = stone_mat
		seg.position = wall_center + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0)
		seg.rotation.y = -angle + (PI * 0.5)
		holder.add_child(seg)

		# Battlement Coping Cap
		var cap := MeshInstance3D.new()
		var cap_box := BoxMesh.new()
		cap_box.size = Vector3(segment_width * 1.06, 0.35, 1.35)
		cap.mesh = cap_box
		var cap_mat := StandardMaterial3D.new()
		cap_mat.albedo_color = Color(0.35, 0.33, 0.30)
		cap_mat.roughness = 0.85
		cap.material_override = cap_mat
		cap.position = wall_center + Vector3(0.0, WALL_HEIGHT + 0.175, 0.0)
		cap.rotation.y = seg.rotation.y
		holder.add_child(cap)

		# Wall Collider Shape
		var col := CollisionShape3D.new()
		var c_box := BoxShape3D.new()
		c_box.size = Vector3(segment_width * 1.04, WALL_HEIGHT * 1.2, 1.2)
		col.shape = c_box
		col.position = wall_center + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0)
		col.rotation.y = seg.rotation.y
		wall_body.add_child(col)

		# Corner Columns & Perimeter Braziers (every 2nd column)
		var pillar_corner := CENTER + Vector3(cos(angle + angle_step * 0.5), 0.0, sin(angle + angle_step * 0.5)) * ARENA_RADIUS
		_build_corner_pillar(holder, pillar_corner, (i % 2 == 0))

	# 4. North and South Spectator Grandstands
	_build_grandstand(holder, CENTER + Vector3(0.0, 0.0, -ARENA_RADIUS - 6.5), 0.0, true)  # North stand
	_build_grandstand(holder, CENTER + Vector3(0.0, 0.0, ARENA_RADIUS + 6.5), PI, false) # South stand


func _build_corner_pillar(holder: Node3D, pos: Vector3, with_torch: bool) -> void:
	var stone_dark := StandardMaterial3D.new()
	stone_dark.albedo_color = Color(0.36, 0.34, 0.32)
	stone_dark.roughness = 0.85

	var pillar := MeshInstance3D.new()
	var p_box := BoxMesh.new()
	p_box.size = Vector3(1.3, WALL_HEIGHT + 0.8, 1.3)
	pillar.mesh = p_box
	pillar.material_override = stone_dark
	pillar.position = pos + Vector3(0.0, (WALL_HEIGHT + 0.8) * 0.5, 0.0)
	holder.add_child(pillar)

	if with_torch:
		# Iron Sconce & Active Torch
		var iron_mat := StandardMaterial3D.new()
		iron_mat.albedo_color = Color(0.18, 0.18, 0.20)
		iron_mat.metallic = 0.85

		var brazier := MeshInstance3D.new()
		var b_cyl := CylinderMesh.new()
		b_cyl.top_radius = 0.42
		b_cyl.bottom_radius = 0.22
		b_cyl.height = 0.45
		brazier.mesh = b_cyl
		brazier.material_override = iron_mat
		brazier.position = pos + Vector3(0.0, WALL_HEIGHT + 0.9, 0.0)
		holder.add_child(brazier)

		var fire := MeshInstance3D.new()
		var f_sph := SphereMesh.new()
		f_sph.radius = 0.32
		f_sph.height = 0.55
		fire.mesh = f_sph
		var fire_mat := StandardMaterial3D.new()
		fire_mat.albedo_color = Color(1.0, 0.45, 0.12)
		fire_mat.emission_enabled = true
		fire_mat.emission = Color(1.0, 0.48, 0.10)
		fire_mat.emission_energy_multiplier = 2.4
		fire.material_override = fire_mat
		fire.position = pos + Vector3(0.0, WALL_HEIGHT + 1.25, 0.0)
		holder.add_child(fire)

		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.72, 0.38)
		light.light_energy = 1.6
		light.omni_range = 14.0
		light.position = fire.position
		light.add_to_group("night_lights")
		holder.add_child(light)
		_torch_lights.append(light)


func _build_gate_portal(holder: Node3D, pos: Vector3, angle: float) -> void:
	var stone_dark := StandardMaterial3D.new()
	stone_dark.albedo_color = Color(0.36, 0.34, 0.32)
	stone_dark.roughness = 0.85

	# Left and Right Stone Archway Towers
	for offset_x in [-2.8, 2.8]:
		var side_vec := Vector3(0.0, 0.0, offset_x)
		var tower := MeshInstance3D.new()
		var t_box := BoxMesh.new()
		t_box.size = Vector3(1.6, WALL_HEIGHT + 1.8, 1.6)
		tower.mesh = t_box
		tower.material_override = stone_dark
		tower.position = pos + side_vec + Vector3(0.0, (WALL_HEIGHT + 1.8) * 0.5, 0.0)
		holder.add_child(tower)

	# Overhead Stone Lintel Beam
	var lintel := MeshInstance3D.new()
	var l_box := BoxMesh.new()
	l_box.size = Vector3(1.6, 0.85, 6.2)
	lintel.mesh = l_box
	lintel.material_override = stone_dark
	lintel.position = pos + Vector3(0.0, WALL_HEIGHT + 1.5, 0.0)
	holder.add_child(lintel)

	# Red and Gold Heraldic Championship Banners on Archway
	for bx in [-2.4, 2.4]:
		var banner := MeshInstance3D.new()
		var b_quad := QuadMesh.new()
		b_quad.size = Vector2(0.9, 2.6)
		banner.mesh = b_quad
		var b_mat := StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.82, 0.12, 0.10) # crimson arena red
		b_mat.roughness = 0.8
		banner.material_override = b_mat
		banner.position = pos + Vector3(-0.85, WALL_HEIGHT - 0.2, bx)
		banner.rotation_degrees = Vector3(0.0, -90.0, 0.0)
		holder.add_child(banner)

	# Movable Heavy Iron Portcullis Gate
	_portcullis = Node3D.new()
	_portcullis.name = "Portcullis"
	_portcullis.position = pos
	holder.add_child(_portcullis)

	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.22, 0.22, 0.25)
	iron_mat.metallic = 0.90
	iron_mat.roughness = 0.40

	# Vertical and horizontal iron bars
	for bar_i in 9:
		var bar_z := -2.2 + float(bar_i) * 0.55
		var bar_v := MeshInstance3D.new()
		var c_cyl := CylinderMesh.new()
		c_cyl.top_radius = 0.045
		c_cyl.bottom_radius = 0.045
		c_cyl.height = 3.6
		bar_v.mesh = c_cyl
		bar_v.material_override = iron_mat
		bar_v.position = Vector3(0.0, 1.8, bar_z)
		_portcullis.add_child(bar_v)

	for bar_j in 4:
		var bar_y := 0.6 + float(bar_j) * 0.9
		var bar_h := MeshInstance3D.new()
		var b_box := BoxMesh.new()
		b_box.size = Vector3(0.12, 0.08, 4.8)
		bar_h.mesh = b_box
		bar_h.material_override = iron_mat
		bar_h.position = Vector3(0.0, bar_y, 0.0)
		_portcullis.add_child(bar_h)

	# Portcullis Gate Physical Collider
	_portcullis_body = StaticBody3D.new()
	_portcullis_body.name = "PortcullisCollider"
	_portcullis_body.collision_layer = 1
	_portcullis_body.collision_mask = 0
	var p_col := CollisionShape3D.new()
	var p_shape := BoxShape3D.new()
	p_shape.size = Vector3(1.2, 4.0, 5.0)
	p_col.shape = p_shape
	p_col.position = Vector3(0.0, 2.0, 0.0)
	_portcullis_body.add_child(p_col)
	_portcullis.add_child(_portcullis_body)


func _build_grandstand(holder: Node3D, pos: Vector3, yaw: float, is_north: bool) -> void:
	var stand := Node3D.new()
	stand.name = "Stand_North" if is_north else "Stand_South"
	stand.position = pos
	stand.rotation.y = yaw
	holder.add_child(stand)

	var wood_dark := StandardMaterial3D.new()
	wood_dark.albedo_color = Color(0.38, 0.25, 0.16)
	wood_dark.roughness = 0.85

	# 3-Tiered Platform Steps
	for tier in 3:
		var step := MeshInstance3D.new()
		var step_box := BoxMesh.new()
		step_box.size = Vector3(16.0, 0.6, 1.8)
		step.mesh = step_box
		step.material_override = wood_dark
		step.position = Vector3(0.0, 0.3 + float(tier) * 0.6, float(tier) * 1.5)
		stand.add_child(step)

		# Wooden Viewing Bench
		var bench := MeshInstance3D.new()
		var b_box := BoxMesh.new()
		b_box.size = Vector3(15.2, 0.45, 0.5)
		bench.mesh = b_box
		bench.material_override = wood_dark
		bench.position = Vector3(0.0, 0.85 + float(tier) * 0.6, float(tier) * 1.5)
		stand.add_child(bench)

	# Cheering Spectator Props / NPCs on the stands
	var spectator_models := [
		"res://assets/characters/Barbarian.glb",
		"res://assets/characters/Knight.glb",
		"res://assets/characters/Rogue.glb",
		"res://assets/characters/Mage.glb",
	]
	for k in 5:
		var sc_tier := k % 3
		var spec_x := -5.5 + float(k) * 2.8
		var spec_path: String = spectator_models[k % spectator_models.size()]
		var spec_scene := load(spec_path) as PackedScene
		if spec_scene != null:
			var spec_node := spec_scene.instantiate() as Node3D
			spec_node.scale = Vector3.ONE * 0.95
			spec_node.position = Vector3(spec_x, 0.6 + float(sc_tier) * 0.6, float(sc_tier) * 1.5)
			stand.add_child(spec_node)
			var anim := spec_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if anim != null and anim.has_animation("Idle"):
				anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
				anim.play("Idle")
				anim.seek(float(k) * 0.7, true)


# =========================================================================
# 2. APPROACH AVENUE, SIGNPOST & ARENA MASTER KASSANDROS
# =========================================================================
func _build_approach_and_master() -> void:
	# 1. Approach Cobblestone Path
	var path_mat := StandardMaterial3D.new()
	path_mat.albedo_color = Color(0.48, 0.45, 0.42)
	path_mat.roughness = 0.92

	for dist_x in range(96, 108, 3):
		var stone_step := MeshInstance3D.new()
		var step_mesh := BoxMesh.new()
		step_mesh.size = Vector3(2.8, 0.05, 3.8)
		stone_step.mesh = step_mesh
		stone_step.material_override = path_mat
		stone_step.position = Vector3(float(dist_x), 0.02, -75.0)
		add_child(stone_step)

	# 2. Arena Master Podium & Kassandros NPC
	var podium_mat := StandardMaterial3D.new()
	podium_mat.albedo_color = Color(0.40, 0.38, 0.35)
	podium_mat.roughness = 0.85

	var podium := MeshInstance3D.new()
	var p_cyl := CylinderMesh.new()
	p_cyl.top_radius = 1.4
	p_cyl.bottom_radius = 1.6
	p_cyl.height = 0.4
	podium.mesh = p_cyl
	podium.material_override = podium_mat
	podium.position = MASTER_POS + Vector3(0.0, 0.2, 0.0)
	add_child(podium)

	# Weapon rack & shield next to podium
	var wrack_sc := load("res://assets/world/decoration/props/weaponrack.gltf") as PackedScene
	if wrack_sc != null:
		var wrack := wrack_sc.instantiate() as Node3D
		wrack.scale = Vector3.ONE * 1.4
		wrack.position = MASTER_POS + Vector3(-1.8, 0.0, 0.5)
		wrack.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		add_child(wrack)

	# Master NPC: Kassandros
	_master_npc = Npc.new()
	_master_npc.set("npc_id", "kassandros")
	_master_npc.set("rest_yaw", deg_to_rad(90.0))
	_master_npc.position = MASTER_POS + Vector3(0.0, 0.4, 0.0)
	add_child(_master_npc)

	# 3. Interactive Spot at Podium
	var spot := InteractSpot.make("", func(player: Player):
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree != null:
			tree.call_group("hud", "open_arena", self, player)
			Sfx.ui("window_open")
	, 4.0)
	spot.prompt_func = func() -> String:
		return "[R] Κάσσανδρος ο Επιστάτης της Αρένας (Δοκιμασίες Μονομάχων)"
	spot.position = MASTER_POS + Vector3(0.0, 0.4, 0.0)
	add_child(spot)

	# 4. Arena Grand Signpost
	var sign_sc := load("res://assets/world/decoration/props/resource_stone.gltf") as PackedScene
	var sign_holder := Node3D.new()
	sign_holder.position = SIGN_POS
	sign_holder.rotation_degrees = Vector3(0.0, 75.0, 0.0)
	add_child(sign_holder)

	var sign_label := Label3D.new()
	sign_label.text = Strings.ARENA_SIGNPOST
	sign_label.font_size = 40
	sign_label.pixel_size = 0.0075
	sign_label.outline_size = 12
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.modulate = Color(1.0, 0.90, 0.40)
	sign_label.position = Vector3(0.0, 2.2, 0.0)
	sign_label.no_depth_test = true
	sign_holder.add_child(sign_label)


# =========================================================================
# 3. GATE OPEN / CLOSE LOGIC
# =========================================================================
func _open_gate(instant: bool = false) -> void:
	_gate_open = true
	if _portcullis != null:
		var target_y := 3.8
		if instant:
			_portcullis.position.y = target_y
		else:
			var tw := create_tween()
			tw.tween_property(_portcullis, "position:y", target_y, 1.2)
	if _portcullis_body != null:
		_portcullis_body.process_mode = Node.PROCESS_MODE_DISABLED


func _close_gate(instant: bool = false) -> void:
	_gate_open = false
	if _portcullis != null:
		var target_y := 0.0
		if instant:
			_portcullis.position.y = target_y
		else:
			var tw := create_tween()
			tw.tween_property(_portcullis, "position:y", target_y, 0.6)
	if _portcullis_body != null:
		_portcullis_body.process_mode = Node.PROCESS_MODE_INHERIT


# =========================================================================
# 4. TRIAL COMBAT FLOW & WAVE MANAGEMENT
# =========================================================================
func start_trial(trial_id: String, player: Player) -> bool:
	if trial_active:
		return false
	var chk := ArenaDataClass.can_start(trial_id, player.level, player.gold, completed_trials)
	if not chk["ok"]:
		player.message.emit(chk["reason"])
		Sfx.ui("error")
		return false

	var trial := ArenaDataClass.get_trial(trial_id)
	var fee: int = int(trial["fee"])
	if fee > 0:
		player.gold -= fee
		player.inventory_changed.emit(player.gold, player.potions)

	_player = player
	trial_active = true
	current_trial_id = trial_id
	current_wave = 0
	total_waves = (trial["waves"] as Array).size()
	_active_mobs.clear()

	# Remove previous victory chest if any
	if is_instance_valid(_victory_chest):
		_victory_chest.queue_free()

	# Move player safely inside fighting pit
	player.global_position = CENTER + Vector3(-7.5, 0.05, 0.0)
	player.set_heading(0.0, true)

	_close_gate()
	Sfx.ui("invasion_horn")
	Sfx.ui("crowd_cheer")

	trial_started.emit(trial_id)
	_player.message.emit("Ξεκίνησε: %s!" % trial["title"])

	# Connect death listener
	if not _player.died.is_connected(_on_player_died):
		_player.died.connect(_on_player_died)

	get_tree().create_timer(1.8).timeout.connect(_spawn_next_wave)
	return true


func _spawn_next_wave() -> void:
	if not trial_active:
		return
	var trial := ArenaDataClass.get_trial(current_trial_id)
	var waves: Array = trial["waves"]
	if current_wave >= waves.size():
		_on_trial_victorious()
		return

	var wave_data: Dictionary = waves[current_wave]
	current_wave += 1

	var banner_text := Strings.ARENA_WAVE_BANNER % [trial["title"], current_wave, total_waves]
	if wave_data.get("is_boss", false):
		banner_text = "⚔️ ΠΡΩΤΑΘΛΗΤΗΣ ΑΡΕΝΑΣ: %s!" % wave_data.get("boss_name", "Πρωταθλητής")
		Sfx.ui("boss_roar")

	_player.message.emit(banner_text)
	Sfx.ui("wave_horn" if SfxIds.VARIANTS.has("wave_horn") else "invasion_horn")
	wave_started.emit(current_wave, total_waves)

	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	var spawns: Array = wave_data["spawns"]

	for sp in spawns:
		var kind: String = sp["kind"]
		var spawn_pos: Vector3 = CENTER + sp["offset"]
		var enemy: Enemy = null
		if spawner != null and spawner.has_method("spawn_invader"):
			enemy = spawner.spawn_invader(kind, spawn_pos, _player.global_position)
		elif spawner != null and spawner.has_method("spawn_extra"):
			enemy = spawner.spawn_extra(kind, spawn_pos)

		if enemy != null:
			enemy.aggro_range = 45.0
			enemy.leash_range = 60.0
			enemy.add_to_group("arena_mobs")
			_active_mobs.append(enemy)
			enemy.died.connect(_on_mob_died.bind(enemy))

	mob_count_changed.emit(_active_mobs.size())


func _on_mob_died(_enemy: Enemy) -> void:
	_active_mobs = _active_mobs.filter(func(e): return is_instance_valid(e) and not e.is_dead())
	mob_count_changed.emit(_active_mobs.size())

	if _active_mobs.is_empty():
		Sfx.ui("crowd_cheer")
		if current_wave < total_waves:
			_player.message.emit("Το Κύμα %d εξουδετερώθηκε! Ετοιμάσου..." % current_wave)
			get_tree().create_timer(2.6).timeout.connect(_spawn_next_wave)
		else:
			_on_trial_victorious()


func _on_trial_victorious() -> void:
	if not trial_active:
		return
	trial_active = false
	var trial := ArenaDataClass.get_trial(current_trial_id)
	var reward: Dictionary = trial["reward"]

	if not completed_trials.has(current_trial_id):
		completed_trials.append(current_trial_id)

	_open_gate()
	Sfx.ui("quest_done")
	Sfx.ui("crowd_cheer")

	var vic_text := Strings.ARENA_VICTORY_BANNER % trial["title"]
	_player.message.emit(vic_text)

	var tree := get_tree() if is_inside_tree() else null
	if tree != null:
		tree.call_group("journal_manager", "report_stat", "arena_victories", 1)
		tree.call_group("journal_manager", "report_stat", "arena_" + current_trial_id, 1)

	# Apply Rewards
	if _player != null:
		_player.apply_reward(reward)

		# Add Arena Trophy to Junk Inventory
		if reward.has("trophy"):
			var trophy_id: String = reward["trophy"]
			_player.junk[trophy_id] = int(_player.junk.get(trophy_id, 0)) + 1
			_player.message.emit("Απέκτησες το %s!" % ShopData.JUNK[trophy_id]["name"])

		# Add Gladiator Champion Armor
		if reward.has("gear"):
			var gear_id: String = reward["gear"]
			if not _player.gear_owned.has(gear_id):
				_player.gear_owned.append(gear_id)
			_player.equipped["armor"] = gear_id
			_player._recalc()
			_player.message.emit("Εξοπλίστηκες: %s!" % ShopData.GEAR[gear_id]["name"])

		# Title Grant
		if reward.has("title"):
			var title_str: String = reward["title"]
			_player.message.emit("Νέος Τίτλος: «%s»!" % title_str)

	# Spawn Golden Victory Chest in Center of Sand Pit
	_spawn_gladiator_chest()

	trial_finished.emit(current_trial_id, true)
	current_trial_id = ""


func _spawn_gladiator_chest() -> void:
	if is_instance_valid(_victory_chest):
		_victory_chest.queue_free()

	_victory_chest = Node3D.new()
	_victory_chest.name = "GladiatorVictoryChest"
	_victory_chest.position = CENTER + Vector3(0.0, 0.08, 0.0)
	add_child(_victory_chest)

	var chest_sc := load("res://assets/items/chest.glb") as PackedScene
	if chest_sc != null:
		var c_mesh := chest_sc.instantiate() as Node3D
		c_mesh.scale = Vector3.ONE * 1.5
		_victory_chest.add_child(c_mesh)

	var spot := InteractSpot.make("[R] Σεντούκι του Πρωταθλητή", func(player: Player):
		if is_instance_valid(_victory_chest):
			Sfx.ui("chest_coins")
			player.message.emit("Άνοιξες το Σεντούκι του Πρωταθλητή!")
			_victory_chest.queue_free()
	, 3.5)
	spot.position = Vector3(0.0, 0.4, 0.0)
	_victory_chest.add_child(spot)


func _on_player_died() -> void:
	if not trial_active:
		return
	trial_active = false
	current_trial_id = ""
	_open_gate()

	for mob in _active_mobs:
		if is_instance_valid(mob):
			mob.queue_free()
	_active_mobs.clear()

	_player.message.emit(Strings.ARENA_DEFEAT_BANNER)
	trial_finished.emit("", false)


func _process(delta: float) -> void:
	_anim_clock += delta
	# Subtle flame flicker on arena torches
	for i in _torch_lights.size():
		var l := _torch_lights[i]
		if is_instance_valid(l):
			l.light_energy = 1.6 + sin(_anim_clock * 8.0 + float(i) * 1.5) * 0.22


# =========================================================================
# 5. PERSISTENCE (SAVE / LOAD)
# =========================================================================
func save_data() -> Dictionary:
	return {
		"completed_trials": completed_trials.duplicate(),
	}

func load_data(d: Dictionary) -> void:
	if d.has("completed_trials"):
		completed_trials = (d["completed_trials"] as Array).duplicate()
