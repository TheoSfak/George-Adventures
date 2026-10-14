extends SceneTree
## A contact sheet of the props that can become creatures:
##   godot --path . --resolution 1600x900 --script tools/mobmodelshot.gd -- <outdir>
var out := "."
const ROW1 := [
	["res://assets/world/decoration/nature/rock_single_A.gltf", 8.0], ["res://assets/world/decoration/nature/rock_single_B.gltf", 8.0],
	["res://assets/world/decoration/nature/rock_single_C.gltf", 8.0], ["res://assets/world/decoration/nature/rock_single_D.gltf", 8.0],
	["res://assets/world/decoration/nature/rock_single_E.gltf", 8.0],
]
const ROW2 := [
	["res://assets/graveyard/pumpkin_orange_jackolantern.gltf", 1.0], ["res://assets/graveyard/pumpkin_yellow_jackolantern.gltf", 1.0],
	["res://assets/graveyard/ribcage.gltf", 1.0], ["res://assets/graveyard/skull.gltf", 1.0], ["res://assets/graveyard/bone_C.gltf", 1.0],
	["res://assets/graveyard/tree_dead_small.gltf", 1.0], ["res://assets/graveyard/tree_dead_medium.gltf", 1.0],
	["res://assets/items/chest.glb", 1.0], ["res://assets/graveyard/shrine_candles.gltf", 1.0], ["res://assets/graveyard/post_skull.gltf", 1.0],
]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run()


func _place_row(models: Array, z: float, spacing: float) -> void:
	var x := -spacing * float(models.size() - 1) * 0.5
	for m in models:
		var node := (load(m[0]) as PackedScene).instantiate() as Node3D
		node.scale = Vector3.ONE * float(m[1])
		node.position = Vector3(x, 0, z)
		root.add_child(node)
		var label := Label3D.new()
		label.text = String(m[0]).get_file().get_basename()
		label.font_size = 40
		label.pixel_size = 0.01
		label.position = Vector3(x, 0.05, z + 1.6)
		label.rotation.x = -PI / 2.0
		root.add_child(label)
		x += spacing


func _run() -> void:
	await process_frame
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.3, 0.35)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	root.add_child(env)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 30)
	floor.mesh = plane
	root.add_child(floor)
	_place_row(ROW1, -5.0, 4.0)
	_place_row(ROW2, 3.0, 4.2)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 16, 15)
	cam.rotation_degrees = Vector3(-52, 0, 0)
	cam.fov = 55
	root.add_child(cam)
	await create_timer(0.5).timeout
	DirAccess.make_dir_recursive_absolute(out)
	root.get_viewport().get_texture().get_image().save_png("%s/model_sheet.png" % out)
	quit(0)
