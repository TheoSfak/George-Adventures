class_name GameSettings
## Player settings, kept in the plain-text file user://settings.json (separate from the save
## game): volumes, audio output device and re-bound keys. Edit the file by hand if you like.
##
##   {"version": 1, "volumes": {"master": 1.0, "music": 0.8, ...}, "device": "Default",
##    "keys": {"move_forward": 87, ...}}        (key codes are Godot physical keycodes)

const PATH := "user://settings.json"
const VERSION := 1

## [action id, Greek label] shown in the settings window, in this order.
const REBINDABLE := [
	["move_forward", "Μπροστά"], ["move_back", "Πίσω"], ["turn_left", "Στροφή αριστερά"], ["turn_right", "Στροφή δεξιά"],
	["strafe_left", "Πλάγια αριστερά"], ["strafe_right", "Πλάγια δεξιά"], ["jump", "Άλμα"], ["run", "Τρέξιμο"],
	["attack", "Επίθεση"], ["block", "Άμυνα"], ["interact", "Δράση / Συνομιλία"], ["potion", "Φίλτρο υγείας"],
	["slot_1", "Δεξιότητα 1"], ["slot_2", "Δεξιότητα 2"], ["slot_3", "Δεξιότητα 3"], ["slot_4", "Δεξιότητα 4"],
	["slot_5", "Δεξιότητα 5"], ["slot_6", "Δεξιότητα 6"], ["slot_7", "Δεξιότητα 7"], ["slot_8", "Δεξιότητα 8"],
	["skillbook", "Ικανότητες"], ["talents", "Ταλέντα"], ["equipment", "Εξοπλισμός"], ["map", "Χάρτης"], ["mount", "Άλογο"],
]
const BUS_NAMES := {"master": "Master", "music": "Music", "sfx": "SFX", "ambient": "Ambient", "voice": "Voice"}
const DEFAULT_VOLUMES := {"master": 1.0, "music": 0.8, "sfx": 0.9, "ambient": 0.8, "voice": 1.0}

static var volumes := DEFAULT_VOLUMES.duplicate()
static var device := ""
static var keys := {}                  # action -> physical keycode (only the re-bound ones)
static var check_updates := true       # ask GitHub for a newer release when the title menu opens
static var _loaded := false


static func load_file() -> void:
	_loaded = true
	volumes = DEFAULT_VOLUMES.duplicate()
	device = ""
	keys = {}
	check_updates = true
	if not FileAccess.file_exists(PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_warning("settings.json is not valid, using defaults")
		return
	for id in DEFAULT_VOLUMES:
		if parsed.get("volumes", {}).has(id):
			volumes[id] = clampf(float(parsed["volumes"][id]), 0.0, 1.0)
	device = String(parsed.get("device", ""))
	for action in parsed.get("keys", {}):
		keys[String(action)] = int(parsed["keys"][action])
	check_updates = bool(parsed.get("check_updates", true))


static func save_file() -> void:
	var data := {"version": VERSION, "volumes": volumes, "device": device, "keys": keys, "check_updates": check_updates}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("could not write %s" % PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))


static func ensure_loaded() -> void:
	if not _loaded:
		load_file()


static func set_check_updates(on: bool) -> void:
	check_updates = on
	save_file()


# ------------------------------------------------------------------- audio ----

## Applies volumes and the output device (called once the audio buses exist, and after changes).
static func apply_audio() -> void:
	ensure_loaded()
	for id in BUS_NAMES:
		var idx := AudioServer.get_bus_index(BUS_NAMES[id])
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, _db(id))
	if device != "" and AudioServer.get_output_device_list().has(device):
		AudioServer.output_device = device


## Slider position 0..1 -> bus volume. Each bus has a base level (set when mixing the game)
## that the slider scales, so 1.0 means "as mixed".
const BASE_DB := {"master": 0.0, "music": -9.0, "sfx": -2.0, "ambient": -8.0, "voice": 0.0}


static func _db(id: String) -> float:
	var v: float = volumes[id]
	return -80.0 if v <= 0.001 else BASE_DB[id] + linear_to_db(v)


static func set_volume(id: String, value: float) -> void:
	volumes[id] = clampf(value, 0.0, 1.0)
	apply_audio()
	save_file()


static func set_device(name: String) -> void:
	device = name
	apply_audio()
	save_file()


# -------------------------------------------------------------------- keys ----

## Re-binds `action` to the key in `event` (a key press). Both the physical and the logical
## code are bound, so keys still work when a remote-desktop tool sends odd codes.
static func rebind(action: String, event: InputEventKey) -> void:
	var code: int = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	keys[action] = code
	_apply_key(action, code)
	save_file()


static func _apply_key(action: String, code: int) -> void:
	if not InputMap.has_action(action):
		return
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var physical := InputEventKey.new()
	physical.physical_keycode = code as Key
	InputMap.action_add_event(action, physical)
	var logical := InputEventKey.new()
	logical.keycode = code as Key
	InputMap.action_add_event(action, logical)


static func apply_keys() -> void:
	ensure_loaded()
	for action in keys:
		_apply_key(action, keys[action])


static func reset_keys() -> void:
	keys = {}
	save_file()
	var inputs: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Inputs")
	if inputs != null:
		inputs.restore_defaults()


## "W", "Space", "Left"... for the settings window.
static func key_name(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var k := ev as InputEventKey
			var code: int = k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			var s := OS.get_keycode_string(code as Key)
			if s != "":
				return s
	return "—"
