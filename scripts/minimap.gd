class_name Minimap
extends Control
## The corner minimap (big = false) and the full-screen map (big = true, toggled with M).
## Supports the main village of Agios Vlasis as well as outdoor expansion regions
## (The Frontier and the Ash Valley). Markers are drawn on top:
##   "!" a quest giver with a new quest   "?" a finished quest to hand in
##   gold diamond: something an active quest wants (quest items, bosses)
##   red dots: enemies   pulsing red ring: the well during a night invasion

const WORLD_HALF := 300.0           # village world half size
const CAPTURE_SIZE := 2048
# metres from the centre to the edge of the corner minimap, one entry per zoom step ([+] / [-] buttons)
const ZOOM_LEVELS: Array[float] = [35.0, 50.0, 70.0, 85.0, 120.0, 170.0]
const GOLD := Color(1.0, 0.82, 0.25)
const GREEN := Color(0.6, 0.95, 0.5)
const INK := Color(0.1, 0.07, 0.03)
const RED := Color(0.9, 0.2, 0.15)

# [Strings.MAP_PLACES key, x, z, optional label offset in px] places named on the big map
const PLACES := [
	["church", 0.0, -59.0], ["tavern", -59.0, -9.8], ["market", 59.0, -11.5], ["smith", -93.5, 29.5],
	["mill", 88.0, 32.0], ["windmill", -100.0, -54.1], ["tower", 95.1, -78.7], ["well", 0.0, 0.0],
	["camp", -175.0, 20.0, -24.0], ["quarry", 140.0, 125.0], ["crypt", 0.0, -178.0], ["bigtree", 172.0, -40.0],
	["stable", 63.0, 53.0], ["bandits", -140.0, -90.0], ["cult", -80.0, -140.0],
	["lighthouse", -115.0, 138.0], ["harbor", -35.0, 126.0], ["waterfall", 48.0, -132.0],
	["bridge_meadow", 70.0, -66.0], ["highlands", 82.0, -155.0], ["shipwreck", -72.0, 168.0],
	["cliffs", 64.0, 160.0], ["barracks", 78.0, -84.0], ["orc_stronghold", 150.0, 68.0],
	["golden_grove", 55.0, 25.0], ["grotto", -15.0, 142.0], ["bounty_board", -53.5, -12.5],
	["george_cottage", -28.0, -28.0], ["pirate_island", -20.0, 520.0], ["camp_babis", -22.0, 92.0],
	["pirate_lake", -75.0, 520.0], ["secret_pirate_cache", 35.0, 535.0],
]
const SHOPS := [
	Vector2(59.0, -11.5), Vector2(-93.5, 29.5),
	Vector2(78.0, -84.0), Vector2(-4.8, 9.2), Vector2(63.0, 53.0),
]
const BOSS_AREAS := {
	"captain": Vector2(142.0, 128.0), "king": Vector2(0.0, -190.0),
	"bandit_chief": Vector2(-140.0, -98.0), "bandit": Vector2(-140.0, -90.0),
	"cult_priest": Vector2(-80.0, -147.0), "cultist": Vector2(-80.0, -140.0),
	"orc_warlord": Vector2(150.0, 68.0), "orc": Vector2(150.0, 68.0),
	"warband_totem": Vector2(150.0, 68.0), "orc_catapult": Vector2(145.0, 79.0),
	"wolf": Vector2(55.0, 25.0), "spider": Vector2(140.0, 125.0),
	"brute": Vector2(140.0, 125.0), "cursed_scarecrow": Vector2(-95.0, -50.0),
	"pirate_captain": Vector2(-20.0, 520.0),
}

