class_name PlayerArrow
extends Node3D
## Projectile for George's Bows and Crossbows.
## Supports physical ballistic trajectory (gravity drop), environmental collision,
## critical hits, and special arrow types (normal, power, volley, fire).

const ARROW_MODEL := "res://assets/characters/skeleton_weapons/Skeleton_Arrow.gltf"

var arrow_type := "normal"     # "normal", "power", "volley", "fire"
var damage := 20.0
var crit_chance := 0.05
var velocity := Vector3.ZERO
var gravity := 9.8
var pierce_left := 0
var shooter: Player

var _life := 5.0
var _hit_targets: Array[Node] = []
var _model_node: Node3D

static func spawn(
	tree: SceneTree,
	type: String,
	from_pos: Vector3,
	dir: Vector3,
	speed: float,
	dmg: float,
	crit: float,
	p_shooter: Player = null
) -> Node:
	var arrow = (load("res://scripts/player_arrow.gd") as GDScript).new()
	arrow.arrow_type = type
	arrow.damage = dmg
	arrow.crit_chance = crit
	arrow.shooter = p_shooter
	arrow.velocity = dir.normalized() * speed
	arrow.position = from_pos
	if type == "power":
		arrow.gravity = 2.5
		arrow.pierce_left = 2
	elif type == "volley":
		arrow.gravity = 11.0
	elif type == "fire":
		arrow.gravity = 7.5
	else:
		arrow.gravity = 9.0

	var root := tree.current_scene
	if root == null:
		root = tree.root
	root.add_child(arrow)
	return arrow


func _ready() -> void:
	# Load KayKit arrow model
	var sc := load(ARROW_MODEL) as PackedScene
	if sc:
		_model_node = sc.instantiate() as Node3D
		_model_node.scale = Vector3.ONE * 2.2
		_model_node.rotation.x = -PI / 2.0
		add_child(_model_node)

	# Special VFX and lights for elemental / power arrows
	if arrow_type == "fire":
		var flame := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.22
		sphere.height = 0.44
		flame.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.45, 0.1)
		flame.material_override = mat
		add_child(flame)

		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, 0.4, 0.1)
		glow.light_energy = 2.2
		glow.omni_range = 5.0
		add_child(glow)
	elif arrow_type == "power":
		var energy := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.08
		cyl.height = 0.9
		energy.mesh = cyl
		energy.rotation.x = PI / 2.0
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.35, 0.85, 1.0)
		energy.material_override = mat
		add_child(energy)

		var glow := OmniLight3D.new()
		glow.light_color = Color(0.3, 0.8, 1.0)
		glow.light_energy = 2.0
		glow.omni_range = 4.5
		add_child(glow)
	elif arrow_type == "volley":
		var trail := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		trail.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.6, 0.95, 0.85)
		trail.material_override = mat
		add_child(trail)

	if is_inside_tree() and velocity.length_squared() > 0.01:
		look_at(global_position + velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return

	# Ballistic arc
	velocity.y -= gravity * delta
	if velocity.length_squared() > 0.01:
		look_at(global_position + velocity, Vector3.UP)

	var from_pos := global_position
	var to_pos := from_pos + velocity * delta

	# Check world static collision (walls, rocks, terrain)
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(from_pos, to_pos, 1) # Layer 1
	var hit := space.intersect_ray(ray)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider is Node and collider.is_in_group("breakables"):
			_hit_breakable(collider as Node, hit["position"])
		else:
			_hit_environment(hit["position"])
		return

	# Check enemies & targets along trajectory
	var hit_enemy := _check_enemy_hit(from_pos, to_pos)
	if hit_enemy:
		if pierce_left > 0:
			pierce_left -= 1
		else:
			queue_free()
			return

	global_position = to_pos


func _check_enemy_hit(from_pos: Vector3, to_pos: Vector3) -> bool:
	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("enemies"))
	candidates.append_array(get_tree().get_nodes_in_group("breakables"))

	var best_target: Node = null
	var best_dist := 1e9

	for target in candidates:
		if not is_instance_valid(target) or target in _hit_targets:
			continue
		var target_3d := target as Node3D
		if target_3d == null:
			continue
		if "is_dead" in target and target.get("is_dead"):
			continue

		var center := target_3d.global_position + Vector3.UP * 0.9
		# Approximate distance from line segment [from_pos, to_pos] to center
		var seg_v := to_pos - from_pos
		var seg_len := seg_v.length()
		if seg_len < 0.001:
			continue
		var seg_dir := seg_v / seg_len
		var t := clampf((center - from_pos).dot(seg_dir), 0.0, seg_len)
		var closest := from_pos + seg_dir * t
		var d := closest.distance_to(center)

		var hit_radius := 1.15
		if "model_scale" in target:
			hit_radius = maxf(0.8, float(target.get("model_scale")) * 1.1)

		if d <= hit_radius and t < best_dist:
			best_dist = t
			best_target = target

	if best_target != null:
		_apply_hit(best_target)
		return true

	return false


func _apply_hit(target: Node) -> void:
	_hit_targets.append(target)
	var is_crit := randf() < crit_chance
	var final_dmg := damage * (1.8 if is_crit else 1.0)

	var hit_dir := velocity.normalized()
	var from_dir := global_position - hit_dir * 2.0

	# Apply damage
	if target.has_method("take_damage"):
		target.call("take_damage", final_dmg, from_dir, true)
	elif target.has_method("hit"):
		target.call("hit", final_dmg)

	Sfx.play("arrow_hit", global_position)

	if is_crit:
		Sfx.play("sword_crit", global_position)
		if shooter != null and shooter.has_signal("message"):
			shooter.message.emit("Κρίσιμο Χτύπημα! (%.0f)" % final_dmg)

	# Special arrow effects
	if arrow_type == "fire":
		_explode_fire(global_position)
	elif arrow_type == "power":
		if target.has_method("apply_knockback"):
			target.call("apply_knockback", hit_dir * 10.0)
		elif target.has_method("stun"):
			target.call("stun", 1.5)


func _explode_fire(center: Vector3) -> void:
	Sfx.play("skill_flame", center)
	# AoE damage
	var radius := 4.5
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy in _hit_targets:
			continue
		var e3d := enemy as Node3D
		if e3d and e3d.global_position.distance_to(center) <= radius:
			_hit_targets.append(enemy)
			if enemy.has_method("take_damage"):
				enemy.call("take_damage", damage * 0.75, center, true)

	# Brief visual burst ring
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.8
	mesh.height = 3.6
	sphere.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.45, 0.1, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = mat
	sphere.global_position = center
	get_tree().current_scene.add_child(sphere)

	var tween := sphere.create_tween()
	tween.tween_property(sphere, "scale", Vector3.ONE * 2.5, 0.25)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tween.tween_callback(sphere.queue_free)


func _hit_breakable(b: Node, hit_pos: Vector3) -> void:
	if b.has_method("take_damage"):
		b.call("take_damage", damage)
	elif b.has_method("hit"):
		b.call("hit", damage)
	_hit_environment(hit_pos)


func _hit_environment(hit_pos: Vector3) -> void:
	Sfx.play("arrow_hit", hit_pos, -4.0)
	queue_free()
