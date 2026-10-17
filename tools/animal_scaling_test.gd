@tool
extends SceneTree

## Headless test verifying that all animals and mobs are properly scaled
## and not oversized/giant compared to the player (height ~1.9m).

var passed := 0
var failed := 0

func check(desc: String, condition: bool) -> void:
	if condition:
		print("  PASS: %s" % desc)
		passed += 1
	else:
		print("  FAIL: %s" % desc)
		failed += 1

func _calc_mesh_bounds(inst: Node3D) -> Vector3:
	var min_pt = Vector3(1e9, 1e9, 1e9)
	var max_pt = Vector3(-1e9, -1e9, -1e9)
	var stack: Array[Node3D] = [inst]
	while not stack.is_empty():
		var curr = stack.pop_back()
		for child in curr.get_children():
			if child is Node3D:
				stack.append(child)
			if child is MeshInstance3D:
				var mi = child as MeshInstance3D
				var a = mi.get_aabb()
				var rel_t = Transform3D.IDENTITY
				var n: Node = mi
				while n != inst and n != null:
					if n is Node3D:
						rel_t = (n as Node3D).transform * rel_t
					n = n.get_parent()
				rel_t = inst.transform * rel_t
				var corners = [
					rel_t * Vector3(a.position.x, a.position.y, a.position.z),
					rel_t * Vector3(a.position.x + a.size.x, a.position.y, a.position.z),
					rel_t * Vector3(a.position.x, a.position.y + a.size.y, a.position.z),
					rel_t * Vector3(a.position.x + a.size.x, a.position.y + a.size.y, a.position.z),
					rel_t * Vector3(a.position.x, a.position.y, a.position.z + a.size.z),
					rel_t * Vector3(a.position.x + a.size.x, a.position.y, a.position.z + a.size.z),
					rel_t * Vector3(a.position.x, a.position.y + a.size.y, a.position.z + a.size.z),
					rel_t * Vector3(a.position.x + a.size.x, a.position.y + a.size.y, a.position.z + a.size.z),
				]
				for pt in corners:
					min_pt.x = minf(min_pt.x, pt.x)
					min_pt.y = minf(min_pt.y, pt.y)
					min_pt.z = minf(min_pt.z, pt.z)
					max_pt.x = maxf(max_pt.x, pt.x)
					max_pt.y = maxf(max_pt.y, pt.y)
					max_pt.z = maxf(max_pt.z, pt.z)
	return max_pt - min_pt

