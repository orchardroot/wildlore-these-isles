# Wave 54, air: sound, sky and season

## What was built
- **Ten silent music ids.** The ids `pub`, `church`, `museum` and `castle` (ten Carlisle, Borders and Biot zones) had no file. Four new tracks, composed in `tools/music/{pub,church,museum,castle}.gd` and listed in `tools/sfxgen.gd`: `godot --headless --path . -s res://tools/sfxgen.gd -- pub church museum castle`.
- **Rooms sound like rooms.** `Ambience.room_kind` reads a room's music and the words in its id. Beds: `amb_pub`, `amb_church`, `amb_shop`, `amb_home`, `amb_works`; anything else keeps `amb_interior`. Caves and `ambience` overrides win.
- **Emitters.** New `world/sound_emitters.gd` (one hook line in `overworld._build_zone_node`). One polyphonic player; fire (fireplace, brazier, range cooker), clock, stream (`~`, `w`) and shore (sea tiles touching land). The nearest source of each kind is polled 4 times a second, easing per frame; no allocation in the poll. Loops: `em_fire`, `em_clock`, `em_stream`, `em_shore`.
- **Night.** `amb_night_town`, `amb_night_coast`, `amb_night_city` (a town after dark, shore with a buoy bell, city with a distant siren). The country `amb_night` is unchanged; moor and caves stay the same all night.
- **Weather.** Thunder (`thunder`, `thunder_far` sfx) in a downpour (every 28-75 s) or a gale (55-130 s), timed in `SkyAndLight`, heard indoors too (muffled, far). A soft double lift of the whole picture with it, only when Reduce Flashing is off and outdoors (peak alpha 0.09). Fog and frost close a low-pass on a new `Ambience` bus (fog 2.8 kHz and -3 dB, frost 5 kHz and -2 dB), outdoors only. Rain (and rain on the roof) carries into battle at -14 dB while the bed hushes; the old whole-player fade is gone.
- **Sky.** `art/shaders/night_sky.gdshader` and `world/night_sky.gd`: stars, and the moon in its real phase for the date (Julian-day maths against the 6 Jan 2000 new moon, tested against known eclipse and quarter dates). The moon rises left, sets right by the real hour angle (full moon up all night, new never). Twinkle is off under Reduce Flashing and on Low. By day the background is a plain colour as before (`BG_SKY` only while there is something to show). Caveat: the game's camera never sees above the horizon, so the sky is laid on the picture and only shows where the world ends (past an edge, small zones, photo mode).
- **Season on the ground.** `ground.gdshader` takes `spring`, `autumn`, `winter`, set by `Seasonal.tint_ground` beside `Seasonal.tint` (same region rules, so tropics stay green). Grass only (UV.y); roads, paths and floors are unchanged.
- **Small things.** Chapels ring a small bell (`bell_small`, pitched up) where there is no cathedral; the hour is struck as many times as it is (7 to 21 only), 2.1 s apart. A `text_blip` sfx every few letters in dialogue, new setting "Text blips" (default on, `Settings.text_blip`).

## New audio and how it was made
All through the existing generators, no samples. Beds and emitter loops (12): `tools/audio/ambgen.gd` (recipes in `ambience_recipes.gd`): `godot --headless --path . -s res://tools/audio/ambgen.gd -- amb_pub amb_church amb_shop amb_home amb_works amb_night_town amb_night_coast amb_night_city em_fire em_clock em_stream em_shore`. Sfx `thunder`, `thunder_far`, `text_blip`: `tools/sfxgen.gd`. Music (4): `tools/sfxgen.gd`. Files in `audio/ambience`, `audio/sfx`, `audio/music`.

## How to hear it
Args go after `--`; `tools/shot.sh` is silent, so run the game normally to listen, e.g. `godot --path . -- --boot=<zone>@x,y --clock=HH:MM --weather=<w> --date=MM-DD`.
- Pub bed, fire, clock and the new tune: `--boot=boston_pub` (walk to the hearth, then away). Music alone: `--boot=carlisle_statepub`.
- Church: `--boot=galway_cathedral`; castle music `--boot=carlisle_castle`; museum music `--boot=carlisle_tullie`; shop bed `--boot=boston_shop`; home `--boot=bath_home1`.
- Stream and shore: any water zone, e.g. `--boot=faerie_glen` (pond); a coastal town with `~`/sea tiles for the shore.
- Night beds: `--clock=23:00` with `--boot=macclesfield` (town), a coast zone, `--boot=york` or another city.
- Thunder: `--weather=downpour` or `--weather=gale`, wait up to about 20 s for the first (first strike comes at 40% of a normal gap).
- Fog or frost damp: `--weather=fog` / `--weather=frost`, compare with `clear`.
- Rain in battle: `--weather=downpour` then walk into grass, or `--battle=<species>` with `--weather`.
- Bells: `--boot=<town with a cathedral or chapel>` and `--clock=09:58`; stand outdoors.
- Text blip: any dialogue; Settings > Text blips turns it off.
- Sky: `--clock=23:30 --date=11-23 --photo --photo-view=0,-14,1.35`.

## Numbers
Beds sit -29 to -37 dB RMS (loudness test enforces at least 12 dB under the music). Emitters -26 to -34. Emitter range: fire 9 tiles, clock 7, stream 11, shore 15; at most 48 sources per kind per zone.

## Tests
`tests/audio/test_ambience.gd` (extended), `tests/world/test_sound_emitters.gd`, `tests/world/test_night_sky.gd`. Existing night-bed asserts were updated to the new beds.

## Screenshots (`docs/screens/w54/`)
`sky_night_moon.png`, `sky_crescent_today.png`, `season_{spring,summer,autumn,winter}.png` (faerie_glen). At the integrator's request, no more were taken. Skipped from the brief: nothing else was listed for air beyond these two items. Lightning flash was not captured.

## Unsure / for the integrator
- Moon and stars only show where the background does; in ordinary play that is edges and small zones. Moon sits in the top band and can be hidden by far trees.
- `fog_sky_affect` is 1.0 by day (as before) and 0.0 only while the sky shows.
- Hook lines in shared files: `overworld.gd` (one line), `settings.gd` and `settings_screen.gd` (the blip setting), `dialogue_box.gd` (blip).
- Not run: the full suite, and I did not listen to the tracks (levels and loop seams are test-checked, melodies are not judged by ear).
- Bell for every town with a chapel may be a lot of bells; trivial to restrict in `Ambience.accents`.
