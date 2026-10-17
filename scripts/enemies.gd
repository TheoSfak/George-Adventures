extends Node3D
## Places the skeleton enemies. Edit SPAWNS to add, move or remove them, and KINDS to
## tune each type. Positions are in metres like village.gd ((0, 0) is the well, -Z is
## north). Defeated skeletons come back after a while, except the named bosses.

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CHAR := "res://assets/characters/"
const WEAPONS := CHAR + "skeleton_weapons/"
const GRAVE := "res://assets/graveyard/"
const ROCK := "res://assets/world/decoration/nature/"
const PROP := "res://assets/world/decoration/props/"
const ITEMS := "res://assets/items/"

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
		"kind_id": "brute", "respawn_after": 60.0, "tint_color": Color(0.75, 0.15, 0.12, 0.30), "model_scale": 1.4,
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
	# Boss of every fifth night's invasion (invasion_boss.gd scales it by tier; it calls
	# minions while fighting and enrages at half health, like Malakar)
	"night_lord": {
		"kind_id": "night_lord", "respawn": false, "tint_color": Color(0.25, 0.20, 0.65, 0.34),
		"display_name": "Άρχοντας της Νύχτας", "model_scale": 2.4,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 900.0, "attack_damage": 28.0, "chase_speed": 4.0, "attack_range": 3.8,
		"attack_hit_time": 0.65, "attack_cooldown": 1.9, "aggro_range": 26.0, "leash_range": 60.0,
		"patrol_radius": 4.0,
		"summon_kind": "minion", "summon_interval": 12.0, "summon_max": 4,
		"enrage_below": 0.5, "enrage_summon": "warrior",
		"xp_reward": 500, "gold_min": 120, "gold_max": 160, "potion_chance": 1.0,
	},
	# Quest bosses (they come back one minute after they die: "respawn_after")
	"captain": {
		"kind_id": "captain", "respawn_after": 60.0,
		"display_name": "Λοχαγός των Νεκρών", "model_scale": 1.6,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Small_A.gltf",
		"max_health": 220.0, "attack_damage": 18.0, "chase_speed": 4.3, "attack_range": 3.0,
		"attack_hit_time": 0.55, "attack_cooldown": 1.7, "aggro_range": 20.0, "patrol_radius": 4.0,
		"xp_reward": 120, "gold_min": 40, "gold_max": 60, "potion_chance": 1.0,
	},
	"king": {
		"kind_id": "king", "respawn_after": 60.0,
		"display_name": "Βασιλιάς των Οστών", "model_scale": 2.3,
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Small_A.gltf",
		"max_health": 520.0, "attack_damage": 26.0, "chase_speed": 4.4, "attack_range": 4.2,
		"attack_hit_time": 0.6, "attack_cooldown": 1.8, "aggro_range": 26.0, "leash_range": 45.0,
		"patrol_radius": 3.0,
		"xp_reward": 400, "gold_min": 100, "gold_max": 140, "potion_chance": 1.0,
	},
	# --- the bandits (people, not skeletons): Adventurers models with one weapon each, tinted and named
	# (see docs/superpowers/specs/2026-10-14-bandits-design.md; the hideout is bandit_camp.gd)
	"bandit_thug": {
		"kind_id": "bandit_thug", "human": true, "walk_anim": "Walking_A", "tint_color": Color(0.55, 0.28, 0.12, 0.40),
		"model_path": CHAR + "Barbarian.glb", "show_nodes": ["1H_Axe", "Barbarian_Round_Shield"],
		"max_health": 60.0, "attack_damage": 14.0, "chase_speed": 4.0, "attack_range": 2.2,
		"attack_hit_time": 0.55, "attack_cooldown": 1.5, "aggro_range": 15.0, "patrol_radius": 4.0,
		"xp_reward": 35, "gold_min": 8, "gold_max": 18, "potion_chance": 0.35,
	},
	"bandit_archer": {
		"kind_id": "bandit_archer", "human": true, "walk_anim": "Walking_A", "tint_color": Color(0.20, 0.45, 0.16, 0.38),
		"model_path": CHAR + "Rogue.glb", "show_nodes": ["1H_Crossbow"],
		"ranged": true, "projectile_kind": "arrow", "shoot_anim": "1H_Ranged_Shoot", "projectile_speed": 17.0,
		"ranged_min": 6.0, "ranged_max": 13.0, "aggro_range": 17.0,
		"max_health": 40.0, "attack_damage": 11.0, "chase_speed": 4.0, "attack_cooldown": 2.1,
		"xp_reward": 38, "gold_min": 8, "gold_max": 18, "potion_chance": 0.35,
	},
	"bandit_thief": {
		"kind_id": "bandit_thief", "human": true, "walk_anim": "Walking_A", "tint_color": Color(0.20, 0.14, 0.34, 0.45),
		"model_path": CHAR + "Rogue_Hooded.glb", "show_nodes": ["Knife", "Knife_Offhand"],
		"max_health": 35.0, "attack_damage": 7.0, "chase_speed": 5.4, "attack_range": 1.9,
		"attack_hit_time": 0.3, "attack_cooldown": 0.8, "aggro_range": 16.0, "patrol_radius": 5.0,
		"xp_reward": 30, "gold_min": 10, "gold_max": 22, "potion_chance": 0.3,
	},
	"bandit_chief": {
		"kind_id": "bandit_chief", "respawn_after": 60.0, "human": true, "walk_anim": "Walking_A",
		"tint_color": Color(0.45, 0.10, 0.10, 0.30), "display_name": "Αρχηγός των Ληστών", "model_scale": 1.7,
		"model_path": CHAR + "Barbarian.glb", "show_nodes": ["2H_Axe"],
		"max_health": 450.0, "attack_damage": 24.0, "chase_speed": 4.2, "attack_range": 3.2, "attack_anim": "2H_Melee_Attack_Chop",
		"attack_hit_time": 0.7, "attack_cooldown": 1.9, "aggro_range": 24.0, "leash_range": 45.0, "patrol_radius": 3.0,
		"enrage_below": 0.5, "enrage_summon": "bandit_thug", "summon_interval": 12.0, "summon_max": 4,
		"xp_reward": 350, "gold_min": 100, "gold_max": 150, "potion_chance": 1.0,
	},
	# --- creatures made from props (no skeleton: static_rig.gd gives them hopping, lunging, rising and dying by code;
	# see docs/superpowers/specs/2026-10-14-more-mobs-design.md). The mimic is made by chest.gd where a "mimic" chest is opened.
	"pumpkin": {
		"kind_id": "pumpkin", "static_mob": true, "sound_set": "squish", "display_name": "Κολοκυθένιο Τέρας",
		"model_path": GRAVE + "pumpkin_orange_jackolantern.gltf", "model_scale": 1.0,
		"hop_height": 0.45, "hop_rate": 2.6, "glow_color": Color(1.0, 0.55, 0.15, 0.6),
		"max_health": 42.0, "attack_damage": 10.0, "chase_speed": 5.2, "patrol_speed": 1.8,
		"attack_range": 1.9, "attack_hit_time": 0.45, "static_attack_time": 0.9, "attack_cooldown": 1.3,
		"aggro_range": 12.0, "patrol_radius": 4.0,
		"xp_reward": 24, "gold_min": 3, "gold_max": 8, "potion_chance": 0.3,
	},
	"haunted_tree": {
		"kind_id": "haunted_tree", "static_mob": true, "sound_set": "wood", "display_name": "Στοιχειωμένο Δέντρο",
		"model_path": GRAVE + "tree_dead_medium.gltf", "model_scale": 1.0, "sway": 0.05,
		"max_health": 170.0, "attack_damage": 15.0, "chase_speed": 0.0, "patrol_speed": 0.0,
		"attack_range": 4.6, "attack_hit_time": 0.7, "static_attack_time": 1.3, "attack_cooldown": 2.0,
		"aggro_range": 9.0, "leash_range": 15.0, "patrol_radius": 0.5,
		"xp_reward": 40, "gold_min": 6, "gold_max": 14, "potion_chance": 0.4,
	},
	# A boulder that stands up when George comes within 6 m (or when it is hit): slow, hits like a hammer and slows him
	"golem": {
		"kind_id": "golem", "static_mob": true, "dormant": true, "wake_range": 6.0, "sound_set": "stone",
		"respawn_after": 60.0, "display_name": "Πέτρινος Γίγαντας", "wake_text": "Ο βράχος σηκώνεται!",
		"model_path": "", "model_scale": 1.8, "sway": 0.03,
		"parts": [
			{"path": ROCK + "rock_single_C.gltf", "pos": Vector3(0.0, 0.0, 0.0), "scale": Vector3(4.6, 8.5, 4.6)},
			{"path": ROCK + "rock_single_D.gltf", "pos": Vector3(0.0, 1.55, 0.1), "scale": Vector3(3.0, 4.2, 3.0), "yaw": 30.0},
			{"path": ROCK + "rock_single_D.gltf", "pos": Vector3(-0.95, 0.15, 0.1), "scale": Vector3(2.6, 6.0, 2.6), "yaw": 70.0},
			{"path": ROCK + "rock_single_D.gltf", "pos": Vector3(0.95, 0.15, 0.1), "scale": Vector3(2.6, 6.0, 2.6), "yaw": -70.0},
			{"eye": 0.07, "pos": Vector3(-0.2, 1.72, 0.42), "color": Color(1.0, 0.45, 0.1)},
			{"eye": 0.07, "pos": Vector3(0.2, 1.72, 0.42), "color": Color(1.0, 0.45, 0.1)},
		],
		"max_health": 260.0, "attack_damage": 24.0, "chase_speed": 2.6, "patrol_speed": 0.0,
		"attack_range": 3.2, "attack_hit_time": 0.8, "static_attack_time": 1.5, "attack_cooldown": 2.4, "stomp_slow": 2.0,
		"aggro_range": 12.0, "leash_range": 30.0,
		"xp_reward": 70, "gold_min": 12, "gold_max": 26, "potion_chance": 0.6,
	},
	# A pile of bones: wakes at 6.5 m or when hit and bursts into three skeletons, gone itself (no reward)
	"bone_heap": {
		"kind_id": "bone_heap", "static_mob": true, "dormant": true, "wake_range": 6.5, "sound_set": "bone",
		"wake_spawn": "minion", "wake_count": 3, "wake_text": "Τα κόκαλα ζωντανεύουν!",
		"model_path": "", "model_scale": 1.0,
		"parts": [
			{"path": GRAVE + "ribcage.gltf", "pos": Vector3(0.0, 0.4, 0.0), "scale": 1.8},
			{"path": GRAVE + "skull.gltf", "pos": Vector3(0.7, 0.0, 0.5), "scale": 1.1, "yaw": 150.0},
			{"path": GRAVE + "bone_C.gltf", "pos": Vector3(-0.7, 0.15, 0.3), "scale": 1.6, "yaw": 40.0},
			{"path": GRAVE + "bone_A.gltf", "pos": Vector3(0.1, 0.12, -0.8), "scale": 1.7, "yaw": 110.0},
			{"path": GRAVE + "bone_B.gltf", "pos": Vector3(-0.3, 0.55, 0.6), "scale": 1.6, "yaw": 75.0},
		],
		"max_health": 30.0, "attack_damage": 0.0, "chase_speed": 0.0, "patrol_speed": 0.0,
		"xp_reward": 0, "gold_min": 0, "gold_max": 0, "potion_chance": 0.0,
	},
	# The chest that was a creature (chest.gd spawns it where a "mimic" chest was opened; it never comes back)
	"mimic": {
		"kind_id": "mimic", "respawn": false, "static_mob": true, "sound_set": "mimic", "display_name": "Μίμικ",
		"model_path": ITEMS + "chest.glb", "model_scale": 1.25, "hop_height": 0.3, "hop_rate": 2.8,
		"max_health": 90.0, "attack_damage": 14.0, "chase_speed": 4.6, "patrol_speed": 0.0,
		"attack_range": 2.3, "attack_hit_time": 0.35, "static_attack_time": 0.8, "attack_cooldown": 1.1,
		"aggro_range": 30.0, "leash_range": 60.0,
		"xp_reward": 60, "gold_min": 40, "gold_max": 90, "potion_chance": 0.5,
	},
	# --- the cult in the ritual circle of the north-west forest (cult_site.gd; quest "cult")
	"cultist": {
		"kind_id": "cultist", "human": true, "walk_anim": "Walking_A", "tint_color": Color(0.55, 0.04, 0.12, 0.62),
		"display_name": "Οπαδός της Σέκτας",
		"model_path": CHAR + "Rogue_Hooded.glb", "show_nodes": [],
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 12.0,
		"ranged_min": 6.0, "ranged_max": 14.0, "aggro_range": 17.0, "leash_range": 30.0,
		"max_health": 55.0, "attack_damage": 11.0, "chase_speed": 4.0, "attack_cooldown": 2.2, "projectile_slows": true,
		"xp_reward": 34, "gold_min": 8, "gold_max": 18, "potion_chance": 0.4,
	},
	"cult_priest": {
		"kind_id": "cult_priest", "respawn_after": 60.0, "human": true, "walk_anim": "Walking_A",
		"tint_color": Color(0.30, 0.02, 0.07, 0.70), "display_name": "Αρχιερέας της Σέκτας", "model_scale": 1.6,
		"model_path": CHAR + "Mage.glb", "show_nodes": ["2H_Staff"],
		"max_health": 520.0, "attack_damage": 20.0, "chase_speed": 4.4, "attack_range": 3.0, "attack_anim": "2H_Melee_Attack_Chop",
		"attack_hit_time": 0.7, "attack_cooldown": 1.8, "aggro_range": 24.0, "leash_range": 45.0, "patrol_radius": 3.0,
		"summon_kind": "cultist", "summon_interval": 13.0, "summon_max": 3,
		"enrage_below": 0.5, "enrage_summon": "minion",
		"xp_reward": 360, "gold_min": 120, "gold_max": 200, "potion_chance": 1.0,
	},
	# --- new wanderers and threats of the island (Dark Knights, Witches, Thieves, Raiders, Cursed Coffins)
	"dark_knight": {
		"kind_id": "dark_knight", "human": true, "walk_anim": "Walking_A",
		"display_name": "Σκοτεινός Ιππότης", "model_scale": 1.25,
		"model_path": CHAR + "Knight.glb", "show_nodes": ["2H_Sword", "Knight_Helmet", "Knight_Cape"],
		"tint_color": Color(0.15, 0.08, 0.22, 0.80),
		"max_health": 170.0, "attack_damage": 25.0, "chase_speed": 3.8, "attack_range": 3.0,
		"attack_hit_time": 0.65, "attack_cooldown": 1.9, "attack_anim": "2H_Melee_Attack_Slice",
		"aggro_range": 18.0, "leash_range": 35.0, "patrol_radius": 4.0,
		"xp_reward": 75, "gold_min": 18, "gold_max": 40, "potion_chance": 0.5,
	},
	"witch": {
		"kind_id": "witch", "human": true, "walk_anim": "Walking_A",
		"display_name": "Μάγισσα των Σκιών", "model_scale": 1.0,
		"model_path": CHAR + "Mage.glb", "show_nodes": ["Spellbook", "Mage_Hat", "Mage_Cape"],
		"tint_color": Color(0.28, 0.05, 0.42, 0.72),
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 12.0,
		"ranged_min": 7.0, "ranged_max": 16.0, "aggro_range": 19.0, "leash_range": 32.0,
		"max_health": 80.0, "attack_damage": 18.0, "chase_speed": 4.0, "attack_cooldown": 2.2, "projectile_slows": true,
		"xp_reward": 60, "gold_min": 14, "gold_max": 30, "potion_chance": 0.45,
	},
	"thief": {
		"kind_id": "thief", "human": true, "walk_anim": "Walking_A",
		"display_name": "Άπληστος Κλέφτης", "model_scale": 1.0,
		"model_path": CHAR + "Rogue_Hooded.glb", "show_nodes": ["Knife", "Knife_Offhand", "Rogue_Cape"],
		"tint_color": Color(0.18, 0.26, 0.18, 0.65),
		"max_health": 55.0, "attack_damage": 11.0, "chase_speed": 5.4, "attack_cooldown": 1.1,
		"aggro_range": 22.0, "leash_range": 36.0, "steals_gold": 8,
		"xp_reward": 45, "gold_min": 20, "gold_max": 45, "potion_chance": 0.35,
	},
	"raider": {
		"kind_id": "raider", "human": true, "walk_anim": "Walking_A",
		"display_name": "Άγριος Επιδρομέας", "model_scale": 1.2,
		"model_path": CHAR + "Barbarian.glb", "show_nodes": ["2H_Axe", "Barbarian_Hat", "Barbarian_Cape"],
		"tint_color": Color(0.50, 0.15, 0.08, 0.58),
		"max_health": 135.0, "attack_damage": 22.0, "chase_speed": 4.5, "attack_range": 2.8,
		"attack_hit_time": 0.55, "attack_cooldown": 1.6, "attack_anim": "2H_Melee_Attack_Chop",
		"aggro_range": 18.0, "leash_range": 32.0,
		"xp_reward": 65, "gold_min": 14, "gold_max": 28, "potion_chance": 0.45,
	},
	"cursed_coffin": {
		"kind_id": "cursed_coffin", "static_mob": true, "dormant": true, "wake_range": 6.0, "sound_set": "wood",
		"display_name": "Καταραμένο Φέρετρο", "wake_text": "Το φέρετρο τρίζει και σηκώνεται!",
		"model_path": GRAVE + "coffin.gltf", "model_scale": 1.25, "sway": 0.04,
		"max_health": 120.0, "attack_damage": 16.0, "chase_speed": 3.8, "patrol_speed": 0.0,
		"attack_range": 2.8, "attack_hit_time": 0.4, "static_attack_time": 0.9, "attack_cooldown": 1.5,
		"aggro_range": 14.0, "leash_range": 28.0,
		"xp_reward": 50, "gold_min": 10, "gold_max": 25, "potion_chance": 0.4,
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
		"kind_id": "warden_bone", "respawn_after": 60.0, "quest": "wardens", "tint_color": Color(0.85, 0.9, 1.0, 0.20),
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
		"kind_id": "warden_flame", "respawn_after": 60.0, "quest": "wardens", "tint_color": Color(1.0, 0.45, 0.10, 0.38),
		"display_name": "Φύλακας της Φλόγας", "model_scale": 2.0,
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 13.0,
		"ranged_min": 7.0, "ranged_max": 15.0, "aggro_range": 22.0, "leash_range": 38.0, "patrol_radius": 3.0, "need_los": true,
		"max_health": 540.0, "attack_damage": 24.0, "chase_speed": 4.3, "attack_cooldown": 1.7,
		"xp_reward": 320, "gold_min": 70, "gold_max": 110, "potion_chance": 1.0,
	},
	"warden_shadow": {
		"kind_id": "warden_shadow", "respawn_after": 60.0, "quest": "wardens", "tint_color": Color(0.35, 0.12, 0.55, 0.45),
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
		"kind_id": "necromancer", "respawn_after": 60.0, "quest": "necro", "tint_color": Color(0.20, 0.90, 0.40, 0.32),
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
		"kind_id": "shadow_knight", "respawn_after": 60.0, "tint_color": Color(0.30, 0.20, 0.55, 0.34), "model_scale": 1.3,
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
		"kind_id": "giant_skeleton", "respawn_after": 60.0, "quest": "f_wall", "tint_color": Color(0.55, 0.50, 0.65, 0.28),
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
		"kind_id": "malakar", "respawn_after": 60.0, "quest": "f_malakar", "tint_color": Color(0.45, 0.10, 0.70, 0.36),
		"display_name": "Μαλάκαρ ο Σκοτεινός Άρχοντας", "model_scale": 2.5,
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "orb", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 13.0,
		"ranged_min": 7.0, "ranged_max": 16.0, "aggro_range": 28.0, "leash_range": 50.0, "patrol_radius": 2.0, "need_los": true,
		"max_health": 3200.0, "attack_damage": 36.0, "chase_speed": 4.4, "attack_cooldown": 2.0,
		"enrage_below": 0.5, "enrage_summon": "shadow_knight", "summon_interval": 12.0, "summon_max": 3,
		"xp_reward": 1800, "gold_min": 300, "gold_max": 380, "potion_chance": 1.0,
	},
	# --- the Ash Valley (placed by ash_valley.gd): base stats for a strong level-20 hero, LevelScaling adds the rest
	"ember_skeleton": {
		"kind_id": "ember_skeleton", "tint_color": Color(1.0, 0.38, 0.05, 0.36), "display_name": "Φλογοσκελετός",
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Small_A.gltf",
		"max_health": 300.0, "attack_damage": 34.0, "chase_speed": 5.0, "attack_cooldown": 1.5,
		"aggro_range": 16.0, "leash_range": 32.0,
		"xp_reward": 150, "gold_min": 15, "gold_max": 32, "potion_chance": 0.5,
	},
	# Ash caster: stays back and throws burning orbs
	"ash_caster": {
		"kind_id": "ash_caster", "tint_color": Color(1.0, 0.50, 0.10, 0.34), "display_name": "Στάχτινος Μάγος",
		"model_path": CHAR + "Skeleton_Mage.glb",
		"weapon_path": WEAPONS + "Skeleton_Staff.gltf",
		"ranged": true, "projectile_kind": "fire", "shoot_anim": "Spellcast_Shoot", "projectile_speed": 12.0,
		"ranged_min": 8.0, "ranged_max": 16.0, "aggro_range": 20.0, "leash_range": 34.0,
		"max_health": 160.0, "attack_damage": 30.0, "chase_speed": 3.9, "attack_cooldown": 2.4,
		"xp_reward": 140, "gold_min": 15, "gold_max": 32, "potion_chance": 0.5,
	},
	# A lump of cooled lava that stands up when George comes within 6 m (or when it is hit): slow, hits like a hammer and slows him
	"magma_golem": {
		"kind_id": "magma_golem", "static_mob": true, "dormant": true, "wake_range": 6.0, "sound_set": "stone",
		"respawn_after": 60.0, "display_name": "Γίγαντας του Μάγματος", "wake_text": "Το μάγμα ξυπνά!",
		"tint_color": Color(0.22, 0.05, 0.02, 0.70), "glow_color": Color(1.0, 0.40, 0.10, 0.5),
		"model_path": "", "model_scale": 2.0, "sway": 0.03,
		"parts": [
			{"path": ROCK + "rock_single_C.gltf", "pos": Vector3(0.0, 0.0, 0.0), "scale": Vector3(4.6, 8.5, 4.6)},
			{"path": ROCK + "rock_single_D.gltf", "pos": Vector3(0.0, 1.55, 0.1), "scale": Vector3(3.0, 4.2, 3.0), "yaw": 30.0},
			{"path": ROCK + "rock_single_D.gltf", "pos": Vector3(-0.95, 0.15, 0.1), "scale": Vector3(2.6, 6.0, 2.6), "yaw": 70.0},
			{"path": ROCK + "rock_single_D.gltf", "pos": Vector3(0.95, 0.15, 0.1), "scale": Vector3(2.6, 6.0, 2.6), "yaw": -70.0},
			{"eye": 0.09, "pos": Vector3(-0.2, 1.72, 0.42), "color": Color(1.0, 0.55, 0.05)},
			{"eye": 0.09, "pos": Vector3(0.2, 1.72, 0.42), "color": Color(1.0, 0.55, 0.05)},
		],
		"max_health": 900.0, "attack_damage": 52.0, "chase_speed": 2.8, "patrol_speed": 0.0,
		"attack_range": 3.4, "attack_hit_time": 0.8, "static_attack_time": 1.5, "attack_cooldown": 2.4, "stomp_slow": 2.0,
		"aggro_range": 12.0, "leash_range": 30.0,
		"xp_reward": 420, "gold_min": 40, "gold_max": 80, "potion_chance": 0.7,
	},
	# Ancient burning warlord of the eastern lava ridge
	"ash_lord": {
		"kind_id": "ash_lord", "respawn_after": 60.0, "tint_color": Color(1.0, 0.28, 0.05, 0.55),
		"display_name": "Ιγνάτιος ο Σταχτοφόρος", "model_scale": 1.9, "glow_color": Color(1.0, 0.40, 0.08, 0.7),
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Blade.gltf",
		"max_health": 2400.0, "attack_damage": 38.0, "chase_speed": 4.5, "attack_range": 3.2,
		"attack_hit_time": 0.6, "attack_cooldown": 1.7, "attack_anim": "1H_Melee_Attack_Slice_Horizontal",
		"aggro_range": 22.0, "leash_range": 42.0, "patrol_radius": 3.0, "need_los": true,
		"enrage_below": 0.4, "enrage_summon": "ember_skeleton", "summon_interval": 14.0, "summon_max": 3,
		"xp_reward": 2200, "gold_min": 350, "gold_max": 600, "potion_chance": 1.0,
	},
	# The boss of the Temple of the Flame: below half health he calls burning skeletons and speeds up
	"pyrforos": {
		"kind_id": "pyrforos", "respawn_after": 60.0, "quest": "a_boss", "tint_color": Color(1.0, 0.30, 0.04, 0.46),
		"display_name": "Πυρφόρος, ο Φύλακας της Φλόγας", "model_scale": 2.8, "glow_color": Color(1.0, 0.45, 0.10, 0.8),
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Axe.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 6000.0, "attack_damage": 55.0, "chase_speed": 4.2, "attack_range": 4.6,
		"attack_hit_time": 0.85, "attack_cooldown": 2.2, "attack_anim": "1H_Melee_Attack_Chop",
		"aggro_range": 26.0, "leash_range": 46.0, "patrol_radius": 3.0, "need_los": true,
		"enrage_below": 0.5, "enrage_summon": "ember_skeleton", "summon_interval": 12.0, "summon_max": 4,
		"xp_reward": 4000, "gold_min": 500, "gold_max": 650, "potion_chance": 1.0,
	},
	# --- Cursed Scarecrow in the wheat fields of the village
	"cursed_scarecrow": {
		"kind_id": "cursed_scarecrow", "static_mob": true, "sound_set": "scarecrow",
		"display_name": "Καταραμένο Σκιάχτρο", "model_scale": 1.35, "sway": 0.08,
		"model_path": "", "glow_color": Color(1.0, 0.45, 0.1, 0.7),
		"parts": [
			{"path": PROP + "target.gltf", "pos": Vector3(0.0, 0.0, 0.0), "scale": 1.25},
			{"path": GRAVE + "pumpkin_orange_jackolantern.gltf", "pos": Vector3(0.0, 1.85, 0.0), "scale": 0.85, "yaw": 0.0},
			{"path": GRAVE + "bone_A.gltf", "pos": Vector3(-0.75, 1.2, 0.1), "scale": 1.4, "yaw": 90.0},
			{"path": GRAVE + "bone_B.gltf", "pos": Vector3(0.75, 1.2, 0.1), "scale": 1.4, "yaw": -90.0},
			{"eye": 0.06, "pos": Vector3(-0.16, 1.95, 0.32), "color": Color(1.0, 0.4, 0.05)},
			{"eye": 0.06, "pos": Vector3(0.16, 1.95, 0.32), "color": Color(1.0, 0.4, 0.05)},
		],
		"max_health": 85.0, "attack_damage": 15.0, "chase_speed": 4.2, "patrol_speed": 1.5,
		"attack_range": 2.4, "attack_hit_time": 0.5, "static_attack_time": 1.0, "attack_cooldown": 1.4,
		"aggro_range": 14.0, "patrol_radius": 5.0,
		"xp_reward": 45, "gold_min": 6, "gold_max": 16, "potion_chance": 0.35,
	},
	# --- The Temple Sanctum (Άδυτο της Φλόγας): Cinder Guardians and the final boss Cinder Archon
	"cinder_guardian": {
		"kind_id": "cinder_guardian", "tint_color": Color(1.0, 0.22, 0.05, 0.65), "model_scale": 1.5,
		"display_name": "Φύλακας της Τέφρας",
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Shield_Large_A.gltf",
		"max_health": 550.0, "attack_damage": 42.0, "chase_speed": 4.6, "attack_range": 3.0,
		"attack_hit_time": 0.6, "attack_cooldown": 1.6, "attack_anim": "1H_Melee_Attack_Slice_Horizontal",
		"aggro_range": 18.0, "leash_range": 35.0,
		"xp_reward": 240, "gold_min": 35, "gold_max": 75, "potion_chance": 0.6,
	},
	"cinder_archon": {
		"kind_id": "cinder_archon", "respawn_after": 60.0, "quest": "t_archon",
		"display_name": "Ο Άρχοντας της Τέφρας", "model_scale": 3.2,
		"tint_color": Color(1.0, 0.15, 0.02, 0.75), "glow_color": Color(1.0, 0.35, 0.05, 0.9),
		"model_path": CHAR + "Skeleton_Warrior.glb",
		"weapon_path": WEAPONS + "Skeleton_Blade.gltf",
		"offhand_path": WEAPONS + "Skeleton_Blade.gltf",
		"max_health": 9500.0, "attack_damage": 68.0, "chase_speed": 4.5, "attack_range": 5.0,
		"attack_hit_time": 0.75, "attack_cooldown": 1.9, "attack_anim": "1H_Melee_Attack_Chop",
		"aggro_range": 28.0, "leash_range": 55.0, "patrol_radius": 3.0, "need_los": true,
		"enrage_below": 0.45, "enrage_summon": "cinder_guardian", "summon_interval": 11.0, "summon_max": 3,
		"xp_reward": 6000, "gold_min": 800, "gold_max": 1200, "potion_chance": 1.0,
	},
	# --- Feature 5: New Mobs (Orcs, Wolves, Spiders) ---
	"orc_warrior": {
		"kind_id": "orc_warrior", "human": false, "model_scale": 0.78,
		"model_path": CHAR + "Orc.glb",
		"walk_anim": "CharacterArmature|Walk", "idle_anim": "CharacterArmature|Idle",
		"run_anim": "CharacterArmature|Run", "attack_anim": "CharacterArmature|Weapon",
		"hit_anim": "CharacterArmature|HitReact", "death_anim": "CharacterArmature|Death",
		"sound_set": "orc",
		"max_health": 85.0, "attack_damage": 16.0, "chase_speed": 4.5, "attack_range": 2.4,
		"attack_hit_time": 0.5, "attack_cooldown": 1.5,
		"aggro_range": 16.0, "leash_range": 32.0, "patrol_radius": 5.0,
		"xp_reward": 45, "gold_min": 6, "gold_max": 14, "potion_chance": 0.35,
	},
	"orc_berserker": {
		"kind_id": "orc_berserker", "human": false, "model_scale": 0.88,
		"tint_color": Color(0.85, 0.20, 0.10, 0.25),
		"model_path": CHAR + "Orc.glb",
		"walk_anim": "CharacterArmature|Walk", "idle_anim": "CharacterArmature|Idle",
		"run_anim": "CharacterArmature|Run", "attack_anim": "CharacterArmature|Punch",
		"hit_anim": "CharacterArmature|HitReact", "death_anim": "CharacterArmature|Death",
		"sound_set": "orc",
		"max_health": 150.0, "attack_damage": 23.0, "chase_speed": 4.9, "attack_range": 2.7,
		"attack_hit_time": 0.55, "attack_cooldown": 1.4,
		"aggro_range": 18.0, "leash_range": 34.0, "patrol_radius": 6.0,
		"xp_reward": 80, "gold_min": 12, "gold_max": 24, "potion_chance": 0.5,
	},
	"orc_warlord": {
		"kind_id": "orc_warlord", "respawn_after": 60.0, "model_scale": 1.05,
		"tint_color": Color(0.95, 0.15, 0.05, 0.35), "display_name": "Γκρομ'γκαρ ο Αιμοδιψής",
		"model_path": CHAR + "Orc.glb",
		"walk_anim": "CharacterArmature|Walk", "idle_anim": "CharacterArmature|Idle",
		"run_anim": "CharacterArmature|Run", "attack_anim": "CharacterArmature|Weapon",
		"hit_anim": "CharacterArmature|HitReact", "death_anim": "CharacterArmature|Death",
		"sound_set": "orc",
		"max_health": 580.0, "attack_damage": 28.0, "chase_speed": 4.4, "attack_range": 3.4,
		"attack_hit_time": 0.6, "attack_cooldown": 1.7, "aggro_range": 22.0, "leash_range": 45.0,
		"enrage_below": 0.5, "enrage_summon": "orc_warrior", "summon_interval": 12.0, "summon_max": 3,
		"xp_reward": 350, "gold_min": 80, "gold_max": 140, "potion_chance": 1.0,
	},
	"wolf": {
		"kind_id": "wolf", "model_scale": 0.55,
		"model_path": CHAR + "Wolf.glb",
		"walk_anim": "AnimalArmature|Walk", "idle_anim": "AnimalArmature|Idle",
		"run_anim": "AnimalArmature|Gallop", "attack_anim": "AnimalArmature|Attack",
		"hit_anim": "AnimalArmature|Idle_HitReact_Left", "death_anim": "AnimalArmature|Death",
		"sound_set": "wolf",
		"max_health": 55.0, "attack_damage": 14.0, "chase_speed": 6.0, "attack_range": 2.2,
		"attack_hit_time": 0.45, "attack_cooldown": 1.2,
		"aggro_range": 19.0, "leash_range": 36.0, "patrol_radius": 7.0,
		"xp_reward": 30, "gold_min": 2, "gold_max": 6, "potion_chance": 0.25,
	},
	"spider": {
		"kind_id": "spider", "model_scale": 0.52,
		"model_path": CHAR + "Spider.glb",
		"walk_anim": "SpiderArmature|Spider_Walk", "idle_anim": "SpiderArmature|Spider_Idle",
		"run_anim": "SpiderArmature|Spider_Walk", "attack_anim": "SpiderArmature|Spider_Attack",
		"hit_anim": "SpiderArmature|Spider_Idle", "death_anim": "SpiderArmature|Spider_Death",
		"sound_set": "spider", "stomp_slow": 1.5,
		"max_health": 50.0, "attack_damage": 13.0, "chase_speed": 4.8, "attack_range": 2.4,
		"attack_hit_time": 0.5, "attack_cooldown": 1.4,
		"aggro_range": 17.0, "leash_range": 32.0, "patrol_radius": 5.0,
		"xp_reward": 32, "gold_min": 3, "gold_max": 7, "potion_chance": 0.3,
	},
}

