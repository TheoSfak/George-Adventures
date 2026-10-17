@tool
extends SceneTree

const ShopDataClass := preload("res://scripts/shop_data.gd")
const WildFloraNodeClass := preload("res://scripts/wild_flora_node.gd")
const AlchemyBenchClass := preload("res://scripts/alchemy_bench.gd")
const PlayerClass := preload("res://scripts/player.gd")
const EnemyClass := preload("res://scripts/enemy.gd")

var _checks_passed := 0
var _checks_failed := 0

func _assert(condition: bool, msg: String) -> void:
	if condition:
		_checks_passed += 1
		print("  PASS: %s" % msg)
	else:
		_checks_failed += 1
		print("  FAIL: %s" % msg)

func _init() -> void:
	print("==================================================")
	print("Alchemy & Herb Brewing at Andreas' Shop Test")
	print("==================================================")

	_test_flora_reagents_data()
	_test_alchemy_recipes_data()
	_test_wild_flora_nodes()
	_test_alchemy_bench()
	_test_brewing_mechanics()
	_test_blade_coating_combat()

	print("==================================================")
	print("Results: %d Passed, %d Failed" % [_checks_passed, _checks_failed])
	print("==================================================")
	quit(_checks_failed)


func _test_flora_reagents_data() -> void:
	print("\n--- Testing Wild Flora Reagents in ShopData ---")
	var required_flora := ["waterlily", "reed", "mountain_herb", "autumn_cone"]
	for fid in required_flora:
		_assert(ShopDataClass.JUNK.has(fid), "Reagent '%s' exists in ShopData.JUNK" % fid)
		var item: Dictionary = ShopDataClass.JUNK.get(fid, {})
		_assert(item.get("material") == true, "Reagent '%s' is marked as crafting material" % fid)
		_assert(String(item.get("name", "")).length() > 0, "Reagent '%s' has Greek name: %s" % [fid, item.get("name", "")])
		_assert(int(item.get("price", 0)) > 0, "Reagent '%s' has sell price > 0" % fid)


func _test_alchemy_recipes_data() -> void:
	print("\n--- Testing Alchemy Recipes in ShopData ---")
	_assert(ShopDataClass.ALCHEMY_RECIPES.has("flame_oil"), "Recipe 'flame_oil' exists")
	_assert(ShopDataClass.ALCHEMY_RECIPES.has("poison_coat"), "Recipe 'poison_coat' exists")
	_assert(ShopDataClass.ALCHEMY_RECIPES.has("frost_ward"), "Recipe 'frost_ward' exists")
	_assert(ShopDataClass.ALCHEMY_RECIPES.has("elixir_stone"), "Recipe 'elixir_stone' exists")
	_assert(ShopDataClass.ALCHEMY_RECIPES.has("elixir_swiftness"), "Recipe 'elixir_swiftness' exists")

	# Check coating details
	var flame: Dictionary = ShopDataClass.ALCHEMY_RECIPES.get("flame_oil", {})
	_assert(flame.get("category") == "coating", "flame_oil is a coating")
	_assert(float(flame.get("coating_damage", 0.0)) >= 8.0, "flame_oil grants +8 fire damage")

	# Check elixir details
	var stone: Dictionary = ShopDataClass.ALCHEMY_RECIPES.get("elixir_stone", {})
	_assert(stone.get("category") == "elixir", "elixir_stone is an elixir")
	var smods: Dictionary = stone.get("mods", {})
	_assert(smods.get("hp_add", 0.0) >= 60.0, "elixir_stone grants +60 max HP")

	# Check shop registration
	_assert(ShopDataClass.SHOPS.has("andreas_alchemy"), "andreas_alchemy shop registered")
	var ashop: Dictionary = ShopDataClass.SHOPS.get("andreas_alchemy", {})
	_assert(ashop.get("kind") == "alchemy", "andreas_alchemy has kind == 'alchemy'")


func _test_wild_flora_nodes() -> void:
	print("\n--- Testing Wild Flora Interactive Harvesting ---")
	var flora_types := ["waterlily", "reed", "mountain_herb", "autumn_cone"]
	for ftype in flora_types:
		var node: Node = WildFloraNodeClass.new()
		node.set("flora_id", ftype)
		root.add_child(node)
		node._ready()

		_assert(node.is_in_group("interactables"), "%s node is in 'interactables' group" % ftype)
		_assert(node.is_in_group("flora"), "%s node is in 'flora' group" % ftype)

		var prompt: String = node.call("interact_prompt")
		_assert("Συγκομιδή" in prompt, "Prompt indicates harvesting: %s" % prompt)

		# Harvest with test player
		var player: Player = PlayerClass.new()
		player.add_to_group("player")
		root.add_child(player)

		var initial_reagents: int = int(player.junk.get(ftype, 0))
		node.call("interact", player)

		var harvested_reagents: int = int(player.junk.get(ftype, 0))
		_assert(harvested_reagents > initial_reagents, "Harvest successfully gathered %s into player.junk (%d)" % [ftype, harvested_reagents])
		_assert(node.get("harvested") == true, "Flora node is marked as harvested")
		_assert(String(node.call("interact_prompt")) == "", "Harvested flora node has empty prompt during cooldown")

		player.free()
		node.free()


