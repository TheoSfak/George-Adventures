class_name Villager
extends CharacterBody3D
## An ordinary villager who makes the village feel alive. They wander around the
## square, stand in pairs chatting in speech bubbles, or sit in the tavern with a
## mug of beer. Talk to them with R for a bit of gossip (all Greek, see villager_data.gd).

enum Mode { WANDER, CHAT, SIT, STAND }

var display_name := ""
var model_path := "res://assets/characters/Rogue.glb"
var mode := Mode.WANDER
var partner: Villager = null          # CHAT: the one they talk to
var lead := false                     # CHAT: the leader of a pair starts the conversations
var talk_lines: Array = []            # what they tell George
var bubble_lines: Array = []          # SIT / STAND: things they say out loud now and then
var conversations: Array = VillagerData.CONVERSATIONS
var holds_mug := false
var rest_yaw := 0.0                   # which way they face (KayKit yaw: forward = (sin, 0, cos))
var wander_center := Vector2.ZERO
var wander_ring := Vector2(10.0, 26.0)  # min / max distance from the centre they stroll to
var sit_lift := 0.0                   # raise or lower a seated villager to match the seat

const WALK_SPEED := 1.5
const GRAVITY := 22.0
const MUG := "res://assets/characters/mug_full.gltf"

var _model_root: Node3D
var _anim: AnimationPlayer
var _bubble: Label3D
var _hud: Node
var _player: Player
var _target := Vector3.ZERO
var _wait := 0.0
var _talking := false
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO
var _bubble_tween: Tween
var _base_anim := "Idle"
var _sheltered := false
var _shelter_tween: Tween


func _ready() -> void:
	add_to_group("interactables")
	if mode == Mode.WANDER or mode == Mode.CHAT:
		add_to_group("villagers")       # these go indoors at night (set_sheltered)
	collision_layer = 16
	collision_mask = 1 if mode == Mode.WANDER else 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.6 if mode == Mode.SIT else 1.9
	shape.shape = capsule
	shape.position.y = 0.95 if mode != Mode.SIT else 0.8
	add_child(shape)

	_model_root = Node3D.new()
	add_child(_model_root)
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	_model_root.add_child(model)
	for n in model.find_children("*", "Node3D", true, false):
		if n.name in Npc.WEAPON_NODES:
			n.visible = false
	if holds_mug:
		_attach_mug(model)
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for a in ["Idle", "Walking_A", "Sit_Chair_Idle"]:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	_model_root.rotation.y = rest_yaw
	if mode == Mode.SIT:
		_model_root.position.y = sit_lift

	var tag := Label3D.new()
	tag.text = display_name
	tag.font_size = 40
	tag.pixel_size = 0.0068
	tag.outline_size = 12
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.86, 0.92, 1.0)
	tag.position.y = 2.4 if mode != Mode.SIT else 1.9
	tag.no_depth_test = true
	add_child(tag)

	_bubble = Label3D.new()
	_bubble.font_size = 44
	_bubble.pixel_size = 0.0075
	_bubble.outline_size = 16
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.modulate = Color(1.0, 0.97, 0.82)
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.width = 560.0
	_bubble.position.y = 3.05 if mode != Mode.SIT else 2.5
	_bubble.no_depth_test = true
	_bubble.visible = false
	add_child(_bubble)

	_last_pos = global_position
	match mode:
		Mode.WANDER:
			_set_base("Idle")
			_wait = randf_range(0.5, 5.0)
			_target = global_position
		Mode.CHAT:
			_set_base("Idle")
			if lead and partner != null:
				_chat_loop()
		Mode.SIT:
			_set_base("Sit_Chair_Idle")
			set_physics_process(false)
			_bubble_loop()
		Mode.STAND:
			_set_base("Idle")
			set_physics_process(false)
			_bubble_loop()
	if mode == Mode.CHAT:
		set_physics_process(false)


func _attach_mug(model: Node3D) -> void:
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or skeleton.find_bone("handslot.r") < 0:
		return
	var holder := BoneAttachment3D.new()
	holder.bone_name = "handslot.r"
	skeleton.add_child(holder)
	var mug := (load(MUG) as PackedScene).instantiate() as Node3D
	mug.scale = Vector3.ONE * 0.55
	holder.add_child(mug)


## At dusk the outdoor villagers go home (hidden, not talkable); at dawn they come back.
func set_sheltered(on: bool) -> void:
	if on == _sheltered:
		return
	_sheltered = on
	if _shelter_tween:
		_shelter_tween.kill()
	_shelter_tween = create_tween()
	if on:
		remove_from_group("interactables")
		collision_layer = 0
		_talking = false
		_shelter_tween.tween_property(_model_root, "scale", Vector3.ONE * 0.01, 0.6)
		_shelter_tween.tween_callback(func(): visible = false)
		set_physics_process(false)
	else:
		visible = true
		add_to_group("interactables")
		collision_layer = 16
		set_physics_process(mode == Mode.WANDER)
		_shelter_tween.tween_property(_model_root, "scale", Vector3.ONE, 0.6)


