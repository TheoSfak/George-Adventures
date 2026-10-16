extends SceneTree
## Test driver for v1.16.0: All 5 expansion features.

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		printerr("  FAIL: %s" % desc)

func _run() -> void:
	# Provide Quests node if not present in test tree
	if not root.has_node("Quests"):
		var quests_node = load("res://scripts/quests.gd").new()
		quests_node.name = "Quests"
		root.add_child(quests_node)

	print("--- Running v1.16.0 Features Test ---")

	# 1. Feature 1: River Flora & Great Tree Lake Lilies
	print("\n[1] Testing Feature 1: River Flora...")
	var river_gd = load("res://scripts/island_river.gd") as GDScript
	if river_gd:
		var river: Node3D = river_gd.new()
		river._ready()
		var flora: Node = river.get_node_or_null("RiverFlora")
		check("RiverFlora exists and has waterlilies & reeds", flora != null and flora.get_child_count() >= 20)
		river.free()

	# 2. Feature 5: Mob KINDS & Quest Data
	print("\n[2] Testing Feature 5: Mob Kinds & Quests...")
	var enemies_gd = load("res://scripts/enemies.gd") as GDScript
	if enemies_gd:
		var kinds: Dictionary = enemies_gd.KINDS
		var needed_kinds := ["orc_warrior", "orc_berserker", "orc_warlord", "wolf", "spider"]
		for k in needed_kinds:
			check("enemies.gd has mob kind '%s'" % k, kinds.has(k))
		check("enemies.gd has orc_warlord in BOSSES", "orc_warlord" in enemies_gd.BOSSES)

	var q_needed := ["orc_raid", "orc_warlord", "wolf_hunt"]
	for q in q_needed:
		check("QuestData has quest '%s'" % q, QuestData.QUESTS.has(q))

	check("QuestData.is_orc recognizes orc_warrior and berserker", QuestData.is_orc("orc_warrior") and QuestData.is_orc("orc_berserker"))
	check("QuestData.is_orc excludes orc_warlord boss", not QuestData.is_orc("orc_warlord"))
	check("NOT_SKELETONS contains orcs, wolf, spider", not QuestData.is_skeleton("orc_warrior") and not QuestData.is_skeleton("wolf") and not QuestData.is_skeleton("spider"))

	# 3. Features 2, 3, 4 & Ambient Animals in Village
	print("\n[3] Testing Features 2, 3, 4, 5 in Village...")
	var village_gd = load("res://scripts/village.gd") as GDScript
	if village_gd:
		var v: Node3D = village_gd.new()
		v._ready()

		# Feature 2: Archery Grounds
		var archery: Node = v.get_node_or_null("ArcheryGrounds")
		check("ArcheryGrounds exists with range, barracks, targets, weapon racks", archery != null and archery.get_child_count() >= 5)

		# Feature 3: Quarry Mine, Lumbermill, Ruined Outpost
		var quarry: Node = v.get_node_or_null("Quarry")
		var mine: Node = quarry.get_node_or_null("building_mine_blue") if quarry else null
		check("Quarry mine excavation building exists", mine != null)

		var lumbermill: Node = v.get_node_or_null("Lumbermill")
		check("Lumbermill exists with mill building & timber props", lumbermill != null and lumbermill.get_child_count() >= 4)

		var outpost: Node = v.get_node_or_null("RuinedOutpost")
		check("Ruined Outpost (Orc Stronghold) exists with keep, walls, catapult", outpost != null and outpost.get_child_count() >= 5)

		# Feature 4: Golden Grove
		var grove: Node = v.get_node_or_null("GoldenGrove")
		check("Golden Pine Grove exists with autumn pines and decorated tree", grove != null and grove.get_child_count() >= 8)

		# Feature 5: Ambient Animals (Cows and Deer)
		var animals: Node = v.get_node_or_null("Animals")
		if animals:
			var cow_count := 0
			var deer_count := 0
			for child in animals.get_children():
				var s: Script = child.get_script()
				if s != null:
					if s.resource_path.ends_with("village_cow.gd"):
						cow_count += 1
					elif s.resource_path.ends_with("village_deer.gd"):
						deer_count += 1
			check("Pasture cows exist (>= 2)", cow_count >= 2)
			check("Wild deer exist (>= 3)", deer_count >= 3)
		else:
			check("Animals node exists", false)

		v.free()

	print("\n--- Summary: %d passed, %d failed ---" % [passed, failed])
	quit(0 if failed == 0 else 1)