const REGION_DATA := {
	"": {
		"name": "Άγιος Βλάσης",
		"origin": Vector3.ZERO,
		"center_offset": Vector2.ZERO,
		"half": 300.0,
		"bg_color": Color(0.12, 0.17, 0.11),
		"shops": SHOPS,
		"places": PLACES,
		"boss_areas": BOSS_AREAS,
	},
	"frontier": {
		"name": "Τα Σύνορα",
		"origin": Vector3(-6000.0, 0.0, 6000.0),
		"center_offset": Vector2(0.0, -30.0),
		"half": 200.0,
		"bg_color": Color(0.13, 0.15, 0.18),
		"shops": [],
		"places": [
			["frontier_pass", 0.0, 118.0],
			["frontier_camp", 0.0, 0.0],
			["frontier_road", 0.0, -70.0],
			["frontier_fort", 0.0, -150.0],
		],
		"boss_areas": {
			"giant_skeleton": Vector2(0.0, -128.0),
			"malakar": Vector2(0.0, -156.0),
			"shadow_knight": Vector2(0.0, -80.0),
			"soul_collector": Vector2(0.0, -80.0),
			"raider": Vector2(0.0, 40.0),
		},
	},
	"ashvalley": {
		"name": "Κοιλάδα της Στάχτης",
		"origin": Vector3(6000.0, 0.0, -6000.0),
		"center_offset": Vector2(0.0, -40.0),
		"half": 200.0,
		"bg_color": Color(0.18, 0.10, 0.08),
		"shops": [Vector2(14.0, 40.0)],
		"places": [
			["ash_entry", 0.0, 116.0],
			["ash_shelter", 0.0, 30.0],
			["ash_bridge", 0.0, -60.0],
			["ash_temple", 0.0, -166.0],
		],
		"boss_areas": {
			"ash_lord": Vector2(52.0, -82.0),
			"pyrforos": Vector2(0.0, -166.0),
			"cinder_guardian": Vector2(0.0, -175.0),
			"cinder_archon": Vector2(0.0, -192.0),
		},
	},
}

static var world_texture: Texture2D
static var zoom_index := 3          # kept while the game runs

var big := false
var _player: Player
var _invasion
var _placed_border_markers: Array[Vector2] = []


## Zoom the corner minimap: +1 = closer, -1 = farther away.
static func zoom(step: int) -> void:
	zoom_index = clampi(zoom_index - step, 0, ZOOM_LEVELS.size() - 1)


static func view_half() -> float:
	return ZOOM_LEVELS[zoom_index]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if not big and world_texture == null:
		_capture_world.call_deferred()
	set_process(true)


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		_invasion = get_tree().get_first_node_in_group("invasion")
	if is_visible_in_tree():
		queue_redraw()


# ------------------------------------------------------------------ capture ----

## Takes a top-down picture of the village world with an orthographic camera.
func _capture_world() -> void:
	for i in 4:
		await get_tree().process_frame
	var hud_node := get_tree().get_first_node_in_group("hud")
	if hud_node == null or hud_node.get_parent() == null:
		return
	var main: Node = hud_node.get_parent()
	var vp := SubViewport.new()
	vp.size = Vector2i(CAPTURE_SIZE, CAPTURE_SIZE)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = WORLD_HALF * 2.0
	cam.near = 1.0
	cam.far = 900.0
	cam.basis = Basis(Vector3.RIGHT, -PI / 2.0)     # looks straight down, screen up = north (-Z)
	cam.position = Vector3(0.0, 400.0, 0.0)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.22, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 0.75
	cam.environment = env
	vp.add_child(cam)
	add_child(vp)

	var daynight := get_tree().get_first_node_in_group("daynight")
	var sun := main.get_node_or_null("Sun") as DirectionalLight3D
	var clouds := main.get_node_or_null("Village/Clouds") as Node3D
	var sun_saved := {}
	if daynight:
		daynight.set_process(false)
	if sun:
		sun_saved = {"visible": sun.visible, "energy": sun.light_energy, "basis": sun.basis, "color": sun.light_color}
		sun.visible = true
		sun.light_energy = 0.9
		sun.light_color = Color(1.0, 0.97, 0.9)
		sun.basis = Basis.looking_at(Vector3(-0.35, -1.0, -0.25).normalized(), Vector3.FORWARD)
	if clouds:
		clouds.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img := vp.get_texture().get_image()
	if sun and not sun_saved.is_empty():
		sun.visible = sun_saved["visible"]
		sun.light_energy = sun_saved["energy"]
		sun.light_color = sun_saved["color"]
		sun.basis = sun_saved["basis"]
	if clouds:
		clouds.visible = true
	if daynight:
		daynight.set_process(true)
	vp.queue_free()
	if img == null or img.is_empty():
		push_warning("minimap: could not capture the world")
		return
	img.generate_mipmaps()
	world_texture = ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ helpers ----

