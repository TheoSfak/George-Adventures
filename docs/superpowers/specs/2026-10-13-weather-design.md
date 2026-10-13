# Weather: fog, rain and storms in the village (design)

Date: 2026-10-13. Backlog item C of `HANDOVER.md`. Approved by Theodore in chat ("proxora egrino").

## Goal

The village gets changing weather: clear, fog, rain and thunderstorm. It changes at random with smooth transitions, looks and sounds like weather (grey sky, thick fog, rain falling around George, lightning, thunder, wet ground) and **does not change gameplay**. Indoors, in the catacombs and in the Frontier there is no weather.

## Decisions already made (do not ask again)

- Weathers: **clear, fog, rain, storm** (no snow in the village; the Frontier keeps its own snow look).
- **Atmosphere only**: no change to damage, enemy senses, speed, quests, the invasion or the tests.
- **Random with smooth transitions**: every 2 to 5 real minutes a new state is picked by weight; blending takes about 25 s.
- Rain technique: **`GPUParticles3D` that follows George** (one draw call, density scales with intensity).
- Extras that Theodore saw and approved with the design: a Greek message when the weather changes, a weather icon next to the clock, and **F6** to change the weather by hand (to try it).

## Architecture

New node `Weather` (`scripts/weather.gd`, `class_name Weather`, node name `"Weather"` in `scenes/main.tscn`, group `"weather"`). It owns the weather state and its effects; **`DayNight` keeps owning the environment** and only reads four numbers from `Weather` in `_apply` (so there is one writer of `Environment`).

```
Weather (state machine, 4 blended values, rain particles, lightning, messages)
   | reads: Interiors.is_inside()/in_region()
   v
DayNight._apply   -> sky colours, sun energy, fog (reads weather.overcast / fog / flash)
Terrain.set_wetness -> ground and path shaders (called by Weather)
SoundManager      -> rain loops, quieter birds/crickets, wind, thunder (reads weather.rain / storm)
HUD               -> weather icon in the clock capsule, message feed (Player.message)
```

### State machine

- `enum State { CLEAR, FOG, RAIN, STORM }`, `var state := State.CLEAR`.
- Target values per state (starting values, tuned by screenshots in the look task):

| state | overcast | fog | rain | storm |
|---|---|---|---|---|
| CLEAR | 0.0 | 0.0 | 0.0 | 0.0 |
| FOG | 0.5 | 1.0 | 0.0 | 0.0 |
| RAIN | 0.75 | 0.25 | 0.7 | 0.0 |
| STORM | 1.0 | 0.35 | 1.0 | 1.0 |

- The four values glide to the targets with `move_toward` at 1/25 per second (about 25 s for a full change; 6 s when forced by F6).
- Timer: after each change the next one comes after `randf_range(120, 300)` seconds of real time (it runs while the game runs, not while the menu pauses the tree).
- Pick: `static func pick_next(current: State, rng) -> State`. Weights CLEAR 45, FOG 20, RAIN 25, STORM 10; never the current state; **STORM only after RAIN** (CLEAR/FOG go through RAIN first, STORM can go back to RAIN or CLEAR).
- Starts CLEAR on every launch and after loading a game. **Weather is not saved** (like potion buffs).
- Public, already faded values (what everybody else reads): `overcast`, `fog`, `rain`, `storm`, `flash` (0..1, only during a lightning flash). They are the blended values multiplied by `outdoor` (0..1): `outdoor` glides to 0 in 1.5 s while `Interiors.is_inside()` or `Interiors.in_region()` (catacombs, houses, Frontier) and back to 1 outside. The internal blend keeps running underneath, so stepping out of a house into the middle of a storm is correct.
- API: `force(state: State, fast := false)`, `cycle()` (F6), `state_name() -> String` (Greek), `static pick_next`, `step(delta)` (called by `_process`, public so a headless test can drive time).

## Look

