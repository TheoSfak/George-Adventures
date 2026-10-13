extends SceneTree
## The fish, the meals and the kitchen as data (no world needed):
##   godot --path . --headless --script tools/fish_data_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var ids: Array = ShopData.fish_ids()
	check("13 species (found %d)" % ids.size(), ids.size() == 13)
	if ids.size() != 13:
		quit(1)
		return
	var counts := {}
	for id in ids:
		var f: Dictionary = ShopData.JUNK[id]
		counts[f["rarity"]] = int(counts.get(f["rarity"], 0)) + 1
		check("%s has name, price, icon, desc, zone, speed and weight" % id,
				f.has("name") and f.has("price") and f["icon"] == "fish" and f.has("desc") and float(f["zone"]) > 0.0 and float(f["speed"]) > 0.0 and float(f["weight"]) > 0.0)
	check("rarities 5 / 4 / 3 / 1: " + str(counts), counts == {"common": 5, "uncommon": 4, "rare": 3, "legendary": 1})
	check("sunfish is day only, moonfish night only", ShopData.JUNK["sunfish"]["only"] == "day" and ShopData.JUNK["moonfish"]["only"] == "night")
	check("rarer fish have narrower zones", float(ShopData.JUNK["goby"]["zone"]) > float(ShopData.JUNK["trout"]["zone"]) and float(ShopData.JUNK["trout"]["zone"]) > float(ShopData.JUNK["goldfish"]["zone"]) and float(ShopData.JUNK["goldfish"]["zone"]) > float(ShopData.JUNK["king"]["zone"]))
	check("the old junk is still there", ShopData.JUNK.has("bone") and ShopData.JUNK.has("rust") and ShopData.JUNK.has("charm"))

	# cheapest first inside a rarity
	var common: Array = ShopData.fish_by_rarity("common")
	check("common fish sorted cheapest first: " + str(common), common == ["goby", "perch", "sazani", "carp", "barbel"])

	# meals
	check("7 meals", ShopData.MEALS.size() == 7)
	for id in ShopData.MEALS:
		var m: Dictionary = ShopData.MEALS[id]
		var keys_ok := true
		for k in m["mods"]:
			if not Stats.NAMES.has(k):
				keys_ok = false
		check("meal %s: name, desc, tab, duration, valid Stats keys, gold cost" % id,
				m.has("name") and m.has("desc") and m["tab"] in ["buy", "cook"] and float(m["duration"]) >= 600.0 and keys_ok and int(m["cost"]["gold"]) > 0)
	check("3 meals to buy and 4 to cook", ShopData.MEALS.values().filter(func(m): return m["tab"] == "buy").size() == 3 and ShopData.MEALS.values().filter(func(m): return m["tab"] == "cook").size() == 4)
	check("the feast lasts 15 minutes", float(ShopData.MEALS["feast"]["duration"]) == 900.0)

	# cooking rules
	var junk := {"goby": 2, "perch": 3, "trout": 1}
	check("fried fish needs 3 common fish and 5 gold", ShopData.can_prepare("fried", 5, junk) and not ShopData.can_prepare("fried", 4, junk) and not ShopData.can_prepare("fried", 5, {"goby": 2}))
	check("fish_to_use takes the cheapest first", ShopData.fish_to_use("fried", junk) == {"goby": 2, "perch": 1})
	check("soup needs 2 uncommon fish", not ShopData.can_prepare("soup", 100, junk))
	check("a gold meal needs only gold", ShopData.can_prepare("fasolada", 25, {}) and not ShopData.can_prepare("fasolada", 24, {}))
	check("fish_have counts a rarity", ShopData.fish_have(junk, "common") == 5 and ShopData.fish_have(junk, "uncommon") == 1)
	check("need text is Greek and shows what George has: " + ShopData.fish_need_text("fried", junk), ShopData.fish_need_text("fried", junk).contains("3") and ShopData.fish_need_text("fried", junk).contains("5"))
	check("meal_mods of nothing is empty", ShopData.meal_mods({}).is_empty())
	check("meal_mods of a meal", ShopData.meal_mods({"id": "fasolada", "time": 10.0}) == {"hp_add": 30})

	# the kitchen and its cook
	check("the kitchen shop exists", ShopData.SHOPS.has("kitchen") and ShopData.SHOPS["kitchen"]["kind"] == "kitchen")
	check("the cook exists and runs the kitchen", QuestData.NPCS.has("thanasis") and QuestData.NPCS["thanasis"]["shop"] == "kitchen")
	check("the cook's greeting is Greek text", ShopData.SHOPS["kitchen"]["greeting"].size() > 0)
	check("strings exist", Strings.PROMPT_FISH != "" and Strings.MSG_FISH_CAUGHT.contains("%s") and Strings.KITCHEN_EAT != "")
	quit(1 if failed else 0)