# Bosses always drop buff potions and a charm.
const BOSSES: Array[String] = ["cult_priest", "bandit_chief", "captain", "king", "warden_bone", "warden_flame", "warden_shadow", "necromancer", "giant_skeleton", "malakar", "night_lord", "pyrforos", "ash_lord", "cinder_archon", "orc_warlord"]

# [kind, x, z]   (village houses stand within ~125 m of the well)
const SPAWNS := [
	# --- around the stolen wine barrels (quest "Τα Κλεμμένα Βαρέλια")
	["minion", -38.0, -138.0], ["minion", -22.0, -146.0],
	["minion", 112.0, -22.0], ["warrior", 110.0, -38.0],
	["minion", 18.0, 78.0], ["warrior", 34.0, 80.0],
	["warrior", -128.0, 76.0], ["minion", -116.0, 74.0],
	# --- wandering around the village outskirts
	["minion", 80.0, -112.0], ["warrior", 58.0, -118.0],
	["minion", -82.0, 75.0], ["minion", 96.0, 104.0],
	["warrior", -60.0, -110.0], ["minion", 146.0, 52.0],
	["minion", -150.0, -40.0],
	# --- the skeleton camp in the west (quest "Το Χαμένο Κλειδί")
	["warrior", -168.0, 8.0], ["warrior", -184.0, 30.0], ["minion", -160.0, 42.0],
	["minion", -178.0, -4.0], ["warrior", -190.0, 10.0], ["minion", -152.0, 22.0],
	# --- the quarry in the south-east (quest "Ο Λοχαγός των Νεκρών")
	["captain", 136.0, 118.0],
	["minion", 126.0, 112.0], ["minion", 154.0, 132.0], ["minion", 154.0, 108.0], ["warrior", 124.0, 136.0],
	# --- new mobs: archers hunt in the west and on the outskirts, brutes guard the quarry, mages haunt the crypt
	["rogue", -150.0, 36.0], ["rogue", -190.0, 40.0], ["rogue", -176.0, -14.0], ["rogue", -140.0, 4.0],
	["rogue", 42.0, -118.0], ["rogue", 112.0, 80.0], ["rogue", -96.0, -112.0],
	["brute", 132.0, 100.0], ["brute", 158.0, 118.0], ["brute", 68.0, 84.0], ["brute", -126.0, 75.0],
	["mage", 140.0, 134.0], ["mage", -34.0, -158.0], ["mage", 34.0, -158.0], ["mage", -34.0, -198.0], ["mage", 34.0, -198.0],
	["mage", -168.0, 22.0], ["mage", 100.0, -150.0],
	# --- the old crypt in the north (quest "Ο Βασιλιάς των Οστών")
	["king", 0.0, -182.0],
	["warrior", -10.0, -168.0], ["warrior", 16.0, -170.0],
	["minion", -26.0, -186.0], ["minion", 26.0, -186.0], ["minion", 0.0, -166.0],
	# --- the bandits' hideout in the north-west forest (bandit_camp.gd, centre (-140, -90)) and patrols on the roads
	["bandit_chief", -140.0, -98.0],
	["bandit_thug", -148.0, -88.0], ["bandit_thug", -132.0, -87.0], ["bandit_thug", -140.0, -81.0],
	["bandit_archer", -149.0, -95.0], ["bandit_archer", -131.0, -96.0], ["bandit_thief", -136.0, -84.0],
	["bandit_thug", 140.0, 10.0], ["bandit_archer", 143.0, 12.0],
	["bandit_thug", -20.0, 76.0], ["bandit_archer", -17.0, 78.0],
	["bandit_thug", 60.0, -160.0], ["bandit_archer", 63.0, -158.0],
	# --- creatures made from props: a pumpkin patch beside the crypt road, haunted trees at the graveyard, boulders that
	# stand up in the quarry, heaps of bones in the west and on the way to the bandits
	["pumpkin", 66.0, -172.0], ["pumpkin", 74.0, -168.0], ["pumpkin", 70.0, -177.0], ["pumpkin", 64.0, -166.0], ["pumpkin", 76.0, -175.0],
	["haunted_tree", -62.0, -186.0], ["haunted_tree", -52.0, -190.0], ["haunted_tree", 60.0, -190.0],
	["golem", 120.0, 130.0], ["golem", 144.0, 144.0], ["golem", 166.0, 116.0],
	["bone_heap", -166.0, 32.0], ["bone_heap", -192.0, 2.0], ["bone_heap", -112.0, -104.0], ["bone_heap", -30.0, -100.0],
	# --- the cult's ritual circle (cult_site.gd, centre (-80, -140)): five followers and the high priest
	["cult_priest", -80.0, -147.0],
	["cultist", -87.0, -135.0], ["cultist", -73.0, -135.0], ["cultist", -90.0, -143.0], ["cultist", -70.0, -144.0], ["cultist", -80.0, -130.0],
	# --- new roamers: Dark Knights, Witches, Thieves, Raiders, Cursed Coffins
	["dark_knight", -110.0, 72.0], ["dark_knight", 130.0, -120.0],
	["witch", -45.0, -180.0], ["witch", 45.0, -180.0],
	["thief", -60.0, 40.0], ["thief", 80.0, 20.0],
	["raider", -70.0, 74.0], ["raider", 90.0, 130.0],
	["cursed_coffin", -50.0, -195.0], ["cursed_coffin", 50.0, -195.0],
	# --- Cursed Scarecrows haunting the wheat fields and farm tracks
	["cursed_scarecrow", -114.0, -48.0], ["cursed_scarecrow", -86.0, -62.0], ["cursed_scarecrow", -102.0, -74.0], ["cursed_scarecrow", 86.0, 112.0],
	# --- Feature 5: Orcs, Wolves, and Spiders ---
	# The Orc Stronghold at the eastern ruined outpost (148, 68)
	["orc_warlord", 148.0, 72.0],
	["orc_berserker", 142.0, 68.0], ["orc_berserker", 154.0, 74.0],
	["orc_warrior", 136.0, 68.0], ["orc_warrior", 145.0, 58.0], ["orc_warrior", 154.0, 62.0],
	# The Wolves roaming the Autumn Golden Pine Forest (112, 68)
	["wolf", 110.0, 62.0], ["wolf", 116.0, 72.0], ["wolf", 104.0, 75.0], ["wolf", 122.0, 66.0],
	# Giant Spiders in the eastern Quarry rocks and cave path (158, 115)
	["spider", 162.0, 112.0], ["spider", 160.0, 120.0], ["spider", 168.0, 134.0], ["spider", 142.0, 106.0],
]

