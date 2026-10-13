extends Node3D
## Builds the whole Agios Vlasis world: ground, mountain border, the village with its
## enterable houses and NPCs, the three story areas (west camp, quarry, old crypt),
## chests, quest items, signposts and the scattered forests.
##
## Everything is data-driven: edit the lists below to move things around. Positions are
## in metres, (0, 0) is the village well, -Z is north. The map reaches about 200 m
## from the well in every direction.

const ST := 12.0                      # ground tile scale (hex tile = 24 m wide)
const BS := 12.0                      # building scale (a house is ~10 m wide)
const TS := 9.5                       # tree scale
const PS := 7.0                       # prop scale (barrels, crates, tents...)
const HEX_W := 2.0 * ST
const ROW_H := 1.7320508 * ST
const WORLD := "res://assets/world/"
const GRAVE := "res://assets/graveyard/"
const ITEMS := "res://assets/items/"

@export var radius := 12              # map size in hex tiles from the centre
@export var seed_value := 4412

# [model, x, z, interior kind ("" = cannot enter), scale multiplier, npc id ("" = none)]
# Buildings turn to face the well, doors are on the side facing the well.
const BUILDINGS := [
	["buildings/blue/building_church_blue.gltf", 0.0, -59.0, "church", 1.0, "stavros"],
	["buildings/blue/building_tavern_blue.gltf", -59.0, -9.8, "tavern", 1.0, "maria"],
	["buildings/red/building_market_red.gltf", 59.0, -11.5, "market", 1.0, ""],
	["buildings/blue/building_home_A_blue.gltf", -47.6, 36.1, "home", 1.0, ""],
	["buildings/yellow/building_home_B_yellow.gltf", -16.4, 52.5, "home", 1.0, ""],
	["buildings/red/building_home_A_red.gltf", 16.4, 52.5, "home", 1.0, ""],
	["buildings/green/building_home_B_green.gltf", 47.6, 36.1, "home", 1.0, ""],
	["buildings/yellow/building_home_A_yellow.gltf", -41.0, -47.6, "home", 1.0, ""],
	["buildings/green/building_home_B_green.gltf", 41.0, -47.6, "home", 1.0, ""],
	["buildings/blue/building_blacksmith_blue.gltf", -93.5, 29.5, "blacksmith", 1.0, "nikitas"],
	["buildings/red/building_lumbermill_red.gltf", 95.1, 39.4, "", 1.0, "giannis"],
	["buildings/yellow/building_windmill_yellow.gltf", -100.0, -54.1, "", 1.0, "stelios"],
	["buildings/blue/building_tower_A_blue.gltf", 95.1, -78.7, "", 1.0, "vasilis"],
	["buildings/blue/building_well_blue.gltf", 0.0, 0.0, "", 0.6, ""],
]

# Props next to a building, in the building's own frame:
# building index -> [[model, right, forward, rotation, scale multiplier], ...]
# "forward" points toward the well, "right" is to the right when facing out of the door.
const BUILDING_PROPS := {
	0: [["decoration/props/flag_blue.gltf", -8.0, 9.0, 0, 1.2], ["decoration/props/flag_blue.gltf", 8.0, 9.0, 0, 1.2]],
	1: [["decoration/props/barrel.gltf", -9.5, 9.0, 0, 1.0], ["decoration/props/barrel.gltf", -8.2, 9.6, 40, 1.0],
		["decoration/props/crate_A_big.gltf", 10.0, 8.5, 15, 1.0], ["decoration/props/sack.gltf", 9.0, 10.0, 70, 1.0],
		["decoration/props/bucket_water.gltf", -7.0, 10.5, 20, 1.0]],
	2: [["decoration/props/crate_A_big.gltf", -14.0, 9.5, 10, 1.0], ["decoration/props/crate_B_big.gltf", -12.5, 10.5, 80, 1.0],
		["decoration/props/sack.gltf", 13.0, 9.5, 0, 1.0], ["decoration/props/wheelbarrow.gltf", 14.5, 8.5, 110, 1.0]],
	3: [["decoration/props/bucket_empty.gltf", 6.5, 8.0, 0, 1.0], ["decoration/props/crate_A_small.gltf", -6.5, 8.5, 30, 1.0]],
	4: [["decoration/props/barrel.gltf", 6.5, 8.0, 0, 1.0], ["decoration/props/sack.gltf", -6.5, 8.5, 50, 1.0]],
	5: [["decoration/props/crate_A_small.gltf", 6.5, 8.0, 20, 1.0], ["decoration/props/bucket_water.gltf", -6.5, 8.5, 0, 1.0]],
	6: [["decoration/props/barrel.gltf", -6.5, 8.0, 0, 1.0], ["decoration/props/crate_B_small.gltf", 6.5, 8.5, 70, 1.0]],
	7: [["decoration/props/sack.gltf", 6.5, 8.0, 30, 1.0], ["decoration/props/barrel.gltf", -6.5, 8.5, 0, 1.0]],
	8: [["decoration/props/crate_A_small.gltf", -6.5, 8.0, 10, 1.0], ["decoration/props/bucket_empty.gltf", 6.5, 8.5, 0, 1.0]],
	9: [["decoration/props/weaponrack.gltf", -11.0, 9.0, 0, 1.6], ["decoration/props/target.gltf", 13.0, 9.5, 20, 1.6],
		["decoration/props/resource_stone.gltf", 11.0, 11.0, 30, 1.0], ["decoration/props/barrel.gltf", -9.0, 11.0, 0, 1.0]],
	10: [["decoration/props/resource_lumber.gltf", -12.0, 10.0, 20, 1.0], ["decoration/props/resource_lumber.gltf", 12.0, 12.0, 100, 1.0],
		["decoration/props/pallet.gltf", 0.0, 14.0, 0, 1.0], ["decoration/props/crate_long_A.gltf", 15.0, 9.0, 30, 1.0]],
}

