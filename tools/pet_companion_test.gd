@tool
extends SceneTree

const VillageDogClass := preload("res://scripts/village_dog.gd")
const WolfPupCompanionClass := preload("res://scripts/wolf_pup_companion.gd")
const ChestClass := preload("res://scripts/chest.gd")
const EnemyClass := preload("res://scripts/enemy.gd")
const PlayerClass := preload("res://scripts/player.gd")

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
	print("Animal Companion & Wilderness Pet System Test")
	print("==================================================")

	_test_mourgos_dog_companion()
	_test_wolf_pup_companion()

	print("==================================================")
	print("Results: %d Passed, %d Failed" % [_checks_passed, _checks_failed])
	print("==================================================")
	quit(_checks_failed)

func _test_mourgos_dog_companion() -> void:
	print("\n--- Testing Mourgos the Dog Companion ---")
	var dog: Node = VillageDogClass.new()
	root.add_child(dog)
	dog._ready()

	_assert(dog != null, "VillageDog instantiates successfully")
	_assert(dog.is_in_group("companions"), "Dog is in 'companions' group")
	_assert(dog.is_in_group("animals"), "Dog is in 'animals' group")
	_assert(dog.is_in_group("interactables"), "Dog is in 'interactables' group")

	# Initial prompt when idle
	var prompt_idle: String = dog.call("interact_prompt")
	_assert("Ακολούθησέ με" in prompt_idle, "Idle prompt invites following: %s" % prompt_idle)

	# Activate companion mode
	dog.call("set_companion", true)
	_assert(dog.get("is_active_companion") == true, "Companion mode activated")

	var prompt_following: String = dog.call("interact_prompt")
	_assert("Κάτσε εδώ" in prompt_following, "Following prompt allows stay command: %s" % prompt_following)

	# Toggle sitting (stay)
	dog.call("toggle_sitting")
	_assert(dog.get("is_sitting") == true, "Dog is sitting / staying in place")
	var prompt_sitting: String = dog.call("interact_prompt")
	_assert("Σήκω" in prompt_sitting, "Sitting prompt allows resume following: %s" % prompt_sitting)

	dog.call("toggle_sitting")
	_assert(dog.get("is_sitting") == false, "Dog resumes following after toggle")

	# Test tricks
	var player: Player = PlayerClass.new()
	player.add_to_group("player")
	root.add_child(player)

	dog.call("perform_next_trick", player)
	_assert(int(dog.get("affection_level")) >= 2, "Trick execution increases affection level")

	dog.call("perform_next_trick", player)
	_assert(int(dog.get("affection_level")) >= 3, "Affection level progresses with tricks")

	# Test hidden chest scent detection
	var chest: Chest = ChestClass.new()
	chest.opened = false
	chest.position = dog.position + Vector3(6.0, 0.0, 0.0)
	root.add_child(chest)
	chest._ready()

	dog.call("_check_chest_scent", dog.position, player, self)
	_assert(float(dog.get("_scent_timer")) > 0.0, "Scent detection triggered on nearby unopened chest")

	chest.free()
	player.free()
	dog.free()

func _test_wolf_pup_companion() -> void:
	print("\n--- Testing Rescued Silver Wolf Pup Companion ---")
	var pup: Node = WolfPupCompanionClass.new()
	root.add_child(pup)
	pup._ready()

	_assert(pup != null, "WolfPupCompanion instantiates successfully")
	_assert(pup.is_in_group("companions"), "Wolf pup is in 'companions' group")
	_assert(pup.get("is_trapped") == true, "Pup is initially trapped in briars")

	var prompt_trapped: String = pup.call("interact_prompt")
	_assert("Απελευθέρωση" in prompt_trapped, "Trapped prompt offers rescue: %s" % prompt_trapped)

	# Rescue pup
	var player: Player = PlayerClass.new()
	player.add_to_group("player")
	root.add_child(player)

	pup.call("rescue", player)
	_assert(pup.get("is_trapped") == false, "Pup successfully rescued from briars")
	_assert(pup.get("is_active_companion") == true, "Pup automatically becomes active companion upon rescue")

	# Test wild tricks
	pup.call("perform_wild_trick", player)
	_assert(int(pup.get("affection_level")) >= 2, "Wild trick increases pup affection")

	# Test keen wilderness scent
	var chest: Chest = ChestClass.new()
	chest.opened = false
	chest.position = pup.position + Vector3(12.0, 0.0, 0.0)
	root.add_child(chest)
	chest._ready()

	pup.call("check_chest_scent", pup.position, self, player)
	_assert(float(pup.get("_scent_timer")) > 0.0, "Wilderness keen scent triggered at extended range (12m)")

	chest.free()
	player.free()
	pup.free()
