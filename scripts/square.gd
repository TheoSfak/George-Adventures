class_name VillageSquare
extends Node3D
## The heart of Agios Vlasis: the village square around the well. Built by village.gd after the
## houses. Everything is placed on rings around the well at (0, 0): inlaid paving, a low kerb with
## gaps around the flower bed, benches and lamp posts joined by festive bunting, four market stalls
## with vendors, the statue of the Saint, a notice board, a small stage and two old trees.
## Angles are in degrees, 0 = east (+X), 90 = south (+Z), 270 = north (the church).
## The angles were chosen in the gaps between the cobbled spokes that lead to the houses.

const GRAVE := "res://assets/graveyard/"
const ITEMS := "res://assets/items/"
const NATURE := "res://assets/world/decoration/nature/"
const PROPS := "res://assets/world/decoration/props/"
const NEUTRAL := "res://assets/world/buildings/neutral/"
const FURN := "res://assets/furniture/"
const CHAR := "res://assets/characters/"

const KERB_RADIUS := 8.9
const BENCH_RADIUS := 10.4
const LAMP_RADIUS := 12.2
const RING_Y := 0.07                      # the cobbled patch lies at 0.04

# [angle, radius, awning colour, goods kind, sign, vendor name, vendor model, lines the vendor calls out]
const STALLS := [
	[249.7, 14.5, Color(0.25, 0.62, 0.30), "veg", "Λαχανικά", "Κυρά-Βούλα", "Rogue_Hooded",
		["Φρέσκα λαχανικά από τον κήπο μου!", "Ντομάτες, αγγούρια, κρεμμύδια!", "Φέτος έγιναν τεράστιες οι ντομάτες!"]],
	[290.0, 14.5, Color(0.90, 0.72, 0.20), "bread", "Ψωμί & Αλεύρι", "Μπάρμπα-Θόδωρος", "Barbarian",
		["Ζεστό ψωμί, ζεστό ψωμί!", "Αλεύρι από τον μύλο του Στέλιου!", "Φρέσκο ψωμί για τους γενναίους!"]],
	[334.7, 14.5, Color(0.28, 0.45, 0.85), "potion", "Βότανα & Φίλτρα", "Αδελφή Αρετή", "Mage",
		["Βότανα και φίλτρα από το βουνό!", "Ένα φίλτρο την ημέρα, τον θάνατο τον κρατά μακριά!", "Τα καλύτερα βότανα του Άγιου Βλάση!"]],
	[5.7, 14.5, Color(0.80, 0.22, 0.22), "wine", "Κρασί & Μπύρα", "Σήφης ο Κρασάς", "Knight",
		["Κρασί από τον κάμπο, όσο θέλετε!", "Γευτείτε το κρασί του Αγίου!", "Η Κυρά-Μαρία αγοράζει τα βαρέλια μου!"]],
]

var _stone: StandardMaterial3D
var _stone_light: StandardMaterial3D
var _wood: StandardMaterial3D
var _wood_dark: StandardMaterial3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "Square"
	_rng.seed = 3170
	_stone = _material(Color(0.62, 0.60, 0.56), 0.9)
	_stone_light = _material(Color(0.78, 0.76, 0.70), 0.85)
	_wood = _material(Color(0.52, 0.34, 0.18), 0.85)
	_wood_dark = _material(Color(0.34, 0.22, 0.12), 0.9)
	_build_paving()
	_build_well_plinth()
	_build_kerb()
	_build_benches_and_lamps()
	for s in STALLS:
		_build_stall(s)
	_build_statue(55.0, 15.5)
	_build_notice_board(176.0, 15.0)
	_build_stage(125.0, 17.8)
	_build_tree(218.8, 17.5)


# ------------------------------------------------------------------ helpers ----

