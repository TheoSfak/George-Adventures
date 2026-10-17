class_name Catacombs
extends Node3D
## The catacombs below the old crypt (story part 2). A maze of halls and corridors
## carved from solid rock, built once on the first visit from the layout below and
## placed far outside the map like the house interiors (see interiors.gd). Edit ROOMS,
## CORRIDORS, SPAWNS, CHESTS and PAGES to change the level. Positions are in "cells"
## of 3 m: x grows to the east, y to the south (the entrance is at the bottom).

const CELL := 3.0
const HEIGHT := 6.0
const GRID := Vector2i(60, 50)
const ORIGIN := Vector3(6000.0, 0.0, 6000.0)      # world position of the middle of the grid

const G := "res://assets/graveyard/"
const I := "res://assets/items/"
const F := "res://assets/furniture/"
const C := "res://assets/characters/"

# name -> Rect2i(x, y, width, height) in cells
const ROOMS := {
	"entry": Rect2i(24, 40, 12, 8),         # the hall of candles: safe, Theodora lives here
	"cloister": Rect2i(20, 20, 20, 14),     # the great hall in the middle
	"west": Rect2i(2, 22, 8, 10),
	"east": Rect2i(50, 22, 8, 10),
	"warden_bone": Rect2i(1, 3, 12, 11),
	"warden_flame": Rect2i(47, 3, 12, 11),
	"warden_shadow": Rect2i(15, 11, 10, 8),
	"vault": Rect2i(35, 11, 10, 8),
	"alcove_w": Rect2i(13, 29, 6, 5),
	"alcove_e": Rect2i(41, 29, 6, 5),
	"abbot": Rect2i(20, 1, 20, 9),          # the abbot's chamber, behind the gate
}
const CORRIDORS: Array[Rect2i] = [
	Rect2i(29, 34, 2, 6),                   # entry <-> cloister
	Rect2i(10, 26, 10, 2),                  # cloister <-> west
	Rect2i(40, 26, 10, 2),                  # cloister <-> east
	Rect2i(5, 14, 2, 8),                    # west <-> bone warden
	Rect2i(53, 14, 2, 8),                   # east <-> flame warden
	Rect2i(29, 10, 2, 10),                  # cloister <-> abbot (the gate stands in row 10)
	Rect2i(25, 14, 4, 2),                   # north corridor <-> shadow warden
	Rect2i(31, 14, 4, 2),                   # north corridor <-> vault
	Rect2i(15, 28, 2, 1),                   # west corridor <-> south-west alcove
	Rect2i(43, 28, 2, 1),                   # east corridor <-> south-east alcove
]

const GATE_CELL := Vector2(30.0, 10.5)       # centre of the sealed gate (cell units)
const ENTRY_SPAWN := Vector2(30.0, 44.6)
const EXIT_DOOR := Vector2(30.0, 48.0)

# Light colour of a room (the default is warm candle light)
const ROOM_LIGHT := {
	"warden_bone": Color(0.70, 0.85, 1.0), "warden_flame": Color(1.0, 0.45, 0.15),
	"warden_shadow": Color(0.65, 0.35, 1.0), "abbot": Color(0.35, 1.0, 0.55),
	"entry": Color(1.0, 0.82, 0.55), "vault": Color(1.0, 0.85, 0.45),
}

