class_name BlacksmithForge
extends Node3D
## Interactive 3D Blacksmith Forge Station (Village Square Forecourt & Workshop Interior).
## Features stone hearth furnace with glowing burning embers and flickering light,
## heavy steel anvil with horn on sturdy oak stump, water quenching basin with steam,
## red-hot heated billet, hammer and tongs rack.
## Allows George to forge unique masterwork weapons/armor and upgrade gear up to +5.

var forge_title := "Αμόνι & Καμίνι του Νικήτα"
var _model: Node3D
var _anim_clock := 0.0
var _fire_light: OmniLight3D
var _coal_mesh: MeshInstance3D
var _steam_mesh: MeshInstance3D
var _ingot_mesh: MeshInstance3D

func _ready() -> void:
	name = "BlacksmithForge"
	add_to_group("interactables")
	add_to_group("blacksmith")

	_build_forge_visuals()


func _build_forge_visuals() -> void:
	_model = Node3D.new()
	_model.name = "ForgeModel"
	add_child(_model)

	# --- Materials ---
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.28, 0.29, 0.31)
	stone_mat.roughness = 0.95

	var dark_brick_mat := StandardMaterial3D.new()
	dark_brick_mat.albedo_color = Color(0.35, 0.32, 0.30)
	dark_brick_mat.roughness = 0.90

	var oak_bark_mat := StandardMaterial3D.new()
	oak_bark_mat.albedo_color = Color(0.25, 0.17, 0.11)
	oak_bark_mat.roughness = 0.95

	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.42, 0.44, 0.47)
	steel_mat.metallic = 0.92
	steel_mat.roughness = 0.28

	var polished_steel_mat := StandardMaterial3D.new()
	polished_steel_mat.albedo_color = Color(0.68, 0.70, 0.74)
	polished_steel_mat.metallic = 0.95
	polished_steel_mat.roughness = 0.18

	var copper_brass_mat := StandardMaterial3D.new()
	copper_brass_mat.albedo_color = Color(0.72, 0.52, 0.25)
	copper_brass_mat.metallic = 0.85
	copper_brass_mat.roughness = 0.35

	# 1. Base Stone Foundation Platform
	var base := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(3.2, 0.12, 2.6)
	base.mesh = b_mesh
	base.material_override = stone_mat
	base.position = Vector3(0.0, 0.06, 0.0)
	_model.add_child(base)

	# 2. Stone Hearth Furnace Chamber (Back Left)
	var furnace_pos := Vector3(-0.75, 0.0, -0.55)

	# Furnace lower stone body
	var f_base := MeshInstance3D.new()
	var fb_mesh := BoxMesh.new()
	fb_mesh.size = Vector3(1.35, 0.95, 1.1)
	f_base.mesh = fb_mesh
	f_base.material_override = dark_brick_mat
	f_base.position = furnace_pos + Vector3(0.0, 0.475, 0.0)
	_model.add_child(f_base)

	# Upper hood / chimney tapering up
	var hood := MeshInstance3D.new()
	var h_mesh := CylinderMesh.new()
	h_mesh.top_radius = 0.28
	h_mesh.bottom_radius = 0.65
	h_mesh.height = 1.6
	hood.mesh = h_mesh
	hood.material_override = dark_brick_mat
	hood.position = furnace_pos + Vector3(0.0, 1.75, 0.0)
	_model.add_child(hood)

	# Iron chimney chimney pipe cap
	var cap := MeshInstance3D.new()
	var c_mesh := CylinderMesh.new()
	c_mesh.top_radius = 0.32
	c_mesh.bottom_radius = 0.32
	c_mesh.height = 0.35
	cap.mesh = c_mesh
	cap.material_override = steel_mat
	cap.position = furnace_pos + Vector3(0.0, 2.65, 0.0)
	_model.add_child(cap)

	# Hearth Burning Coals & Embers
	_coal_mesh = MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.95, 0.20, 0.65)
	_coal_mesh.mesh = cm
	var coal_mat := StandardMaterial3D.new()
	coal_mat.albedo_color = Color(0.95, 0.30, 0.08)
	coal_mat.emission_enabled = true
	coal_mat.emission = Color(1.0, 0.38, 0.08)
	coal_mat.emission_energy_multiplier = 1.8
	_coal_mesh.material_override = coal_mat
	_coal_mesh.position = furnace_pos + Vector3(0.0, 0.98, 0.18)
	_model.add_child(_coal_mesh)

	# Warm Hearth Firelight
	_fire_light = OmniLight3D.new()
	_fire_light.light_color = Color(1.0, 0.46, 0.12)
	_fire_light.light_energy = 1.4
	_fire_light.omni_range = 5.5
	_fire_light.position = furnace_pos + Vector3(0.0, 1.35, 0.25)
	_fire_light.add_to_group("night_lights")
	_model.add_child(_fire_light)

	# Pile of iron ore chunks & charcoal on side of furnace
	for c_pos in [Vector3(-1.35, 0.16, 0.1), Vector3(-1.25, 0.22, -0.2), Vector3(-1.4, 0.14, -0.45)]:
		var rock := MeshInstance3D.new()
		var r_mesh := SphereMesh.new()
		r_mesh.radius = 0.15
		r_mesh.height = 0.24
		rock.mesh = r_mesh
		rock.material_override = stone_mat
		rock.position = c_pos
		_model.add_child(rock)

	# 3. Heavy Steel Anvil on Sturdy Oak Stump (Right Front)
	var anvil_pos := Vector3(0.65, 0.0, 0.25)

	# Oak Stump Pedestal
	var stump := MeshInstance3D.new()
	var st_mesh := CylinderMesh.new()
	st_mesh.top_radius = 0.38
	st_mesh.bottom_radius = 0.42
	st_mesh.height = 0.65
	stump.mesh = st_mesh
	stump.material_override = oak_bark_mat
	stump.position = anvil_pos + Vector3(0.0, 0.325, 0.0)
	_model.add_child(stump)

	# Steel Base & Waist of Anvil
	var anvil_body := MeshInstance3D.new()
	var ab_mesh := BoxMesh.new()
	ab_mesh.size = Vector3(0.62, 0.28, 0.32)
	anvil_body.mesh = ab_mesh
	anvil_body.material_override = steel_mat
	anvil_body.position = anvil_pos + Vector3(0.0, 0.79, 0.0)
	_model.add_child(anvil_body)

	# Polished Flat Face of Anvil
	var anvil_face := MeshInstance3D.new()
	var af_mesh := BoxMesh.new()
	af_mesh.size = Vector3(0.54, 0.06, 0.26)
	anvil_face.mesh = af_mesh
	anvil_face.material_override = polished_steel_mat
	anvil_face.position = anvil_pos + Vector3(0.0, 0.94, 0.0)
	_model.add_child(anvil_face)

	# Conical Anvil Horn (Projecting Forward-Right)
	var horn := MeshInstance3D.new()
	var h_cone := CylinderMesh.new()
	h_cone.top_radius = 0.02
	h_cone.bottom_radius = 0.12
	h_cone.height = 0.38
	horn.mesh = h_cone
	horn.material_override = steel_mat
	horn.position = anvil_pos + Vector3(0.46, 0.88, 0.0)
	horn.rotation.z = -PI / 2.0
	_model.add_child(horn)

	# Red-Hot Heated Billet / Ingot on Anvil Face
	_ingot_mesh = MeshInstance3D.new()
	var in_mesh := BoxMesh.new()
	in_mesh.size = Vector3(0.24, 0.05, 0.09)
	_ingot_mesh.mesh = in_mesh
	var ingot_mat := StandardMaterial3D.new()
	ingot_mat.albedo_color = Color(1.0, 0.45, 0.1)
	ingot_mat.emission_enabled = true
	ingot_mat.emission = Color(1.0, 0.48, 0.12)
	ingot_mat.emission_energy_multiplier = 1.5
	_ingot_mesh.material_override = ingot_mat
	_ingot_mesh.position = anvil_pos + Vector3(-0.05, 0.98, 0.0)
	_ingot_mesh.rotation.y = 0.25
	_model.add_child(_ingot_mesh)

	# Heavy Blacksmith Forging Hammer Resting on Anvil
	var hammer_head := MeshInstance3D.new()
	var hh_mesh := BoxMesh.new()
	hh_mesh.size = Vector3(0.16, 0.08, 0.08)
	hammer_head.mesh = hh_mesh
	hammer_head.material_override = steel_mat
	hammer_head.position = anvil_pos + Vector3(0.18, 1.01, -0.06)
	hammer_head.rotation.y = 0.45
	_model.add_child(hammer_head)

	var hammer_handle := MeshInstance3D.new()
	var hl_mesh := CylinderMesh.new()
	hl_mesh.top_radius = 0.02
	hl_mesh.bottom_radius = 0.025
	hl_mesh.height = 0.38
	hammer_handle.mesh = hl_mesh
	hammer_handle.material_override = oak_bark_mat
	hammer_handle.position = anvil_pos + Vector3(0.18, 0.98, 0.10)
	hammer_handle.rotation.x = PI / 2.2
	_model.add_child(hammer_handle)

	# 4. Quenching Water Trough / Basin (Right Back)
	var trough_pos := Vector3(0.65, 0.0, -0.75)

	var trough := MeshInstance3D.new()
	var tr_mesh := BoxMesh.new()
	tr_mesh.size = Vector3(1.15, 0.58, 0.65)
	trough.mesh = tr_mesh
	trough.material_override = oak_bark_mat
	trough.position = trough_pos + Vector3(0.0, 0.29, 0.0)
	_model.add_child(trough)

	# Metal rim bands
	var rim := MeshInstance3D.new()
	var rim_mesh := BoxMesh.new()
	rim_mesh.size = Vector3(1.18, 0.06, 0.68)
	rim.mesh = rim_mesh
	rim.material_override = copper_brass_mat
	rim.position = trough_pos + Vector3(0.0, 0.55, 0.0)
	_model.add_child(rim)

	# Translucent Water Surface
	var water := MeshInstance3D.new()
	var w_mesh := BoxMesh.new()
	w_mesh.size = Vector3(1.05, 0.04, 0.55)
	water.mesh = w_mesh
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.18, 0.42, 0.65, 0.80)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.1
	water.material_override = water_mat
	water.position = trough_pos + Vector3(0.0, 0.52, 0.0)
	_model.add_child(water)

	# Quenching Steam Mesh Disc
	_steam_mesh = MeshInstance3D.new()
	var stm_mesh := CylinderMesh.new()
	stm_mesh.top_radius = 0.35
	stm_mesh.bottom_radius = 0.15
	stm_mesh.height = 0.10
	_steam_mesh.mesh = stm_mesh
	var steam_mat := StandardMaterial3D.new()
	steam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	steam_mat.albedo_color = Color(0.92, 0.95, 1.0, 0.25)
	steam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_steam_mesh.material_override = steam_mat
	_steam_mesh.position = trough_pos + Vector3(0.0, 0.72, 0.0)
	_model.add_child(_steam_mesh)

	# Blacksmith Tongs Leaning Against Trough
	var tongs := MeshInstance3D.new()
	var tg_mesh := BoxMesh.new()
	tg_mesh.size = Vector3(0.04, 0.58, 0.08)
	tongs.mesh = tg_mesh
	tongs.material_override = steel_mat
	tongs.position = trough_pos + Vector3(-0.55, 0.38, 0.0)
	tongs.rotation.z = deg_to_rad(18.0)
	_model.add_child(tongs)

	# 5. Collision Body so George cannot walk through the solid forge station
	var body := StaticBody3D.new()
	body.name = "ForgeCollision"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.1, 1.8, 2.5)
	col.shape = box
	col.position = Vector3(0.0, 0.9, 0.0)
	body.add_child(col)
	add_child(body)