# ---------------------------------------------------------------- talking ----

## Shows a speech bubble over their head for a while.
func say(text: String, seconds: float = 3.5) -> void:
	Sfx.play("voice_blip", global_position, -6.0)
	_bubble.text = text
	_bubble.visible = true
	_bubble.modulate.a = 1.0
	if _bubble_tween:
		_bubble_tween.kill()
	_bubble_tween = create_tween()
	_bubble_tween.tween_interval(seconds)
	_bubble_tween.tween_property(_bubble, "modulate:a", 0.0, 0.5)
	_bubble_tween.tween_callback(func(): _bubble.visible = false)


func _chat_loop() -> void:
	await get_tree().create_timer(randf_range(0.5, 6.0)).timeout
	while is_inside_tree() and partner != null and is_instance_valid(partner):
		var convo: Array = conversations.pick_random()
		for i in convo.size():
			if not is_inside_tree() or partner == null or not is_instance_valid(partner):
				return
			var speaker: Villager = self if i % 2 == 0 else partner
			var line: String = convo[i]
			speaker.say(line, 2.4 + line.length() * 0.05)
			if randf() < 0.35:
				speaker.gesture(["Interact", "Taunt", "Cheer"][randi() % 3])
			await get_tree().create_timer(2.6 + line.length() * 0.055).timeout
		await get_tree().create_timer(randf_range(7.0, 16.0)).timeout


## Regulars say something out loud every now and then (and raise their mug for a toast).
func _bubble_loop() -> void:
	await get_tree().create_timer(randf_range(1.0, 9.0)).timeout
	while is_inside_tree():
		if not bubble_lines.is_empty():
			var line: String = bubble_lines.pick_random()
			say(line, 3.2)
			if mode == Mode.STAND and "υγειά" in line:
				gesture("Cheer")
		await get_tree().create_timer(randf_range(7.0, 17.0)).timeout


func gesture(anim_name: String) -> void:
	if _anim == null or not _anim.has_animation(anim_name) or mode == Mode.SIT:
		return
	_anim.play(anim_name, 0.15)
	await _anim.animation_finished
	if is_inside_tree():
		_anim.play(_base_anim, 0.2)


func interact_prompt() -> String:
	return Strings.PROMPT_TALK % display_name


func interact_range() -> float:
	return 3.6


func interact(_player_ref: Player) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or hud.is_dialogue_open():
		return
	_talking = true
	var line: String = talk_lines.pick_random() if not talk_lines.is_empty() else "…"
	hud.show_dialogue(display_name, [line], Callable())


# --------------------------------------------------------------- moving ----

func _set_base(anim_name: String) -> void:
	_base_anim = anim_name
	if _anim and _anim.has_animation(anim_name):
		_anim.play(anim_name, 0.2)


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		_hud = get_tree().get_first_node_in_group("hud")
		return
	if _talking:
		if _hud != null and not _hud.is_dialogue_open():
			_talking = false
		var to := _player.global_position - global_position
		_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(to.x, to.z), 1.0 - exp(-6.0 * delta))
	elif mode == Mode.CHAT and partner != null and is_instance_valid(partner):
		var to := partner.global_position - global_position
		_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(to.x, to.z), 1.0 - exp(-4.0 * delta))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if _talking:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if _wait > 0.0:
		_wait -= delta
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		if _base_anim != "Idle":
			_set_base("Idle")
		if _wait <= 0.0:
			var a := randf() * TAU
			var r := randf_range(wander_ring.x, wander_ring.y)
			_target = Vector3(wander_center.x + cos(a) * r, global_position.y, wander_center.y + sin(a) * r)
			_stuck_time = 0.0
	else:
		var to := _target - global_position
		to.y = 0.0
		if to.length() < 0.9:
			_wait = randf_range(3.0, 9.0)
		else:
			var dir := to.normalized()
			velocity.x = dir.x * WALK_SPEED
			velocity.z = dir.z * WALK_SPEED
			_model_root.rotation.y = lerp_angle(_model_root.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-7.0 * delta))
			if _base_anim != "Walking_A":
				_set_base("Walking_A")
			# stuck behind something: give up on this destination
			_stuck_time += delta
			if _stuck_time > 1.5:
				if global_position.distance_to(_last_pos) < 0.3:
					_wait = randf_range(0.5, 2.0)
				_last_pos = global_position
				_stuck_time = 0.0
	move_and_slide()
