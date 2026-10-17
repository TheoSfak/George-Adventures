class_name BountyManager
extends Node
## Central manager for the village Bounty Board system.
## Handles available board contracts, active player hunts, kill tracking,
## rewards distribution, and hunter rankings.

signal bounties_updated
signal bounty_progress(bounty_id: String, current: int, total: int)
signal bounty_ready_to_claim(bounty_id: String)
signal bounty_claimed(bounty_id: String, gold: int, xp: int)
signal hunter_rank_up(new_title: String)

const BountyDataClass := preload("res://scripts/bounty_data.gd")

var available_bounties: Array[Dictionary] = []
var active_bounties: Array[Dictionary] = []
var completed_count := 0

func _ready() -> void:
	add_to_group("bounty_manager")
	if available_bounties.is_empty():
		refresh_board_contracts()


## Generates 3 contracts for the board: 1 Bronze, 1 Silver, 1 Gold (or random mix).
func refresh_board_contracts() -> void:
	available_bounties.clear()
	var templates: Array[Dictionary] = BountyDataClass.CONTRACT_TEMPLATES.duplicate()
	templates.shuffle()

	# Pick 1 bronze, 1 silver, 1 gold if possible, or 3 unique
	var picked_ids: Array[String] = []

	# Check currently active IDs so we don't duplicate on board
	for a in active_bounties:
		picked_ids.append(String(a["id"]))

	for tier in ["bronze", "silver", "gold"]:
		for t in templates:
			var tid: String = t["id"]
			if t["tier"] == tier and not (tid in picked_ids):
				available_bounties.append(t.duplicate(true))
				picked_ids.append(tid)
				break

	# If fewer than 3, fill with any remaining template
	for t in templates:
		if available_bounties.size() >= 3:
			break
		var tid: String = t["id"]
		if not (tid in picked_ids):
			available_bounties.append(t.duplicate(true))
			picked_ids.append(tid)

	bounties_updated.emit()


func is_bounty_active(bounty_id: String) -> bool:
	for a in active_bounties:
		if a["id"] == bounty_id:
			return true
	return false


func get_active_bounty(bounty_id: String) -> Dictionary:
	for a in active_bounties:
		if a["id"] == bounty_id:
			return a
	return {}


func accept_bounty(bounty_id: String) -> bool:
	if is_bounty_active(bounty_id):
		return false
	var template := BountyDataClass.get_template(bounty_id)
	if template.is_empty():
		return false

	var contract := template.duplicate(true)
	contract["progress"] = 0
	contract["ready"] = false
	active_bounties.append(contract)

	# Remove from available board list
	for i in range(available_bounties.size() - 1, -1, -1):
		if available_bounties[i]["id"] == bounty_id:
			available_bounties.remove_at(i)
			break

	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		var p := tree.get_first_node_in_group("player") as Player
		if p != null and p.has_signal("message"):
			p.message.emit("Ανάληψη Επικήρυξης: «%s»!" % contract["title"])

	bounties_updated.emit()
	return true


func report_kill(kind: String) -> void:
	var any_changed := false
	for a in active_bounties:
		if a.get("ready", false):
			continue
		var target_kind: String = a.get("target_kind", "")
		if BountyDataClass.is_target_match(target_kind, kind):
			var current: int = int(a.get("progress", 0)) + 1
			var total: int = int(a.get("count", 1))
			a["progress"] = mini(current, total)
			any_changed = true

			var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			var p := tree.get_first_node_in_group("player") as Player if tree != null else null

			if a["progress"] >= total:
				a["ready"] = true
				bounty_ready_to_claim.emit(String(a["id"]))
				if p != null and p.has_signal("message"):
					p.message.emit("Επικήρυξη Ολοκληρώθηκε: «%s»! Επιστρέψτε στον Πίνακα για την αμοιβή." % a["title"])
					Sfx.ui("quest_ready")
			else:
				bounty_progress.emit(String(a["id"]), a["progress"], total)
				if p != null and p.has_signal("message"):
					p.message.emit("Επικήρυξη: %s (%d/%d)" % [a["target_name"], a["progress"], total])

	if any_changed:
		bounties_updated.emit()


func claim_bounty(bounty_id: String, player: Player) -> bool:
	var found_idx := -1
	for i in active_bounties.size():
		if active_bounties[i]["id"] == bounty_id:
			found_idx = i
			break

	if found_idx == -1:
		return false

	var contract: Dictionary = active_bounties[found_idx]
	if not bool(contract.get("ready", false)):
		return false

	var old_rank := BountyDataClass.get_hunter_rank(completed_count)
	completed_count += 1
	var new_rank := BountyDataClass.get_hunter_rank(completed_count)

	# Deliver rewards
	var gold: int = int(contract.get("reward_gold", 0))
	var xp: int = int(contract.get("reward_xp", 0))

	if player != null:
		player.gold += gold
		player.gain_xp(xp)

		# Add items
		var items: Dictionary = contract.get("reward_items", {})
		for item_id in items:
			var qty: int = int(items[item_id])
			if item_id == "potion":
				player.consumables["potion"] = player.consumables.get("potion", 0) + qty
			else:
				player.junk[item_id] = player.junk.get(item_id, 0) + qty

		if player.has_signal("message"):
			player.message.emit("Είσπραξη Επικήρυξης! +%d Χρυσός, +%d XP" % [gold, xp])
		Sfx.ui("quest_complete")

	active_bounties.remove_at(found_idx)
	bounty_claimed.emit(bounty_id, gold, xp)

	# Check rank promotion
	if String(new_rank["title"]) != String(old_rank["title"]):
		hunter_rank_up.emit(String(new_rank["title"]))
		if player != null and player.has_signal("message"):
			player.message.emit("ΝΕΟΣ ΤΙΤΛΟΣ ΚΥΝΗΓΟΥ: %s %s!" % [new_rank["badge"], new_rank["title"]])

	# Refill available contracts on board if under 3
	if available_bounties.size() < 3:
		_refill_single_contract()

	bounties_updated.emit()
	return true


func _refill_single_contract() -> void:
	var templates: Array[Dictionary] = BountyDataClass.CONTRACT_TEMPLATES.duplicate()
	templates.shuffle()
	var taken_ids: Array[String] = []
	for a in available_bounties:
		taken_ids.append(String(a["id"]))
	for a in active_bounties:
		taken_ids.append(String(a["id"]))

	for t in templates:
		if not (t["id"] in taken_ids):
			available_bounties.append(t.duplicate(true))
			break


func save_data() -> Dictionary:
	return {
		"completed_count": completed_count,
		"available": available_bounties,
		"active": active_bounties,
	}


func load_data(d: Dictionary) -> void:
	if d.is_empty():
		return
	completed_count = int(d.get("completed_count", 0))
	available_bounties.clear()
	for b in d.get("available", []):
		available_bounties.append(b as Dictionary)
	active_bounties.clear()
	for a in d.get("active", []):
		active_bounties.append(a as Dictionary)
	if available_bounties.is_empty():
		refresh_board_contracts()
	bounties_updated.emit()