@export var respawn_time := 45.0     # seconds until a defeated skeleton returns

var _loot: Node3D
var _clock := 0.0                      # game seconds (stands still while the game is paused), for the respawn times
var _spawned := {}                     # spawn index -> the enemy that stands there now
var _due := {}                         # spawn index -> the clock time at which the defeated enemy comes back
var _pending_load := {}                # a saved game that arrived before the first spawn: applied right after it


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
	if not _pending_load.is_empty():
		var pending := _pending_load
		_pending_load = {}
		load_data(pending)


func _process(delta: float) -> void:
	_clock += delta
	if _due.is_empty():
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	for index in _due.keys():
		if _clock < float(_due[index]):
			continue
		var home := Vector3(SPAWNS[index][1], 0.0, SPAWNS[index][2])
		var clear := 40.0 if SPAWNS[index][0] in BOSSES else 25.0
		if player != null and player.global_position.distance_to(home) < clear:
			continue                               # never respawn in George's face
		_due.erase(index)
		_spawn(index)


func _spawn(index: int) -> void:
	var s: Array = SPAWNS[index]
	var enemy := _make(s[0], Vector3(s[1], 0.05, s[2]))
	enemy.died.connect(_on_enemy_died.bind(index))
	add_child(enemy)
	_spawned[index] = enemy