func _current_region() -> String:
	if not is_inside_tree():
		return ""
	var tree := get_tree()
	if tree == null:
		return ""
	var interiors := tree.get_first_node_in_group("interiors")
	if interiors != null and interiors.has_method("in_region") and interiors.in_region():
		return String(interiors.get("current_kind"))
	return ""


func _region_config(reg: String) -> Dictionary:
	if REGION_DATA.has(reg):
		return REGION_DATA[reg]
	return REGION_DATA[""]


func _to_map(p: Vector3) -> Vector2:
	var reg := _current_region()
	var cfg: Dictionary = _region_config(reg)
	if big:
		var local := Vector2(p.x - cfg["origin"].x - cfg["center_offset"].x, p.z - cfg["origin"].z - cfg["center_offset"].y)
		return (local + Vector2.ONE * cfg["half"]) / (cfg["half"] * 2.0) * size
	var centre := Vector2(_player.global_position.x, _player.global_position.z)
	return size / 2.0 + (Vector2(p.x, p.z) - centre) / view_half() * (size.x / 2.0)


func _inside_world(p: Vector3) -> bool:
	var reg := _current_region()
	var cfg: Dictionary = _region_config(reg)
	var local := Vector2(p.x - cfg["origin"].x - cfg["center_offset"].x, p.z - cfg["origin"].z - cfg["center_offset"].y)
	return absf(local.x) <= cfg["half"] * 1.15 and absf(local.y) <= cfg["half"] * 1.15


# ------------------------------------------------------------------ drawing ----

func _draw() -> void:
	var reg := _current_region()
	var cfg: Dictionary = _region_config(reg)
	draw_rect(Rect2(Vector2.ZERO, size), cfg["bg_color"])
	if _player == null:
		return
	_placed_border_markers.clear()
	if reg == "" and world_texture != null:
		var ppm := float(world_texture.get_width()) / (WORLD_HALF * 2.0)
		if big:
			draw_texture_rect(world_texture, Rect2(Vector2.ZERO, size), false)
		else:
			var centre := Vector2(_player.global_position.x, _player.global_position.z)
			var src_half := view_half() * ppm
			var src_centre := (centre + Vector2.ONE * WORLD_HALF) * ppm
			draw_texture_rect_region(world_texture, Rect2(Vector2.ZERO, size),
					Rect2(src_centre - Vector2.ONE * src_half, Vector2.ONE * src_half * 2.0))
	elif reg != "":
		_draw_region_terrain(reg, cfg)
	_draw_enemies(reg, cfg)
	_draw_guards(reg)
	_draw_shops_and_places(cfg)
	if reg == "":
		_draw_invasion_well()
		_draw_rescue_marker()
	_draw_quest_markers(cfg)
	_draw_player()
	if big:
		_draw_region_header(cfg["name"])