# [kind, x, y]  (enemies.gd KINDS)
const SPAWNS := [
	# the great hall (placed in open aisles clear of columns and sarcophagi)
	["cguard", 25.2, 27.0], ["cguard", 34.8, 27.0], ["cguard", 30.0, 23.5],
	["minion", 28.5, 31.5], ["minion", 31.5, 31.5], ["minion", 30.0, 27.0],
	["acolyte", 22.0, 26.0], ["acolyte", 38.0, 27.0],
	# corridors
	["minion", 14.0, 26.8], ["minion", 45.0, 26.8], ["minion", 29.5, 37.0],
	["minion", 5.5, 17.0], ["minion", 53.5, 17.0], ["minion", 29.5, 16.0],
	# west wing (bones)
	["cguard", 5.0, 25.0], ["cguard", 7.5, 28.0], ["acolyte", 4.0, 30.0], ["minion", 7.0, 24.0],
	["warden_bone", 7.0, 8.0], ["cguard", 4.5, 7.5], ["cguard", 9.5, 8.5],
	# east wing (flame)
	["acolyte", 53.0, 25.0], ["acolyte", 55.5, 29.0], ["rogue", 52.0, 29.5], ["rogue", 56.0, 24.0], ["brute", 54.0, 27.0],
	["warden_flame", 53.0, 8.0], ["acolyte", 49.5, 5.0], ["acolyte", 56.5, 11.0],
	# shadow chamber (spaced clear of the 4 ring pillars)
	["warden_shadow", 20.0, 14.5], ["acolyte", 18.0, 14.5], ["acolyte", 22.0, 14.5], ["rogue", 20.0, 12.8], ["rogue", 20.0, 16.2],
	# the vault
	["cguard", 37.0, 14.0], ["cguard", 41.0, 15.0], ["cguard", 41.5, 13.5], ["brute", 39.5, 14.0],
	# alcoves
	["minion", 15.0, 31.0], ["minion", 17.0, 32.0], ["minion", 43.0, 31.0], ["cguard", 45.0, 32.0],
	# the abbot
	["necromancer", 30.0, 4.8],
]

# [x, y, rotation in degrees, golden, gold_min, gold_max, potions]
const CHESTS := [
	[34.6, 41.4, 270, false, 25, 55, 1],      # entry hall
	[21.8, 21.8, 90, false, 30, 70, 1],       # great hall
	[15.5, 31.0, 0, true, 60, 120, 2],        # south-west alcove
	[43.5, 31.0, 0, true, 60, 120, 2],        # south-east alcove
	[36.4, 12.4, 270, true, 90, 160, 2],      # vault
	[37.5, 2.6, 270, true, 120, 200, 3],      # abbot's chamber
]

# Pages of the Saint's prayer (quest "Οι Σελίδες της Ευχής"): x, y
const PAGES := [Vector2(4.2, 29.8), Vector2(55.8, 29.8), Vector2(40.5, 14.4)]

var exit_action := Callable()               # set by Interiors: leaves the catacombs

var _floor := {}                            # Vector2i -> true
var _root: Node3D
var _gate: Node3D
var _gate_open := false
var _torch_count := 0
var _bosses := {}                           # boss kind -> Enemy
var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _trim_mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("catacombs")


## World position of a cell coordinate (floats: 30.0 is the border between cell 29 and 30).
static func wp(x: float, y: float, h: float = 0.0) -> Vector3:
	return ORIGIN + Vector3((x - GRID.x / 2.0) * CELL, h, (y - GRID.y / 2.0) * CELL)


## Where George appears and which way he faces.
func spawn_point() -> Vector3:
	return wp(ENTRY_SPAWN.x, ENTRY_SPAWN.y, 0.05)


# --------------------------------------------------------------------- building ----

## Builds the whole level. Await it: the creatures appear after the physics server knows the walls.
func build() -> void:
	_rng.seed = 6602
	_root = Node3D.new()
	_root.name = "Level"
	add_child(_root)
	for name in ROOMS:
		_carve(ROOMS[name])
	for r in CORRIDORS:
		_carve(r)
	_make_materials()
	_build_shell()
	_build_lights()
	_build_decor()
	_build_door()
	_build_gate()
	_build_pickups()
	_build_nav()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_spawn_creatures()
	Quests.changed.connect(_on_quests_changed)
	_on_quests_changed()


## The walkable-ground grid the creatures use to get round pillars and corners (see nav_grid.gd).
func _build_nav() -> void:
	var size := Vector2(GRID) * CELL
	var grid := NavGrid.build([_root], Rect2(Vector2(ORIGIN.x, ORIGIN.z) - size * 0.5, size))
	grid.prepare(true)
	NavGrid.set_region("catacombs", grid)


func _carve(r: Rect2i) -> void:
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_floor[Vector2i(x, y)] = true


func _is_floor(x: int, y: int) -> bool:
	return _floor.has(Vector2i(x, y))


