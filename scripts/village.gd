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
	["buildings/red/building_lumbermill_red.gltf", 96.0, 40.0, "", 1.0, ""],
	["buildings/yellow/building_windmill_yellow.gltf", -100.0, -54.1, "", 1.0, "stelios"],
	["buildings/blue/building_tower_A_blue.gltf", 95.1, -78.7, "tower", 1.0, "vasilis"],
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
}

# [quest item id, x, z]   (see quest_data.gd; they only appear while their quest is active)
const QUEST_ITEMS := [
	["keg", -30.0, -142.0], ["keg", 124.0, -26.0], ["keg", 26.0, 78.0], ["keg", -122.0, 74.0],
	["key", -176.0, 24.0],
	# flour sacks scattered around the windmill, logs around the lumber mill
	["sack", -113.0, -41.0], ["sack", -87.0, -67.0], ["sack", -121.0, -63.0], ["sack", -96.0, -33.0], ["sack", -109.0, -81.0],
	["log", 109.0, 24.0], ["log", 82.0, 57.0], ["log", 121.0, 49.0], ["log", 98.0, 67.0], ["log", 77.0, 27.0], ["log", 113.0, 38.0],
]

# Bone totems (quest "Τα Οστέινα Τοτέμ"): x, z. They only stand while the quest is active.
const TOTEMS := [Vector2(-175.0, 27.0), Vector2(153.0, 133.0), Vector2(17.0, -142.0)]   # the quarry one used to stand inside a rock (147, 135)

# [x, z, rotation, golden, gold_min, gold_max, potions, optional: true = a mimic]   (more chests are inside the houses)
const CHESTS := [
	[-186.0, 14.0, 80, false, 15, 35, 1],      # west camp
	[152.0, 116.0, 200, true, 30, 60, 2],      # quarry
	[-26.0, -197.0, 20, true, 50, 90, 2],      # crypt
	[-133.0, -76.0, 40, false, 10, 25, 0],     # behind the windmill
	[134.0, -78.0, 150, false, 12, 28, 1],     # beside the watchtower
	[92.0, 120.0, 250, false, 8, 20, 0],       # south-east farm track
	[-100.0, 76.0, 0, false, 10, 24, 1],       # south-west meadow edge
	[-135.0, -95.0, 30, true, 150, 250, 2],    # the bandits' hideout (BanditCamp.CHEST)
	[CultSite.CHEST.x, CultSite.CHEST.y, 200, true, 120, 200, 2],   # the cult's ritual circle
	[-30.0, -135.0, 200, false, 10, 20, 0, true],   # a mimic by the road to the crypt
	[128.0, -52.0, 120, false, 10, 20, 0, true],    # a mimic in the east meadow
	[160.0, 100.0, 60, false, 10, 20, 0, true],     # a mimic at the quarry
]

# [text, x, z, rotation in degrees (the board faces +Z when 0)]
const SIGNPOSTS := [
	["Δυτικό Στρατόπεδο  ←", -138.0, 4.0, 90],
	["Λατομείο  ↘", 104.0, 84.0, 20],
	["Το Μεγάλο Δέντρο  →", 112.0, -44.0, 270],
	["Παλιά Κρύπτη  ↑\nΚίνδυνος!", 14.0, -118.0, 0],
	["Κρησφύγετο Ληστών  ↖\nΚίνδυνος!", -118.0, -74.0, 42],
	["Ξέφωτο της Σέκτας  ↖\nΚίνδυνος!", CultSite.SIGN.x, CultSite.SIGN.y, 20],
	["Προς τη Θάλασσα & το Φάρο  ↓", -12.0, 62.0, 0],
	["Ποταμός & Καταρράκτης  ↗", 42.0, -52.0, 315],
	["Βίγλα των Αετών (Οροπέδιο 14μ)  ↗", 38.0, -96.0, 330],
]

const CAMP := Vector2(-175.0, 20.0)
const QUARRY := Vector2(140.0, 125.0)
const CRYPT := Vector2(0.0, -178.0)
const STABLE := Vector2(63.0, 53.0)   # the stable yard of Μανώλης (open ground; the horse is sold there)
const DOCK_ANGLE := -60.0            # where on the pond shore the fishing dock stands (degrees, 0 = east, -90 = north)

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
	var merchant = (load("res://scripts/traveling_merchant.gd") as GDScript).new()
	merchant.name = "TravelingMerchant"
	add_child(merchant)
	var parkour = ParkourCourse.new()
	parkour.name = "ParkourCourse"
	add_child(parkour)
	_build_camp()
	_build_quarry()
	_build_lumbermill()
	_build_ruined_outpost()
	_build_golden_grove()
	_build_archery_grounds()
	_build_crypt()
	_build_chests_items_signs()
	_build_totems()
	_build_stable()
	_build_animals()
	_build_bandit_camp()
	_build_cult_site()
	_build_pumpkin_patch()
	_occupy(RescueEvent.SITE.x, RescueEvent.SITE.y, 14.0)      # the meadow of the rescue event stays open
	_build_great_tree()
	_build_alchemy_and_flora()
	_build_blacksmith_forge()
	_build_bounty_board()
	_build_george_cottage()
	_build_gladiator_arena()
	# ------------------------------------------------------------- Island Overhaul ----
	add_child(IslandSouthSea.new())
	add_child(IslandRiver.new())
	add_child(IslandHighlands.new())
	_build_rolling_hills()
	_occupy_island_features()
	# ----------------------------------------------------------------------------------
	_build_terrain_details()
	_build_scatter()
	_finish_terrain()
	_build_clouds()
	_build_night_lights()
	_build_nav()


## The walkable-ground grid enemies and guards use to get around houses and trees (see nav_grid.gd). It is
## prepared on worker threads; until it is ready they walk straight as before.
func _build_nav() -> void:
	var half := Vector2(HEX_W * (radius + 1.0), ROW_H * (radius + 1.0))
	var grid := NavGrid.build([self], Rect2(-half, half * 2.0))
	grid.prepare(true)
	NavGrid.set_region("village", grid)


func _exit_tree() -> void:
	NavGrid.clear_regions()


func _process(delta: float) -> void:
	for c in _clouds:
		c.position.x += delta * 1.8
		if c.position.x > 400.0:
			c.position.x = -400.0


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

	# Split ground colliders: keep the world solid everywhere EXCEPT the south sea bay opening!
	# The south sea bay (X in [-165, 55], Z >= 86) has its own sloped beach and seabed colliders in IslandSouthSea.
	var body := StaticBody3D.new()
	body.name = "GroundCollider"

	# 1. Main North & Central land mass (Z from -260 to +86)
	var shape_main := CollisionShape3D.new()
	var box_main := BoxShape3D.new()
	box_main.size = Vector3(HEX_W * (radius * 2 + 2), 2.0, 346.0)
	shape_main.shape = box_main
	shape_main.position = Vector3(0.0, -1.0, -87.0)
	body.add_child(shape_main)

	# 2. South-East land mass (Quarry sector: X from 55 to 270, Z from 86 to 260)
	var shape_se := CollisionShape3D.new()
	var box_se := BoxShape3D.new()
	box_se.size = Vector3(215.0, 2.0, 174.0)
	shape_se.shape = box_se
	shape_se.position = Vector3(162.5, -1.0, 173.0)
	body.add_child(shape_se)

	# 3. South-West land mass (Mountain sector: X from -270 to -165, Z from 86 to 260)
	var shape_sw := CollisionShape3D.new()
	var box_sw := BoxShape3D.new()
	box_sw.size = Vector3(105.0, 2.0, 174.0)
	shape_sw.shape = box_sw
	shape_sw.position = Vector3(-217.5, -1.0, 173.0)
	body.add_child(shape_sw)

	add_child(body)

	# Ground patches: cobbled village square and the three story areas.
	_terrain.add_patch(Vector2.ZERO, 21.0, Color(0.66, 0.62, 0.54), true, Color(0.30, 0.27, 0.22))
	_terrain.add_patch(CAMP, 34.0, Color(0.58, 0.47, 0.30))
	_terrain.add_patch(QUARRY, 38.0, Color(0.60, 0.60, 0.57), false, Color(0.38, 0.38, 0.36))
	_terrain.add_patch(CRYPT + Vector2(0, -2), 46.0, Color(0.38, 0.43, 0.38), false, Color(0.25, 0.29, 0.25))
	_terrain.add_patch(Vector2(92.0, 36.0), 24.0, Color(0.52, 0.42, 0.28), false, Color(0.35, 0.28, 0.19))


func _build_border() -> void:
	# Outer ring = mountains and hills that act as the edge of the world.
	# Next ring in = dense forest.
	var holder := Node3D.new()
	holder.name = "Border"
	add_child(holder)
	for h in _all_hexes():
		var d := _hex_dist(h.x, h.y)
		var pos := _hex_to_world(h.x, h.y)
		# Skip south border mountains/forests so the coast opens up to the sea!
		if pos.z > 86.0 and pos.x >= -165.0 and pos.x <= 55.0:
			continue
		if d == radius:
			var model: String = BORDER[_rng.randi() % BORDER.size()]
			var node := _place(model, pos, _rng.randi_range(0, 5) * 60.0, ST * 1.45, holder)
			_add_cylinder_collider(node, ST * 1.4, 40.0, Vector3.ZERO)
		elif d == radius - 1:
			var model: String = FORESTS[_rng.randi() % FORESTS.size()]
			var node := _place(model, pos, _rng.randi_range(0, 5) * 60.0, ST, holder)
			_add_cylinder_collider(node, ST * 0.85, 20.0, Vector3.ZERO)


## Natural undulating hills in the lowland meadows to break up terrain flatness.
func _build_rolling_hills() -> void:
	var holder := Node3D.new()
	holder.name = "RollingHills"
	add_child(holder)

	var hill_data: Array[Dictionary] = [
		{"model": "decoration/nature/hills_A.gltf", "pos": Vector3(-118.0, 0.0, -18.0), "rot": 45.0, "scale": 11.0},
		{"model": "decoration/nature/hill_single_A.gltf", "pos": Vector3(-88.0, 0.0, 6.0), "rot": 120.0, "scale": 9.0},
		{"model": "decoration/nature/hills_B.gltf", "pos": Vector3(-6.0, 0.0, 70.0), "rot": 20.0, "scale": 10.5},
		{"model": "decoration/nature/hill_single_B.gltf", "pos": Vector3(32.0, 0.0, 74.0), "rot": 210.0, "scale": 8.5},
		{"model": "decoration/nature/hills_C.gltf", "pos": Vector3(88.0, 0.0, 74.0), "rot": 85.0, "scale": 10.0},
		{"model": "decoration/nature/hill_single_C.gltf", "pos": Vector3(105.0, 0.0, 8.0), "rot": 160.0, "scale": 8.0},
	]

	for hd in hill_data:
		_place(hd["model"], hd["pos"], hd["rot"], hd["scale"], holder)