func _draw_region_terrain(reg: String, cfg: Dictionary) -> void:
	if reg == "frontier":
		# Mountain pass trail from south entry to fortress north
		var path_pts := [
			_to_map(cfg["origin"] + Vector3(0.0, 0.0, 120.0)),
			_to_map(cfg["origin"] + Vector3(6.0, 0.0, 80.0)),
			_to_map(cfg["origin"] + Vector3(-6.0, 0.0, 40.0)),
			_to_map(cfg["origin"] + Vector3(0.0, 0.0, 0.0)),
			_to_map(cfg["origin"] + Vector3(-4.0, 0.0, -50.0)),
			_to_map(cfg["origin"] + Vector3(0.0, 0.0, -114.0)),
			_to_map(cfg["origin"] + Vector3(0.0, 0.0, -150.0)),
		]
		draw_polyline(PackedVector2Array(path_pts), Color(0.24, 0.26, 0.30, 0.85), 7.0 if big else 4.5)
		# Refugee camp stockade ring
		var camp_pos := _to_map(cfg["origin"] + Vector3(0.0, 0.0, 0.0))
		var camp_r: float = 30.0 / (float(cfg["half"]) * 2.0) * size.x if big else 30.0 / view_half() * (size.x / 2.0)
		draw_circle(camp_pos, camp_r, Color(0.20, 0.22, 0.26, 0.5))
		draw_arc(camp_pos, camp_r, 0.0, TAU, 32, Color(0.38, 0.35, 0.30, 0.8), 2.0)
		# Fortress walls
		var fort_pos := _to_map(cfg["origin"] + Vector3(0.0, 0.0, -150.0))
		var fw: float = 46.0 / (float(cfg["half"]) * 2.0) * size.x if big else 46.0 / view_half() * (size.x / 2.0)
		var fh: float = 36.0 / (float(cfg["half"]) * 2.0) * size.y if big else 36.0 / view_half() * (size.y / 2.0)
		draw_rect(Rect2(fort_pos - Vector2(fw, fh), Vector2(fw * 2.0, fh * 2.0)), Color(0.18, 0.19, 0.24, 0.65))
		draw_rect(Rect2(fort_pos - Vector2(fw, fh), Vector2(fw * 2.0, fh * 2.0)), Color(0.35, 0.38, 0.45, 0.9), false, 2.0)
	elif reg == "ashvalley":
		# Shelter camp circle
		var shelter_pos := _to_map(cfg["origin"] + Vector3(0.0, 0.0, 30.0))
		var shelter_r: float = 28.0 / (float(cfg["half"]) * 2.0) * size.x if big else 28.0 / view_half() * (size.x / 2.0)
		draw_circle(shelter_pos, shelter_r, Color(0.24, 0.14, 0.12, 0.6))
		draw_arc(shelter_pos, shelter_r, 0.0, TAU, 32, Color(0.55, 0.35, 0.20, 0.8), 2.0)
		# Molten lava river winding across z = -60
		var lava_pts: Array[Vector2] = []
		for x_m in [-85.0, -50.0, -20.0, 0.0, 20.0, 50.0, 85.0]:
			var z_m := -60.0 + sin(x_m * 0.08) * 6.0
			lava_pts.append(_to_map(cfg["origin"] + Vector3(x_m, 0.0, z_m)))
		var lava_arr := PackedVector2Array(lava_pts)
		draw_polyline(lava_arr, Color(0.85, 0.20, 0.05, 0.9), 12.0 if big else 8.0)
		draw_polyline(lava_arr, Color(1.0, 0.70, 0.15, 0.95), 5.0 if big else 3.5)
		# Stone bridge across the lava
		var b_top := _to_map(cfg["origin"] + Vector3(0.0, 0.0, -52.0))
		var b_bot := _to_map(cfg["origin"] + Vector3(0.0, 0.0, -68.0))
		draw_line(b_top, b_bot, Color(0.35, 0.34, 0.33), 8.0 if big else 5.0)
		# Temple of the Flame outer courtyard
		var temple_pos := _to_map(cfg["origin"] + Vector3(0.0, 0.0, -165.0))
		var tw: float = 40.0 / (float(cfg["half"]) * 2.0) * size.x if big else 40.0 / view_half() * (size.x / 2.0)
		var th: float = 35.0 / (float(cfg["half"]) * 2.0) * size.y if big else 35.0 / view_half() * (size.y / 2.0)
		draw_rect(Rect2(temple_pos - Vector2(tw, th), Vector2(tw * 2.0, th * 2.0)), Color(0.25, 0.12, 0.10, 0.7))
		draw_rect(Rect2(temple_pos - Vector2(tw, th), Vector2(tw * 2.0, th * 2.0)), Color(0.85, 0.45, 0.20, 0.9), false, 2.0)
		# The Flame glowing core
		var flame_pos := _to_map(cfg["origin"] + Vector3(0.0, 0.0, -192.0))
		var flame_pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
		draw_circle(flame_pos, 7.0 * flame_pulse, Color(1.0, 0.5, 0.1, 0.8))
		draw_circle(flame_pos, 4.0 * flame_pulse, Color(1.0, 0.9, 0.4, 0.95))


