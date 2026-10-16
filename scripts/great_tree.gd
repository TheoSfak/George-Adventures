class_name GreatTree
extends Node3D
## The Great Tree area in the east of the map: a turquoise lake with a central rock island carrying a giant
## tree, four smaller islands, rope bridges and a stone causeway (all walkable, collision layer 1), umbrella
## trees, a chest, balloons. Added by Village._build_great_tree(). The geometry comes from tree_meshes.gd;
## this node holds the layout and places everything. All coordinates below are LOCAL to CENTER.

const CENTER := Vector2(172.0, -40.0)         # world x, z
const LAKE := Vector2(36.0, 30.0)             # radii of the oval lake (x, z)
const AREA_RADIUS := 44.0                     # nothing is scattered inside this circle (Village._occupy)
const WATER_Y := 0.10
const SHORE_Y := 0.03                         # height of the shore end of the first bridge
const WORLD := "res://assets/world/"

# name -> {pos (x, z), r (radius), top (walkable height), seed}
const ISLANDS := {
	"central": {"pos": Vector2(4.0, 0.0), "r": 11.0, "top": 7.0, "seed": 11},
	"entry": {"pos": Vector2(-24.0, 3.0), "r": 5.0, "top": 3.0, "seed": 12},
	"south": {"pos": Vector2(-10.0, 21.0), "r": 5.0, "top": 5.6, "seed": 13},
	"east": {"pos": Vector2(22.0, 16.0), "r": 5.5, "top": 6.2, "seed": 14},
	"far": {"pos": Vector2(28.0, -4.0), "r": 5.0, "top": 4.0, "seed": 15},
}
## The stone causeway around the central island: an arc from `a0` to `a_top` degrees (0 = +x, 90 = +z) that
## climbs from y0 to y1, then a flat taper (angles a_top to a_end, radius down to `land_r`) that curves onto the
## plateau, so the causeway lands there by itself.
const RAMP := {"center": Vector2(4.0, 0.0), "radius": 16.5, "a0": 180.0, "a_top": 300.0, "a_end": 340.0, "land_r": 8.4,
		"y0": 3.0, "y1": 7.0, "width": 2.6, "steps": 36, "taper": 10}
## Where the plateau bridges leave the rim: beyond the cliff, already at the plateau height.
const RIM_RADIUS := 13.0
const SHORE_START := Vector3(-46.0, SHORE_Y, 2.5)

var terrain: Terrain                          # set by Village before add_child (sand ring, flowers)
var _bridge_count := 0


func _ready() -> void:
	name = "GreatTree"
	position = Vector3(CENTER.x, 0.0, CENTER.y)
	_build_lake()
	for key in ISLANDS:
		_build_island(key)
	for pair in bridge_list():
		_build_bridge(pair[0], pair[1])
	_build_ramp()
	_build_props()
	_build_balloons()
	# >>> the later tasks add their builders here


# ------------------------------------------------------------------- layout ----

## Local (x, y, z) to world.
static func to_world(local: Vector3) -> Vector3:
	return Vector3(CENTER.x + local.x, local.y, CENTER.y + local.z)


## A point on the walkable top of `island`, `inset` of the way from its centre toward `toward` (local x, z).
static func island_point(island: String, toward: Vector2, inset := 0.78) -> Vector3:
	var d: Dictionary = ISLANDS[island]
	var c: Vector2 = d["pos"]
	var p := c + (toward - c).normalized() * float(d["r"]) * inset
	return Vector3(p.x, float(d["top"]), p.y)


## A point on the central plateau at `radius` from its centre, toward `toward` (local x, z).
static func plateau_point(toward: Vector2, radius: float) -> Vector3:
	var d: Dictionary = ISLANDS["central"]
	var c: Vector2 = d["pos"]
	var p := c + (toward - c).normalized() * radius
	return Vector3(p.x, float(d["top"]), p.y)


