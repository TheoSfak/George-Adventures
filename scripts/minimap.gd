class_name Minimap
extends Control
## The corner minimap (big = false) and the full-screen map (big = true, toggled with M).
## The terrain picture is a top-down photo of the real world, taken once at start-up
## (see _capture_world) and shared by both. Markers are drawn on top:
##   "!" a quest giver with a new quest   "?" a finished quest to hand in
##   gold diamond: something an active quest wants (quest items, bosses)
##   red dots: enemies   pulsing red ring: the well during a night invasion

const WORLD_HALF := 300.0           # the captured picture covers x, z in -300 .. 300 m
const CAPTURE_SIZE := 2048
# metres from the centre to the edge of the corner minimap, one entry per zoom step ([+] / [-] buttons)
const ZOOM_LEVELS: Array[float] = [35.0, 50.0, 70.0, 85.0, 120.0, 170.0]
const GOLD := Color(1.0, 0.82, 0.25)
const GREEN := Color(0.6, 0.95, 0.5)
const INK := Color(0.1, 0.07, 0.03)
const RED := Color(0.9, 0.2, 0.15)

# [Strings.MAP_PLACES key, x, z, optional label offset in px (default +22 = below)] places named on the big map
const PLACES := [
	["church", 0.0, -59.0], ["tavern", -59.0, -9.8], ["market", 59.0, -11.5], ["smith", -93.5, 29.5],
	["mill", 95.1, 39.4], ["windmill", -100.0, -54.1], ["tower", 95.1, -78.7], ["well", 0.0, 0.0],
	["camp", -175.0, 20.0, -24.0], ["quarry", 140.0, 125.0], ["crypt", 0.0, -178.0], ["bigtree", 172.0, -40.0],
	["stable", 63.0, 53.0], ["bandits", -140.0, -90.0], ["cult", -80.0, -140.0],
]
const SHOPS := [Vector2(59.0, -11.5), Vector2(-93.5, 29.5)]
# where a boss quest points when the boss itself cannot be found (x, z)
const BOSS_AREAS := {"captain": Vector2(142.0, 128.0), "king": Vector2(0.0, -190.0), "bandit_chief": Vector2(-140.0, -98.0), "bandit": Vector2(-140.0, -90.0),
		"cult_priest": Vector2(-80.0, -147.0), "cultist": Vector2(-80.0, -140.0)}

static var world_texture: Texture2D
static var zoom_index := 3          # kept while the game runs

var big := false
var _player: Player
var _invasion


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

## Takes a top-down picture of the whole world with an orthographic camera. The sun is
## fixed and the clouds hidden for that one frame so the map looks the same at any hour.
func _capture_world() -> void:
	for i in 4:
		await get_tree().process_frame
	var main := get_tree().get_first_node_in_group("hud").get_parent()
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


# ------------------------------------------------------------------ drawing ----

func _to_map(p: Vector3) -> Vector2:
	if big:
		return (Vector2(p.x, p.z) + Vector2.ONE * WORLD_HALF) / (WORLD_HALF * 2.0) * size
	var centre := Vector2(_player.global_position.x, _player.global_position.z)
	return size / 2.0 + (Vector2(p.x, p.z) - centre) / view_half() * (size.x / 2.0)


func _inside_world(p: Vector3) -> bool:
	return absf(p.x) < WORLD_HALF and absf(p.z) < WORLD_HALF


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.17, 0.11))
	if _player == null:
		return
	if world_texture != null:
		var ppm := float(world_texture.get_width()) / (WORLD_HALF * 2.0)
		if big:
			draw_texture_rect(world_texture, Rect2(Vector2.ZERO, size), false)
		else:
			var centre := Vector2(_player.global_position.x, _player.global_position.z)
			var src_half := view_half() * ppm
			var src_centre := (centre + Vector2.ONE * WORLD_HALF) * ppm
			draw_texture_rect_region(world_texture, Rect2(Vector2.ZERO, size),
					Rect2(src_centre - Vector2.ONE * src_half, Vector2.ONE * src_half * 2.0))
	_draw_enemies()
	_draw_guards()
	_draw_shops_and_places()
	_draw_invasion_well()
	_draw_quest_markers()
	_draw_rescue_marker()
	_draw_player()


