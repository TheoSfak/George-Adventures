@tool
extends SceneTree

## Headless test for Feature 1: Ranged Combat & Archery System (Bows & Crossbows).

var passed := 0
var failed := 0

func check(desc: String, condition: bool) -> void:
	if condition:
		print("  PASS: %s" % desc)
		passed += 1
	else:
		print("  FAIL: %s" % desc)
		failed += 1

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	print("--- Running Ranged Combat & Archery System Test ---")

	# [1] Testing ShopData Ranged Weapons & Archery Shop
	print("\n[1] Testing ShopData Gear & Archery Shop...")
	var shop_data_sc := load("res://scripts/shop_data.gd")
	check("ShopData script loaded", shop_data_sc != null)

	var bows := ["bow_1", "crossbow_1", "bow_2", "crossbow_2", "bow_3", "crossbow_3", "bow_4", "bow_5", "crossbow_4", "bow_6"]
	for b_id in bows:
		var g: Dictionary = shop_data_sc.GEAR.get(b_id, {})
		check("Gear %s exists in ShopData" % b_id, not g.is_empty())
		var wtype: String = g.get("weapon_type", "")
		check("Gear %s has valid weapon_type (%s)" % [b_id, wtype], wtype in ["bow", "crossbow"])
		check("Gear %s has valid Greek name" % b_id, String(g.get("name", "")).length() > 0)
		check("Gear %s weapon slot" % b_id, g.get("slot", "") == "weapon")

	check("Archery shop exists in SHOPS", shop_data_sc.SHOPS.has("archery"))
	var arch_shop: Dictionary = shop_data_sc.SHOPS.get("archery", {})
	check("Archery shop keeper is Dimitris", arch_shop.get("keeper", "") == "Δημήτρης ο Τοξότης")
	check("Archery shop has stock", (arch_shop.get("stock", []) as Array).size() >= 10)

	# [2] Testing Dimitris NPC Data
	print("\n[2] Testing Dimitris NPC Data...")
	var quest_data_sc := load("res://scripts/quest_data.gd")
	var dimitris_npc: Dictionary = quest_data_sc.NPCS.get("dimitris", {})
	check("Dimitris has shop assigned as archery", dimitris_npc.get("shop", "") == "archery")

	# [3] Testing Ranged Skills in SkillData
	print("\n[3] Testing Ranged Skills in SkillData...")
	var skill_data_sc := load("res://scripts/skill_data.gd")
	var r_skills := ["power_shot", "volley", "fire_arrow"]
	for s_id in r_skills:
		check("Skill %s exists in SkillData.SKILLS" % s_id, skill_data_sc.SKILLS.has(s_id))
		var s_def: Dictionary = skill_data_sc.SKILLS[s_id]
		check("Skill %s has cooldown > 0" % s_id, float(s_def.get("cooldown", 0)) > 0.0)
		check("Skill %s has Greek name" % s_id, String(s_def.get("name", "")).length() > 0)

	# [4] Testing BowMeshBuilder
	print("\n[4] Testing BowMeshBuilder...")
	var bow_builder_sc := load("res://scripts/bow_mesh_builder.gd")
	check("BowMeshBuilder loaded", bow_builder_sc != null)
	var bow_mesh: ArrayMesh = bow_builder_sc.build_recurve_bow_mesh()
	check("Recurve bow mesh created", bow_mesh != null)
	check("Recurve bow mesh has surfaces", bow_mesh.get_surface_count() > 0)
	var aabb: AABB = bow_mesh.get_aabb()
	print("  Bow mesh bounds: Height=%.2fm, Width=%.2fm, Depth=%.2fm" % [aabb.size.y, aabb.size.x, aabb.size.z])
	check("Bow mesh height is proportional (~1.2m)", aabb.size.y >= 1.0 and aabb.size.y <= 1.5)

	# [5] Testing PlayerArrow Projectile Class
	print("\n[5] Testing PlayerArrow Projectile Class...")
	var arrow_sc := load("res://scripts/player_arrow.gd") as GDScript
	check("PlayerArrow class loaded", arrow_sc != null)
	var arrow: Node3D = arrow_sc.new()
	arrow.set("arrow_type", "fire")
	arrow.set("damage", 35.0)
	arrow.set("velocity", Vector3(0, 0, -40.0))
	arrow._ready()
	check("PlayerArrow instantiates with fire type", arrow.get("arrow_type") == "fire")
	check("PlayerArrow has forward velocity", (arrow.get("velocity") as Vector3).z < -10.0)
	arrow.free()

	# [6] Testing Player Ranged Combat Integration
	print("\n[6] Testing Player Ranged Combat Integration...")
	var player_sc := load("res://scripts/player.gd") as GDScript
	check("Player script loaded", player_sc != null)
	var player = player_sc.new()
	player.level = 20
	check("Player has aim_changed signal", player.has_signal("aim_changed"))
	player.gear_owned.append("bow_1")
	player.gear_owned.append("crossbow_1")
	var equipped_bow = player.equip("bow_1")
	check("Player equipped bow_1 successfully", equipped_bow)
	check("Player weapon type is now 'bow'", player.current_weapon_type() == "bow")

	var equipped_cb = player.equip("crossbow_1")
	check("Player equipped crossbow_1 successfully", equipped_cb)
	check("Player weapon type is now 'crossbow'", player.current_weapon_type() == "crossbow")

	check("Player knows power_shot", player.knows_skill("power_shot"))
	check("Player knows volley", player.knows_skill("volley"))
	check("Player knows fire_arrow", player.knows_skill("fire_arrow"))
	player.free()

	# [7] Testing PlayerArrow Hit Registration on Living Enemy
	print("\n[7] Testing PlayerArrow Hit Detection against Living Enemy...")
	var test_root := Node3D.new()
	root.add_child(test_root)

	var dummy_enemy_sc := GDScript.new()
	dummy_enemy_sc.source_code = """
extends CharacterBody3D
var health := 50.0
var _dead := false

func is_dead() -> bool:
	return _dead

func take_damage(amount: float, _from: Vector3, _knock: float = 5.0) -> void:
	health -= amount
	if health <= 0:
		_dead = true
"""
	dummy_enemy_sc.reload()

	var dummy_enemy = dummy_enemy_sc.new()
	dummy_enemy.position = Vector3(0, 0, 5)
	dummy_enemy.add_to_group("enemies")
	test_root.add_child(dummy_enemy)

	var test_arrow: Node3D = arrow_sc.new()
	test_arrow.set("damage", 25.0)
	test_arrow.set("arrow_type", "normal")
	test_arrow.set("velocity", Vector3(0, 0, 30))
	test_root.add_child(test_arrow)

	# Test line segment passing through enemy position
	var from_p := Vector3(0, 0.9, 0)
	var to_p := Vector3(0, 0.9, 10)
	var did_hit: bool = test_arrow._check_enemy_hit(from_p, to_p)
	check("PlayerArrow hits living enemy", did_hit)
	check("Living enemy health reduced by arrow damage", dummy_enemy.health <= 25.0)

	# Test that dead enemy is skipped
	var fresh_arrow: Node3D = arrow_sc.new()
	fresh_arrow.set("damage", 25.0)
	test_root.add_child(fresh_arrow)
	dummy_enemy._dead = true
	var did_hit_dead: bool = fresh_arrow._check_enemy_hit(from_p, to_p)
	check("PlayerArrow skips already dead enemy", not did_hit_dead)

	test_arrow.free()
	fresh_arrow.free()
	dummy_enemy.free()
	test_root.free()

	print("\n--- Summary: %d passed, %d failed ---" % [passed, failed])
	if failed == 0:
		print("FEATURE 1: RANGED COMBAT & ARCHERY SYSTEM FULLY VERIFIED!")
	quit(0 if failed == 0 else 1)
