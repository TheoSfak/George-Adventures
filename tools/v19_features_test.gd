extends SceneTree
## Automated test suite for George Adventures v1.9.0 features:
## 1. Autonomous Map / Minimap for outdoor regions (Ash Valley & Frontier)
## 2. Rescue event follow-ups (custom alert/fail SFX, Andreas herb/provision shop & dialogue)
## 3. Visual & UI polish (fix no_depth_test on enemy/totem tags, minimap clutter spacing, glass tooltips)
## Run with:
##   cmd /c "godot --headless --script tools/v19_features_test.gd"

var failed := false

func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame

	# Ensure Quests autoload exists in root before loading any quest-dependent scripts
	if not root.has_node("Quests"):
		var q_node = (load("res://scripts/quests.gd") as GDScript).new()
		q_node.name = "Quests"
		root.add_child(q_node)

	print("=== Part 1: Autonomous Map / Minimap for Outdoor Regions ===")
	var minimap_cls = load("res://scripts/minimap.gd")
	check("Minimap class exists", minimap_cls != null)
	var reg_data: Dictionary = minimap_cls.REGION_DATA
	check("REGION_DATA contains village, frontier, ashvalley",
			reg_data.has("") and reg_data.has("frontier") and reg_data.has("ashvalley"))

	var village_cfg: Dictionary = reg_data[""]
	var frontier_cfg: Dictionary = reg_data["frontier"]
	var ash_cfg: Dictionary = reg_data["ashvalley"]

	var frontier_cls = load("res://scripts/frontier.gd")
	var ash_cls = load("res://scripts/ash_valley.gd")

	check("Village origin is ZERO", village_cfg.get("origin") == Vector3.ZERO)
	check("Frontier origin matches Frontier.ORIGIN", frontier_cfg.get("origin") == frontier_cls.ORIGIN)
	check("Ash Valley origin matches AshValley.ORIGIN", ash_cfg.get("origin") == ash_cls.ORIGIN)
	check("Frontier has valid places and boss areas", frontier_cfg.get("places", []).size() >= 4 and frontier_cfg.get("boss_areas", {}).has("malakar"))
	check("Ash Valley has valid places and boss areas", ash_cfg.get("places", []).size() >= 4 and ash_cfg.get("boss_areas", {}).has("pyrforos"))

	var str_cls = load("res://scripts/strings_el.gd")
	for place_key in ["frontier_pass", "frontier_camp", "frontier_fort", "ash_entry", "ash_shelter", "ash_bridge", "ash_temple"]:
		check("Strings.MAP_PLACES has " + place_key, str_cls.MAP_PLACES.has(place_key))

	check("Region title constants exist", str_cls.MAP_REGION_VILLAGE != "" and str_cls.MAP_REGION_FRONTIER != "" and str_cls.MAP_REGION_ASHVALLEY != "")

	# Coordinate conversion checks
	var mini = minimap_cls.new()
	mini.size = Vector2(200.0, 200.0)
	var big_map = minimap_cls.new()
	big_map.big = true
	big_map.size = Vector2(1000.0, 1000.0)

	# In village: big map center
	var v_center: Vector2 = big_map._to_map(Vector3.ZERO)
	check("Big map village center is (500, 500)", (v_center - Vector2(500.0, 500.0)).length() < 1.0)

	print("\n=== Part 2: Rescue Event Follow-ups & Andreas Shop ===")
	var sfx_ids_cls = load("res://scripts/sfx_ids.gd")
	check("SfxIds has rescue_alert", sfx_ids_cls.VARIANTS.has("rescue_alert"))
	check("SfxIds has rescue_failed", sfx_ids_cls.VARIANTS.has("rescue_failed"))
	check("rescue_alert.wav exists on disk", FileAccess.file_exists("res://assets/audio/sfx/rescue_alert.wav"))
	check("rescue_failed.wav exists on disk", FileAccess.file_exists("res://assets/audio/sfx/rescue_failed.wav"))

	var shop_data_cls = load("res://scripts/shop_data.gd")
	check("ShopData has andreas_herbs", shop_data_cls.SHOPS.has("andreas_herbs"))
	var andreas_shop: Dictionary = shop_data_cls.SHOPS.get("andreas_herbs", {})
	check("Andreas shop keeper is Andreas", andreas_shop.get("keeper") == "Αντρέας")
	check("Andreas shop title is Greek", andreas_shop.get("title") == "Βότανα & Προμήθειες")
	var stock: Array = andreas_shop.get("stock", [])
	check("Andreas shop sells potions and elixirs", stock.size() >= 4)
	var has_cheap_potion := false
	for item in stock:
		if item.get("id") == "health" and int(item.get("price")) < 25:
			has_cheap_potion = true
	check("Andreas gives friendly discount on health potion (< 25g)", has_cheap_potion)

	var quest_data_cls = load("res://scripts/quest_data.gd")
	check("QuestData.NPCS has andreas", quest_data_cls.NPCS.has("andreas"))
	check("Andreas NPC has shop andreas_herbs assigned", quest_data_cls.NPCS.get("andreas", {}).get("shop") == "andreas_herbs")
	var idle_lines: Array = quest_data_cls.NPCS.get("andreas", {}).get("idle", [])
	check("Andreas has expanded idle dialogue (>= 5 lines)", idle_lines.size() >= 5)

	print("\n=== Part 3: Visual & UI Polish ===")
	# Enemy tag and health bar depth testing
	var enemy_cls = load("res://scripts/enemy.gd")
	var enemy = enemy_cls.new()
	enemy.kind_id = "captain"
	enemy.display_name = "Καπετάνιος"
	enemy._build_health_bar()
	var tag = enemy.get("_tag")
	var bar = enemy.get("_bar")
	check("Enemy display nameplate has no_depth_test == false", tag != null and tag.no_depth_test == false)
	check("Enemy health bar has no_depth_test == false", bar != null and bar.no_depth_test == false)
	enemy.free()

	# Totem depth testing
	var totem_cls = load("res://scripts/totem.gd")
	var totem = totem_cls.new()
	totem._ready()
	var t_tag: Label3D
	var t_bar: Sprite3D
	for child in totem.get_children():
		if child is Label3D:
			t_tag = child
		elif child is Sprite3D:
			t_bar = child
	check("Totem tag has no_depth_test == false", t_tag != null and t_tag.no_depth_test == false)
	check("Totem bar has no_depth_test == false", t_bar != null and t_bar.no_depth_test == false)
	totem.free()

	# Minimap border decluttering test
	mini._placed_border_markers.clear()
	var border_pos1 := Vector2(100.0, -50.0) # off-edge above
	var p1: Vector2 = mini._clamped(border_pos1)
	var border_pos2 := Vector2(101.0, -50.0) # off-edge close direction
	var p2: Vector2 = mini._clamped(border_pos2)
	check("Clamped border markers are spaced apart (>= 15px)", p1.distance_to(p2) >= 15.0)

	# Tooltip stylebox check
	var ui_kit_cls = load("res://scripts/ui_kit.gd")
	ui_kit_cls.install_font()
	var theme := ThemeDB.get_default_theme()
	var tt_style = theme.get_stylebox("panel", "TooltipPanel")
	check("Custom TooltipPanel StyleBoxFlat installed", tt_style is StyleBoxFlat)
	if tt_style is StyleBoxFlat:
		check("Tooltip has rounded corners and margins", tt_style.corner_radius_top_left > 0 and tt_style.content_margin_left > 0)

	mini.free()
	big_map.free()

	print("\n=== Result ===")
	if failed:
		print("FAIL: One or more v1.9.0 checks failed.")
		quit(1)
	else:
		print("SUCCESS: All v1.9.0 feature checks passed!")
		quit(0)
