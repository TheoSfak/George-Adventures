class_name ParkourCourse
extends Node3D
## Roblox-Style Obby: "Το Πάρκουρ των Στεγών & του Μύλου" (Village Rooftop Parkour).
## Full obstacle course traversing tavern roofs, balance beams, tree canopies,
## jump pads, church bell tower balcony, moving sky platforms, and the windmill,
## culminating in the Acrobat's Trophy Chest and return launch pad.

signal course_started
signal checkpoint_passed(index: int, total: int)
signal course_completed(time_seconds: float, is_record: bool)

const SAVE_PATH := "user://parkour_best.json"
const TOTAL_CHECKPOINTS := 6

enum State { IDLE, RUNNING, FINISHED }

var state: State = State.IDLE
var elapsed_time: float = 0.0
var best_time: float = 0.0
var current_checkpoint: int = 0

const JumpPad = preload("res://scripts/jump_pad.gd")
const ParkourCheckpoint = preload("res://scripts/parkour_checkpoint.gd")
const ParkourMover = preload("res://scripts/parkour_mover.gd")

var _checkpoints: Array = []
var _checkpoint_transforms: Array[Transform3D] = []
var _jump_pads: Array = []
var _movers: Array = []

var _player: Player
var _start_area: Area3D
var _sign_label: Label3D
var _sign_body: StaticBody3D

# UI CanvasLayer
var _ui_layer: CanvasLayer
var _hud_panel: PanelContainer
var _hud_time_label: Label
var _hud_cp_label: Label
var _hud_best_label: Label
var _hud_hint_label: Label

var _trophy_chest: Chest
var _return_pad: JumpPad


func _init() -> void:
	name = "VillageParkourCourse"
	_load_best_time()
	_build_ui()
	_build_start_zone()
	_build_stage_1_tavern()
	_build_stage_2_canopy()
	_build_stage_3_nw_house()
	_build_stage_4_church_balcony()
	_build_stage_5_sky_flotilla()
	_build_stage_6_windmill()
	_build_stage_7_finish_podium()
	_connect_checkpoints()


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _player == null and get_tree() != null:
		_player = get_tree().get_first_node_in_group("player") as Player

	if state == State.RUNNING:
		elapsed_time += delta
		_update_hud()

		# Player fall detection (fell from rooftops or sky platforms to village ground)
		if _player != null and not _player.is_dead:
			if _player.global_position.y < 1.1:
				_on_player_fell()

			# Press [R] / action shortcut to respawn at current checkpoint
			if Input.is_action_just_pressed("action"):
				_respawn_at_checkpoint()


func _load_best_time() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var text := file.get_as_text()
			var json = JSON.parse_string(text)
			if json is Dictionary and json.has("best_time"):
				best_time = float(json["best_time"])


func _save_best_time(new_best: float) -> void:
	best_time = new_best
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		var data := {"best_time": best_time}
		file.store_string(JSON.stringify(data))


func _format_time(t: float) -> String:
	if t <= 0.0:
		return "--:--.-"
	var mins := int(t) / 60
	var secs := int(t) % 60
	var tenths := int((t - float(int(t))) * 10.0)
	return "%02d:%02d.%d" % [mins, secs, tenths]


# ---------------------------------------------------------------- Course Flow ----

func start_course() -> void:
	state = State.RUNNING
	elapsed_time = 0.0
	current_checkpoint = 0
	for cp in _checkpoints:
		if cp != null and cp.has_method("reset_state"):
			cp.reset_state()

	if _hud_panel != null:
		_hud_panel.visible = true
	_update_hud()
	if is_inside_tree():
		Sfx.ui("buy")
		get_tree().call_group("hud", "show_banner", Strings.PARKOUR_TITLE + " - " + Strings.PARKOUR_SUBTITLE, 2.5)
	course_started.emit()


func _on_checkpoint_reached(index: int, pos: Vector3, heading: float) -> void:
	if state != State.RUNNING:
		# If player touches checkpoint without starting, automatically start trial
		start_course()

	if index > current_checkpoint:
		current_checkpoint = index
		checkpoint_passed.emit(current_checkpoint, TOTAL_CHECKPOINTS)
		_update_hud()

		if current_checkpoint == TOTAL_CHECKPOINTS:
			_complete_course()
		else:
			var msg := Strings.PARKOUR_CHECKPOINT_REACHED % [current_checkpoint, TOTAL_CHECKPOINTS]
			if is_inside_tree():
				get_tree().call_group("hud", "show_banner", msg, 2.0)


