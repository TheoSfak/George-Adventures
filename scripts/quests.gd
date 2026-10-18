extends Node
## Quest manager (autoload "Quests"). Reads quest_data.gd, tracks which quests are
## available / active / ready to hand in / done, counts kills and collected items,
## and hands out rewards. Everything shown to the player is Greek.

signal changed                       # any quest state or progress changed
signal message(text: String)         # short notices for the HUD feed
signal quest_done(id: String)
signal game_finished                 # the final quest was handed in

enum S { LOCKED, AVAILABLE, ACTIVE, READY, DONE, FAILED }   # FAILED: an event quest that was lost

var intro_seen := false              # tests set this to true to skip the prologue
var state := {}                      # quest id -> S
var progress := {}                   # quest id -> Array[int], one counter per objective


func _ready() -> void:
	reset()


## Back to the start of the story (new game).
func reset() -> void:
	intro_seen = false
	state = {}
	progress = {}
	for id in QuestData.QUESTS:
		state[id] = S.LOCKED
		progress[id] = []
		for _o in QuestData.QUESTS[id]["objectives"]:
			progress[id].append(0)
	_refresh_availability()


func _refresh_availability() -> void:
	for id in QuestData.QUESTS:
		if state[id] != S.LOCKED or QuestData.QUESTS[id].get("event", false):
			continue
		var ok := true
		for req in QuestData.QUESTS[id]["requires"]:
			if state[req] != S.DONE:
				ok = false
		if ok:
			state[id] = S.AVAILABLE


# ------------------------------------------------------------ NPC talking ----

func npc_name(npc_id: String) -> String:
	return QuestData.NPCS[npc_id]["name"]


## "!" if this NPC has a new quest, "?" if a finished quest can be handed in, else "".
func marker_for(npc_id: String) -> String:
	for id in QuestData.QUESTS:
		var q: Dictionary = QuestData.QUESTS[id]
		if q["turn_in"] == npc_id and state[id] == S.READY:
			return "?"
	for id in QuestData.QUESTS:
		if QuestData.QUESTS[id]["giver"] == npc_id and state[id] == S.AVAILABLE:
			return "!"
	return ""


## What this NPC says right now. Returns {"speaker", "lines", "quest", "kind"}.
## Afterwards call finish_dialogue() with the same dictionary.
func dialogue_for(npc_id: String) -> Dictionary:
	var speaker := npc_name(npc_id)
	for id in QuestData.QUESTS:
		var q: Dictionary = QuestData.QUESTS[id]
		if q["turn_in"] == npc_id and state[id] == S.READY:
			return {"speaker": speaker, "lines": q["complete"], "quest": id, "kind": "complete"}
	for id in QuestData.QUESTS:
		var q: Dictionary = QuestData.QUESTS[id]
		if q["giver"] == npc_id and state[id] == S.AVAILABLE:
			return {"speaker": speaker, "lines": q["offer"], "quest": id, "kind": "offer"}
	for id in QuestData.QUESTS:
		var q: Dictionary = QuestData.QUESTS[id]
		if state[id] == S.ACTIVE and (q["giver"] == npc_id or q["turn_in"] == npc_id):
			return {"speaker": speaker, "lines": q["progress"], "quest": id, "kind": "progress"}
	var idle: Array = QuestData.NPCS[npc_id]["idle"]
	return {"speaker": speaker, "lines": [idle.pick_random()], "quest": "", "kind": "idle"}


func finish_dialogue(plan: Dictionary) -> void:
	var id: String = plan["quest"]
	match plan["kind"]:
		"offer":
			state[id] = S.ACTIVE
			message.emit(Strings.QUEST_NEW % QuestData.QUESTS[id]["title"])
			Sfx.ui("quest_new")
			_check_ready(id)
			changed.emit()
		"complete":
			_complete(id)


# ------------------------------------------------------------- progress ----

