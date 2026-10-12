extends SceneTree
## Screenshot of the prologue dialogue:  godot --path . --resolution 1920x1080 --script tools/promptshot.gd -- <outdir>
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(4.0).timeout
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "."
	root.get_viewport().get_texture().get_image().save_png(out + "/prologue.png")
	quit()
