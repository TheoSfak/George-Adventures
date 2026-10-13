# Graphics setting with automatic restart — design

Date: 2026-10-13. Status: requested by Theodore ("βάζω ρύθμιση «Γραφικά» στο μενού με αυτόματη επανεκκίνηση").

## Problem

On a weaker or older PC the normal graphics mode (Vulkan, Forward+ renderer with SSAO) drew black
surfaces and noisy pixels. 1.0.0 only ships `Play-Mobile-Renderer.bat` / `Play-Compatibility-Renderer.bat`
as a manual workaround. The renderer cannot be changed while the game runs, so a setting must restart the game.

## Behaviour

- Settings page (title and pause menu) gets a row **Γραφικά**: a drop-down with three modes, a button
  **Εφαρμογή και επανεκκίνηση** and, below, a one-line description of the chosen mode (the page has no room for
  longer labels; a problem message replaces the description line instead of adding a line).
  - `forward_plus` — "Υψηλά" (the project default, Vulkan Forward+, SSAO); its description says "αν τα γραφικά φαίνονται μαύρα ή σπασμένα, δοκίμασε «Μεσαία»"
  - `mobile` — "Μεσαία" (Vulkan Mobile renderer, no SSAO, looks almost the same; for weaker or older cards)
  - `gl_compatibility` — "Συμβατά" (OpenGL, paler colours; for very old cards)
- The drop-down starts on the renderer in use (`RenderingServer.get_current_rendering_method()`); the button is
  disabled while the selection equals it.
- **How the choice persists:** the game writes `override.cfg` next to the exe (Godot reads it at start and it
  overrides `rendering/renderer/rendering_method`; verified with the real exe: no file = Forward+, `mobile` =
  Vulkan Forward Mobile, `gl_compatibility` = OpenGL). Choosing `forward_plus` deletes the file again, but only
  if it carries the game's own marker comment (`; written by the game's graphics setting`), so a hand-made
  `override.cfg` is never touched or deleted. No settings.json entry (the file and the running renderer are the truth).
- **Apply:** from the pause menu the game is saved first (`GameMenu.autosave(true)`); then `override.cfg` is
  written, the exe is started again with `--rendering-method <id>` (the command line wins over the file) plus the
  user arguments after `--`, and the old instance quits.
- **Failures** show a Greek message under the row and change nothing:
  - not the exported game (editor/script runs; the exe path would be Godot's own): "Η αλλαγή γραφικών λειτουργεί μόνο στο εξαγόμενο παιχνίδι (το αρχείο exe)." Nothing is ever written next to the editor.
  - the folder is not writable: "Ο φάκελος του παιχνιδιού δεν επιτρέπει αλλαγές. Χρησιμοποίησε το Play-Mobile-Renderer.bat."
- The updater is unaffected: `override.cfg` is not part of the update zip and `UpdateInstaller.cleanup` only
  removes `.old`/`.new` files; the updater's own restart already passes the renderer in use.

## Components

- `scripts/graphics_mode.gd` (`class_name GraphicsMode`, static, no autoload references): `ids()`, `is_valid(id)`,
  `label(id)`, `description(id)`, `current()`, `can_restart()`, `override_text(id)`, `write_override(dir, id) -> bool`,
  `read_override(dir) -> String`, `restart_args(id, user_args) -> PackedStringArray`, `apply(id, dir) -> Dictionary`
  (`{"ok": bool, "error": "" | "editor" | "invalid" | "write"}`; on success it has already started the new
  instance when `restart` is allowed; the caller quits).
- `scripts/strings_el.gd`: `SET_GRAPHICS`, `GFX_HIGH/MEDIUM/COMPAT`, `GFX_DESC_HIGH/MEDIUM/COMPAT`, `GFX_APPLY`, `GFX_ERR_EDITOR`, `GFX_ERR_WRITE`.
- `scripts/game_menu.gd`: the row in `_build_settings` (the key list gets 90 px shorter to make room), the
  apply handler (autosave, `GraphicsMode.apply`, quit).

## Tests

- `graphics_mode_test` (headless): ids and labels, `override_text`, `write_override`/`read_override` in a
  temporary folder (mobile writes, forward_plus deletes only its own file, a foreign `override.cfg` survives),
  `restart_args`, `apply` refuses with "editor" in a script run and writes nothing, `apply("bogus")` is "invalid".
- `graphicsmenutest` (windowed): the settings page shows the drop-down with three entries on the current
  renderer, the button is disabled until another mode is chosen, pressing it in the editor shows the editor
  message and writes no file; screenshot of the page.
- Manual with the real exe (done in the verification step): an `override.cfg` produced by `GraphicsMode` next to a
  copy of the exported exe makes it start with Forward Mobile / OpenGL.

## Not included

No automatic detection of weak graphics cards, no per-setting quality sliders (shadows, MSAA), no
change of the project default renderer. If the Mobile mode fixes the weak PC, a later change can pick it automatically.
