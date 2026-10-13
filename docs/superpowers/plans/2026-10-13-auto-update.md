# Update with one click, credits and release 1.0.0 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The title menu tells players when a newer GitHub release exists and updates the exported game with one click; the title screen also shows the creators and a Credits page; the version becomes 1.0.0.

**Architecture:** Four small units: `UpdateLogic` (pure functions), `UpdateInstaller` (file work in absolute paths), `Updater` (a Node: HTTP + state machine, no autoload references) and the menu UI in `GameMenu`. The running exe renames itself to `.old`, so no helper script is needed. `tools/release.py` makes a release in one command.

**Tech Stack:** Godot 4.7.2 GDScript (tabs), `HTTPRequest`, `ZIPReader`/`ZIPPacker`, `FileAccess.get_sha256`, Python 3 (release script and the local test server), `gh` CLI.

Spec: `docs/superpowers/specs/2026-10-13-auto-update-design.md` (read it first).

## Global Constraints

- All in-game text is Greek (strings in `scripts/strings_el.gd`); code, comments, file names English. The creators line is exactly `Δημιουργοί: Theodore Sfakianakis & George Sfakianakis` (names as Theodore wrote them).
- Edit Greek files only with the Edit/Write tools (UTF-8), never with a bash heredoc.
- Theodore is the sole author: **no `Co-Authored-By` or "Generated with Claude Code" line in any commit message or PR text.**
- Commit, push, tag and release only when Theodore asks. The plan's commit steps commit on the feature branch only; merging to `main`, pushing and releasing 1.0.0 wait for his request.
- No autoload references (for example `Quests`) in `update_logic.gd`, `update_installer.gd`, `updater.gd`, so test scripts can type-reference them (`GameMenu` mentions `Quests`, so tests reach it only through the `game_menu` group and never type-reference it).
- Only URLs starting with `https://github.com/TheoSfak/George-Adventures/releases/download/` are ever downloaded in production.
- Tests that touch `user://settings.json` must back it up and restore it. Tests never call the real network except the optional `updater_live_test`.
- Headless test command: `timeout 150 godot --path . --headless --script tools/<name>.gd`. Run `godot --path . --headless --import` once after adding a `class_name` script.
- Windowed tests may crash when the GPU is shared (another Godot is open): retry, or use `--resolution 1280x720`.

## File Structure

| File | Responsibility |
|---|---|
| `scripts/update_logic.gd` (new) | version parsing/compare, choose release, checksum parsing, URL + zip-name safety, restart args |
| `scripts/update_installer.gd` (new) | extract zip, swap files, cleanup, remove tree |
| `scripts/updater.gd` (new) | state machine + HTTP + install orchestration |
| `scripts/game_settings.gd` | `check_updates` flag |
| `scripts/strings_el.gd` | Greek texts |
| `scripts/game_menu.gd` | update panel, version label, creators line, Credits page, settings checkbox |
| `tools/update_logic_test.gd`, `tools/update_installer_test.gd`, `tools/updater_flow_test.gd`, `tools/settings_update_test.gd` (new, headless), `tools/updatemenutest.gd` (new, windowed), `tools/updater_live_test.gd` (new, manual) | tests |
| `tools/release.py`, `tools/launchers/*.bat` (new) | release script and launchers |
| `.gitignore`, `export_presets.cfg` | the preset is committed |
| `project.godot`, `CHANGELOG.md`, `README.md`, `CLAUDE.md`, `HANDOVER.md` | version 1.0.0 and docs |

## Task 0: Branch

- [ ] **Step 1: Commit this plan on main and branch**

```bash
cd "C:/Users/user/Desktop/George Adventures"
git add docs/superpowers/plans/2026-10-13-auto-update.md
git commit -m "Plan: update with one click, credits and release 1.0.0"
git checkout -b feature/auto-update
```

Expected: `Switched to a new branch 'feature/auto-update'`.

## Task 1: `UpdateLogic` (pure functions)

**Files:**
- Create: `scripts/update_logic.gd`
- Test: `tools/update_logic_test.gd`

**Interfaces:**
- Produces (all `static`, on `class_name UpdateLogic`):
  - `parse_version(text: String) -> Dictionary` → `{"valid": bool, "nums": [major, minor, patch], "suffix": String}`
  - `is_newer(remote: String, local: String) -> bool`
  - `pick_release(releases: Array, local: String, extra_prefix := "") -> Dictionary` → `{}` or `{version, tag, notes, page_url, zip_url, zip_name, zip_size, sha_url}`
  - `parse_sha256(text: String) -> String` (64 lower-case hex or `""`)
  - `notes_head(text: String, max_lines: int) -> String`
  - `url_allowed(url: String, extra_prefix := "") -> bool`
  - `safe_entry_name(name: String) -> bool`
  - `restart_args(current_method: String, default_method: String, user_args: PackedStringArray) -> PackedStringArray`
  - constants `RELEASE_PREFIX`, `ZIP_PREFIX`, `ZIP_SUFFIX`

- [ ] **Step 1: Write the failing test**

Create `tools/update_logic_test.gd`:

```gdscript
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
```

- [ ] **Step 2: Run it and see it fail**

```bash
cd "C:/Users/user/Desktop/George Adventures"
timeout 150 godot --path . --headless --script tools/update_logic_test.gd 2>&1 | tail -8
```

Expected: errors such as `Identifier "UpdateLogic" not declared` (the script does not exist yet).

- [ ] **Step 3: Write `scripts/update_logic.gd`**

```gdscript
class_name UpdateLogic
## The pure helpers of the updater (no scene, no network): version comparison, choosing a release
## from the GitHub API list, checksum parsing, URL and zip-entry safety, restart arguments.
## See docs/superpowers/specs/2026-10-13-auto-update-design.md.

const RELEASE_PREFIX := "https://github.com/TheoSfak/George-Adventures/releases/download/"
const ZIP_PREFIX := "George-Adventures-"
const ZIP_SUFFIX := "-win64.zip"


## {"valid": bool, "nums": [major, minor, patch], "suffix": String} from "1.2.3", "v1.2" or "0.16-beta".
static func parse_version(text: String) -> Dictionary:
	var invalid := {"valid": false, "nums": [0, 0, 0], "suffix": ""}
	var t := text.strip_edges()
	if t.begins_with("v"):
		t = t.substr(1)
	var suffix := ""
	var dash := t.find("-")
	if dash >= 0:
		suffix = t.substr(dash + 1)
		t = t.substr(0, dash)
	var parts := t.split(".")
	if parts.size() > 3:
		return invalid
	var nums := [0, 0, 0]
	for i in parts.size():
		if not parts[i].is_valid_int():
			return invalid
		nums[i] = int(parts[i])
	return {"valid": true, "nums": nums, "suffix": suffix}


## True when `remote` is a newer version than `local`. A remote that is not a version never is;
## an unknown local version counts as 0.0.0; with equal numbers the one without a suffix wins.
static func is_newer(remote: String, local: String) -> bool:
	var r := parse_version(remote)
	if not r["valid"]:
		return false
	var l := parse_version(local)
	if not l["valid"]:
		return true
	for i in 3:
		if r["nums"][i] != l["nums"][i]:
			return r["nums"][i] > l["nums"][i]
	return r["suffix"] == "" and l["suffix"] != ""


## The newest published release (not a draft, not a pre-release) that is newer than `local` and has
## both assets George-Adventures-<version>-win64.zip and the same name + ".sha256" on an allowed URL.
static func pick_release(releases: Array, local: String, extra_prefix := "") -> Dictionary:
	var best := {}
	for entry in releases:
		if not entry is Dictionary:
			continue
		if bool(entry.get("draft", false)) or bool(entry.get("prerelease", false)):
			continue
		var version := String(entry.get("tag_name", "")).strip_edges()
		if version.begins_with("v"):
			version = version.substr(1)
		if not is_newer(version, local):
			continue
		if not best.is_empty() and not is_newer(version, best["version"]):
			continue
		var assets = entry.get("assets", [])
		if not assets is Array:
			continue
		var zip_name := ZIP_PREFIX + version + ZIP_SUFFIX
		var zip_asset := {}
		var sha_asset := {}
		for asset in assets:
			if not asset is Dictionary:
				continue
			if asset.get("name", "") == zip_name:
				zip_asset = asset
			elif asset.get("name", "") == zip_name + ".sha256":
				sha_asset = asset
		if zip_asset.is_empty() or sha_asset.is_empty():
			continue
		var zip_url := String(zip_asset.get("browser_download_url", ""))
		var sha_url := String(sha_asset.get("browser_download_url", ""))
		if not url_allowed(zip_url, extra_prefix) or not url_allowed(sha_url, extra_prefix):
			continue
		best = {
			"version": version,
			"tag": String(entry.get("tag_name", "")),
			"notes": String(entry.get("body", "")),
			"page_url": String(entry.get("html_url", "")),
			"zip_url": zip_url,
			"zip_name": zip_name,
			"zip_size": int(zip_asset.get("size", 0)),
			"sha_url": sha_url,
		}
	return best


## The 64 hex characters of a .sha256 file ("<hash>" or "<hash>  <file name>"), lower case, or "".
static func parse_sha256(text: String) -> String:
	var cleaned := text.strip_edges().replace("\t", " ").replace("\r", " ").replace("\n", " ")
	var parts := cleaned.split(" ", false)
	if parts.is_empty():
		return ""
	var token := parts[0].to_lower()
	if token.length() != 64 or not token.is_valid_hex_number(false):
		return ""
	return token


## The first `max_lines` non-empty lines of the release notes with the markdown noise removed.
static func notes_head(text: String, max_lines: int) -> String:
	var out := PackedStringArray()
	for line in text.replace("\r\n", "\n").split("\n"):
		var t := line.replace("**", "").strip_edges().lstrip("#").strip_edges()
		if t == "":
			continue
		if t.begins_with("- "):
			t = "• " + t.substr(2)
		out.append(t)
		if out.size() >= max_lines:
			break
	return "\n".join(out)


## Only files from this repository's release downloads (or, in tests, from `extra_prefix`).
static func url_allowed(url: String, extra_prefix := "") -> bool:
	if url.begins_with(RELEASE_PREFIX):
		return true
	return extra_prefix != "" and url.begins_with(extra_prefix)


## Zip-slip guard: a plain file name, no folders, no drive letters, no "..".
static func safe_entry_name(name: String) -> bool:
	if name == "" or name.contains("/") or name.contains("\\") or name.contains(":") or name.contains(".."):
		return false
	return true


## Godot removes its own arguments from OS.get_cmdline_args(), so the restart passes the renderer that
## is actually in use (when it is not the project default) and the user arguments after "--".
static func restart_args(current_method: String, default_method: String, user_args: PackedStringArray) -> PackedStringArray:
	var args := PackedStringArray()
	if current_method != "" and current_method != default_method:
		args.append("--rendering-method")
		args.append(current_method)
	if not user_args.is_empty():
		args.append("--")
		args.append_array(user_args)
	return args
```

