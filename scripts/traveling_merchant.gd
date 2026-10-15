class_name TravelingMerchant
extends CharacterBody3D
## The traveling merchant ("Κυρ-Παντελής") roaming between village points of interest:
## the central well, the church, the tavern, the market, and the outskirts.
## Offers unique goods, exotic weapons, potions, and crafting materials.

const CHAR_MODEL := "res://assets/characters/Rogue_Hooded.glb"
const SPEED := 2.4
const ARRIVE_DIST := 1.2
const PAUSE_DURATION := 14.0

const WAYPOINTS: Array[Vector3] = [
	Vector3(12.0, 0.05, 10.0),    # Village Well
	Vector3(38.0, 0.05, 12.0),    # East Road
	Vector3(56.0, 0.05, -10.0),   # In front of Market
	Vector3(26.0, 0.05, -34.0),   # North-East Junction
	Vector3(-8.0, 0.05, -46.0),   # Church Square
	Vector3(-38.0, 0.05, -16.0),  # Tavern Junction
	Vector3(-55.0, 0.05, -8.0),   # In front of Tavern
	Vector3(-24.0, 0.05, 16.0),   # South Green
]

var _wp_index := 0
var _wait_timer := 0.0
var _model_root: Node3D
var _anim: AnimationPlayer
var _player: Player
var _busy := false

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("traveling_merchant")
	collision_layer = 16
	collision_mask = 1

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.9
	shape.shape = capsule
	shape.position.y = 0.95
	add_child(shape)

	_model_root = Node3D.new()
	add_child(_model_root)

	var scene := load(CHAR_MODEL) as PackedScene
	if scene:
		var model := scene.instantiate() as Node3D
		_model_root.add_child(model)
		CharacterProps.apply(model, ["Knife"])
		_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _anim and _anim.has_animation("Idle"):
			_anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
			_anim.play("Idle")
		if _anim and _anim.has_animation("Walking_A"):
			_anim.get_animation("Walking_A").loop_mode = Animation.LOOP_LINEAR

	var tag := Label3D.new()
	tag.text = "Κυρ-Παντελής\n(Πλανόδιος Έμπορος)"
	tag.font_size = 40
	tag.pixel_size = 0.0075
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(1.0, 0.88, 0.45)
	tag.position.y = 2.5
	tag.no_depth_test = true
	add_child(tag)

	if not WAYPOINTS.is_empty():
		global_position = WAYPOINTS[0]


func _physics_process(delta: float) -> void:
	if _busy:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player

	# If George is talking or very close, face him and pause
	if _player and global_position.distance_to(_player.global_position) < 3.2:
		var look_dir := _player.global_position - global_position
		look_dir.y = 0.0
		if look_dir.length() > 0.1:
			_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(look_dir.x, look_dir.z), 1.0 - exp(-6.0 * delta))
		_play_anim("Idle")
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		_play_anim("Idle")
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var target := WAYPOINTS[_wp_index]
	var to_target := target - global_position
	to_target.y = 0.0
	var dist := to_target.length()

	if dist <= ARRIVE_DIST:
		_wp_index = (_wp_index + 1) % WAYPOINTS.size()
		_wait_timer = PAUSE_DURATION
		_play_anim("Idle")
		velocity = Vector3.ZERO
	else:
		var dir := to_target.normalized()
		velocity = dir * SPEED
		_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-7.0 * delta))
		_play_anim("Walking_A")

	move_and_slide()


func _play_anim(anim_name: String) -> void:
	if _anim and _anim.has_animation(anim_name) and _anim.current_animation != anim_name:
		_anim.play(anim_name, 0.2)


func interact_prompt() -> String:
	return Strings.PROMPT_TALK % "Κυρ-Παντελής (Πλανόδιος Έμπορος)"


func interact_range() -> float:
	return 5.0


func interact(player: Player) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or hud.is_dialogue_open():
		return
	_busy = true
	var to := player.global_position - global_position
	to.y = 0.0
	if to.length() > 0.1:
		_model_root.rotation.y = atan2(to.x, to.z)
	_play_anim("Idle")
	var shop: Dictionary = ShopData.SHOPS["wandering"]
	hud.show_dialogue("Κυρ-Παντελής", shop["greeting"], func():
		_busy = false
		hud.open_shop("wandering", player)
	)