# [quest item id, x, z]   (see quest_data.gd; they only appear while their quest is active)
const QUEST_ITEMS := [
	["keg", -30.0, -142.0], ["keg", 143.0, -29.0], ["keg", 26.0, 152.0], ["keg", -122.0, 111.0],
	["key", -176.0, 24.0],
	# flour sacks scattered around the windmill, logs around the lumber mill
	["sack", -113.0, -41.0], ["sack", -87.0, -67.0], ["sack", -121.0, -63.0], ["sack", -96.0, -33.0], ["sack", -109.0, -81.0],
	["log", 109.0, 24.0], ["log", 82.0, 57.0], ["log", 121.0, 49.0], ["log", 98.0, 67.0], ["log", 77.0, 27.0], ["log", 113.0, 38.0],
]

# Bone totems (quest "Τα Οστέινα Τοτέμ"): x, z. They only stand while the quest is active.
const TOTEMS := [Vector2(-175.0, 27.0), Vector2(147.0, 135.0), Vector2(17.0, -142.0)]

# [x, z, rotation, golden, gold_min, gold_max, potions]   (more chests are inside the houses)
const CHESTS := [
	[-186.0, 14.0, 80, false, 15, 35, 1],      # west camp
	[152.0, 116.0, 200, true, 30, 60, 2],      # quarry
	[-26.0, -197.0, 20, true, 50, 90, 2],      # crypt
	[-133.0, -76.0, 40, false, 10, 25, 0],     # behind the windmill
	[134.0, -78.0, 150, false, 12, 28, 1],     # beside the watchtower
	[92.0, 120.0, 250, false, 8, 20, 0],       # south-east farm track
	[-100.0, 130.0, 0, false, 10, 24, 1],      # south-west pines
]

# [text, x, z, rotation in degrees (the board faces +Z when 0)]
const SIGNPOSTS := [
	["Δυτικό Στρατόπεδο  ←", -138.0, 4.0, 90],
	["Λατομείο  ↘", 104.0, 84.0, 20],
	["Παλιά Κρύπτη  ↑\nΚίνδυνος!", 14.0, -118.0, 0],
]

const CAMP := Vector2(-175.0, 20.0)
const QUARRY := Vector2(140.0, 125.0)
const CRYPT := Vector2(0.0, -178.0)

const TREES := ["decoration/nature/tree_single_A.gltf", "decoration/nature/tree_single_B.gltf"]
const FORESTS := [
	"decoration/nature/trees_A_large.gltf", "decoration/nature/trees_B_large.gltf",
	"decoration/nature/trees_A_medium.gltf", "decoration/nature/trees_B_medium.gltf",
]
const ROCKS := [
	"decoration/nature/rock_single_A.gltf", "decoration/nature/rock_single_B.gltf",
	"decoration/nature/rock_single_C.gltf", "decoration/nature/rock_single_D.gltf",
	"decoration/nature/rock_single_E.gltf",
]
const BORDER := [
	"decoration/nature/mountain_A_grass_trees.gltf", "decoration/nature/mountain_B_grass_trees.gltf",
	"decoration/nature/mountain_C_grass_trees.gltf", "decoration/nature/hills_A_trees.gltf",
	"decoration/nature/hills_B_trees.gltf", "decoration/nature/hills_C_trees.gltf",
]
const GRAVE_STONES := ["gravestone.gltf", "gravemarker_A.gltf", "gravemarker_B.gltf", "grave_A.gltf", "grave_B.gltf", "grave_A_destroyed.gltf"]

var _cache := {}
var _rng := RandomNumberGenerator.new()
const OCC_CELL := 16.0
var _occ_big: Array[Vector3] = []    # x, z, radius of large things (zones, the square)
var _occ_grid := {}                  # Vector2i cell -> small things (x, z, radius)
var _clouds: Array[Node3D] = []
var _terrain: Terrain
var _door_fronts: Array[Vector2] = []
var _home_frames: Array = []         # [position, heading in degrees, forward, right, half width] of the houses


func _ready() -> void:
	_rng.seed = seed_value
	_build_ground()
	_build_border()
	_build_village()
	_build_villagers()
	add_child(VillageSquare.new())
	_build_camp()
	_build_quarry()
	_build_crypt()
	_build_chests_items_signs()
	_build_totems()
	_build_terrain_details()
	_build_scatter()
	_finish_terrain()
	_build_clouds()
	_build_night_lights()


func _process(delta: float) -> void:
	for c in _clouds:
		c.position.x += delta * 1.6
		if c.position.x > 340.0:
			c.position.x = -340.0