func _is_wall(x: int, y: int) -> bool:
	if _is_floor(x, y):
		return false
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if _is_floor(x + dx, y + dy):
				return true
	return false


func _make_materials() -> void:
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_texture = _flagstone_texture()
	_floor_mat.uv1_triplanar = true
	_floor_mat.uv1_world_triplanar = true
	_floor_mat.uv1_scale = Vector3.ONE * 0.25
	_floor_mat.roughness = 0.9
	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_texture = _brick_texture()
	_wall_mat.uv1_triplanar = true
	_wall_mat.uv1_world_triplanar = true
	_wall_mat.uv1_scale = Vector3.ONE * 0.25
	_wall_mat.roughness = 0.95
	_trim_mat = StandardMaterial3D.new()
	_trim_mat.albedo_color = Color(0.10, 0.09, 0.11)
	_trim_mat.roughness = 1.0


static func _flagstone_texture() -> ImageTexture:
	var n := 256
	var slab := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for sy in n / slab:
		for sx in n / slab:
			var tone := rng.randf_range(0.30, 0.42)
			for y in slab:
				for x in slab:
					var v := tone + rng.randf_range(-0.025, 0.025)
					if x < 2 or y < 2:
						v *= 0.5
					img.set_pixel(sx * slab + x, sy * slab + y, Color(v * 0.95, v, v * 1.12))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _brick_texture() -> ImageTexture:
	var n := 256
	var bh := 32
	var bw := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for row in n / bh:
		var shift := (bw / 2) if row % 2 == 1 else 0
		for col in n / bw + 1:
			var tone := rng.randf_range(0.26, 0.38)
			for y in bh:
				for x in bw:
					var px := (col * bw + x - shift + n) % n
					var py := row * bh + y
					var v := tone + rng.randf_range(-0.03, 0.03)
					if x < 2 or y < 2:
						v = 0.10
					img.set_pixel(px, py, Color(v * 0.92, v * 0.98, v * 1.1))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Floor, ceiling and the walls around every carved cell (solid, one box per row run).
func _build_shell() -> void:
	var full := Vector3(GRID.x * CELL, 0.0, GRID.y * CELL)
	_box(wp(GRID.x / 2.0, GRID.y / 2.0, -0.25), Vector3(full.x, 0.5, full.z), _floor_mat, true)
	var ceiling := StandardMaterial3D.new()
	ceiling.albedo_color = Color(0.09, 0.08, 0.10)
	ceiling.roughness = 1.0
	_box(wp(GRID.x / 2.0, GRID.y / 2.0, HEIGHT + 0.25), Vector3(full.x, 0.5, full.z), ceiling, true)
	for y in GRID.y:
		var x := 0
		while x < GRID.x:
			if _is_wall(x, y):
				var start := x
				while x < GRID.x and _is_wall(x, y):
					x += 1
				var run := x - start
				_box(wp(start + run / 2.0, y + 0.5, HEIGHT / 2.0), Vector3(run * CELL, HEIGHT, CELL), _wall_mat, true)
			else:
				x += 1
	# dark skirting along the foot of the walls would need extra boxes; the brick texture is enough


func _box(pos: Vector3, size: Vector3, mat: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_root.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		mi.add_child(body)
	return mi


# --------------------------------------------------------------------- lighting ----

func _build_lights() -> void:
	# one wide light per room (coloured in the boss rooms), small ones along the corridors
	for name in ROOMS:
		var r: Rect2i = ROOMS[name]
		var light := OmniLight3D.new()
		light.light_color = ROOM_LIGHT.get(name, Color(1.0, 0.72, 0.45))
		light.light_energy = 2.0 if name in ROOM_LIGHT else 1.5
		light.omni_range = maxf(r.size.x, r.size.y) * CELL * 0.55
		light.position = wp(r.position.x + r.size.x / 2.0, r.position.y + r.size.y / 2.0, HEIGHT - 1.4)
		_root.add_child(light)
		_torches(r, 7, true)
	for r in CORRIDORS:
		var horizontal := r.size.x > r.size.y
		var count := 1 if maxi(r.size.x, r.size.y) < 9 else 2
		for i in count:
			var t := (i + 0.5) / count
			var px := r.position.x + r.size.x * (t if horizontal else 0.5)
			var py := r.position.y + r.size.y * (0.5 if horizontal else t)
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.65, 0.35)
			light.light_energy = 1.1
			light.omni_range = 8.0
			light.position = wp(px, py, HEIGHT - 1.6)
			_root.add_child(light)
		_torches(r, 6, false)