- [ ] **Step 4: Refresh the class cache and run the test**

```bash
cd "C:/Users/user/Desktop/George Adventures"
godot --path . --headless --import 2>&1 | tail -3
timeout 150 godot --path . --headless --script tools/update_logic_test.gd 2>&1 | grep -E "FAIL|ALL PASS|SOME FAILED|ERROR"
```

Expected: `ALL PASS` and no `FAIL` lines. If a check fails, fix `update_logic.gd` (not the test) unless the test is wrong.

- [ ] **Step 5: Commit**

```bash
git add scripts/update_logic.gd tools/update_logic_test.gd
git commit -m "Updater: version comparison, release choice and safety helpers"
```

## Task 2: `UpdateInstaller` (files)

**Files:**
- Create: `scripts/update_installer.gd`
- Test: `tools/update_installer_test.gd`

**Interfaces:**
- Consumes: `UpdateLogic.safe_entry_name`.
- Produces (static, absolute paths, on `class_name UpdateInstaller`):
  - `extract(zip_path: String, dest_dir: String, exe_name: String) -> Dictionary` → `{"ok": true, "files": Array[String]}` or `{"ok": false, "error": "zip"|"files"}`
  - `swap(stage_dir: String, install_dir: String, files: Array, exe_name: String) -> Dictionary` → `{"ok": bool, "error": String}`
  - `is_leftover(name: String) -> bool`, `cleanup(install_dir: String) -> void`, `remove_tree(dir: String) -> void`

- [ ] **Step 1: Write the failing test**

Create `tools/update_installer_test.gd`:

```gdscript
extends SceneTree
## The file work of the updater in a temporary folder under user://:
##   godot --path . --headless --script tools/update_installer_test.gd
var failed := false
var tmp := ""


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func make_zip(path: String, entries: Dictionary) -> void:
	var zp := ZIPPacker.new()
	zp.open(path)
	for name in entries:
		zp.start_file(name)
		zp.write_file(String(entries[name]).to_utf8_buffer())
		zp.close_file()
	zp.close()


func write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func read(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _run() -> void:
	await process_frame
	tmp = ProjectSettings.globalize_path("user://update_installer_test")
	UpdateInstaller.remove_tree(tmp)
	DirAccess.make_dir_recursive_absolute(tmp)
	# --- extract
	make_zip(tmp + "/good.zip", {"GeorgeAdventures.exe": "NEWEXE", "Play-Mobile-Renderer.bat": "NEWBAT"})
	var ex := UpdateInstaller.extract(tmp + "/good.zip", tmp + "/stage", "GeorgeAdventures.exe")
	check("extract ok", ex["ok"] and ex["files"].size() == 2)
	check("extracted exe content", read(tmp + "/stage/GeorgeAdventures.exe") == "NEWEXE")
	check("extracted bat content", read(tmp + "/stage/Play-Mobile-Renderer.bat") == "NEWBAT")
	make_zip(tmp + "/slip.zip", {"GeorgeAdventures.exe": "X", "../evil.txt": "EVIL"})
	var slip := UpdateInstaller.extract(tmp + "/slip.zip", tmp + "/stage_slip", "GeorgeAdventures.exe")
	check("zip-slip entry refused", not slip["ok"] and slip["error"] == "zip")
	check("nothing escaped the stage folder", not FileAccess.file_exists(tmp + "/evil.txt"))
	make_zip(tmp + "/noexe.zip", {"readme.txt": "hi"})
	check("zip without the exe refused", not UpdateInstaller.extract(tmp + "/noexe.zip", tmp + "/stage_noexe", "GeorgeAdventures.exe")["ok"])
	check("missing zip refused", not UpdateInstaller.extract(tmp + "/nope.zip", tmp + "/stage_nope", "GeorgeAdventures.exe")["ok"])
	# --- swap
	var inst := tmp + "/install"
	DirAccess.make_dir_recursive_absolute(inst)
	write(inst + "/GeorgeAdventures.exe", "OLDEXE")
	write(inst + "/Play-Mobile-Renderer.bat", "OLDBAT")
	var sw := UpdateInstaller.swap(tmp + "/stage", inst, ex["files"], "GeorgeAdventures.exe")
	check("swap ok", sw["ok"])
	check("new exe in place", read(inst + "/GeorgeAdventures.exe") == "NEWEXE")
	check("old exe kept as .old", read(inst + "/GeorgeAdventures.exe.old") == "OLDEXE")
	check("bat replaced", read(inst + "/Play-Mobile-Renderer.bat") == "NEWBAT")
	check("no .new files left", not FileAccess.file_exists(inst + "/GeorgeAdventures.exe.new") and not FileAccess.file_exists(inst + "/Play-Mobile-Renderer.bat.new"))
	# a second update with a leftover .old
	write(inst + "/GeorgeAdventures.exe", "EXE2")
	var sw2 := UpdateInstaller.swap(tmp + "/stage", inst, ex["files"], "GeorgeAdventures.exe")
	check("swap over an existing .old ok", sw2["ok"] and read(inst + "/GeorgeAdventures.exe.old") == "EXE2")
	# first install into a folder without an exe
	var inst2 := tmp + "/install2"
	DirAccess.make_dir_recursive_absolute(inst2)
	check("swap into a folder without an exe", UpdateInstaller.swap(tmp + "/stage", inst2, ex["files"], "GeorgeAdventures.exe")["ok"] and read(inst2 + "/GeorgeAdventures.exe") == "NEWEXE")
	# an install folder that does not exist changes nothing and fails
	var bad := UpdateInstaller.swap(tmp + "/stage", tmp + "/no_such_folder", ex["files"], "GeorgeAdventures.exe")
	check("swap into a missing folder fails", not bad["ok"] and bad["error"] == "write")
	check("...and created nothing", not DirAccess.dir_exists_absolute(tmp + "/no_such_folder"))
	# --- cleanup
	write(inst + "/Play-Mobile-Renderer.bat.new", "x")
	write(inst + "/other.old", "keep")
	UpdateInstaller.cleanup(inst)
	check("cleanup removed GeorgeAdventures.exe.old", not FileAccess.file_exists(inst + "/GeorgeAdventures.exe.old"))
	check("cleanup removed a .bat.new", not FileAccess.file_exists(inst + "/Play-Mobile-Renderer.bat.new"))
	check("cleanup kept the exe and unrelated files", FileAccess.file_exists(inst + "/GeorgeAdventures.exe") and FileAccess.file_exists(inst + "/other.old"))
	check("is_leftover table", UpdateInstaller.is_leftover("GeorgeAdventures.exe.old") and UpdateInstaller.is_leftover("Play-X.bat.new")
		and not UpdateInstaller.is_leftover("GeorgeAdventures.exe") and not UpdateInstaller.is_leftover("other.old") and not UpdateInstaller.is_leftover("godot.exe.new"))
	# --- remove_tree
	UpdateInstaller.remove_tree(tmp)
	check("remove_tree removed everything", not DirAccess.dir_exists_absolute(tmp))
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and see it fail**

```bash
timeout 150 godot --path . --headless --script tools/update_installer_test.gd 2>&1 | tail -5
```

Expected: `Identifier "UpdateInstaller" not declared`.

- [ ] **Step 3: Write `scripts/update_installer.gd`**

```gdscript
class_name UpdateInstaller
## The file work of the updater. Every path is absolute (use ProjectSettings.globalize_path for user://).
## The running exe is renamed to <exe>.old (Windows allows that), the new one takes its place, and the
## next start deletes the leftovers. See docs/superpowers/specs/2026-10-13-auto-update-design.md.