# ---------------------------------------------------------------- ground ----

func _hex_to_world(q: int, r: int) -> Vector3:
	return Vector3(HEX_W * (float(q) + float(r) * 0.5), 0.0, ROW_H * float(r))


func _hex_dist(q: int, r: int) -> int:
	return maxi(maxi(absi(q), absi(r)), absi(q + r))


func _all_hexes() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			out.append(Vector2i(q, r))
	return out


func _build_ground() -> void:
	_terrain = Terrain.new()
	_terrain.name = "Terrain"
	add_child(_terrain)
	_terrain.setup(seed_value)
	_terrain.build_ground(Vector2(HEX_W * (radius + 1.0), ROW_H * (radius + 1.0)))

	# One big invisible floor so George never falls anywhere.
	var body := StaticBody3D.new()
	body.name = "GroundCollider"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(HEX_W * (radius * 2 + 2), 2.0, ROW_H * (radius * 2 + 2))
	shape.shape = box
	shape.position = Vector3(0.0, -1.0, 0.0)
	body.add_child(shape)
	add_child(body)

	# Ground patches: cobbled village square and the three story areas.
	_terrain.add_patch(Vector2.ZERO, 21.0, Color(0.66, 0.62, 0.54), true, Color(0.30, 0.27, 0.22))
	_terrain.add_patch(CAMP, 34.0, Color(0.58, 0.47, 0.30))
	_terrain.add_patch(QUARRY, 38.0, Color(0.60, 0.60, 0.57), false, Color(0.38, 0.38, 0.36))
	_terrain.add_patch(CRYPT + Vector2(0, -2), 46.0, Color(0.38, 0.43, 0.38), false, Color(0.25, 0.29, 0.25))


func _build_border() -> void:
	# Outer ring = mountains and hills that act as the edge of the world.
	# Next ring in = dense forest.
	var holder := Node3D.new()
	holder.name = "Border"
	add_child(holder)
	for h in _all_hexes():
		var d := _hex_dist(h.x, h.y)
		var pos := _hex_to_world(h.x, h.y)
		if d == radius:
			var model: String = BORDER[_rng.randi() % BORDER.size()]
			var node := _place(model, pos, _rng.randi_range(0, 5) * 60.0, ST * 1.45, holder)
			_add_cylinder_collider(node, ST * 1.4, 40.0, Vector3.ZERO)
		elif d == radius - 1:
			var model: String = FORESTS[_rng.randi() % FORESTS.size()]
			var node := _place(model, pos, _rng.randi_range(0, 5) * 60.0, ST, holder)
			_add_cylinder_collider(node, ST * 0.85, 20.0, Vector3.ZERO)


# --------------------------------------------------------------- village ----

func _build_village() -> void:
	var holder := Node3D.new()
	holder.name = "Buildings"
	add_child(holder)
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	var npcs := Node3D.new()
	npcs.name = "Npcs"
	add_child(npcs)
	var doors := Node3D.new()
	doors.name = "Doors"
	add_child(doors)

	for i in BUILDINGS.size():
		var b: Array = BUILDINGS[i]
		var pos := Vector3(b[1], 0.0, b[2])
		var rot := rad_to_deg(atan2(-pos.x, -pos.z))  # face the well
		var node := _place(b[0], pos, rot, BS * b[4], holder)
		_add_box_collider(node)
		var aabb := _local_aabb(node)
		_occupy(pos.x, pos.z, Vector2(aabb.size.x, aabb.size.z).length() / 2.0 + 4.0)
		var heading := deg_to_rad(rot)
		var forward := Vector3(sin(heading), 0.0, cos(heading))
		var right := Vector3(-cos(heading), 0.0, sin(heading))
		var door_front := pos + forward * (aabb.position.z + aabb.size.z + 2.4)
		if b[0].find("well") < 0:
			_door_fronts.append(Vector2(door_front.x, door_front.z))
		if b[3] == "home":
			_home_frames.append([pos, rot, forward, right, aabb.size.x / 2.0])

		if BUILDING_PROPS.has(i):
			for p in BUILDING_PROPS[i]:
				var ppos: Vector3 = pos + right * p[1] + forward * p[2]
				var pnode := _place(p[0], ppos, rot + float(p[3]), PS * p[4], props)
				_add_box_collider(pnode, 0.8)
				_occupy(ppos.x, ppos.z, 2.0)
		if b[3] != "":
			doors.add_child(_make_door(i, b[3], door_front, heading))
		if b[5] != "":
			var npc := Npc.new()
			npc.npc_id = b[5]
			npc.rest_yaw = heading
			npc.position = door_front + right * 5.5 + forward * 0.5
			npcs.add_child(npc)
	_occupy(0, 0, 22)
# ---------------------------------------------------------------- villagers ----

var _villager_count := 0