func _on_player_fell() -> void:
	if state != State.RUNNING or _player == null:
		return
	elapsed_time += 3.0 # Fall penalty
	if is_inside_tree():
		Sfx.ui("error")
		get_tree().call_group("hud", "show_banner", Strings.PARKOUR_FALL_MSG, 2.0)
	_respawn_at_checkpoint()


func _respawn_at_checkpoint() -> void:
	if _player == null:
		return
	if current_checkpoint < _checkpoint_transforms.size():
		var t: Transform3D = _checkpoint_transforms[current_checkpoint]
		var heading := t.basis.get_euler().y
		_player.teleport(t.origin, heading)


func _complete_course() -> void:
	state = State.FINISHED
	var is_rec := (best_time <= 0.0 or elapsed_time < best_time)
	if is_rec:
		_save_best_time(elapsed_time)
		_refresh_sign_text()

	if is_inside_tree():
		var cp_pos: Vector3 = _checkpoints[_checkpoints.size() - 1].global_position if _checkpoints.size() > 0 else global_position
		Sfx.play("crowd_cheer", cp_pos, 4.0)
		var win_msg := Strings.PARKOUR_WIN_MSG % _format_time(elapsed_time)
		if is_rec:
			win_msg += "\n" + Strings.PARKOUR_NEW_RECORD
		get_tree().call_group("hud", "show_banner", win_msg, 5.0)

	_update_hud()
	course_completed.emit(elapsed_time, is_rec)


# ---------------------------------------------------------------- Start & Sign ----

func _build_start_zone() -> void:
	var start_pos := Vector3(-51.5, 0.0, -5.0)

	# Decorative Start Plinth Pad
	var plinth := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.8
	cyl.height = 0.15
	plinth.mesh = cyl
	plinth.position = start_pos + Vector3(0, 0.075, 0)
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.9, 0.75, 0.2)
	p_mat.emission_enabled = true
	p_mat.emission = Color(0.9, 0.75, 0.2)
	p_mat.emission_energy_multiplier = 0.8
	plinth.material_override = p_mat
	add_child(plinth)

	# Trigger area for starting course
	_start_area = Area3D.new()
	_start_area.position = start_pos
	var shape := CollisionShape3D.new()
	var c_shape := CylinderShape3D.new()
	c_shape.radius = 1.8
	c_shape.height = 1.5
	shape.shape = c_shape
	shape.position.y = 0.75
	_start_area.add_child(shape)
	_start_area.body_entered.connect(func(b):
		if b is Player and state != State.RUNNING:
			start_course()
	)
	add_child(_start_area)

	# Start Signpost
	var sign_pos := start_pos + Vector3(2.2, 0.0, 0.5)
	_sign_body = StaticBody3D.new()
	_sign_body.position = sign_pos

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.18, 2.2, 0.18)
	post.mesh = post_mesh
	post.position.y = 1.1
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	post.material_override = wood_mat
	_sign_body.add_child(post)

	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(2.0, 1.3, 0.1)
	board.mesh = board_mesh
	board.position.y = 1.8
	board.material_override = wood_mat
	_sign_body.add_child(board)

	_sign_label = Label3D.new()
	_sign_label.position = Vector3(0.0, 1.8, 0.06)
	_sign_label.pixel_size = 0.0055
	_sign_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sign_label.font_size = 32
	_sign_label.modulate = Color(1.0, 0.95, 0.8)
	_sign_body.add_child(_sign_label)
	_refresh_sign_text()

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.4, 0.3)
	col.shape = box
	col.position.y = 1.2
	_sign_body.add_child(col)
	add_child(_sign_body)

	# Store checkpoint 0 as start platform
	var t := Transform3D(Basis.from_euler(Vector3(0, PI * 0.75, 0)), start_pos + Vector3(0, 0.2, 0))
	_checkpoint_transforms.append(t)


func _refresh_sign_text() -> void:
	if _sign_label != null:
		_sign_label.text = Strings.PARKOUR_SIGN_TEXT % _format_time(best_time)


# ---------------------------------------------------------------- Course Geometry ----

func _make_box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.position.y = size.y * 0.5

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position.y = size.y * 0.5
	body.add_child(shape)

	add_child(body)
	return body