## Unzips into `dest_dir`. Refuses zips with unsafe entry names or without `exe_name`.
## Returns {"ok": true, "files": [names]} or {"ok": false, "error": "zip" | "files"}.
static func extract(zip_path: String, dest_dir: String, exe_name: String) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return {"ok": false, "error": "zip"}
	var files: Array[String] = []
	for entry in reader.get_files():
		if entry.ends_with("/"):
			continue
		if not UpdateLogic.safe_entry_name(entry):
			reader.close()
			return {"ok": false, "error": "zip"}
		files.append(entry)
	if not files.has(exe_name):
		reader.close()
		return {"ok": false, "error": "zip"}
	DirAccess.make_dir_recursive_absolute(dest_dir)
	for entry in files:
		var f := FileAccess.open(dest_dir.path_join(entry), FileAccess.WRITE)
		if f == null:
			reader.close()
			return {"ok": false, "error": "files"}
		f.store_buffer(reader.read_file(entry))
		f.close()
	reader.close()
	return {"ok": true, "files": files}


## Copies the staged files next to the game as <name>.new (a failure here changes nothing), then renames
## the old exe to .old and the new one into place, then replaces the other files.
static func swap(stage_dir: String, install_dir: String, files: Array, exe_name: String) -> Dictionary:
	var copied: Array[String] = []
	for name in files:
		var target := install_dir.path_join(name) + ".new"
		if DirAccess.copy_absolute(stage_dir.path_join(name), target) != OK:
			_drop(copied)
			return {"ok": false, "error": "write"}
		copied.append(target)
	var exe := install_dir.path_join(exe_name)
	var old := exe + ".old"
	if FileAccess.file_exists(old):
		DirAccess.remove_absolute(old)
	var had_exe := FileAccess.file_exists(exe)
	if had_exe and DirAccess.rename_absolute(exe, old) != OK:
		_drop(copied)
		return {"ok": false, "error": "rename"}
	if DirAccess.rename_absolute(exe + ".new", exe) != OK:
		if had_exe:
			DirAccess.rename_absolute(old, exe)
		_drop(copied)
		return {"ok": false, "error": "rename"}
	for name in files:
		if name == exe_name:
			continue
		var path := install_dir.path_join(name)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		DirAccess.rename_absolute(path + ".new", path)
	return {"ok": true, "error": ""}


static func _drop(paths: Array[String]) -> void:
	for p in paths:
		DirAccess.remove_absolute(p)


## Files left by an update: GeorgeAdventures*.old/.new and Play-*.old/.new next to the exe.
static func is_leftover(name: String) -> bool:
	if not (name.ends_with(".old") or name.ends_with(".new")):
		return false
	return name.begins_with("GeorgeAdventures") or name.begins_with("Play-")


static func cleanup(install_dir: String) -> void:
	for f in DirAccess.get_files_at(install_dir):
		if is_leftover(f):
			DirAccess.remove_absolute(install_dir.path_join(f))


