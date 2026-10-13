extends SceneTree
## The procedural geometry of the Great Tree area (no scene needed):
##   godot --path . --headless --script tools/tree_meshes_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


## Number of triangles whose winding is wrong (Godot's front faces are clockwise seen from outside,
## so the right-hand cross product must point AGAINST the stored outward normal) or whose normal is not unit.
func bad_triangles(mesh: ArrayMesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var bad := 0
	for i in range(0, v.size(), 3):
		var cr := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
		if cr.dot(n[i]) >= 0.0 or absf(n[i].length() - 1.0) > 0.001:
			bad += 1
	return bad


func tri_count(mesh: ArrayMesh) -> int:
	if mesh.get_surface_count() == 0:
		return 0
	return (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	# --- the triangle builder
	var s := TreeMeshes.Soup.new()
	s.tri(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), Color.WHITE, Color.WHITE, Color.WHITE, Vector3(0, -1, 0))
	var m := s.build()
	check("a triangle above its inside point gets an upward normal", m.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0].y > 0.99)
	check("and clockwise winding seen from above", bad_triangles(m) == 0)
	var s2 := TreeMeshes.Soup.new()
	s2.tri(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), Color.WHITE, Color.WHITE, Color.WHITE, Vector3(0, 5, 0))
	check("the same triangle below its inside point faces down", s2.build().surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0].y < -0.99)
	var s3 := TreeMeshes.Soup.new()
	s3.tri(Vector3.ZERO, Vector3.ZERO, Vector3.RIGHT, Color.WHITE, Color.WHITE, Color.WHITE, Vector3.DOWN)
	check("a degenerate triangle is skipped", s3.build().get_surface_count() == 0)
	var s4 := TreeMeshes.Soup.new()
	s4.box(Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(2, 1, 3), Color.RED)
	var bm := s4.build()
	check("a box has 12 triangles, all outward and clockwise", tri_count(bm) == 12 and bad_triangles(bm) == 0)
	check("the box measures 2 x 1 x 3", bm.get_aabb().size.is_equal_approx(Vector3(2, 1, 3)))
	var s5 := TreeMeshes.Soup.new()
	s5.strut(Vector3.ZERO, Vector3(0, 4, 0), 0.2, Color.GREEN)
	check("a vertical strut is 4 m long and 0.2 m thick", s5.build().get_aabb().size.is_equal_approx(Vector3(0.2, 4, 0.2)))

	# --- an island
	var isl := TreeMeshes.island(5.0, 7.0, 11)
	var ia := isl.get_aabb()
	check("island: one surface, many triangles (%d)" % tri_count(isl), isl.get_surface_count() == 1 and tri_count(isl) > 200)
	check("island: the plateau is flat at its top height (max y %.3f)" % ia.end.y, absf(ia.end.y - 7.0) < 0.001)
	check("island: the cliff goes down below the water (min y %.2f)" % ia.position.y, absf(ia.position.y + 1.6) < 0.001)
	var reach := maxf(maxf(absf(ia.position.x), ia.end.x), maxf(absf(ia.position.z), ia.end.z))
	check("island: radius fits (%.2f for radius 5)" % reach, reach > 4.0 and reach < 6.6)
	check("island: every triangle is clockwise and outward", bad_triangles(isl) == 0)
	var arrays := isl.surface_get_arrays(0)
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var tops := 0
	var top_wrong := 0
	for i in range(0, verts.size(), 3):
		if norms[i].y > 0.9:
			tops += 1
			if (verts[i].y + verts[i + 1].y + verts[i + 2].y) / 3.0 < 6.5:
				top_wrong += 1
	check("island: the top faces up (%d triangles) and nothing faces up lower down" % tops, tops >= 60 and top_wrong == 0)
	check("island: the same seed gives the same shape, another seed another one",
			TreeMeshes.island(5.0, 7.0, 11).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == arrays[Mesh.ARRAY_VERTEX] and TreeMeshes.island(5.0, 7.0, 12).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != arrays[Mesh.ARRAY_VERTEX])
	check("island: the trimesh collider can be made", isl.create_trimesh_shape() != null)

	# --- the great tree
	var tree := TreeMeshes.great_tree(21)
	var ta := tree.get_aabb()
	check("tree: about 30 m tall and 30 m wide (%s)" % str(ta.size), ta.end.y > 29.0 and ta.end.y < 36.0 and ta.size.x > 24.0 and ta.size.z > 24.0)
	check("tree: a sensible number of triangles (%d)" % tri_count(tree), tri_count(tree) > 1000 and tri_count(tree) < 16000)
	check("tree: clockwise and outward", bad_triangles(tree) == 0)

	# --- umbrella tree
	var um := TreeMeshes.umbrella_tree(5.0, 3.5, 5)
	check("umbrella tree: height and canopy (%s)" % str(um.get_aabb().size), um.get_aabb().size.y > 5.0 and um.get_aabb().size.x > 6.0 and bad_triangles(um) == 0)

	# --- bridges
	var a := Vector3(0, 0.03, 0)
	var b := Vector3(12, 2.4, 0)
	var line := TreeMeshes.bridge_line(a, b, 20)
	check("bridge line: starts and ends exactly on its endpoints", line[0] == a and line[20].is_equal_approx(b))
	check("bridge line: sags in the middle (%.3f below the straight line)" % (a.lerp(b, 0.5).y - line[10].y), line[10].y < a.lerp(b, 0.5).y - 0.05)
	check("bridge line: slope %.3f stays under 0.27" % TreeMeshes.max_slope(line), TreeMeshes.max_slope(line) < 0.27)
	var br := TreeMeshes.bridge(a, b)
	check("bridge: spans from a to b and is wider than 2 m (%s)" % str(br.get_aabb().size), br.get_aabb().size.x > 11.9 and br.get_aabb().size.z >= 2.2 and bad_triangles(br) == 0)
	var bc := TreeMeshes.bridge_collision(a, b)
	check("bridge collision: a deck and rails 1.1 m high", bc.get_aabb().size.y > 1.1 + 2.0 and bc.create_trimesh_shape() != null)

	# --- ramp and pillar
	var rl := TreeMeshes.ramp_line(Vector2(4, 0), 16.5, 180.0, 330.0, 2.4, 7.0, 44)
	check("ramp line: 45 points from y 2.4 up to y 7.0", rl.size() == 45 and is_equal_approx(rl[0].y, 2.4) and is_equal_approx(rl[44].y, 7.0))
	check("ramp line: slope %.3f stays under 0.15" % TreeMeshes.max_slope(rl), TreeMeshes.max_slope(rl) < 0.15)
	check("ramp line starts west of the island and ends north-east", rl[0].x < -8.0 and rl[44].x > 15.0 and rl[44].z < -6.0)
	var rm := TreeMeshes.ramp(rl, 2.6)
	check("ramp: a mesh with stone and parapets, clockwise (%d triangles)" % tri_count(rm), tri_count(rm) > 800 and bad_triangles(rm) == 0)
	check("ramp collision", TreeMeshes.ramp_collision(rl, 2.6).create_trimesh_shape() != null)
	var pil := TreeMeshes.pillar(5.0, 3)
	check("pillar: from below the water up to the deck", pil.get_aabb().position.y < -1.5 and pil.get_aabb().end.y > 4.4 and bad_triangles(pil) == 0)

	# --- balloon
	var bal := TreeMeshes.balloon([Color(1.0, 0.5, 0.2), Color(0.98, 0.9, 0.7)], 4)
	var seen := {}
	for c in bal.surface_get_arrays(0)[Mesh.ARRAY_COLOR]:
		seen[(c as Color).to_html(false)] = true
	check("balloon: about 17 m tall with a basket at the bottom (%s)" % str(bal.get_aabb()), bal.get_aabb().position.y >= -0.01 and bal.get_aabb().end.y > 15.0 and bal.get_aabb().size.x > 8.0 and bad_triangles(bal) == 0)
	check("balloon: striped (%d colours)" % seen.size(), seen.size() > 6)

	# --- props
	check("bench", tri_count(TreeMeshes.bench()) > 40)
	var pts: Array[Vector3] = [Vector3(1, 0, 1), Vector3(-2, 0, 3), Vector3(4, 0, -1)]
	check("lanterns: posts and heads", tri_count(TreeMeshes.lanterns_posts(pts)) >= 3 * 10 and tri_count(TreeMeshes.lanterns_heads(pts)) >= 3 * 10)
	check("flowers: stems and heads", tri_count(TreeMeshes.flowers(pts, 2)) >= 3 * 12)
	check("lily pads", tri_count(TreeMeshes.lily_pads(pts, 2)) >= 3 * 8)
	var ring := TreeMeshes.deck_ring(5.0, 7.0, 24)
	check("deck ring: 24 planks around the trunk", tri_count(ring) == 24 * 12 and ring.get_aabb().size.x > 13.9 and bad_triangles(ring) == 0)
	quit(1 if failed else 0)
