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
const TIME_LIMIT: float = 180.0 # 3 minutes

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
var _return_pad: Node3D
var _return_pad_disc: MeshInstance3D
var _return_pad_arrow: MeshInstance3D
var _return_pad_light: OmniLight3D
var _return_pad_beam: MeshInstance3D
var _return_trigger_area: Area3D
var _return_portal_active: bool = false
var _trophy_chest_opened: bool = false


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

		# 3-minute timeout (trial expires after 180s)
		if elapsed_time >= TIME_LIMIT:
			_on_time_expired()
			return

		# Manual respawn: press [R] / interact shortcut to respawn at current checkpoint
		if Input.is_action_just_pressed("interact"):
			_respawn_at_checkpoint()
	elif state == State.FINISHED:
		if not _return_portal_active and _trophy_chest != null and _trophy_chest.opened:
			_check_return_portal_activation()


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
	_return_portal_active = false
	_trophy_chest_opened = false
	_update_return_pad_visuals(false)
	if _trophy_chest != null and _trophy_chest.has_method("reset_chest"):
		_trophy_chest.reset_chest()
	for cp in _checkpoints:
		if cp != null and cp.has_method("reset_state"):
			cp.reset_state()

	if _hud_panel != null:
		_hud_panel.visible = true
	if _hud_hint_label != null:
		_hud_hint_label.text = Strings.PARKOUR_RESPAWN_PROMPT
		_hud_hint_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
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
			_check_return_portal_activation()
		else:
			var msg := Strings.PARKOUR_CHECKPOINT_REACHED % [current_checkpoint, TOTAL_CHECKPOINTS]
			if is_inside_tree():
				get_tree().call_group("hud", "show_banner", msg, 2.0)


func _respawn_at_checkpoint() -> void:
	if _player == null or state != State.RUNNING:
		return
	if current_checkpoint < _checkpoint_transforms.size():
		var t: Transform3D = _checkpoint_transforms[current_checkpoint]
		var heading := t.basis.get_euler().y
		_player.teleport(t.origin, heading)
		if is_inside_tree():
			Sfx.play("jump", t.origin, -1.0)
			var msg := Strings.PARKOUR_RESPAWN_BANNER % current_checkpoint
			get_tree().call_group("hud", "show_banner", msg, 1.5)