static func ramp_points() -> Array[Vector3]:
	var c: Vector2 = RAMP["center"]
	var radius := float(RAMP["radius"])
	var out := TreeMeshes.ramp_line(c, radius, float(RAMP["a0"]), float(RAMP["a_top"]), float(RAMP["y0"]), float(RAMP["y1"]), int(RAMP["steps"]))
	var taper := int(RAMP["taper"])
	for i in range(1, taper + 1):
		var t := float(i) / float(taper)
		var ang := deg_to_rad(lerpf(float(RAMP["a_top"]), float(RAMP["a_end"]), t))
		var r := lerpf(radius, float(RAMP["land_r"]), t)
		out.append(Vector3(c.x + cos(ang) * r, float(RAMP["y1"]), c.y + sin(ang) * r))
	return out


## The eight bridges as [from, to] in local coordinates: 0 shore to entry island, 1 entry island to the foot of
## the causeway, 2 south island to the rim of the plateau (sloped), 3 that rim point on to the plateau (flat),
## 4 east island to the rim, 5 that rim point on to the plateau (flat), 6 entry to south island, 7 east to far.
## The causeway lands on the plateau by itself (see RAMP).
static func bridge_list() -> Array:
	var ramp := ramp_points()
	var foot: Vector3 = ramp[0]
	var entry_pos: Vector2 = ISLANDS["entry"]["pos"]
	var south_pos: Vector2 = ISLANDS["south"]["pos"]
	var east_pos: Vector2 = ISLANDS["east"]["pos"]
	var far_pos: Vector2 = ISLANDS["far"]["pos"]
	var south_rim := plateau_point(south_pos, RIM_RADIUS)
	var south_landing := plateau_point(south_pos, 8.4)
	var east_rim := plateau_point(east_pos, RIM_RADIUS)
	var east_landing := plateau_point(east_pos, 8.4)
	return [
		[SHORE_START, island_point("entry", Vector2(SHORE_START.x, SHORE_START.z))],
		[island_point("entry", Vector2(foot.x, foot.z)), foot],
		[island_point("south", Vector2(south_rim.x, south_rim.z)), south_rim],
		[south_rim, south_landing],
		[island_point("east", Vector2(east_rim.x, east_rim.z)), east_rim],
		[east_rim, east_landing],
		[island_point("entry", south_pos), island_point("south", entry_pos)],
		[island_point("east", far_pos), island_point("far", east_pos)],
	]


## Waypoints (local) of a walk from dry ground west of the lake to the plateau by the causeway.
static func walk_main() -> Array[Vector3]:
	var bl := bridge_list()
	var ramp := ramp_points()
	var out: Array[Vector3] = [Vector3(SHORE_START.x - 5.0, 0.0, SHORE_START.z)]
	out.append(bl[0][0])
	out.append(bl[0][1])
	out.append(bl[1][0])
	out.append(bl[1][1])
	for i in range(4, ramp.size(), 4):
		out.append(ramp[i])
	out.append(ramp[ramp.size() - 1])
	out.append(Vector3(8.0, 7.0, 4.0))
	return out


## ... to the plateau by the south island.
static func walk_south() -> Array[Vector3]:
	var bl := bridge_list()
	var out: Array[Vector3] = [Vector3(SHORE_START.x - 5.0, 0.0, SHORE_START.z)]
	out.append(bl[0][0])
	out.append(bl[0][1])
	out.append(bl[6][0])
	out.append(bl[6][1])
	out.append(bl[2][0])
	out.append(bl[2][1])
	out.append(bl[3][1])
	out.append(Vector3(8.0, 7.0, 4.0))
	return out


## ... and on over the east island to the far island.
static func walk_far() -> Array[Vector3]:
	var bl := bridge_list()
	var out := walk_south()
	out.append(bl[5][0])
	out.append(bl[4][0])
	out.append(bl[7][0])
	out.append(bl[7][1])
	var far_pos: Vector2 = ISLANDS["far"]["pos"]
	out.append(Vector3(far_pos.x, float(ISLANDS["far"]["top"]), far_pos.y))
	return out


# ----------------------------------------------------------------- builders ----

