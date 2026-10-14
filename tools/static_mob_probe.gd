extends SceneTree
## Sizes and parts of the static models that can become creatures:
##   godot --path . --headless --script tools/static_mob_probe.gd
const MODELS := [
	"res://assets/graveyard/pumpkin_orange_jackolantern.gltf", "res://assets/graveyard/pumpkin_yellow_jackolantern.gltf",
	"res://assets/graveyard/pumpkin_orange.gltf", "res://assets/graveyard/ribcage.gltf", "res://assets/graveyard/skull.gltf",
	"res://assets/graveyard/bone_A.gltf", "res://assets/graveyard/bone_B.gltf", "res://assets/graveyard/bone_C.gltf",
	"res://assets/graveyard/tree_dead_medium.gltf", "res://assets/graveyard/tree_dead_large.gltf", "res://assets/graveyard/tree_dead_small.gltf",
	"res://assets/world/decoration/nature/rock_single_A.gltf", "res://assets/world/decoration/nature/rock_single_C.gltf",
	"res://assets/world/decoration/nature/rock_single_E.gltf",
	"res://assets/items/chest.glb", "res://assets/items/chest_gold.glb",
	"res://assets/graveyard/shrine.gltf", "res://assets/graveyard/shrine_candles.gltf", "res://assets/graveyard/candle_triple.gltf",
	"res://assets/graveyard/post_skull.gltf", "res://assets/graveyard/coffin_decorated.gltf",
]


func _initialize() -> void:
	for path in MODELS:
		var scene := load(path) as PackedScene
		if scene == null:
			print("MISSING ", path)
			continue
		var node := scene.instantiate() as Node3D
		root.add_child(node)
		var box := AABB()
		var first := true
		var names: Array[String] = []
		for m in node.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			var a := mi.global_transform * mi.mesh.get_aabb()
			box = a if first else box.merge(a)
			first = false
			names.append(String(mi.name))
		var anim := node.find_child("AnimationPlayer", true, false) != null
		print("%s: size %s, bottom y %.2f, anim %s, meshes %s" % [path.get_file(), str(box.size.snapped(Vector3.ONE * 0.01)), box.position.y, anim, str(names)])
		node.queue_free()
	quit(0)
