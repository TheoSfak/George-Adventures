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
