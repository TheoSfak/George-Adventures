extends SceneTree
## The stable: the keeper, the shop window, buying the horse, saving it:
##   godot --path . --headless --script tools/mount_stable_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")

	var shops = load("res://scripts/shop_data.gd")
	var shop: Dictionary = shops.SHOPS["stable"]
	check("the stable shop sells one mount at the rule's price and level", shop["stock"].size() == 1 and shop["stock"][0]["type"] == "mount" and shop["stock"][0]["price"] == MountRules.PRICE and shop["stock"][0]["level"] == MountRules.MIN_LEVEL)
	check("it is a stable (no selling tab)", shop.get("kind", "") == "stable")

	var keeper = null
	for n in get_nodes_in_group("npcs"):
		if n.get("npc_id") == "manolis":
			keeper = n
	check("Μανώλης stands in the village", keeper != null)
	if keeper == null:
		quit(1)
		return
	check("at the stable yard near (63, 53)", Vector2(keeper.global_position.x - 63.0, keeper.global_position.z - 53.0).length() < 12.0)
	var yard := main.get_node("Village").get_node_or_null("Stable")
	check("the stable yard exists with a standing horse", yard != null and yard.find_children("*", "Node3D", true, false).any(func(n): return n is Horse))

	# --- the shop window
	p.gold = 1000
	p.level = 1
	var window = hud.get("_shop")
	window.call("open", "stable", p)
	await create_timer(0.4).timeout
	check("the window opens", window.is_open())
	var buy_entry: Dictionary = shop["stock"][0]
	window.call("_buy", buy_entry)
	check("below level 5 he cannot buy", not p.horse_owned and p.gold == 1000)
	p.level = 5
	p.gold = 349
	window.call("_buy", buy_entry)
	check("without 350 gold he cannot buy", not p.horse_owned and p.gold == 349)
	p.gold = 500
	var heard := []
	p.message.connect(func(t): heard.append(t))
	window.call("_buy", buy_entry)
	check("with level 5 and gold he buys the horse", p.horse_owned and p.gold == 150)
	check("with the message", heard.has(Strings.MOUNT_BOUGHT))
	window.call("_buy", buy_entry)
	check("he cannot buy a second one", p.gold == 150)
	window.call("close")
	await create_timer(0.5).timeout

	# --- saving keeps the horse and not the saddle (the real save files are backed up and restored)
	var backup := _backup_saves()
	var save = load("res://scripts/save_game.gd")
	p.teleport(Vector3(0, 0.05, 12), PI)
	await create_timer(0.3).timeout
	check("George mounts", p.mount())
	check("the game saves", save.save())
	var data: Dictionary = save.read()
	check("the save file says horse_owned", data.has("player") and data["player"].get("horse_owned", false) == true)
	p.horse_owned = false
	save.apply(data)
	await create_timer(1.0).timeout
	check("loading restores the horse and puts him on foot", p.horse_owned and not p.mounted)
	_restore_saves(backup)
	quit(1 if failed else 0)


func _backup_saves() -> Dictionary:
	var out := {}
	for f in ["user://savegame.json", "user://savegame.bak"]:
		out[f] = FileAccess.get_file_as_string(f) if FileAccess.file_exists(f) else null
	return out


func _restore_saves(backup: Dictionary) -> void:
	for f in backup:
		if backup[f] == null:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
		else:
			var file := FileAccess.open(f, FileAccess.WRITE)
			file.store_string(backup[f])
			file.close()
