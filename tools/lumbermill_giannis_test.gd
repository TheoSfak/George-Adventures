@tool
extends SceneTree

var _checks_passed := 0
var _checks_failed := 0

func _assert(condition: bool, msg: String) -> void:
	if condition:
		_checks_passed += 1
		print("  PASS: %s" % msg)
	else:
		_checks_failed += 1
		printerr("  FAIL: %s" % msg)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("Lumbermill & Gero-Giannis Redesign Verification")
	print("==================================================")

	# 1. Instantiate Village
	var village_script = load("res://scripts/village.gd")
	_assert(village_script != null, "village.gd loads successfully")
	var village: Node3D = village_script.new()
	root.add_child(village)

	await process_frame
	await process_frame

	_test_giannis_node(village)
	_test_giannis_clearance(village)
	_test_giannis_workstation(village)
	_test_chopping_block_and_axe(village)
	_test_seasoning_shed(village)
	_test_lumbermill_building_and_yard(village)
	_test_rustic_fencing_and_signpost(village)

	print("==================================================")
	print("Results: %d Passed, %d Failed" % [_checks_passed, _checks_failed])
	print("==================================================")

	village.queue_free()
	await process_frame
	quit(1 if _checks_failed > 0 else 0)


func _test_giannis_node(village: Node3D) -> void:
	print("\n--- Testing Gero-Giannis NPC Node & Setup ---")
	var giannis: Node3D = null
	for n in village.find_children("*", "Npc", true, false):
		if n.npc_id == "giannis":
			giannis = n
			break

	_assert(giannis != null, "Gero-Giannis Npc node found in world")
	if not giannis:
		return

	_assert(giannis.is_in_group("npcs"), "Giannis is in 'npcs' group")
	_assert(giannis.is_in_group("interactables"), "Giannis is in 'interactables' group")
	_assert(giannis.collision_layer == 16, "Giannis collision layer is interactable (16)")

	# Check position
	var expected_pos := Vector3(85.5, 0.0, 26.5)
	var pos_dist := giannis.global_position.distance_to(expected_pos)
	_assert(pos_dist < 0.2, "Giannis stands at designated foreman post %s (actual: %s)" % [expected_pos, giannis.global_position])

	# Check orientation (facing WNW toward village path)
	var yaw_deg := rad_to_deg(giannis.rest_yaw)
	_assert(absf(yaw_deg - (-115.0)) < 2.0, "Giannis faces village entrance road (yaw: %.1f deg)" % yaw_deg)

	# Check QuestData equipped woodcutter weapon
	var quest_data = load("res://scripts/quest_data.gd")
	var g_data: Dictionary = quest_data.NPCS.get("giannis", {})
	_assert(g_data.get("name", "") == "Γέρο-Γιάννης", "Giannis Greek name is 'Γέρο-Γιάννης'")
	var show_props: Array = g_data.get("show", [])
	_assert("1H_Axe" in show_props, "Giannis is equipped with woodcutter's hatchet (1H_Axe)")


func _test_giannis_clearance(village: Node3D) -> void:
	print("\n--- Testing Gero-Giannis 100% Item Clearance & Zero Clipping ---")
	var giannis: Node3D = null
	for n in village.find_children("*", "Npc", true, false):
		if n.npc_id == "giannis":
			giannis = n
			break
	if not giannis:
		_assert(false, "Cannot test clearance without Giannis")
		return

	var gpos := giannis.global_position

	# Test all StaticBody3D colliders in the lumbermill and props
	var clipping_bodies: Array[String] = []
	for sb in village.find_children("*", "StaticBody3D", true, false):
		if sb == giannis or sb.get_parent() == giannis:
			continue
		var sb_node := sb as Node3D
		if not sb_node:
			continue
		var dist: float = sb_node.global_position.distance_to(gpos)
		# Any collider center closer than 1.0m to Giannis would overlap his capsule
		if dist < 1.0:
			clipping_bodies.append("%s (dist: %.2f m)" % [sb_node.name, dist])

	_assert(clipping_bodies.is_empty(), "Zero clipping colliders inside Giannis's personal space (clipped: %s)" % str(clipping_bodies))

	# Test all mesh instances near Giannis
	var clipping_props: Array[String] = []
	var lumbermill_holder = village.get_node_or_null("Lumbermill")
	if lumbermill_holder:
		for child in lumbermill_holder.get_children():
			if child.name == "SawdustShavings":
				continue # Sawdust on the floor is fine
			var child_node := child as Node3D
			if not child_node:
				continue
			var d: float = child_node.global_position.distance_to(gpos)
			if d < 1.0:
				clipping_props.append("%s at %s (dist: %.2f m)" % [child_node.name, child_node.global_position, d])

	_assert(clipping_props.is_empty(), "No props overlapping Giannis (found: %s)" % str(clipping_props))


