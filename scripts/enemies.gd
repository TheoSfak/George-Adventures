extends Node3D
## Places the skeleton enemies. Edit SPAWNS to add, move or remove them, and KINDS to
## tune each type. Positions are in metres like village.gd ((0, 0) is the well, -Z is
## north). Defeated skeletons come back after a while, except the named bosses.

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CHAR := "res://assets/characters/"
const WEAPONS := CHAR + "skeleton_weapons/"

const KINDS := {
	"warrior": {
		"kind_id": "warrior",
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Small_A.gltf",
		"max_health": 45.0, "attack_damage": 12.0, "chase_speed": 4.2,
		"xp_reward": 25, "gold_min": 3, "gold_max": 9, "potion_chance": 0.35,
	},
	"minion": {
		"kind_id": "minion",
		"model_path": CHAR + "Skeleton_Minion.glb",
		"weapon_path": WEAPONS + "Skeleton_Axe.gltf",
		"max_health": 28.0, "attack_damage": 8.0, "chase_speed": 5.0, "attack_cooldown": 1.2,
		"xp_reward": 12, "gold_min": 1, "gold_max": 4, "potion_chance": 0.2,
	},
	# Skeleton archer: keeps its distance and shoots crossbow bolts
	"rogue": {
		"kind_id": "rogue", "tint_color": Color(0.35, 0.8, 0.3, 0.22),
		"model_path": CHAR + "Skeleton_Rogue.glb",
		"weapon_path": WEAPONS + "Skeleton_Crossbow.gltf",
		"ranged": true, "projectile_kind": "arrow", "shoot_anim": "1H_Ranged_Shoot", "projectile_speed": 20.0,
		"ranged_min": 6.0, "ranged_max": 14.0, "aggro_range": 19.0, "leash_range": 32.0,
		"max_health": 26.0, "attack_damage": 9.0, "chase_speed": 4.6, "attack_cooldown": 2.1,
		"xp_reward": 18, "gold_min": 2, "gold_max": 6, "potion_chance": 0.25,
	},
	# Skeleton mage: slow glowing orbs, stays far away
	"mage": {
		"kind_id": "mage", "tint_color": Color(0.55, 0.35, 0.95, 0.28),
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 11.0,
		"ranged_min": 8.0, "ranged_max": 16.0, "aggro_range": 20.0, "leash_range": 34.0,
		"max_health": 24.0, "attack_damage": 14.0, "chase_speed": 3.8, "attack_cooldown": 2.8,
		"xp_reward": 22, "gold_min": 3, "gold_max": 8, "potion_chance": 0.3,
	},
	# Skeleton brute: big, slow, hits very hard
	"brute": {
		"kind_id": "brute", "tint_color": Color(0.75, 0.15, 0.12, 0.30), "model_scale": 1.4,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Axe.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 130.0, "attack_damage": 22.0, "chase_speed": 3.3, "attack_range": 2.9,
		"attack_hit_time": 0.7, "attack_cooldown": 2.3, "attack_anim": "1H_Melee_Attack_Chop",
		"aggro_range": 15.0, "patrol_radius": 4.0,
		"xp_reward": 55, "gold_min": 8, "gold_max": 18, "potion_chance": 0.5,
	},
	# Night invasion mini-boss (nights 3 and later)
	"warlord": {
		"kind_id": "warlord", "respawn": false, "tint_color": Color(0.9, 0.3, 0.1, 0.3),
		"display_name": "Οστέινος Πολέμαρχος", "model_scale": 1.9,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 300.0, "attack_damage": 20.0, "chase_speed": 4.0, "attack_range": 3.4,
		"attack_hit_time": 0.6, "attack_cooldown": 1.8, "aggro_range": 22.0, "patrol_radius": 4.0,
		"xp_reward": 160, "gold_min": 40, "gold_max": 70, "potion_chance": 1.0,
	},
	# Quest bosses (they do not respawn)
	"captain": {
		"kind_id": "captain", "respawn": false,
		"display_name": "Λοχαγός των Νεκρών", "model_scale": 1.6,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Small_A.gltf",
		"max_health": 220.0, "attack_damage": 18.0, "chase_speed": 4.3, "attack_range": 3.0,
		"attack_hit_time": 0.55, "attack_cooldown": 1.7, "aggro_range": 20.0, "patrol_radius": 4.0,
		"xp_reward": 120, "gold_min": 40, "gold_max": 60, "potion_chance": 1.0,
	},
	"king": {
		"kind_id": "king", "respawn": false,
		"display_name": "Βασιλιάς των Οστών", "model_scale": 2.3,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Small_A.gltf",
		"max_health": 520.0, "attack_damage": 26.0, "chase_speed": 4.4, "attack_range": 4.2,
		"attack_hit_time": 0.6, "attack_cooldown": 1.8, "aggro_range": 26.0, "leash_range": 45.0,
		"patrol_radius": 3.0,
		"xp_reward": 400, "gold_min": 100, "gold_max": 140, "potion_chance": 1.0,
	},
	# --- the catacombs below the old crypt (placed by catacombs.gd; "quest" = the quest that needs the boss)
	"cguard": {
		"kind_id": "cguard", "tint_color": Color(0.30, 0.70, 0.85, 0.26), "model_scale": 1.15,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 85.0, "attack_damage": 16.0, "chase_speed": 4.0, "attack_cooldown": 1.5,
		"aggro_range": 14.0, "leash_range": 30.0, "need_los": true,
		"xp_reward": 42, "gold_min": 6, "gold_max": 14, "potion_chance": 0.4,
	},
	"acolyte": {
		"kind_id": "acolyte", "tint_color": Color(0.85, 0.15, 0.30, 0.30),
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 12.0,
		"ranged_min": 8.0, "ranged_max": 15.0, "aggro_range": 18.0, "leash_range": 30.0, "need_los": true,
		"max_health": 40.0, "attack_damage": 18.0, "chase_speed": 3.9, "attack_cooldown": 2.4,
		"xp_reward": 40, "gold_min": 6, "gold_max": 14, "potion_chance": 0.35,
	},
	"warden_bone": {
		"kind_id": "warden_bone", "respawn": false, "quest": "wardens", "tint_color": Color(0.85, 0.9, 1.0, 0.20),
		"display_name": "Φύλακας των Οστών", "model_scale": 2.1,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Axe.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 640.0, "attack_damage": 26.0, "chase_speed": 3.9, "attack_range": 3.6,
		"attack_hit_time": 0.7, "attack_cooldown": 2.0, "attack_anim": "1H_Melee_Attack_Chop",
		"aggro_range": 20.0, "leash_range": 36.0, "patrol_radius": 3.0, "need_los": true,
		"xp_reward": 320, "gold_min": 70, "gold_max": 110, "potion_chance": 1.0,
	},
	"warden_flame": {
		"kind_id": "warden_flame", "respawn": false, "quest": "wardens", "tint_color": Color(1.0, 0.45, 0.10, 0.38),
		"display_name": "Φύλακας της Φλόγας", "model_scale": 2.0,
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 13.0,
		"ranged_min": 7.0, "ranged_max": 15.0, "aggro_range": 22.0, "leash_range": 38.0, "patrol_radius": 3.0, "need_los": true,
		"max_health": 540.0, "attack_damage": 24.0, "chase_speed": 4.3, "attack_cooldown": 1.7,
		"xp_reward": 320, "gold_min": 70, "gold_max": 110, "potion_chance": 1.0,
	},
	"warden_shadow": {
		"kind_id": "warden_shadow", "respawn": false, "quest": "wardens", "tint_color": Color(0.35, 0.12, 0.55, 0.45),
		"display_name": "Φύλακας της Σκιάς", "model_scale": 1.9,
		"model_path": CHAR + "Skeleton_Rogue.glb",
		"weapon_path": WEAPONS + "Skeleton_Crossbow.gltf",
		"ranged": true, "projectile_kind": "arrow", "shoot_anim": "1H_Ranged_Shoot", "projectile_speed": 22.0,
		"ranged_min": 6.0, "ranged_max": 14.0, "aggro_range": 22.0, "leash_range": 38.0, "patrol_radius": 3.0, "need_los": true,
		"max_health": 500.0, "attack_damage": 19.0, "chase_speed": 5.0, "attack_cooldown": 1.3,
		"xp_reward": 320, "gold_min": 70, "gold_max": 110, "potion_chance": 1.0,
	},
	# The last boss: fires orbs from afar and calls skeleton helpers
	"necromancer": {
		"kind_id": "necromancer", "respawn": false, "quest": "necro", "tint_color": Color(0.20, 0.90, 0.40, 0.32),
		"display_name": "Αρχιερέας της Σκιάς", "model_scale": 2.3,
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 12.0,
		"ranged_min": 7.0, "ranged_max": 15.0, "aggro_range": 26.0, "leash_range": 48.0, "patrol_radius": 2.0, "need_los": true,
		"max_health": 1100.0, "attack_damage": 30.0, "chase_speed": 4.4, "attack_cooldown": 2.2,
		"summon_kind": "minion", "summon_interval": 13.0, "summon_max": 4,
		"xp_reward": 900, "gold_min": 200, "gold_max": 260, "potion_chance": 1.0,
	},
	# --- the Frontier beyond the mountains (placed by frontier.gd)
	"shadow_knight": {
		"kind_id": "shadow_knight", "tint_color": Color(0.30, 0.20, 0.55, 0.34), "model_scale": 1.3,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 190.0, "attack_damage": 24.0, "chase_speed": 3.4, "attack_range": 2.6,
		"attack_hit_time": 0.65, "attack_cooldown": 2.0, "aggro_range": 15.0, "leash_range": 32.0,
		"xp_reward": 110, "gold_min": 12, "gold_max": 26, "potion_chance": 0.5,
	},
	# Soul collector: a caster whose blue souls slow George down
	"soul_collector": {
		"kind_id": "soul_collector", "tint_color": Color(0.25, 0.55, 0.95, 0.32),
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "soul", "projectile_slows": true, "shoot_anim": "Spellcast_Shoot", "projectile_speed": 11.0,
		"ranged_min": 8.0, "ranged_max": 16.0, "aggro_range": 20.0, "leash_range": 34.0,
		"max_health": 85.0, "attack_damage": 16.0, "chase_speed": 3.9, "attack_cooldown": 2.5,
		"xp_reward": 100, "gold_min": 12, "gold_max": 26, "potion_chance": 0.45,
	},
	# Mini-boss of the fortress courtyard
	"giant_skeleton": {
		"kind_id": "giant_skeleton", "respawn": false, "quest": "f_wall", "tint_color": Color(0.55, 0.50, 0.65, 0.28),
		"display_name": "Γιγάντιος Σκελετός", "model_scale": 2.6,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Axe.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 1600.0, "attack_damage": 34.0, "chase_speed": 3.6, "attack_range": 4.4,
		"attack_hit_time": 0.8, "attack_cooldown": 2.4, "attack_anim": "1H_Melee_Attack_Chop",
		"aggro_range": 24.0, "leash_range": 44.0, "patrol_radius": 3.0, "need_los": true,
		"xp_reward": 700, "gold_min": 120, "gold_max": 170, "potion_chance": 1.0,
	},
	# The last boss: orbs from afar, and when he is hurt badly he calls shadow knights and speeds up
	"malakar": {
		"kind_id": "malakar", "respawn": false, "quest": "f_malakar", "tint_color": Color(0.45, 0.10, 0.70, 0.36),
		"display_name": "Μαλάκαρ ο Σκοτεινός Άρχοντας", "model_scale": 2.5,
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 13.0,
		"ranged_min": 7.0, "ranged_max": 16.0, "aggro_range": 28.0, "leash_range": 50.0, "patrol_radius": 2.0, "need_los": true,
		"max_health": 3200.0, "attack_damage": 36.0, "chase_speed": 4.4, "attack_cooldown": 2.0,
		"enrage_below": 0.5, "enrage_summon": "shadow_knight", "summon_interval": 12.0, "summon_max": 3,
		"xp_reward": 1800, "gold_min": 300, "gold_max": 380, "potion_chance": 1.0,
	},
}