## Ordinary villagers: some stroll around the square, some stand in pairs and chat.
func _build_villagers() -> void:
	var holder := Node3D.new()
	holder.name = "Villagers"
	add_child(holder)
	var vrng := RandomNumberGenerator.new()
	vrng.seed = seed_value + 7
	# strollers
	for i in 6:
		var a := vrng.randf() * TAU
		var r := vrng.randf_range(11.0, 24.0)
		_make_villager(Vector3(cos(a) * r, 0.05, sin(a) * r), Villager.Mode.WANDER, 0.0, holder)
	# pairs that chat in speech bubbles
	for pair in [[Vector2(-14.0, -17.0), 0.6], [Vector2(17.0, -13.0), 2.2], [Vector2(11.0, 21.0), 1.0],
			[Vector2(-19.0, 13.0), 0.3], [Vector2(-3.0, 27.0), 1.7]]:
		var c: Vector2 = pair[0]
		var d := Vector2(cos(pair[1]), sin(pair[1]))
		var pa := Vector3(c.x + d.x * 0.85, 0.05, c.y + d.y * 0.85)
		var pb := Vector3(c.x - d.x * 0.85, 0.05, c.y - d.y * 0.85)
		var a := _make_villager(pa, Villager.Mode.CHAT, atan2(-d.x, -d.y), holder)
		var b := _make_villager(pb, Villager.Mode.CHAT, atan2(d.x, d.y), holder)
		a.partner = b
		b.partner = a
		a.lead = true


func _make_villager(pos: Vector3, mode: int, yaw: float, parent: Node) -> Villager:
	var v := Villager.new()
	v.mode = mode
	v.rest_yaw = yaw
	v.model_path = VillagerData.MODELS[(_villager_count * 3 + 1) % VillagerData.MODELS.size()]
	v.display_name = VillagerData.NAMES[(_villager_count * 7 + 2) % VillagerData.NAMES.size()]
	for i in 3:
		v.talk_lines.append(VillagerData.GOSSIP[(_villager_count * 5 + i * 4) % VillagerData.GOSSIP.size()])
	_villager_count += 1
	v.position = pos
	parent.add_child(v)
	return v


func _make_door(index: int, kind: String, door_front: Vector3, heading: float) -> InteractSpot:
	var door_id := "%s_%d" % [kind, index]
	var label: String = Strings.PROMPT_ENTER % Strings.BUILDING_NAMES[kind]
	var spot := InteractSpot.make(label, func(player: Player):
		var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
		if interiors:
			interiors.enter(door_id, kind, door_front, heading, player), 4.6)
	spot.position = door_front
	return spot


# ------------------------------------------------------------- story areas ----

func _build_camp() -> void:
	# The skeletons' camp in the west: tents around a fire of torches.
	var holder := Node3D.new()
	holder.name = "Camp"
	add_child(holder)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3
		var p := CAMP + Vector2(cos(a), sin(a)) * 19.0
		var node := _place("decoration/props/tent.gltf", Vector3(p.x, 0, p.y), rad_to_deg(-a) - 90.0, PS * 2.0, holder)
		_add_box_collider(node, 0.8)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.8
		var p := CAMP + Vector2(cos(a), sin(a)) * 4.0
		_place_abs(ITEMS + "torch_lit.gltf.glb", Vector3(p.x, 0, p.y), 0.0, 2.4, holder)
	var light := OmniLight3D.new()
	light.position = Vector3(CAMP.x, 3.0, CAMP.y)
	light.light_color = Color(1.0, 0.65, 0.3)
	light.light_energy = 2.0
	light.omni_range = 22.0
	light.add_to_group("night_lights")
	holder.add_child(light)
	var extras := [
		["decoration/props/weaponrack.gltf", -9.0, -6.0, 40, 1.6], ["decoration/props/crate_A_big.gltf", 8.0, -9.0, 20, 1.2],
		["decoration/props/crate_B_big.gltf", 10.0, -7.5, 70, 1.2], ["decoration/props/barrel.gltf", -7.0, 9.0, 0, 1.2],
		["decoration/props/barrel.gltf", -5.5, 9.5, 40, 1.2], ["decoration/props/flag_red.gltf", 0.0, -13.0, 0, 1.3],
		["decoration/props/target.gltf", 12.0, 8.0, 200, 1.6],
	]
	for e in extras:
		var node := _place(e[0], Vector3(CAMP.x + e[1], 0, CAMP.y + e[2]), float(e[3]), PS * e[4], holder)
		_add_box_collider(node, 0.8)
	_occupy(CAMP.x, CAMP.y, 36)
func _build_quarry() -> void:
	# The quarry in the south-east, home of the skeleton captain.
	var holder := Node3D.new()
	holder.name = "Quarry"
	add_child(holder)
	for i in 10:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(10.0, 34.0)
		var p := QUARRY + Vector2(cos(a), sin(a)) * d
		var node := _place("decoration/props/resource_stone.gltf", Vector3(p.x, 0, p.y), _rng.randf() * 360.0, PS * _rng.randf_range(2.2, 3.4), holder)
		_add_box_collider(node, 0.8)
	for i in 14:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(24.0, 40.0)
		var p := QUARRY + Vector2(cos(a), sin(a)) * d
		var node := _place(ROCKS[_rng.randi() % ROCKS.size()], Vector3(p.x, 0, p.y), _rng.randf() * 360.0, PS * _rng.randf_range(3.0, 5.0), holder)
		_add_box_collider(node, 0.8)
	for e in [["decoration/props/crate_A_big.gltf", -8.0, -4.0, 30, 1.4], ["decoration/props/crate_B_big.gltf", -6.0, -6.0, 80, 1.4],
			["decoration/props/barrel.gltf", 7.0, -8.0, 0, 1.4], ["decoration/props/wheelbarrow.gltf", 9.0, -5.0, 150, 1.4],
			["decoration/props/resource_lumber.gltf", -12.0, 8.0, 60, 1.2]]:
		var node := _place(e[0], Vector3(QUARRY.x + e[1], 0, QUARRY.y + e[2]), float(e[3]), PS * e[4], holder)
		_add_box_collider(node, 0.8)
	_place_abs(ITEMS + "banner_red.gltf.glb", Vector3(QUARRY.x - 5.0, 0, QUARRY.y + 6.0), 0.0, 2.6, holder)
	_place_abs(ITEMS + "banner_red.gltf.glb", Vector3(QUARRY.x + 5.0, 0, QUARRY.y + 6.0), 0.0, 2.6, holder)
	_occupy(QUARRY.x, QUARRY.y, 42)