func _draw_region_header(title: String) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 18).x
	var rect := Rect2(size.x / 2.0 - w / 2.0 - 24.0, 16.0, w + 48.0, 36.0)
	draw_rect(rect, Color(0.05, 0.06, 0.09, 0.90))
	draw_rect(rect, Color(0.92, 0.72, 0.34, 0.85), false, 1.5)
	draw_string(font, Vector2(size.x / 2.0 - w / 2.0, 41.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.88, 0.45))


func _draw_enemies(reg: String, cfg: Dictionary) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("is_dormant") and e.is_dormant():
			continue
		if not _inside_world(e.global_position):
			continue
		var kind: String = e.get("kind_id")
		var boss := kind in ["captain", "king", "warlord", "orc_warlord", "night_lord", "bandit_chief", "cult_priest", "giant_skeleton", "malakar", "pyrforos", "ash_lord", "cinder_archon"]
		var invader: bool = e.is_in_group("invaders")
		if big and not (boss or invader):
			continue
		var pos := _to_map(e.global_position)
		if not Rect2(Vector2.ZERO, size).grow(-3.0).has_point(pos):
			continue
		if boss:
			draw_circle(pos, 6.5, INK)
			draw_circle(pos, 5.0, RED)
			draw_line(pos + Vector2(-2.5, -2.5), pos + Vector2(2.5, 2.5), Color.WHITE, 1.6)
			draw_line(pos + Vector2(2.5, -2.5), pos + Vector2(-2.5, 2.5), Color.WHITE, 1.6)
		else:
			draw_circle(pos, 3.4, INK)
			draw_circle(pos, 2.5, Color(1.0, 0.45, 0.2) if invader else RED)


func _draw_guards(reg: String) -> void:
	if reg != "":
		return
	for g in get_tree().get_nodes_in_group("guards"):
		var pos := _to_map(g.global_position)
		if _on_map(pos, 3.0):
			draw_circle(pos, 3.6, INK)
			draw_circle(pos, 2.7, Color(0.45, 0.75, 1.0))


func _draw_shops_and_places(cfg: Dictionary) -> void:
	var font := ThemeDB.fallback_font
	var shops: Array = cfg.get("shops", [])
	var places: Array = cfg.get("places", [])
	for s in shops:
		var pos := _to_map(Vector3(cfg["origin"].x + s.x, 0.0, cfg["origin"].z + s.y))
		if Rect2(Vector2.ZERO, size).grow(-6.0).has_point(pos):
			draw_circle(pos, 8.0, INK)
			Icons.draw(self, Rect2(pos - Vector2(7, 7), Vector2(14, 14)), "coin", GOLD)
	if not big:
		return
	for pl in places:
		var pos := _to_map(Vector3(cfg["origin"].x + pl[1], 0.0, cfg["origin"].z + pl[2]))
		var key: String = pl[0]
		var text: String = Strings.MAP_PLACES.get(key, key)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var at := pos + Vector2(-w / 2.0, pl[3] if pl.size() > 3 else 22.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 5, INK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.98, 0.95, 0.85))


func _draw_invasion_well() -> void:
	if _invasion == null or not _invasion.active:
		return
	var pos := _to_map(Vector3.ZERO)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 5.0)
	var r := (14.0 if big else 9.0) + pulse * 4.0
	draw_arc(pos, r, 0.0, TAU, 32, Color(RED, 0.9), 2.5)
	draw_circle(pos, r * 0.6, Color(RED, 0.25 + 0.2 * pulse))