# Bosses always drop buff potions and a charm.
const BOSSES: Array[String] = ["captain", "king", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar"]

# [kind, x, z]   (village houses stand within ~125 m of the well)
const SPAWNS := [
	# --- around the stolen wine barrels (quest "Τα Κλεμμένα Βαρέλια")
	["minion", -38.0, -138.0], ["minion", -22.0, -146.0],
	["minion", 138.0, -22.0], ["warrior", 148.0, -36.0],
	["minion", 18.0, 148.0], ["warrior", 34.0, 156.0],
	["warrior", -128.0, 104.0], ["minion", -116.0, 118.0],
	# --- wandering around the village outskirts
	["minion", 80.0, -112.0], ["warrior", 62.0, -126.0],
	["minion", -82.0, 118.0], ["minion", 96.0, 104.0],
	["warrior", -60.0, -110.0], ["minion", 150.0, 60.0],
	["minion", -150.0, -40.0],
	# --- the skeleton camp in the west (quest "Το Χαμένο Κλειδί")
	["warrior", -168.0, 8.0], ["warrior", -184.0, 30.0], ["minion", -160.0, 42.0],
	["minion", -178.0, -4.0], ["warrior", -196.0, 12.0], ["minion", -152.0, 22.0],
	# --- the quarry in the south-east (quest "Ο Λοχαγός των Νεκρών")
	["captain", 142.0, 128.0],
	["minion", 126.0, 112.0], ["minion", 158.0, 140.0], ["minion", 154.0, 108.0], ["warrior", 128.0, 146.0],
	# --- new mobs: archers hunt in the west and on the outskirts, brutes guard the quarry, mages haunt the crypt
	["rogue", -150.0, 36.0], ["rogue", -190.0, 40.0], ["rogue", -176.0, -14.0], ["rogue", -140.0, 4.0],
	["rogue", 70.0, -138.0], ["rogue", 112.0, 80.0], ["rogue", -96.0, -112.0],
	["brute", 132.0, 100.0], ["brute", 162.0, 124.0], ["brute", 60.0, 150.0], ["brute", -126.0, 136.0],
	["mage", 148.0, 146.0], ["mage", -34.0, -158.0], ["mage", 34.0, -158.0], ["mage", -34.0, -198.0], ["mage", 34.0, -198.0],
	["mage", -168.0, 22.0], ["mage", 100.0, -150.0],
	# --- the old crypt in the north (quest "Ο Βασιλιάς των Οστών")
	["king", 0.0, -190.0],
	["warrior", -16.0, -170.0], ["warrior", 16.0, -170.0],
	["minion", -26.0, -186.0], ["minion", 26.0, -186.0], ["minion", 0.0, -166.0],
]

@export var respawn_time := 45.0     # seconds until a defeated skeleton returns

var _loot: Node3D


func _ready() -> void:
	add_to_group("enemy_spawner")
	_loot = Node3D.new()
	_loot.name = "Loot"
	add_child(_loot)
	# Wait for the village colliders to register with the physics server, so spawn
	# points that land inside a tree, rock or house can be nudged to open ground.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i in SPAWNS.size():
		_spawn(i)


func _spawn(index: int) -> void:
	var s: Array = SPAWNS[index]
	if not KINDS[s[0]].get("respawn", true) and SaveGame.boss_defeated(s[0]):
		return                            # this boss was killed in an earlier session
	var enemy := _make(s[0], Vector3(s[1], 0.05, s[2]))
	enemy.died.connect(_on_enemy_died.bind(index))
	add_child(enemy)


func _make(kind: String, pos: Vector3) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	var stats: Dictionary = KINDS[kind]
	for key in stats:
		if key != "respawn" and key != "quest":
			enemy.set(key, stats[key])
	enemy.position = _free_spot(pos)
	return enemy


## A creature of the catacombs (catacombs.gd calls this once the rooms exist). Ordinary
## ones come back after a long while; the bosses stay dead once their quest is done.
func spawn_extra(kind: String, pos: Vector3) -> Enemy:
	var stats: Dictionary = KINDS[kind]
	if not stats.get("respawn", true) and SaveGame.boss_defeated(kind) and Quests.state[stats["quest"]] == Quests.S.DONE:
		return null
	var enemy := _make(kind, pos)
	enemy.died.connect(_on_extra_died.bind(kind, pos))
	add_child(enemy)
	return enemy


## Helpers called by a boss (the necromancer's skeletons): they never come back.
func spawn_summon(kind: String, pos: Vector3) -> Enemy:
	var enemy := _make(kind, pos)
	enemy.aggro_range = 30.0
	enemy.died.connect(_on_enemy_died.bind(-1))
	add_child(enemy)
	return enemy


func _on_extra_died(enemy: Enemy, kind: String, home: Vector3) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.gain_xp(enemy.xp_reward)
	Quests.report_kill(enemy.kind_id)
	_drop_loot(enemy)
	if KINDS[kind].get("respawn", true):
		await get_tree().create_timer(respawn_time * 2.0).timeout
		while player and player.global_position.distance_to(home) < 30.0:
			await get_tree().create_timer(5.0).timeout
		spawn_extra(kind, home)
	else:
		SaveGame.note_boss(kind)


## A night invader: marches on the well, dies for good (index -1: no respawn).
func spawn_invader(kind: String, pos: Vector3, target: Vector3 = Vector3.ZERO) -> Enemy:
	var enemy := _make(kind, pos)
	enemy.invader = true
	enemy.march_target = target
	enemy.aggro_range = maxf(enemy.aggro_range, 15.0)
	enemy.died.connect(_on_enemy_died.bind(-1))
	add_child(enemy)
	return enemy


func _on_enemy_died(enemy: Enemy, index: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.gain_xp(enemy.xp_reward)
	Quests.report_kill(enemy.kind_id)
	_drop_loot(enemy)
	if index >= 0 and KINDS[SPAWNS[index][0]].get("respawn", true):
		_respawn_later(index)
	elif index >= 0:
		SaveGame.note_boss(enemy.kind_id)


func _drop_loot(enemy: Enemy) -> void:
	var gold := randi_range(enemy.gold_min, enemy.gold_max)
	if gold > 0:
		var pieces := clampi(gold / 4 + 1, 1, 4)
		for i in pieces:
			var share := gold / pieces + (1 if i < gold % pieces else 0)
			_drop(Pickup.make("gold", share), enemy.global_position)
	if randf() < enemy.potion_chance:
		_drop(Pickup.make("potion", 1), enemy.global_position)
	# rarer buff potions (bosses always drop one)
	var is_boss := enemy.kind_id in BOSSES
	var rare := 1.0 if is_boss else 0.07
	if randf() < rare:
		_drop(Pickup.make("power_potion", 1), enemy.global_position)
	if randf() < rare:
		_drop(Pickup.make("speed_potion", 1), enemy.global_position)
	# loot that only sells at the market: bones are common, charms rare (bosses always drop a charm)
	var roll := randf()
	if is_boss or roll < 0.04:
		_drop(Pickup.make("junk_charm", 1), enemy.global_position)
	elif roll < 0.16:
		_drop(Pickup.make("junk_rust", 1), enemy.global_position)
	elif roll < 0.42:
		_drop(Pickup.make("junk_bone", 1), enemy.global_position)


func _drop(pickup: Pickup, at: Vector3) -> void:
	pickup.position = at + Vector3.UP * 0.8
	_loot.add_child(pickup)


func _respawn_later(index: int) -> void:
	await get_tree().create_timer(respawn_time).timeout
	var home := Vector3(SPAWNS[index][1], 0.0, SPAWNS[index][2])
	var player := get_tree().get_first_node_in_group("player") as Node3D
	while player and player.global_position.distance_to(home) < 25.0:
		await get_tree().create_timer(5.0).timeout  # never respawn in George's face
	_spawn(index)


## Returns the closest open position to `wanted` (spiralling outwards), or `wanted` itself.
func _free_spot(wanted: Vector3) -> Vector3:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.8
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var space := get_world_3d().direct_space_state
	for ring in range(0, 9):
		var steps := 1 if ring == 0 else ring * 6
		for i in steps:
			var angle := TAU * float(i) / float(steps)
			var pos := wanted + Vector3(cos(angle), 0.0, sin(angle)) * ring * 1.5
			query.transform = Transform3D(Basis.IDENTITY, pos + Vector3.UP * 1.1)
			if space.intersect_shape(query, 1).is_empty():
				return pos
	push_warning("enemies.gd: no free spot near %s" % wanted)
	return wanted
