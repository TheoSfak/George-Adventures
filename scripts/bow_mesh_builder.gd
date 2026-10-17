class_name BowMeshBuilder
extends RefCounted
## Procedural 3D Recurve Bow mesh generator.
## Creates a stylized wooden recurve bow with leather grip, metallic limb nocks,
## and a bowstring matching the KayKit medieval aesthetic.

static func build_recurve_bow_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Control points defining the recurve curve from bottom (-Y) to top (+Y)
	# (X is sideways, Y is along the bow height, Z is forward/backward along shot)
	var curve_pts: Array[Vector3] = [
		Vector3(0.0, -0.62, -0.06), # bottom nock
		Vector3(0.0, -0.50, -0.02),
		Vector3(0.0, -0.32,  0.06), # bottom limb belly
		Vector3(0.0, -0.15,  0.03),
		Vector3(0.0,  0.00,  0.00), # grip center
		Vector3(0.0,  0.15,  0.03),
		Vector3(0.0,  0.32,  0.06), # top limb belly
		Vector3(0.0,  0.50, -0.02),
		Vector3(0.0,  0.62, -0.06), # top nock
	]

	# Build stave segments
	var ring_segments := 6
	var prev_ring: Array[Vector3] = []
	var prev_col: Color = Color.WHITE

	for i in curve_pts.size():
		var pt := curve_pts[i]
		var t := absf(pt.y) / 0.62
		var radius := lerpf(0.022, 0.012, t)

		# Color: grip is dark leather, limbs are polished cedar, tips are brass
		var col := Color(0.55, 0.32, 0.15) # cedar
		if absf(pt.y) < 0.10:
			col = Color(0.24, 0.16, 0.10) # leather grip
		elif t > 0.85:
			col = Color(0.85, 0.72, 0.25) # brass nocks

		# Calculate tangent
		var dir := Vector3.UP
		if i < curve_pts.size() - 1:
			dir = (curve_pts[i + 1] - pt).normalized()
		elif i > 0:
			dir = (pt - curve_pts[i - 1]).normalized()

		var normal := dir.cross(Vector3.RIGHT).normalized()
		var binormal := dir.cross(normal).normalized()

		var current_ring: Array[Vector3] = []
		for s in ring_segments:
			var angle := TAU * float(s) / float(ring_segments)
			var offset := (normal * cos(angle) + binormal * sin(angle)) * radius
			current_ring.append(pt + offset)

		if i > 0:
			for s in ring_segments:
				var s_next := (s + 1) % ring_segments
				var p0 := prev_ring[s]
				var p1 := prev_ring[s_next]
				var p2 := current_ring[s_next]
				var p3 := current_ring[s]

				var face_norm := (p1 - p0).cross(p3 - p0).normalized()

				st.set_color(prev_col)
				st.set_normal(face_norm)
				st.add_vertex(p0)
				st.set_color(prev_col)
				st.set_normal(face_norm)
				st.add_vertex(p1)
				st.set_color(col)
				st.set_normal(face_norm)
				st.add_vertex(p2)

				st.set_color(prev_col)
				st.set_normal(face_norm)
				st.add_vertex(p0)
				st.set_color(col)
				st.set_normal(face_norm)
				st.add_vertex(p2)
				st.set_color(col)
				st.set_normal(face_norm)
				st.add_vertex(p3)

		prev_ring = current_ring
		prev_col = col

	# Bowstring: from bottom nock to top nock
	var str_top := curve_pts[curve_pts.size() - 1]
	var str_btm := curve_pts[0]
	var str_col := Color(0.95, 0.95, 0.95, 0.9)
	var str_r := 0.005

	for a in 4:
		var a_next := (a + 1) % 4
		var ang0 := TAU * float(a) / 4.0
		var ang1 := TAU * float(a_next) / 4.0
		var off0 := Vector3(cos(ang0), 0, sin(ang0)) * str_r
		var off1 := Vector3(cos(ang1), 0, sin(ang1)) * str_r

		var norm := (off0 + off1).normalized()
		st.set_color(str_col)
		st.set_normal(norm)
		st.add_vertex(str_btm + off0)
		st.set_color(str_col)
		st.set_normal(norm)
		st.add_vertex(str_btm + off1)
		st.set_color(str_col)
		st.set_normal(norm)
		st.add_vertex(str_top + off1)

		st.set_color(str_col)
		st.set_normal(norm)
		st.add_vertex(str_btm + off0)
		st.set_color(str_col)
		st.set_normal(norm)
		st.add_vertex(str_top + off1)
		st.set_color(str_col)
		st.set_normal(norm)
		st.add_vertex(str_top + off0)

	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mesh.surface_set_material(0, mat)
	return mesh