static func remove_tree(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		remove_tree(dir.path_join(d))
	DirAccess.remove_absolute(dir)
```

- [ ] **Step 4: Refresh the class cache and run the test**

```bash
godot --path . --headless --import 2>&1 | tail -3
timeout 150 godot --path . --headless --script tools/update_installer_test.gd 2>&1 | grep -E "FAIL|ALL PASS|SOME FAILED|ERROR"
```

Expected: `ALL PASS`.

- [ ] **Step 5: Commit**

```bash
git add scripts/update_installer.gd tools/update_installer_test.gd
git commit -m "Updater: extract, swap and cleanup of the update files"
```

## Task 3: Settings flag, Greek texts and the `Updater` node

**Files:**
- Modify: `scripts/game_settings.gd` (flag), `scripts/strings_el.gd` (texts)
- Create: `scripts/updater.gd`
- Test: `tools/settings_update_test.gd`, `tools/updater_flow_test.gd`

**Interfaces:**
- Consumes: `UpdateLogic.*`, `UpdateInstaller.*`, `Strings.UPDATE_ERR_*`, `GameSettings.check_updates`.
- Produces:
  - `GameSettings.check_updates: bool` (static, default true) and `GameSettings.set_check_updates(on: bool)` (saves)
  - `Strings` constants listed in Step 3
  - `class_name Updater` (Node): `enum State { IDLE, CHECKING, AVAILABLE, DOWNLOADING, VERIFYING, INSTALLING, DONE, FAILED, NONE }`; signals `state_changed`, `progress(fraction: float)`; vars `state`, `release: Dictionary`, `error_text: String`, `api_url`, `local_version`, `install_dir`, `work_dir`, `allow_prefix`, `install_enabled`, `restart_after_install`; methods `check()`, `start_update()`, `_set_state(s)`, static `current_version() -> String`; const `PAGE_URL`.

- [ ] **Step 1: Write the failing settings test**

Create `tools/settings_update_test.gd`:

```gdscript
extends SceneTree
## The update flag in settings.json:  godot --path . --headless --script tools/settings_update_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var had := FileAccess.file_exists(GameSettings.PATH)
	var backup := FileAccess.get_file_as_bytes(GameSettings.PATH) if had else PackedByteArray()
	if had:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	GameSettings.load_file()
	check("default is on", GameSettings.check_updates)
	GameSettings.set_check_updates(false)
	GameSettings.load_file()
	check("off survives a reload", not GameSettings.check_updates)
	check("the file keeps the other settings", FileAccess.get_file_as_string(GameSettings.PATH).contains("\"volumes\""))
	GameSettings.set_check_updates(true)
	GameSettings.load_file()
	check("on again", GameSettings.check_updates)
	# restore the real file
	if had:
		var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		f.store_buffer(backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	GameSettings.load_file()
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and see it fail**

```bash
timeout 150 godot --path . --headless --script tools/settings_update_test.gd 2>&1 | tail -4
```

Expected: error about `check_updates` / `set_check_updates` not declared.

- [ ] **Step 3: Add the flag and the texts**

In `scripts/game_settings.gd`:

1. After `static var keys := {}                  # action -> physical keycode (only the re-bound ones)` add:

```gdscript
static var check_updates := true       # ask GitHub for a newer release when the title menu opens
```

2. In `load_file()` after `keys = {}` (the reset at the top) add `check_updates = true`, and after the `for action in parsed.get("keys", {}):` loop's body add (at function level, same indent as the `for`):

```gdscript
	check_updates = bool(parsed.get("check_updates", true))
```

3. In `save_file()` change the `data` line to:

```gdscript
	var data := {"version": VERSION, "volumes": volumes, "device": device, "keys": keys, "check_updates": check_updates}
```

4. After `ensure_loaded()` add:

```gdscript
static func set_check_updates(on: bool) -> void:
	check_updates = on
	save_file()
```

In `scripts/strings_el.gd`, after the line `const MENU_PAUSED := "Παύση"` add (use the Edit tool):

```gdscript
const MENU_CREDITS := "Συντελεστές"
const SET_UPDATES := "Έλεγχος για ενημερώσεις"
const VERSION_LABEL := "v%s"
const CREDITS_CREATORS_LINE := "Δημιουργοί: Theodore Sfakianakis & George Sfakianakis"
const CREDITS_HEADING := "Συντελεστές"
## [heading, text] pairs of the Credits page.
const CREDITS_LINES := [
	["Δημιουργοί", "Theodore Sfakianakis & George Sfakianakis"],
	["Σχεδιασμός και προγραμματισμός", "Με τη βοήθεια τεχνητής νοημοσύνης (Claude της Anthropic)"],
	["Γραφικά", "KayKit της Kay Lousberg (CC0): Adventurers, Skeletons, Medieval Hexagon, Dungeon Remastered, Furniture Bits, Halloween Bits"],
	["Μηχανή παιχνιδιού", "Godot Engine (άδεια MIT)"],
	["Ήχοι και μουσική", "Δημιουργήθηκαν από τα δικά μας scripts (Python και numpy)"],
]
const UPDATE_AVAILABLE := "Νέα έκδοση %s διαθέσιμη"
const UPDATE_CURRENT := "Τρέχουσα έκδοση: %s"
const UPDATE_BUTTON := "Ενημέρωση"
const UPDATE_LATER := "Αργότερα"
const UPDATE_DOWNLOADING := "Λήψη… %d%%"
const UPDATE_VERIFYING := "Έλεγχος αρχείου…"
const UPDATE_INSTALLING := "Εγκατάσταση…"
const UPDATE_DONE := "Η ενημέρωση ολοκληρώθηκε. Ξεκίνα ξανά το παιχνίδι."
const UPDATE_OPEN_PAGE := "Άνοιγμα σελίδας λήψης"
const UPDATE_ERR_EDITOR := "Η ενημέρωση λειτουργεί μόνο στο εξαγόμενο παιχνίδι (το αρχείο exe)."
const UPDATE_ERR_URL := "Μη αποδεκτή διεύθυνση λήψης."
const UPDATE_ERR_SIZE := "Το αρχείο της ενημέρωσης έχει ασυνήθιστο μέγεθος."
const UPDATE_ERR_DOWNLOAD := "Η λήψη απέτυχε. Έλεγξε τη σύνδεσή σου στο internet."
const UPDATE_ERR_CHECKSUM := "Το αρχείο που κατέβηκε είναι κατεστραμμένο."
const UPDATE_ERR_FILES := "Δεν ήταν δυνατή η εγγραφή των αρχείων. Ο φάκελος του παιχνιδιού δεν επιτρέπει αλλαγές."
const UPDATE_ERR_ZIP := "Το αρχείο της ενημέρωσης δεν είναι έγκυρο."
```

- [ ] **Step 4: Run the settings test**

```bash
timeout 150 godot --path . --headless --script tools/settings_update_test.gd 2>&1 | grep -E "FAIL|ALL PASS|SOME FAILED|ERROR"
```

Expected: `ALL PASS`. Then confirm the real settings file is unchanged in content apart from nothing (the test restores it): `git status --short` shows no change to tracked files other than the two edited scripts and the new test.

- [ ] **Step 5: Write the failing flow test**

Create `tools/updater_flow_test.gd`:

```gdscript
extends SceneTree
## The whole updater against a local HTTP server (no internet):
##   T=$(cygpath -m "$(mktemp -d)"); python -I -m http.server 8765 --bind 127.0.0.1 --directory "$T" >/dev/null 2>&1 &
##   godot --path . --headless --script tools/updater_flow_test.gd -- "$T" 8765
var failed := false
var tmp := ""
var base := ""
var states: Array = []


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func read(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func make_zip(path: String, entries: Dictionary) -> void:
	var zp := ZIPPacker.new()
	zp.open(path)
	for name in entries:
		zp.start_file(name)
		zp.write_file(String(entries[name]).to_utf8_buffer())
		zp.close_file()
	zp.close()


## Writes releases.json with one release 1.1.0 whose assets are served from `base`.
func publish(sha: String) -> void:
	var zip_name := "George-Adventures-1.1.0-win64.zip"
	var size := FileAccess.get_file_as_bytes(tmp + "/" + zip_name).size()
	write(tmp + "/" + zip_name + ".sha256", sha + "  " + zip_name + "\n")
	var releases := [{
		"tag_name": "v1.1.0", "draft": false, "prerelease": false, "body": "## Novo\n- tests",
		"html_url": base + "page",
		"assets": [
			{"name": zip_name, "browser_download_url": base + zip_name, "size": size},
			{"name": zip_name + ".sha256", "browser_download_url": base + zip_name + ".sha256", "size": 100},
		],
	}]
	write(tmp + "/releases.json", JSON.stringify(releases))


func make_updater(local: String) -> Updater:
	var u := Updater.new()
	u.api_url = base + "releases.json"
	u.local_version = local
	u.install_dir = tmp + "/install"
	u.work_dir = tmp + "/work"
	u.allow_prefix = base
	u.install_enabled = true
	u.restart_after_install = false
	root.add_child(u)
	u.state_changed.connect(func(): states.append(u.state))
	return u


func wait_for(u: Updater, wanted: Array, seconds := 10.0) -> void:
	var left := seconds
	while left > 0.0 and not wanted.has(u.state):
		await create_timer(0.05).timeout
		left -= 0.05


func fresh_install() -> void:
	UpdateInstaller.remove_tree(tmp + "/install")
	DirAccess.make_dir_recursive_absolute(tmp + "/install")
	write(tmp + "/install/GeorgeAdventures.exe", "OLDEXE")


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	tmp = args[0]
	base = "http://127.0.0.1:%s/" % args[1]
	GameSettings.ensure_loaded()
	GameSettings.check_updates = true
	var zip_path := tmp + "/George-Adventures-1.1.0-win64.zip"
	make_zip(zip_path, {"GeorgeAdventures.exe": "NEWEXE-1.1.0", "Play-Mobile-Renderer.bat": "NEWBAT"})
	var good_sha := FileAccess.get_sha256(zip_path)

	# --- A: the happy path
	publish(good_sha)
	fresh_install()
	var a := make_updater("1.0.0")
	a.check()
	check("A: checking started", a.state == Updater.State.CHECKING)
	await wait_for(a, [Updater.State.AVAILABLE, Updater.State.NONE, Updater.State.FAILED])
	check("A: update available", a.state == Updater.State.AVAILABLE)
	check("A: release is 1.1.0", a.release.get("version", "") == "1.1.0")
	states.clear()
	a.start_update()
	await wait_for(a, [Updater.State.DONE, Updater.State.FAILED])
	check("A: update done (error: '%s')" % a.error_text, a.state == Updater.State.DONE)
	check("A: states were DOWNLOADING, VERIFYING, INSTALLING, DONE", states == [Updater.State.DOWNLOADING, Updater.State.VERIFYING, Updater.State.INSTALLING, Updater.State.DONE])
	check("A: new exe in place", read(tmp + "/install/GeorgeAdventures.exe") == "NEWEXE-1.1.0")
	check("A: old exe kept as .old", read(tmp + "/install/GeorgeAdventures.exe.old") == "OLDEXE")
	check("A: launcher copied", read(tmp + "/install/Play-Mobile-Renderer.bat") == "NEWBAT")
	a.queue_free()

	# --- B: a wrong checksum changes nothing
	publish("0".repeat(64))
	fresh_install()
	var b := make_updater("1.0.0")
	b.check()
	await wait_for(b, [Updater.State.AVAILABLE, Updater.State.NONE])
	b.start_update()
	await wait_for(b, [Updater.State.DONE, Updater.State.FAILED])
	check("B: failed", b.state == Updater.State.FAILED)
	check("B: checksum message", b.error_text == Strings.UPDATE_ERR_CHECKSUM)
	check("B: exe untouched", read(tmp + "/install/GeorgeAdventures.exe") == "OLDEXE" and not FileAccess.file_exists(tmp + "/install/GeorgeAdventures.exe.old"))
	check("B: the bad zip was deleted", not FileAccess.file_exists(tmp + "/work/1.1.0.zip"))
	b.queue_free()

	# --- C: the flag off makes no request
	GameSettings.check_updates = false
	var c := make_updater("1.0.0")
	c.api_url = "http://127.0.0.1:1/never"
	c.check()
	check("C: flag off -> NONE at once", c.state == Updater.State.NONE and c.release.is_empty())
	GameSettings.check_updates = true
	c.queue_free()

	# --- D: already up to date
	publish(good_sha)
	var d := make_updater("1.1.0")
	d.check()
	await wait_for(d, [Updater.State.AVAILABLE, Updater.State.NONE])
	check("D: nothing newer -> NONE", d.state == Updater.State.NONE)
	d.queue_free()

	# --- E: not installable (editor): the click explains instead of downloading
	var e := make_updater("1.0.0")
	e.install_enabled = false
	e.check()
	await wait_for(e, [Updater.State.AVAILABLE, Updater.State.NONE])
	e.start_update()
	check("E: failed with the editor message", e.state == Updater.State.FAILED and e.error_text == Strings.UPDATE_ERR_EDITOR)
	check("E: nothing was downloaded", not FileAccess.file_exists(tmp + "/work/1.1.0.zip"))
	e.queue_free()

	# --- F: server not reachable: silent
	var f := make_updater("1.0.0")
	f.api_url = "http://127.0.0.1:1/releases.json"
	f.check()
	await wait_for(f, [Updater.State.AVAILABLE, Updater.State.NONE, Updater.State.FAILED], 15.0)
	check("F: unreachable server -> NONE (silent)", f.state == Updater.State.NONE)
	f.queue_free()

	# --- G: a release whose asset is on a foreign host is never offered
	var foreign := [{"tag_name": "v9.0.0", "draft": false, "prerelease": false, "body": "", "html_url": "",
		"assets": [{"name": "George-Adventures-9.0.0-win64.zip", "browser_download_url": "https://evil.example/x.zip", "size": 10},
			{"name": "George-Adventures-9.0.0-win64.zip.sha256", "browser_download_url": "https://evil.example/x.sha256", "size": 10}]}]
	write(tmp + "/releases.json", JSON.stringify(foreign))
	var g := make_updater("1.0.0")
	g.check()
	await wait_for(g, [Updater.State.AVAILABLE, Updater.State.NONE])
	check("G: foreign host -> NONE", g.state == Updater.State.NONE)
	g.queue_free()

	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
```

- [ ] **Step 6: Run it and see it fail**

```bash
cd "C:/Users/user/Desktop/George Adventures"
T=$(cygpath -m "$(mktemp -d)")
python -I -m http.server 8765 --bind 127.0.0.1 --directory "$T" >/dev/null 2>&1 &
SP=$!
sleep 1
timeout 150 godot --path . --headless --script tools/updater_flow_test.gd -- "$T" 8765 2>&1 | tail -5
kill $SP
```

Expected: `Identifier "Updater" not declared`.

- [ ] **Step 7: Write `scripts/updater.gd`**

```gdscript
class_name Updater
extends Node
## Asks GitHub for a newer release, downloads it on request, checks it and swaps the exe.
## State machine: IDLE -> CHECKING -> AVAILABLE | NONE; AVAILABLE -> DOWNLOADING -> VERIFYING ->
## INSTALLING -> DONE | FAILED. No scene or autoload access, so tests can use it directly.
## See docs/superpowers/specs/2026-10-13-auto-update-design.md.

signal state_changed
signal progress(fraction: float)

enum State { IDLE, CHECKING, AVAILABLE, DOWNLOADING, VERIFYING, INSTALLING, DONE, FAILED, NONE }

const API_URL := "https://api.github.com/repos/TheoSfak/George-Adventures/releases?per_page=10"
const PAGE_URL := "https://github.com/TheoSfak/George-Adventures/releases"
const EXE_NAME := "GeorgeAdventures.exe"
const MAX_ZIP_BYTES := 500 * 1024 * 1024
const CHECK_TIMEOUT := 8.0

var state := State.IDLE
var release := {}                    # UpdateLogic.pick_release result while AVAILABLE or later
var error_text := ""                 # Greek message while FAILED
var api_url := API_URL
var local_version := ""
var install_dir := ""                # where the running exe lives
var work_dir := "user://update"      # downloads and extracted files
var allow_prefix := ""               # tests: an extra allowed URL prefix (the local server)
var install_enabled := false         # only the exported game on Windows replaces itself
var restart_after_install := true

var _download: HTTPRequest
var _zip_path := ""


static func current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func _init() -> void:
	local_version = current_version()
	install_dir = OS.get_executable_path().get_base_dir()
	install_enabled = not OS.has_feature("editor") and OS.get_name() == "Windows"


func _ready() -> void:
	set_process(false)
	if install_enabled:
		# the previous update left the old exe and the downloaded files behind
		UpdateInstaller.cleanup(install_dir)
		UpdateInstaller.remove_tree(ProjectSettings.globalize_path(work_dir))


func _set_state(s: State) -> void:
	state = s
	state_changed.emit()


func _fail(text: String) -> void:
	set_process(false)
	if _download != null:
		_download.queue_free()
		_download = null
	if _zip_path != "" and FileAccess.file_exists(_zip_path):
		DirAccess.remove_absolute(_zip_path)
	error_text = text
	_set_state(State.FAILED)


func _user_agent() -> String:
	return "User-Agent: GeorgeAdventures/" + local_version


# ------------------------------------------------------------------- check ----

## Once per start: asks GitHub for the releases. Silent on every problem (state NONE).
func check() -> void:
	if state != State.IDLE:
		return
	GameSettings.ensure_loaded()
	if not GameSettings.check_updates:
		_set_state(State.NONE)
		return
	_set_state(State.CHECKING)
	var http := HTTPRequest.new()
	http.timeout = CHECK_TIMEOUT
	add_child(http)
	http.request_completed.connect(_on_check_done.bind(http))
	if http.request(api_url, ["Accept: application/vnd.github+json", _user_agent()]) != OK:
		http.queue_free()
		_set_state(State.NONE)


func _on_check_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_set_state(State.NONE)
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Array:
		_set_state(State.NONE)
		return
	release = UpdateLogic.pick_release(parsed, local_version, allow_prefix)
	_set_state(State.AVAILABLE if not release.is_empty() else State.NONE)


# ---------------------------------------------------------------- download ----

## The click on "Ενημέρωση".
func start_update() -> void:
	if state != State.AVAILABLE:
		return
	if not install_enabled:
		_fail(Strings.UPDATE_ERR_EDITOR)
		return
	if not UpdateLogic.url_allowed(release["zip_url"], allow_prefix) or not UpdateLogic.url_allowed(release["sha_url"], allow_prefix):
		_fail(Strings.UPDATE_ERR_URL)
		return
	var size := int(release["zip_size"])
	if size <= 0 or size > MAX_ZIP_BYTES:
		_fail(Strings.UPDATE_ERR_SIZE)
		return
	var dir := ProjectSettings.globalize_path(work_dir)
	DirAccess.make_dir_recursive_absolute(dir)
	_zip_path = dir.path_join(String(release["version"]) + ".zip")
	_set_state(State.DOWNLOADING)
	_download = HTTPRequest.new()
	_download.download_file = _zip_path
	_download.max_redirects = 8
	_download.timeout = 900.0
	add_child(_download)
	_download.request_completed.connect(_on_download_done)
	if _download.request(release["zip_url"], [_user_agent()]) != OK:
		_fail(Strings.UPDATE_ERR_DOWNLOAD)
		return
	set_process(true)


func _process(_delta: float) -> void:
	if state == State.DOWNLOADING and _download != null:
		var total := maxf(float(release["zip_size"]), 1.0)
		progress.emit(clampf(float(_download.get_downloaded_bytes()) / total, 0.0, 1.0))


func _on_download_done(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	set_process(false)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail(Strings.UPDATE_ERR_DOWNLOAD)
		return
	var f := FileAccess.open(_zip_path, FileAccess.READ)
	if f == null or f.get_length() != int(release["zip_size"]):
		_fail(Strings.UPDATE_ERR_DOWNLOAD)
		return
	f.close()
	progress.emit(1.0)
	_set_state(State.VERIFYING)
	var http := HTTPRequest.new()
	http.timeout = 30.0
	add_child(http)
	http.request_completed.connect(_on_sha_done.bind(http))
	if http.request(release["sha_url"], [_user_agent()]) != OK:
		http.queue_free()
		_fail(Strings.UPDATE_ERR_DOWNLOAD)


func _on_sha_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail(Strings.UPDATE_ERR_DOWNLOAD)
		return
	var expected := UpdateLogic.parse_sha256(body.get_string_from_utf8())
	if expected == "" or expected != FileAccess.get_sha256(_zip_path):
		_fail(Strings.UPDATE_ERR_CHECKSUM)
		return
	_install()


# ----------------------------------------------------------------- install ----

func _install() -> void:
	_set_state(State.INSTALLING)
	var stage := ProjectSettings.globalize_path(work_dir).path_join(String(release["version"]))
	var extracted := UpdateInstaller.extract(_zip_path, stage, EXE_NAME)
	if not extracted["ok"]:
		_fail(Strings.UPDATE_ERR_FILES if extracted["error"] == "files" else Strings.UPDATE_ERR_ZIP)
		return
	var swapped := UpdateInstaller.swap(stage, install_dir, extracted["files"], EXE_NAME)
	if not swapped["ok"]:
		_fail(Strings.UPDATE_ERR_FILES)
		return
	_set_state(State.DONE)
	if restart_after_install:
		var default_method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"))
		var args := UpdateLogic.restart_args(RenderingServer.get_current_rendering_method(), default_method, OS.get_cmdline_user_args())
		OS.create_process(install_dir.path_join(EXE_NAME), args)
		get_tree().quit()
```

- [ ] **Step 8: Refresh the class cache and run the flow test**

```bash
cd "C:/Users/user/Desktop/George Adventures"
godot --path . --headless --import 2>&1 | tail -3
T=$(cygpath -m "$(mktemp -d)")
python -I -m http.server 8765 --bind 127.0.0.1 --directory "$T" >/dev/null 2>&1 &
SP=$!
sleep 1
timeout 150 godot --path . --headless --script tools/updater_flow_test.gd -- "$T" 8765 2>&1 | grep -E "PASS|FAIL|ERROR|SOME"
kill $SP
```

Expected: all `PASS` lines, then `ALL PASS`. If the server port 8765 is busy, change both numbers. If scenario F is slow, the connection refusal on port 1 should return within 1 s.

- [ ] **Step 9: Commit**

```bash
git add scripts/updater.gd scripts/game_settings.gd scripts/strings_el.gd tools/settings_update_test.gd tools/updater_flow_test.gd
git commit -m "Updater: check, download, verify and install against GitHub releases"
```

## Task 4: Menu UI — update panel, version, creators, Credits page, settings checkbox

**Files:**
- Modify: `scripts/game_menu.gd`
- Test: `tools/updatemenutest.gd` (windowed)

**Interfaces:**
- Consumes: `Updater` (all of Task 3), `Strings.*`, `GameSettings.check_updates/set_check_updates`, `UpdateLogic.notes_head`, `UiKit.panel_style/row_style/label/paragraph/button`, `FancyBar`.
- Produces: `GameMenu.Page.CREDITS` (enum value 3), members `_updater: Updater`, `_update_hidden: bool`, button texts findable by tests.

- [ ] **Step 1: Write the failing windowed test**

Create `tools/updatemenutest.gd`:

```gdscript
extends SceneTree
## The update panel, version label, creators line, Credits page and settings checkbox:
##   godot --path . --resolution 1280x720 --script tools/updatemenutest.gd -- <outdir>
var out := "."
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


## The first Button / CheckBox under `node` whose text is `text`.
func find_button(node: Node, text: String) -> BaseButton:
	for c in node.find_children("*", "BaseButton", true, false):
		if (c as BaseButton).get("text") == text and (c as BaseButton).is_visible_in_tree():
			return c
	return null


func has_label(node: Node, text: String) -> bool:
	for c in node.find_children("*", "Label", true, false):
		if (c as Label).text == text and (c as Label).is_visible_in_tree():
			return true
	return false


func _run() -> void:
	await process_frame
	var settings_backup := FileAccess.get_file_as_bytes(GameSettings.PATH) if FileAccess.file_exists(GameSettings.PATH) else PackedByteArray()
	var had_settings := FileAccess.file_exists(GameSettings.PATH)
	var save = load("res://scripts/save_game.gd")
	save.menu_in_tests = true
	GameSettings.ensure_loaded()
	GameSettings.check_updates = false              # no network in tests
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var menu = get_first_node_in_group("game_menu")
	check("title menu is open", menu != null and paused)
	var u: Updater = menu._updater
	check("the updater exists and did not check (flag off)", u != null and u.state == Updater.State.NONE)
	check("creators line is shown", has_label(menu, Strings.CREDITS_CREATORS_LINE))
	check("version label is shown", has_label(menu, Strings.VERSION_LABEL % Updater.current_version()))
	check("no update panel without an update", find_button(menu, Strings.UPDATE_BUTTON) == null)
	await shot("update_0_title")

	# an available update
	u.release = {"version": "1.1.0", "tag": "v1.1.0", "notes": "## Novo\n- Prwto\n- Deftero", "page_url": Updater.PAGE_URL,
		"zip_url": "", "zip_name": "", "zip_size": 1000, "sha_url": ""}
	u._set_state(Updater.State.AVAILABLE)
	await create_timer(0.3).timeout
	check("panel shows the new version", has_label(menu, Strings.UPDATE_AVAILABLE % "1.1.0"))
	check("panel has the update button", find_button(menu, Strings.UPDATE_BUTTON) != null)
	await shot("update_1_available")
	find_button(menu, Strings.UPDATE_LATER).pressed.emit()
	await create_timer(0.2).timeout
	check("Later hides the panel", find_button(menu, Strings.UPDATE_BUTTON) == null)
	# progress
	menu._update_hidden = false
	u._set_state(Updater.State.DOWNLOADING)
	await create_timer(0.2).timeout
	u.progress.emit(0.34)
	await create_timer(0.2).timeout
	check("progress text", has_label(menu, Strings.UPDATE_DOWNLOADING % 34))
	await shot("update_2_downloading")
	# failure
	u.error_text = Strings.UPDATE_ERR_CHECKSUM
	u._set_state(Updater.State.FAILED)
	await create_timer(0.2).timeout
	check("failure message shown", has_label(menu, Strings.UPDATE_ERR_CHECKSUM))
	check("open-page button shown", find_button(menu, Strings.UPDATE_OPEN_PAGE) != null)
	await shot("update_3_failed")
	menu._update_hidden = true
	menu._show_page(0)

	# credits
	find_button(menu, Strings.MENU_CREDITS).pressed.emit()
	await create_timer(0.3).timeout
	check("credits page is open (page 3)", menu._page == 3)
	check("credits show the creators", has_label(menu, "Theodore Sfakianakis & George Sfakianakis"))
	await shot("update_4_credits")
	menu.toggle_pause()                              # Esc: back to the main page
	await create_timer(0.2).timeout
	check("Esc returns to the main page", menu._page == 0)

	# settings checkbox
	menu._show_page(1)
	await create_timer(0.3).timeout
	var box := find_button(menu, Strings.SET_UPDATES) as CheckBox
	check("settings has the update checkbox", box != null)
	await shot("update_5_settings")
	if box != null:
		check("checkbox reflects the flag (off)", not box.button_pressed)
		box.button_pressed = true
		check("toggling it turns the flag on", GameSettings.check_updates)
		box.button_pressed = false
		check("...and off again", not GameSettings.check_updates)
	# restore the real settings file
	if had_settings:
		var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		f.store_buffer(settings_backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and see it fail**

```bash
cd "C:/Users/user/Desktop/George Adventures"
mkdir -p tools/_shots
timeout 200 godot --path . --resolution 1280x720 --script tools/updatemenutest.gd -- tools/_shots 2>&1 | grep -E "PASS|FAIL|ERROR|SOME" | head
```

Expected: errors/FAIL (`_updater` does not exist yet; Invalid access).

- [ ] **Step 3: Edit `scripts/game_menu.gd`**

All edits use the Edit tool (Greek strings come from `Strings`, none are typed here).

1. Page enum and members. Replace `enum Page { MAIN, SETTINGS, HELP }` with:

```gdscript
enum Page { MAIN, SETTINGS, HELP, CREDITS }
```

and after `var _hud: Node` add:

```gdscript
var _updater: Updater
var _update_hidden := false          # "Αργότερα" was pressed: no panel until the next start
var _update_bar: FancyBar
var _update_label: Label
var _creators_label: Label
var _version_label: Label
```

2. In `_ready()`, right after `_build_root()` add:

```gdscript
	_updater = Updater.new()
	add_child(_updater)
	_updater.state_changed.connect(_on_update_state)
	_updater.progress.connect(_on_update_progress)
```

and in the `match SaveGame.start_action:` the default branch becomes:

```gdscript
		_:
			_show_title()
			_updater.check()
```

3. In `_build_root()` after `_dim.add_child(_title_label)` add:

```gdscript
	_creators_label = UiKit.label(Strings.CREDITS_CREATORS_LINE, 15, UiKit.MUTED)
	_creators_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_creators_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_creators_label.offset_left = 22.0
	_creators_label.offset_bottom = -14.0
	_dim.add_child(_creators_label)
	_version_label = UiKit.label(Strings.VERSION_LABEL % Updater.current_version(), 15, UiKit.MUTED)
	_version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_version_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_version_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_version_label.offset_right = -22.0
	_version_label.offset_bottom = -14.0
	_dim.add_child(_version_label)
```

4. In `_clear()` add at the end of the function body:

```gdscript
	_update_bar = null
	_update_label = null
```

5. In `_show_page(page)` after the line `_title_label.visible = _title and page == Page.MAIN` add:

```gdscript
	_creators_label.visible = _title and page == Page.MAIN
	_version_label.visible = _title and page == Page.MAIN
```

and extend the page dispatch: after `elif page == Page.HELP:\n\t\t_build_help()` add

```gdscript
	elif page == Page.CREDITS:
		_build_credits()
```

6. In `_build_title_page()` insert as the first lines after `_panel.offset_top = 80.0`:

```gdscript
	_build_update_panel()
```

and before `_menu_button(Strings.MENU_QUIT, ...)` add:

```gdscript
	_menu_button(Strings.MENU_CREDITS, func(): _show_page(Page.CREDITS))
```

7. Add these functions after `_build_title_page()`:

```gdscript
## The update panel above the title buttons (nothing while there is no update or after "Αργότερα").
func _build_update_panel() -> void:
	if _updater == null or _update_hidden:
		return
	var st := _updater.state
	if st == Updater.State.IDLE or st == Updater.State.CHECKING or st == Updater.State.NONE:
		return
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.row_style(true))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	match st:
		Updater.State.AVAILABLE:
			var head := UiKit.label(Strings.UPDATE_AVAILABLE % String(_updater.release.get("version", "")), 21, UiKit.GOLD_TEXT)
			head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(head)
			var cur := UiKit.label(Strings.UPDATE_CURRENT % Updater.current_version(), 14, UiKit.MUTED)
			cur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(cur)
			var notes := UpdateLogic.notes_head(String(_updater.release.get("notes", "")), 12)
			if notes != "":
				v.add_child(UiKit.paragraph(notes, 15, 340.0))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 10)
			row.add_child(UiKit.button(Strings.UPDATE_BUTTON, func(): _updater.start_update(), 170.0, 18))
			row.add_child(UiKit.button(Strings.UPDATE_LATER, _hide_update_panel, 130.0, 18))
			v.add_child(row)
		Updater.State.DOWNLOADING:
			_update_label = UiKit.label(Strings.UPDATE_DOWNLOADING % 0, 18)
			_update_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(_update_label)
			_update_bar = FancyBar.new()
			_update_bar.custom_minimum_size = Vector2(340, 14)
			_update_bar.glide = false
			v.add_child(_update_bar)
		Updater.State.VERIFYING:
			v.add_child(UiKit.label(Strings.UPDATE_VERIFYING, 18))
		Updater.State.INSTALLING:
			v.add_child(UiKit.label(Strings.UPDATE_INSTALLING, 18))
		Updater.State.DONE:
			v.add_child(UiKit.paragraph(Strings.UPDATE_DONE, 17, 340.0, UiKit.CREAM))
		Updater.State.FAILED:
			v.add_child(UiKit.paragraph(_updater.error_text, 16, 340.0, UiKit.BAD))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 10)
			row.add_child(UiKit.button(Strings.UPDATE_OPEN_PAGE, func():
				OS.shell_open(String(_updater.release.get("page_url", Updater.PAGE_URL))), 220.0, 16))
			row.add_child(UiKit.button(Strings.UPDATE_LATER, _hide_update_panel, 110.0, 16))
			v.add_child(row)
	_box.add_child(panel)