func _on_time_expired() -> void:
	state = State.IDLE
	elapsed_time = 0.0
	current_checkpoint = 0
	_return_portal_active = false
	_update_return_pad_visuals(false)
	for cp in _checkpoints:
		if cp != null and cp.has_method("reset_state"):
			cp.reset_state()
	if _hud_panel != null:
		_hud_panel.visible = false
	if is_inside_tree():
		Sfx.ui("error")
		get_tree().call_group("hud", "show_banner", Strings.PARKOUR_TIME_EXPIRED, 4.0)


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
		get_tree().call_group("journal_manager", "report_stat", "parkour_completed", 1)

	_update_hud()
	if _hud_hint_label != null:
		_hud_hint_label.text = Strings.PARKOUR_COMPLETED_STATUS
		_hud_hint_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

	# Auto-close HUD panel after 8 seconds of finishing
	var tw := create_tween()
	tw.tween_interval(8.0)
	tw.tween_callback(func():
		if state == State.FINISHED and _hud_panel != null:
			_hud_panel.visible = false
	)

	course_completed.emit(elapsed_time, is_rec)
	_check_return_portal_activation()


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

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	wood_mat.roughness = 0.85

	# Board: Width 2.6m, Height 1.3m, Depth 0.12m, Center Y = 1.8m
	# Board bottom is at Y = 1.8 - 0.65 = 1.15m
	var board_y := 1.8
	var board_h := 1.3
	var board_w := 2.6
	var board_d := 0.12
	var board_bottom := board_y - board_h * 0.5   # 1.15m

	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(board_w, board_h, board_d)
	board.mesh = board_mesh
	board.position = Vector3(0.0, board_y, 0.0)
	board.material_override = wood_mat
	_sign_body.add_child(board)

	# Post: stops exactly at the bottom of the board (Y = 1.15m)
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.18, board_bottom, 0.18)
	post.mesh = post_mesh
	post.position = Vector3(0.0, board_bottom * 0.5, 0.0)
	post.material_override = wood_mat
	_sign_body.add_child(post)

	_sign_label = Label3D.new()
	_sign_label.position = Vector3(0.0, board_y, board_d * 0.5 + 0.015)
	_sign_label.pixel_size = 0.0052
	_sign_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sign_label.double_sided = false
	_sign_label.font_size = 32
	_sign_label.outline_size = 8
	_sign_label.outline_modulate = Color(0.12, 0.08, 0.04)
	_sign_label.modulate = Color(1.0, 0.95, 0.8)
	_sign_body.add_child(_sign_label)
	_refresh_sign_text()

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(board_w, 2.4, 0.3)
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

	# Smooth ramp collider over tavern stairs for fluid walking traversal
	var stair_ramp := StaticBody3D.new()
	stair_ramp.position = Vector3(-49.5, 2.15, -7.9)
	stair_ramp.rotation.x = 0.3055
	stair_ramp.collision_layer = 1
	stair_ramp.collision_mask = 0
	var sr_col := CollisionShape3D.new()
	var sr_box := BoxShape3D.new()
	sr_box.size = Vector3(2.45, 0.25, 12.8)
	sr_col.shape = sr_box
	stair_ramp.add_child(sr_col)
	add_child(stair_ramp)

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
	var wood := Color(0.55, 0.38, 0.20)

	# Stepping stone from Church parapet towards Mover 1
	_make_cylinder(Vector3(-21.0, 12.0, -49.5), 1.1, 0.35, sky_stone)

	# Moving Platform 1 (North-South sliding obstacle)
	_add_mover(Vector3(-27.0, 12.1, -50.0), Vector3(0.0, 0.0, 4.5), 3.6, 0.0, Vector3(3.6, 0.35, 3.6), Color(1.0, 0.55, 0.1))

	# Stepping stones between Mover 1 and Checkpoint 4
	_make_cylinder(Vector3(-33.5, 12.0, -50.0), 1.1, 0.35, sky_stone)
	_make_cylinder(Vector3(-39.5, 12.0, -50.0), 1.1, 0.35, sky_stone)

	# Intermediate Resting Sky-Dock (Checkpoint 4)
	_make_box(Vector3(-46.0, 12.0, -50.0), Vector3(4.2, 0.4, 4.2), sky_stone)
	_add_checkpoint(Vector3(-46.0, 12.4, -50.0), 4, PI * 0.5)

	# Stepping Discs leading from Checkpoint 4 straight to Moving Platform 2
	_make_cylinder(Vector3(-52.0, 12.0, -50.0), 1.2, 0.35, wood)
	_make_cylinder(Vector3(-57.0, 12.0, -50.0), 1.2, 0.35, wood)

	# Moving Platform 2 (Moving Ramp across the chasm)
	_add_mover(Vector3(-63.0, 12.0, -50.0), Vector3(0.0, 1.2, 4.5), 3.8, 1.2, Vector3(3.8, 0.35, 3.8), Color(0.9, 0.2, 0.9))

	# Stepping Discs from Moving Platform 2 to Sky Jump Pad
	_make_cylinder(Vector3(-69.5, 11.9, -49.5), 1.2, 0.35, wood)
	_make_cylinder(Vector3(-75.5, 11.8, -49.0), 1.2, 0.35, wood)

	# Sky Jump Pad Platform
	_make_box(Vector3(-82.5, 11.5, -48.0), Vector3(3.6, 0.35, 3.6), Color(0.25, 0.28, 0.32))

	# Jump Pad #2: Launches West towards Windmill South Gallery!
	_add_jump_pad(Vector3(-82.5, 11.7, -48.0), 19.0, Vector3(-11.0, 0.0, 1.3), Color(1.0, 0.85, 0.1))