func _build_crypt() -> void:
	# The old crypt in the north: a fenced graveyard with the Bone King's tomb at the back.
	var holder := Node3D.new()
	holder.name = "Crypt"
	add_child(holder)
	var crypt := _place_abs(GRAVE + "crypt.gltf", Vector3(CRYPT.x, 0, CRYPT.y - 22.0), 0.0, 2.6, holder)
	_add_box_collider(crypt, 0.85)

	# Fence: front line with a gate in the middle, and both sides.
	var front_z := CRYPT.y + 28.0
	_place_abs(GRAVE + "arch_gate.gltf", Vector3(0, 0, front_z), 0.0, 3.0, holder)
	for x in [-36.0, -28.0, -20.0, 20.0, 28.0, 36.0]:
		var f := _place_abs(GRAVE + ("fence_broken.gltf" if absf(x) == 28.0 else "fence.gltf"), Vector3(x, 0, front_z), 0.0, 2.0, holder)
		_add_box_collider(f, 0.9)
	for z in range(int(front_z) - 8, int(CRYPT.y) - 44, -8):
		for x in [-40.0, 40.0]:
			var f := _place_abs(GRAVE + "fence.gltf", Vector3(x, 0, float(z)), 90.0, 2.0, holder)
			_add_box_collider(f, 0.9)
	# the gate pillars block the sides of the opening so the arch reads as the entrance
	for x in [-6.0, 6.0]:
		var pil := _place_abs(GRAVE + "pillar.gltf", Vector3(x, 0, front_z), 0.0, 1.6, holder)
		_add_box_collider(pil, 0.9)

	# Graves, dead trees, coffins and bones - kept clear of the path to the crypt door.
	for i in 34:
		var x := _rng.randf_range(-34.0, 34.0)
		var z := _rng.randf_range(CRYPT.y - 30.0, front_z - 6.0)
		if absf(x) < 7.0:
			continue
		var n := _place_abs(GRAVE + GRAVE_STONES[_rng.randi() % GRAVE_STONES.size()], Vector3(x, 0, z), _rng.randf_range(-12.0, 12.0), _rng.randf_range(1.6, 2.2), holder)
		_add_box_collider(n, 0.7)
	for p in [Vector2(-24, -150), Vector2(26, -152), Vector2(-30, -182), Vector2(31, -190), Vector2(-16, -204), Vector2(18, -206)]:
		var tree := _place_abs(GRAVE + "tree_dead_large.gltf", Vector3(p.x, 0, p.y), _rng.randf() * 360.0, _rng.randf_range(2.6, 3.4), holder)
		_add_cylinder_collider(tree, 1.0, 12.0, Vector3.ZERO)
	for p in [Vector2(-18, -165), Vector2(19, -172), Vector2(-14, -196)]:
		var coffin := _place_abs(GRAVE + ("coffin_decorated.gltf" if p.x < 0 else "coffin.gltf"), Vector3(p.x, 0, p.y), _rng.randf_range(-30.0, 30.0), 1.5, holder)
		_add_box_collider(coffin, 0.9)
	for p in [Vector2(-9, -168), Vector2(10, -176), Vector2(-8, -186), Vector2(9, -192), Vector2(2, -158)]:
		_place_abs(GRAVE + ["bone_A.gltf", "bone_B.gltf", "ribcage.gltf", "skull.gltf", "bone_C.gltf"][_rng.randi() % 5], Vector3(p.x, 0, p.y), _rng.randf() * 360.0, 2.0, holder)
	# Lanterns light the path to the crypt.
	for z in [-150.0, -163.0, -176.0]:
		for x in [-8.0, 8.0]:
			var lamp := _place_abs(GRAVE + "lantern_standing.gltf", Vector3(x, 0, z), 0.0, 2.4, holder)
			var light := OmniLight3D.new()
			light.position = Vector3(x, 2.4, z)
			light.light_color = Color(1.0, 0.7, 0.35)
			light.light_energy = 1.2
			light.omni_range = 11.0
			light.add_to_group("night_lights")
			holder.add_child(light)
			_add_cylinder_collider(lamp, 0.5, 2.0, Vector3.ZERO)
	_occupy(CRYPT.x, CRYPT.y - 6.0, 52)
	_build_catacomb_door()
	_build_pass_gate()