## Clear space in scatter grid so procedural trees/rocks do not overlap the ocean, river or highlands.
func _occupy_island_features() -> void:
	# 1. South Sea Coast & Sandy Beach
	_occupy(-115.0, 138.0, 16.0) # Lighthouse promontory
	_occupy(-35.0, 126.0, 16.0)  # Fishing pier
	for bx in range(-140, 45, 18):
		_occupy(float(bx), 118.0, 14.0)
		_occupy(float(bx), 142.0, 16.0)
		_occupy(float(bx), 170.0, 18.0)

	# 2. Waterfall & River channel
	_occupy(48.0, -132.0, 16.0) # Waterfall & plunge pool
	_occupy(70.0, -66.0, 12.0)  # Arched Bridge 1
	_occupy(114.0, -22.0, 12.0) # Arched Bridge 2
	for wp in IslandRiver.RIVER_WAYPOINTS:
		_occupy(wp.x, wp.y, 8.0)

	# 3. North Highlands
	_occupy(68.0, -132.0, 14.0)
	_occupy(76.0, -145.0, 16.0)
	_occupy(82.0, -155.0, 18.0) # Summit



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
		if b[0].find("lumbermill") >= 0:
			_add_trimesh_collider(node)
		else:
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
			# For Maria (tavern, index 1), stand on the front terrace porch clear of parkour stairs
			if i == 1:
				npc.position = door_front + right * 2.8 + forward * 1.5
			else:
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
	v.display_name = VillagerData.name_for(v.model_path, _villager_count * 7 + 2)
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
## The bandits' hideout in the north-west forest: tents around a fire, crates, barrels, a flag and a weapon rack.
## The creatures are in Enemies.SPAWNS, the golden chest in CHESTS.
func _build_bandit_camp() -> void:
	var holder := Node3D.new()
	holder.name = "BanditCamp"
	add_child(holder)
	var c := BanditCamp.CENTER
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.5
		var p := c + Vector2(cos(a), sin(a)) * 14.0
		var node := _place("decoration/props/tent.gltf", Vector3(p.x, 0, p.y), rad_to_deg(-a) - 90.0, PS * 1.8, holder)
		_add_box_collider(node, 0.8)
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		var p := c + Vector2(cos(a), sin(a)) * 3.5
		_place_abs(ITEMS + "torch_lit.gltf.glb", Vector3(p.x, 0, p.y), 0.0, 2.2, holder)
	var light := OmniLight3D.new()
	light.position = Vector3(c.x, 3.0, c.y)
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = 2.0
	light.omni_range = 22.0
	light.add_to_group("night_lights")
	holder.add_child(light)
	for e in [
			["decoration/props/weaponrack.gltf", -8.0, -4.0, 40, 1.6], ["decoration/props/crate_A_big.gltf", 8.0, -8.0, 20, 1.2],
			["decoration/props/crate_B_big.gltf", 10.0, -6.5, 70, 1.2], ["decoration/props/barrel.gltf", -7.0, 8.0, 0, 1.2],
			["decoration/props/barrel.gltf", -5.5, 8.5, 40, 1.2], ["decoration/props/sack.gltf", 6.0, 8.0, 80, 1.2],
			["decoration/props/flag_red.gltf", 0.0, -12.0, 0, 1.3], ["decoration/props/wheelbarrow.gltf", 11.0, 4.0, 130, 1.2]]:
		var node := _place(e[0], Vector3(c.x + e[1], 0, c.y + e[2]), float(e[3]), PS * e[4], holder)
		_add_box_collider(node, 0.8)
	_occupy(c.x, c.y, BanditCamp.RADIUS)


## The cult's ritual circle in the north-west forest: dark ground, a ring of candles, skull posts, a shrine as the altar
## with a red glow, banners and heaps of bones. The creatures are in Enemies.SPAWNS, the quest is "cult".
func _build_cult_site() -> void:
	var holder := Node3D.new()
	holder.name = "CultSite"
	add_child(holder)
	var c := CultSite.CENTER
	_terrain.add_patch(c, 21.0, Color(0.24, 0.17, 0.19), false, Color(0.12, 0.08, 0.10))
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.55, 0.15)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.5, 0.1)
	flame_mat.emission_energy_multiplier = 3.5
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.1
	flame_mesh.height = 0.3
	for i in 16:
		var a := TAU * float(i) / 16.0
		var p := c + Vector2(cos(a), sin(a)) * 11.5
		_place_abs(GRAVE + "candle_triple.gltf", Vector3(p.x, 0.0, p.y), rad_to_deg(-a), 1.6, holder)
		var flame := MeshInstance3D.new()
		flame.mesh = flame_mesh
		flame.material_override = flame_mat
		flame.position = Vector3(p.x, 1.3, p.y)
		holder.add_child(flame)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI / 4.0
		var p := c + Vector2(cos(a), sin(a)) * 15.5
		var post := _place_abs(GRAVE + "post_skull.gltf", Vector3(p.x, 1.29 * 0.9, p.y), rad_to_deg(-a) + 90.0, 0.9, holder)
		_add_cylinder_collider(post, 0.5, 2.8, Vector3(0.0, -1.0, 0.0))
	var altar := _place_abs(GRAVE + "shrine_candles.gltf", Vector3(CultSite.ALTAR.x, 0.0, CultSite.ALTAR.y), 0.0, 2.6, holder)
	_add_box_collider(altar, 0.8)
	var glow := OmniLight3D.new()
	glow.position = Vector3(CultSite.ALTAR.x, 3.2, CultSite.ALTAR.y + 2.0)
	glow.light_color = Color(0.95, 0.18, 0.30)
	glow.light_energy = 2.2
	glow.omni_range = 24.0
	holder.add_child(glow)
	for off in [-7.0, 7.0]:
		_place_abs(ITEMS + "banner_red.gltf.glb", Vector3(CultSite.ALTAR.x + off, 0.0, CultSite.ALTAR.y - 1.5), 0.0, 2.6, holder)
	for e in [[GRAVE + "ribcage.gltf", -6.0, 2.0, 30.0, 1.8], [GRAVE + "skull.gltf", 5.0, 4.0, 200.0, 1.3],
			[GRAVE + "bone_C.gltf", -4.0, 6.0, 70.0, 1.8], [GRAVE + "bone_A.gltf", 7.0, -2.0, 140.0, 1.8],
			[GRAVE + "skull.gltf", -8.0, -4.0, 20.0, 1.2], [GRAVE + "ribcage.gltf", 8.0, 7.0, 250.0, 1.8]]:
		_place_abs(e[0], Vector3(c.x + e[1], 0.0, c.y + e[2]), float(e[3]), float(e[4]), holder)
	_occupy(c.x, c.y, CultSite.RADIUS)


## A tilled patch beside the road to the crypt full of pumpkins; five of them are alive (Enemies.SPAWNS, kind pumpkin).
func _build_pumpkin_patch() -> void:
	var holder := Node3D.new()
	holder.name = "PumpkinPatch"
	add_child(holder)
	var c := CultSite.PATCH
	_terrain.add_patch(c, 10.5, Color(0.36, 0.27, 0.16), false, Color(0.22, 0.16, 0.10))
	var rng := RandomNumberGenerator.new()             # its own sequence: the world's random numbers must not shift
	rng.seed = 4412
	var kinds := ["pumpkin_orange.gltf", "pumpkin_yellow.gltf", "pumpkin_orange_small.gltf", "pumpkin_yellow_small.gltf",
			"pumpkin_orange_jackolantern.gltf", "pumpkin_yellow_jackolantern.gltf"]
	for i in 18:
		var a := rng.randf() * TAU
		var d := rng.randf_range(1.0, CultSite.PATCH_RADIUS)
		var p := c + Vector2(cos(a), sin(a)) * d
		_place_abs(GRAVE + kinds[rng.randi() % kinds.size()], Vector3(p.x, 0.0, p.y), rng.randf() * 360.0, rng.randf_range(0.8, 1.15), holder)
	_occupy(c.x, c.y, CultSite.PATCH_RADIUS + 6.0)


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
		_add_rock_collider(node)
	for i in 14:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(24.0, 40.0)
		var p := QUARRY + Vector2(cos(a), sin(a)) * d
		var node := _place(ROCKS[_rng.randi() % ROCKS.size()], Vector3(p.x, 0, p.y), _rng.randf() * 360.0, PS * _rng.randf_range(3.0, 5.0), holder)
		_add_rock_collider(node)
	for e in [["decoration/props/crate_A_big.gltf", -8.0, -4.0, 30, 1.4], ["decoration/props/crate_B_big.gltf", -6.0, -6.0, 80, 1.4],
			["decoration/props/barrel.gltf", 7.0, -8.0, 0, 1.4], ["decoration/props/wheelbarrow.gltf", 9.0, -5.0, 150, 1.4],
			["decoration/props/resource_lumber.gltf", -12.0, 8.0, 60, 1.2]]:
		var node := _place(e[0], Vector3(QUARRY.x + e[1], 0, QUARRY.y + e[2]), float(e[3]), PS * e[4], holder)
		_add_box_collider(node, 0.8)
	_place_abs(ITEMS + "banner_red.gltf.glb", Vector3(QUARRY.x - 5.0, 0, QUARRY.y + 6.0), 0.0, 2.6, holder)
	_place_abs(ITEMS + "banner_red.gltf.glb", Vector3(QUARRY.x + 5.0, 0, QUARRY.y + 6.0), 0.0, 2.6, holder)

	# Mine excavation entrance, scaffolding and extraction platform (trimesh colliders allow walking into mine shaft and onto stage)
	var mine := _place("buildings/blue/building_mine_blue.gltf", Vector3(QUARRY.x + 8.0, 0.0, QUARRY.y + 14.0), -45.0, BS * 1.15, holder)
	_add_trimesh_collider(mine)
	var scaffold := _place("buildings/neutral/building_scaffolding.gltf", Vector3(QUARRY.x - 2.0, 0.0, QUARRY.y + 16.0), 15.0, BS * 0.95, holder)
	_add_trimesh_collider(scaffold)
	var stage := _place("buildings/neutral/building_stage_B.gltf", Vector3(QUARRY.x + 3.0, 0.0, QUARRY.y - 12.0), 30.0, BS * 0.9, holder)
	_add_trimesh_collider(stage)

	_occupy(QUARRY.x, QUARRY.y, 42)


