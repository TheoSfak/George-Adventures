extends SceneTree
## The new creatures in an arena with real physics: godot --path . --headless --script tools/static_mob_test.gd
## (about 90 s)
var failed := false
var p: Player
var spawner
var arena_at := Vector3(8000, 0, 8000)


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func spot(x: float, z: float) -> Vector3:
	return arena_at + Vector3(x, 0.05, z)


func george_at(x: float, z: float) -> void:
	p.teleport(spot(x, z), PI)
	p.velocity = Vector3.ZERO


## George is a physics body: after a teleport the server needs a couple of steps before something can be put where he stood.
func settle() -> void:
	await physics_frame
	await physics_frame
	await physics_frame


func clear_arena() -> void:
	for e in get_nodes_in_group("enemies"):
		if (e as Node3D).global_position.distance_to(arena_at) < 200.0:
			e.queue_free()
	await create_timer(0.2).timeout


func model_of(e: Enemy) -> Node3D:
	return e.get_node("Model") as Node3D


func hurt_free(e: Enemy) -> void:
	if is_instance_valid(e):
		e.take_damage(100000.0, e.global_position + Vector3(1, 0, 0))


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	spawner = get_first_node_in_group("enemy_spawner")
	p.max_health = 100000.0
	p.health = 100000.0
	p._invulnerable = 0.0
	var arena := Node3D.new()
	root.add_child(arena)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(300, 1, 300)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = arena_at + Vector3(0, -0.5, 0)
	arena.add_child(floor_body)
	await physics_frame
	await physics_frame

	# --- the pumpkin hops after George and bites him
	george_at(0, 0)
	await settle()
	var pump: Enemy = spawner.spawn_extra("pumpkin", spot(0, 8))
	var base_scale := pump.model_scale
	var max_hop := 0.0
	var min_dist := 99.0
	var scale_changed := false
	var hp0 := p.health
	for i in 6 * 60:
		await physics_frame
		george_at(0, 0)
		var m := model_of(pump)
		max_hop = maxf(max_hop, m.position.y)
		scale_changed = scale_changed or absf(m.scale.y - base_scale) > 0.03
		min_dist = minf(min_dist, pump.global_position.distance_to(p.global_position))
	check("the pumpkin hops (%.2f m) and its body squashes and stretches" % max_hop, max_hop > 0.12 and scale_changed)
	check("it reaches George (%.1f m) and hurts him (%.0f damage)" % [min_dist, hp0 - p.health], min_dist < 2.6 and p.health < hp0)
	var died_count := [0]
	pump.died.connect(func(_e): died_count[0] += 1)
	pump.take_damage(1000.0, pump.global_position + Vector3(1, 0, 0))
	await create_timer(0.9).timeout
	check("a dead pumpkin leaves the enemies, shrinks and `died` came once", pump.is_dead() and not pump.is_in_group("enemies") and died_count[0] == 1 and model_of(pump).scale.y < base_scale * 0.4)
	await clear_arena()

	# --- the haunted tree stays where it is and lashes at 4.6 m
	george_at(0, 0)
	await settle()
	var tree: Enemy = spawner.spawn_extra("haunted_tree", spot(0, 9))
	var tree_start := tree.global_position
	await create_timer(2.5).timeout
	check("the tree does not walk (%.2f m)" % tree.global_position.distance_to(tree_start), tree.global_position.distance_to(tree_start) < 0.3)
	hp0 = p.health
	george_at(0, 5.5)                                        # 3.5 m from the tree, inside its reach
	for i in 4 * 60:
		await physics_frame
		george_at(0, 5.5)
	check("it lashes out at George inside its reach (%.0f damage)" % (hp0 - p.health), p.health < hp0)
	check("and still has not moved", tree.global_position.distance_to(tree_start) < 0.3)
	await clear_arena()

	# --- the golem sleeps until George is within 6 m, then rises, chases and stomps
	george_at(0, 0)
	await settle()
	var golem: Enemy = spawner.spawn_extra("golem", spot(0, 14))
	var golem_base := golem.model_scale
	await create_timer(1.5).timeout
	check("a golem asleep 14 m away is dormant, low and without a name", golem._state == Enemy.State.DORMANT and model_of(golem).scale.y < golem_base * 0.7 and not golem._bar.visible and not golem._tag.visible)
	check("a sleeping golem reports itself dormant (the minimap skips it)", golem.is_dormant())
	george_at(0, 8.5)                                        # 5.5 m
	for i in 60:
		await physics_frame
		george_at(0, 8.5)
	check("within 6 m it wakes", golem._state != Enemy.State.DORMANT and not golem.is_dormant())
	for i in 90:
		await physics_frame
		george_at(0, 8.5)
	check("it stands up to full height and shows its name", absf(model_of(golem).scale.y - golem_base) < 0.1 and golem._tag.visible and golem._bar.visible)
	hp0 = p.health
	var slowed := false
	for i in 7 * 60:
		await physics_frame
		george_at(0, 8.5)
		slowed = slowed or p.is_slowed()
	check("it walks to George and its stomp hurts him (%.0f) and slows him" % (hp0 - p.health), p.health < hp0 and slowed)
	await clear_arena()

	# --- a blow wakes a sleeper too
	george_at(0, 0)
	await settle()
	var golem2: Enemy = spawner.spawn_extra("golem", spot(0, 20))
	await create_timer(0.5).timeout
	golem2.take_damage(5.0, spot(0, 0))
	check("hit from far away, a golem wakes", golem2._state != Enemy.State.DORMANT)
	await clear_arena()

	# --- the heap of bones bursts into three skeletons and is gone
	george_at(0, 0)
	await settle()
	var heap: Enemy = spawner.spawn_extra("bone_heap", spot(0, 16))
	await create_timer(1.0).timeout
	check("a heap 16 m away sleeps", heap._state == Enemy.State.DORMANT)
	var before := get_nodes_in_group("enemies").size()
	var xp0 := p.xp
	var pickups0 := get_nodes_in_group("pickups").size()
	george_at(0, 11)                                         # 5 m
	await create_timer(0.8).timeout
	var minions := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "minion" and (e as Node3D).global_position.distance_to(arena_at) < 100.0:
			minions += 1
	check("within 6.5 m it bursts into three skeletons (%d)" % minions, minions == 3)
	check("the heap itself is gone and gave no experience and dropped nothing", heap.is_dead() and p.xp == xp0 and get_nodes_in_group("pickups").size() == pickups0)
	await clear_arena()

	# --- the cultist shoots magic from a distance
	george_at(0, 0)
	await settle()
	var cultist: Enemy = spawner.spawn_extra("cultist", spot(0, 11))
	hp0 = p.health
	var shots := 0
	for i in 9 * 60:
		await physics_frame
		george_at(0, 0)
		shots = maxi(shots, get_nodes_in_group("projectiles").size())

	check("a cultist keeps its distance (%.1f m) and its orbs hit George (%.0f damage)" % [cultist.global_position.distance_to(p.global_position), hp0 - p.health], p.health < hp0 and cultist.global_position.distance_to(p.global_position) > 3.0)
	await clear_arena()

	# --- the priest calls cultists
	george_at(0, 0)
	await settle()
	var priest: Enemy = spawner.spawn_extra("cult_priest", spot(0, 12))
	priest.aggro_range = 40.0
	await create_timer(9.0).timeout
	var helpers := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "cultist":
			helpers += 1
	check("the priest has called cultists to help (%d)" % helpers, helpers >= 1)
	check("and is a named boss with a health bar", priest.display_name != "" and priest._bar.visible)
	await clear_arena()

	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
