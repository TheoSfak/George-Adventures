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
			if current_checkpoint >= 1 and _player.global_position.y < 1.5:
				_on_player_fell()

			# Press [R] / interact shortcut to respawn at current checkpoint
			if Input.is_action_just_pressed("interact"):
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
	var start_pos := Vector3(-49.5, 0.0, -1.0)

	# Decorative Start Plinth Pad
	var plinth := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.8
	cyl.height = 0.15
	plinth.mesh = cyl
	plinth.position = start_pos + Vector3(0, 0.075, 0)
	var p_mat := StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.95, 0.8, 0.2)
	p_mat.emission_enabled = true
	p_mat.emission = Color(0.95, 0.8, 0.2)
	p_mat.emission_energy_multiplier = 0.9
	plinth.material_override = p_mat
	add_child(plinth)

	# Trigger area for starting course (detects Player layer 2)
	_start_area = Area3D.new()
	_start_area.collision_mask = 1 | 2
	_start_area.position = start_pos
	var shape := CollisionShape3D.new()
	var c_shape := CylinderShape3D.new()
	c_shape.radius = 2.0
	c_shape.height = 1.6
	shape.shape = c_shape
	shape.position.y = 0.8
	_start_area.add_child(shape)
	_start_area.body_entered.connect(func(b):
		if b is Player and state != State.RUNNING:
			start_course()
	)
	add_child(_start_area)

	# Start Signpost
	var sign_pos := start_pos + Vector3(2.5, 0.0, 0.0)
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
	board_mesh.size = Vector3(2.2, 1.3, 0.1)
	board.mesh = board_mesh
	board.position.y = 1.8
	board.material_override = wood_mat
	_sign_body.add_child(board)

	_sign_label = Label3D.new()
	_sign_label.position = Vector3(0.0, 1.8, 0.06)
	_sign_label.pixel_size = 0.0052
	_sign_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sign_label.font_size = 32
	_sign_label.modulate = Color(1.0, 0.95, 0.8)
	_sign_body.add_child(_sign_label)
	_refresh_sign_text()

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.4, 0.3)
	col.shape = box
	col.position.y = 1.2
	_sign_body.add_child(col)
	add_child(_sign_body)

	# InteractSpot so player can also start by walking up and pressing [R]
	var spot := InteractSpot.make(Strings.PARKOUR_TITLE, func(_p: Player):
		if state != State.RUNNING:
			start_course()
	, 3.2)
	spot.position = start_pos
	add_child(spot)

	# Store checkpoint 0 as start platform
	var t := Transform3D(Basis.from_euler(Vector3(0, PI, 0)), start_pos + Vector3(0, 0.2, 0))
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


# Stage 1: Wooden Ascent Stairs & Tavern North Catwalk (Checkpoint 1)
func _build_stage_1_tavern() -> void:
	var wood := Color(0.55, 0.35, 0.18)
	var deck_wood := Color(0.48, 0.30, 0.15)

	# Gentle 8-step wooden staircase along X = -49.5 (clear east of tavern wall at X = -53.12)
	var step_zs: Array[float] = [-2.5, -4.0, -5.5, -7.0, -8.5, -10.0, -11.5, -13.0]
	for i in step_zs.size():
		var sz: float = step_zs[i]
		var h: float = (i + 1) * 0.45
		_make_box(Vector3(-49.5, 0.0, sz), Vector3(2.4, h, 1.3), wood)

	# High Landing Terrace 1
	_make_box(Vector3(-49.5, 0.0, -15.0), Vector3(2.8, 4.05, 2.5), wood)

	# Transition walkway heading West to Tavern North Catwalk (North of tavern Z = -16.96)
	_make_box(Vector3(-52.0, 4.1, -18.5), Vector3(2.6, 0.3, 1.8), deck_wood)
	_make_box(Vector3(-56.0, 4.3, -18.5), Vector3(5.5, 0.3, 1.8), deck_wood)

	# Checkpoint 1 Deck
	_make_box(Vector3(-60.0, 4.4, -18.5), Vector3(3.4, 0.35, 3.4), wood)

	# Checkpoint 1
	_add_checkpoint(Vector3(-60.0, 4.6, -18.5), 1, PI)


# Stage 2: Balance beam across to Tree Canopy platform & stepping logs
func _build_stage_2_canopy() -> void:
	var wood := Color(0.48, 0.30, 0.15)
	var leaf_wood := Color(0.38, 0.45, 0.20)

	# Narrow balance beam heading North towards big tree
	_make_box(Vector3(-58.0, 4.8, -23.0), Vector3(0.85, 0.25, 6.0), wood)

	# Large Oak Tree canopy wooden ring platform
	_make_cylinder(Vector3(-54.0, 5.2, -28.5), 2.2, 0.35, leaf_wood)

	# Stepping Discs
	_make_cylinder(Vector3(-50.0, 5.5, -33.5), 0.95, 0.35, wood)
	_make_cylinder(Vector3(-45.5, 5.8, -37.5), 0.95, 0.35, wood)