## The door of the old crypt leads down to the catacombs (story part 2). It stays sealed
## until Παπά-Σταύρος has sent George down ("Η Κάθοδος").
func _build_catacomb_door() -> void:
	var front := Vector3(CRYPT.x, 0.0, CRYPT.y - 22.0 + 4.0 * 2.6 + 1.2)
	var spot := InteractSpot.make(Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["catacombs"], func(player: Player):
		if not _catacombs_open():
			player.message.emit(Strings.MSG_CATACOMBS_SEALED)
			return
		var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
		if interiors:
			interiors.enter("catacombs", "catacombs", front + Vector3(0, 0, 1.6), 0.0, player), 4.6)
	spot.prompt_func = func():
		return Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["catacombs"] if _catacombs_open() else "[R] " + Strings.CATACOMBS_SEALED
	spot.position = front
	add_child(spot)


func _catacombs_open() -> bool:
	return Quests.state["descent"] >= Quests.S.ACTIVE


## The stone arch in the northern mountains that leads to the Frontier (story part 3). It stays
## sealed until Παπά-Σταύρος has told George about the Fortress of Shadow ("Η Πύλη του Περάσματος").
func _build_pass_gate() -> void:
	var gate_pos: Vector3 = Frontier.VILLAGE_GATE
	var holder := Node3D.new()
	holder.name = "PassGate"
	add_child(holder)
	_place_abs(GRAVE + "arch_gate.gltf", gate_pos, 0.0, 3.4, holder)
	for dx in [-7.0, 7.0]:
		var lamp := _place_abs(GRAVE + "lantern_standing.gltf", gate_pos + Vector3(dx, 0, 3.0), 0.0, 2.4, holder)
		_add_cylinder_collider(lamp, 0.5, 2.0, Vector3.ZERO)
		var light := OmniLight3D.new()
		light.position = gate_pos + Vector3(dx, 2.4, 3.0)
		light.light_color = Color(0.6, 0.7, 1.0)
		light.light_energy = 1.2
		light.omni_range = 11.0
		light.add_to_group("night_lights")
		holder.add_child(light)
	_occupy(gate_pos.x, gate_pos.z, 14.0)
	var front := gate_pos + Vector3(0, 0, 3.0)
	var enter := func(player: Player):
		if not _frontier_open():
			player.message.emit(Strings.MSG_FRONTIER_SEALED)
			return
		var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
		if interiors:
			interiors.enter_region("frontier", front + Vector3(0, 0, 2.0), 0.0, player)
	var spot := InteractSpot.make(Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["frontier"], enter, 4.6)
	spot.prompt_func = func():
		return Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["frontier"] if _frontier_open() else "[R] " + Strings.FRONTIER_SEALED
	spot.position = front
	add_child(spot)


func _frontier_open() -> bool:
	return Quests.state["f_gate"] >= Quests.S.ACTIVE


func _build_chests_items_signs() -> void:
	var chests := Node3D.new()
	chests.name = "Chests"
	add_child(chests)
	for c in CHESTS:
		var chest := Chest.new()
		chest.position = Vector3(c[0], 0.0, c[1])
		chest.rotation_degrees.y = c[2]
		chest.golden = c[3]
		chest.gold_min = c[4]
		chest.gold_max = c[5]
		chest.potions = c[6]
		chests.add_child(chest)
		_occupy(c[0], c[1], 3.0)
	var items := Node3D.new()
	items.name = "QuestItems"
	add_child(items)
	for q in QUEST_ITEMS:
		var item := QuestItem.new()
		item.item_id = q[0]
		item.position = Vector3(q[1], 0.0, q[2])
		items.add_child(item)
		_occupy(q[1], q[2], 4.0)
	var signs := Node3D.new()
	signs.name = "Signposts"
	add_child(signs)
	for s in SIGNPOSTS:
		_signpost(s[0], Vector3(s[1], 0.0, s[2]), s[3], signs)
		_occupy(s[1], s[2], 4.0)
func _build_totems() -> void:
	var holder := Node3D.new()
	holder.name = "Totems"
	add_child(holder)
	for t in TOTEMS:
		var totem := Totem.new()
		totem.position = Vector3(t.x, 0.0, t.y)
		holder.add_child(totem)
		_occupy(t.x, t.y, 5.0)


func _signpost(text: String, pos: Vector3, rot_deg: float, parent: Node) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_deg
	parent.add_child(root)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.30, 0.17)
	var post := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.45, 5.0, 0.45)
	post.mesh = pm
	post.material_override = wood
	post.position.y = 2.5
	root.add_child(post)
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(5.6, 2.0, 0.25)
	board.mesh = bm
	board.material_override = wood
	board.position = Vector3(0, 4.0, 0.2)
	root.add_child(board)
	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.pixel_size = 0.0105
	label.outline_size = 0
	label.modulate = Color(0.95, 0.88, 0.7)
	label.position = Vector3(0, 4.0, 0.34)
	root.add_child(label)
	var back := Label3D.new()
	back.text = text
	back.font_size = 72
	back.pixel_size = 0.0105
	back.outline_size = 0
	back.modulate = Color(0.95, 0.88, 0.7)
	back.position = Vector3(0, 4.0, 0.06)
	back.rotation_degrees.y = 180.0
	root.add_child(back)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 5.0, 0.6)
	shape.shape = box
	shape.position.y = 2.5
	body.add_child(shape)
	root.add_child(body)