func _process(delta: float) -> void:
	_anim_clock += delta
	# Flickering warm forge firelight
	if _fire_light != null:
		var flicker := sin(_anim_clock * 11.0) * 0.12 + cos(_anim_clock * 21.0) * 0.08
		_fire_light.light_energy = 1.35 + flicker

	# Pulsing hot coals and heated ingot
	if _coal_mesh != null and _coal_mesh.material_override is StandardMaterial3D:
		var mat := _coal_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 1.6 + sin(_anim_clock * 4.5) * 0.35

	if _ingot_mesh != null and _ingot_mesh.material_override is StandardMaterial3D:
		var mat := _ingot_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 1.4 + sin(_anim_clock * 3.8 + 1.0) * 0.30

	# Rising steam pulsation
	if _steam_mesh != null:
		_steam_mesh.position.y = 0.72 + sin(_anim_clock * 2.2) * 0.06
		_steam_mesh.rotation.y += delta * 0.6


func interact_prompt() -> String:
	return "[R] Αμόνι & Καμίνι του Νικήτα (Σφυρηλάτηση & Ενισχύσεις)"


func interact_range() -> float:
	return 3.5


func interact(player: Player) -> void:
	if player == null:
		return
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		tree.call_group("hud", "open_shop", "blacksmith_forge", player)
