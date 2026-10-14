extends SceneTree
## The voice rules (no audio): profiles of the speakers, the list of voiced lines, the file hash:
##   godot --path . --headless --script tools/voice_data_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	# --- every story NPC has a voice
	var all_have := true
	var profiles_exist := true
	for id in QuestData.NPCS:
		if not VoiceData.NPC_PROFILES.has(id):
			all_have = false
			print("  no profile for ", id)
		elif not VoiceData.PROFILES.has(VoiceData.NPC_PROFILES[id]):
			profiles_exist = false
	check("every NPC id has a profile", all_have)
	check("every profile named in NPC_PROFILES exists", profiles_exist)
	var agree := true
	for a in QuestData.NPCS:
		for b in QuestData.NPCS:
			if QuestData.NPCS[a]["name"] == QuestData.NPCS[b]["name"]:
				agree = agree and VoiceData.NPC_PROFILES[a] == VoiceData.NPC_PROFILES[b]
	check("NPCs with the same name share a profile", agree)
	var azure_ok := true
	for p in VoiceData.PROFILES:
		var v: Dictionary = VoiceData.PROFILES[p]
		azure_ok = azure_ok and String(v["voice"]).begins_with("el-GR-") and String(v["rate"]).ends_with("%") and String(v["pitch"]).ends_with("st")
	check("profiles carry an el-GR voice and SSML rate / pitch", azure_ok)

	# --- speaker -> profile
	check("the narrator", VoiceData.profile_for(Strings.NARRATOR) == "narrator")
	check("a man and a woman", VoiceData.profile_for("Παπά-Σταύρος") == "man" and VoiceData.profile_for("Κυρά-Μαρία") == "woman")
	check("both blacksmiths are the same man", VoiceData.profile_for("Νικήτας ο Σιδεράς") == "man")
	check("unknown speakers are silent", VoiceData.profile_for("Τυχαίος Χωριανός") == "" and VoiceData.profile_for("") == "")

	# --- the list of lines
	var lines := VoiceData.lines()
	check("there are plenty of lines", lines.size() > 120)
	var clean := true
	var seen := {}
	var unique := true
	for l in lines:
		clean = clean and String(l["text"]) != "" and VoiceData.PROFILES.has(l["profile"]) and VoiceData.profile_for(l["speaker"]) == l["profile"]
		var id: String = l["profile"] + "|" + l["text"]
		unique = unique and not seen.has(id)
		seen[id] = true
	check("every line has text and a known profile", clean)
	check("no line twice", unique)
	check("the prologue is read by the narrator", lines[0]["speaker"] == Strings.NARRATOR and lines[0]["text"] == QuestData.PROLOGUE[0])
	var has := func(speaker: String, text: String) -> bool:
		for l in lines:
			if l["speaker"] == speaker and l["text"] == text:
				return true
		return false
	var covered := true
	for id in QuestData.NPCS:
		var npc: Dictionary = QuestData.NPCS[id]
		for t in npc["idle"]:
			covered = covered and has.call(npc["name"], t)
		if npc.has("shop"):
			for t in ShopData.SHOPS[npc["shop"]]["greeting"]:
				covered = covered and has.call(npc["name"], t)
	check("all idle lines and shop greetings are there", covered)
	var quests_ok := true
	var split_progress := 0
	for qid in QuestData.QUESTS:
		var q: Dictionary = QuestData.QUESTS[qid]
		var giver: String = QuestData.NPCS[q["giver"]]["name"]
		var turn_in: String = QuestData.NPCS[q["turn_in"]]["name"]
		for t in q.get("offer", []):
			quests_ok = quests_ok and has.call(giver, t)
		for t in q.get("complete", []):
			quests_ok = quests_ok and has.call(turn_in, t)
		for t in q.get("progress", []):
			quests_ok = quests_ok and has.call(giver, t) and has.call(turn_in, t)
			if giver != turn_in:
				split_progress += 1
	check("offer, progress and complete lines of every quest are there", quests_ok)
	check("a quest with another turn-in NPC has its progress lines for both", split_progress > 0)

	# --- the villagers
	var names_ok := true
	for n in VillagerData.NAMES_FEMALE:
		names_ok = names_ok and VoiceData.profile_for(n) == "woman"
	for n in VillagerData.NAMES_MALE:
		names_ok = names_ok and VoiceData.profile_for(n) == "man"
	check("ambient villager names are voiced by gender", names_ok)
	var square_ok := true
	for n in VillagerData.SQUARE_SPEAKERS:
		square_ok = square_ok and VoiceData.profile_for(n) == ("woman" if VillagerData.SQUARE_SPEAKERS[n] == "f" else "man")
	check("vendors and musicians are voiced by gender", square_ok)
	var shared := true
	for t in VillagerData.GOSSIP + VillagerData.DRINK_LINES:
		shared = shared and has.call(VillagerData.NAMES_MALE[0], t) and has.call(VillagerData.NAMES_FEMALE[0], t)
	check("every gossip and drink line exists in both voices", shared)
	# a line two people of the same gender share is listed once, so look for the voice, not the name
	var has_voice := func(speaker: String, text: String) -> bool:
		var profile := VoiceData.profile_for(speaker)
		for l in lines:
			if l["profile"] == profile and l["text"] == text:
				return true
		return false
	var vendors_ok := true
	for v in VillagerData.VENDOR_CALLOUT:
		for t in VillagerData.vendor_talk(v):
			vendors_ok = vendors_ok and has_voice.call(v, t)
	for m in ["Αρετούσα η Τραγουδίστρια", "Μπάρμπα-Σπύρος ο Βιολιτζής"]:
		for t in VillagerData.MUSICIAN_TALK:
			vendors_ok = vendors_ok and has_voice.call(m, t)
	check("vendor and musician lines are there", vendors_ok)
	var square_script := load("res://scripts/square.gd") as GDScript
	var callouts_ok := true
	for stall in square_script.STALLS:
		callouts_ok = callouts_ok and VillagerData.VENDOR_CALLOUT.get(stall[5], "") == stall[7][0]
	check("the first bubble line of every stall is the vendor's call-out", callouts_ok and square_script.STALLS.size() == VillagerData.VENDOR_CALLOUT.size())

	# --- the file key
	var text := "Ο Άγιος να σε φυλάει, παιδί μου."
	check("the key matches the one computed with Python", VoiceData.key("man", text) == "490d9023e57e1ab1")
	check("a different speed or voice gives another key", VoiceData.key("man", text) != VoiceData.key("man_slow", text) and VoiceData.key("man", text) != VoiceData.key("woman", text))
	check("another text gives another key", VoiceData.key("man", text) != VoiceData.key("man", text + " "))
	var path := VoiceData.path("man", text)
	check("the path is DIR + key + .mp3", path == VoiceData.DIR + "490d9023e57e1ab1.mp3")
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
