class_name Npc
extends StaticBody3D
## A villager who talks and gives quests. Data (name, model, dialogue) comes from
## quest_data.gd, quest state from the Quests autoload. Shows a gold "!" when it has
## a new quest and a green "?" when a finished quest can be handed in.

@export var npc_id := "stavros"
var rest_yaw := 0.0            # which way the NPC faces when George is not around

var _model_root: Node3D
var _anim: AnimationPlayer
var _marker: Label3D
var _player: Player
var _time := 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("npcs")
	collision_layer = 16
	collision_mask = 0
	var data: Dictionary = QuestData.NPCS[npc_id]

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.9
	shape.shape = capsule
	shape.position.y = 0.95
	add_child(shape)

	_model_root = Node3D.new()
	add_child(_model_root)
	var model := (load(data["model"]) as PackedScene).instantiate() as Node3D
	_model_root.add_child(model)
	CharacterProps.apply(model, data["show"])
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim and _anim.has_animation("Idle"):
		_anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		_anim.play("Idle")
	_model_root.rotation.y = rest_yaw

	var tag := Label3D.new()
	tag.text = data["name"]
	tag.font_size = 44
	tag.pixel_size = 0.0075
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(1, 0.96, 0.85)
	tag.position.y = 2.45
	tag.no_depth_test = true
	add_child(tag)

	_marker = Label3D.new()
	_marker.font_size = 140
	_marker.pixel_size = 0.0075
	_marker.outline_size = 24
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.position.y = 3.35
	_marker.no_depth_test = true
	add_child(_marker)

	var q: Node = get_node_or_null("/root/Quests")
	if q and q.has_signal("changed"):
		q.changed.connect(_update_marker)
	_update_marker()


func _update_marker() -> void:
	var q: Node = get_node_or_null("/root/Quests")
	var m: String = ""
	if q and q.has_method("marker_for"):
		m = q.marker_for(npc_id)
	_marker.text = m
	_marker.visible = m != ""
	_marker.modulate = Color(0.55, 1.0, 0.5) if m == "?" else Color(1.0, 0.85, 0.2)


func _process(delta: float) -> void:
	_time += delta
	if _marker.visible:
		_marker.position.y = 3.35 + sin(_time * 3.0) * 0.12
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	# Turn toward George when he is close.
	var to := _player.global_position - global_position
	to.y = 0.0
	var target := rest_yaw
	if to.length() < 9.0:
		target = atan2(to.x, to.z)
	_model_root.rotation.y = lerp_angle(_model_root.rotation.y, target, 1.0 - exp(-5.0 * delta))


## A short hurt reaction, then back to idle (Andreas while the skeletons hit him).
func flinch() -> void:
	if _anim and _anim.has_animation("Hit_A"):
		_anim.play("Hit_A", 0.1)
		_anim.animation_finished.connect(func(_n): if is_inside_tree(): _anim.play("Idle", 0.2), CONNECT_ONE_SHOT)


## The NPC dies: no more talking, falls, sinks into the ground and disappears.
func fall() -> void:
	remove_from_group("interactables")
	remove_from_group("npcs")
	set_process(false)
	_marker.visible = false
	var q: Node = get_node_or_null("/root/Quests")
	if q and q.has_signal("changed") and q.changed.is_connected(_update_marker):
		q.changed.disconnect(_update_marker)
	if _anim and _anim.has_animation("Death_A"):
		_anim.play("Death_A", 0.1)
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(self, "position:y", position.y - 2.0, 1.5)
	tween.tween_callback(queue_free)


func interact_prompt() -> String:
	var q: Node = get_node_or_null("/root/Quests")
	if QuestData.NPCS[npc_id].has("shop"):
		if q and q.has_method("marker_for") and q.marker_for(npc_id) != "":
			return Strings.PROMPT_TALK % QuestData.NPCS[npc_id]["name"]
		return Strings.PROMPT_TRADE % QuestData.NPCS[npc_id]["name"]
	if QuestData.NPCS[npc_id].has("arena"):
		return "[R] %s (Δοκιμασίες Μονομάχων)" % QuestData.NPCS[npc_id]["name"]
	return Strings.PROMPT_TALK % QuestData.NPCS[npc_id]["name"]


func interact_range() -> float:
	return 5.5 if (QuestData.NPCS[npc_id].has("shop") or QuestData.NPCS[npc_id].has("arena")) else 4.0


func interact(player: Player) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or hud.is_dialogue_open():
		return
	var q: Node = get_node_or_null("/root/Quests")
	var shop_id: String = QuestData.NPCS[npc_id].get("shop", "")
	if shop_id != "" and (q == null or not q.has_method("marker_for") or q.marker_for(npc_id) == ""):
		var shop: Dictionary = ShopData.SHOPS[shop_id]
		hud.show_dialogue(QuestData.NPCS[npc_id]["name"], shop["greeting"], func(): hud.open_shop(shop_id, player))
		return
	var arena_id: String = QuestData.NPCS[npc_id].get("arena", "")
	if arena_id != "" and (q == null or not q.has_method("marker_for") or q.marker_for(npc_id) == ""):
		var arena := get_tree().get_first_node_in_group("gladiator_arena")
		var greeting: Array = QuestData.NPCS[npc_id].get("greeting", ["Καλωσόρισες στην Αρένα!"])
		hud.show_dialogue(QuestData.NPCS[npc_id]["name"], greeting, func(): hud.open_arena(arena, player))
		return
	if q and q.has_method("dialogue_for"):
		var plan: Dictionary = q.dialogue_for(npc_id)
		hud.show_dialogue(plan["speaker"], plan["lines"], func():
			q.finish_dialogue(plan)
			if shop_id != "" and q.marker_for(npc_id) == "":
				hud.open_shop(shop_id, player)
		)
