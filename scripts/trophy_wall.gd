class_name TrophyWall
extends Node3D
## Boss Trophy Wall mounted inside George's cottage.
## Displays commemorative trophies and relics from defeated island bosses:
## Skeleton King, Bandit Chief, Alpha Wolf, Cave Spider, Malakar, and Warlord Grom'gar.

const TROPHIES := [
	{
		"id": "king",
		"name": "Κρανίο του Βασιλιά των Οστών",
		"desc": "Το επιχρυσωμένο κρανίο του πρώτου κυρίαρχου της Παλιάς Κρύπτης.",
		"boss_kind": "king",
		"x": -4.2,
	},
	{
		"id": "bandit_chief",
		"name": "Πολεμικό Τσεκούρι του Αρχηγού των Ληστών",
		"desc": "Το βαρύ διπλό τσεκούρι που τρομοκρατούσε το βορειοδυτικό δάσος.",
		"boss_kind": "bandit_chief",
		"x": -2.5,
	},
	{
		"id": "wolf",
		"name": "Κυνόδοντας του Alpha Wolf",
		"desc": "Ο τεράστιος κυνόδοντας του αρχηγού της αγέλης των Χρυσών Πεύκων.",
		"boss_kind": "wolf",
		"x": -0.8,
	},
	{
		"id": "spider",
		"name": "Σαγόνι της Αράχνης των Σπηλαίων",
		"desc": "Το χιτινώδες σαγόνι της μητέρας των αραχνών από τα βάθη του λατομείου.",
		"boss_kind": "spider",
		"x": 0.9,
	},
	{
		"id": "malakar",
		"name": "Σπαθί του Σκοτεινού Ιππότη Μαλάκαρ",
		"desc": "Η σκοτεινή λεπίδα του φύλακα του Φρουρίου της Σκιάς στα Σύνορα.",
		"boss_kind": "malakar",
		"x": 2.6,
	},
	{
		"id": "orc_warlord",
		"name": "Κέρατο του Warlord Γκρομ'γκαρ",
		"desc": "Το πολεμικό κέρατο του Αιμοδιψή Πολέμαρχου των Όρκ από το Κατεστραμμένο Φρούριο.",
		"boss_kind": "orc_warlord",
		"x": 4.3,
	},
]

var _mounts: Array[Node3D] = []

func _ready() -> void:
	name = "TrophyWall"
	_build_wall_mounts()


func _build_wall_mounts() -> void:
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.24, 0.14, 0.08) # polished mahogany
	wood_mat.roughness = 0.65

	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.90, 0.75, 0.30)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.35

	var bone_mat := StandardMaterial3D.new()
	bone_mat.albedo_color = Color(0.90, 0.87, 0.78)
	bone_mat.roughness = 0.60

	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.72, 0.74, 0.78)
	steel_mat.metallic = 0.90
	steel_mat.roughness = 0.25

	for cfg in TROPHIES:
		var mount_root := Node3D.new()
		mount_root.name = "Mount_" + cfg["id"]
		mount_root.position = Vector3(cfg["x"], 0.0, 0.0)
		add_child(mount_root)
		_mounts.append(mount_root)

		# 1. Mahogany Shield Plaque
		var plaque := MeshInstance3D.new()
		var p_box := BoxMesh.new()
		p_box.size = Vector3(1.15, 1.35, 0.06)
		plaque.mesh = p_box
		plaque.material_override = wood_mat
		mount_root.add_child(plaque)

		# Brass rim border
		var rim := MeshInstance3D.new()
		var r_box := BoxMesh.new()
		r_box.size = Vector3(1.22, 1.42, 0.04)
		rim.mesh = r_box
		rim.material_override = brass_mat
		rim.position.z = -0.015
		mount_root.add_child(rim)

		# Engraved Brass Nameplate on bottom
		var plate := MeshInstance3D.new()
		var pl_box := BoxMesh.new()
		pl_box.size = Vector3(0.95, 0.18, 0.02)
		plate.mesh = pl_box
		plate.material_override = brass_mat
		plate.position = Vector3(0.0, -0.52, 0.04)
		mount_root.add_child(plate)

		# 2. Check if this boss is defeated
		var is_slain := _is_boss_slain(cfg["boss_kind"])

		if is_slain:
			# Golden highlight spotlight
			var spot := SpotLight3D.new()
			spot.light_color = Color(1.0, 0.88, 0.65)
			spot.light_energy = 1.2
			spot.spot_range = 3.0
			spot.spot_angle = 35.0
			spot.position = Vector3(0.0, 0.8, 0.9)
			spot.rotation_degrees.x = -40.0
			mount_root.add_child(spot)

			# 3D Trophy representation
			_build_trophy_visual(mount_root, cfg["id"], bone_mat, steel_mat, brass_mat)

			# Interactive spot to inspect
			var spot_node := InteractSpot.make(
				"[R] Εξέταση Τροπαίου: %s" % cfg["name"],
				func(p: Player):
					p.message.emit("🏆 %s: %s" % [cfg["name"], cfg["desc"]])
					Sfx.ui("quest_complete"),
				2.8
			)
			spot_node.position = Vector3(0.0, -0.1, 0.3)
			mount_root.add_child(spot_node)
		else:
			# Silhouetted velvet empty placeholder
			var velvet := MeshInstance3D.new()
			var v_box := BoxMesh.new()
			v_box.size = Vector3(0.9, 0.9, 0.02)
			velvet.mesh = v_box
			var v_mat := StandardMaterial3D.new()
			v_mat.albedo_color = Color(0.14, 0.10, 0.12)
			velvet.material_override = v_mat
			velvet.position.z = 0.04
			mount_root.add_child(velvet)

			var empty_spot := InteractSpot.make(
				"[R] Κενή Βάση Τροπαίου (%s)" % cfg["name"],
				func(p: Player):
					p.message.emit("Αυτή η βάση περιμένει την ήττα του: %s." % cfg["name"]),
				2.5
			)
			empty_spot.position = Vector3(0.0, -0.1, 0.3)
			mount_root.add_child(empty_spot)


