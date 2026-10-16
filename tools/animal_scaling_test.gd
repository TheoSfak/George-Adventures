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
		check("Cow is not giant (height <= 1.8m, was 6.2m)", cow_sz.y <= 1.8)
		check("Cow length fits in paddock (length <= 3.0m, was 10.9m)", cow_sz.z <= 3.0)
		check("Cow has realistic height (>= 1.1m)", cow_sz.y >= 1.1)
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
		check("Deer is not giant (height <= 1.6m, was 5.3m)", deer_sz.y <= 1.6)
		check("Deer length is realistic (length <= 2.0m, was 5.5m)", deer_sz.z <= 2.0)
		check("Deer has natural height (>= 0.9m)", deer_sz.y >= 0.9)
	deer.free()

	# [3] Testing Forest Wolf
	print("\n[3] Testing Forest Wolf (enemies.gd)...")
	var enemies_script = load("res://scripts/enemies.gd")
	var wolf_data = enemies_script.KINDS.get("wolf", {})
	var wolf_scale: float = wolf_data.get("model_scale", 1.0)
	check("Wolf scale reduced from 1.15 (scale <= 0.40)", wolf_scale <= 0.40)
	var wolf_sc = load("res://assets/characters/Wolf.glb") as PackedScene
	if wolf_sc:
		var wolf_inst = wolf_sc.instantiate() as Node3D
		wolf_inst.scale = Vector3.ONE * wolf_scale
		var wolf_sz = _calc_mesh_bounds(wolf_inst)
		print("  Wolf dimensions: Height=%.2fm, Length=%.2fm" % [wolf_sz.y, wolf_sz.z])
		check("Wolf height is realistic (height <= 1.1m, was 3.1m)", wolf_sz.y <= 1.1)
		check("Wolf length is realistic (length <= 2.2m, was 6.4m)", wolf_sz.z <= 2.2)
		wolf_inst.free()

	# [4] Testing Cave Spider
	print("\n[4] Testing Cave Spider (enemies.gd)...")
	var spider_data = enemies_script.KINDS.get("spider", {})
	var spider_scale: float = spider_data.get("model_scale", 1.0)
	check("Spider scale reduced from 1.3 (scale <= 0.35)", spider_scale <= 0.35)
	var spider_sc = load("res://assets/characters/Spider.glb") as PackedScene
	if spider_sc:
		var spider_inst = spider_sc.instantiate() as Node3D
		spider_inst.scale = Vector3.ONE * spider_scale
		var spider_sz = _calc_mesh_bounds(spider_inst)
		print("  Spider dimensions: Width=%.2fm, Height=%.2fm, Length=%.2fm" % [spider_sz.x, spider_sz.y, spider_sz.z])
		check("Spider width is realistic (width <= 2.0m, was 7.7m)", spider_sz.x <= 2.0)
		check("Spider height is low (height <= 0.8m, was 2.5m)", spider_sz.y <= 0.8)
		spider_inst.free()

	# [5] Testing Orcs
	print("\n[5] Testing Orc Warband Proportions...")
	var warrior_scale: float = enemies_script.KINDS.get("orc_warrior", {}).get("model_scale", 1.0)
	var berserker_scale: float = enemies_script.KINDS.get("orc_berserker", {}).get("model_scale", 1.0)
	var warlord_scale: float = enemies_script.KINDS.get("orc_warlord", {}).get("model_scale", 1.0)
	check("Orc warrior scale adjusted (scale <= 0.75, was 1.25)", warrior_scale <= 0.75)
	check("Orc berserker scale adjusted (scale <= 0.85, was 1.5)", berserker_scale <= 0.85)
	check("Orc warlord boss scale adjusted (scale <= 1.0, was 2.0)", warlord_scale <= 1.0)

	print("\n--- Summary: %d passed, %d failed ---" % [passed, failed])
	if failed == 0:
		print("ALL ANIMAL & MOB PROPORTIONS ARE PROPERLY SCALED!")
	quit(0 if failed == 0 else 1)
