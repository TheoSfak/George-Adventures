# Voice-over for the story dialogue — design

Date: 2026-10-14. Status: requested by Theodore ("βάζουμε και TTS της Microsoft για ηχητικές αφηγήσεις μέσα στο παιχνίδι"),
design approved in chat. Decisions: scope = all story dialogue (prologue, every story NPC, shop greetings; not the villagers'
gossip); the text box types in step with the voice; voices from the demo Theodore listened to (narrator = Nestoras 1b,
men = Nestoras natural 1a/2a, women = Athina natural).

## Problem

All story dialogue is text only (`HUD.show_dialogue`). Theodore wants spoken Greek. Free tools only; the game is exported as a
Windows exe and works offline, so nothing may call a speech service while playing and no key may ship in the exe.

## Approach

Pre-generate the audio at development time with Azure AI Speech (free tier F0, resource in North Europe; neural voices
`el-GR-NestorasNeural` and `el-GR-AthinaNeural`), commit the mp3 files, and let the game look each line up by a hash of
its voice parameters and text. Editing a line only means re-running the generator, which makes just the changed file.
Rejected: IDs on every line in the data files (a big refactor of `quest_data.gd`, brittle), and speech at runtime
(needs a key inside the exe or software on the player's PC).

## Behaviour in the game

- When a dialogue line is shown and a voice file exists for it, the voice plays and the typewriter takes as long as the voice
  (`length + 0.15 s`); the text blips (`dialogue_blip`) are not played for a voiced line.
- First click / Space / Enter while the text is still typing shows the whole line at once and the voice keeps speaking;
  the next press goes to the next line and cuts the voice. After the last line the voice is stopped too (also when a
  shop window opens next).
- No file (a line the generator has not seen, a villager) = silent, exactly like today. Nothing ever errors.
- While a voice plays, music and ambience are ducked by 6 dB (0.25 s down, 0.5 s up); sound effects are not.
- The voice pauses while the game is paused (pause menu) and resumes after.
- Settings page: a fifth slider **Φωνές** (default 1.0, saved as `volumes.voice` in `settings.json`; an old file without
  it loads with the default). The text is always shown, there is no separate subtitle option.
- Credits page gets a line "Φωνές: Microsoft Azure AI Speech"; `THIRD_PARTY_NOTICES.md` gets the same note.

## Voices

`VoiceData.PROFILES` (id → `{voice, rate, pitch}` as Azure SSML values):

| profile | voice | rate | pitch | who |
|---|---|---|---|---|
| `narrator` | Nestoras | -5% | +0st | the prologue (speaker `Strings.NARRATOR`) |
| `man` | Nestoras | +0% | +0st | Παπά-Σταύρος, Νικήτας (both entries), Βασίλης, Στέλιος |
| `man_slow` | Nestoras | -4% | +0st | Γέρο-Γιάννης, Μοναχός Ιλαρίων |
| `man_quick` | Nestoras | +4% | +0st | Μανώλης, Θανάσης, Αντρέας |
| `woman` | Athina | +0% | +0st | Κυρά-Μαρία, Αδελφή Θεοδώρα, Ελπίδα, Κυρά-Ελένη |

`NPC_PROFILES` maps every id of `QuestData.NPCS` to a profile. The speaker handed to `show_dialogue` is the NPC's display
name, so `VoiceData.profile_for(speaker)` finds the NPC by name (`Strings.NARRATOR` → `narrator`; unknown name → `""`).
The two `Νικήτας ο Σιδεράς` entries share one profile (a test checks that same-named NPCs agree). The table is data:
changing a profile only means re-running the generator.

## Components

- `scripts/voice_data.gd` (`class_name VoiceData`, static, pure: no scene access, no autoload references; mentions
  `QuestData`, `ShopData`, `Strings`):
  `PROFILES`, `NPC_PROFILES`, `DIR` (`res://assets/audio/voice/`), `profile_for(speaker) -> String`,
  `key(profile, text) -> String` = first 16 hex characters of `sha1(voice + "|" + rate + "|" + pitch + "|" + text)` of the
  UTF-8 bytes (the parameters are in the hash, so changing a profile makes new files and never plays a stale one),
  `path(profile, text) -> String`, and `lines() -> Array` = every voiced line as `{speaker, profile, text}`:
  the prologue (narrator); per NPC the `idle` lines; per quest `offer` (giver), `complete` (turn-in) and `progress`
  (giver and turn-in, as `Quests.dialogue_for` shows it to both); and for every NPC with a `"shop"` key the `greeting`
  lines of that `ShopData.SHOPS` entry (speaker = the NPC's name, as `Npc.interact` passes it). The event quest
  (`andreas`) is covered by the same loop.
- `scripts/voice_over.gd` (`class_name VoiceOver`, static facade like `Sfx`): `play(speaker, text) -> float` (seconds, `0.0`
  when there is no profile or no file or no SoundManager), `stop()`, `is_speaking() -> bool`. It finds the node in group
  `sound_manager`.
- `scripts/sound_manager.gd`: bus `Voice` (added with the other three in `_setup_buses`), one `AudioStreamPlayer`
  `_voice` on it, `play_voice(stream) -> float`, `stop_voice()`; an `AudioEffectAmplify` on the `Music` and `Ambient`
  buses whose volume the manager tweens to -6 dB while `_voice.playing` (this is independent of the user's sliders, which
  `GameSettings` writes to the bus volumes); `_voice.stream_paused = get_tree().paused` each frame (the node already runs
  in `PROCESS_MODE_ALWAYS`).
- `scripts/game_settings.gd`: `BUS_NAMES["voice"] = "Voice"`, `DEFAULT_VOLUMES["voice"] = 1.0`, `BASE_DB["voice"] = 0.0`
  (a first guess, to be tuned by ear like the other buses).
- `scripts/game_menu.gd`: the `["voice", Strings.SET_VOICE]` row in the volume loop of `_build_settings` (check that
  the page still fits, as with the graphics row).
- `scripts/hud.gd`: `_show_line()` asks `VoiceOver.play(_dlg_name.text, line)`; a result `> 0` sets the typewriter duration
  to `result + 0.15` and skips the blips; `_advance_dialogue()` calls `VoiceOver.stop()` when moving on or when the
  panel closes. The speaker name shown is already what the data uses, so no caller changes (`npc.gd`, prologue).
- `scripts/strings_el.gd`: `SET_VOICE := "Φωνές"` and the credits line.
- `tools/dump_voice_lines.gd` (Godot, headless script): writes `tools/_voice/lines.json` =
  `{"profiles": {...}, "lines": [{"speaker", "profile", "text", "key"}]}` from `VoiceData`. The JSON is the only thing the
  generator reads, so the profiles and the hash are defined once, in GDScript.
- `tools/gen_voice.py` (Python 3, standard library only): reads `lines.json`; for every `key` without
  `assets/audio/voice/<key>.mp3` it POSTs SSML (`xml:lang='el-GR'`, `<voice name=...><prosody rate pitch>`, text escaped for
  XML) to `https://<region>.tts.speech.microsoft.com/cognitiveservices/v1` with `Ocp-Apim-Subscription-Key` and
  `X-Microsoft-OutputFormat: audio-24khz-48kbitrate-mono-mp3`. Key and region come from the user environment variables
  `AZURE_SPEECH_KEY` and `AZURE_SPEECH_REGION` (never written to the repo, never printed). Options: `--dry-run` (list what
  is missing and the character count, no network), `--prune` (delete mp3 files, and their `.import` files, whose key is
  not in the JSON), `--only <word>` (only lines containing it). A 429 or 5xx is retried three times with a growing pause;
  a line that still fails is reported, the others go on, the exit code is 1. The script recomputes every key itself
  (`hashlib.sha1` of the same UTF-8 string) and stops if one differs from the JSON.
- `.gitignore`: `tools/_voice/`.
- After generating: `godot --headless --import` creates the `.mp3.import` files; they are committed with the mp3 files, like the
  existing `.wav.import` files.

Roughly 17,000 characters, about 20 minutes of speech, 5 to 8 MB of mp3 (6 KB/s). One full run is about 3% of the monthly
free allowance (500,000 characters). The existing `voice_blip` sound effect (villager babble) is unrelated and stays.

## Tests

- `voice_data_test` (headless): every id in `QuestData.NPCS` has a profile and all profiles exist; same-named NPCs agree;
  `profile_for` of the narrator, a story NPC and an unknown name; `lines()` is not empty, has no empty text and only known
  profiles, and contains the prologue; `key` is stable (a pinned value computed with Python for one Greek sentence and
  profile), differs when the rate changes, and `path` has the form `DIR + key + ".mp3"`.
- `voice_files_test` (headless): every entry of `VoiceData.lines()` has its mp3 (`ResourceLoader.exists`). This is the guard
  that fails when a line was edited and the generator was not run again.
- `voice_player_test` (headless, with a `SoundManager` node): `VoiceOver.play` of a real voiced line returns a length above
  zero; of an unknown speaker or text returns `0.0`; without a SoundManager returns `0.0`; the `Voice` bus exists; the
  `Music` amplify effect is below 0 dB while a voice runs and back at 0 dB after `stop()` plus the fade. It asserts on return
  values and bus state, not on audible output (the headless audio driver is a dummy).
- `dialogue_voice_test` (headless, `HUD`): a voiced line gives a typewriter time equal to the voice length plus 0.15 s and
  no blips; a line without a file keeps the old time and the blips; the voice is stopped after the last line and after a
  shop greeting hands over to the shop window.
- The settings checks (default 1.0, an old `settings.json` without `voice`, the `Voice` bus follows the slider, 0 is
  silent) are part of `voice_player_test`, which backs up and restores the real `settings.json`.
- `menutest` and `graphicsmenutest` keep passing; a screenshot of the settings page confirms five sliders fit.
- Manual, by ear (Theodore): the prologue and one quest of each voice; level of the `Voice` bus against music and effects.

## Failure behaviour

No key or region: `gen_voice.py` stops with a message that names the missing variable. Network or quota errors: see
above. In the game nothing depends on the files: a missing or unreadable mp3 is silence.

## Not included

Villager gossip and the stage musicians (their speaker names are random), boss and invasion banners, English voices,
effects on the voices (reverb for the undead), pronunciation fixes (add a replacement table only when a word is read
wrongly), lip sync or talking animations, a separate subtitles option, a key to mute only the voices (the slider does it).
The release (version, changelog, Greek release notes) happens later through the usual release process.