func _build_trophy_visual(parent: Node3D, trophy_id: String, bone_mat: Material, steel_mat: Material, brass_mat: Material) -> void:
	match trophy_id:
		"king":
			# Crowned Golden Skull
			var skull := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.22
			sm.height = 0.38
			skull.mesh = sm
			skull.material_override = bone_mat
			skull.position = Vector3(0.0, 0.06, 0.16)
			parent.add_child(skull)

			var crown := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.24
			cm.bottom_radius = 0.22
			cm.height = 0.14
			crown.mesh = cm
			crown.material_override = brass_mat
			crown.position = Vector3(0.0, 0.24, 0.16)
			parent.add_child(crown)

		"bandit_chief":
			# Crossed Steel Battleaxes
			var axe := MeshInstance3D.new()
			var am := BoxMesh.new()
			am.size = Vector3(0.08, 0.75, 0.06)
			axe.mesh = am
			axe.material_override = bone_mat
			axe.position = Vector3(0.0, 0.06, 0.12)
			axe.rotation_degrees.z = 35.0
			parent.add_child(axe)

			var blade := MeshInstance3D.new()
			var bm := PrismMesh.new()
			bm.size = Vector3(0.34, 0.30, 0.06)
			blade.mesh = bm
			blade.material_override = steel_mat
			blade.position = Vector3(-0.16, 0.30, 0.14)
			blade.rotation_degrees.z = -90.0
			parent.add_child(blade)

		"wolf":
			# Curved Giant Wolf Fang
			var fang := MeshInstance3D.new()
			var fm := CylinderMesh.new()
			fm.top_radius = 0.02
			fm.bottom_radius = 0.12
			fm.height = 0.52
			fang.mesh = fm
			fang.material_override = bone_mat
			fang.position = Vector3(0.0, 0.06, 0.14)
			fang.rotation_degrees.z = 25.0
			parent.add_child(fang)

		"spider":
			# Spiked Chitinous Mandible
			var mandible := MeshInstance3D.new()
			var mm := BoxMesh.new()
			mm.size = Vector3(0.14, 0.52, 0.10)
			mandible.mesh = mm
			var chitin := StandardMaterial3D.new()
			chitin.albedo_color = Color(0.18, 0.12, 0.10)
			mandible.material_override = chitin
			mandible.position = Vector3(0.0, 0.06, 0.14)
			mandible.rotation_degrees.z = -20.0
			parent.add_child(mandible)

		"malakar":
			# Dark Knight Broadsword Blade
			var sword := MeshInstance3D.new()
			var swm := BoxMesh.new()
			swm.size = Vector3(0.12, 0.75, 0.04)
			sword.mesh = swm
			sword.material_override = steel_mat
			sword.position = Vector3(0.0, 0.08, 0.14)
			parent.add_child(sword)

			var guard := MeshInstance3D.new()
			var gm := BoxMesh.new()
			gm.size = Vector3(0.36, 0.06, 0.06)
			guard.mesh = gm
			guard.material_override = brass_mat
			guard.position = Vector3(0.0, -0.16, 0.14)
			parent.add_child(guard)

		"orc_warlord":
			# Warlord Great Horn
			var horn := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = 0.04
			hm.bottom_radius = 0.16
			hm.height = 0.58
			horn.mesh = hm
			horn.material_override = bone_mat
			horn.position = Vector3(0.0, 0.06, 0.15)
			horn.rotation_degrees.z = -35.0
			parent.add_child(horn)


func _is_boss_slain(boss_kind: String) -> bool:
	# 1. Check SaveGame defeated bosses
	if SaveGame.boss_defeated(boss_kind):
		return true

	# 2. Check Quests completion states
	var q_node := get_node_or_null("/root/Quests")
	if q_node != null and "state" in q_node:
		var q_state: Dictionary = q_node.state
		match boss_kind:
			"king":
				if q_state.get("king") == 4: # S.DONE == 4
					return true
			"bandit_chief":
				if q_state.get("bandits") == 4:
					return true
			"malakar":
				if q_state.get("f_malakar") == 4:
					return true
			"orc_warlord":
				if q_state.get("orc_warlord") == 4:
					return true

	# 3. Check BountyManager completed contracts
	var tree := get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		var bm = tree.get_first_node_in_group("bounty_manager")
		if bm != null and int(bm.get("completed_count")) > 0:
			# Bosses with bounties can be considered slain if completed contracts exist
			if boss_kind in ["wolf", "spider"] and int(bm.get("completed_count")) >= 1:
				return true
			if boss_kind == "bandit_chief" and int(bm.get("completed_count")) >= 3:
				return true
			if boss_kind == "orc_warlord" and int(bm.get("completed_count")) >= 5:
				return true

	return false
