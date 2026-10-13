# Update with one click (and release 1.0.0) — design

Date: 2026-10-13. Status: approved by Theodore in chat ("nai egrino, proxora").

## Goal

Players who installed the Windows build (the `GeorgeAdventures.exe` from the release zip) get new
versions without reinstalling by hand: the title menu tells them a newer release exists and one
click downloads it, checks it and restarts the game on the new version. The repo is public, so no
login or key is needed. The first release with this feature is **1.0.0** (no more "beta").

Decisions already made with Theodore: update only on a click (never silently in the background);
the latest published release for everyone (no beta/stable channels); the version becomes `1.0.0`
and the release is no longer a pre-release. Players on 0.16-beta must install 1.0.0 by hand once.

## Non-goals

No code signing (costs money; the exe stays unsigned), no delta/patch packs (the whole zip, about
70 MB, is downloaded), no silent or automatic install, no other platforms than Windows x64, no
update while a game is being played (only from the title menu).

## What the player sees

- When the title menu opens, `Updater.check()` runs once per launch in the background (timeout 8 s).
  Nothing is shown while it runs or when it fails (no internet, GitHub down, rate limit).
- If a newer release exists, a panel sits above the title buttons: "Νέα έκδοση 1.1.0 διαθέσιμη"
  (the current one in small print), the first lines of the release notes, and a button
  **Ενημέρωση**. A second small button "Αργότερα" hides the panel until the next launch.
- Click = the panel turns into a progress bar ("Λήψη… 34%"), then "Έλεγχος…" and "Εγκατάσταση…",
  then the game restarts itself on the new version with the same command line arguments (so
  `--rendering-method mobile` from the launcher .bat survives).
- On failure the panel shows a Greek message (no space, not writable, wrong checksum, no network)
  and a button "Άνοιγμα σελίδας λήψης" that opens the release page in the browser (`OS.shell_open`).
- The version is shown small at the bottom of the title menu ("v1.0.0").
- Settings page: a checkbox "Έλεγχος για ενημερώσεις" (default on). Stored in `settings.json` as
  `"check_updates"`; when off, no network request is ever made.
- In the editor / non-exported runs the check works and the panel appears, but "Ενημέρωση" only
  says that updating works in the exported game (nothing is replaced).

## Release rules (what the updater expects)

- A release counts when it is not a draft and not a pre-release (a pre-release is the way to try
  a release without pushing it to players).
- It must carry two assets: `George-Adventures-<version>-win64.zip` and the same name plus
  `.sha256` (one line: 64 hex characters, optionally followed by the file name).
- The release tag is `v<version>` and `config/version` in `project.godot` is the version, e.g. `1.0.0`.
- The release notes (body) are shown as "what is new"; only the first 12 lines are used.

## Version comparison

`UpdateLogic.parse_version("0.16-beta")` takes the first three dot-separated integers (missing
parts are 0, a suffix after `-` is remembered). `1.0.0` is newer than `0.16-beta`; `1.0.1` newer
than `1.0.0`; with equal numbers a version without a suffix is newer than one with it. Garbage
(empty, no digits) never counts as newer.

## Components

Each unit has one job and is testable alone.