func _make(kind: String, pos: Vector3) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	var stats: Dictionary = KINDS[kind]
	for key in stats:
		if key != "respawn" and key != "respawn_after" and key != "quest":
			enemy.set(key, stats[key])
	enemy.position = _free_spot(pos)
	return enemy


## A creature of the catacombs or the Frontier (they call this once the rooms exist). Ordinary
## ones come back after a long while, the bosses and big ones after `respawn_after` (60 s).
## A quest boss is unique: while one is alive no second one appears.
func spawn_extra(kind: String, pos: Vector3) -> Enemy:
	var stats: Dictionary = KINDS[kind]
	if stats.has("quest"):
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.kind_id == kind and not e.is_dead():
				return e
	var enemy := _make(kind, pos)
	enemy.died.connect(_on_extra_died.bind(kind, pos))
	add_child(enemy)
	return enemy


## Helpers called by a boss (the necromancer's skeletons): they never come back. The
## helpers of a night invader march on the well too, so the invasion counts them.
func spawn_summon(kind: String, pos: Vector3, summoner: Enemy = null) -> Enemy:
	var enemy := _make(kind, pos)
	enemy.aggro_range = 30.0
	if summoner != null and summoner.invader:
		enemy.invader = true
		enemy.march_target = summoner.march_target
	enemy.died.connect(_on_enemy_died.bind(-1))
	add_child(enemy)
	return enemy