func _build_terrain_details() -> void:
	# Cobbled spokes from every door to the village square, flower borders along them.
	for df in _door_fronts:
		var dir := df.normalized()
		_terrain.add_path([df, df * 0.55 + dir * 4.0, dir * 17.0], 4.2, true, true)
	# Dirt roads to the three story areas (they start at a door spoke or the square).
	_terrain.add_path([Vector2(13, -14), Vector2(27, -48), Vector2(24, -84), Vector2(10, -122), Vector2(0.0, -151.0)], 4.8, false, true)
	_terrain.add_path([Vector2(-78, 19), Vector2(-100, 11), Vector2(-128, 12), Vector2(-154, 17), Vector2(-172, 22)], 4.6, false, true)
	_terrain.add_path([Vector2(88, 52), Vector2(97, 74), Vector2(112, 97), Vector2(128, 114), Vector2(138, 124)], 4.6, false, true)
	# The flower bed around the well.
	_terrain.add_flower_ring(Vector2.ZERO, 4.6, 8.6, 70)
	# A vegetable garden beside every house.
	for h in _home_frames:
		var pos: Vector3 = h[0]
		var right: Vector3 = h[3]
		var forward: Vector3 = h[2]
		var c: Vector3 = pos + right * (float(h[4]) + 9.5) + forward * 1.0
		_terrain.add_garden(Vector2(c.x, c.z), float(h[1]), Vector2(9.0, 7.0))
		_occupy(c.x, c.z, 8.0)
	# A pond with a ring of stones in the south-west meadow.
	var pond := Vector2(-70.0, 108.0)
	_terrain.add_pond(pond, 11.0)
	_occupy(pond.x, pond.y, 17.0)
	var rocks := Node3D.new()
	rocks.name = "PondRocks"
	add_child(rocks)
	for i in 12:
		var a := TAU * float(i) / 12.0 + _rng.randf() * 0.3
		var r := 12.4 + _rng.randf() * 3.0
		var node := _place(ROCKS[_rng.randi() % ROCKS.size()], Vector3(pond.x + cos(a) * r, 0, pond.y + sin(a) * r * 0.72), _rng.randf() * 360.0, ST * _rng.randf_range(0.22, 0.4), rocks)
		_add_box_collider(node, 0.8)


func _finish_terrain() -> void:
	var blocked := func(p: Vector2) -> bool: return _outside_map(p) or _is_occupied(p.x, p.y, 0.7)
	_terrain.scatter_path_flowers(blocked)
	_terrain.scatter_meadow((radius - 2.2) * ROW_H, blocked)
	_terrain.flush_plants()


func _build_scatter() -> void:
	var holder := Node3D.new()
	holder.name = "Nature"
	add_child(holder)
	var reach := (radius - 2.2) * ROW_H     # keep clear of the forest ring at the edge
	# Forest groves
	var groves := 0
	var tries := 0
	while groves < 22 and tries < 400:
		tries += 1
		var c := Vector2(_rng.randf_range(-reach, reach), _rng.randf_range(-reach, reach))
		if _outside_map(c) or _is_occupied(c.x, c.y, 18.0):
			continue
		groves += 1
		for i in _rng.randi_range(10, 22):
			var p := c + Vector2(_rng.randfn(0.0, 14.0), _rng.randfn(0.0, 14.0))
			_try_tree(p, holder)
	# Lone trees and rocks
	var singles := 0
	var rocks := 0
	tries = 0
	while (singles < 90 or rocks < 90) and tries < 4000:
		tries += 1
		var p := Vector2(_rng.randf_range(-reach, reach), _rng.randf_range(-reach, reach))
		if _outside_map(p):
			continue
		if singles < 90 and _rng.randf() < 0.55:
			if _try_tree(p, holder):
				singles += 1
		elif rocks < 90 and not _is_occupied(p.x, p.y, 2.5) and not _terrain.near_path(p, 3.0):
			var scale := _rng.randf_range(1.0, 2.2) * ST * 0.55
			var node := _place(ROCKS[_rng.randi() % ROCKS.size()], Vector3(p.x, 0, p.y),
					_rng.randf_range(0.0, 360.0), scale, holder)
			_add_box_collider(node, 0.8)
			_occupy(p.x, p.y, 3.0)
			rocks += 1


func _try_tree(p: Vector2, holder: Node3D) -> bool:
	if _outside_map(p) or _is_occupied(p.x, p.y, 2.0) or _terrain.near_path(p, 3.0):
		return false
	var scale := TS * _rng.randf_range(0.85, 1.3)
	var node := _place(TREES[_rng.randi() % TREES.size()], Vector3(p.x, 0, p.y),
			_rng.randf_range(0.0, 360.0), scale, holder)
	_add_cylinder_collider(node, 0.1 * scale, 8.0, Vector3.ZERO)
	_occupy(p.x, p.y, 2.2)
	return true


func _outside_map(p: Vector2) -> bool:
	var q := roundi(p.x / HEX_W - p.y / ROW_H * 0.5)
	var r := roundi(p.y / ROW_H)
	return _hex_dist(q, r) > radius - 2