func _test_alchemy_bench() -> void:
	print("\n--- Testing Andreas' Alchemy Bench ---")
	var bench: Node = AlchemyBenchClass.new()
	root.add_child(bench)
	bench._ready()

	_assert(bench != null, "AlchemyBench instantiates successfully")
	_assert(bench.is_in_group("interactables"), "Bench is in 'interactables' group")
	_assert(bench.is_in_group("alchemy"), "Bench is in 'alchemy' group")

	var prompt: String = bench.call("interact_prompt")
	_assert("Αλχημείας" in prompt, "Prompt indicates alchemy table: %s" % prompt)

	# Collision Shape Check
	var cols := bench.find_children("*", "CollisionShape3D", true, false)
	_assert(cols.size() > 0, "AlchemyBench has solid CollisionShape3D")

	bench.free()


func _test_brewing_mechanics() -> void:
	print("\n--- Testing Brewing Crafting Logic ---")
	var player: Player = PlayerClass.new()
	player.add_to_group("player")
	root.add_child(player)

	# 1. Test missing ingredients check
	player.gold = 100
	player.junk.clear()
	_assert(ShopDataClass.can_brew("flame_oil", player.gold, player.junk) == false, "Cannot brew flame_oil without reagents")

	# 2. Add required ingredients for flame_oil (1 mountain_herb, 1 autumn_cone, 15 gold)
	player.junk["mountain_herb"] = 1
	player.junk["autumn_cone"] = 1
	player.gold = 50
	_assert(ShopDataClass.can_brew("flame_oil", player.gold, player.junk) == true, "Can brew flame_oil with sufficient reagents & gold")

	# 3. Brew flame_oil
	var brewed: bool = ShopDataClass.brew_recipe("flame_oil", player)
	_assert(brewed == true, "flame_oil successfully brewed")
	_assert(player.gold == 35, "15 gold deducted on brewing flame_oil (current: %d)" % player.gold)
	_assert(int(player.junk.get("mountain_herb", 0)) == 0, "mountain_herb consumed")
	_assert(int(player.junk.get("autumn_cone", 0)) == 0, "autumn_cone consumed")
	_assert(player.blade_coating.get("type") == "flame_oil", "Player blade coating is 'flame_oil'")
	_assert(float(player.blade_coating.get("time", 0.0)) > 290.0, "Blade coating duration set to 300s")

	# 4. Brew Stoneskin Elixir (2 mountain_herb, 1 reed, 30 gold)
	player.junk["mountain_herb"] = 2
	player.junk["reed"] = 1
	player.gold = 50
	var base_hp := player.max_health
	var brewed_stone: bool = ShopDataClass.brew_recipe("elixir_stone", player)
	_assert(brewed_stone == true, "elixir_stone successfully brewed")
	_assert(player.gold == 20, "30 gold deducted on brewing elixir_stone (current: %d)" % player.gold)
	_assert(player.active_elixirs.has("elixir_stone"), "elixir_stone recorded in active_elixirs")
	_assert(player.max_health >= base_hp + 60.0, "Player max health increased by +60 from Stoneskin Elixir (%f -> %f)" % [base_hp, player.max_health])

	player.free()


func _test_blade_coating_combat() -> void:
	print("\n--- Testing Blade Coating Combat Enhancement ---")
	var player: Player = PlayerClass.new()
	player.add_to_group("player")
	root.add_child(player)

	var enemy: Enemy = EnemyClass.new()
	enemy.max_health = 100.0
	enemy.health = 100.0
	root.add_child(enemy)

	# Apply flame_oil coating
	player.apply_blade_coating("flame_oil", 300.0, 8.0)
	_assert(player.blade_coating.get("type") == "flame_oil", "Flame oil coating active")

	# Strike enemy
	player.call("_hit", enemy, 10.0, 1.0)
	var expected_max_hp: float = 100.0 - 10.0 - 8.0 # base damage + 8 flame proc
	_assert(enemy.health <= expected_max_hp, "Enemy took combined physical and flame elemental damage (hp: %f)" % enemy.health)

	enemy.free()
	player.free()