**Sky and light (in `DayNight._apply`, outdoors only, as today):**
- `top`, `horizon`, `fog colour` are mixed toward a grey of the same brightness by `overcast * 0.8`.
- Sun energy `*= lerpf(1.0, 0.35, overcast)`; moon energy `*= lerpf(1.0, 0.5, overcast)`.
- `fog_density = lerpf(0.0006, 0.0011, darkness()) + fog * 0.0045` (starting value; fog must stay readable: enemies at the well, 14 m from the square edge, must remain visible. Tuned by screenshots).
- `shaders/sky.gdshader` gets `uniform float overcast` (fades the sun disc, the moon disc and the stars by `1 - overcast`) and `uniform float flash` (adds a cold white-blue to the whole sky). `DayNight` sets both.
- Lightning also raises `ambient_light_energy` by `flash * 1.5` for the flash.

**Clouds:** `Village/Clouds` are 14 KayKit models. Weather gives all their meshes one shared `StandardMaterial3D` as `material_override` whose albedo goes from white to dark grey with `overcast` (the models are plain white, nothing is lost).

**Wet ground:** `ground.gdshader`, `path.gdshader` and `patch.gdshader` get `uniform float wet = 0.0;` and darken the albedo by `0.28 * wet` (the clean look at 0). `Terrain.set_wetness(v: float)` sets it on `_ground_mat`, `_path_dirt`, `_path_cobble` and the patch material. `wet` follows `rain` but dries slowly (it lags: rises with rain, falls at 1/90 per second), so the ground stays dark for a while after the rain stops.

## Rain and lightning

- `GPUParticles3D` child of `Weather`, repositioned to the player every frame (box 36 x 22 x 36 m starting 14 m above George, no per-particle collision). Fixed `amount` 2400, intensity through `amount_ratio = rain`; one streak quad per drop (`QuadMesh`, unshaded, translucent white-blue, `TRANSFORM_ALIGN_Y_TO_VELOCITY`), speed about 28 m/s down with a slight tilt, lifetime 0.7 s, no shadows. Hidden when `rain < 0.02` and indoors.
- Storm: while `storm > 0.6`, every 6 to 18 s a flash (double flicker: 0.06 s on, 0.05 s off, 0.14 s on with a decay) drives `flash`; the thunder sound starts 0.3 to 2.0 s later (distance of the lightning).
- No splashes, puddles or wind on the grass (out of scope).

## Sound (all synthesized in `tools/audio/sfx.py`, regenerate with `python tools/gen_audio.py sfx rain thunder`)

- New loops `amb_rain` (steady rain on the meadow) and `amb_rain_roof` (rain on a roof, duller, used inside houses, the tavern and the church); new one-shots `thunder` (2 variants, deep and rolling).
- `SoundManager._update_ambience`: `amb_rain` volume follows `rain` (`-60` dB at 0 up to about `-3` dB at 1) outdoors only; `amb_rain_roof` while inside a building; nothing in the catacombs or the Frontier. `amb_day` and `amb_night` drop up to 18 dB as `rain` goes to 1; `wind_loop` gains up to 4 dB in a storm.
- Thunder is played flat with `Sfx.ui("thunder")` (quieter, about 10 dB, inside a building).
- Music is not changed.

## Boundaries

- Indoors (`Interiors.is_inside()`), in the catacombs and in the Frontier: no particles, no fog or overcast (DayNight already leaves the environment alone indoors; in the Frontier `outdoor` fades the values to 0), no lightning flash; only the muffled rain loop inside buildings.
- The night invasion and the day/night cycle are unchanged; fog and rain simply sit on top of them.
- The minimap picture (`Minimap._capture_world`) is taken once in the first frames of the game. The weather always starts CLEAR and the first change comes after at least 120 s, so the capture never sees rain, fog or wet ground; `weather_test` asserts that, so `minimap.gd` needs no change.

## HUD