## Mounted torches along the walls of a room (and a torch model + light for each).
func _torches(r: Rect2i, spacing: int, both_sides: bool) -> void:
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	for x in range(x0 + 2, x1 - 1, spacing):
		if not _is_floor(x, y0 - 1) and not _is_floor(x + 1, y0 - 1):
			_torch(wp(x + 1.0, y0, 2.5) + Vector3(0, 0, 0.3), 0.0)
		if both_sides and not _is_floor(x, y1) and not _is_floor(x + 1, y1):
			_torch(wp(x + 1.0, y1, 2.5) + Vector3(0, 0, -0.3), 180.0)
	for y in range(y0 + 2, y1 - 1, spacing):
		if not _is_floor(x0 - 1, y) and not _is_floor(x0 - 1, y + 1):
			_torch(wp(x0, y + 1.0, 2.5) + Vector3(0.3, 0, 0), 90.0)
		if both_sides and not _is_floor(x1, y) and not _is_floor(x1, y + 1):
			_torch(wp(x1, y + 1.0, 2.5) + Vector3(-0.3, 0, 0), 270.0)


func _torch(pos: Vector3, yaw_deg: float) -> void:
	var model := (load(I + "torch_mounted.gltf.glb") as PackedScene).instantiate() as Node3D
	model.position = pos
	model.rotation_degrees.y = yaw_deg
	model.scale = Vector3.ONE * 1.9
	_root.add_child(model)
	_torch_count += 1
	if _torch_count % 3 != 0:        # a light for every third torch keeps the frame rate up
		return
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.60, 0.28)
	light.light_energy = 1.6
	light.omni_range = 7.0
	var forward := Vector3(sin(deg_to_rad(yaw_deg)), 0.0, cos(deg_to_rad(yaw_deg)))
	light.position = pos + forward * 0.6 + Vector3.UP * 0.3
	_root.add_child(light)


# ------------------------------------------------------------------------ decor ----

func _prop(path: String, x: float, y: float, yaw_deg: float, scale_: float, lift: float = 0.0, solid: bool = false) -> Node3D:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	model.position = wp(x, y, lift)
	model.rotation_degrees.y = yaw_deg
	model.scale = Vector3.ONE * scale_
	_root.add_child(model)
	if solid:
		Interiors.collider_for(model)
	return model


func _scatter(room: String, count: int, models: Array, scale_min: float, scale_max: float, solid: bool = false, margin: float = 1.2) -> void:
	var r: Rect2i = ROOMS[room]
	for i in count:
		var x := _rng.randf_range(r.position.x + margin, r.end.x - margin)
		var y := _rng.randf_range(r.position.y + margin, r.end.y - margin)
		var model: String = models[_rng.randi() % models.size()]
		var scale_ := _rng.randf_range(scale_min, scale_max) * (0.55 if model.contains("skull") else 1.0)   # skulls are big models
		_prop(model, x, y, _rng.randf() * 360.0, scale_, 0.0, solid)


func _column(x: float, y: float) -> void:
	_prop(I + "column.gltf.glb", x, y, 0.0, 2.2, 0.0, true)