## The working timber mill of Gero-Giannis the woodcutter in the eastern forest edge.
## Features a dedicated open-air carpenter workbench, chopping block with embedded woodcutter's axe,
## sawdust mounds, woodcutter's tools, timber seasoning shelter, perimeter log stacks, rustic fencing,
## entrance gate with signpost, and warm lantern lighting with zero clutter clipping.
func _build_lumbermill() -> void:
	var holder := Node3D.new()
	holder.name = "Lumbermill"
	add_child(holder)

	# 1. GERO-GIANNIS'S MASTER CARPENTER WORKSTATION
	# Open, elevated, prominent woodcutter foreman platform with clear 10m line of sight to village road
	var giannis_pos := Vector3(85.5, 0.0, 26.5)
	var giannis := Npc.new()
	giannis.name = "Giannis"
	giannis.npc_id = "giannis"
	giannis.rest_yaw = deg_to_rad(-115.0) # Faces WNW towards the incoming village path & entrance gate
	giannis.position = giannis_pos
	var npcs := get_node_or_null("Npcs")
	(npcs if npcs else holder).add_child(giannis)

	# Heavy carpenter's workbench placed in front of Giannis as his work counter
	var bench_pos := Vector3(84.3, 0.0, 25.4)
	var bench := _place("decoration/props/crate_long_A.gltf", bench_pos, 65.0, PS * 1.15, holder)
	_add_box_collider(bench, 0.85)

	# Lit warm lantern on Giannis's workbench
	var bench_lamp := _place_abs(ITEMS + "torch_lit.gltf.glb", Vector3(84.0, 0.82, 24.8), 0.0, 1.5, holder)
	var bench_light := OmniLight3D.new()
	bench_light.name = "GiannisWorkLight"
	bench_light.light_color = Color(1.0, 0.82, 0.48)
	bench_light.light_energy = 1.8
	bench_light.omni_range = 6.5
	bench_light.position = Vector3(84.0, 1.45, 24.8)
	holder.add_child(bench_light)

	# Water quench / blade cooling bucket beside the workbench
	var bucket := _place("decoration/props/bucket_water.gltf", Vector3(83.1, 0.0, 26.4), 20.0, PS * 1.1, holder)
	_add_box_collider(bucket, 0.7)

	# 2. CHOPPING BLOCK & EMBEDDED WOODCUTTER'S AXE
	# Sturdy tree stump chopping block positioned to Giannis's left
	var stump_pos := Vector3(86.2, 0.0, 29.8)
	var stump := _place("decoration/nature/tree_single_A_cut.gltf", stump_pos, 35.0, 1.35, holder)
	_add_cylinder_collider(stump, 0.65, 0.85, Vector3.ZERO)

	# Real Woodcutter's Axe embedded firmly in the top center of the chopping block
	var axe_root := Node3D.new()
	axe_root.name = "WoodcutterAxe"
	axe_root.position = Vector3(86.2, 0.82, 29.8)
	axe_root.rotation_degrees = Vector3(-18.0, 40.0, 8.0)
	var axe_scene = load("res://assets/characters/skeleton_weapons/Skeleton_Axe.gltf")
	if axe_scene:
		var axe_model: Node3D = axe_scene.instantiate()
		axe_model.scale = Vector3.ONE * 1.1
		axe_root.add_child(axe_model)
	holder.add_child(axe_root)

	# Sawdust wood shavings mound under the chopping block
	var sawdust := MeshInstance3D.new()
	sawdust.name = "SawdustShavings"
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = 1.4
	cyl_mesh.bottom_radius = 1.8
	cyl_mesh.height = 0.03
	var sawdust_mat := StandardMaterial3D.new()
	sawdust_mat.albedo_color = Color(0.76, 0.62, 0.38)
	sawdust_mat.roughness = 0.95
	sawdust.mesh = cyl_mesh
	sawdust.material_override = sawdust_mat
	sawdust.position = Vector3(86.2, 0.02, 29.8)
	holder.add_child(sawdust)

	# Stack of freshly split firewood logs beside the chopping block
	var split_logs := _place("decoration/nature/tree_single_B_cut.gltf", Vector3(87.6, 0.0, 30.6), -25.0, 1.15, holder)
	_add_box_collider(split_logs, 0.7)

	# Woodcutter's wheelbarrow loaded with split firewood
	var barrow := _place("decoration/props/wheelbarrow.gltf", Vector3(89.2, 0.0, 25.0), 115.0, PS * 1.2, holder)
	_add_box_collider(barrow, 0.75)

	# 3. TIMBER SEASONING & DRYING SHED (SCAFFOLDING SHELTER)
	# Relocated south to clear Giannis and the main road; open walkthrough with Trimesh Collider
	var shed_pos := Vector3(82.0, 0.0, 48.0)
	var shed := _place("buildings/neutral/building_scaffolding.gltf", shed_pos, 15.0, BS * 0.75, holder)
	_add_trimesh_collider(shed)

	# Seasoned timber neatly stacked under the shelter against rear posts
	var shed_lumber_1 := _place("decoration/props/resource_lumber.gltf", shed_pos + Vector3(-1.4, 0.0, 1.8), 15.0, PS * 1.35, holder)
	_add_box_collider(shed_lumber_1, 0.8)
	var shed_lumber_2 := _place("decoration/props/resource_lumber.gltf", shed_pos + Vector3(1.6, 0.0, 1.0), 15.0, PS * 1.35, holder)
	_add_box_collider(shed_lumber_2, 0.8)

	# Hanging lantern under seasoning shed roof
	var shed_lamp := _place_abs(ITEMS + "torch_lit.gltf.glb", shed_pos + Vector3(0.0, 2.7, 0.0), 0.0, 1.5, holder)
	var shed_light := OmniLight3D.new()
	shed_light.name = "ShedLight"
	shed_light.light_color = Color(1.0, 0.80, 0.45)
	shed_light.light_energy = 1.3
	shed_light.omni_range = 6.0
	shed_light.position = shed_pos + Vector3(0.0, 2.5, 0.0)
	holder.add_child(shed_light)

	# 4. SAWMILL BUILDING DECK & ACCESSORIES
	# Pallet of freshly planed boards on the mill approach ramp
	var mill_pallet := _place("decoration/props/pallet.gltf", Vector3(91.8, 0.0, 36.8), 25.0, PS * 1.25, holder)
	_add_box_collider(mill_pallet, 0.8)
	var mill_planks := _place("decoration/props/resource_lumber.gltf", Vector3(91.8, 0.35, 36.8), 25.0, PS * 1.15, holder)
	_add_box_collider(mill_planks, 0.8)

	# Heavy carpenter tool crate and pitch barrel beside the mill
	var mill_crate := _place("decoration/props/crate_long_B.gltf", Vector3(97.5, 0.0, 34.0), -15.0, PS * 1.1, holder)
	_add_box_collider(mill_crate, 0.75)
	var resin_barrel := _place("decoration/props/barrel.gltf", Vector3(101.5, 0.0, 37.0), 10.0, PS * 1.15, holder)
	_add_box_collider(resin_barrel, 0.75)

	# 5. FOREST PERIMETER TIMBER STORAGE & TREE STUMPS
	# Heavy tree trunks stacked along the forest border
	var log_stack_1 := _place("decoration/props/resource_lumber.gltf", Vector3(104.5, 0.0, 27.5), -75.0, PS * 1.5, holder)
	_add_box_collider(log_stack_1, 0.8)
	var log_stack_2 := _place("decoration/props/resource_lumber.gltf", Vector3(105.0, 0.0, 47.0), 10.0, PS * 1.5, holder)
	_add_box_collider(log_stack_2, 0.8)

	# Tall wooden ladder leaning against the timber stack
	var ladder := _place("decoration/props/ladder.gltf", Vector3(103.2, 0.0, 29.5), 105.0, PS * 1.35, holder)
	_add_box_collider(ladder, 0.6)

	# Harvested stump cluster in the clearing
	var stumps := _place("decoration/nature/trees_A_cut.gltf", Vector3(100.0, 0.0, 21.0), 20.0, 1.35, holder)
	_add_box_collider(stumps, 0.8)

	# 6. RUSTIC WOODEN FENCING & WELCOMING ENTRANCE GATE
	# Boundary fences with wide 6.5m open entrance passage connecting to village road
	var fence_1 := _place("buildings/neutral/fence_wood_straight.gltf", Vector3(75.5, 0.0, 19.5), 80.0, BS * 0.85, holder)
	_add_box_collider(fence_1, 0.6)
	var fence_2 := _place("buildings/neutral/fence_wood_straight.gltf", Vector3(75.5, 0.0, 34.0), 100.0, BS * 0.85, holder)
	_add_box_collider(fence_2, 0.6)
	var fence_3 := _place("buildings/neutral/fence_wood_straight.gltf", Vector3(76.5, 0.0, 42.5), 105.0, BS * 0.85, holder)
	_add_box_collider(fence_3, 0.6)

	# Entrance Signpost right by the gateway post facing the village road
	_signpost("Υλοτομείο Αγίου Βλάση  →\nΕργαστήρι Γέρο-Γιάννη", Vector3(74.5, 0.0, 23.8), 110.0, holder)

	# Standing lantern at the entrance gate
	var gate_lamp := _place_abs(GRAVE + "lantern_standing.gltf", Vector3(74.2, 0.0, 22.6), 0.0, 2.2, holder)
	var gate_light := OmniLight3D.new()
	gate_light.name = "GateLampLight"
	gate_light.light_color = Color(1.0, 0.85, 0.52)
	gate_light.light_energy = 1.4
	gate_light.omni_range = 5.5
	gate_light.position = Vector3(74.2, 2.2, 22.6)
	holder.add_child(gate_light)

	# 7. OCCUPATION GRIDS
	# Reserve areas to keep random trees, rocks and flora clear of the lumber yard
	_occupy(85.5, 26.5, 4.0)   # Giannis workstation & clearing
	_occupy(96.0, 40.0, 15.0)  # Main lumbermill building
	_occupy(82.0, 48.0, 10.0)  # Seasoning shed
	_occupy(104.0, 36.0, 12.0) # Forest perimeter timber stacks
	_occupy(75.5, 27.0, 5.0)   # Entrance gate & approach path


