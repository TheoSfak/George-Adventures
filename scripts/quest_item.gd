class_name QuestItem
extends Node3D
## An item a quest asks for (a stolen wine barrel, a blacksmith's key...). It is only
## visible while an active quest still needs it, shines with a tall golden beam so it
## can be spotted from far away, and is picked up by walking into it.

const MODELS := {
	"keg": {"path": "res://assets/items/keg.gltf.glb", "scale": 0.7, "lift": 0.0},
	"key": {"path": "res://assets/items/key.gltf.glb", "scale": 3.0, "lift": 1.2},
	"sack": {"path": "res://assets/world/decoration/props/sack.gltf", "scale": 12.0, "lift": 0.0},
	"log": {"path": "res://assets/world/decoration/props/resource_lumber.gltf", "scale": 5.0, "lift": 0.3},
	"page": {"path": "res://assets/furniture/book_single.gltf", "scale": 3.0, "lift": 0.9},
}

var item_id := "keg"

var _visual: Node3D
var _beam: MeshInstance3D
var _light: OmniLight3D
var _player: Player
var _time := 0.0


func _ready() -> void:
	add_to_group("quest_items")
	var def: Dictionary = MODELS[item_id]
	_visual = Node3D.new()
	_visual.position.y = def["lift"]
	add_child(_visual)
	var model := (load(def["path"]) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * def["scale"]
	_visual.add_child(model)

	_beam = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.6
	cyl.height = 40.0
	_beam.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.8, 0.25, 0.16)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam.material_override = mat
	_beam.position.y = 20.0
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.85, 0.4)
	_light.light_energy = 1.5
	_light.omni_range = 6.0
	_light.position.y = 1.5
	add_child(_light)

	Quests.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	visible = Quests.item_wanted(item_id)
	set_physics_process(visible)


func _physics_process(delta: float) -> void:
	_time += delta
	_visual.rotation.y += delta * 1.6
	_visual.position.y = MODELS[item_id]["lift"] + 0.2 + sin(_time * 2.5) * 0.12
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	if _player.is_dead:
		return
	if global_position.distance_to(_player.global_position) < 2.6:
		Quests.report_item(item_id)
		SaveGame.note_item(item_id, global_position)
		Sfx.ui("quest_item")
		_player.message.emit(QuestData.ITEMS[item_id])
		queue_free()
