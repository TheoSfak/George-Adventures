class_name ArenaData
extends RefCounted
## Gladiator Arena & Proving Grounds data: 5 trial tiers, wave compositions,
## champions, entry requirements, and rewards.

const TRIALS: Array[Dictionary] = [
	{
		"id": "bronze",
		"title": "Χάλκινη Δοκιμασία",
		"subtitle": "Δοκιμασία των Νεοσυλλέκτων",
		"desc": "Αντιμετώπισε τους πρώτους μονομάχους της αρένας και τον βαρύ πολεμιστή «Βράχο».",
		"rec_level": 5,
		"fee": 25,
		"tier_color": Color(0.85, 0.55, 0.28),
		"waves": [
			{
				"name": "Κύμα 1/3 — Εκπαιδευόμενοι",
				"spawns": [
					{"kind": "gladiator_recruit", "offset": Vector3(-4.0, 0.0, -3.0)},
					{"kind": "gladiator_recruit", "offset": Vector3(4.0, 0.0, -3.0)},
					{"kind": "gladiator_recruit", "offset": Vector3(0.0, 0.0, -5.0)},
				],
			},
			{
				"name": "Κύμα 2/3 — Οστέινοι Μονομάχοι",
				"spawns": [
					{"kind": "gladiator_skeleton", "offset": Vector3(-5.0, 0.0, -2.0)},
					{"kind": "gladiator_skeleton", "offset": Vector3(5.0, 0.0, -2.0)},
					{"kind": "gladiator_skeleton", "offset": Vector3(-2.0, 0.0, -5.0)},
					{"kind": "gladiator_skeleton", "offset": Vector3(2.0, 0.0, -5.0)},
				],
			},
			{
				"name": "Κύμα 3/3 — Πρωταθλητής: «Βράχος» ο Αήττητος",
				"is_boss": true,
				"boss_name": "«Βράχος» ο Αήττητος",
				"spawns": [
					{"kind": "arena_gorgor", "offset": Vector3(0.0, 0.0, -4.5)},
				],
			},
		],
		"reward": {
			"gold": 180,
			"xp": 400,
			"potions": 2,
			"trophy": "trophy_arena_bronze",
			"title": "Χάλκινος Μονομάχος",
		},
	},
	{
		"id": "silver",
		"title": "Ασημένια Δοκιμασία",
		"subtitle": "Δοκιμασία της Ταχύτητας & του Ατσαλιού",
		"desc": "Αντιμετώπισε επιδέξιους κουρσάρους, λύκους της αρένας και τον αδίστακτο Αρχικουρσάρο Σιδηρόχερο.",
		"rec_level": 12,
		"fee": 60,
		"tier_color": Color(0.85, 0.90, 0.98),
		"waves": [
			{
				"name": "Κύμα 1/3 — Επιδέξιοι Κουρσάροι",
				"spawns": [
					{"kind": "bandit_thief", "offset": Vector3(-4.5, 0.0, -2.5)},
					{"kind": "bandit_thief", "offset": Vector3(4.5, 0.0, -2.5)},
					{"kind": "bandit_archer", "offset": Vector3(-5.0, 0.0, -6.0)},
					{"kind": "bandit_archer", "offset": Vector3(5.0, 0.0, -6.0)},
				],
			},
			{
				"name": "Κύμα 2/3 — Αγέλη Λύκων Αρένας",
				"spawns": [
					{"kind": "wolf", "offset": Vector3(-4.0, 0.0, -3.0)},
					{"kind": "wolf", "offset": Vector3(4.0, 0.0, -3.0)},
					{"kind": "wolf", "offset": Vector3(0.0, 0.0, -5.5)},
				],
			},
			{
				"name": "Κύμα 3/3 — Πρωταθλητής: Αρχικουρσάρος Σιδηρόχερος",
				"is_boss": true,
				"boss_name": "Αρχικουρσάρος Σιδηρόχερος",
				"spawns": [
					{"kind": "arena_drake", "offset": Vector3(0.0, 0.0, -4.5)},
					{"kind": "bandit_thug", "offset": Vector3(-4.0, 0.0, -2.5)},
					{"kind": "bandit_thug", "offset": Vector3(4.0, 0.0, -2.5)},
				],
			},
		],
		"reward": {
			"gold": 450,
			"xp": 850,
			"potions": 3,
			"power": 1,
			"trophy": "trophy_arena_silver",
			"title": "Ασημένιος Μονομάχος",
		},
	},
	{
		"id": "gold",
		"title": "Χρυσή Δοκιμασία",
		"subtitle": "Δοκιμασία των Βαρβάρων & των Όρκ",
		"desc": "Αντιμετώπισε την πολεμική μανία των Όρκ και τον γιγάντιο δήμιο Βοργκ'θουλ.",
		"rec_level": 20,
		"fee": 120,
		"tier_color": Color(1.0, 0.82, 0.22),
		"waves": [
			{
				"name": "Κύμα 1/3 — Ορκ Πολεμιστές",
				"spawns": [
					{"kind": "orc_warrior", "offset": Vector3(-4.5, 0.0, -3.0)},
					{"kind": "orc_warrior", "offset": Vector3(4.5, 0.0, -3.0)},
					{"kind": "orc_warrior", "offset": Vector3(0.0, 0.0, -5.0)},
				],
			},
			{
				"name": "Κύμα 2/3 — Ορκ Berserkers & Μάγοι",
				"spawns": [
					{"kind": "orc_berserker", "offset": Vector3(-4.0, 0.0, -3.0)},
					{"kind": "orc_berserker", "offset": Vector3(4.0, 0.0, -3.0)},
					{"kind": "mage", "offset": Vector3(-5.0, 0.0, -6.0)},
					{"kind": "mage", "offset": Vector3(5.0, 0.0, -6.0)},
				],
			},
			{
				"name": "Κύμα 3/3 — Πρωταθλητής: Ορκ Μονομάχος Βοργκ'θουλ",
				"is_boss": true,
				"boss_name": "Ορκ Μονομάχος Βοργκ'θουλ",
				"spawns": [
					{"kind": "arena_vorgthul", "offset": Vector3(0.0, 0.0, -4.5)},
				],
			},
		],
		"reward": {
			"gold": 950,
			"xp": 1800,
			"potions": 4,
			"speed": 2,
			"trophy": "trophy_arena_gold",
			"title": "Χρυσός Μονομάχος",
		},
	},
	{
		"id": "heroic",
		"title": "Ηρωική Δοκιμασία",
		"subtitle": "Δοκιμασία των Τιτάνων & της Σκοτεινιάς",
		"desc": "Αντιμετώπισε επίλεκτους Σκοτεινούς Ιππότες, Πέτρινους Γίγαντες και τον Σκελετό Τιτάνα.",
		"rec_level": 28,
		"fee": 250,
		"tier_color": Color(0.72, 0.35, 0.95),
		"waves": [
			{
				"name": "Κύμα 1/3 — Σκοτεινή Φρουρά",
				"spawns": [
					{"kind": "dark_knight", "offset": Vector3(-4.0, 0.0, -3.0)},
					{"kind": "dark_knight", "offset": Vector3(4.0, 0.0, -3.0)},
					{"kind": "soul_collector", "offset": Vector3(0.0, 0.0, -6.0)},
				],
			},
			{
				"name": "Κύμα 2/3 — Πέτρινοι Γίγαντες & Στάχτινοι Μάγοι",
				"spawns": [
					{"kind": "golem", "offset": Vector3(-4.5, 0.0, -3.5)},
					{"kind": "golem", "offset": Vector3(4.5, 0.0, -3.5)},
					{"kind": "ash_caster", "offset": Vector3(0.0, 0.0, -6.0)},
				],
			},
			{
				"name": "Κύμα 3/3 — Πρωταθλητής: Σκελετός Τιτάνας των Κατακομβών",
				"is_boss": true,
				"boss_name": "Σκελετός Τιτάνας των Κατακομβών",
				"spawns": [
					{"kind": "arena_titan", "offset": Vector3(0.0, 0.0, -4.5)},
				],
			},
		],
		"reward": {
			"gold": 2000,
			"xp": 3500,
			"potions": 5,
			"power": 2,
			"speed": 2,
			"trophy": "trophy_arena_heroic",
			"title": "Ηρωικός Μονομάχος",
		},
	},
	{
		"id": "mythic",
		"title": "Μυθική Δοκιμασία των Πρωταθλητών",
		"subtitle": "Η Απόλυτη Αναμέτρηση της Αρένας",
		"desc": "Αντιμετώπισε τους ισχυρότερους εχθρούς του βασιλείου και τον θρυλικό Βαλθάζαρ, τον Αιώνιο Μονομάχο.",
		"rec_level": 36,
		"fee": 500,
		"tier_color": Color(1.0, 0.30, 0.15),
		"waves": [
			{
				"name": "Κύμα 1/3 — Επίλεκτοι Σκιώδεις Ιππότες",
				"spawns": [
					{"kind": "shadow_knight", "offset": Vector3(-4.5, 0.0, -3.0)},
					{"kind": "shadow_knight", "offset": Vector3(4.5, 0.0, -3.0)},
					{"kind": "ash_caster", "offset": Vector3(-3.0, 0.0, -6.0)},
					{"kind": "ash_caster", "offset": Vector3(3.0, 0.0, -6.0)},
				],
			},
			{
				"name": "Κύμα 2/3 — Πύρινος Άρχοντας Ιγνάτιος",
				"spawns": [
					{"kind": "ash_lord", "offset": Vector3(0.0, 0.0, -4.0)},
					{"kind": "ember_skeleton", "offset": Vector3(-5.0, 0.0, -2.0)},
					{"kind": "ember_skeleton", "offset": Vector3(5.0, 0.0, -2.0)},
				],
			},
			{
				"name": "Κύμα 3/3 — Υπέρτατος Πρωταθλητής: Βαλθάζαρ ο Αιώνιος Μονομάχος",
				"is_boss": true,
				"boss_name": "Βαλθάζαρ ο Αιώνιος Μονομάχος",
				"spawns": [
					{"kind": "arena_balthazar", "offset": Vector3(0.0, 0.0, -4.5)},
				],
			},
		],
		"reward": {
			"gold": 4000,
			"xp": 6000,
			"potions": 6,
			"power": 3,
			"speed": 3,
			"gear": "armor_gladiator_champion",
			"trophy": "trophy_arena_mythic",
			"title": "Πρωταθλητής του Αγίου Βλάση",
		},
	},
]

static func get_trial(trial_id: String) -> Dictionary:
	for t in TRIALS:
		if t["id"] == trial_id:
			return t
	return {}

static func is_unlocked(trial_id: String, completed_trials: Array) -> bool:
	if trial_id == "bronze":
		return true
	for i in range(1, TRIALS.size()):
		if TRIALS[i]["id"] == trial_id:
			var prev_id: String = TRIALS[i - 1]["id"]
			return completed_trials.has(prev_id)
	return false

static func can_start(trial_id: String, player_level: int, player_gold: int, completed_trials: Array) -> Dictionary:
	var trial := get_trial(trial_id)
	if trial.is_empty():
		return {"ok": false, "reason": "Άγνωστη δοκιμασία"}
	if not is_unlocked(trial_id, completed_trials):
		return {"ok": false, "reason": "Πρέπει πρώτα να ολοκληρώσεις την προηγούμενη δοκιμασία!"}
	if player_gold < int(trial["fee"]):
		return {"ok": false, "reason": "Δεν έχεις αρκετό χρυσό (%d απαιτούνται)!" % int(trial["fee"])}
	return {"ok": true, "reason": ""}