func _make_cylinder(pos: Vector3, radius: float, height: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos

	var mesh_inst := MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = radius
	cyl_mesh.bottom_radius = radius
	cyl_mesh.height = height
	mesh_inst.mesh = cyl_mesh
	mesh_inst.position.y = height * 0.5

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var shape := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = radius
	cyl_shape.height = height
	shape.shape = cyl_shape
	shape.position.y = height * 0.5
	body.add_child(shape)

	add_child(body)
	return body


func _add_checkpoint(pos: Vector3, index: int, heading: float) -> Node3D:
	var cp = ParkourCheckpoint.new()
	cp.position = pos
	cp.checkpoint_index = index
	cp.respawn_heading = heading
	add_child(cp)
	_checkpoints.append(cp)

	var t := Transform3D(Basis.from_euler(Vector3(0, heading, 0)), pos + Vector3(0, 0.25, 0))
	_checkpoint_transforms.append(t)
	return cp


func _add_jump_pad(pos: Vector3, power: float, forward: Vector3, col: Color = Color(0.15, 0.9, 1.0)) -> Node3D:
	var jp = JumpPad.new()
	jp.position = pos
	jp.launch_power = power
	jp.forward_kick = forward
	jp.pad_color = col
	add_child(jp)
	_jump_pads.append(jp)
	return jp


func _add_mover(pos: Vector3, offset: Vector3, dur: float, phase: float, size: Vector3, col: Color) -> Node3D:
	var m = ParkourMover.new()
	m.position = pos
	m.travel_offset = offset
	m.cycle_duration = dur
	m.phase_offset = phase
	m.platform_size = size
	m.neon_color = col
	add_child(m)
	_movers.append(m)
	return m


# Stage 1: Stack of crates & ramp to Tavern roof ridge (Checkpoint 1)
func _build_stage_1_tavern() -> void:
	var wood := Color(0.55, 0.35, 0.18)
	# Crates climbing up
	_make_box(Vector3(-53.8, 0.0, -5.5), Vector3(1.4, 0.8, 1.4), wood)
	_make_box(Vector3(-55.4, 0.0, -6.5), Vector3(1.4, 1.6, 1.4), wood)
	_make_box(Vector3(-57.0, 0.0, -7.8), Vector3(1.4, 2.5, 1.4), wood)

	# Scaffolding platform landing on Tavern eaves
	_make_box(Vector3(-58.6, 0.0, -9.0), Vector3(1.8, 3.6, 1.8), wood)
	_make_box(Vector3(-60.2, 0.0, -9.8), Vector3(2.4, 4.6, 2.4), wood)

	# Tavern Roof Ridge Walkway
	_make_box(Vector3(-60.0, 4.6, -12.5), Vector3(1.2, 0.3, 5.0), wood)

	# Checkpoint 1 on Tavern chimney ridge
	_add_checkpoint(Vector3(-60.0, 4.8, -15.5), 1, PI * 0.9)


# Stage 2: Balance beam across to Tree Canopy platform & stepping logs
func _build_stage_2_canopy() -> void:
	var wood := Color(0.48, 0.30, 0.15)
	var leaf_wood := Color(0.38, 0.45, 0.20)

	# Narrow balance beam heading North towards tree
	_make_box(Vector3(-58.5, 4.9, -19.5), Vector3(0.65, 0.25, 6.0), wood)
	_make_box(Vector3(-56.5, 5.2, -24.0), Vector3(0.65, 0.25, 4.0), wood)

	# Large Oak Tree canopy wooden ring platform
	_make_cylinder(Vector3(-54.0, 5.4, -28.0), 2.2, 0.3, leaf_wood)

	# Suspended Stepping Logs / Discs
	_make_cylinder(Vector3(-50.5, 5.6, -33.5), 0.85, 0.3, wood)
	_make_cylinder(Vector3(-47.0, 5.7, -38.5), 0.85, 0.3, wood)
	_make_cylinder(Vector3(-44.0, 5.6, -43.0), 0.85, 0.3, wood)


# Stage 3: NW House Roof, Checkpoint 2 & Jump Pad #1 to Church
func _build_stage_3_nw_house() -> void:
	var wood := Color(0.52, 0.34, 0.18)

	# NW House roof platform
	_make_box(Vector3(-41.0, 5.6, -47.6), Vector3(3.4, 0.3, 3.4), wood)

	# Checkpoint 2 on NW House Roof
	_add_checkpoint(Vector3(-41.0, 5.8, -46.5), 2, deg_to_rad(75.0))

	# Launch Ramp platform holding Jump Pad #1
	_make_box(Vector3(-36.5, 5.7, -50.5), Vector3(2.6, 0.3, 2.6), Color(0.25, 0.28, 0.32))

	# Jump Pad #1: Launches East towards the Church Bell Tower ledge!
	# Church is at (0, 0, -59), dx ≈ +35m, dy ≈ +6.5m, dz ≈ -9m
	_add_jump_pad(Vector3(-36.5, 5.9, -50.5), 22.5, Vector3(14.5, 0.0, -3.6), Color(0.1, 0.9, 1.0))


# Stage 4: Church Bell Tower cornice & Checkpoint 3
func _build_stage_4_church_balcony() -> void:
	var stone := Color(0.65, 0.62, 0.58)

	# Church West Cornice Landing Platform
	_make_box(Vector3(-6.5, 11.8, -58.5), Vector3(4.5, 0.4, 3.5), stone)

	# Narrow gothic parapet walkway along the Church Tower front
	_make_box(Vector3(-3.0, 11.9, -58.5), Vector3(3.5, 0.3, 1.2), stone)
	_make_box(Vector3(0.0, 12.0, -58.5), Vector3(3.0, 0.3, 2.5), stone)

	# Checkpoint 3 on Church Bell Tower ledge
	_add_checkpoint(Vector3(0.0, 12.2, -58.5), 3, PI)


# Stage 5: Sky Flotilla - Moving Platforms across the void to Windmill
func _build_stage_5_sky_flotilla() -> void:
	var sky_stone := Color(0.3, 0.35, 0.42)

	# Moving Platform 1 (North-South sliding obstacle)
	_add_mover(Vector3(-22.0, 12.4, -59.0), Vector3(0.0, 0.0, 8.5), 3.6, 0.0, Vector3(3.2, 0.35, 3.2), Color(1.0, 0.55, 0.1))

	# Intermediate Resting Sky-Dock (Checkpoint 4)
	_make_box(Vector3(-46.0, 12.2, -58.0), Vector3(3.6, 0.4, 3.6), sky_stone)
	_add_checkpoint(Vector3(-46.0, 12.5, -58.0), 4, PI * 0.5)

	# Moving Platform 2 (East-West & Vertical bobbing obstacle)
	_add_mover(Vector3(-68.0, 11.8, -57.0), Vector3(7.5, 2.4, 0.0), 4.2, 1.2, Vector3(3.2, 0.35, 3.2), Color(0.9, 0.2, 0.9))

	# Sky Jump Pad Platform
	_make_box(Vector3(-85.0, 10.8, -55.5), Vector3(2.8, 0.35, 2.8), Color(0.25, 0.28, 0.32))

	# Jump Pad #2: Launches West-North-West directly onto Windmill upper gallery!
	_add_jump_pad(Vector3(-85.0, 11.0, -55.5), 18.5, Vector3(-7.2, 0.0, 0.8), Color(1.0, 0.85, 0.1))


# Stage 6: Windmill Balcony, Spiral Gear Beams & Checkpoint 5
func _build_stage_6_windmill() -> void:
	var wood := Color(0.55, 0.38, 0.20)

	# Windmill Balcony Landing Deck
	_make_box(Vector3(-96.5, 9.8, -54.0), Vector3(3.5, 0.35, 3.5), wood)

	# Checkpoint 5 on Windmill Balcony
	_add_checkpoint(Vector3(-96.5, 10.1, -54.0), 5, deg_to_rad(135.0))

	# Ascending spiral timber beams around windmill wall
	_make_box(Vector3(-101.5, 11.4, -51.5), Vector3(2.2, 0.3, 1.2), wood)
	_make_box(Vector3(-104.5, 13.0, -54.8), Vector3(1.2, 0.3, 2.2), wood)
	_make_box(Vector3(-101.5, 14.6, -57.8), Vector3(2.2, 0.3, 1.2), wood)
	_make_box(Vector3(-98.0, 15.6, -55.0), Vector3(1.6, 0.3, 2.0), wood)


# Stage 7: Finish Sky Podium, Trophy Chest & Return Launcher
func _build_stage_7_finish_podium() -> void:
	var gold_podium := Color(0.72, 0.58, 0.22)
	var finish_pos := Vector3(-106.0, 16.4, -49.0)

	# Grand Sky Podium Platform
	_make_cylinder(finish_pos, 4.2, 0.5, gold_podium)

	# Decorative Golden Pillars
	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.9, 0.78, 0.3)
	pillar_mat.metallic = 0.6
	pillar_mat.roughness = 0.3

	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var p_pos := finish_pos + Vector3(cos(angle) * 3.6, 0.25, sin(angle) * 3.6)
		var pillar := MeshInstance3D.new()
		var p_mesh := CylinderMesh.new()
		p_mesh.top_radius = 0.22
		p_mesh.bottom_radius = 0.28
		p_mesh.height = 3.2
		pillar.mesh = p_mesh
		pillar.position = p_pos + Vector3(0, 1.6, 0)
		pillar.material_override = pillar_mat
		add_child(pillar)

	# Checkpoint 6 (Finish Line)
	_add_checkpoint(finish_pos + Vector3(0.0, 0.25, 0.0), 6, PI * 0.25)

	# Acrobat's Trophy Chest
	_trophy_chest = Chest.new()
	_trophy_chest.golden = true
	_trophy_chest.gold_min = 400
	_trophy_chest.gold_max = 600
	_trophy_chest.potions = 3
	_trophy_chest.position = finish_pos + Vector3(0.0, 0.5, -2.4)
	_trophy_chest.rotation_degrees.y = 180.0
	add_child(_trophy_chest)

	# Return Launch Pad (Teleports / Launches George straight back to the Village Well!)
	var ret_pos := finish_pos + Vector3(2.4, 0.25, 1.5)
	_return_pad = JumpPad.new()
	_return_pad.position = ret_pos
	_return_pad.launch_power = 24.0
	_return_pad.pad_color = Color(0.2, 1.0, 0.5)
	add_child(_return_pad)

	# Attach return teleport trigger to launch pad
	var ret_area := Area3D.new()
	ret_area.position = ret_pos
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.2
	cyl.height = 1.0
	shape.shape = cyl
	shape.position.y = 0.5
	ret_area.add_child(shape)
	ret_area.body_entered.connect(func(b):
		if b is Player:
			_teleport_home_safely(b as Player)
	)
	add_child(ret_area)