## The ring of skeletons around a victim (rescue event). They never respawn; XP, loot and
## quest kills work as for any skeleton.
func spawn_besiegers(kinds: Array, center: Vector3, target: Node3D) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for i in kinds.size():
		var angle := TAU * float(i) / float(kinds.size())
		var enemy := _make(kinds[i], center + Vector3(cos(angle), 0.0, sin(angle)) * 4.0)
		enemy.besiege_target = target
		enemy.patrol_radius = 0.5
		enemy.died.connect(_on_enemy_died.bind(-1))
		add_child(enemy)
		enemy.add_to_group("besiegers")
		out.append(enemy)
	return out


func _on_extra_died(enemy: Enemy, kind: String, home: Vector3) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.gain_xp(int(round(enemy.xp_reward * LevelScaling.xp_mult(player.level))))
	Quests.report_kill(enemy.kind_id)
	_drop_loot(enemy)
	if KINDS[kind].get("respawn", true):
		await get_tree().create_timer(KINDS[kind].get("respawn_after", respawn_time * 2.0)).timeout
		var clear := 40.0 if kind in BOSSES else 30.0
		while player and player.global_position.distance_to(home) < clear:
			await get_tree().create_timer(5.0).timeout     # never respawn in George's face
		spawn_extra(kind, home)