# Stage 6: Windmill South Gallery, Spiral Beams & Checkpoint 5
func _build_stage_6_windmill() -> void:
	var wood := Color(0.55, 0.38, 0.20)

	# Windmill South Gallery Landing Deck (Z = -46.0 clear south of windmill Z = -49.58)
	_make_box(Vector3(-99.0, 11.5, -46.0), Vector3(4.2, 0.4, 4.2), wood)

	# Checkpoint 5 on Windmill South Gallery
	_add_checkpoint(Vector3(-99.0, 11.8, -46.0), 5, deg_to_rad(135.0))

	# Intermediate gallery platforms wrapping around the South & SW corner to the West beams
	# Step 5A: South Mid timber platform
	_make_box(Vector3(-103.2, 12.2, -45.5), Vector3(2.6, 0.35, 2.4), wood)
	# Step 5B: South-West Corner timber landing
	_make_box(Vector3(-107.5, 12.9, -47.0), Vector3(2.6, 0.35, 2.4), wood)

	# Ascending timber beams along West side (X = -108.5 clear west of windmill)
	_make_box(Vector3(-108.5, 13.8, -51.0), Vector3(2.5, 0.35, 2.0), wood)
	_make_box(Vector3(-108.5, 14.8, -54.5), Vector3(2.5, 0.35, 2.0), wood)
	_make_box(Vector3(-108.0, 15.8, -58.0), Vector3(2.5, 0.35, 2.0), wood)


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
	_trophy_chest.chest_opened.connect(_on_trophy_chest_opened)
	add_child(_trophy_chest)

	# Return Teleport Pad (Teleports George back to the Village Square once trial & chest are complete)
	var ret_pos := finish_pos + Vector3(2.4, 0.25, 1.5)
	_build_return_portal(ret_pos)


func _build_return_portal(ret_pos: Vector3) -> void:
	_return_pad = Node3D.new()
	_return_pad.position = ret_pos
	add_child(_return_pad)

	# Base rim (dark carved stone / iron rim)
	var base := MeshInstance3D.new()
	var base_cyl := CylinderMesh.new()
	base_cyl.top_radius = 1.25
	base_cyl.bottom_radius = 1.35
	base_cyl.height = 0.2
	base.mesh = base_cyl
	base.position.y = 0.1
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.2, 0.22, 0.26)
	base_mat.metallic = 0.5
	base_mat.roughness = 0.5
	base.material_override = base_mat
	_return_pad.add_child(base)

	# Inner Rune Disc
	_return_pad_disc = MeshInstance3D.new()
	var pad_cyl := CylinderMesh.new()
	pad_cyl.top_radius = 1.0
	pad_cyl.bottom_radius = 1.05
	pad_cyl.height = 0.14
	_return_pad_disc.mesh = pad_cyl
	_return_pad_disc.position.y = 0.18
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(0.28, 0.26, 0.24)
	disc_mat.roughness = 0.3
	_return_pad_disc.material_override = disc_mat
	_return_pad.add_child(_return_pad_disc)

	# Arrow / Star Rune Glyph on top
	_return_pad_arrow = MeshInstance3D.new()
	var prism := BoxMesh.new()
	prism.size = Vector3(0.55, 0.04, 0.55)
	_return_pad_arrow.mesh = prism
	_return_pad_arrow.position.y = 0.26
	_return_pad_arrow.rotation_degrees.y = 45.0
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(0.35, 0.35, 0.38)
	_return_pad_arrow.material_override = arrow_mat
	_return_pad.add_child(_return_pad_arrow)

	# OmniLight beacon
	_return_pad_light = OmniLight3D.new()
	_return_pad_light.light_color = Color(0.2, 1.0, 0.6)
	_return_pad_light.light_energy = 0.0
	_return_pad_light.omni_range = 5.0
	_return_pad_light.position.y = 0.6
	_return_pad.add_child(_return_pad_light)

	# Vertical Light Beam (active only when conditions are fulfilled)
	_return_pad_beam = MeshInstance3D.new()
	var beam_cyl := CylinderMesh.new()
	beam_cyl.top_radius = 0.95
	beam_cyl.bottom_radius = 0.95
	beam_cyl.height = 8.0
	_return_pad_beam.mesh = beam_cyl
	_return_pad_beam.position.y = 4.1
	var beam_mat := StandardMaterial3D.new()
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.albedo_color = Color(0.2, 1.0, 0.6, 0.3)
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(0.2, 1.0, 0.6)
	beam_mat.emission_energy_multiplier = 1.8
	_return_pad_beam.material_override = beam_mat
	_return_pad_beam.visible = false
	_return_pad.add_child(_return_pad_beam)

	# Solid base collider so players can stand on the pad
	var static_body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 0.2, 2.4)
	col_shape.shape = box
	col_shape.position.y = 0.1
	static_body.add_child(col_shape)
	_return_pad.add_child(static_body)

	# Return Teleport Trigger Area
	_return_trigger_area = Area3D.new()
	_return_trigger_area.collision_mask = 1 | 2
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.2
	cyl.height = 1.0
	shape.shape = cyl
	shape.position.y = 0.5
	_return_trigger_area.add_child(shape)
	_return_trigger_area.body_entered.connect(_on_return_pad_entered)
	_return_pad.add_child(_return_trigger_area)