func _draw_quest_markers(cfg: Dictionary) -> void:
	var q: Node = get_node_or_null("/root/Quests")
	if q == null:
		return
	# Priority 1: Ready turn-ins ("?") and active quest objectives (diamonds)
	for n in get_tree().get_nodes_in_group("npcs"):
		if not _inside_world(n.global_position):
			continue
		var m: String = q.marker_for(n.get("npc_id")) if q.has_method("marker_for") else ""
		if m == "?":
			var pos := _to_map(n.global_position)
			_glyph(pos, m, GREEN)
			if big:
				_label(pos + Vector2(0, -16), QuestData.NPCS[n.get("npc_id")]["name"])

	for id in QuestData.QUESTS:
		if q.state[id] != Quests.S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if q.progress[id][i] >= o["count"]:
				continue
			match o["type"]:
				"collect":
					for it in get_tree().get_nodes_in_group("quest_items"):
						if it.visible and it.get("item_id") == o["item"] and _inside_world(it.global_position):
							_diamond(it.global_position)
				"reach":
					var reach_pos := Vector3.ZERO
					var pl: String = o.get("place", "")
					if pl == "catacombs":
						reach_pos = Vector3(0.0, 0.0, -178.0)
					elif pl == "frontier":
						reach_pos = Vector3(17.0, 0.0, -142.0)
					elif pl == "temple":
						reach_pos = cfg["origin"] + Vector3(0.0, 0.0, -165.0)
					if reach_pos != Vector3.ZERO and _inside_world(reach_pos):
						_diamond(reach_pos)
				"rescue":
					pass
				"kill":
					if o["target"] in ["totem", "warband_totem"]:
						for t in get_tree().get_nodes_in_group("breakables"):
							if t.visible and _inside_world(t.global_position):
								_diamond(t.global_position)
						for t in get_tree().get_nodes_in_group("totems"):
							if t.visible and _inside_world(t.global_position):
								_diamond(t.global_position)
						continue
					if o["target"] == "orc_catapult":
						for c in get_tree().get_nodes_in_group("interactables"):
							if c.visible and _inside_world(c.global_position) and (c.name.find("Catapult") >= 0 or c.name.find("catapult") >= 0 or (c.has_method("interact_prompt") and "Καταπέλτη" in c.interact_prompt())):
								_diamond(c.global_position)
						continue
					var found := false
					for e in get_tree().get_nodes_in_group("enemies"):
						var ek: String = e.get("kind_id")
						var matches := false
						if ek == o["target"]:
							matches = true
						elif o["target"] == "orc" and QuestData.is_orc(ek):
							matches = true
						elif o["target"] == "bandit" and QuestData.is_bandit(ek):
							matches = true
						if matches and o["target"] != "skeleton" and _inside_world(e.global_position):
							_diamond(e.global_position)
							found = true
					if not found and cfg["boss_areas"].has(o["target"]):
						var a: Vector2 = cfg["boss_areas"][o["target"]]
						_diamond(Vector3(cfg["origin"].x + a.x, 0.0, cfg["origin"].z + a.y))

	# Priority 2: Available quest givers ("!")
	for n in get_tree().get_nodes_in_group("npcs"):
		if not _inside_world(n.global_position):
			continue
		var m: String = q.marker_for(n.get("npc_id")) if q.has_method("marker_for") else ""
		if m == "!":
			var pos := _to_map(n.global_position)
			_glyph(pos, m, GOLD)
			if big:
				_label(pos + Vector2(0, -16), QuestData.NPCS[n.get("npc_id")]["name"])