## A night invader: marches on the well, dies for good (index -1: no respawn).
## `overrides` are stats set before the enemy enters the tree (the Night Lord's tier scaling).
func spawn_invader(kind: String, pos: Vector3, target: Vector3 = Vector3.ZERO, overrides: Dictionary = {}) -> Enemy:
	var enemy := _make(kind, pos)
	for key in overrides:
		enemy.set(key, overrides[key])
	enemy.invader = true
	enemy.march_target = target
	enemy.aggro_range = maxf(enemy.aggro_range, 15.0)
	enemy.died.connect(_on_enemy_died.bind(-1))
	add_child(enemy)
	return enemy


func _on_enemy_died(enemy: Enemy, index: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.gain_xp(int(round(enemy.xp_reward * LevelScaling.xp_mult(player.level))))
	Quests.report_kill(enemy.kind_id)
	_drop_loot(enemy)
	if index >= 0:
		_spawned.erase(index)
		if KINDS[SPAWNS[index][0]].get("respawn", true):
			_respawn_later(index)


func _drop_loot(enemy: Enemy) -> void:
	if enemy.gold_max <= 0 and enemy.xp_reward <= 0:      # a creature that leaves nothing behind (the heap of bones that burst)
		return
	var gold := randi_range(enemy.gold_min, enemy.gold_max)
	var looter := get_tree().get_first_node_in_group("player") as Player
	if looter != null:
		gold = int(round(gold * LevelScaling.gold_mult(looter.level)))
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

	# crafting materials
	var mat_roll := randf()
	var kind := enemy.kind_id
	if kind in ["ember_skeleton", "ash_caster", "magma_golem", "pyrforos", "ash_lord", "cinder_archon", "cinder_guardian"]:
		if is_boss or mat_roll < 0.40:
			_drop(Pickup.make("junk_lava_ember", randi_range(1, 2) if is_boss else 1), enemy.global_position)
	elif bool(KINDS.get(kind, {}).get("human", false)) or kind in ["dark_knight", "raider", "thief", "bandit_chief"]:
		if is_boss or mat_roll < 0.45:
			_drop(Pickup.make("junk_iron_scrap", 1), enemy.global_position)
	else:
		if is_boss or mat_roll < 0.45:
			_drop(Pickup.make("junk_bone_shard", 1), enemy.global_position)


func _drop(pickup: Pickup, at: Vector3) -> void:
	pickup.position = at + Vector3.UP * 0.8
	_loot.add_child(pickup)


## A defeated spawn comes back after `delay` seconds (default: its kind's respawn time); `_process` does the rest.
func _respawn_later(index: int, delay: float = -1.0) -> void:
	var kind: String = SPAWNS[index][0]
	_due[index] = _clock + (delay if delay >= 0.0 else float(KINDS[kind].get("respawn_after", respawn_time)))


# ------------------------------------------------------------ save game ----

## What the save game remembers of the village spawns: which ones are defeated (and in how many seconds they come
## back) and how hurt the living ones are. Creatures of the catacombs and the Frontier and the night invaders are not saved.
func save_data() -> Dictionary:
	var dead := {}
	for index in _due:
		dead[str(index)] = snappedf(maxf(float(_due[index]) - _clock, 0.0), 0.1)
	var hurt := {}
	for index in _spawned:
		var e = _spawned[index]
		if is_instance_valid(e) and not e.is_dead() and e.health < e.max_health - 0.5:
			hurt[str(index)] = snappedf(e.health / e.max_health, 0.01)
	return {"dead": dead, "hurt": hurt}


## Puts a saved game into the running village (a save without this block leaves the village as it is).
func load_data(d: Dictionary) -> void:
	if d.is_empty():
		return
	if _spawned.is_empty() and _due.is_empty():
		_pending_load = d                        # the first spawn has not happened yet
		return
	var dead: Dictionary = d.get("dead", {})
	for index in SPAWNS.size():
		var key := str(index)
		var enemy = _spawned.get(index)
		if dead.has(key):
			if enemy != null and is_instance_valid(enemy):
				enemy.queue_free()               # no loot, no XP: it was defeated in the saved game
			_spawned.erase(index)
			_due[index] = _clock + float(dead[key])
		elif _due.has(index):
			_due.erase(index)                    # alive in the saved game, defeated in this session: it stands again
			_spawn(index)
	var hurt: Dictionary = d.get("hurt", {})
	for key in hurt:
		var enemy = _spawned.get(int(key))
		if enemy != null and is_instance_valid(enemy) and not enemy.is_dead():
			enemy.health = maxf(enemy.max_health * float(hurt[key]), 1.0)
			enemy._bar.visible = true
			enemy._update_health_bar()


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