func _update_return_pad_visuals(active: bool) -> void:
	if _return_pad_disc != null and _return_pad_disc.material_override is StandardMaterial3D:
		var mat := _return_pad_disc.material_override as StandardMaterial3D
		if active:
			mat.albedo_color = Color(0.15, 0.95, 0.65)
			mat.emission_enabled = true
			mat.emission = Color(0.15, 0.95, 0.65)
			mat.emission_energy_multiplier = 2.2
		else:
			mat.albedo_color = Color(0.28, 0.26, 0.24)
			mat.emission_enabled = false

	if _return_pad_arrow != null and _return_pad_arrow.material_override is StandardMaterial3D:
		var a_mat := _return_pad_arrow.material_override as StandardMaterial3D
		if active:
			a_mat.albedo_color = Color.WHITE
			a_mat.emission_enabled = true
			a_mat.emission = Color.WHITE
			a_mat.emission_energy_multiplier = 2.5
		else:
			a_mat.albedo_color = Color(0.35, 0.35, 0.38)
			a_mat.emission_enabled = false

	if _return_pad_light != null:
		_return_pad_light.light_energy = 2.5 if active else 0.0

	if _return_pad_beam != null:
		_return_pad_beam.visible = active


func _on_trophy_chest_opened() -> void:
	_trophy_chest_opened = true
	_check_return_portal_activation()


func _check_return_portal_activation() -> void:
	if _return_portal_active:
		return
	var time_registered := (state == State.FINISHED or current_checkpoint >= TOTAL_CHECKPOINTS)
	var chest_done := (_trophy_chest != null and (_trophy_chest.opened or _trophy_chest_opened))
	if time_registered and chest_done:
		_activate_return_portal()


func _activate_return_portal() -> void:
	if _return_portal_active:
		return
	_return_portal_active = true
	_update_return_pad_visuals(true)
	if is_inside_tree():
		Sfx.ui("checkpoint_chime")
		get_tree().call_group("hud", "show_banner", Strings.PARKOUR_PORTAL_ACTIVE, 3.5)

	if _return_trigger_area != null:
		for b in _return_trigger_area.get_overlapping_bodies():
			if b is Player and not (b as Player).is_dead:
				get_tree().create_timer(0.3).timeout.connect(func():
					if _return_portal_active and is_instance_valid(b):
						_teleport_home_safely(b as Player)
				)
				break