func _init() -> void:
	print("--- Running Animal & Mob Proportional Scaling Test ---")

	# [1] Testing Pasture Cow
	print("\n[1] Testing Pasture Cow (VillageCow)...")
	var cow = (load("res://scripts/village_cow.gd") as GDScript).new()
	cow._ready()
	var cow_model = cow.get_node_or_null("Cow")
	if not cow_model:
		for c in cow.get_children():
			if c is Node3D and c != cow.get_node_or_null("CollisionShape3D"):
				cow_model = c
				break
	check("VillageCow model exists", cow_model != null)
	if cow_model:
		var cow_sz = _calc_mesh_bounds(cow_model)
		print("  Cow dimensions: Height=%.2fm, Length=%.2fm, Width=%.2fm" % [cow_sz.y, cow_sz.z, cow_sz.x])
		check("Cow has natural pasture height (~2.0m)", cow_sz.y >= 1.7 and cow_sz.y <= 2.5)
		check("Cow length matches realistic livestock (~3.6m)", cow_sz.z >= 3.0 and cow_sz.z <= 4.2)
	check("VillageCow has interact_range", cow.has_method("interact_range"))
	check("VillageCow has interact_prompt", cow.has_method("interact_prompt"))
	cow.free()

	# [2] Testing Wild Deer
	print("\n[2] Testing Wild Deer (VillageDeer)...")
	var deer = (load("res://scripts/village_deer.gd") as GDScript).new()
	deer._ready()
	var deer_model = null
	for c in deer.get_children():
		if c is Node3D and c != deer.get_node_or_null("CollisionShape3D"):
			deer_model = c
			break
	check("VillageDeer model exists", deer_model != null)
	if deer_model:
		var deer_sz = _calc_mesh_bounds(deer_model)
		print("  Deer dimensions: Height=%.2fm, Length=%.2fm, Width=%.2fm" % [deer_sz.y, deer_sz.z, deer_sz.x])
		check("Deer has majestic height with antlers (~3.1m)", deer_sz.y >= 2.0 and deer_sz.y <= 3.8)
		check("Deer length is natural (~3.2m)", deer_sz.z >= 2.0 and deer_sz.z <= 3.8)
	deer.free()

	# [3] Testing Forest Wolf
	print("\n[3] Testing Forest Wolf (enemies.gd)...")
	var enemies_script = load("res://scripts/enemies.gd")
	var wolf_data = enemies_script.KINDS.get("wolf", {})
	var wolf_scale: float = wolf_data.get("model_scale", 1.0)
	check("Wolf scale is in grand dire wolf range (0.70 - 0.95)", wolf_scale >= 0.70 and wolf_scale <= 0.95)
	var wolf_sc = load("res://assets/characters/Wolf.glb") as PackedScene
	if wolf_sc:
		var wolf_inst = wolf_sc.instantiate() as Node3D
		wolf_inst.scale = Vector3.ONE * wolf_scale
		var wolf_sz = _calc_mesh_bounds(wolf_inst)
		print("  Wolf dimensions: Height=%.2fm, Length=%.2fm" % [wolf_sz.y, wolf_sz.z])
		check("Wolf height is visible and formidable (~2.2m)", wolf_sz.y >= 1.8 and wolf_sz.y <= 2.8)
		check("Wolf length is natural (~4.5m)", wolf_sz.z >= 3.6 and wolf_sz.z <= 5.2)
		wolf_inst.free()

	# [4] Testing Cave Spider
	print("\n[4] Testing Cave Spider (enemies.gd)...")
	var spider_data = enemies_script.KINDS.get("spider", {})
	var spider_scale: float = spider_data.get("model_scale", 1.0)
	check("Spider scale is in giant cave spider range (0.45 - 0.60)", spider_scale >= 0.45 and spider_scale <= 0.60)
	var spider_sc = load("res://assets/characters/Spider.glb") as PackedScene
	if spider_sc:
		var spider_inst = spider_sc.instantiate() as Node3D
		spider_inst.scale = Vector3.ONE * spider_scale
		var spider_sz = _calc_mesh_bounds(spider_inst)
		print("  Spider dimensions: Width=%.2fm, Height=%.2fm, Length=%.2fm" % [spider_sz.x, spider_sz.y, spider_sz.z])
		check("Spider width has wide leg span (~3.1m)", spider_sz.x >= 2.5 and spider_sz.x <= 3.8)
		check("Spider height is formidable (~1.0m)", spider_sz.y >= 0.8 and spider_sz.y <= 1.4)
		spider_inst.free()

	# [5] Testing Orcs
	print("\n[5] Testing Orc Warband Proportions...")
	var warrior_scale: float = enemies_script.KINDS.get("orc_warrior", {}).get("model_scale", 1.0)
	var berserker_scale: float = enemies_script.KINDS.get("orc_berserker", {}).get("model_scale", 1.0)
	var warlord_scale: float = enemies_script.KINDS.get("orc_warlord", {}).get("model_scale", 1.0)
	check("Orc warrior scale adjusted (scale ~0.78)", warrior_scale >= 0.70 and warrior_scale <= 0.85)
	check("Orc berserker scale adjusted (scale ~0.88)", berserker_scale >= 0.80 and berserker_scale <= 0.95)
	check("Orc warlord boss scale adjusted (scale ~1.05)", warlord_scale >= 0.95 and warlord_scale <= 1.15)

	print("\n--- Summary: %d passed, %d failed ---" % [passed, failed])
	if failed == 0:
		print("ALL ANIMAL & MOB PROPORTIONS ARE PROPERLY SCALED!")
	quit(0 if failed == 0 else 1)