func _test_giannis_workstation(village: Node3D) -> void:
	print("\n--- Testing Giannis's Carpenter Workbench & Illumination ---")
	var lumbermill = village.get_node_or_null("Lumbermill")
	_assert(lumbermill != null, "Lumbermill holder exists")
	if not lumbermill:
		return

	# Workbench
	var bench: Node3D = null
	for c in lumbermill.get_children():
		if c.name.begins_with("crate_long_A") or c.name.begins_with("bench"):
			if c.global_position.distance_to(Vector3(84.3, 0.0, 25.4)) < 1.0:
				bench = c
				break
	_assert(bench != null, "Carpenter's workbench placed in front of Giannis")

	# Worktable light
	var light: OmniLight3D = lumbermill.get_node_or_null("GiannisWorkLight") as OmniLight3D
	_assert(light != null, "GiannisWorkLight OmniLight3D exists")
	if light:
		_assert(light.light_energy >= 1.0, "Worklight has warm energy (%.1f)" % light.light_energy)
		_assert(light.omni_range >= 5.0, "Worklight illuminates worktable & Giannis (range: %.1f m)" % light.omni_range)

	# Water bucket
	var bucket: Node3D = null
	for c in lumbermill.get_children():
		if c.name.begins_with("bucket_water"):
			bucket = c
			break
	_assert(bucket != null, "Blade cooling water bucket placed at workstation")


func _test_chopping_block_and_axe(village: Node3D) -> void:
	print("\n--- Testing Chopping Block, Embedded Axe & Sawdust ---")
	var lumbermill = village.get_node_or_null("Lumbermill")
	if not lumbermill:
		return

	# Stump chopping block
	var stump: Node3D = null
	for c in lumbermill.get_children():
		if c.name.begins_with("tree_single_A_cut"):
			if c.global_position.distance_to(Vector3(86.2, 0.0, 29.8)) < 1.0:
				stump = c
				break
	_assert(stump != null, "Chopping block tree stump positioned beside Giannis")

	# Embedded axe
	var axe_root: Node3D = lumbermill.get_node_or_null("WoodcutterAxe") as Node3D
	_assert(axe_root != null, "WoodcutterAxe node exists")
	if axe_root:
		_assert(axe_root.get_child_count() > 0, "WoodcutterAxe has 3D model child")
		_assert(axe_root.global_position.y >= 0.7, "Axe is embedded on top of chopping stump (Y: %.2f m)" % axe_root.global_position.y)

	# Sawdust shavings mound
	var sawdust: MeshInstance3D = lumbermill.get_node_or_null("SawdustShavings") as MeshInstance3D
	_assert(sawdust != null, "SawdustShavings ground mesh exists")
	if sawdust:
		_assert(sawdust.mesh is CylinderMesh, "Sawdust mesh is CylinderMesh disk")

	# Wheelbarrow
	var barrow: Node3D = null
	for c in lumbermill.get_children():
		if c.name.begins_with("wheelbarrow"):
			barrow = c
			break
	_assert(barrow != null, "Wheelbarrow loaded with firewood placed in yard")