func report_kill(kind: String) -> void:
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		tree.call_group("bounty_manager", "report_kill", kind)
		tree.call_group("journal_manager", "report_kill", kind)
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "kill" and progress[id][i] < o["count"] and ((o["target"] == "skeleton" and QuestData.is_skeleton(kind)) or o["target"] == kind or (o["target"] == "bandit" and QuestData.is_bandit(kind)) or (o["target"] == "orc" and QuestData.is_orc(kind))):
				progress[id][i] += 1
		_check_ready(id)
	changed.emit()


func report_item(item_id: String) -> void:
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "collect" and o["item"] == item_id and progress[id][i] < o["count"]:
				progress[id][i] += 1
		_check_ready(id)
	changed.emit()


## The village survived a night invasion.
func report_defense() -> void:
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "defend" and progress[id][i] < o["count"]:
				progress[id][i] += 1
		_check_ready(id)
	changed.emit()


## George arrived somewhere a quest asks for ("catacombs").
func report_reach(place: String) -> void:
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "reach" and o["place"] == place and progress[id][i] < o["count"]:
				progress[id][i] += 1
		_check_ready(id)
	changed.emit()


## The rescue of Andreas succeeded (all besiegers dead while he lives).
func report_rescue() -> void:
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "rescue" and progress[id][i] < o["count"]:
				progress[id][i] += 1
		_check_ready(id)
	changed.emit()


## Quests that nobody hands out: an event (rescue.gd) starts them.
func start_event_quest(id: String) -> void:
	if state[id] != S.LOCKED and state[id] != S.AVAILABLE:
		return
	state[id] = S.ACTIVE
	message.emit(Strings.QUEST_NEW % QuestData.QUESTS[id]["title"])
	Sfx.ui("quest_new")
	changed.emit()


func fail_event_quest(id: String) -> void:
	if state[id] != S.ACTIVE and state[id] != S.READY:
		return
	state[id] = S.FAILED
	changed.emit()


## True while some active quest still wants something of this kind killed or destroyed.
func target_wanted(kind: String) -> bool:
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "kill" and o["target"] == kind and progress[id][i] < o["count"]:
				return true
	return false


## True while some active quest still needs this item (quest items only show up then).
func item_wanted(item_id: String) -> bool:
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if o["type"] == "collect" and o["item"] == item_id and progress[id][i] < o["count"]:
				return true
	return false


func _check_ready(id: String) -> void:
	if state[id] != S.ACTIVE:
		return
	var objectives: Array = QuestData.QUESTS[id]["objectives"]
	for i in objectives.size():
		if progress[id][i] < objectives[i]["count"]:
			return
	state[id] = S.READY
	message.emit(Strings.QUEST_READY % QuestData.QUESTS[id]["title"])
	Sfx.ui("quest_ready")


func _complete(id: String) -> void:
	var q: Dictionary = QuestData.QUESTS[id]
	state[id] = S.DONE
	message.emit(Strings.QUEST_DONE % q["title"])
	Sfx.ui("quest_done")
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.apply_reward(q["reward"])
	_refresh_availability()
	changed.emit()
	quest_done.emit(id)
	if q.get("ends_game", false):
		game_finished.emit()


# ------------------------------------------------------------- HUD data ----

## Active and ready quests for the tracker:
## [{"title": String, "lines": [String], "objectives": [{"text", "cur", "max"}], "ready": bool}]
func tracker() -> Array:
	var out := []
	for id in QuestData.QUESTS:
		if state[id] != S.ACTIVE and state[id] != S.READY:
			continue
		var q: Dictionary = QuestData.QUESTS[id]
		var lines := []
		var bars := []                    # one entry per objective, for the progress bars of the tracker
		if state[id] == S.READY:
			lines.append(Strings.RETURN_TO % npc_name(q["turn_in"]))
		else:
			var objectives: Array = q["objectives"]
			for i in objectives.size():
				lines.append("%s: %d/%d" % [objectives[i]["text"], progress[id][i], objectives[i]["count"]])
				bars.append({"text": objectives[i]["text"], "cur": progress[id][i], "max": objectives[i]["count"]})
		out.append({"title": q["title"], "lines": lines, "objectives": bars, "ready": state[id] == S.READY})
	return out
