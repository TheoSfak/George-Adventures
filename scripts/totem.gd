class_name Totem
extends StaticBody3D
## A cursed bone totem that feeds the dead. It only stands in the world while a quest asks
## for it to be destroyed (quest "Τα Οστέινα Τοτέμ"), has a health bar, and breaks under
## George's sword like a skeleton would (the player damages every node in group "breakables").

const MODEL := "res://assets/graveyard/post_skull.gltf"
const SCALE := 1.7
const BAR_SIZE := Vector2i(64, 8)

@export var max_health := 90.0
var health := 0.0
var hit_radius := 1.0               # the player subtracts this from the distance (it is a thick post)

var _collider: CollisionShape3D
var _visual: Node3D
var _bar: Sprite3D
var _light: OmniLight3D
var _dying := false


func _ready() -> void:
	add_to_group("breakables")
	health = max_health
	collision_layer = 1
	collision_mask = 0
	_visual = (load(MODEL) as PackedScene).instantiate() as Node3D
	_visual.scale = Vector3.ONE * SCALE
	_visual.position.y = 1.29 * SCALE         # the model's origin is not at its foot
	add_child(_visual)
	_collider = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.9
	cyl.height = 8.0
	_collider.shape = cyl
	_collider.position.y = 4.0
	add_child(_collider)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.45, 1.0, 0.4)
	_light.light_energy = 2.4
	_light.omni_range = 12.0
	_light.position.y = 5.5
	add_child(_light)
	var tag := Label3D.new()
	tag.text = Strings.TOTEM_NAME
	tag.font_size = 44
	tag.pixel_size = 0.008
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(0.7, 1.0, 0.6)
	tag.position.y = 9.4
	tag.no_depth_test = true
	add_child(tag)
	_bar = Sprite3D.new()
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_bar.shaded = false
	_bar.pixel_size = 0.035
	_bar.position.y = 8.7
	add_child(_bar)
	_update_bar()
	Quests.changed.connect(_refresh)
	_refresh()


## Only there while a quest wants it destroyed.
func _refresh() -> void:
	if _dying:
		return
	var wanted := Quests.target_wanted("totem")
	visible = wanted
	_collider.set_deferred("disabled", not wanted)


func _update_bar() -> void:
	var img := Image.create(BAR_SIZE.x, BAR_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.05, 0.05, 0.9))
	var inner := BAR_SIZE - Vector2i(2, 2)
	img.fill_rect(Rect2i(1, 1, ceili(inner.x * clampf(health / max_health, 0.0, 1.0)), inner.y), Color(0.45, 0.9, 0.35))
	_bar.texture = ImageTexture.create_from_image(img)


func take_damage(amount: float, _from: Vector3, _knock: float = 0.0) -> void:
	if _dying or not visible:
		return
	health -= amount
	_update_bar()
	_light.light_energy = 4.0                  # flashes when hit
	create_tween().tween_property(_light, "light_energy", 2.4, 0.25)
	Sfx.play("sword_hit", global_position)
	if health <= 0.0:
		_destroy()


func _destroy() -> void:
	_dying = true
	_collider.set_deferred("disabled", true)
	SaveGame.note_totem(global_position)
	Sfx.play("skel_death", global_position)
	Sfx.play("orb_hit", global_position)
	var parent := get_parent()
	for i in 3:
		var coin := Pickup.make("gold", randi_range(4, 9))
		coin.position = global_position + Vector3(0, 1.5, 0)
		parent.add_child(coin)
	Quests.report_kill("totem")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_visual, "scale", Vector3(SCALE, 0.05, SCALE), 0.8)
	tween.tween_property(_light, "light_energy", 0.0, 0.6)
	tween.chain().tween_callback(queue_free)