func _test_seasoning_shed(village: Node3D) -> void:
	print("\n--- Testing Timber Seasoning Shed (Scaffolding) ---")
	var lumbermill = village.get_node_or_null("Lumbermill")
	if not lumbermill:
		return

	# Scaffolding shed
	var shed: Node3D = null
	for c in lumbermill.get_children():
		if c.name.begins_with("building_scaffolding"):
			shed = c
			break
	_assert(shed != null, "Covered seasoning shed (building_scaffolding) exists")
	if shed:
		# Check distance to Giannis (must be separated > 15m)
		var giannis: Node3D = null
		for n in village.find_children("*", "Npc", true, false):
			if n.npc_id == "giannis":
				giannis = n
				break
		if giannis:
			var d: float = shed.global_position.distance_to(giannis.global_position)
			_assert(d > 18.0, "Seasoning shed is at south yard perimeter, clear of Giannis (dist: %.2f m)" % d)

		# Check trimesh collider (for walkable covered shelter)
		var has_trimesh := false
		for mi in shed.find_children("*", "MeshInstance3D", true, false):
			for c in mi.get_children():
				if c is StaticBody3D:
					for sc in c.get_children():
						if sc is CollisionShape3D and sc.shape is ConcavePolygonShape3D:
							has_trimesh = true
							break
		_assert(has_trimesh, "Seasoning shed has Trimesh ConcavePolygon collision for walkthrough")

	# Sheltered lumber stacks
	var shed_lumber_count := 0
	for c in lumbermill.get_children():
		if c.name.begins_with("resource_lumber"):
			if c.global_position.distance_to(Vector3(82.0, 0.0, 48.0)) < 8.0:
				shed_lumber_count += 1
	_assert(shed_lumber_count >= 2, "Seasoning lumber stacks sheltered under the shed (count: %d)" % shed_lumber_count)


func _test_lumbermill_building_and_yard(village: Node3D) -> void:
	print("\n--- Testing Lumbermill Building & Perimeter Yard ---")
	# Building
	var mill: Node3D = null
	for b in village.find_children("*", "Node3D", true, false):
		if b.name.begins_with("building_lumbermill"):
			mill = b
			break
	_assert(mill != null, "Main lumbermill building exists in village")
	if mill:
		# Check trimesh collision
		var has_trimesh := false
		for mi in mill.find_children("*", "MeshInstance3D", true, false):
			for c in mi.get_children():
				if c is StaticBody3D:
					for sc in c.get_children():
						if sc is CollisionShape3D and sc.shape is ConcavePolygonShape3D:
							has_trimesh = true
							break
		_assert(has_trimesh, "Lumbermill building has Trimesh collision for accessible porch/ramp")

	# Timber pallet
	var lumbermill = village.get_node_or_null("Lumbermill")
	if lumbermill:
		var pallet: Node3D = null
		for c in lumbermill.get_children():
			if c.name.begins_with("pallet"):
				pallet = c
				break
		_assert(pallet != null, "Fresh-sawn lumber pallet placed by mill dock")

		# Perimeter timber stacks
		var perimeter_stacks := 0
		for c in lumbermill.get_children():
			if c.name.begins_with("resource_lumber"):
				if c.global_position.x > 100.0:
					perimeter_stacks += 1
		_assert(perimeter_stacks >= 2, "Perimeter forest log stacks placed along east border (count: %d)" % perimeter_stacks)

		# Stumps clearing
		var stumps: Node3D = null
		for c in lumbermill.get_children():
			if c.name.begins_with("trees_A_cut"):
				stumps = c
				break
		_assert(stumps != null, "Harvested tree stumps clearing present")


func _test_rustic_fencing_and_signpost(village: Node3D) -> void:
	print("\n--- Testing Rustic Fencing, Entrance Gate & Signpost ---")
	var lumbermill = village.get_node_or_null("Lumbermill")
	if not lumbermill:
		return

	# Fencing
	var fence_count := 0
	for c in lumbermill.get_children():
		if c.name.begins_with("fence_wood"):
			fence_count += 1
	_assert(fence_count >= 3, "Rustic wooden fence segments enclose yard (count: %d)" % fence_count)

	# Signpost
	var sign_found := false
	var sign_text := ""
	for c in lumbermill.find_children("*", "Label3D", true, false):
		var lbl := c as Label3D
		if lbl and ("Υλοτομείο" in lbl.text or "Γιάννη" in lbl.text):
			sign_found = true
			sign_text = lbl.text
			break
	_assert(sign_found, "Entrance signpost found with Greek text")
	_assert("Υλοτομείο Αγίου Βλάση" in sign_text, "Signpost text contains 'Υλοτομείο Αγίου Βλάση'")
	_assert("Γέρο-Γιάννη" in sign_text or "Γιάννη" in sign_text, "Signpost text directs to Giannis's workshop")

	# Gate standing lantern
	var gate_light: OmniLight3D = lumbermill.get_node_or_null("GateLampLight") as OmniLight3D
	_assert(gate_light != null, "GateLampLight OmniLight3D illuminates entrance gate")
