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
