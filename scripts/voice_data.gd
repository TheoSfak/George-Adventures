class_name VoiceData
## Spoken dialogue: which voice reads whose lines and where the pre-generated recording of a line lives.
## The mp3 files in assets/audio/voice are made by tools/gen_voice.py (Microsoft Azure neural voices) from
## lines(); the game finds a recording by the hash of the voice settings plus the exact text of the line,
## so editing a line (or a profile) only needs the generator to be run again. See
## docs/superpowers/specs/2026-10-14-voice-over-design.md.
## Pure data and rules: no scene access, no autoload references (tests and tools use it directly).

const DIR := "res://assets/audio/voice/"
const KEY_LENGTH := 16

## Profile id -> Azure voice and SSML <prosody> values. Tuning a profile and re-running the generator
## makes new files (the values are part of the hash), the old ones are removed with --prune.
const PROFILES := {
	"narrator": {"voice": "el-GR-NestorasNeural", "rate": "-5%", "pitch": "+0st"},
	"man": {"voice": "el-GR-NestorasNeural", "rate": "+0%", "pitch": "+0st"},
	"man_slow": {"voice": "el-GR-NestorasNeural", "rate": "-4%", "pitch": "+0st"},
	"man_quick": {"voice": "el-GR-NestorasNeural", "rate": "+4%", "pitch": "+0st"},
	"woman": {"voice": "el-GR-AthinaNeural", "rate": "+0%", "pitch": "+0st"},
}

## Every id of QuestData.NPCS -> profile. The dialogue box only knows the NPC's display name, see profile_for().
const NPC_PROFILES := {
	"stavros": "man",
	"maria": "woman",
	"nikitas": "man",
	"giannis": "man_slow",
	"vasilis": "man",
	"stelios": "man",
	"theodora": "woman",
	"manolis": "man_quick",
	"thanasis": "man_quick",
	"andreas": "man_quick",
	"ilarion": "man_slow",
	"elpida": "woman",
	"elena": "woman",
	"nikitas_forge": "man",
}


## Profile for the speaker name shown in the dialogue box; "" when that speaker has no voice.
static func profile_for(speaker: String) -> String:
	if speaker == Strings.NARRATOR:
		return "narrator"
	for id in QuestData.NPCS:
		if QuestData.NPCS[id]["name"] == speaker:
			return NPC_PROFILES.get(id, "")
	# the ambient villagers, tavern regulars, stall vendors and musicians: the voice follows the name's gender
	if speaker in VillagerData.NAMES_FEMALE or VillagerData.SQUARE_SPEAKERS.get(speaker, "") == "f":
		return "woman"
	if speaker in VillagerData.NAMES_MALE or VillagerData.SQUARE_SPEAKERS.get(speaker, "") == "m":
		return "man"
	return ""


## File name (without extension) of the recording of `text` in `profile`: the first 16 hex characters of
## sha1(voice|rate|pitch|text) over the UTF-8 bytes. tools/gen_voice.py computes the same thing in Python.
static func key(profile: String, text: String) -> String:
	var p: Dictionary = PROFILES[profile]
	return (str(p["voice"]) + "|" + str(p["rate"]) + "|" + str(p["pitch"]) + "|" + text).sha1_text().substr(0, KEY_LENGTH)


static func path(profile: String, text: String) -> String:
	return DIR + key(profile, text) + ".mp3"


## Every voiced line of the game as [{"speaker", "profile", "text"}], without duplicates: the prologue
## (narrator), the idle lines of each NPC, the shop greetings, the offer / progress / complete lines of
## every quest, said by the NPC that Quests.dialogue_for() lets say them, and what the villagers answer
## (any ambient villager or regular may say any gossip / drink line, so those exist in both voices;
## vendors and musicians have their own lines).
static func lines() -> Array:
	var out: Array = []
	var seen := {}
	for text in QuestData.PROLOGUE:
		_add(out, seen, Strings.NARRATOR, text)
	for id in QuestData.NPCS:
		var npc: Dictionary = QuestData.NPCS[id]
		for text in npc["idle"]:
			_add(out, seen, npc["name"], text)
		if npc.has("shop"):
			for text in ShopData.SHOPS[npc["shop"]]["greeting"]:
				_add(out, seen, npc["name"], text)
	for qid in QuestData.QUESTS:
		var q: Dictionary = QuestData.QUESTS[qid]
		var giver := _npc_name(q["giver"])
		var turn_in := _npc_name(q["turn_in"])
		for text in q.get("offer", []):
			_add(out, seen, giver, text)
		for text in q.get("progress", []):
			_add(out, seen, giver, text)
			_add(out, seen, turn_in, text)
		for text in q.get("complete", []):
			_add(out, seen, turn_in, text)
	for text in VillagerData.GOSSIP + VillagerData.DRINK_LINES:
		_add(out, seen, VillagerData.NAMES_MALE[0], text)
		_add(out, seen, VillagerData.NAMES_FEMALE[0], text)
	for vendor in VillagerData.VENDOR_CALLOUT:
		for text in VillagerData.vendor_talk(vendor):
			_add(out, seen, vendor, text)
	for musician in VillagerData.SQUARE_SPEAKERS:
		if not VillagerData.VENDOR_CALLOUT.has(musician):
			for text in VillagerData.MUSICIAN_TALK:
				_add(out, seen, musician, text)
	return out


static func _npc_name(npc_id: String) -> String:
	return QuestData.NPCS[npc_id]["name"] if QuestData.NPCS.has(npc_id) else ""


static func _add(out: Array, seen: Dictionary, speaker: String, text: String) -> void:
	var profile := profile_for(speaker)
	if profile == "" or text == "":
		return
	var id := profile + "|" + text
	if seen.has(id):
		return
	seen[id] = true
	out.append({"speaker": speaker, "profile": profile, "text": text})