## The ruined eastern fortress now occupied by the Orc Warband.
func _build_ruined_outpost() -> void:
	var holder := Node3D.new()
	holder.name = "RuinedOutpost"
	add_child(holder)

	var center := Vector3(150.0, 0.0, 68.0)

	# Ruined keep / fortress (trimesh collider allows walking through ruined arches and courtyard!)
	var destroyed := _place("buildings/neutral/building_destroyed.gltf", center, 45.0, BS * 1.2, holder)
	_add_trimesh_collider(destroyed)

	# Entrance door to explore inside the Ruined Orc Castle Keep!
	var castle_door_front := center + Vector3(-3.5, 0.05, 4.0)
	var orc_door_label: String = Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["orc_castle"]
	var orc_castle_spot := InteractSpot.make(orc_door_label, func(player: Player):
		var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
		if interiors:
			interiors.enter("orc_castle_0", "orc_castle", castle_door_front, deg_to_rad(45.0), player), 4.6)
	orc_castle_spot.position = castle_door_front
	holder.add_child(orc_castle_spot)

	# Fortification walls & gates (gate and walls use trimesh collider so gateway arch and corridors are open!)
	var wall1 := _place("buildings/neutral/wall_straight.gltf", center + Vector3(-8.0, 0.0, -4.0), 20.0, BS * 1.0, holder)
	_add_trimesh_collider(wall1)
	var wall2 := _place("buildings/neutral/wall_straight.gltf", center + Vector3(8.0, 0.0, 4.0), 20.0, BS * 1.0, holder)
	_add_trimesh_collider(wall2)
	var gate := _place("buildings/neutral/wall_corner_A_gate.gltf", center + Vector3(-12.0, 0.0, 6.0), -60.0, BS * 1.0, holder)
	# Remove closed gate doors so the ruined fortress entrance arch is wide open and passable
	for d in gate.find_children("*door*", "MeshInstance3D", true, false):
		d.free()
	_add_trimesh_collider(gate)

	# Siege weapon & war banners
	var catapult := _place("buildings/neutral/projectile_catapult.gltf", center + Vector3(-5.0, 0.0, 11.0), -120.0, BS * 0.9, holder)
	_add_box_collider(catapult)
	_place_abs(ITEMS + "banner_red.gltf.glb", center + Vector3(-4.0, 0.0, -7.0), 0.0, 2.8, holder)
	_place_abs(ITEMS + "banner_red.gltf.glb", center + Vector3(5.0, 0.0, 8.0), 180.0, 2.8, holder)

	# Props around outpost
	var outpost_props: Array = [
		["decoration/props/barrel.gltf", center + Vector3(4.0, 0.0, -2.0), 10.0, 1.4],
		["decoration/props/crate_open.gltf", center + Vector3(6.0, 0.0, -4.0), 45.0, 1.3],
		["decoration/props/tent.gltf", center + Vector3(12.0, 0.0, -7.0), -45.0, 1.4],
	]
	for op in outpost_props:
		var n := _place(op[0], op[1], op[2], PS * op[3], holder)
		_add_box_collider(n, 0.75)

	_signpost("Ερειπωμένο Προπύργιο  ↖\nΠροσοχή: Πολεμική Συμμορία Όρκ!", center + Vector3(-16.0, 0.0, -5.0), 75.0, holder)
	_occupy(center.x, center.z, 22.0)

	# Story Part 6: The Siege of the Orc Stronghold Raid Controller
	var raid_sc := preload("res://scripts/orc_stronghold_raid.gd")
	var raid := raid_sc.new()
	holder.add_child(raid)


## Autumn golden and orange pine forest grove on the eastern ridge.
func _build_golden_grove() -> void:
	var holder := Node3D.new()
	holder.name = "GoldenGrove"
	add_child(holder)

	var center := Vector3(112.0, 0.0, 68.0)

	# Beautiful Autumn golden and orange pine clusters
	var pines: Array = [
		[GRAVE + "tree_pine_orange_large.gltf", center + Vector3(-8.0, 0.0, -6.0), 30.0, 1.5],
		[GRAVE + "tree_pine_orange_medium.gltf", center + Vector3(-12.0, 0.0, 4.0), -45.0, 1.4],
		[GRAVE + "tree_pine_orange_small.gltf", center + Vector3(-4.0, 0.0, 8.0), 70.0, 1.3],
		[GRAVE + "tree_pine_yellow_large.gltf", center + Vector3(8.0, 0.0, -8.0), -15.0, 1.5],
		[GRAVE + "tree_pine_yellow_medium.gltf", center + Vector3(12.0, 0.0, 2.0), 110.0, 1.4],
		[GRAVE + "tree_pine_yellow_small.gltf", center + Vector3(6.0, 0.0, 9.0), -80.0, 1.3],
		[GRAVE + "tree_pine_orange_large.gltf", center + Vector3(2.0, 0.0, -14.0), 40.0, 1.6],
		[GRAVE + "tree_pine_yellow_large.gltf", center + Vector3(-6.0, 0.0, -15.0), -60.0, 1.5],
	]
	for p in pines:
		var node := _place_abs(p[0], p[1], p[2], p[3], holder)
		_add_box_collider(node, 0.4)

	# Central ancient lantern tree
	var anc_tree := _place_abs(GRAVE + "tree_dead_large_decorated.gltf", center, 15.0, 1.8, holder)
	_add_box_collider(anc_tree, 0.5)

	var omni := OmniLight3D.new()
	omni.light_color = Color(1.0, 0.78, 0.38)
	omni.light_energy = 1.4
	omni.omni_range = 14.0
	omni.position = center + Vector3(0.0, 3.5, 0.0)
	holder.add_child(omni)

	# Decorated sitting benches
	var bench1 := _place_abs(GRAVE + "bench_decorated.gltf", center + Vector3(-3.2, 0.0, 2.5), 35.0, 1.2, holder)
	_add_box_collider(bench1, 0.7)
	var bench2 := _place_abs(GRAVE + "bench_decorated.gltf", center + Vector3(3.5, 0.0, -1.8), -145.0, 1.2, holder)
	_add_box_collider(bench2, 0.7)

	_signpost("Άλσος των Χρυσών Πεύκων  ↗\nΠροσοχή στους Άγριους Λύκους!", center + Vector3(-14.0, 0.0, -10.0), 45.0, holder)
	_occupy(center.x, center.z, 20.0)

	# Wilderness Pet: Trapped Silver Wolf Pup companion
	var wolf_pup_sc := preload("res://scripts/wolf_pup_companion.gd")
	var wolf_pup := wolf_pup_sc.new()
	wolf_pup.position = center + Vector3(6.0, 0.0, -5.0)
	holder.add_child(wolf_pup)


## Archery training grounds and village defense barracks.
func _build_archery_grounds() -> void:
	var holder := Node3D.new()
	holder.name = "ArcheryGrounds"
	add_child(holder)

	var center := Vector3(84.0, 0.0, -96.0)

	# Main buildings: Archery range and Barracks
	var range_bldg := _place("buildings/blue/building_archeryrange_blue.gltf", center + Vector3(-7.0, 0.0, 0.0), 0.0, BS * 1.0, holder)
	_add_trimesh_collider(range_bldg)

	var barracks := _place("buildings/blue/building_barracks_blue.gltf", center + Vector3(8.0, 0.0, 2.0), -15.0, BS * 1.05, holder)
	_add_trimesh_collider(barracks)

	# Archery targets
	var targets: Array[Vector3] = [
		center + Vector3(-12.0, 0.0, -14.0),
		center + Vector3(-7.0, 0.0, -14.0),
		center + Vector3(-2.0, 0.0, -14.0),
	]
	for t_pos in targets:
		var target_node := _place("decoration/props/target.gltf", t_pos, 0.0, PS * 1.3, holder)
		_add_box_collider(target_node, 0.8)

	# Weapon racks, arrow buckets, flags
	var props: Array = [
		["decoration/props/bucket_arrows.gltf", center + Vector3(-10.0, 0.0, -4.0), 15.0, 1.2],
		["decoration/props/bucket_arrows.gltf", center + Vector3(-5.0, 0.0, -4.0), -20.0, 1.2],
		["decoration/props/weaponrack.gltf", center + Vector3(1.5, 0.0, -3.0), 90.0, 1.2],
		["decoration/props/weaponrack.gltf", center + Vector3(1.5, 0.0, -1.0), 90.0, 1.2],
		["decoration/props/flag_blue.gltf", center + Vector3(-13.0, 0.0, 4.0), 45.0, 1.4],
		["decoration/props/flag_blue.gltf", center + Vector3(14.0, 0.0, 5.0), -30.0, 1.4],
	]
	for p in props:
		var node := _place(p[0], p[1], p[2], PS * p[3], holder)
		_add_box_collider(node, 0.7)

	# Dimitris the Archer NPC: stands welcoming in the open entrance avenue
	var dimitris := Npc.new()
	dimitris.npc_id = "dimitris"
	dimitris.rest_yaw = deg_to_rad(180.0)
	dimitris.position = center + Vector3(-8.0, 0.0, 12.0)
	var npcs := get_node_or_null("Npcs")
	(npcs if npcs else holder).add_child(dimitris)

	# Signpost
	_signpost("Πεδίο Τοξοβολίας & Στρατώνες  ←\nΕκπαίδευση Φρουράς", center + Vector3(-0.5, 0.0, 7.5), 180.0, holder)

	_occupy(center.x, center.z, 20.0)

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
	for x in [-36.0, -28.0, -20.0, 20.0, 28.0]:
		var f := _place_abs(GRAVE + ("fence_broken.gltf" if absf(x) == 28.0 else "fence.gltf"), Vector3(x, 0, front_z), 0.0, 2.0, holder)
		_add_box_collider(f, 0.9)
	for z in range(int(front_z) - 8, int(CRYPT.y) - 44, -8):
		for x in [-36.0, 28.0]:
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
		_add_cylinder_collider(tree, 0.45, 12.0, Vector3.ZERO)
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
	_build_ash_gate()
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
		var invasion := get_tree().get_first_node_in_group("invasion")
		if invasion != null and invasion.active:       # the village needs its hero tonight
			player.message.emit(Strings.MSG_FRONTIER_INVASION)
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


