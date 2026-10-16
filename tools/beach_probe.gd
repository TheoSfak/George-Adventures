extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var space := main.get_viewport().world_3d.direct_space_state

	print("\n=== RAYCAST TESTS FROM Z=70 TO Z=160 ===")
	for test_x in [-50.0, -35.0, -18.0, 0.0, 20.0]:
		print("\n--- Testing column at X = %s ---" % test_x)
		for z in range(70, 160, 5):
			var from := Vector3(test_x, 15.0, float(z))
			var to := Vector3(test_x, -15.0, float(z))
			var query := PhysicsRayQueryParameters3D.create(from, to, 1) # layer 1
			var res := space.intersect_ray(query)
			if res.is_empty():
				print("  Z=%d: MISS! NO COLLISION! VOID FALL!" % z)
			else:
				var collider = res["collider"]
				var c_name = collider.name if collider else "unknown"
				var p_name = collider.get_parent().name if collider and collider.get_parent() else "no_parent"
				print("  Z=%d: HIT at Y=%.2f on %s/%s normal=%s" % [z, res["position"].y, p_name, c_name, res["normal"]])

	print("\n=== PROBING PIER AND DEEP SEA COLLIDERS ===")
	# Test under pier deck and around pier (pier is at X = -35, Z = 96..144)
	for z in [96, 110, 125, 140, 150, 170]:
		for x in [-35.0, -31.0, -39.0]:
			var from := Vector3(x, 10.0, float(z))
			var to := Vector3(x, -10.0, float(z))
			var query := PhysicsRayQueryParameters3D.create(from, to, 1)
			var res := space.intersect_ray(query)
			if res.is_empty():
				print("  Pier area X=%s Z=%s: MISS! VOID!" % [x, z])
			else:
				print("  Pier area X=%s Z=%s: HIT Y=%.2f on %s" % [x, z, res["position"].y, res["collider"].name])

	quit(0)
