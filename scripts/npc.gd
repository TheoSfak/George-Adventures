class_name Npc
extends StaticBody3D
## A villager who talks and gives quests. Data (name, model, dialogue) comes from
## quest_data.gd, quest state from the Quests autoload. Shows a gold "!" when it has
## a new quest and a green "?" when a finished quest can be handed in.

@export var npc_id := "stavros"
var rest_yaw := 0.0            # which way the NPC faces when George is not around

const WEAPON_NODES: Array[String] = [
	"1H_Axe", "1H_Axe_Offhand", "2H_Axe", "Barbarian_Round_Shield", "Mug", "Barbarian_Hat",
	"Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff",
	"Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable",
]

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
	for n in model.find_children("*", "Node3D", true, false):
		if n.name in WEAPON_NODES:
			n.visible = n.name in data["show"]
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

	Quests.changed.connect(_update_marker)
	_update_marker()


func _update_marker() -> void:
	var m := Quests.marker_for(npc_id)
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


func interact_prompt() -> String:
	if QuestData.NPCS[npc_id].has("shop"):
		return Strings.PROMPT_TRADE % QuestData.NPCS[npc_id]["name"]
	return Strings.PROMPT_TALK % QuestData.NPCS[npc_id]["name"]


func interact_range() -> float:
	return 5.5 if QuestData.NPCS[npc_id].has("shop") else 4.0   # shopkeepers stand behind a counter


func interact(player: Player) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or hud.is_dialogue_open():
		return
	var shop_id: String = QuestData.NPCS[npc_id].get("shop", "")
	if shop_id != "":
		var shop: Dictionary = ShopData.SHOPS[shop_id]
		hud.show_dialogue(QuestData.NPCS[npc_id]["name"], shop["greeting"], func(): hud.open_shop(shop_id, player))
		return
	var plan := Quests.dialogue_for(npc_id)
	hud.show_dialogue(plan["speaker"], plan["lines"], func(): Quests.finish_dialogue(plan))