- `scripts/update_logic.gd` (`class_name UpdateLogic`, pure static functions, no scene or network access):
  `parse_version`, `is_newer(remote, local)`, `pick_release(releases: Array, local: String) -> Dictionary`
  (newest eligible release that is newer than `local`: `{version, tag, notes, page_url, zip_url,
  zip_name, zip_size, sha_url}`, or `{}`), `parse_sha256(text) -> String`, `notes_head(text, lines)`,
  `url_allowed(url)` (only `https://github.com/TheoSfak/George-Adventures/releases/download/`),
  `safe_entry_name(name)` (zip-slip guard: no `/`, `\`, `:` or `..`).
- `scripts/updater.gd` (`class_name Updater`, a Node owned by `GameMenu`): the state machine
  `IDLE / CHECKING / AVAILABLE / DOWNLOADING / VERIFYING / INSTALLING / FAILED / NONE` with signals
  (`state_changed`, `progress(fraction)`). It owns two `HTTPRequest` nodes (API call, download),
  reads the settings flag, and runs the install steps below. Its constructor takes the API URL and
  the install directory so tests can point it at a local server and a temporary folder.
- `scripts/game_menu.gd`: builds the panel and the version label on the title page, listens to
  `Updater`, adds the settings checkbox.
- `scripts/game_settings.gd`: `check_updates` (static bool, default true) saved and loaded with the
  other settings.
- `scripts/strings_el.gd`: all new Greek texts (`UPDATE_*`, `SET_UPDATES`).
- `tools/release.py`: the one-command release (see below).

## Data flow

1. `check()`: `GET https://api.github.com/repos/TheoSfak/George-Adventures/releases?per_page=10`
   with header `Accept: application/vnd.github+json` and a `User-Agent`. On HTTP 200 the body is
   parsed and `UpdateLogic.pick_release` chooses. Any other result (403 rate limit, 5xx, timeout,
   bad JSON) ends in state `NONE` silently.
2. `start_update()` (only from `AVAILABLE`): the zip URL must pass `url_allowed`; the download goes
   to `user://update/<version>.zip` (`HTTPRequest.download_file`, `max_redirects` 8: GitHub redirects
   to its storage host), progress from `get_downloaded_bytes()` / the asset size. The downloaded
   size must equal the asset size, and the zip must stay under 500 MB.
3. Verify: fetch the `.sha256` asset (small), compare with `FileAccess.get_sha256(zip)`. Mismatch
   deletes the zip and ends in `FAILED` ("το αρχείο είναι κατεστραμμένο").
4. Install (exported Windows runs only; install dir = `OS.get_executable_path().get_base_dir()`):
   1. read the zip with `ZIPReader`; every entry name must pass `safe_entry_name`, and the zip must
      contain `GeorgeAdventures.exe`; extract to `user://update/<version>/`;
   2. copy each extracted file next to the game as `<name>.new` (any failure here, for example a
      folder that is not writable, stops before anything was changed);
   3. rename the running `GeorgeAdventures.exe` to `GeorgeAdventures.exe.old` (Windows allows this
      while it runs), then `GeorgeAdventures.exe.new` to `GeorgeAdventures.exe`; the other files
      (the .bat launchers) are replaced by their `.new` copies. If a rename fails the steps already
      done are reversed;
   4. `OS.create_process(exe_path, OS.get_cmdline_args())`, then quit the game.
5. At startup the game deletes `*.old` and `*.new` leftovers next to the exe and the
   `user://update/` folder (`Updater.cleanup()`, called from `GameMenu._ready`).

Saves and settings live in `user://` (`%APPDATA%`) and are never touched.

## Error handling

Every failure leaves the installed game exactly as it was and shows a message with the "open the
download page" button. Rate limit or network problems during the check are silent. A failure while
downloading removes the partial file. A second click while a download runs is ignored.

## Security notes (to be told to Theodore, not hidden)

The `.sha256` asset sits in the same release, so it protects against a damaged download, not
against someone who controls the GitHub account. Only URLs under the repository's release path are
followed. The request reveals the player's IP address to GitHub and nothing else. The unsigned exe
may still trigger SmartScreen on the first manual install; files the game downloads itself do not
carry the "downloaded from the internet" mark, so updates do not.

## Release script (`tools/release.py`, run only when Theodore asks for a release)

Checks the branch is `main`, the tree is clean and `config/version` equals the requested version;
runs `godot --headless --export-release "Windows Desktop" build/GeorgeAdventures.exe`; builds
`build/George-Adventures-<version>-win64.zip` (exe + the two launcher .bat files); writes the
`.sha256` file; takes the section for this version from `CHANGELOG.md` as the notes; then
`gh release create v<version>` (not `--prerelease`) with both assets. `--dry-run` stops before any
upload. `export_presets.cfg` moves out of `.gitignore` into the repo (it holds no secrets) so the
build is reproducible; the launcher .bat files move into `tools/launchers/`.

## Version 1.0.0

`config/version` = `1.0.0`; CHANGELOG gets a 1.0.0 entry (the updater, the version label, the
launchers, what 0.16-beta had); README gets a download/update section. The first release is made
only when Theodore asks.

## Testing

Headless (`godot --headless --script tools/<name>.gd`):
- `update_logic_test`: version parsing and ordering (including `0.16-beta` < `1.0.0`, equal numbers
  with and without suffix, garbage), `pick_release` over a fake JSON list (skips drafts and
  pre-releases, skips older, needs both assets, picks the newest), `parse_sha256`, `url_allowed`,
  `safe_entry_name`, `notes_head`.
- `updater_install_test`: builds a zip with a fake exe and a bat in a temporary folder, runs the
  extract and swap against a fake install directory (a copy of a dummy exe file): the new file is in
  place, `.old` exists, `.new` is gone, a not-writable target fails without changing anything, a
  zip entry with `../x` is refused, the rename rollback works, `cleanup()` removes leftovers.
- `updater_flow_test`: a local Python `http.server` serves a fake releases JSON, the zip and its
  `.sha256`; a real `Updater` (pointed at `http://127.0.0.1:<port>` in test mode, which relaxes
  `url_allowed` only for that prefix) goes CHECKING → AVAILABLE → DOWNLOADING → VERIFYING, with a
  correct checksum succeeding and a wrong one ending in `FAILED` with the zip deleted; the
  `check_updates` flag off makes no request.
- `settings_update_test`: the flag round-trips through `settings.json`, default true.
Windowed:
- `updatemenutest`: the title menu with a faked available update shows the panel, version label and
  the settings checkbox (screenshot), "Αργότερα" hides it, and the existing `menutest` still passes.
Optional manual: `updater_live_test` calls the real API read-only and prints what it found.

## Open decisions after this spec

LICENSE for the public repository (Theodore to choose; KayKit assets are CC0 and need only a
credits line in the README).
