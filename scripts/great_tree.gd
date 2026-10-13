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


# >>> more builders are added below this line