func _material(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


## Point on a ring around the well: angle in degrees (0 = east, 90 = south).
static func ring_point(angle_deg: float, radius: float) -> Vector3:
	var a := deg_to_rad(angle_deg)
	return Vector3(cos(a) * radius, 0.0, sin(a) * radius)


## Yaw (radians) that makes a model's local +Z point at the well from the given position.
static func facing_well(pos: Vector3) -> float:
	return atan2(-pos.x, -pos.z)


func _model(path: String, pos: Vector3, yaw: float, scale_: float, parent: Node, solid: bool = false) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	var visual := (load(path) as PackedScene).instantiate() as Node3D
	visual.scale = Vector3.ONE * scale_
	holder.add_child(visual)
	parent.add_child(holder)
	if solid:
		Interiors.collider_for(visual)
	return holder


func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material, solid: bool = false, yaw: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = yaw
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		body.add_child(shape)
		mi.add_child(body)
	return mi


func _cylinder(parent: Node, pos: Vector3, radius: float, height: float, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos + Vector3(0, height / 2.0, 0)
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = radius
		cs.height = height
		shape.shape = cs
		body.add_child(shape)
		mi.add_child(body)
	return mi


func _light(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.add_to_group("night_lights")
	add_child(light)


func _label(parent: Node, text: String, pos: Vector3, size: int, color: Color, yaw: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.0085
	l.outline_size = 10
	l.modulate = color
	l.position = pos
	l.rotation.y = yaw
	parent.add_child(l)
	return l


# ------------------------------------------------------------------- paving ----

## Flat rings of darker and lighter stone inlaid in the cobbles.
func _build_paving() -> void:
	var dark := Color(0.52, 0.47, 0.40)
	var light := Color(0.86, 0.82, 0.70)
	_ring(2.4, 2.9, dark)
	_ring(3.0, 3.2, light)
	_ring(9.6, 10.0, light)
	_ring(10.0, 10.9, dark)
	_ring(13.2, 13.5, light)
	_ring(17.2, 17.8, dark)
	_ring(17.8, 18.0, light)
	# a sun of eight rays between the kerb and the lamp ring
	for i in 8:
		var a := deg_to_rad(45.0 * i)
		var dir := Vector3(cos(a), 0, sin(a))
		var holder := Node3D.new()
		holder.position = dir * 12.2 + Vector3(0, RING_Y + 0.003, 0)
		holder.rotation.y = atan2(-dir.z, dir.x)
		var ray := _box(holder, Vector3.ZERO, Vector3(3.6, 0.01, 0.45), _material(dark, 1.0))
		ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(holder)


func _ring(r_in: float, r_out: float, color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var n := 96
	for i in n:
		var a0 := TAU * float(i) / n
		var a1 := TAU * float(i + 1) / n
		var p0 := Vector3(cos(a0) * r_in, 0, sin(a0) * r_in)
		var p1 := Vector3(cos(a0) * r_out, 0, sin(a0) * r_out)
		var p2 := Vector3(cos(a1) * r_out, 0, sin(a1) * r_out)
		var p3 := Vector3(cos(a1) * r_in, 0, sin(a1) * r_in)
		for v in [p0, p1, p2, p0, p2, p3]:
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := _material(color, 1.0)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position = Vector3(0, RING_Y, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Two low round steps under the well.
func _build_well_plinth() -> void:
	_cylinder(self, Vector3.ZERO, 3.9, 0.12, _stone_light)
	_cylinder(self, Vector3.ZERO, 3.3, 0.22, _stone)


## A low stone kerb around the flower bed: eight pieces with a gap between each (the paths to the well).
func _build_kerb() -> void:
	for k in 8:
		var centre := 22.5 + 45.0 * k
		for off in [-5.2, 5.2]:
			var a := deg_to_rad(centre + off)
			var pos := Vector3(cos(a), 0, sin(a)) * KERB_RADIUS
			var tangent := Vector3(-sin(a), 0, cos(a))
			var piece := _box(self, pos + Vector3(0, 0.22, 0), Vector3(1.75, 0.44, 0.5), _stone, true, atan2(-tangent.z, tangent.x))
			piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


# ---------------------------------------------------- benches, lamps, bunting ----

func _build_benches_and_lamps() -> void:
	var tops: Array[Vector3] = []
	for k in 8:
		var angle := 22.5 + 45.0 * k
		var bpos := ring_point(angle, BENCH_RADIUS)
		_model(GRAVE + "bench.gltf", bpos, facing_well(bpos), 1.6, self, true)
		# the lamp posts stand behind the benches: an iron pole with a lantern on top
		var lpos := ring_point(angle, LAMP_RADIUS)
		var iron := _material(Color(0.16, 0.15, 0.15), 0.7)
		_cylinder(self, lpos, 0.38, 0.5, _stone, true)
		_cylinder(self, lpos, 0.11, 3.7, iron)
		_model(GRAVE + "lantern_standing.gltf", lpos + Vector3(0, 3.7, 0), 0.0, 1.5, self)
		if k % 2 == 0:                      # a light on every second post keeps the frame rate up
			_light(lpos + Vector3(0, 4.4, 0), Color(1.0, 0.72, 0.38), 2.2, 17.0)
		tops.append(lpos + Vector3(0, 4.9, 0))
	# bunting: a string of little pennants between neighbouring lamp posts
	var colors := [Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.25, 0.5, 0.9), Color(0.3, 0.7, 0.35), Color(0.95, 0.95, 0.9)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 8:
		var a: Vector3 = tops[k]
		var b: Vector3 = tops[(k + 1) % 8]
		var flags := 11
		var prev := a
		for i in range(1, flags + 2):
			var t := float(i) / (flags + 1)
			var p := a.lerp(b, t)
			p.y -= sin(t * PI) * 0.9              # the string sags in the middle
			_cord(st, prev, p)
			if i <= flags:
				_pennant(st, prev.lerp(p, 0.5), (b - a).normalized(), colors[(k * 3 + i) % colors.size()])
			prev = p
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## A thin dark string between two points, as two crossing ribbons added to the shared bunting mesh.
func _cord(st: SurfaceTool, from: Vector3, to: Vector3) -> void:
	var along := (to - from).normalized()
	var side := along.cross(Vector3.UP).normalized() * 0.03
	var up := Vector3.UP * 0.03
	st.set_color(Color(0.22, 0.17, 0.12))
	for off in [side, up]:
		st.set_normal(off.normalized().cross(along).normalized())
		for v in [from - off, from + off, to + off, from - off, to + off, to - off]:
			st.add_vertex(v)


## One triangular flag hanging from the string at `at` (the string runs along `along`).
func _pennant(st: SurfaceTool, at: Vector3, along: Vector3, color: Color) -> void:
	var half := along * 0.32
	var tip := at + Vector3(0, -0.75, 0)
	st.set_color(color)
	st.set_normal(Vector3.UP.cross(along).normalized())
	st.add_vertex(at - half)
	st.add_vertex(at + half)
	st.add_vertex(tip)


# ------------------------------------------------------------------- stalls ----

func _build_stall(def: Array) -> void:
	var pos := ring_point(def[0], def[1])
	var yaw := facing_well(pos)
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var awning: Color = def[2]
	# counter
	var counter := (load(FURN + "table_medium_long.gltf") as PackedScene).instantiate() as Node3D
	counter.position = Vector3(0, 0, 0.7)
	root.add_child(counter)
	Interiors.collider_for(counter)
	# posts, back cloth, awning
	for x in [-1.9, 1.9]:
		for z in [-1.4, 2.2]:
			_box(root, Vector3(x, 1.35 if z < 0 else 1.2, z), Vector3(0.14, 2.7 if z < 0 else 2.4, 0.14), _wood_dark)
	_box(root, Vector3(0, 2.1, -1.45), Vector3(3.8, 1.0, 0.06), _material(awning.darkened(0.25), 1.0))   # a short back cloth: the stall stays open from behind
	var roof := _box(root, Vector3(0, 2.62, 0.4), Vector3(4.3, 0.1, 4.0), _striped_material(awning), false)
	roof.rotation.x = deg_to_rad(8.0)           # the front edge hangs lower
	_box(root, Vector3(0, 2.22, 2.38), Vector3(4.0, 0.3, 0.04), _striped_material(awning))   # striped valance along the front
	_label(root, def[4], Vector3(0, 3.15, 1.4), 54, Color(0.98, 0.92, 0.78), 0.0).rotation.x = deg_to_rad(-12.0)
	_stall_goods(root, def[3])
	# the vendor behind the counter
	var v := Villager.new()
	v.mode = Villager.Mode.STAND
	v.model_path = CHAR + def[6] + ".glb"
	v.display_name = def[5]
	v.rest_yaw = yaw
	v.bubble_lines = def[7]
	v.talk_lines = VillagerData.vendor_talk(def[5])
	v.add_to_group("villagers")                  # they go home at dusk like everyone else
	v.position = pos + Vector3(sin(yaw), 0, cos(yaw)) * -1.0 + Vector3(0, 0.05, 0)
	add_child(v)


func _stripe_texture(color: Color) -> ImageTexture:
	var img := Image.create(8, 2, false, Image.FORMAT_RGB8)
	for x in 8:
		var c := color if x % 2 == 0 else Color(0.96, 0.94, 0.88)
		img.set_pixel(x, 0, c)
		img.set_pixel(x, 1, c)
	return ImageTexture.create_from_image(img)


func _striped_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _stripe_texture(color)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	return m


func _stall_goods(root: Node3D, kind: String) -> void:
	var top := 1.0                               # height of the counter top
	match kind:
		"veg":
			_model(PROPS + "crate_open.gltf", Vector3(-0.8, top, 0.7), 0.2, 4.0, root)
			_model(PROPS + "crate_open.gltf", Vector3(0.8, top, 0.7), -0.3, 4.0, root)
			_model(PROPS + "sack.gltf", Vector3(-2.3, 0, 1.0), 0.6, 7.0, root)
			_model(PROPS + "sack.gltf", Vector3(2.3, 0, 0.8), 2.1, 7.0, root)
		"bread":
			for x in [-1.0, 0.0, 1.0]:
				_model(PROPS + "sack.gltf", Vector3(x, top, 0.8), x, 5.0, root)
			_model(PROPS + "barrel.gltf", Vector3(-2.4, 0, 0.6), 0.0, 5.0, root)
			_model(PROPS + "sack.gltf", Vector3(2.3, 0, 0.9), 0.8, 7.0, root)
		"potion":
			var bottles := ["bottle_A_green", "bottle_B_green", "bottle_C_brown"]
			for i in 6:
				_model(ITEMS + bottles[i % 3] + ".gltf.glb", Vector3(-1.2 + i * 0.48, top, 0.5 + (i % 2) * 0.45), i * 1.1, 0.55, root)
			_model(ITEMS + "candle_lit.gltf.glb", Vector3(1.3, top, 1.2), 0.0, 1.0, root)
		"wine":
			_model(ITEMS + "keg.gltf.glb", Vector3(-2.4, 0, 0.9), 0.0, 0.55, root, true)
			_model(ITEMS + "keg_decorated.gltf.glb", Vector3(2.4, 0, 0.9), 0.0, 0.55, root, true)
			for i in 4:
				_model(CHAR + "mug_full.gltf", Vector3(-1.1 + i * 0.7, top, 0.8), i * 1.3, 0.8, root)
			_model(ITEMS + "barrel_large.gltf.glb", Vector3(2.4, 0, -0.5), 0.0, 0.6, root, true)


# --------------------------------------------------------- the Saint's statue ----

func _build_statue(angle: float, radius: float) -> void:
	var pos := ring_point(angle, radius)
	var yaw := facing_well(pos)
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	_cylinder(root, Vector3.ZERO, 2.1, 0.25, _stone_light)
	_cylinder(root, Vector3.ZERO, 1.7, 0.55, _stone)
	var pedestal := _box(root, Vector3(0, 1.35, 0), Vector3(1.6, 1.6, 1.6), _stone_light, true)
	_box(root, Vector3(0, 2.25, 0), Vector3(2.0, 0.22, 2.0), _stone)
	# the Saint: the priest model in stone
	var statue := (load(CHAR + "Mage.glb") as PackedScene).instantiate() as Node3D
	statue.scale = Vector3.ONE * 1.25
	statue.position = Vector3(0, 2.36, 0)
	root.add_child(statue)
	var stone := _material(Color(0.70, 0.69, 0.66), 0.8)
	for mi in statue.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = stone
	var anim := statue.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		anim.play("Idle")
		anim.seek(0.3, true)
		anim.pause()
	_label(root, "Άγιος Βλάσης", Vector3(0, 1.35, 0.82), 36, Color(0.2, 0.17, 0.12))


# --------------------------------------------------------------- notice board ----

func _build_notice_board(angle: float, radius: float) -> void:
	var pos := ring_point(angle, radius)
	var yaw := facing_well(pos)
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	for x in [-1.7, 1.7]:
		_box(root, Vector3(x, 1.5, 0), Vector3(0.22, 3.0, 0.22), _wood_dark, true)
	_box(root, Vector3(0, 1.9, 0.02), Vector3(3.6, 2.0, 0.12), _wood, true)
	var roof := _box(root, Vector3(0, 3.05, 0.1), Vector3(4.2, 0.14, 1.0), _wood_dark)
	roof.rotation.x = deg_to_rad(-10.0)
	var paper := _material(Color(0.93, 0.89, 0.76), 1.0)
	for p in [Vector2(-1.2, 2.3), Vector2(0.0, 2.45), Vector2(1.2, 2.2), Vector2(-0.6, 1.4), Vector2(0.6, 1.5)]:
		var note := _box(root, Vector3(p.x, p.y - 0.1, 0.1), Vector3(0.75, 0.55, 0.02), paper)
		note.rotation.z = _rng.randf_range(-0.12, 0.12)
	_label(root, "ΑΝΑΚΟΙΝΩΣΕΙΣ", Vector3(0, 2.75, 0.14), 46, Color(0.25, 0.14, 0.05))
	_label(root, "Ζητούνται γενναίοι\nπροστάτες του χωριού!", Vector3(-0.0, 1.95, 0.14), 28, Color(0.2, 0.15, 0.1))
	_label(root, "Μετά τη δύση, μείνετε μέσα.\nΟι νεκροί περπατούν…", Vector3(0.0, 1.2, 0.14), 24, Color(0.45, 0.1, 0.08))


# --------------------------------------------------------------------- stage ----

func _build_stage(angle: float, radius: float) -> void:
	var pos := ring_point(angle, radius)
	var yaw := facing_well(pos)
	var root := Node3D.new()
	root.name = "Stage"
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var red := _material(Color(0.62, 0.12, 0.14), 1.0)
	# low wooden platform (George can step onto it), steps, painted backdrop with curtains
	_box(root, Vector3(0, 0.1, 0), Vector3(8.4, 0.2, 5.0), _wood)
	_box(root, Vector3(0, 0.06, 2.75), Vector3(3.0, 0.12, 0.5), _wood_dark)
	for x in [-4.1, 4.1]:
		_box(root, Vector3(x, 2.1, -2.3), Vector3(0.25, 4.0, 0.25), _wood_dark, true)
	_box(root, Vector3(0, 1.9, -2.4), Vector3(8.0, 3.4, 0.2), _material(Color(0.20, 0.27, 0.50), 1.0), true)
	_box(root, Vector3(0, 3.8, -2.2), Vector3(8.4, 0.9, 0.5), red)
	for x in [-3.2, 3.2]:
		_box(root, Vector3(x, 1.8, -2.15), Vector3(1.6, 3.2, 0.3), red)
	_label(root, "Άγιος Βλάσης", Vector3(0, 2.3, -2.28), 70, Color(0.97, 0.88, 0.55))
	_label(root, "Γιορτή του Χωριού", Vector3(0, 1.5, -2.28), 40, Color(0.9, 0.9, 0.95))
	for x in [-3.0, 3.0]:
		_model(ITEMS + "torch_lit.gltf.glb", Vector3(x, 0.6, 2.0), 0.0, 1.4, root)
	_light(pos + Vector3(sin(yaw), 0, cos(yaw)) * 1.0 + Vector3(0, 3.0, 0), Color(1.0, 0.8, 0.5), 1.6, 12.0)
	# two musicians perform on the stage
	var bard_lines := ["♪ Ο Άγιος Βλάσης μας φυλάει… ♪", "Τραγουδάμε για να διώξουμε το σκοτάδι!", "♪ Στου χωριού μας την πλατεία… ♪"]
	for def in [[-1.4, "Rogue_Hooded", "Αρετούσα η Τραγουδίστρια"], [1.4, "Barbarian", "Μπάρμπα-Σπύρος ο Βιολιτζής"]]:
		var v := Villager.new()
		v.mode = Villager.Mode.STAND
		v.model_path = CHAR + def[1] + ".glb"
		v.display_name = def[2]
		v.rest_yaw = yaw
		v.bubble_lines = bard_lines
		v.talk_lines = VillagerData.MUSICIAN_TALK.duplicate()
		v.add_to_group("villagers")
		v.position = pos + Vector3(cos(yaw), 0, -sin(yaw)) * def[0] + Vector3(0, 0.2, 0)
		add_child(v)


# --------------------------------------------------------------------- trees ----

func _build_tree(angle: float, radius: float) -> void:
	var pos := ring_point(angle, radius)
	var tree := _model(NATURE + "tree_single_A.gltf", pos, _rng.randf() * TAU, 9.5, self)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.9
	cs.height = 8.0
	shape.shape = cs
	shape.position.y = 4.0
	body.add_child(shape)
	tree.add_child(body)
	# two benches under it
	for off in [-70.0, 70.0]:
		var bpos := pos + Vector3(cos(deg_to_rad(angle + off)), 0, sin(deg_to_rad(angle + off))) * 0.0
		bpos = ring_point(angle + off * 0.12, radius - 3.4)
		_model(GRAVE + "bench.gltf", bpos, facing_well(bpos) + PI, 1.6, self, true)