- **Messages** (in Greek, through `Player.message`, only when `outdoor` > 0.5): `WEATHER_FOG` "Η ομίχλη πέφτει πάνω στο χωριό…", `WEATHER_RAIN` "Άρχισε να βρέχει…", `WEATHER_STORM` "Μπουρίνι! Ακούγονται βροντές…", `WEATHER_CLEAR` "Ο ουρανός καθαρίζει." (in `scripts/strings_el.gd`).
- **Clock icon:** the capsule next to the time shows `cloud` when `fog > 0.5` or `overcast > 0.5` with no rain, `rain` when `rain > 0.3`, `storm` (cloud with a bolt) when `storm > 0.5`; otherwise the usual sun or moon. Three new code-drawn icons in `scripts/icons.gd`.
- **F6** (physical key, like F11 and F12, handled in `Weather._unhandled_input`; not rebindable) cycles CLEAR, FOG, RAIN, STORM, CLEAR with a 6 s blend and shows the message of the new state. Added to `Strings.CONTROLS_HELP` ("F6", "Αλλαγή καιρού").

## Files

| File | Change |
|---|---|
| `scripts/weather.gd` (new) | The node: state machine, blended values, rain particles, lightning, messages, F6, wetness and cloud tint. |
| `scenes/main.tscn` | Node `Weather`. |
| `scripts/daynight.gd`, `shaders/sky.gdshader` | Read the four numbers, `overcast` and `flash` uniforms. |
| `shaders/ground.gdshader`, `path.gdshader`, `patch.gdshader`, `scripts/terrain.gd` | `wet` uniform and `set_wetness`. |
| `scripts/sound_manager.gd`, `tools/audio/sfx.py`, generated `sfx_ids.gd`, `assets/audio/sfx/*` | Rain loops, thunder, ambience mixing. |
| `scripts/hud.gd`, `scripts/icons.gd`, `scripts/strings_el.gd` | Clock weather icon, messages, help line. |
| `tools/weather_test.gd`, `tools/weathershot.gd` (new) | Tests and screenshots. |
| `CLAUDE.md`, `HANDOVER.md`, `CHANGELOG.md` | Documentation (unreleased `0.15-beta`). |

## Testing

- **`weather_test` (headless, drives `step(delta)`):** `pick_next` over 10000 draws never repeats the current state, produces STORM only from RAIN, and has the order CLEAR > RAIN > FOG > STORM in frequency; `force("storm")` reaches the target values within 30 s of simulated time; going indoors fades the effective values to 0 and back; the Frontier region does the same; DayNight with a storm has a higher `fog_density` and a lower sun energy than with clear sky at the same hour; the rain particles are hidden indoors and visible in rain; `SoundManager` targets: `amb_rain` above `-60` dB when it rains outdoors, `amb_rain_roof` only inside a building; the clock icon id for each state; F6 cycles the four states; the save file has no weather key.
- **`weathershot` (windowed, 1920x1080):** screenshots of clear, fog, rain, storm (with a forced flash) by day, rain and fog at night, a house interior while it rains, and the fps of each (`PERF` lines, target 58 or more, 60 expected; baseline at night is the tightest because of the lights).
- **Regression:** `perftest` (day) and `perftest -- night`, `daytest`, `eventtest`, `minimaptest`, `audiotest`, `savetest`, and the headless suites of the fishing and Frontier work.

## Risks and how they are handled

- **Look** (rain streaks too thick or too faint, fog hiding enemies, flash too harsh): the numbers above are starting values; the screenshot task looks at every picture and tunes (dock-style visual bar check as in the fishing plan); if something cannot be fixed it is reported to Theodore with the screenshot paths.
- **Frame rate:** one particle system with a fixed amount and `amount_ratio`; shader uniforms cost nothing; if `perftest -- night` under rain drops below 58 fps, lower the particle `amount` before anything else.
- **Single owner of the environment:** weather never writes to `Environment` itself; only `DayNight` does (a second writer would fight it every frame).
- **Sound:** the new loops and thunder are synthesized and cannot be heard by Claude; they are checked with `audiotest` numbers only, and Theodore judges them by ear (backlog item H).

## Out of scope

Snow in the village, wind sway on grass and trees, puddles, rain splashes and ripples on the pond, weather affecting quests or combat, a forecast or a weather map, saving the weather, weather in the Frontier or the catacombs, rain dripping through interiors.