func _on_return_pad_entered(body: Node3D) -> void:
	if not (body is Player):
		return
	var p: Player = body
	if p.is_dead:
		return

	var time_registered := (state == State.FINISHED or current_checkpoint >= TOTAL_CHECKPOINTS)
	var chest_done := (_trophy_chest != null and (_trophy_chest.opened or _trophy_chest_opened))

	if not time_registered:
		if is_inside_tree():
			Sfx.ui("error")
			get_tree().call_group("hud", "show_banner", Strings.PARKOUR_NEED_FINISH, 2.5)
		return

	if not chest_done:
		if is_inside_tree():
			Sfx.ui("error")
			get_tree().call_group("hud", "show_banner", Strings.PARKOUR_NEED_CHEST, 2.5)
		return

	_teleport_home_safely(p)


func _teleport_home_safely(p: Player) -> void:
	if _hud_panel != null:
		_hud_panel.visible = false
	if is_inside_tree():
		Sfx.play("crowd_cheer", p.global_position, 3.5)
		get_tree().call_group("hud", "show_banner", Strings.PARKOUR_RETURN_SUCCESS, 3.0)
	p.teleport(Vector3(0.0, 0.5, 5.0), PI)


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
	_hud_panel.offset_left = -170.0
	_hud_panel.offset_right = 170.0
	_hud_panel.offset_top = 18.0
	_hud_panel.offset_bottom = 114.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.90)
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
	style.content_margin_top = 6.0
	style.content_margin_bottom = 8.0
	_hud_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	# Header: Title & Close Button
	var top_bar := HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_lbl := Label.new()
	title_lbl.text = Strings.PARKOUR_TITLE
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(24, 22)
	close_btn.tooltip_text = Strings.PARKOUR_HUD_CLOSE_TOOLTIP
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.35, 0.35))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.18, 0.20, 0.26, 0.8)
	btn_style.set_corner_radius_all(6)
	btn_style.content_margin_left = 4
	btn_style.content_margin_right = 4
	btn_style.content_margin_top = 1
	btn_style.content_margin_bottom = 1
	close_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hov := btn_style.duplicate() as StyleBoxFlat
	btn_hov.bg_color = Color(0.35, 0.15, 0.15, 0.95)
	btn_hov.border_color = Color(1.0, 0.4, 0.4, 0.8)
	btn_hov.set_border_width_all(1)
	close_btn.add_theme_stylebox_override("hover", btn_hov)
	close_btn.pressed.connect(func():
		_hud_panel.visible = false
	)
	top_bar.add_child(close_btn)
	vbox.add_child(top_bar)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_hud_time_label = Label.new()
	_hud_time_label.text = Strings.PARKOUR_HUD_TIME % "03:00.0"
	_hud_time_label.add_theme_font_size_override("font_size", 20)
	_hud_time_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	hbox.add_child(_hud_time_label)

	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 16.0
	hbox.add_child(sep)

	_hud_cp_label = Label.new()
	_hud_cp_label.text = Strings.PARKOUR_HUD_CP % [0, TOTAL_CHECKPOINTS]
	_hud_cp_label.add_theme_font_size_override("font_size", 19)
	_hud_cp_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	hbox.add_child(_hud_cp_label)

	vbox.add_child(hbox)

	var hbox2 := HBoxContainer.new()
	hbox2.alignment = BoxContainer.ALIGNMENT_CENTER

	_hud_best_label = Label.new()
	_hud_best_label.text = Strings.PARKOUR_HUD_BEST % _format_time(best_time)
	_hud_best_label.add_theme_font_size_override("font_size", 13)
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
	var remaining: float = maxf(0.0, TIME_LIMIT - elapsed_time)
	if _hud_time_label != null:
		_hud_time_label.text = Strings.PARKOUR_HUD_TIME % _format_time(remaining)
		if remaining <= 30.0:
			var flash: bool = int(remaining * 4.0) % 2 == 0
			_hud_time_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25) if flash else Color(1.0, 0.7, 0.2))
		else:
			_hud_time_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	if _hud_cp_label != null:
		_hud_cp_label.text = Strings.PARKOUR_HUD_CP % [current_checkpoint, TOTAL_CHECKPOINTS]
	if _hud_best_label != null:
		_hud_best_label.text = Strings.PARKOUR_HUD_BEST % _format_time(best_time)