func _hide_update_panel() -> void:
	_update_hidden = true
	_show_page(Page.MAIN)


func _on_update_state() -> void:
	if _open and _title and _page == Page.MAIN:
		_show_page(Page.MAIN)


func _on_update_progress(fraction: float) -> void:
	if is_instance_valid(_update_bar):
		_update_bar.value = fraction
	if is_instance_valid(_update_label):
		_update_label.text = Strings.UPDATE_DOWNLOADING % roundi(fraction * 100.0)


func _build_credits() -> void:
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_top = 30.0 if _title else 0.0
	_heading(Strings.CREDITS_HEADING)
	for entry in Strings.CREDITS_LINES:
		var head := UiKit.label(entry[0], 19, UiKit.GOLD_TEXT)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(head)
		var body := UiKit.paragraph(entry[1], 17, 560.0, UiKit.CREAM)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(body)
	var version := UiKit.label(Strings.VERSION_LABEL % Updater.current_version(), 15, UiKit.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(version)
	var center := CenterContainer.new()
	center.add_child(UiKit.button(Strings.MENU_BACK, func(): _show_page(Page.MAIN), 160.0, 18))
	_box.add_child(center)
```

8. In `_build_settings()` after `_box.add_child(_device_picker())` add:

```gdscript
	var updates := CheckBox.new()
	updates.text = Strings.SET_UPDATES
	updates.button_pressed = GameSettings.check_updates
	updates.focus_mode = Control.FOCUS_NONE
	updates.add_theme_font_size_override("font_size", 18)
	updates.add_theme_color_override("font_color", UiKit.CREAM)
	updates.toggled.connect(func(on: bool): GameSettings.set_check_updates(on))
	_box.add_child(updates)
```

- [ ] **Step 4: Run the windowed test**

```bash
cd "C:/Users/user/Desktop/George Adventures"
timeout 200 godot --path . --resolution 1280x720 --script tools/updatemenutest.gd -- tools/_shots 2>&1 | grep -E "PASS|FAIL|ERROR|SOME"
```

Expected: all `PASS`, `ALL PASS`. If it crashes with a Vulkan/segfault error, retry (shared GPU).

- [ ] **Step 5: Look at the screenshots**

Read `tools/_shots/update_0_title.png`, `update_1_available.png`, `update_2_downloading.png`, `update_3_failed.png`, `update_4_credits.png`, `update_5_settings.png`. Check: the creators line (bottom left) and `v…` (bottom right) are readable and not overlapping buttons; the update panel sits above the buttons and the whole menu fits in 720 px height; the Credits text wraps and fits; the settings page still fits with the extra checkbox (if it overflows at 1280x720, reduce the spacing by moving the checkbox next to the "Συσκευή" heading row instead and re-run). Fix layout problems and re-run Step 4.

- [ ] **Step 6: Regression and commit**

```bash
timeout 200 godot --path . --resolution 1280x720 --script tools/menutest.gd -- tools/_shots 2>&1 | grep -E "menu present|after Continue|after Esc|jump|ERROR" 
git add scripts/game_menu.gd tools/updatemenutest.gd
git commit -m "Menu: update panel, version, creators line, Credits page and the update setting"
```

Expected: `menu present: true`, `after Continue: paused=false`, `after Esc: paused=true`, `jump after reset:` unchanged from before, no `ERROR`. (`menutest` touches the real `settings.json` rebinding and resets it: it is an existing test.)

## Task 5: Release tooling, launchers, version 1.0.0 and docs

**Files:**
- Create: `tools/release.py`, `tools/launchers/Play-Mobile-Renderer.bat`, `tools/launchers/Play-Compatibility-Renderer.bat`, `tools/updater_live_test.gd`
- Modify: `.gitignore`, `project.godot`, `CHANGELOG.md`, `README.md`, `CLAUDE.md`, `HANDOVER.md`
- Add to git: `export_presets.cfg`

- [ ] **Step 1: Launchers into the repo**

Create `tools/launchers/Play-Mobile-Renderer.bat`:

```bat
@echo off
rem Use this if the normal GeorgeAdventures.exe shows black or broken graphics (weaker or older graphics card).
start "" "%~dp0GeorgeAdventures.exe" --rendering-method mobile
```

Create `tools/launchers/Play-Compatibility-Renderer.bat`:

```bat
@echo off
rem Last resort if Play-Mobile-Renderer.bat is also broken (OpenGL instead of Vulkan; paler colours).
start "" "%~dp0GeorgeAdventures.exe" --rendering-method gl_compatibility
```

- [ ] **Step 2: Commit the export preset**

Remove the line `export_presets.cfg` from `.gitignore` (Edit tool), then:

```bash
cd "C:/Users/user/Desktop/George Adventures"
git add .gitignore export_presets.cfg tools/launchers
git status --short
```

Expected: the three/four files staged, nothing unexpected. The preset has no secrets (it only names the output and the exclude filter).

- [ ] **Step 3: Write `tools/release.py`**

```python
#!/usr/bin/env python3
"""Makes a release in one command (run only when Theodore asks for a release).

    python tools/release.py 1.0.0            # export, zip, checksum, GitHub release
    python tools/release.py 1.0.0 --dry-run  # everything except the upload (git checks only warn)

Needs: godot and gh on the PATH, the export templates installed, `export_presets.cfg` (committed).
The release notes are the CHANGELOG.md section whose heading starts with "## <version>".
The updater (scripts/update_logic.gd) expects exactly these asset names:
    George-Adventures-<version>-win64.zip  and  George-Adventures-<version>-win64.zip.sha256
"""
import argparse
import hashlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
EXE = "GeorgeAdventures.exe"


def run(cmd, **kw):
    print("+", " ".join(str(c) for c in cmd))
    return subprocess.run(cmd, check=True, cwd=ROOT, **kw)


def out(cmd):
    return subprocess.run(cmd, check=True, cwd=ROOT, capture_output=True, text=True).stdout.strip()


def project_version():
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    m = re.search(r'^config/version="([^"]+)"', text, re.M)
    return m.group(1) if m else ""


def changelog_section(version):
    lines = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8").splitlines()
    head = re.compile(r"^##\s+v?" + re.escape(version) + r"(\s|$)")
    start = next((i for i, l in enumerate(lines) if head.match(l)), None)
    if start is None:
        return ""
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    return "\n".join(lines[start + 1:end]).strip() + "\n"


def problem(message, dry_run, problems):
    problems.append(message)
    print(("WARN  " if dry_run else "ERROR ") + message)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("version")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    version = args.version.lstrip("v")
    problems = []

    if out(["git", "branch", "--show-current"]) != "main":
        problem("not on the main branch", args.dry_run, problems)
    if out(["git", "status", "--porcelain"]):
        problem("the working tree is not clean", args.dry_run, problems)
    if project_version() != version:
        problem("config/version in project.godot is %r, not %r" % (project_version(), version), args.dry_run, problems)
    notes = changelog_section(version)
    if not notes:
        problem("CHANGELOG.md has no '## %s' section" % version, args.dry_run, problems)
    if problems and not args.dry_run:
        sys.exit(1)

    BUILD.mkdir(exist_ok=True)
    run(["godot", "--path", ".", "--headless", "--export-release", "Windows Desktop", str(BUILD / EXE)])
    zip_path = BUILD / ("George-Adventures-%s-win64.zip" % version)
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(BUILD / EXE, EXE)
        for bat in sorted((ROOT / "tools" / "launchers").glob("*.bat")):
            z.write(bat, bat.name)
    digest = hashlib.sha256(zip_path.read_bytes()).hexdigest()
    sha_path = Path(str(zip_path) + ".sha256")
    sha_path.write_text("%s  %s\n" % (digest, zip_path.name), encoding="utf-8")
    notes_path = BUILD / "release-notes.md"
    notes_path.write_text(notes, encoding="utf-8")
    print("zip:", zip_path, "%.1f MB" % (zip_path.stat().st_size / 1048576))
    print("sha256:", digest)
    if args.dry_run:
        print("dry run: nothing was uploaded")
        return
    run(["gh", "release", "create", "v" + version, str(zip_path), str(sha_path),
         "--title", "%s" % version, "--notes-file", str(notes_path)])
    print("released v" + version)


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: A manual live check of the real API (optional tool)**

Create `tools/updater_live_test.gd`:

```gdscript
extends SceneTree
## Read-only call to the real GitHub API; prints what the updater would offer for a given local version:
##   godot --path . --headless --script tools/updater_live_test.gd -- 0.16-beta
func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	GameSettings.ensure_loaded()
	GameSettings.check_updates = true
	var args := OS.get_cmdline_user_args()
	var u := Updater.new()
	if args.size() > 0:
		u.local_version = args[0]
	root.add_child(u)
	u.check()
	var left := 15.0
	while left > 0.0 and u.state == Updater.State.CHECKING:
		await create_timer(0.1).timeout
		left -= 0.1
	print("local ", u.local_version, " -> state ", Updater.State.keys()[u.state])
	print("offered: ", u.release)
	quit()
```

Run it (needs internet; before 1.0.0 is released, the release list has only pre-releases, so `NONE` is the expected answer):

```bash
cd "C:/Users/user/Desktop/George Adventures"
timeout 60 godot --path . --headless --script tools/updater_live_test.gd -- 0.1 2>&1 | grep -E "local|offered|ERROR"
```

Expected now: `local 0.1 -> state NONE` and `offered: {}` (all existing releases are pre-releases and lack the asset names). After the real 1.0.0 release this prints that release.

- [ ] **Step 5: Version 1.0.0 and the CHANGELOG**

In `project.godot` change `config/version="0.16-beta"` to `config/version="1.0.0"`.

At the top of `CHANGELOG.md` (below the title, above the first entry) add (Edit tool; keep the existing format of the other entries):

```markdown
## 1.0.0 (unreleased) — updates, credits and the first full release
**New in this version**
- **Update with one click.** When the title menu opens the game asks GitHub whether a newer release exists (only the latest published release, never a pre-release). If there is one, a panel shows the version and what is new with an "Ενημέρωση" button: the game downloads the zip, checks its SHA-256, replaces its own exe (the old one is kept as `.old` until the next start) and restarts, keeping the renderer in use. An option in the settings turns the check off. Saves and settings are untouched.
- The title menu shows the version (bottom right), the creators line "Δημιουργοί: Theodore Sfakianakis & George Sfakianakis" (bottom left) and a new "Συντελεστές" page.
- `Play-Mobile-Renderer.bat` and `Play-Compatibility-Renderer.bat` come with the download for computers where the normal graphics mode looks broken.
- `tools/release.py` builds the Windows zip, the checksum and the GitHub release in one command.

**Notes**
- Everything from 0.16-beta (the Great Tree and its lake, the weather) is included. 0.16-beta has no updater, so it must be replaced by hand once with this version.
```

- [ ] **Step 6: README, CLAUDE.md, HANDOVER.md**

Append to `README.md` (read it first; match its language and style, which is English):

```markdown
## Download and updates

Download `George-Adventures-<version>-win64.zip` from the latest [release](https://github.com/TheoSfak/George-Adventures/releases), unzip it anywhere and run `GeorgeAdventures.exe`. If the graphics look broken (black surfaces), start `Play-Mobile-Renderer.bat` instead. The game checks for a newer release when the title menu opens and updates itself with one click (turn the check off in the settings). The exe is not code-signed, so Windows SmartScreen may warn on the first start.

## Credits

Created by Theodore Sfakianakis and George Sfakianakis, with the help of AI (Claude by Anthropic). Art: the [KayKit](https://kaylousberg.itch.io/) packs by Kay Lousberg (CC0). Engine: Godot (MIT). All sounds and music are generated by the scripts in `tools/`.
```

In `CLAUDE.md`, after the "**The Great Tree and its lake**" paragraph add (keep the existing paragraph style):

```markdown
**Updates, credits and releases** (`update_logic.gd`, `update_installer.gd`, `updater.gd`, `game_menu.gd`, `tools/release.py`; spec `docs/superpowers/specs/2026-10-13-auto-update-design.md`): when the title menu opens, `GameMenu._ready` calls `Updater.check()` (once per start, 8 s timeout, silent on any problem, off when `GameSettings.check_updates` is false). `UpdateLogic.pick_release` takes the newest release that is not a draft and not a pre-release, is newer than `config/version` (`is_newer`: numbers first, a version without suffix beats the same one with `-beta`) and has the assets `George-Adventures-<v>-win64.zip` + `.sha256` on a `https://github.com/TheoSfak/George-Adventures/releases/download/` URL. The panel (`GameMenu._build_update_panel`) offers "Ενημέρωση"/"Αργότερα"; `Updater.start_update` downloads to `user://update/`, compares the SHA-256, then `UpdateInstaller.extract` (zip-slip guard) and `swap` (the running exe is renamed to `GeorgeAdventures.exe.old`, the new one renamed in; leftovers are deleted by `Updater._ready` at the next start) and restarts with `UpdateLogic.restart_args` (Godot strips its own arguments from `OS.get_cmdline_args()`, so the renderer in use is passed explicitly). It only installs in the exported Windows build (`install_enabled`); in the editor the button explains that. The title menu also shows the version, the creators line and a Credits page (`Page.CREDITS`, texts `Strings.CREDITS_*`). **Release process:** bump `config/version`, add a `## <version>` section to CHANGELOG.md, commit, then `python tools/release.py <version>` (use `--dry-run` first; it builds `build/George-Adventures-<v>-win64.zip` with the exe and `tools/launchers/*.bat`, the `.sha256` and runs `gh release create` WITHOUT `--prerelease`; a pre-release is the way to try a release without offering it to players; tag and push `main` first when asked). Tests: `update_logic_test`, `update_installer_test`, `settings_update_test`, `updater_flow_test` (needs a local `python -m http.server`, see the header of the file), `updatemenutest` (windowed), `updater_live_test` (manual, real API).
```

In `HANDOVER.md` update the **State** line and **What to do now** (read the file first): state that the feature branch `feature/auto-update` holds the updater, credits and 1.0.0 (not merged, not released), and that the next steps are: Theodore reviews, then merge to `main`, tag `v1.0.0`, push and `python tools/release.py 1.0.0`, then install 1.0.0 by hand on the other computer once. Also note the open point: the repository has no LICENSE yet (Theodore to choose).

- [ ] **Step 7: Dry run of the release script**

```bash
cd "C:/Users/user/Desktop/George Adventures"
python tools/release.py 1.0.0 --dry-run 2>&1 | tail -12
```

Expected: `WARN  not on the main branch` (and maybe `the working tree is not clean`), then the export log, `zip: ...George-Adventures-1.0.0-win64.zip  ~68 MB`, `sha256: <64 hex>`, `dry run: nothing was uploaded`. Check the zip content:

```bash
python -I -c "import zipfile; print(zipfile.ZipFile('build/George-Adventures-1.0.0-win64.zip').namelist())"
```

Expected: `['GeorgeAdventures.exe', 'Play-Compatibility-Renderer.bat', 'Play-Mobile-Renderer.bat']`.

- [ ] **Step 8: Commit**

```bash
git add project.godot CHANGELOG.md README.md CLAUDE.md HANDOVER.md tools/release.py tools/updater_live_test.gd
git status --short
git commit -m "Release tooling, launchers, credits docs and version 1.0.0"
```

Expected: nothing left untracked except `build/` (ignored).

## Task 6: Whole-project verification

- [ ] **Step 1: All new headless tests**

```bash
cd "C:/Users/user/Desktop/George Adventures"
for t in update_logic_test update_installer_test settings_update_test; do echo "== $t"; timeout 150 godot --path . --headless --script tools/$t.gd 2>&1 | grep -E "FAIL|ALL PASS|SOME FAILED|ERROR"; done
T=$(cygpath -m "$(mktemp -d)"); python -I -m http.server 8765 --bind 127.0.0.1 --directory "$T" >/dev/null 2>&1 & SP=$!; sleep 1
echo "== updater_flow_test"; timeout 150 godot --path . --headless --script tools/updater_flow_test.gd -- "$T" 8765 2>&1 | grep -E "FAIL|ALL PASS|SOME FAILED|ERROR"; kill $SP
```

Expected: `ALL PASS` four times, no `FAIL`/`ERROR`.

- [ ] **Step 2: Regression**

```bash
for t in gender_test fish_data_test kitchen_test weather_logic_test great_tree_integration_test guard_snag_test part3_data_test; do echo "== $t"; timeout 150 godot --path . --headless --script tools/$t.gd 2>&1 | grep -E "FAIL|ALL PASS|SOME FAILED|ERROR|passed|failed" | tail -3; done
timeout 200 godot --path . --resolution 1280x720 --script tools/updatemenutest.gd -- tools/_shots 2>&1 | grep -E "FAIL|ALL PASS|SOME FAILED"
timeout 200 godot --path . --resolution 1280x720 --script tools/savetest.gd -- tools/_shots 2>&1 | tail -6
```

Expected: the same results as before this work (no FAIL). If `savetest` touches `savegame.json`, confirm Theodore's real save is unchanged: `ls -l "$APPDATA/Godot/app_userdata/"*/savegame.json` timestamps should not change from the test.

- [ ] **Step 3: Exported-game smoke test with the new build**

```bash
cd "C:/Users/user/Desktop/George Adventures/build"
timeout 100 ./GeorgeAdventures.exe --resolution 1280x720 --quit-after 400 2>&1 | grep -v "^$" | head -5; echo "exit=${PIPESTATUS[0]}"
```

Expected: `exit=0`. In the exported game with `config/version` 1.0.0 the live check finds nothing newer (no 1.0.0 release exists yet), so the title menu shows no panel. Also take a look at the title screen in the exported build (windowed run, screenshot via the test) only if Theodore asks.

- [ ] **Step 4: Report**

Tell Theodore in Greek: what was built; what was tested and what was NOT (no real update was installed over a real exe yet, because 1.0.0 is not released; the flow test used a local server and a fake install folder); that the title menu now has the creators line and the Credits page; that merging, tagging, pushing and the 1.0.0 release wait for his word; that 0.16-beta machines need one manual install; the open LICENSE decision. Do not merge, push or release.
