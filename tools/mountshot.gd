extends SceneTree
## The stable, the rider and a gallop, screenshots and frame rate:
##   godot --path . --resolution 1920x1080 --script tools/mountshot.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


## A free camera for the pictures.
func _look(cam: Camera3D, target: Vector3, from: Vector3) -> void:
	cam.global_position = from
	cam.look_at(target, Vector3.UP)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	dn.running = false
	dn.set_time(12.0)
	p.max_health = 50000.0
	p.health = 50000.0
	p.horse_owned = true
	var cam := Camera3D.new()
	cam.fov = 60.0
	main.add_child(cam)
	cam.make_current()

	# the stable from the well side
	var stable := Vector3(63.0, 0.0, 53.0)
	var toward_well := Vector3(-stable.x, 0.0, -stable.z).normalized()
	p.teleport(stable + toward_well * 14.0 + Vector3(0, 0.05, 0), atan2(-toward_well.x, -toward_well.z))
	await create_timer(0.6).timeout
	_look(cam, stable + Vector3(0, 1.4, 0), stable + toward_well * 13.0 + Vector3(5.0, 4.5, 0))
	await shot("mount_stable")
	_look(cam, stable + toward_well * 4.0 + Vector3(0, 1.6, 0), stable + toward_well * 9.5 + Vector3(2.5, 2.2, 0))
	await shot("mount_keeper")

	# George in the saddle, standing, from the side and from the front
	p.teleport(Vector3(0, 0.05, 14), 0.0)
	await create_timer(0.5).timeout
	p.mount()
	await create_timer(0.8).timeout
	var at: Vector3 = p.global_position
	_look(cam, at + Vector3(0, 1.6, 0), at + Vector3(7.5, 2.2, 0.0))
	await shot("mount_side")
	_look(cam, at + Vector3(0, 1.6, 0), at + Vector3(5.0, 2.8, 5.5))
	await shot("mount_front")

	# a gallop across the square: the real player camera
	cam.queue_free()
	for c in p.find_children("*", "Camera3D", true, false):
		(c as Camera3D).make_current()
	Input.action_press("run")
	Input.action_press("move_forward")
	await create_timer(1.6).timeout
	await shot("mount_gallop")
	print("speed: ", Vector2(p.velocity.x, p.velocity.z).length(), "  fps galloping: ", Engine.get_frames_per_second())
	Input.action_release("move_forward")
	Input.action_release("run")
	await create_timer(0.4).timeout
	p.dismount()
	await create_timer(0.6).timeout
	print("on foot again: ", not p.mounted)
	quit()