## The stone arch in the south-eastern mountains that leads to the Ash Valley (story part 4). It stays
## sealed until Παπά-Σταύρος has told George about the Keeper of the Flame ("Η Πύλη της Στάχτης").
## It faces the well, so the village side is the one you walk up to.
func _build_ash_gate() -> void:
	var gate_pos: Vector3 = AshValley.VILLAGE_GATE
	var yaw := atan2(-gate_pos.x, -gate_pos.z)                 # the arch's front (+Z) looks at the well
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var side := Vector3(cos(yaw), 0.0, -sin(yaw))
	var holder := Node3D.new()
	holder.name = "AshGate"
	add_child(holder)
	_place_abs(GRAVE + "arch_gate.gltf", gate_pos, rad_to_deg(yaw), 3.4, holder)
	for dx in [-7.0, 7.0]:
		var at: Vector3 = gate_pos + side * dx + forward * 3.0
		var lamp := _place_abs(GRAVE + "lantern_standing.gltf", at, 0.0, 2.4, holder)
		_add_cylinder_collider(lamp, 0.5, 2.0, Vector3.ZERO)
		var light := OmniLight3D.new()
		light.position = at + Vector3(0, 2.4, 0)
		light.light_color = Color(1.0, 0.62, 0.30)
		light.light_energy = 1.4
		light.omni_range = 11.0
		light.add_to_group("night_lights")
		holder.add_child(light)
	_occupy(gate_pos.x, gate_pos.z, 14.0)
	var front := gate_pos + forward * 3.0
	var enter := func(player: Player):
		if not _ash_open():
			player.message.emit(Strings.MSG_ASH_SEALED)
			return
		var invasion := get_tree().get_first_node_in_group("invasion")
		if invasion != null and invasion.active:       # the village needs its hero tonight
			player.message.emit(Strings.MSG_FRONTIER_INVASION)
			return
		var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
		if interiors:
			interiors.enter_region("ashvalley", front + forward * 2.0, yaw, player)
	var spot := InteractSpot.make(Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["ashvalley"], enter, 4.6)
	spot.prompt_func = func():
		return Strings.PROMPT_ENTER % Strings.BUILDING_NAMES["ashvalley"] if _ash_open() else "[R] " + Strings.ASH_SEALED
	spot.position = front
	add_child(spot)


func _ash_open() -> bool:
	return Quests.state["a_gate"] >= Quests.S.ACTIVE


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
		chest.mimic = c.size() > 7 and bool(c[7])
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


## The Great Tree area in the east: a lake with rock islands, bridges and a giant tree (great_tree.gd).
## The stable yard: an authentic medieval village horse stable with a covered 3-stall timber barn,
## stone-and-timber floor, straw bedding, hay troughs, water buckets, warm hanging lanterns,
## Manolis's tack lodge, clean post-and-rail paddock fences, and the horses (mount, mare, foal).
func _build_stable() -> void:
	var holder := Node3D.new()
	holder.name = "Stable"
	add_child(holder)
	var heading := atan2(-STABLE.x, -STABLE.y)          # the gate looks at the well
	var center := Vector3(STABLE.x, 0.0, STABLE.y)
	var forward := Vector3(sin(heading), 0.0, cos(heading))
	var right := Vector3(-cos(heading), 0.0, sin(heading))
	var rot := rad_to_deg(heading)

	# --- Materials for authentic timber barn ---
	var wood_dark := StandardMaterial3D.new()
	wood_dark.albedo_color = Color(0.28, 0.17, 0.09)     # dark oak pillars & beams
	wood_dark.roughness = 0.85

	var wood_plank := StandardMaterial3D.new()
	wood_plank.albedo_color = Color(0.42, 0.28, 0.15)    # timber plank walls & partitions
	wood_plank.roughness = 0.8

	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.35, 0.18, 0.10)      # medieval cedar shingle roof
	roof_mat.roughness = 0.75

	var straw_mat := StandardMaterial3D.new()
	straw_mat.albedo_color = Color(0.84, 0.70, 0.35)     # golden dry straw bedding
	straw_mat.roughness = 0.95

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.45, 0.44, 0.42)     # foundation stone
	stone_mat.roughness = 0.9

	var fence_mat := StandardMaterial3D.new()
	fence_mat.albedo_color = Color(0.45, 0.30, 0.16)     # paddock rail wood
	fence_mat.roughness = 0.85

	# Helper lambda to create a collidable box in local stable frame
	var make_box := func(local_pos: Vector3, size: Vector3, mat: Material, has_col: bool = true) -> Node3D:
		var pos := center + right * local_pos.x + Vector3(0.0, local_pos.y, 0.0) + forward * local_pos.z
		var node := Node3D.new()
		node.position = pos
		node.rotation_degrees.y = rot
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = mat
		node.add_child(mi)
		if has_col:
			var sb := StaticBody3D.new()
			var col := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = size
			col.shape = bs
			sb.add_child(col)
			node.add_child(sb)
		holder.add_child(node)
		return node

	# 1. MANOLIS'S TACK LODGE & OFFICE (Right Wing)
	# Real medieval cottage for the stable keeper, storing saddles, bridles & veterinary medicine
	var lodge := _place("buildings/yellow/building_home_A_yellow.gltf",
		center + right * 7.8 - forward * 3.2,
		rot - 18.0,
		BS * 0.75,
		holder)
	_add_box_collider(lodge, 1.0)

	# 2. COVERED 3-STALL TIMBER BARN (Rear / Left Wing)
	var b_x := -1.8     # centered on the stalls
	var b_z := -3.8     # set back in the rear of the paddock
	var bw := 11.4      # total width
	var bd := 5.2       # total depth
	var bh := 3.8       # eaves height

	# Foundation / Floor
	make_box.call(Vector3(b_x, 0.1, b_z), Vector3(bw, 0.22, bd), stone_mat)

	# Rear Wall (Solid timber back wall protecting horses from cold winds)
	make_box.call(Vector3(b_x, bh * 0.5, b_z - bd * 0.5 + 0.12), Vector3(bw, bh, 0.25), wood_plank)

	# Left Outer Wall
	make_box.call(Vector3(b_x - bw * 0.5 + 0.12, bh * 0.5, b_z), Vector3(0.25, bh, bd), wood_plank)

	# Right Outer Wall (separating stalls from lodge pathway)
	make_box.call(Vector3(b_x + bw * 0.5 - 0.12, bh * 0.5, b_z), Vector3(0.25, bh, bd), wood_plank)

	# Stall Dividers (waist-high timber partitions between stalls)
	make_box.call(Vector3(b_x - 1.9, 0.85, b_z), Vector3(0.18, 1.5, bd - 0.8), wood_plank)
	make_box.call(Vector3(b_x + 1.9, 0.85, b_z), Vector3(0.18, 1.5, bd - 0.8), wood_plank)

	# Heavy Timber Columns (Front & Back)
	var col_xs: Array[float] = [-bw * 0.5 + 0.18, -1.9, 1.9, bw * 0.5 - 0.18]
	for cx: float in col_xs:
		make_box.call(Vector3(b_x + cx, bh * 0.5, b_z + bd * 0.5 - 0.18), Vector3(0.38, bh, 0.38), wood_dark)
		make_box.call(Vector3(b_x + cx, (bh + 0.6) * 0.5, b_z - bd * 0.5 + 0.18), Vector3(0.38, bh + 0.6, 0.38), wood_dark)

	# Roof Header Beams
	make_box.call(Vector3(b_x, bh - 0.1, b_z + bd * 0.5 - 0.18), Vector3(bw, 0.3, 0.38), wood_dark)
	make_box.call(Vector3(b_x, bh + 0.6 - 0.1, b_z - bd * 0.5 + 0.18), Vector3(bw, 0.3, 0.38), wood_dark)

	# Sloped Gabled Timber Roof with Overhang
	var roof_node := Node3D.new()
	var roof_pos: Vector3 = center + right * b_x + Vector3(0.0, bh + 0.45, 0.0) + forward * b_z
	roof_node.position = roof_pos
	roof_node.rotation_degrees.y = rot
	roof_node.rotation.x = deg_to_rad(-8.5)
	var r_mesh := MeshInstance3D.new()
	var roof_box := BoxMesh.new()
	roof_box.size = Vector3(bw + 1.2, 0.28, bd + 1.4)
	r_mesh.mesh = roof_box
	r_mesh.material_override = roof_mat
	roof_node.add_child(r_mesh)
	holder.add_child(roof_node)

	# Golden Straw Bedding in each stall
	make_box.call(Vector3(b_x - 3.8, 0.22, b_z + 0.2), Vector3(3.2, 0.08, 3.8), straw_mat, false)
	make_box.call(Vector3(b_x, 0.22, b_z + 0.2), Vector3(3.2, 0.08, 3.8), straw_mat, false)
	make_box.call(Vector3(b_x + 3.8, 0.22, b_z + 0.2), Vector3(3.2, 0.08, 3.8), straw_mat, false)

	# Warm Hanging Lanterns under the front eaves of each stall
	var lantern_xs: Array[float] = [-3.8, 0.0, 3.8]
	for lx: float in lantern_xs:
		var l_pos: Vector3 = center + right * (b_x + lx) + Vector3(0.0, bh - 0.25, 0.0) + forward * (b_z + bd * 0.5 - 0.2)
		var lantern := _place("res://assets/graveyard/lantern_hanging.gltf", l_pos, rot, 1.1, holder)
		var omni := OmniLight3D.new()
		omni.light_color = Color(1.0, 0.82, 0.52)
		omni.light_energy = 0.9
		omni.omni_range = 6.5
		omni.position = Vector3(0, -0.4, 0)
		lantern.add_child(omni)

	# 3. THE HORSES IN THEIR STALLS
	# Center Stall: Player's ready-to-mount horse!
	var horse := Horse.new()
	horse.position = center + right * b_x + forward * (b_z + 0.4)
	horse.rotation.y = heading + PI
	holder.add_child(horse)
	horse.stand()

	# Left Stall: Companion chestnut mare
	var mare := Horse.new()
	mare.position = center + right * (b_x - 3.8) + forward * (b_z + 0.4)
	mare.rotation.y = heading + PI - 0.2
	holder.add_child(mare)
	mare.stand()

	# Right Stall: Companion young foal
	var foal := Horse.new()
	foal.position = center + right * (b_x + 3.8) + forward * (b_z + 0.4)
	foal.rotation.y = heading + PI + 0.25
	foal.scale = Vector3.ONE * 0.65
	holder.add_child(foal)
	foal.stand()

	# 4. RUSTIC POST-AND-RAIL PADDOCK FENCE & OPEN GATE
	var pw_half := 7.6
	var p_front := 4.8

	var add_rail_segment := func(p1: Vector2, p2: Vector2) -> void:
		var world_p1 := center + right * p1.x + forward * p1.y
		var world_p2 := center + right * p2.x + forward * p2.y
		var seg_len := world_p1.distance_to(world_p2)
		var seg_dir := (world_p2 - world_p1).normalized()
		var seg_yaw := atan2(seg_dir.x, seg_dir.z)

		var post := Node3D.new()
		post.position = world_p1 + Vector3(0, 0.65, 0)
		var pm := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.11
		cyl.bottom_radius = 0.13
		cyl.height = 1.3
		pm.mesh = cyl
		pm.material_override = fence_mat
		post.add_child(pm)
		var p_col := StaticBody3D.new()
		var p_shape := CollisionShape3D.new()
		var p_cyl := CylinderShape3D.new()
		p_cyl.radius = 0.15
		p_cyl.height = 1.3
		p_shape.shape = p_cyl
		p_col.add_child(p_shape)
		post.add_child(p_col)
		holder.add_child(post)

		for rh in [0.45, 0.95]:
			var rail := Node3D.new()
			rail.position = (world_p1 + world_p2) * 0.5 + Vector3(0, rh, 0)
			rail.rotation.y = seg_yaw
			var rm := MeshInstance3D.new()
			var rail_box := BoxMesh.new()
			rail_box.size = Vector3(0.09, 0.14, seg_len)
			rm.mesh = rail_box
			rm.material_override = fence_mat
			rail.add_child(rm)
			var r_col := StaticBody3D.new()
			var r_shape := CollisionShape3D.new()
			var r_bshape := BoxShape3D.new()
			r_bshape.size = Vector3(0.2, 0.3, seg_len)
			r_shape.shape = r_bshape
			r_col.add_child(r_shape)
			rail.add_child(r_col)
			holder.add_child(rail)

	# Left Fence boundary
	var left_x := b_x - bw * 0.5
	var left_steps := 3
	for i in left_steps:
		var z1 := lerpf(b_z + bd * 0.5, p_front, float(i) / left_steps)
		var z2 := lerpf(b_z + bd * 0.5, p_front, float(i + 1) / left_steps)
		add_rail_segment.call(Vector2(left_x, z1), Vector2(left_x, z2))

	# Right Fence boundary
	var right_x := pw_half
	var right_steps := 3
	for i in right_steps:
		var z1 := lerpf(0.0, p_front, float(i) / right_steps)
		var z2 := lerpf(0.0, p_front, float(i + 1) / right_steps)
		add_rail_segment.call(Vector2(right_x, z1), Vector2(right_x, z2))

	# Front Fence: Left section
	var gate_half := 2.5
	var gate_center_x := 0.0
	var f_left_steps := 2
	for i in f_left_steps:
		var x1 := lerpf(left_x, gate_center_x - gate_half, float(i) / f_left_steps)
		var x2 := lerpf(left_x, gate_center_x - gate_half, float(i + 1) / f_left_steps)
		add_rail_segment.call(Vector2(x1, p_front), Vector2(x2, p_front))

	# Front Fence: Right section
	var f_right_steps := 2
	for i in f_right_steps:
		var x1 := lerpf(gate_center_x + gate_half, right_x, float(i) / f_right_steps)
		var x2 := lerpf(gate_center_x + gate_half, right_x, float(i + 1) / f_right_steps)
		add_rail_segment.call(Vector2(x1, p_front), Vector2(x2, p_front))

	# Grand Entrance Gate Posts
	var gate_xs: Array[float] = [-gate_half, gate_half]
	for gx: float in gate_xs:
		var gp_pos: Vector3 = center + right * (gate_center_x + gx) + forward * p_front
		var gp := _place("res://assets/graveyard/post_lantern.gltf", gp_pos, rot, 1.4, holder)
		_add_box_collider(gp, 0.4)

	# 5. DETAILS, PROPS & FEEDING TROUGHS
	var extras := [
		["decoration/props/sack.gltf", Vector2(b_x - 4.8, b_z - 1.8), 25.0],
		["decoration/props/sack.gltf", Vector2(b_x + 2.2, b_z - 1.8), -35.0],
		["decoration/props/sack.gltf", Vector2(5.2, -1.5), 15.0],
		["decoration/props/sack.gltf", Vector2(5.8, -1.8), 70.0],
		["decoration/props/barrel.gltf", Vector2(6.4, 0.8), 0.0],
		["decoration/props/barrel.gltf", Vector2(5.6, 1.2), 40.0],
		["decoration/props/bucket_water.gltf", Vector2(b_x - 2.4, b_z + 1.4), 20.0],
		["decoration/props/bucket_water.gltf", Vector2(b_x + 1.4, b_z + 1.4), -15.0],
		["decoration/props/bucket_empty.gltf", Vector2(b_x - 5.0, b_z + 1.4), 10.0],
		["decoration/props/wheelbarrow.gltf", Vector2(4.2, 3.2), 115.0],
	]
	for e in extras:
		var v: Vector2 = e[1]
		var pos := center + right * v.x + forward * v.y
		var node := _place(e[0], pos, rot + float(e[2]), PS, holder)
		_add_box_collider(node, 0.8)

	# 6. MANOLIS THE STABLE GROOM
	var keeper := Npc.new()
	keeper.npc_id = "manolis"
	keeper.rest_yaw = heading
	keeper.position = center + forward * (p_front + 1.6) + right * (gate_center_x + gate_half + 0.8)
	var npcs := get_node_or_null("Npcs")
	(npcs if npcs else holder).add_child(keeper)

	_occupy(center.x, center.z, 14.0)


