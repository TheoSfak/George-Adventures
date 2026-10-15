extends SceneTree
## Every named person must wear a model that fits the name: men are never the braided Rogue,
## women are never the bearded Barbarian or the helmeted Knight (Mage and Rogue_Hooded fit both):
##   godot --path . --headless --script tools/gender_test.gd
var failed := false

## Story NPCs, stall owners and the stage players: gender of each name (anything else must be in
## VillagerData.NAMES_MALE / NAMES_FEMALE).
const FEMALE := ["Κυρά-Μαρία", "Κυρά-Ελένη", "Αδελφή Θεοδώρα", "Ελπίδα η Κυνηγός", "Κυρά-Βούλα", "Αδελφή Αρετή", "Αρετούσα η Τραγουδίστρια"]
const MALE := ["Παπά-Σταύρος", "Νικήτας ο Σιδεράς", "Γέρο-Γιάννης", "Βασίλης ο Λοχαγός", "Στέλιος ο Μυλωνάς", "Θανάσης ο Μάγειρας",
		"Μοναχός Ιλαρίων", "Μπάρμπα-Θόδωρος", "Σήφης ο Κρασάς", "Μπάρμπα-Σπύρος ο Βιολιτζής", "Μανώλης ο Ιπποκόμος", "Αντρέας", "Μοναχός Θεόφιλος", "Δαμιανός ο Σιδεράς"]


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func gender_of_name(n: String) -> String:
	if n in FEMALE or n in VillagerData.NAMES_FEMALE:
		return "f"
	if n in MALE or n in VillagerData.NAMES_MALE:
		return "m"
	return "?"


func fits(n: String, model: String) -> bool:
	var g := gender_of_name(n)
	var mg: String = VillagerData.MODEL_GENDER.get(model.get_file().get_basename(), "?")
	return g != "?" and mg != "?" and (mg == "any" or mg == g)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	# --- the pools
	check("no name is in both pools", VillagerData.NAMES_MALE.filter(func(n): return n in VillagerData.NAMES_FEMALE).is_empty())
	check("no ambient name repeats a story NPC's first name",
			VillagerData.NAMES_MALE.filter(func(n): return MALE.any(func(m): return m.contains(n))).is_empty() and VillagerData.NAMES_FEMALE.filter(func(n): return FEMALE.any(func(m): return m.contains(n))).is_empty())
	for m in ["Barbarian", "Knight", "Rogue", "Mage", "Rogue_Hooded"]:
		var ok := true
		for i in 40:
			if not fits(VillagerData.name_for("res://assets/characters/%s.glb" % m, i), m):
				ok = false
		check("name_for fits %s for 40 different indices" % m, ok)

	# --- story NPCs (quest_data.gd)
	for id in QuestData.NPCS:
		var d: Dictionary = QuestData.NPCS[id]
		check("NPC %s: %s on %s" % [id, d["name"], str(d["model"]).get_file()], fits(d["name"], d["model"]))

	# --- the stalls and the stage of the square (square.gd)
	var sq = load("res://scripts/square.gd")
	for s in sq.STALLS:
		check("stall vendor %s on %s" % [s[5], s[6]], fits(s[5], s[6] + ".glb"))
	check("the singer (stage) fits her model", fits("Αρετούσα η Τραγουδίστρια", "Rogue_Hooded.glb"))
	check("the fiddler (stage) fits his model", fits("Μπάρμπα-Σπύρος ο Βιολιτζής", "Barbarian.glb"))

	# --- everyone who really stands in the world, the village and the tavern
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var interiors = get_first_node_in_group("interiors")
	var seen := {}
	var bad := 0
	for v in get_nodes_in_group("villagers"):
		seen[v] = true
		if not fits(v.display_name, v.model_path):
			bad += 1
			print("   MISMATCH: ", v.display_name, " on ", v.model_path)
	check("%d villagers in the village all fit their models" % seen.size(), seen.size() > 10 and bad == 0)
	interiors.enter("tavern_gender", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	for i in 60:
		await create_timer(0.1).timeout
		if interiors.is_inside() and not p.busy:
			break
	var regulars := 0
	bad = 0
	for v in get_nodes_in_group("interactables"):
		if v.get("holds_mug") == true:       # the tavern regulars (they are not in the "villagers" group)
			regulars += 1
			if not fits(v.display_name, v.model_path):
				bad += 1
				print("   MISMATCH: ", v.display_name, " on ", v.model_path)
	check("%d tavern regulars all fit their models" % regulars, regulars >= 4 and bad == 0)
	quit(1 if failed else 0)
