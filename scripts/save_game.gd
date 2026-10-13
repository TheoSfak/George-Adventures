class_name SaveGame
## The save game: one plain-text JSON file, user://savegame.json (open it in Notepad to look at
## it or edit your level and gold). One slot; the previous save is kept as savegame.bak.
##
## Saved: George (level, xp, gold, health, potions, gear, talents, action bar, fish journal, position),
## the quests, the time of day, defeated bosses, opened chests and collected quest items.
## Not saved: where ordinary skeletons stand (they respawn), a night invasion in progress,
## chests inside buildings. In the Frontier the real position is saved ("in_frontier": true)
## and loading rebuilds the region.
##
## SaveGame.start_action tells the next scene load what to do ("continue", "new", or "" for
## the title menu); it survives scene reloads because it is a static variable.

const PATH := "user://savegame.json"
const BACKUP := "user://savegame.bak"
const VERSION := 1

static var start_action := ""
static var menu_in_tests := false              # tools/menutest.gd turns the menu on in test drivers
static var defeated_bosses: Array = []        # kind ids of bosses that do not respawn
static var opened_chests: Array = []          # "x,z" of chests opened
static var collected_items: Array = []        # "item@x,z" of quest items picked up
static var destroyed_totems: Array = []       # "x,z" of bone totems broken


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	reset_progress()


static func reset_progress() -> void:
	defeated_bosses = []
	opened_chests = []
	collected_items = []
	destroyed_totems = []


static func key_for(position: Vector3) -> String:
	return "%d,%d" % [roundi(position.x), roundi(position.z)]


static func note_chest(position: Vector3) -> void:
	var k := key_for(position)
	if not opened_chests.has(k):
		opened_chests.append(k)


static func note_item(item_id: String, position: Vector3) -> void:
	var k := "%s@%s" % [item_id, key_for(position)]
	if not collected_items.has(k):
		collected_items.append(k)


static func note_totem(position: Vector3) -> void:
	var k := key_for(position)
	if not destroyed_totems.has(k):
		destroyed_totems.append(k)


static func note_boss(kind: String) -> void:
	if not defeated_bosses.has(kind):
		defeated_bosses.append(kind)


static func boss_defeated(kind: String) -> bool:
	return defeated_bosses.has(kind)


# --------------------------------------------------------------------- saving ----

static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Writes the save. Returns false when there is nothing to save (no player) or writing failed.
static func save() -> bool:
	var tree := _tree()
	var player := tree.get_first_node_in_group("player") as Player
	if player == null:
		return false
	var position := player.global_position
	var in_frontier := false
	var interiors := tree.get_first_node_in_group("interiors")
	if interiors != null and interiors.is_inside():
		position = interiors.exit_position()        # inside a building: save the doorstep
	elif interiors != null and interiors.in_region():
		in_frontier = true                          # in the Frontier: save the real position, load rebuilds the region
	var daynight := tree.get_first_node_in_group("daynight") as DayNight
	var data := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"player": {
			"level": player.level, "xp": player.xp, "gold": player.gold, "health": player.health,
			"base_max_health": player.base_max_health, "base_damage": player.base_damage,
			"consumables": player.consumables, "junk": player.junk,
			"gear_owned": player.gear_owned, "equipped": player.equipped,
			"talents": player.talents, "bar": player.bar,
			"position": [position.x, position.y, position.z], "heading": player._heading,
			"in_frontier": in_frontier,
			"fish_seen": player.fish_seen,
		},
		"quests": {"state": Quests.state, "progress": Quests.progress, "intro_seen": Quests.intro_seen},
		"world": {
			"time_of_day": daynight.time_of_day if daynight else 9.0,
			"day": daynight.day_number if daynight else 1,
			"night": daynight.night_number if daynight else 0,
			"defeated_bosses": defeated_bosses, "opened_chests": opened_chests, "collected_items": collected_items, "destroyed_totems": destroyed_totems,
		},
	}
	if exists():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BACKUP))
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("could not write %s" % PATH)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


# -------------------------------------------------------------------- loading ----

static func read() -> Dictionary:
	if not exists():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary and parsed.has("player"):
		return parsed
	push_warning("savegame.json is damaged")
	return {}