func _build_clouds() -> void:
	var holder := Node3D.new()
	holder.name = "Clouds"
	add_child(holder)
	for i in 14:
		var model := "decoration/nature/cloud_big.gltf" if i % 3 != 0 else "decoration/nature/cloud_small.gltf"
		var c := _place(model, Vector3(_rng.randf_range(-320, 320), _rng.randf_range(110, 140),
				_rng.randf_range(-320, 320)), _rng.randf_range(0, 360), _rng.randf_range(7.0, 13.0), holder)
		_clouds.append(c)


## Lamps for the night: a warm light at every door and lantern posts around the square.
## Their lights are in group "night_lights" (DayNight switches them on after dusk).
func _build_night_lights() -> void:
	var holder := Node3D.new()
	holder.name = "NightLights"
	add_child(holder)
	for df in _door_fronts:
		var light := OmniLight3D.new()
		light.position = Vector3(df.x, 3.4, df.y)
		light.light_color = Color(1.0, 0.72, 0.4)
		light.light_energy = 1.6
		light.omni_range = 13.0
		light.add_to_group("night_lights")
		holder.add_child(light)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var p := Vector2(cos(a), sin(a)) * 30.0
		var lamp := _place_abs(GRAVE + "lantern_standing.gltf", Vector3(p.x, 0, p.y), 0.0, 2.4, holder)
		_add_cylinder_collider(lamp, 0.5, 2.0, Vector3.ZERO)
		var light := OmniLight3D.new()
		light.position = Vector3(p.x, 2.6, p.y)
		light.light_color = Color(1.0, 0.7, 0.35)
		light.light_energy = 1.5
		light.omni_range = 14.0
		light.add_to_group("night_lights")
		holder.add_child(light)


# --------------------------------------------------------------- helpers ----

func _occupy(x: float, z: float, r: float) -> void:
	var v := Vector3(x, z, r)
	if r >= 18.0:
		_occ_big.append(v)
		return
	var key := Vector2i(floori(x / OCC_CELL), floori(z / OCC_CELL))
	if not _occ_grid.has(key):
		_occ_grid[key] = []
	_occ_grid[key].append(v)


func _is_occupied(x: float, z: float, margin: float) -> bool:
	for o in _occ_big:
		if Vector2(x - o.x, z - o.y).length() < o.z + margin:
			return true
	var reach := margin + 18.0
	var c0 := Vector2i(floori((x - reach) / OCC_CELL), floori((z - reach) / OCC_CELL))
	var c1 := Vector2i(floori((x + reach) / OCC_CELL), floori((z + reach) / OCC_CELL))
	for cx in range(c0.x, c1.x + 1):
		for cz in range(c0.y, c1.y + 1):
			var key := Vector2i(cx, cz)
			if not _occ_grid.has(key):
				continue
			for o in _occ_grid[key]:
				if Vector2(x - o.x, z - o.y).length() < o.z + margin:
					return true
	return false


## Loads a model: either relative to assets/world/ or a full res:// path.
func _instance(path: String) -> Node3D:
	var full := path if path.begins_with("res://") else WORLD + path
	if not _cache.has(full):
		if not ResourceLoader.exists(full):
			push_warning("village.gd: missing asset %s" % full)
			_cache[full] = null
		else:
			_cache[full] = load(full)
	var scene = _cache[full]
	if scene == null:
		return Node3D.new()
	return scene.instantiate()


## Places a model at an absolute scale. Returns an unscaled "root" holding the scaled
## visual, so colliders can be added at true world size.
func _place(path: String, pos: Vector3, rot_deg: float, scale: float, parent: Node) -> Node3D:
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	root.position = pos
	root.rotation_degrees.y = rot_deg
	var visual := _instance(path)
	visual.name = "Visual"
	visual.scale = Vector3.ONE * scale
	root.add_child(visual)
	parent.add_child(root)
	return root


## Same as _place for models given by a full res:// path.
func _place_abs(path: String, pos: Vector3, rot_deg: float, scale: float, parent: Node) -> Node3D:
	return _place(path, pos, rot_deg, scale, parent)


func _local_aabb(root: Node3D) -> AABB:
	var visual: Node3D = root.get_node("Visual")
	var inv := visual.global_transform.affine_inverse()
	var have := false
	var box := AABB()
	for mi in visual.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (inv * (mi as MeshInstance3D).global_transform) * (mi as MeshInstance3D).get_aabb()
		box = a if not have else box.merge(a)
		have = true
	# convert from the visual's local units to the root's (world-sized) space
	var s := visual.scale
	return AABB(box.position * s, box.size * s)


func _add_box_collider(root: Node3D, shrink: float = 0.9) -> void:
	var a := _local_aabb(root)
	if a.size == Vector3.ZERO:
		return
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(a.size.x * shrink, maxf(a.size.y, 0.5), a.size.z * shrink)
	shape.shape = box
	shape.position = a.get_center()
	body.add_child(shape)
	root.add_child(body)


func _add_cylinder_collider(root: Node3D, r: float, h: float, offset: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = h
	shape.shape = cyl
	shape.position = offset + Vector3(0, h / 2.0, 0)
	body.add_child(shape)
	root.add_child(body)
