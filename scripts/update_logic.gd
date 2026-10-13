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


## The first `max_lines` non-empty lines of the release notes with the markdown noise removed; with
## `max_chars` > 0 a longer line is cut and ends in "…" (the update card has little room: the notes come
## from GitHub and may be very long).
static func notes_head(text: String, max_lines: int, max_chars := 0) -> String:
	var out := PackedStringArray()
	for line in text.replace("\r\n", "\n").split("\n"):
		var t := line.replace("**", "").replace("`", "").strip_edges().lstrip("#").strip_edges()
		if t == "":
			continue
		if t.begins_with("- "):
			t = "• " + t.substr(2)
		if max_chars > 0 and t.length() > max_chars:
			t = t.substr(0, max_chars - 1).strip_edges() + "…"
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