# Stage 3: NW House South Gallery, Checkpoint 2 & Jump Pad #1 to Church
func _build_stage_3_nw_house() -> void:
	var wood := Color(0.52, 0.34, 0.18)

	# Gallery deck South of NW house (Z = -40.5, clear of house wall Z = -43.37)
	_make_box(Vector3(-41.0, 6.0, -40.5), Vector3(4.2, 0.35, 3.2), wood)

	# Checkpoint 2 on Gallery deck
	_add_checkpoint(Vector3(-41.0, 6.2, -40.5), 2, deg_to_rad(75.0))

	# Launch Ramp platform holding Jump Pad #1
	_make_box(Vector3(-34.0, 6.0, -41.0), Vector3(3.2, 0.35, 3.2), Color(0.25, 0.28, 0.32))

	# Jump Pad #1: Launches East-North-East towards Church Overlook terrace at (-9.5, 11.8, -48.0)!
	_add_jump_pad(Vector3(-34.0, 6.2, -41.0), 22.0, Vector3(14.5, 0.0, -4.1), Color(0.1, 0.9, 1.0))


# Stage 4: Church High Overlook & Checkpoint 3
func _build_stage_4_church_balcony() -> void:
	var stone := Color(0.65, 0.62, 0.58)

	# Church West Overlook Landing Terrace (X = -9.5 clear west of church X = -5.56, Z = -48.0 clear south of Z = -52.55)
	_make_box(Vector3(-9.5, 11.8, -48.0), Vector3(4.5, 0.4, 4.5), stone)

	# Checkpoint 3 on Church Overlook
	_add_checkpoint(Vector3(-9.5, 12.1, -48.0), 3, PI * 0.75)

	# Gothic Parapet Walkway extending westward into sky
	_make_box(Vector3(-15.0, 12.0, -49.0), Vector3(4.5, 0.35, 2.0), stone)


# Stage 5: Sky Flotilla - Moving Platforms across the void to Windmill
func _build_stage_5_sky_flotilla() -> void:
	var sky_stone := Color(0.3, 0.35, 0.42)

	# Moving Platform 1 (North-South sliding obstacle)
	_add_mover(Vector3(-26.0, 12.2, -50.0), Vector3(0.0, 0.0, 7.0), 3.6, 0.0, Vector3(3.5, 0.35, 3.5), Color(1.0, 0.55, 0.1))

	# Intermediate Resting Sky-Dock (Checkpoint 4)
	_make_box(Vector3(-46.0, 12.2, -50.0), Vector3(4.0, 0.4, 4.0), sky_stone)
	_add_checkpoint(Vector3(-46.0, 12.5, -50.0), 4, PI * 0.5)

	# Moving Platform 2 (East-West & Vertical bobbing obstacle)
	_add_mover(Vector3(-66.0, 12.0, -50.0), Vector3(6.0, 2.0, 0.0), 4.2, 1.2, Vector3(3.5, 0.35, 3.5), Color(0.9, 0.2, 0.9))

	# Sky Jump Pad Platform
	_make_box(Vector3(-84.0, 11.5, -48.0), Vector3(3.2, 0.35, 3.2), Color(0.25, 0.28, 0.32))

	# Jump Pad #2: Launches West towards Windmill South Gallery!
	_add_jump_pad(Vector3(-84.0, 11.7, -48.0), 18.5, Vector3(-8.8, 0.0, 1.2), Color(1.0, 0.85, 0.1))


# Stage 6: Windmill South Gallery, Spiral Beams & Checkpoint 5
func _build_stage_6_windmill() -> void:
	var wood := Color(0.55, 0.38, 0.20)

	# Windmill South Gallery Landing Deck (Z = -46.0 clear south of windmill Z = -49.58)
	_make_box(Vector3(-99.0, 11.5, -46.0), Vector3(4.2, 0.4, 4.2), wood)

	# Checkpoint 5 on Windmill South Gallery
	_add_checkpoint(Vector3(-99.0, 11.8, -46.0), 5, deg_to_rad(135.0))

	# Ascending timber beams along West side (X = -108.0 clear west of windmill X = -105.74)
	_make_box(Vector3(-108.0, 13.0, -48.0), Vector3(2.5, 0.35, 1.8), wood)
	_make_box(Vector3(-108.0, 14.5, -52.0), Vector3(2.5, 0.35, 1.8), wood)
	_make_box(Vector3(-108.0, 16.0, -56.0), Vector3(2.5, 0.35, 1.8), wood)


# Stage 7: Finish Sky Podium, Trophy Chest & Return Launcher
func _build_stage_7_finish_podium() -> void:
	var gold_podium := Color(0.72, 0.58, 0.22)
	var finish_pos := Vector3(-108.0, 17.0, -62.0)

	# Grand Sky Podium Platform (clear north of windmill Z = -58.39)
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
	ret_area.collision_mask = 1 | 2
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