## One line for the "Continue" button: "Επίπεδο 5 · Ημέρα 2 · 21:30".
static func summary() -> String:
	var d := read()
	if d.is_empty():
		return ""
	var t: float = float(d["world"].get("time_of_day", 9.0))
	return "%s %d  ·  %s %d  ·  %02d:%02d" % [Strings.LEVEL_WORD, int(d["player"]["level"]), Strings.DAY_WORD,
			int(d["world"].get("day", 1)), int(t), int((t - floorf(t)) * 60.0)]


## Loads the quest/progress part before the world spawns (bosses, chests, items).
static func load_progress(d: Dictionary) -> void:
	var w: Dictionary = d.get("world", {})
	defeated_bosses = (w.get("defeated_bosses", []) as Array).duplicate()
	opened_chests = (w.get("opened_chests", []) as Array).duplicate()
	collected_items = (w.get("collected_items", []) as Array).duplicate()
	destroyed_totems = (w.get("destroyed_totems", []) as Array).duplicate()


## Puts a loaded save into the running game. The world must already be built.
static func apply(d: Dictionary) -> void:
	var tree := _tree()
	var player := tree.get_first_node_in_group("player") as Player
	if player == null or d.is_empty():
		return
	load_progress(d)
	var pd: Dictionary = d["player"]
	player.level = int(pd["level"])
	player.xp = int(pd["xp"])
	player.gold = int(pd["gold"])
	player.base_max_health = float(pd["base_max_health"])
	player.base_damage = float(pd["base_damage"])
	for id in pd.get("consumables", {}):
		player.consumables[id] = int(pd["consumables"][id])
	player.junk = {}
	for id in pd.get("junk", {}):
		player.junk[id] = int(pd["junk"][id])
	player.gear_owned.assign(pd.get("gear_owned", []))
	for slot in pd.get("equipped", {}):
		player.equipped[slot] = String(pd["equipped"][slot])
	player.talents = {}
	for id in pd.get("talents", {}):
		player.talents[id] = int(pd["talents"][id])
	player.bar.assign(pd.get("bar", []))
	player.fish_seen.assign(pd.get("fish_seen", []))
	player.is_dead = false
	player._recalc()
	player.health = minf(float(pd.get("health", player.max_health)), player.max_health)
	player._update_equipment_visuals()
	var pos: Array = pd["position"]
	var saved_pos := Vector3(float(pos[0]), float(pos[1]) + 0.05, float(pos[2]))
	var saved_heading := float(pd.get("heading", PI))
	var region_host := tree.get_first_node_in_group("interiors")
	if bool(pd.get("in_frontier", false)) and region_host != null:
		# the Frontier is built on demand: this fades, builds it and places George there a moment later
		region_host.enter_region("frontier", Frontier.VILLAGE_GATE + Vector3(0, 0.05, 5.0), 0.0, player, saved_pos, saved_heading)
	else:
		player.teleport(saved_pos, saved_heading)
	player.bar_changed.emit()
	player.talents_changed.emit()
	player.gear_changed.emit()
	player._announce()

	var qd: Dictionary = d["quests"]
	for id in qd["state"]:
		if Quests.state.has(id):
			Quests.state[id] = int(qd["state"][id])
	for id in qd["progress"]:
		if Quests.progress.has(id):
			var arr: Array = qd["progress"][id]
			for i in arr.size():
				if i < Quests.progress[id].size():
					Quests.progress[id][i] = int(arr[i])
	Quests._refresh_availability()    # quests added after the save was made (story part 2) unlock
	Quests.intro_seen = bool(qd.get("intro_seen", true))
	Quests.changed.emit()

	var wd: Dictionary = d["world"]
	var daynight := tree.get_first_node_in_group("daynight") as DayNight
	if daynight != null:
		daynight.time_of_day = float(wd.get("time_of_day", 9.0))
		daynight.day_number = int(wd.get("day", 1))
		daynight.night_number = int(wd.get("night", 0))
		daynight.phase = daynight._phase_for(daynight.time_of_day)
		if daynight.phase == DayNight.Phase.NIGHT or daynight.phase == DayNight.Phase.DUSK:
			daynight._shelter_villagers(true)
	for chest in tree.get_nodes_in_group("chests"):
		if opened_chests.has(key_for(chest.global_position)):
			chest.mark_opened()
	for totem in tree.get_nodes_in_group("breakables"):
		if destroyed_totems.has(key_for(totem.global_position)):
			totem.queue_free()
	for item in tree.get_nodes_in_group("quest_items"):
		if collected_items.has("%s@%s" % [item.get("item_id"), key_for(item.global_position)]):
			item.queue_free()