## Village animal life: Mourgos the village dog, farm sheep in their pasture pen, and roadside encounters.
func _build_animals() -> void:
	var holder := Node3D.new()
	holder.name = "Animals"
	add_child(holder)

	# 1. Mourgos the Village Dog
	var dog := VillageDog.new()
	dog.position = Vector3(VillageDog.REST_POS.x, 0.0, VillageDog.REST_POS.y)
	holder.add_child(dog)

	# 2. Sheep pen in the eastern farm meadow near (52.0, -80.0)
	var pen_center := Vector3(52.0, 0.0, -80.0)
	var pen_half := Vector2(5.5, 4.2)
	_build_rustic_paddock(pen_center, pen_half, "-x", 2.8, holder)

	# hay trough in sheep pen
	var trough := _place("decoration/props/sack.gltf", pen_center + Vector3(2.5, 0.0, -2.0), 30.0, PS * 0.9, holder)
	_add_box_collider(trough, 0.5)

	# 3 gentle pasture sheep
	var sheep_offsets := [Vector3(-1.2, 0.0, -0.6), Vector3(1.6, 0.0, -1.2), Vector3(0.5, 0.0, 1.4)]
	for s_pos in sheep_offsets:
		var sheep := VillageSheep.new()
		sheep.position = pen_center + s_pos
		sheep.rotation.y = randf() * TAU
		holder.add_child(sheep)

	_occupy(pen_center.x, pen_center.z, 8.0)

	# 4. Pasture Cows in a spacious lush western meadow paddock near (-18.0, -84.0)
	# Relocated well away from the north road to Vigla ton Aeton, with 3x larger paddock area
	var cow_center := Vector3(-18.0, 0.0, -84.0)
	var cow_half := Vector2(8.5, 6.5)
	_build_rustic_paddock(cow_center, cow_half, "+z", 3.6, holder)

	var feed_sack1 := _place("decoration/props/sack.gltf", cow_center + Vector3(-5.0, 0.0, -3.5), 20.0, PS * 1.2, holder)
	_add_box_collider(feed_sack1, 0.6)
	var feed_sack2 := _place("decoration/props/barrel.gltf", cow_center + Vector3(5.2, 0.0, -3.5), 0.0, PS * 1.1, holder)
	_add_box_collider(feed_sack2, 0.6)

	var cow_script := load("res://scripts/village_cow.gd") as GDScript
	if cow_script:
		var cow1 = cow_script.new()
		cow1.position = cow_center + Vector3(-3.0, 0.0, -0.5)
		cow1.rotation.y = randf() * TAU
		holder.add_child(cow1)

		var cow2 = cow_script.new()
		cow2.position = cow_center + Vector3(2.8, 0.0, 1.0)
		cow2.rotation.y = randf() * TAU
		holder.add_child(cow2)

	_occupy(cow_center.x, cow_center.z, 11.0)

	# 5. Wild Deer roaming the eastern meadows and forest margins
	var deer_script := load("res://scripts/village_deer.gd") as GDScript
	if deer_script:
		var deer_positions: Array[Vector3] = [
			Vector3(132.0, 0.0, -58.0),
			Vector3(124.0, 0.0, -76.0),
			Vector3(138.0, 0.0, -86.0),
		]
		for d_pos in deer_positions:
			var deer = deer_script.new()
			deer.position = d_pos
			deer.scale = Vector3.ONE * 1.25
			deer.rotation.y = randf() * TAU
			holder.add_child(deer)

	# 6. Dynamic Night Roadside Encounters
	var ambush := RoadAmbush.new()
	add_child(ambush)


