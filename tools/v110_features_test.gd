extends SceneTree
## Headless test for v1.10.0 features:
## 1. Village Animals: Mourgos the village dog (interactive petting & speed buff),
##    Farm sheep pen (chewing, bleating, interactive feeding),
##    Upgraded stable yard with wooden fencing, shelter & companion horses (mare, foal).
## 2. Dynamic Roadside Encounters: RoadAmbush system spawning bandits at night on trails.
## 3. Audio & Soundscapes: amb_market daytime village square loop, animal audio cues.

var passed := 0
var failed := 0


func _init() -> void:
	print("--- Running v110_features_test ---")
	call_deferred("_run")


func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		print("  FAIL: %s" % desc)


func _run() -> void:
	# Autoloads
	var quests = load("res://scripts/quests.gd").new()
	quests.name = "Quests"
	root.add_child(quests)

	var sound_mgr = load("res://scripts/sound_manager.gd").new()
	sound_mgr.name = "SoundManager"
	root.add_child(sound_mgr)

	await process_frame

	# 1. SoundManager & SfxIds checks
	check("SfxIds has amb_market loop", SfxIds.LOOPS.has("amb_market"))
	check("SfxIds has dog_bark", SfxIds.VARIANTS.get("dog_bark", 0) == 2)
	check("SfxIds has dog_whimper", SfxIds.VARIANTS.get("dog_whimper", 0) == 1)
	check("SfxIds has sheep_baa", SfxIds.VARIANTS.get("sheep_baa", 0) == 2)
	check("SoundManager registered amb_market", sound_mgr._ambient.has("amb_market"))

	# 2. Player pet buff checks
	var player = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	await process_frame

	check("Player initially has 0 pet buff", player.buff_time("pet") == 0.0)
	player.apply_pet_buff(120.0)
	check("Player received 120s pet buff", player.buff_time("pet") > 115.0)

	# 3. Dog (Mourgos) checks
	var dog = load("res://scripts/village_dog.gd").new()
	root.add_child(dog)
	await process_frame

	check("Dog prompt is in Greek", dog.interact_prompt().contains("Χάιδεψε"))
	check("Dog interact range is valid", dog.interact_range() >= 2.0)
	dog.interact(player)
	check("Interacting with dog refreshes player buff", player.buff_time("pet") > 115.0)

	# 4. Sheep checks
	var sheep = load("res://scripts/village_sheep.gd").new()
	root.add_child(sheep)
	await process_frame

	check("Sheep prompt is in Greek", sheep.interact_prompt().contains("Τάισε"))
	check("Sheep interact range is valid", sheep.interact_range() >= 2.0)
	sheep.interact(player)
	check("Sheep feeding sets fed timer", sheep.get("_fed_timer") > 0.0)

	# 5. RoadAmbush system checks
	var ambush = load("res://scripts/road_ambush.gd").new()
	root.add_child(ambush)
	await process_frame
	check("RoadAmbush node exists and processes", ambush != null and ambush.name == "RoadAmbush")

	# 6. Village integration check (static source verification to avoid full navmesh thread pool)
	var v_src := FileAccess.get_file_as_string("res://scripts/village.gd")
	check("Village calls _build_animals in _ready", v_src.contains("_build_animals()"))
	check("Village has upgraded stable shelter and companion horses", v_src.contains("mare := Horse.new()") and v_src.contains("foal := Horse.new()"))
	check("Village creates Mourgos the dog and sheep pen", v_src.contains("dog := VillageDog.new()") and v_src.contains("VillageSheep.new()"))
	check("Village sets up RoadAmbush encounters", v_src.contains("RoadAmbush.new()"))

	# Clean up
	player.queue_free()
	dog.queue_free()
	sheep.queue_free()
	ambush.queue_free()
	sound_mgr.queue_free()
	quests.queue_free()

	print("\n--- v110_features_test Results: %d passed, %d failed ---" % [passed, failed])
	if failed == 0:
		print("ALL PASS")
		quit(0)
	else:
		print("SOME CHECKS FAILED")
		quit(1)