## The friend in danger (rescue event): a pulsing red "!" with a ring.
func _draw_rescue_marker() -> void:
	var rescue := get_tree().get_first_node_in_group("rescue")
	if rescue == null:
		return
	var world: Vector3 = rescue.andreas_position()
	if world == Vector3.ZERO:
		return
	var urgent := Color(1.0, 0.35, 0.2)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 5.0)
	var raw := _to_map(world)
	var centre := size / 2.0
	var pos := raw
	var off := false
	if not big:
		var lim := size.x / 2.0 - 27.0
		var d := raw - centre
		if absf(d.x) > lim or absf(d.y) > lim:
			off = true
			pos = centre + d * (lim / maxf(absf(d.x), absf(d.y)))
	draw_arc(pos, 13.0 + pulse * 4.0, 0.0, TAU, 32, Color(urgent, 0.9), 2.5)
	draw_circle(pos, 9.5, INK)
	draw_circle(pos, 8.0, urgent)
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(-3.0, 5.5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	if off:
		var dir := (raw - centre).normalized()
		var side := Vector2(-dir.y, dir.x)
		var base := pos + dir * (13.0 + pulse * 2.0)
		var tip := pos + dir * (23.0 + pulse * 3.0)
		var arrow := PackedVector2Array([tip, base + side * 7.0, base - side * 7.0])
		draw_colored_polygon(arrow, urgent)
		arrow.append(arrow[0])
		draw_polyline(arrow, INK, 2.0)
		var metres := int(round(Vector2(world.x - _player.global_position.x, world.z - _player.global_position.z).length()))
		var text := "%d μ" % metres
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var at := pos - dir * 24.0 + Vector2(-w / 2.0, 5.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 5, INK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, urgent)
	elif big:
		var bob := 4.0 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
		var tip2 := pos + Vector2(0.0, -17.0 + bob)
		var arrow2 := PackedVector2Array([tip2, tip2 + Vector2(-9.0, -13.0), tip2 + Vector2(9.0, -13.0)])
		draw_colored_polygon(arrow2, urgent)
		arrow2.append(arrow2[0])
		draw_polyline(arrow2, INK, 2.0)
		var label := Strings.RESCUE_MAP_LABEL
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var lat := pos + Vector2(-lw / 2.0, 34.0)
		draw_string_outline(font, lat, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, INK)
		draw_string(font, lat, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, urgent)


func _on_map(pos: Vector2, margin: float) -> bool:
	return Rect2(Vector2.ZERO, size).grow(-margin).has_point(pos)


## Draws a quest glyph; on the corner minimap a marker that is off the edge sticks to the border
## and is spaced along the perimeter to prevent ugly stacking/clutter.
func _clamped(pos: Vector2) -> Vector2:
	if big:
		return pos
	var c := size / 2.0
	var d := pos - c
	var lim := size.x / 2.0 - 11.0
	var is_border := false
	if absf(d.x) > lim or absf(d.y) > lim:
		d *= lim / maxf(absf(d.x), absf(d.y))
		is_border = true
	var target := c + d
	if is_border:
		target = _declutter_border_pos(target, c, lim)
		_placed_border_markers.append(target)
	return target


func _declutter_border_pos(pos: Vector2, c: Vector2, lim: float) -> Vector2:
	var p := pos
	for attempt in 4:
		var too_close := false
		for existing in _placed_border_markers:
			if p.distance_to(existing) < 18.0:
				too_close = true
				break
		if not too_close:
			return p
		var rel := p - c
		if absf(rel.y + lim) < 1.0: # top edge: move right
			p.x = minf(p.x + 18.0, c.x + lim)
		elif absf(rel.x - lim) < 1.0: # right edge: move down
			p.y = minf(p.y + 18.0, c.y + lim)
		elif absf(rel.y - lim) < 1.0: # bottom edge: move left
			p.x = maxf(p.x - 18.0, c.x - lim)
		elif absf(rel.x + lim) < 1.0: # left edge: move up
			p.y = maxf(p.y - 18.0, c.y - lim)
		else:
			break
	return p


func _glyph(pos: Vector2, text: String, color: Color) -> void:
	pos = _clamped(pos)
	var font := ThemeDB.fallback_font
	draw_circle(pos, 9.5, INK)
	draw_circle(pos, 8.0, color)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, pos + Vector2(-w / 2.0, 5.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)


func _diamond(world: Vector3) -> void:
	var pos := _clamped(_to_map(world))
	var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
	var r := 8.5 * pulse
	var pts := PackedVector2Array([pos + Vector2(0, -r), pos + Vector2(r, 0), pos + Vector2(0, r), pos + Vector2(-r, 0)])
	draw_colored_polygon(pts, GOLD)
	pts.append(pts[0])
	draw_polyline(pts, INK, 2.0)


func _label(pos: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var at := pos + Vector2(-w / 2.0, 0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 5, INK)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GOLD)


func _draw_player() -> void:
	var pos := _to_map(_player.global_position)
	var f: Vector3 = _player._facing()
	var dir := Vector2(f.x, f.z).normalized()
	var side := Vector2(-dir.y, dir.x)
	var s := 9.0 if big else 7.5
	var tri := PackedVector2Array([pos + dir * s * 1.3, pos - dir * s * 0.8 + side * s * 0.8, pos - dir * s * 0.8 - side * s * 0.8])
	draw_colored_polygon(tri, Color(1.0, 0.97, 0.85))
	tri.append(tri[0])
	draw_polyline(tri, INK, 2.0)