func _build_decor() -> void:
	var bones := [G + "bone_A.gltf", G + "bone_B.gltf", G + "bone_C.gltf", G + "skull.gltf", G + "ribcage.gltf", G + "skull_candle.gltf"]
	var e: Rect2i = ROOMS["entry"]
	# --- entry hall: a shrine with candles, benches, banners
	_prop(G + "shrine_candles.gltf", 30.0, 41.2, 0.0, 2.2, 0.0, true)
	_prop(G + "candle_triple.gltf", 27.8, 41.4, 0.0, 2.0)
	_prop(G + "candle_triple.gltf", 32.2, 41.4, 0.0, 2.0)
	_prop(I + "banner_blue.gltf.glb", 26.5, 40.3, 0.0, 1.4, 1.0)
	_prop(I + "banner_red.gltf.glb", 33.5, 40.3, 0.0, 1.4, 1.0)
	_prop(G + "bench.gltf", 26.5, 44.0, 90.0, 1.4, 0.0, true)
	_prop(G + "bench.gltf", 33.5, 44.0, 270.0, 1.4, 0.0, true)
	_prop(F + "rug_rectangle_stripes_B.gltf", 30.0, 43.0, 0.0, 2.2)
	for x in [25.2, 34.8]:
		_prop(G + "candle_triple.gltf", x, 46.4, 0.0, 2.0)
	# --- great hall: rows of pillars, old coffins, bones
	for p in [Vector2(23.5, 23.0), Vector2(36.5, 23.0), Vector2(23.5, 31.0), Vector2(36.5, 31.0),
			Vector2(27.0, 25.0), Vector2(33.0, 25.0), Vector2(27.0, 29.0), Vector2(33.0, 29.0)]:
		_column(p.x, p.y)
	for p in [Vector2(21.8, 28.6), Vector2(38.2, 24.4), Vector2(21.6, 32.0)]:
		_prop(G + ("coffin_decorated.gltf" if p.x < 30 else "coffin.gltf"), p.x, p.y, 90.0 if p.x < 30 else 270.0, 1.6, 0.0, true)
	_prop(I + "banner_red.gltf.glb", 23.0, 20.3, 0.0, 1.5, 1.0)
	_prop(I + "banner_red.gltf.glb", 37.0, 20.3, 0.0, 1.5, 1.0)
	_prop(I + "banner_blue.gltf.glb", 30.0, 20.3, 0.0, 1.5, 1.0)
	_scatter("cloister", 18, bones, 0.9, 1.4)
	# --- side wings
	_scatter("west", 10, bones, 0.9, 1.4)
	_scatter("east", 10, bones, 0.9, 1.4)
	_prop(G + "coffin.gltf", 2.9, 26.0, 90.0, 1.6, 0.0, true)
	_prop(G + "coffin_decorated.gltf", 3.0, 29.0, 90.0, 1.6, 0.0, true)
	_prop(G + "coffin.gltf", 57.1, 26.0, 270.0, 1.6, 0.0, true)
	_prop(G + "coffin_decorated.gltf", 57.0, 29.0, 270.0, 1.6, 0.0, true)
	_prop(G + "candle_triple.gltf", 4.2, 30.6, 0.0, 2.0)
	_prop(G + "candle_triple.gltf", 55.8, 30.6, 0.0, 2.0)
	# --- the three seal chambers: a glowing seal on the floor and a ring of pillars
	_seal("warden_bone", Vector2(7.0, 8.0), Color(0.65, 0.85, 1.0))
	_seal("warden_flame", Vector2(53.0, 8.0), Color(1.0, 0.45, 0.12))
	_seal("warden_shadow", Vector2(20.0, 14.5), Color(0.6, 0.3, 1.0))
	for c in [Vector2(7.0, 8.0), Vector2(53.0, 8.0), Vector2(20.0, 14.5)]:
		for off in [Vector2(-4.5, -4.5), Vector2(4.5, -4.5), Vector2(-4.5, 4.5), Vector2(4.5, 4.5)]:
			var p: Vector2 = c + off
			if c.x == 20.0:
				p = c + off * Vector2(0.9, 0.7)
			_column(p.x, p.y)
	_scatter("warden_bone", 14, bones, 0.9, 1.4)
	_scatter("warden_flame", 14, bones, 0.9, 1.4)
	_scatter("warden_shadow", 10, bones, 0.9, 1.4)
	# --- the vault: sarcophagi and treasure
	for p in [Vector2(36.0, 17.2), Vector2(43.8, 17.2), Vector2(43.8, 12.0)]:
		_prop(G + "coffin_decorated.gltf", p.x, p.y, 0.0 if p.y > 15 else 270.0, 1.7, 0.0, true)
	_prop(I + "crates_stacked.gltf.glb", 36.2, 11.8, 90.0, 0.9, 0.0, true)
	_prop(I + "barrel_large.gltf.glb", 38.0, 11.7, 0.0, 0.6, 0.0, true)
	_prop(I + "coin_stack_medium.gltf.glb", 39.5, 17.4, 0.0, 1.8)
	_prop(I + "coin_stack_small.gltf.glb", 40.5, 17.5, 40.0, 1.8)
	_prop(G + "candle_triple.gltf", 41.6, 16.0, 0.0, 2.0)
	_scatter("vault", 8, bones, 0.9, 1.4)
	# --- alcoves
	for room in ["alcove_w", "alcove_e"]:
		_scatter(room, 6, bones, 0.9, 1.4)
	_prop(G + "candle_triple.gltf", 14.2, 30.0, 0.0, 2.0)
	_prop(G + "candle_triple.gltf", 45.8, 30.0, 0.0, 2.0)
	# --- the abbot's chamber: an altar of bones, banners, a ring of pillars
	_prop(G + "shrine.gltf", 30.0, 2.4, 0.0, 2.6, 0.0, true)
	_prop(G + "candle_triple.gltf", 27.0, 2.6, 0.0, 2.2)
	_prop(G + "candle_triple.gltf", 33.0, 2.6, 0.0, 2.2)
	_prop(I + "banner_red.gltf.glb", 24.5, 1.3, 0.0, 1.6, 1.0)
	_prop(I + "banner_red.gltf.glb", 35.5, 1.3, 0.0, 1.6, 1.0)
	for p in [Vector2(23.5, 3.5), Vector2(36.5, 3.5), Vector2(23.5, 8.0), Vector2(36.5, 8.0), Vector2(26.5, 6.0), Vector2(33.5, 6.0)]:
		_column(p.x, p.y)
	_scatter("abbot", 14, bones, 0.9, 1.5)
	_seal("abbot", Vector2(30.0, 5.5), Color(0.35, 1.0, 0.55))


