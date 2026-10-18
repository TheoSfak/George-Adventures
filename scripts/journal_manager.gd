class_name JournalManager
extends Node
## Central manager for the Achievements & Bestiary Lore systems.
## Tracks mob kills, exploration stats, craft milestones, and awards achievements.

signal achievement_unlocked(ach_id: String, ach_data: Dictionary)
signal bestiary_updated(kind_id: String, new_kills: int)

const AchievementDataClass := preload("res://scripts/achievement_data.gd")
const BestiaryDataClass := preload("res://scripts/bestiary_data.gd")

var bestiary_kills: Dictionary = {}
var unlocked_achievements: Dictionary = {}
var stats: Dictionary = {
	"total_kills": 0,
	"skeleton_kills": 0,
	"orc_kills": 0,
	"bandit_kills": 0,
	"pirate_kills": 0,
	"wolf_kills": 0,
	"chests_opened": 0,
	"buried_chests_opened": 0,
	"fish_caught": 0,
	"herbs_harvested": 0,
	"hero_level": 1,
	"gold_held": 0,
	"castles_visited": 0,
}

var _visited_castles: Array[String] = []

func _ready() -> void:
	add_to_group("journal_manager")
	add_to_group("achievement_manager")


func report_kill(kind_id: String) -> void:
	if kind_id.is_empty():
		return
	var cur: int = int(bestiary_kills.get(kind_id, 0)) + 1
	bestiary_kills[kind_id] = cur
	bestiary_updated.emit(kind_id, cur)

	# Update stats
	stats["total_kills"] = int(stats.get("total_kills", 0)) + 1
	stats["kill_" + kind_id] = int(stats.get("kill_" + kind_id, 0)) + 1

	if _is_skeleton(kind_id):
		stats["skeleton_kills"] = int(stats.get("skeleton_kills", 0)) + 1
	elif _is_orc(kind_id):
		stats["orc_kills"] = int(stats.get("orc_kills", 0)) + 1
	elif _is_bandit(kind_id):
		stats["bandit_kills"] = int(stats.get("bandit_kills", 0)) + 1
	elif _is_pirate(kind_id):
		stats["pirate_kills"] = int(stats.get("pirate_kills", 0)) + 1
	elif kind_id == "wolf":
		stats["wolf_kills"] = int(stats.get("wolf_kills", 0)) + 1

	check_achievements()


func report_stat(stat_name: String, amount: int = 1) -> void:
	stats[stat_name] = int(stats.get(stat_name, 0)) + amount
	check_achievements()


func set_stat_max(stat_name: String, value: int) -> void:
	var cur: int = int(stats.get(stat_name, 0))
	if value > cur:
		stats[stat_name] = value
		check_achievements()


func report_castle_visit(castle_kind: String) -> void:
	if not (castle_kind in _visited_castles):
		_visited_castles.append(castle_kind)
		stats["castles_visited"] = _visited_castles.size()
		check_achievements()


func get_kill_count(kind_id: String) -> int:
	return int(bestiary_kills.get(kind_id, 0))


func get_bestiary_tier(kind_id: String) -> int:
	var entry := BestiaryDataClass.get_entry(kind_id)
	var is_boss: bool = entry.get("is_boss", false)
	return BestiaryDataClass.get_unlock_tier(get_kill_count(kind_id), is_boss)


func is_achievement_unlocked(ach_id: String) -> bool:
	return unlocked_achievements.has(ach_id)


func get_stat(stat_name: String) -> int:
	return int(stats.get(stat_name, 0))


func get_achievement_progress(ach: Dictionary) -> int:
	var stat_name: String = ach.get("stat", "")
	return get_stat(stat_name)


func check_achievements() -> void:
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		var player := tree.get_first_node_in_group("player") as Player
		if player:
			if player.level > int(stats.get("hero_level", 1)):
				stats["hero_level"] = player.level
			if player.gold > int(stats.get("gold_held", 0)):
				stats["gold_held"] = player.gold
			if player.cottage_owned:
				stats["cottage_owned"] = 1
			for part in player.gear_upgrades:
				if int(player.gear_upgrades[part]) >= 5:
					stats["gear_upgraded_5"] = 1

	for ach in AchievementDataClass.ACHIEVEMENTS:
		var aid: String = ach["id"]
		if unlocked_achievements.has(aid):
			continue
		var val: int = get_achievement_progress(ach)
		var target: int = int(ach.get("target", 1))
		if val >= target:
			_unlock(ach)


func _unlock(ach: Dictionary) -> void:
	var aid: String = ach["id"]
	unlocked_achievements[aid] = int(Time.get_unix_time_from_system())

	# Grant rewards
	var reward: Dictionary = ach.get("reward", {})
	var gold: int = int(reward.get("gold", 0))
	var xp: int = int(reward.get("xp", 0))
	var title: String = String(reward.get("title", ""))

	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		var player := tree.get_first_node_in_group("player") as Player
		if player:
			if gold > 0:
				player.gold += gold
				player.inventory_changed.emit(player.gold, player.potions)
			if xp > 0:
				player.gain_xp(xp)

	achievement_unlocked.emit(aid, ach)

	# Notify HUD toast
	if tree != null:
		var hud := tree.get_first_node_in_group("hud")
		if hud and hud.has_method("show_achievement_toast"):
			hud.show_achievement_toast(ach)


func _is_skeleton(kind_id: String) -> bool:
	return kind_id in [
		"minion", "warrior", "rogue", "mage", "brute", "captain", "king",
		"cguard", "acolyte", "warden_bone", "warden_flame", "warden_shadow",
		"necromancer", "shadow_knight", "soul_collector", "giant_skeleton",
		"malakar", "ember_skeleton", "ash_caster", "ash_lord", "gladiator_skeleton"
	]


func _is_orc(kind_id: String) -> bool:
	return kind_id in ["orc_warrior", "orc_berserker", "orc_warlord", "arena_vorgthul"]


func _is_bandit(kind_id: String) -> bool:
	return kind_id in ["bandit_thug", "bandit_archer", "bandit_thief", "bandit_chief", "thief", "raider"]


func _is_pirate(kind_id: String) -> bool:
	return kind_id in ["pirate_corsair", "pirate_captain", "arena_drake"]


func save_data() -> Dictionary:
	return {
		"bestiary_kills": bestiary_kills,
		"unlocked_achievements": unlocked_achievements,
		"stats": stats,
		"visited_castles": _visited_castles,
	}


func load_data(data: Dictionary) -> void:
	if data.has("bestiary_kills") and data["bestiary_kills"] is Dictionary:
		bestiary_kills = data["bestiary_kills"].duplicate()
	if data.has("unlocked_achievements") and data["unlocked_achievements"] is Dictionary:
		unlocked_achievements = data["unlocked_achievements"].duplicate()
	if data.has("stats") and data["stats"] is Dictionary:
		stats = data["stats"].duplicate()
	if data.has("visited_castles") and data["visited_castles"] is Array:
		_visited_castles.clear()
		for c in data["visited_castles"]:
			_visited_castles.append(str(c))