func _build_rustic_paddock(center: Vector3, half_size: Vector2, gate_side: String, gate_width: float, holder: Node) -> void:
	var fence_mat := StandardMaterial3D.new()
	fence_mat.albedo_color = Color(0.45, 0.30, 0.16)     # rustic paddock timber
	fence_mat.roughness = 0.85

	var hx := half_size.x
	var hz := half_size.y

	# 4 sides defined by start and end relative coordinates, and whether this side has the gate
	var sides := [
		[Vector2(-hx, -hz), Vector2(hx, -hz), gate_side == "-z"],
		[Vector2(hx, -hz), Vector2(hx, hz), gate_side == "+x"],
		[Vector2(hx, hz), Vector2(-hx, hz), gate_side == "+z"],
		[Vector2(-hx, hz), Vector2(-hx, -hz), gate_side == "-x"],
	]

	for s in sides:
		var p1: Vector2 = s[0]
		var p2: Vector2 = s[1]
		var has_gate: bool = s[2]
		var seg_span := p1.distance_to(p2)
		var dir := (p2 - p1).normalized()

		var segments: Array[Array] = []
		if has_gate:
			var mid := seg_span * 0.5
			var gw := minf(gate_width, seg_span * 0.6)
			segments.append([0.0, mid - gw * 0.5])
			segments.append([mid + gw * 0.5, seg_span])
		else:
			segments.append([0.0, seg_span])

		for seg in segments:
			var s0: float = seg[0]
			var s1: float = seg[1]
			var slen: float = s1 - s0
			if slen <= 0.1:
				continue
			var post_count := maxi(2, int(round(slen / 2.5)) + 1)
			for i in post_count:
				var t := s0 + slen * float(i) / float(post_count - 1)
				var pt := p1 + dir * t
				var post_w := center + Vector3(pt.x, 0.65, pt.y)

				var post := Node3D.new()
				post.position = post_w
				var pm := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.11
				cyl.bottom_radius = 0.13
				cyl.height = 1.3
				pm.mesh = cyl
				pm.material_override = fence_mat
				post.add_child(pm)

				var p_col := StaticBody3D.new()
				var p_shape := CollisionShape3D.new()
				var p_cyl := CylinderShape3D.new()
				p_cyl.radius = 0.15
				p_cyl.height = 1.3
				p_shape.shape = p_cyl
				p_col.add_child(p_shape)
				post.add_child(p_col)
				holder.add_child(post)

			var mid_t := (s0 + s1) * 0.5
			var mid_pt := p1 + dir * mid_t
			var mid_w := center + Vector3(mid_pt.x, 0.0, mid_pt.y)
			var yaw := atan2(dir.x, dir.y)

			for rh in [0.45, 0.95]:
				var rail := Node3D.new()
				rail.position = mid_w + Vector3(0.0, rh, 0.0)
				rail.rotation.y = yaw
				var rm := MeshInstance3D.new()
				var r_box := BoxMesh.new()
				r_box.size = Vector3(0.09, 0.14, slen)
				rm.mesh = r_box
				rm.material_override = fence_mat
				rail.add_child(rm)

				var r_col := StaticBody3D.new()
				var r_shape := CollisionShape3D.new()
				var r_bshape := BoxShape3D.new()
				r_bshape.size = Vector3(0.2, 0.3, slen)
				r_shape.shape = r_bshape
				r_col.add_child(r_shape)
				rail.add_child(r_col)
				holder.add_child(rail)


func _build_great_tree() -> void:
	var area := GreatTree.new()
	area.terrain = _terrain
	add_child(area)
	_occupy(GreatTree.CENTER.x, GreatTree.CENTER.y, GreatTree.AREA_RADIUS)


func _signpost(text: String, pos: Vector3, rot_deg: float, parent: Node) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_deg
	parent.add_child(root)

	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.30, 0.17)
	wood.roughness = 0.85

	# The board: Width 6.4m, Height 1.7m, Depth 0.22m, Centered at Y = 3.8m
	# Board bottom is at Y = 3.8 - 0.85 = 2.95m
	var board_y := 3.8
	var board_h := 1.7
	var board_w := 6.4
	var board_d := 0.22
	var board_bottom := board_y - board_h * 0.5   # 2.95m

	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(board_w, board_h, board_d)
	board.mesh = bm
	board.material_override = wood
	board.position = Vector3(0.0, board_y, 0.0)
	root.add_child(board)

	# The post: stops exactly at the bottom of the board (Y = 2.95m)
	var post := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.42, board_bottom, 0.42)
	post.mesh = pm
	post.material_override = wood
	post.position = Vector3(0.0, board_bottom * 0.5, 0.0)
	root.add_child(post)

	# Front Label: double_sided = false prevents reversed ghost letters bleeding through
	var label := Label3D.new()
	label.text = text
	label.font_size = 54
	label.pixel_size = 0.0065
	label.outline_size = 8
	label.outline_modulate = Color(0.12, 0.08, 0.04)
	label.modulate = Color(0.98, 0.92, 0.80)
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector3(0.0, board_y, board_d * 0.5 + 0.02)
	root.add_child(label)

	# Back Label: double_sided = false prevents front view from seeing reverse text
	var back := Label3D.new()
	back.text = text
	back.font_size = 54
	back.pixel_size = 0.0065
	back.outline_size = 8
	back.outline_modulate = Color(0.12, 0.08, 0.04)
	back.modulate = Color(0.98, 0.92, 0.80)
	back.double_sided = false
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.position = Vector3(0.0, board_y, -board_d * 0.5 - 0.02)
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
	var pond := Vector2(-70.0, 65.0)
	_terrain.add_pond(pond, 11.0)
	_occupy(pond.x, pond.y, 17.0)
	var rocks := Node3D.new()
	rocks.name = "PondRocks"
	add_child(rocks)
	for i in 12:
		var a := TAU * float(i) / 12.0 + _rng.randf() * 0.3
		var r := 12.4 + _rng.randf() * 3.0
		var node := _place(ROCKS[_rng.randi() % ROCKS.size()], Vector3(pond.x + cos(a) * r, 0, pond.y + sin(a) * r * 0.72), _rng.randf() * 360.0, ST * _rng.randf_range(0.22, 0.4), rocks)
		if absf(angle_difference(a, deg_to_rad(DOCK_ANGLE))) < 0.45:     # the dock stands here
			node.queue_free()
			continue
		_add_rock_collider(node)
	_build_dock(pond, 11.0)


## A small wooden dock on the shore of the pond with a bucket, and the fishing spot ([R] Ψάρεμα).
## George stands at the water end and casts toward the open water (see fishing.gd).
func _build_dock(pond: Vector2, radius: float) -> void:
	var a := deg_to_rad(DOCK_ANGLE)
	var shore := Vector3(pond.x + cos(a) * radius, 0.0, pond.y + sin(a) * radius * 0.72)
	var inland := Vector3(cos(a), 0.0, sin(a) * 0.72).normalized()     # from the water toward the land
	var dock := Node3D.new()
	dock.name = "Dock"
	dock.position = shore
	dock.rotation.y = atan2(inland.x, inland.z)                        # local +Z points inland
	add_child(dock)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.30, 0.17)
	wood.roughness = 0.9
	for i in 8:
		var plank := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 0.1, 0.9)
		plank.mesh = box
		plank.material_override = wood
		plank.position = Vector3(0.0, 0.12, -3.5 + float(i))
		plank.scale = Vector3.ONE * (0.97 + 0.03 * float(i % 3))
		dock.add_child(plank)
	for z in [-3.5, 0.0, 3.5]:
		for x in [-1.15, 1.15]:
			var pile := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.11
			cyl.bottom_radius = 0.11
			cyl.height = 0.9
			pile.mesh = cyl
			pile.material_override = wood
			pile.position = Vector3(x, 0.30, z)
			dock.add_child(pile)
	_place("decoration/props/bucket_water.gltf", Vector3(1.9, 0.0, 2.6), 30.0, PS, dock)
	var stand := shore - inland * 3.2 + Vector3(0.0, 0.1, 0.0)        # the water end of the planks
	var target := shore - inland * 8.5 + Vector3(0.0, 0.09, 0.0)      # the float lands out on the open water
	var start := func(player: Player):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.start_fishing(player, stand, target)
	var spot := InteractSpot.make(Strings.PROMPT_FISH, start, 5.0)
	spot.position = shore - inland * 1.5
	add_child(spot)
	_occupy(shore.x, shore.z, 6.0)


func _is_in_sea(pos: Vector2) -> bool:
	return pos.y >= 84.5 and pos.x >= -192.0 and pos.x <= 56.0


func _finish_terrain() -> void:
	var blocked := func(p: Vector2) -> bool: return _outside_map(p) or _is_in_sea(p) or _is_occupied(p.x, p.y, 0.7)
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
		if _outside_map(c) or _is_in_sea(c) or _is_occupied(c.x, c.y, 18.0):
			continue
		groves += 1
		for i in _rng.randi_range(10, 22):
			var p := c + Vector2(_rng.randfn(0.0, 14.0), _rng.randfn(0.0, 14.0))
			if _is_in_sea(p):
				continue
			_try_tree(p, holder)
	# Lone trees and rocks
	var singles := 0
	var rocks := 0
	tries = 0
	while (singles < 90 or rocks < 90) and tries < 4000:
		tries += 1
		var p := Vector2(_rng.randf_range(-reach, reach), _rng.randf_range(-reach, reach))
		if _outside_map(p) or _is_in_sea(p):
			continue
		if singles < 90 and _rng.randf() < 0.55:
			if _try_tree(p, holder):
				singles += 1
		elif rocks < 90 and not _is_occupied(p.x, p.y, 2.5) and not _terrain.near_path(p, 3.0):
			var scale := _rng.randf_range(1.0, 2.2) * ST * 0.55
			var node := _place(ROCKS[_rng.randi() % ROCKS.size()], Vector3(p.x, 0, p.y),
					_rng.randf_range(0.0, 360.0), scale, holder)
			_add_rock_collider(node)
			_occupy(p.x, p.y, 3.0)
			rocks += 1


func _try_tree(p: Vector2, holder: Node3D) -> bool:
	if _outside_map(p) or _is_in_sea(p) or _is_occupied(p.x, p.y, 2.8) or _terrain.near_path(p, 3.0):
		return false
	var scale := TS * _rng.randf_range(0.85, 1.3)
	var node := _place(TREES[_rng.randi() % TREES.size()], Vector3(p.x, 0, p.y),
			_rng.randf_range(0.0, 360.0), scale, holder)
	_add_cylinder_collider(node, 0.048 * scale, 8.0, Vector3.ZERO)
	_occupy(p.x, p.y, 2.8)
	return true


func _outside_map(p: Vector2) -> bool:
	var q := roundi(p.x / HEX_W - p.y / ROW_H * 0.5)
	var r := roundi(p.y / ROW_H)
	return _hex_dist(q, r) > radius - 2