## A glowing disc on the floor in the colour of a seal.
func _seal(room: String, c: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 4.2 if room != "abbot" else 5.5
	disc.bottom_radius = disc.top_radius
	disc.height = 0.04
	mi.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.55)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = wp(c.x, c.y, 0.03)
	_root.add_child(mi)


# --------------------------------------------------------- door, gate, pickups ----

func _build_door() -> void:
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.30, 0.18, 0.09)
	door_mat.roughness = 0.8
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.40, 0.27, 0.16)
	_box(wp(EXIT_DOOR.x, EXIT_DOOR.y, 1.7) + Vector3(0, 0, -0.15), Vector3(2.6, 3.4, 0.3), door_mat, false)
	_box(wp(EXIT_DOOR.x, EXIT_DOOR.y, 3.55) + Vector3(0, 0, -0.15), Vector3(3.2, 0.3, 0.4), trim, false)
	_box(wp(EXIT_DOOR.x, EXIT_DOOR.y, 1.75) + Vector3(-1.45, 0, -0.15), Vector3(0.3, 3.5, 0.4), trim, false)
	_box(wp(EXIT_DOOR.x, EXIT_DOOR.y, 1.75) + Vector3(1.45, 0, -0.15), Vector3(0.3, 3.5, 0.4), trim, false)
	var spot := InteractSpot.make(Strings.PROMPT_EXIT, func(p): exit_action.call(p), 2.6)
	spot.position = wp(EXIT_DOOR.x, EXIT_DOOR.y - 0.6)
	_root.add_child(spot)