func _add_visual(mesh: Mesh, label: String, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = mesh
	mi.material_override = TreeMeshes.material()
	mi.position = pos
	add_child(mi)
	return mi


## A static trimesh collider (layer 1) made from `mesh`.
func _add_collider(mesh: Mesh, label: String, pos := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label + "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var shape := CollisionShape3D.new()
	var concave := mesh.create_trimesh_shape()
	concave.backface_collision = true
	shape.shape = concave
	body.add_child(shape)
	add_child(body)
	return body


func _build_lake() -> void:
	var water := MeshInstance3D.new()
	water.name = "Lake"
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.05
	cm.radial_segments = 64
	water.mesh = cm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader") as Shader
	mat.set_shader_parameter("deep_color", Color(0.05, 0.45, 0.55))
	mat.set_shader_parameter("shallow_color", Color(0.20, 0.80, 0.75))
	water.material_override = mat
	water.position = Vector3(0.0, WATER_Y, 0.0)
	water.scale = Vector3(LAKE.x, 1.0, LAKE.y)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)

	# Floating waterlilies around the edges of the Great Tree lake
	var lake_lilies: Array[Vector3] = [
		Vector3(-22.0, WATER_Y + 0.01, -18.0),
		Vector3(-14.0, WATER_Y + 0.01, -22.0),
		Vector3(12.0, WATER_Y + 0.01, -20.0),
		Vector3(26.0, WATER_Y + 0.01, -14.0),
		Vector3(-28.0, WATER_Y + 0.01, 16.0),
		Vector3(8.0, WATER_Y + 0.01, 24.0),
		Vector3(25.0, WATER_Y + 0.01, 10.0),
	]
	var lily_res_a := load("res://assets/world/decoration/nature/waterlily_A.gltf") as PackedScene
	var lily_res_b := load("res://assets/world/decoration/nature/waterlily_B.gltf") as PackedScene
	for i in lake_lilies.size():
		var res: PackedScene = lily_res_a if i % 2 == 0 else lily_res_b
		if res:
			var inst := res.instantiate() as Node3D
			inst.position = lake_lilies[i]
			inst.rotation_degrees.y = float(i * 53)
			inst.scale = Vector3.ONE * 1.5
			add_child(inst)

	if terrain != null:
		terrain.add_patch(CENTER, 40.0, Color(0.74, 0.66, 0.45), false, Color(0.55, 0.48, 0.32))


func _build_island(key: String) -> void:
	var d: Dictionary = ISLANDS[key]
	var pos: Vector2 = d["pos"]
	var mesh := TreeMeshes.island(float(d["r"]), float(d["top"]), int(d["seed"]))
	var at := Vector3(pos.x, 0.0, pos.y)
	_add_visual(mesh, "Island_" + key, at)
	_add_collider(mesh, "Island_" + key, at)


func _build_bridge(a: Vector3, b: Vector3) -> void:
	var label := "Bridge_%d" % _bridge_count
	_bridge_count += 1
	_add_visual(TreeMeshes.bridge(a, b), label)
	_add_collider(TreeMeshes.bridge_collision(a, b), label)


## The stone causeway with its pillars.
func _build_ramp() -> void:
	var line := ramp_points()
	var width := float(RAMP["width"])
	_add_visual(TreeMeshes.ramp(line, width), "Ramp")
	_add_collider(TreeMeshes.ramp_collision(line, width), "Ramp")
	var centre: Vector2 = RAMP["center"]
	for i in range(6, int(RAMP["steps"]) - 1, 8):
		var p: Vector3 = line[i]
		if Vector2(p.x - centre.x, p.z - centre.y).length() < 14.5:      # over the island: no pillar
			continue
		var top_y := p.y - 0.4
		_add_visual(TreeMeshes.pillar(top_y, 100 + i), "Pillar_%d" % i, Vector3(p.x, 0.0, p.z))
		var body := StaticBody3D.new()
		body.name = "Pillar_%dBody" % i
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.9
		cyl.height = top_y + 1.6
		shape.shape = cyl
		body.position = Vector3(p.x, (top_y - 1.6) * 0.5, p.z)
		body.add_child(shape)
		add_child(body)


# ------------------------------------------------------------ tree and props ----

const TREE_POS := Vector3(4.0, 7.0, -1.0)         # the foot of the great tree on the plateau
const TREE_FOOT := Vector3(9.5, 7.0, 3.0)         # a spot on the plateau a few metres from the trunk
const CHEST_POS := Vector3(-8.2, 5.6, 22.5)       # on the south island
const BENCH_POS := Vector3(23.5, 6.2, 17.6)       # on the east island
const HOUSE_SCALE := 5.0
const HOUSES := [
	["buildings/blue/building_home_A_blue.gltf", Vector3(-3.5, 7.0, -4.5)],
	["buildings/yellow/building_home_B_yellow.gltf", Vector3(4.5, 7.0, -9.0)],
]
# [island, offset on the island (x, z), trunk height, canopy radius]
const UMBRELLAS := [
	["south", Vector2(-1.5, 0.8), 5.5, 3.6], ["south", Vector2(1.8, -1.6), 4.2, 2.8],
	["east", Vector2(-1.4, -0.6), 5.0, 3.3],
	["far", Vector2(0.8, 1.2), 5.8, 3.9], ["far", Vector2(-1.8, -0.8), 4.0, 2.6],
	["entry", Vector2(-1.2, -1.4), 3.6, 2.4],
]
const ROCK_SCALE := 3.2
const TREE_SCALE := 9.5
const ROCKS := [
	"decoration/nature/rock_single_A.gltf", "decoration/nature/rock_single_B.gltf", "decoration/nature/rock_single_C.gltf",
	"decoration/nature/rock_single_D.gltf", "decoration/nature/rock_single_E.gltf",
]
const SHORE_TREES := ["decoration/nature/tree_single_A.gltf", "decoration/nature/tree_single_B.gltf"]


func _build_props() -> void:
	_build_tree()
	_build_houses()
	_build_deck_and_lanterns()
	_build_umbrella_trees()
	_build_chest_and_bench()
	_build_flowers_and_pads()
	_build_shore()


func _build_tree() -> void:
	_add_visual(TreeMeshes.great_tree(21), "Tree", TREE_POS)
	var body := StaticBody3D.new()
	body.name = "TreeTrunk"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = TREE_POS
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 3.4
	cyl.height = 14.0
	shape.shape = cyl
	shape.position = Vector3(0.0, 7.0, 0.0)
	body.add_child(shape)
	add_child(body)


func _relative_transform(child: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var curr: Node = child
	while curr and curr != ancestor and curr is Node3D:
		t = (curr as Node3D).transform * t
		curr = curr.get_parent()
	return t


func _local_node_aabb(node: Node3D) -> AABB:
	var have := false
	var box := AABB()
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		var t := _relative_transform(mesh_inst, node)
		var a: AABB = t * mesh_inst.get_aabb()
		box = a if not have else box.merge(a)
		have = true
	return box


## One box collider around a model (its meshes, in the local space of `node`).
func _box_collider_for(node: Node3D, shrink := 0.9) -> void:
	var box := _local_node_aabb(node)
	if box.size == Vector3.ZERO:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(box.size.x * shrink, maxf(box.size.y, 0.5), box.size.z * shrink)
	shape.shape = bs
	shape.position = box.get_center()
	body.add_child(shape)
	node.add_child(body)


## Dedicated rock collider with full un-shrunk boundaries and full height protection.
## Prevents the player from entering inside rock models on the shore and surrounding areas.
func _add_rock_collider(node: Node3D) -> void:
	var box := _local_node_aabb(node)
	if box.size == Vector3.ZERO:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	var h := maxf(box.size.y, 2.2)
	bs.size = Vector3(box.size.x * 1.02, h, box.size.z * 1.02)
	shape.shape = bs
	var center := box.get_center()
	shape.position = Vector3(center.x, h * 0.5, center.z)
	body.add_child(shape)
	node.add_child(body)


## A KayKit model placed at `pos` (local) with appropriate collider.
func _place_model(path: String, pos: Vector3, rot_deg: float, model_scale: float, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	var base := path.get_file().get_basename()
	root.name = base if not parent.has_node(base) else "%s_%d" % [base, parent.get_child_count()]
	root.position = pos
	root.rotation_degrees.y = rot_deg
	var model := (load(WORLD + path) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * model_scale
	root.add_child(model)
	parent.add_child(root)
	if path.contains("rock") or path.contains("stone"):
		_add_rock_collider(root)
	else:
		_box_collider_for(root, 0.8)
	return root


func _build_houses() -> void:
	for i in HOUSES.size():
		var h: Array = HOUSES[i]
		var pos: Vector3 = h[1]
		var d: Vector3 = TREE_POS - pos
		var house := _place_model(h[0], pos, rad_to_deg(atan2(d.x, d.z)), HOUSE_SCALE, self)
		house.name = "House_%d" % i
		var light := OmniLight3D.new()
		light.name = "HouseLight_%d" % i
		light.light_color = Color(1.0, 0.72, 0.4)
		light.light_energy = 1.4
		light.omni_range = 12.0
		light.position = pos + Vector3(0.0, 3.5, 0.0) + d.normalized() * 3.5
		light.add_to_group("night_lights")
		add_child(light)


func _build_deck_and_lanterns() -> void:
	_add_visual(TreeMeshes.deck_ring(5.4, 7.6, 28), "DeckRing", TREE_POS + Vector3(0.0, 0.03, 0.0))
	var pts: Array[Vector3] = []
	for a in [20.0, 90.0, 160.0, 240.0, 305.0]:
		var ang := deg_to_rad(a)
		pts.append(Vector3(TREE_POS.x + cos(ang) * 8.4, TREE_POS.y, TREE_POS.z + sin(ang) * 8.4))
	for key in ["entry", "south", "east", "far"]:
		var d: Dictionary = ISLANDS[key]
		var ip: Vector2 = d["pos"]
		pts.append(Vector3(ip.x + 1.6, float(d["top"]), ip.y - 1.6))
	_add_visual(TreeMeshes.lanterns_posts(pts), "LanternPosts")
	var heads := _add_visual(TreeMeshes.lanterns_heads(pts), "LanternHeads")
	var glow := StandardMaterial3D.new()
	glow.vertex_color_use_as_albedo = true
	glow.vertex_color_is_srgb = true
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.75, 0.35)
	glow.emission_energy_multiplier = 1.2
	heads.material_override = glow
	var deck_light := OmniLight3D.new()                    # the third light: over the deck, lighting the trunk
	deck_light.name = "DeckLight"
	deck_light.light_color = Color(1.0, 0.76, 0.45)
	deck_light.light_energy = 1.4
	deck_light.omni_range = 13.0
	deck_light.position = TREE_POS + Vector3(0.0, 4.5, 0.0)
	deck_light.add_to_group("night_lights")
	add_child(deck_light)


func _build_umbrella_trees() -> void:
	for i in UMBRELLAS.size():
		var u: Array = UMBRELLAS[i]
		var d: Dictionary = ISLANDS[u[0]]
		var ip: Vector2 = d["pos"]
		var off: Vector2 = u[1]
		var pos := Vector3(ip.x + off.x, float(d["top"]), ip.y + off.y)
		_add_visual(TreeMeshes.umbrella_tree(float(u[2]), float(u[3]), 40 + i), "Umbrella_%d" % i, pos)
		var body := StaticBody3D.new()
		body.name = "Umbrella_%dBody" % i
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = pos + Vector3(0.0, float(u[2]) * 0.5, 0.0)
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.4
		cyl.height = float(u[2])
		shape.shape = cyl
		body.add_child(shape)
		add_child(body)


func _build_chest_and_bench() -> void:
	var chest := Chest.new()
	chest.position = CHEST_POS
	chest.rotation_degrees.y = 200.0
	chest.golden = true
	chest.gold_min = 40
	chest.gold_max = 80
	chest.potions = 2
	add_child(chest)
	_add_visual(TreeMeshes.bench(), "Bench", BENCH_POS)
	var body := StaticBody3D.new()
	body.name = "BenchBody"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = BENCH_POS + Vector3(0.0, 0.45, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 0.9, 0.6)
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _build_flowers_and_pads() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for key in ISLANDS:
		var d: Dictionary = ISLANDS[key]
		var ip: Vector2 = d["pos"]
		var r := float(d["r"])
		var pts: Array[Vector3] = []
		for i in (26 if key == "central" else 14):
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * r * 0.7
			pts.append(Vector3(ip.x + cos(a) * rr, float(d["top"]), ip.y + sin(a) * rr))
		_add_visual(TreeMeshes.flowers(pts, int(d["seed"]) + 100), "Flowers_" + key)
	var pads: Array[Vector3] = []
	for i in 40:
		if pads.size() >= 16:
			break
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * 0.88
		var p := Vector3(cos(a) * LAKE.x * rr, WATER_Y + 0.03, sin(a) * LAKE.y * rr)
		var on_island := false
		for key in ISLANDS:
			var d: Dictionary = ISLANDS[key]
			var ip: Vector2 = d["pos"]
			if Vector2(p.x - ip.x, p.z - ip.y).length() < float(d["r"]) * 1.2 + 1.5:
				on_island = true
		if not on_island:
			pads.append(p)
	_add_visual(TreeMeshes.lily_pads(pads, 5), "LilyPads")


## Rocks and a few trees around the shore (the side toward the village stays open) and flowers on the ground.
func _build_shore() -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 12:
		var a := TAU * float(i) / 12.0 + rng.randf_range(-0.15, 0.15)
		if absf(angle_difference(a, PI)) < 0.45:
			continue
		var f := rng.randf_range(1.08, 1.2)
		_place_model(ROCKS[rng.randi() % ROCKS.size()], Vector3(cos(a) * LAKE.x * f, 0.0, sin(a) * LAKE.y * f),
				rng.randf() * 360.0, ROCK_SCALE * rng.randf_range(0.7, 1.2), holder)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0 + rng.randf_range(-0.1, 0.1)
		if absf(angle_difference(a, PI)) < 0.5:
			continue
		var f := rng.randf_range(1.22, 1.32)
		_place_model(SHORE_TREES[rng.randi() % SHORE_TREES.size()], Vector3(cos(a) * LAKE.x * f, 0.0, sin(a) * LAKE.y * f),
				rng.randf() * 360.0, TREE_SCALE * rng.randf_range(0.8, 1.1), holder)
	if terrain != null:
		terrain.add_flower_ring(CENTER, 38.0, 43.0, 70)


# ------------------------------------------------------------------ balloons ----

# [stripe colours, ellipse radii (x, z), height, angular speed, start angle, seed]
const BALLOONS := [
	[[Color(1.0, 0.55, 0.18), Color(0.98, 0.90, 0.72)], Vector2(40.0, 34.0), 30.0, 0.024, 0.0, 1],
	[[Color(0.82, 0.24, 0.34), Color(0.98, 0.92, 0.75)], Vector2(46.0, 38.0), 38.0, -0.018, 1.7, 2],
	[[Color(0.26, 0.60, 0.80), Color(0.98, 0.92, 0.75)], Vector2(36.0, 31.0), 42.0, 0.030, 3.3, 3],
	[[Color(0.96, 0.80, 0.22), Color(0.88, 0.34, 0.20)], Vector2(50.0, 40.0), 33.0, -0.022, 4.9, 4],
]


func _build_balloons() -> void:
	for i in BALLOONS.size():
		var b: Array = BALLOONS[i]
		var balloon := Balloon.new()
		balloon.name = "Balloon_%d" % i
		balloon.setup(b[0], int(b[5]))
		balloon.center = Vector3(0.0, float(b[2]), 0.0)
		balloon.radii = b[1]
		balloon.angle = float(b[4])
		balloon.angular_speed = float(b[3])
		add_child(balloon)
	var moored := Balloon.new()
	moored.name = "Balloon_moored"
	moored.moored = true
	moored.setup([Color(0.30, 0.62, 0.85), Color(0.98, 0.92, 0.75)], 9)
	moored.position = Vector3(-24.0, float(ISLANDS["entry"]["top"]), -1.2)
	moored.rotation.y = 0.6
	add_child(moored)


# >>> more builders are added below this line
