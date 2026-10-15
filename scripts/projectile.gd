class_name Projectile
extends Node3D
## An arrow (skeleton archers) or a magic orb (skeleton mages; blue souls, orange fire). Flies straight, stops at
## walls, and hurts George when it reaches him. Blocking works against it like any hit.

const ARROW := "res://assets/characters/skeleton_weapons/Skeleton_Arrow.gltf"

var kind := "arrow"
var velocity := Vector3.ZERO
var damage := 10.0
var slows := false              # a hit also slows George down (soul collectors)

var _life := 4.0
var _player: Player


static func make(projectile_kind: String, from: Vector3, direction: Vector3, speed: float, dmg: float) -> Projectile:
	var p := Projectile.new()
	p.kind = projectile_kind
	p.velocity = direction.normalized() * speed
	p.damage = dmg
	p.position = from
	return p


func _ready() -> void:
	if kind == "arrow":
		var model := (load(ARROW) as PackedScene).instantiate() as Node3D
		model.scale = Vector3.ONE * 2.2
		model.rotation.x = -PI / 2.0     # the model lies along Y, we fly along -Z
		add_child(model)
	else:
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		orb.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.45, 0.72, 1.0) if kind == "soul" else (Color(1.0, 0.55, 0.12) if kind == "fire" else Color(0.65, 1.0, 0.45))
		orb.material_override = mat
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(orb)
		var glow := OmniLight3D.new()
		glow.light_color = Color(0.40, 0.65, 1.0) if kind == "soul" else (Color(1.0, 0.5, 0.15) if kind == "fire" else Color(0.55, 1.0, 0.4))
		glow.light_energy = 1.8
		glow.omni_range = 6.0
		add_child(glow)
	if velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	var from := global_position
	var to := from + velocity * delta
	# stop at walls, rocks and buildings
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		Sfx.play("arrow_hit" if kind == "arrow" else "orb_hit", global_position, -3.0)
		queue_free()
		return
	global_position = to
	if _player != null and not _player.is_dead:
		var chest := _player.global_position + Vector3.UP * 1.0
		if to.distance_to(chest) < 0.95:
			# `from` lies behind the shot so knockback and blocking use the flight direction
			_player.take_damage(damage, _player.global_position - velocity.normalized() * 3.0, true)
			if slows:
				_player.slow(2.5)
			Sfx.play("arrow_hit" if kind == "arrow" else "orb_hit", global_position)
			queue_free()