func _draw_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("is_dormant") and e.is_dormant():
			continue
		var kind: String = e.get("kind_id")
		var boss := kind == "captain" or kind == "king" or kind == "warlord" or kind == "night_lord" or kind == "bandit_chief" or kind == "cult_priest"
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


func _draw_guards() -> void:
	for g in get_tree().get_nodes_in_group("guards"):
		var pos := _to_map(g.global_position)
		if _on_map(pos, 3.0):
			draw_circle(pos, 3.6, INK)
			draw_circle(pos, 2.7, Color(0.45, 0.75, 1.0))


func _draw_shops_and_places() -> void:
	var font := ThemeDB.fallback_font
	for s in SHOPS:
		var pos := _to_map(Vector3(s.x, 0.0, s.y))
		if Rect2(Vector2.ZERO, size).grow(-6.0).has_point(pos):
			draw_circle(pos, 8.0, INK)
			Icons.draw(self, Rect2(pos - Vector2(7, 7), Vector2(14, 14)), "coin", GOLD)
	if not big:
		return
	for pl in PLACES:
		var pos := _to_map(Vector3(pl[1], 0.0, pl[2]))
		var text: String = Strings.MAP_PLACES[pl[0]]
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


func _draw_quest_markers() -> void:
	# quest givers and hand-in NPCs
	for n in get_tree().get_nodes_in_group("npcs"):
		if not _inside_world(n.global_position):
			continue   # shopkeepers stand in rooms far outside the map
		var m := Quests.marker_for(n.get("npc_id"))
		if m == "":
			continue
		var pos := _to_map(n.global_position)
		_glyph(pos, m, GOLD if m == "!" else GREEN)
		if big:
			_label(pos + Vector2(0, -16), QuestData.NPCS[n.get("npc_id")]["name"])
	# what the active quests want
	for id in QuestData.QUESTS:
		if Quests.state[id] != Quests.S.ACTIVE:
			continue
		var objectives: Array = QuestData.QUESTS[id]["objectives"]
		for i in objectives.size():
			var o: Dictionary = objectives[i]
			if Quests.progress[id][i] >= o["count"]:
				continue
			match o["type"]:
				"collect":
					for it in get_tree().get_nodes_in_group("quest_items"):
						if it.visible and it.get("item_id") == o["item"] and _inside_world(it.global_position):
							_diamond(it.global_position)
				"rescue":
					pass                       # drawn by _draw_rescue_marker (red, with an arrow)
				"kill":
					if o["target"] == "totem":
						for t in get_tree().get_nodes_in_group("breakables"):
							if t.visible:
								_diamond(t.global_position)
						continue
					var found := false
					for e in get_tree().get_nodes_in_group("enemies"):
						if e.get("kind_id") == o["target"] and o["target"] != "skeleton" and _inside_world(e.global_position):
							_diamond(e.global_position)
							found = true
					if not found and BOSS_AREAS.has(o["target"]):
						var a: Vector2 = BOSS_AREAS[o["target"]]
						_diamond(Vector3(a.x, 0.0, a.y))


## The friend in danger (rescue event): a pulsing red "!" with a ring. On the corner minimap, when he is
## farther away than the picture reaches, the marker sits inside the border with an arrow that points
## the way and the distance in metres; on the big map a bobbing arrow and a label stand over him.
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


## Draws a quest glyph; on the corner minimap a marker that is off the edge sticks to the border.
func _clamped(pos: Vector2) -> Vector2:
	if big:
		return pos
	var c := size / 2.0
	var d := pos - c
	var lim := size.x / 2.0 - 11.0
	if absf(d.x) > lim or absf(d.y) > lim:
		d *= lim / maxf(absf(d.x), absf(d.y))
	return c + d


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