## The sealed gate in front of the abbot's chamber: it dissolves when the three wardens have fallen.
func _build_gate() -> void:
	_gate = Node3D.new()
	_root.add_child(_gate)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2 * CELL, HEIGHT, 0.6)
	shape.shape = box
	body.add_child(shape)
	body.set_meta("nav_ignore", true)       # the gate dissolves later: the navigation grid must not remember it
	body.position = wp(GATE_CELL.x, GATE_CELL.y, HEIGHT / 2.0)
	_gate.add_child(body)
	var wall := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2 * CELL, HEIGHT, 0.4)
	wall.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.45, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.45)
	mat.emission_energy_multiplier = 1.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall.material_override = mat
	wall.position = body.position
	_gate.add_child(wall)
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 1.0, 0.5)
	light.light_energy = 2.0
	light.omni_range = 12.0
	light.position = wp(GATE_CELL.x, GATE_CELL.y + 1.0, 3.0)
	_gate.add_child(light)
	var label := Label3D.new()
	label.text = Strings.PROMPT_GATE_SEALED
	label.font_size = 52
	label.pixel_size = 0.0085
	label.outline_size = 16
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.6, 1.0, 0.7)
	label.no_depth_test = true
	label.position = wp(GATE_CELL.x, GATE_CELL.y + 1.2, 4.2)
	_gate.add_child(label)
	var spot := InteractSpot.make(Strings.PROMPT_GATE_SEALED, func(p: Player): p.message.emit(Strings.MSG_GATE_SEALED), 4.5)
	spot.position = wp(GATE_CELL.x, GATE_CELL.y + 1.6)
	_gate.add_child(spot)


func _on_quests_changed() -> void:
	if not _gate_open and Quests.state["wardens"] >= Quests.S.READY:
		_open_gate()
	_check_bosses()


func _open_gate() -> void:
	_gate_open = true
	if is_instance_valid(_gate):
		var player := get_tree().get_first_node_in_group("player") as Player
		if player:
			player.message.emit(Strings.MSG_GATE_OPEN)
		Sfx.ui("quest_ready")
		var g := _gate
		_gate = null
		for child in g.get_children():
			if child is StaticBody3D or child is InteractSpot:
				child.queue_free()
		var tween := create_tween()
		tween.tween_interval(0.6)
		tween.tween_callback(g.queue_free)


func _build_pickups() -> void:
	for c in CHESTS:
		var chest := Chest.new()
		chest.golden = c[3]
		chest.gold_min = c[4]
		chest.gold_max = c[5]
		chest.potions = c[6]
		chest.position = wp(c[0], c[1])
		chest.rotation_degrees.y = c[2]
		_root.add_child(chest)
		if SaveGame.opened_chests.has(SaveGame.key_for(chest.position)):
			chest.mark_opened()
	for p in PAGES:
		var pos := wp(p.x, p.y)
		if SaveGame.collected_items.has("page@" + SaveGame.key_for(pos)):
			continue
		var item := QuestItem.new()
		item.item_id = "page"
		item.position = pos
		_root.add_child(item)
	# Theodora waits in the hall of candles
	var theodora := Npc.new()
	theodora.npc_id = "theodora"
	theodora.rest_yaw = 0.0
	theodora.position = wp(30.0, 42.6, 0.05)
	_root.add_child(theodora)


# ---------------------------------------------------------------------- enemies ----

func _spawn_creatures() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		push_warning("catacombs.gd: no enemy spawner")
		return
	for s in SPAWNS:
		var enemy: Enemy = spawner.spawn_extra(s[0], wp(s[1], s[2], 0.05))
		if enemy and s[0] in _boss_kinds():
			_bosses[s[0]] = enemy


func _boss_kinds() -> Array:
	return ["warden_bone", "warden_flame", "warden_shadow", "necromancer"]


## A boss that was killed before his quest began comes back when the quest is taken.
func _check_bosses() -> void:
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null:
		return
	for s in SPAWNS:
		var kind: String = s[0]
		if not kind in _boss_kinds():
			continue
		var quest: String = spawner.KINDS[kind]["quest"]
		if Quests.state[quest] != Quests.S.ACTIVE:
			continue
		var alive: bool = _bosses.has(kind) and is_instance_valid(_bosses[kind]) and not _bosses[kind].is_dead()
		var wanted := false
		for i in QuestData.QUESTS[quest]["objectives"].size():
			var o: Dictionary = QuestData.QUESTS[quest]["objectives"][i]
			if o["type"] == "kill" and o["target"] == kind and Quests.progress[quest][i] < o["count"]:
				wanted = true
		if wanted and not alive:
			var enemy: Enemy = spawner.spawn_extra(kind, wp(s[1], s[2], 0.05))
			if enemy:
				_bosses[kind] = enemy