func _teleport_home_safely(p: Player) -> void:
	Sfx.play("crowd_cheer", p.global_position, 3.5)
	# Safely teleport George down to village square near the well
	p.teleport(Vector3(0.0, 0.5, 5.0), PI)
	get_tree().call_group("hud", "show_banner", "Επέστρεψες στην Πλατεία του Αγίου Βλάση!", 3.0)


func _connect_checkpoints() -> void:
	for cp in _checkpoints:
		cp.reached.connect(_on_checkpoint_reached)


# ---------------------------------------------------------------- HUD Overlay ----

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 15

	_hud_panel = PanelContainer.new()
	_hud_panel.visible = false
	_hud_panel.anchor_left = 0.5
	_hud_panel.anchor_right = 0.5
	_hud_panel.offset_left = -160.0
	_hud_panel.offset_right = 160.0
	_hud_panel.offset_top = 22.0
	_hud_panel.offset_bottom = 98.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.88)
	style.border_color = Color(0.9, 0.75, 0.2, 0.9)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	_hud_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_hud_time_label = Label.new()
	_hud_time_label.text = Strings.PARKOUR_HUD_TIME % "00:00.0"
	_hud_time_label.add_theme_font_size_override("font_size", 22)
	_hud_time_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	hbox.add_child(_hud_time_label)

	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 16.0
	hbox.add_child(sep)

	_hud_cp_label = Label.new()
	_hud_cp_label.text = Strings.PARKOUR_HUD_CP % [0, TOTAL_CHECKPOINTS]
	_hud_cp_label.add_theme_font_size_override("font_size", 20)
	_hud_cp_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	hbox.add_child(_hud_cp_label)

	vbox.add_child(hbox)

	var hbox2 := HBoxContainer.new()
	hbox2.alignment = BoxContainer.ALIGNMENT_CENTER

	_hud_best_label = Label.new()
	_hud_best_label.text = Strings.PARKOUR_HUD_BEST % _format_time(best_time)
	_hud_best_label.add_theme_font_size_override("font_size", 14)
	_hud_best_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox2.add_child(_hud_best_label)

	var sep2 := VSeparator.new()
	sep2.custom_minimum_size.x = 12.0
	hbox2.add_child(sep2)

	_hud_hint_label = Label.new()
	_hud_hint_label.text = Strings.PARKOUR_RESPAWN_PROMPT
	_hud_hint_label.add_theme_font_size_override("font_size", 13)
	_hud_hint_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	hbox2.add_child(_hud_hint_label)

	vbox.add_child(hbox2)
	_hud_panel.add_child(vbox)
	_ui_layer.add_child(_hud_panel)
	add_child(_ui_layer)


func _update_hud() -> void:
	if _hud_time_label != null:
		_hud_time_label.text = Strings.PARKOUR_HUD_TIME % _format_time(elapsed_time)
	if _hud_cp_label != null:
		_hud_cp_label.text = Strings.PARKOUR_HUD_CP % [current_checkpoint, TOTAL_CHECKPOINTS]
	if _hud_best_label != null:
		_hud_best_label.text = Strings.PARKOUR_HUD_BEST % _format_time(best_time)