func _build_clouds() -> void:
	var holder := Node3D.new()
	holder.name = "Clouds"
	add_child(holder)
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(1.0, 1.0, 1.0)
	cloud_mat.roughness = 0.95
	cloud_mat.emission_enabled = true
	cloud_mat.emission = Color(0.94, 0.96, 1.0)
	cloud_mat.emission_energy_multiplier = 0.35
	for i in 38:
		var model := "decoration/nature/cloud_big.gltf" if i % 3 != 0 else "decoration/nature/cloud_small.gltf"
		var z_pos := _rng.randf_range(-360.0, 640.0)
		var y_pos := _rng.randf_range(42.0, 78.0)
		var s_val := _rng.randf_range(11.0, 22.0)
		var c := _place(model, Vector3(_rng.randf_range(-380.0, 380.0), y_pos, z_pos),
				_rng.randf_range(0, 360), s_val, holder)
		for mi in c.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).set_surface_override_material(0, cloud_mat)
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
	var base := path.get_file().get_basename()
	root.name = base if not parent.has_node(base) else "%s_%d" % [base, parent.get_child_count()]
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


func _relative_transform(child: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var curr: Node = child
	while curr and curr != ancestor and curr is Node3D:
		t = (curr as Node3D).transform * t
		curr = curr.get_parent()
	return t


func _local_aabb(root: Node3D) -> AABB:
	var visual: Node3D = root.get_node_or_null("Visual")
	if not visual:
		return AABB()
	var have := false
	var box := AABB()
	for mi in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		var t := _relative_transform(mesh_inst, visual)
		var a: AABB = t * mesh_inst.get_aabb()
		box = a if not have else box.merge(a)
		have = true
	# convert from the visual's local units to the root's (world-sized) space
	var s := visual.scale
	return AABB(box.position * s, box.size * s)


## Dedicated rock collider with full un-shrunk boundaries and full height protection.
## Prevents the player from penetrating, walking inside, or clipping through stone geometry.
func _add_rock_collider(root: Node3D) -> void:
	var a := _local_aabb(root)
	if a.size == Vector3.ZERO:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var h := maxf(a.size.y, 2.2)
	# 1.02 margin ensures zero penetration along irregular mesh contours
	box.size = Vector3(a.size.x * 1.02, h, a.size.z * 1.02)
	shape.shape = box
	var center := a.get_center()
	shape.position = Vector3(center.x, h * 0.5, center.z)
	body.add_child(shape)
	root.add_child(body)


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
	# The collider is smaller than the model so that George can squeeze between houses; the camera must not follow
	# him into the walls, so a full-size shell that only the spring arm sees keeps it outside the visible house.
	if shrink < 0.99:
		var shell := StaticBody3D.new()
		shell.name = "CameraShell"
		shell.collision_layer = Player.CAMERA_LAYER
		shell.collision_mask = 0
		var shell_shape := CollisionShape3D.new()
		var shell_box := BoxShape3D.new()
		shell_box.size = Vector3(a.size.x, maxf(a.size.y, 0.5), a.size.z)
		shell_shape.shape = shell_box
		shell_shape.position = a.get_center()
		shell.add_child(shell_shape)
		root.add_child(shell)


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


## Adds exact concave polygon colliders for structures with open archways, ruins, and walkthrough openings.
func _add_trimesh_collider(root: Node3D) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		if mesh_inst and mesh_inst.mesh:
			mesh_inst.create_trimesh_collision()


func _build_blacksmith_forge() -> void:
	var forge_script = load("res://scripts/blacksmith_forge.gd")
	if forge_script == null:
		return
	var forge: Node3D = forge_script.new()
	# Blacksmith building is at (-93.5, 29.5) facing (0,0) (rot ~107.5°).
	# Place the outdoor forge station in the open forecourt near Nikitas:
	forge.position = Vector3(-88.5, 0.0, 24.5)
	forge.rotation.y = deg_to_rad(105.0)
	add_child(forge)
	_occupy(-88.5, 24.5, 3.2)


func _build_alchemy_and_flora() -> void:
	var holder := Node3D.new()
	holder.name = "AlchemyAndFlora"
	add_child(holder)

	# 1. Andreas' Alchemy Crafting Bench in Village Square
	# Andreas stands at Vector3(-7.0, 0.05, 9.0) post-rescue; place the bench right beside him
	var bench_script = load("res://scripts/alchemy_bench.gd")
	var bench: Node3D = bench_script.new()
	bench.position = Vector3(-4.8, 0.0, 9.2)
	bench.rotation.y = PI * 0.15
	holder.add_child(bench)
	_occupy(-4.8, 9.2, 2.5)

	# 2. Scattered Wild Flora across Island (Waterlilies, Reeds, Mountain Herbs, Autumn Cones)
	var flora_spots: Array[Dictionary] = [
		# Waterlilies (floating in shallows / lake / sea coast)
		{"type": "waterlily", "pos": Vector3(-30.0, 0.02, 115.0)},
		{"type": "waterlily", "pos": Vector3(-48.0, 0.02, 130.0)},
		{"type": "waterlily", "pos": Vector3(12.0, 0.02, 140.0)},
		{"type": "waterlily", "pos": Vector3(-22.0, 0.02, -18.0)},
		# River Reeds (along banks and streams)
		{"type": "reed", "pos": Vector3(-18.0, 0.05, -15.0)},
		{"type": "reed", "pos": Vector3(-26.0, 0.05, -22.0)},
		{"type": "reed", "pos": Vector3(-15.0, 0.05, 105.0)},
		{"type": "reed", "pos": Vector3(25.0, 0.05, 125.0)},
		# Mountain Herbs (high rocky terrain, ridges, ruins)
		{"type": "mountain_herb", "pos": Vector3(65.0, 4.5, -45.0)},
		{"type": "mountain_herb", "pos": Vector3(-55.0, 6.0, -85.0)},
		{"type": "mountain_herb", "pos": Vector3(85.0, 12.0, 35.0)},
		{"type": "mountain_herb", "pos": Vector3(-38.0, 5.0, -110.0)},
		# Autumn Pine Cones (Golden Grove forest floor)
		{"type": "autumn_cone", "pos": Vector3(45.0, 0.05, 15.0)},
		{"type": "autumn_cone", "pos": Vector3(52.0, 0.05, 28.0)},
		{"type": "autumn_cone", "pos": Vector3(38.0, 0.05, 32.0)},
		{"type": "autumn_cone", "pos": Vector3(60.0, 0.05, 18.0)},
	]

	var flora_script = load("res://scripts/wild_flora_node.gd")
	for spot in flora_spots:
		var fn: Node3D = flora_script.new()
		fn.set("flora_id", spot["type"])
		fn.position = spot["pos"]
		holder.add_child(fn)


func _build_bounty_board() -> void:
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		var mgr := tree.get_first_node_in_group("bounty_manager")
		if mgr == null:
			var mgr_script = load("res://scripts/bounty_manager.gd")
			var new_mgr: Node = mgr_script.new()
			new_mgr.name = "BountyManager"
			tree.root.call_deferred("add_child", new_mgr)

	var board_script = load("res://scripts/bounty_board.gd")
	var board: Node3D = board_script.new()
	board.position = Vector3(-53.5, 0.0, -12.5)
	board.rotation.y = 1.45
	add_child(board)
	_occupy(-53.5, -12.5, 2.5)


func _build_george_cottage() -> void:
	var holder := Node3D.new()
	holder.name = "GeorgeCottageComplex"
	add_child(holder)

	var cottage_pos := Vector3(-28.0, 0.0, -28.0)
	var heading := 2.35
	var forward := Vector3(sin(heading), 0.0, cos(heading))
	var right := Vector3(-cos(heading), 0.0, sin(heading))

	# 1. Main Cottage Building Model
	var bnode := _place("buildings/yellow/building_home_B_yellow.gltf", cottage_pos, rad_to_deg(heading), PS, holder)
	_add_box_collider(bnode, 0.8)
	_occupy(cottage_pos.x, cottage_pos.z, 6.0)

	# 2. Door spot & Interactive Entrance / Purchase
	var door_front := cottage_pos + forward * 5.0
	var door_spot := InteractSpot.make("", func(player: Player):
		if not player.cottage_owned:
			if player.gold >= 500:
				player.gold -= 500
				player.cottage_owned = true
				player.inventory_changed.emit(player.gold, player.potions)
				player.message.emit("Συγχαρητήρια! Απέκτησες & επισκεύασες το Σπίτι σου στον Άγιο Βλάση!")
				Sfx.ui("quest_complete")
				var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
				if interiors != null:
					interiors.enter("george_cottage_0", "george_cottage", door_front, heading, player)
			else:
				player.message.emit("Χρειάζεσαι 500 Χρυσό για την αγορά & επισκευή της καλύβας!")
				Sfx.ui("error")
		else:
			var interiors := get_tree().get_first_node_in_group("interiors") as Interiors
			if interiors != null:
				interiors.enter("george_cottage_0", "george_cottage", door_front, heading, player)
	, 4.5)

	door_spot.prompt_func = func() -> String:
		var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		var p := tree.get_first_node_in_group("player") as Player if tree != null else null
		if p != null and p.cottage_owned:
			return "[R] Είσοδος: Το Σπίτι του Γιώργου"
		return "[R] Αγορά & Επισκευή Καλύβας (500 Χρυσός)"

	door_spot.position = door_front
	holder.add_child(door_spot)

	# 3. Cottage Signpost on path
	var sign_pos := door_front + right * 2.8 + forward * 0.8
	_signpost("Το Σπίτι του Γιώργου  🏡\nΠροσωπική Καλύβα & Κήπος", sign_pos, rad_to_deg(heading) - 20.0, holder)

	# 4. Cottage Herb Garden in the side yard
	var garden_pos := cottage_pos + right * 5.8 + forward * 0.5
	var garden_script = load("res://scripts/cottage_garden.gd")
	var garden_node: Node3D = garden_script.new()
	garden_node.position = garden_pos
	garden_node.rotation.y = heading
	holder.add_child(garden_node)
	_occupy(garden_pos.x, garden_pos.z, 4.0)

	# 5. Welcoming Entrance Lantern Post
	var lp := door_front + right * -2.2
	_place("res://assets/graveyard/post_lantern.gltf", lp, rad_to_deg(heading), 1.2, holder)


func _build_gladiator_arena() -> void:
	var arena_script = load("res://scripts/gladiator_arena.gd")
	var arena: Node3D = arena_script.new()
	arena.name = "GladiatorArena"
	add_child(arena)
	_occupy(122.0, -75.0, 22.0)
