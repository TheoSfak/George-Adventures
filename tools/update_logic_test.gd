extends SceneTree
## Pure update helpers (no network, no scene):
##   godot --path . --headless --script tools/update_logic_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


## A fake GitHub release; `base` is where the asset URLs point.
func _release(tag: String, draft := false, pre := false, with_assets := true, base := UpdateLogic.RELEASE_PREFIX) -> Dictionary:
	var v := tag.trim_prefix("v")
	var zip := "George-Adventures-%s-win64.zip" % v
	var assets := []
	if with_assets:
		assets = [
			{"name": zip, "browser_download_url": base + tag + "/" + zip, "size": 1000},
			{"name": zip + ".sha256", "browser_download_url": base + tag + "/" + zip + ".sha256", "size": 80},
		]
	return {"tag_name": tag, "draft": draft, "prerelease": pre, "body": "notes " + tag,
		"html_url": "https://github.com/TheoSfak/George-Adventures/releases/tag/" + tag, "assets": assets}


func _run() -> void:
	await process_frame
	# --- versions
	check("1.0.0 is newer than 0.16-beta", UpdateLogic.is_newer("1.0.0", "0.16-beta"))
	check("0.16-beta is not newer than 1.0.0", not UpdateLogic.is_newer("0.16-beta", "1.0.0"))
	check("1.0.1 newer than 1.0.0", UpdateLogic.is_newer("1.0.1", "1.0.0"))
	check("1.10.0 newer than 1.9.0 (numbers, not text)", UpdateLogic.is_newer("1.10.0", "1.9.0"))
	check("v-prefix accepted", UpdateLogic.is_newer("v1.2.0", "1.1.9"))
	check("same version is not newer", not UpdateLogic.is_newer("1.0.0", "1.0.0"))
	check("1.0.0 newer than 1.0.0-beta (suffix)", UpdateLogic.is_newer("1.0.0", "1.0.0-beta"))
	check("1.0.0-beta not newer than 1.0.0", not UpdateLogic.is_newer("1.0.0-beta", "1.0.0"))
	check("empty remote never newer", not UpdateLogic.is_newer("", "1.0.0"))
	check("garbage remote never newer", not UpdateLogic.is_newer("banana", "1.0.0"))
	check("1.2.3.4 is garbage", not UpdateLogic.is_newer("1.2.3.4", "1.0.0"))
	check("unknown local counts as 0.0.0", UpdateLogic.is_newer("0.0.1", "dev"))
	var pv := UpdateLogic.parse_version("0.16-beta")
	check("parse 0.16-beta", pv["valid"] and pv["nums"] == [0, 16, 0] and pv["suffix"] == "beta")
	# --- choosing a release
	var list := [
		_release("v1.1.0"),
		_release("v1.3.0", true),                 # draft
		_release("v1.4.0", false, true),          # pre-release
		_release("v1.2.0"),
		_release("v0.9.0"),                       # older
		_release("v1.5.0", false, false, false),  # no assets
	]
	var pick := UpdateLogic.pick_release(list, "1.0.0")
	check("picks the newest eligible (1.2.0)", pick.get("version", "") == "1.2.0")
	check("pick has the zip url", pick.get("zip_url", "") == UpdateLogic.RELEASE_PREFIX + "v1.2.0/George-Adventures-1.2.0-win64.zip")
	check("pick has the sha url", pick.get("sha_url", "").ends_with(".zip.sha256"))
	check("pick has size and notes", pick.get("zip_size", 0) == 1000 and pick.get("notes", "") == "notes v1.2.0")
	check("pick has the page url", pick.get("page_url", "").ends_with("/tag/v1.2.0"))
	check("nothing newer than 1.2.0 -> {}", UpdateLogic.pick_release(list, "1.2.0").is_empty())
	check("empty list -> {}", UpdateLogic.pick_release([], "1.0.0").is_empty())
	check("junk entries are skipped", UpdateLogic.pick_release([1, "x", null, {}], "1.0.0").is_empty())
	var foreign := [_release("v2.0.0", false, false, true, "https://evil.example/releases/download/")]
	check("a foreign host is refused", UpdateLogic.pick_release(foreign, "1.0.0").is_empty())
	check("...unless the test prefix allows it", not UpdateLogic.pick_release(foreign, "1.0.0", "https://evil.example/").is_empty())
	var wrong_name := _release("v2.0.0")
	wrong_name["assets"][0]["name"] = "something-else.zip"
	check("an asset with the wrong name does not count", UpdateLogic.pick_release([wrong_name], "1.0.0").is_empty())
	var no_sha := _release("v2.0.0")
	no_sha["assets"].remove_at(1)
	check("a release without the .sha256 does not count", UpdateLogic.pick_release([no_sha], "1.0.0").is_empty())
	var null_assets := _release("v2.0.0")
	null_assets["assets"] = null
	check("assets = null does not crash", UpdateLogic.pick_release([null_assets], "1.0.0").is_empty())
	# --- checksum
	var h := "ab".repeat(32)
	check("sha alone", UpdateLogic.parse_sha256(h) == h)
	check("sha with file name and newline", UpdateLogic.parse_sha256(h + "  file.zip\r\n") == h)
	check("sha upper case is lowered", UpdateLogic.parse_sha256(h.to_upper()) == h)
	check("sha too short -> empty", UpdateLogic.parse_sha256("abcd") == "")
	check("sha not hex -> empty", UpdateLogic.parse_sha256("zz".repeat(32)) == "")
	check("sha empty text -> empty", UpdateLogic.parse_sha256("  \n") == "")
	# --- notes
	var notes := "## What is new\n\n- **Updater** works\n- Credits\n\nmore\nmore2"
	check("notes_head limits and cleans", UpdateLogic.notes_head(notes, 3) == "What is new\n• Updater works\n• Credits")
	check("notes_head of empty text", UpdateLogic.notes_head("", 5) == "")
	# --- urls and zip entries
	check("release url allowed", UpdateLogic.url_allowed(UpdateLogic.RELEASE_PREFIX + "v1/x.zip"))
	check("other github path refused", not UpdateLogic.url_allowed("https://github.com/someone/else/releases/download/v1/x.zip"))
	check("http refused", not UpdateLogic.url_allowed("http://github.com/TheoSfak/George-Adventures/releases/download/v1/x.zip"))
	check("empty url refused", not UpdateLogic.url_allowed(""))
	check("extra prefix works", UpdateLogic.url_allowed("http://127.0.0.1:8765/a.zip", "http://127.0.0.1:8765/"))
	check("entry GeorgeAdventures.exe safe", UpdateLogic.safe_entry_name("GeorgeAdventures.exe"))
	check("entry with slash refused", not UpdateLogic.safe_entry_name("dir/x.exe"))
	check("entry with backslash refused", not UpdateLogic.safe_entry_name("dir\\x.exe"))
	check("entry with .. refused", not UpdateLogic.safe_entry_name("..x") and not UpdateLogic.safe_entry_name("a..b"))
	check("entry with drive colon refused", not UpdateLogic.safe_entry_name("C:evil"))
	check("empty entry refused", not UpdateLogic.safe_entry_name(""))
	# --- restart arguments
	check("restart: default renderer, no user args", UpdateLogic.restart_args("forward_plus", "forward_plus", PackedStringArray()).is_empty())
	check("restart: mobile is passed", UpdateLogic.restart_args("mobile", "forward_plus", PackedStringArray()) == PackedStringArray(["--rendering-method", "mobile"]))
	check("restart: user args after --", UpdateLogic.restart_args("forward_plus", "forward_plus", PackedStringArray(["a", "b"])) == PackedStringArray(["--", "a", "b"]))
	check("restart: both", UpdateLogic.restart_args("gl_compatibility", "forward_plus", PackedStringArray(["x"])) == PackedStringArray(["--rendering-method", "gl_compatibility", "--", "x"]))
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
