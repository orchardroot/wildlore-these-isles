# w51-places handoff

Branch `w51-places` (from int-w50). Places that didn't look like what they are, from the w50 critic's and world
sessions' leftovers. Full write-up: `docs/audit/w51_places.md`; before/after in `docs/screens/w51-places-*.png`.

- York Minster is its own pale limestone `minster` style (`world/landmarks_minster.gd`): twin west towers, great
  west window, portal, buttresses, central tower, transepts and the Rose Window. A keeper's hall now always keeps its
  gold board (`Signage._keeper_front`), which also restored Belfast Yard's and made St Michael's Tower's readable.
- Names squeezed past reading on their own board (Signage.MIN_EM): lectern for the small mills, a tablet across the
  York bars' drum towers. `SignSight.audit` reports name height and lettering that runs off its board;
  `tools/dev/sign_audit.gd` lists both (0 of 1,539). No board ever cut a name: "THE CAVERN (ISH" was the screen edge.
- `cathedral` fronts (Chester, Liverpool and about 30 more) have pointed lancets between buttresses.
- All 103 Sanctuaries dressed (`world/sanctuary_props.gd`): restoring cabinet, medicine shelf, baskets, noticeboard,
  posters; test keeps every person and the door reachable.
- Smaller: Kyteler's back door (new `back_door` prop), Wookey Hole braziers, moor gateposts, Honister Slate Mine
  re-dressed, picker "Field Station". Crypt arrival checked, already fine.
- Left: deed huts behind other buildings' doors (York allotment shed through the Minster, Lancaster, Whitby,
  Dingle); Llynnon Mill and the Laxey Wheel drawn as cotton mills; six signs hidden from their doors (sign sight).
- Merge note: `world/zone_builder.gd` gets additive lines in POINT_PROPS, CONTACT_SHADOWED and `_ctor`;
  `world/signage.gd` and `world/sign_sight.gd` (audit only) change; `ui/photo_mode.gd` gets a dev-only
  `--photo-view`. New class_names (MinsterStyle, SanctuaryProps, PlaceProps): run `--import` after merging.
- Checks: `tools/test.sh` 3025 passed, 2 failed (the Minster door rect was 0.84 wide, over test_feel_world's 0.8;
  fixed to 0.8, feel_world and minster re-run 0 failed), validate 0 errors, no SCRIPT ERROR;
  `tools/playtest.sh slice 2` PLAYTEST PASS (Maud won).
# w51-critic2 handoff

Branch `w51-critic2` (from int-w50). A new player's walk round the side content (overseas, islands, Party Pieces
venues and minigames, travel, map, Journal, jobs, festivals, post-game, field pieces), fixing what looked wrong.
Full write-up: `docs/audit/w51_critic2.md`; before/after in `docs/screens/w51-critic2-*.png`.

- Fixed: arriving inside a guide (Exeter passages, Castle of Mey); 14 residents standing in front of a doorstep or
  the Ascension landing; unreadable signs (in the sea off St Peter Port, Dundee, the Exe; Tintagel's Gallos;
  Llangollen); 28 props inside buildings (Oxford's oak, Anguilla's flagpole...); town-name boards on doorless houses
  abroad (Gaiman, Roscoff, Baddeck, Boston, Bristol, Tristan, Adamstown); tropical and southern trees and frost now
  keep their own year (`Calendar.foliage_tint_in`, `season_in`); a clearing round the sheepdog trials steward; a new
  `dartboard` prop in the five darts pubs; field piece hints ("Where to learn it:", real move names); "sticks of rock".
- Left for others: map info panel hides the west (HUD/menus); truncated name boards (w51-places); Guizer Magnus
  sprite; Braemar on snow in September; Grytviken church mesh. See the audit.
- Merge note: `world/zone_builder.gd` gets one line in POINT_PROPS and one match case for `dartboard`;
  `world/dressing.gd` a new function; `world/seasonal.gd`, `world/sky_and_light.gd`, `core/calendar.gd`,
  `core/field_spots.gd`, `world/field_spot.gd` small edits. About 60 zone files, small data edits each.
- Checks: `tools/test.sh` 3021 passed, 0 failed, validate 0 errors, no SCRIPT ERROR; `tools/playtest.sh slice 2`
  PLAYTEST PASS (Maud won).

# w50-critic handoff

Branch `w50-critic` (from int-w50). A new player's walk along the story by screenshot, fixing what looked wrong
outside the other w50 sessions' files. Full write-up: `docs/audit/w50_critic.md`; before/after in
`docs/screens/w50-critic-*.png`.

- Fixed: doorsteps on a town's south edge hid the player behind the tree belt (21 doors, now low hedges); the Tor
  arrival likewise; cathedral and Leeds Town Hall windows were inside the stone (`world/landmarks.gd`); all 102
  shops get a new `shop_shelf` prop; the Percy French plaque was lost in the Mournes spawn array (and a bad spawn now
  fails validation); trees hiding doors and boards moved; 16 signs moved out from behind tree belts; "car park".
- Left for others: the Standing toast lands on the zone card and runs off screen (HUD, w50-tf-world); York Minster
  crypt arrival (should be cured by w50-world's low south wall); York Minster colour needs a signage tweak first;
  starter picker "field station"; truncated venue boards; bare Sanctuaries.
- Merge note: `world/zone_builder.gd` gets three small additive lines for `shop_shelf`; w50-world edits other parts
  of the same file. `data/zones/chat_moss.json` and `ring_of_kerry.json` are touched by both, in different places.
- Checks: `tools/test.sh` 2996 passed, 0 failed, validate 0 errors, no SCRIPT ERROR (five "Parse JSON failed"
  lines come from tests that feed bad JSON on purpose); `tools/playtest.sh slice 2` PLAYTEST PASS (Maud won).
# w50-tf-large handoff

Branch `w50-tf-large` (from int-w50): the text-fit work finished for Large text, long nicknames and the Readable
font. Details and numbers in `docs/audit/w50_text.md` (last section).

## Results
- Text audit, all 122 screens: 0 problems at normal, `--text=large`, `--readable`, `--readable --text=large`, and with
  `--stress` at normal, Large and Readable+Large. Before: 168 on 41 screens at Large; 7 (normal) and 32 (Large)
  trimmed or spilling nicknames with `--stress`. `--text=largest` (not a target) has 144 on 43 screens.
- Before/after shots: `docs/screens/w50-large-{summary,races,exchange}-{before,after}.png`.
- Full `tools/test.sh`: 2997 passed, 0 failed, `validate: 0 error(s)`, no SCRIPT ERROR.
- Also fixed: the hint bar's "move" prompt (crossword, sheepdog, worm charming) showed "-"; it now says Arrows / D-pad.

## Notes for the integrator
- **Real bug fixed in `core/settings.gd`**: `apply_access` let go of `ui/theme.tres` after setting it, so once no menu
  held the theme the next load came back plain: the Readable font (and the theme's Large button size) could quietly
  vanish, and dev runs never had them. Settings now holds the theme. Expect buttons to look bigger with Large text
  everywhere that relied on the theme default (battle UI and overworld too: the other session's area, untouched).
- Shared files: `ui/ui_kit.gd` (new `sized`, `font`, `big_text`, `fit_scaled`, `row_label`; `fit_label`, `fit_size`,
  `fit_block`, `fit_column`, `fit_width`, `keep_fitted`, `line_height` changed as described in the doc),
  `ui/menu_base.gd` (header read-out shrinks to fit; hint bar fits at the Large size), `ui/casino_base.gd`
  (`fit_side`), `core/dev_args.gd` + `core/game_state.gd` (`--text=`, `--readable`), `core/settings.gd` (the held
  theme). `UIKit.fit_size` still takes drawn sizes; anything that passes its result to `UIKit.label` should use
  `fit_scaled` and set the override (as party and Ark now do), or it grows by a quarter with Large text.
- `fit_block`'s last argument (`_block_height`) is now a tier cut, not a bool; `test_fieldbook_teaching` updated.
- Behaviour touches: pause gains "Right: Read on" when Where next? still runs on; quest cards and Gazetteer plaques
  and peoples read on with Confirm (hint says so); with Large text the Noticeboard's standing card sits under the
  list, the bag shows the run of tabs that fits, the Summary's knack shares the entry's card.
- `tests/ui/test_text_fit.gd` runs a second audit (Large + Readable, 4 screens): the file takes about 20 s, 30 s on a
  busy machine.
- Not touched: battle_ui, overworld HUD, 3D signs, data/zones, dialogue (other sessions).

# w50-report handoff

Branch `w50-report` (from 5.2.1). An in-game "report a problem" key, so a bug can be flagged mid-play without
stopping. The previous HANDOFF.md (w49-games) is replaced here; it is still in git history.

## What it does
- **F9 anywhere** (overworld, battle, any menu, minigame, mid-dialogue) writes `user://reports/<YYYY-MM-DD_HH-MM-SS>/`:
  - `shot.png`: the last frame drawn, grabbed at the key press, before the toast exists.
  - `info.json`: version, time, platform, dev session or not, scene, open menus (Router names, bottom first), zone id
    and name, tile, facing, weather, clock and time of day, day, play time; in a battle both sides (species, level,
    hp, status, who is out) and the last 6 log lines; the dialogue or battle text on screen (only what has typed out).
  - `save.json`: the in-memory game through `SaveSystem.payload_of`, so the exact save format. Copy it over a slot
    (`saves/1.json`) to load the moment back. The real save slots are never touched.
- A toast, "Reported. Keep playing.", fades out. No pause, no menu.
- **Second press within 3 s**: a one-line note box mid-screen. Enter keeps the note (into `info.json`), Esc skips
  it. The game is paused while it is open (menus too, see below), so typing can't walk the player or play a minigame.
- On macOS the folder is `~/Library/Application Support/Godot/app_userdata/Wildlore/reports` (project.godot sets
  no custom user dir). `tools/reports.sh [count]` lists them newest first: when, zone and tile, scene, menu or
  battle, the note, and each folder's path.

## Where it lives
- `core/problem_report.gd` (new, pure apart from the file writes): fields, folder names, battle and creature briefs,
  menu names, the note tidy, `write` and `add_note`.
- `ui/report_key.gd` (new): the node. Game adds it in `_ready` (one line). It listens on the root window's
  `window_input` signal, which fires before any node's `_input`, so a menu that marks keys handled can't hide F9.
  Nothing per frame; the PNG and JSON are written on a WorkerThreadPool task (the save dict is deep-copied first).
- `core/input_setup.gd`: new `report` action, F9, no pad button. New `OPTIONAL` / `may_be_empty()`: an action may
  have an empty pad list without `sanitise` throwing the whole pad set back to defaults or `rebound` refusing to
  take its only pad button. Old settings files get F9 by default.
- Small additive hooks: `Router.open_menus()` and `Router.hold_menus()`, `DialogueBox.on_screen()`,
  `ControlsScreen.capturing()` (F9 doesn't report while you are binding a key), `SaveSystem.payload_of()` (the
  body of `save()` lifted out, behaviour unchanged).
- Controls page: the new row, and the help line now ends "F9 anywhere reports a problem." (the key name follows
  the binding). Cells lost 1 px of margin each so twelve rows and the help line fit (layout audit: ok).
- README controls table: one row.

## Dev switches
`--report-now[=seconds]` presses F9 (as a real key event) that many real seconds after the boot has settled
(a zone, battle or menu is up; default 3). `--report-note=<text>` then presses again and types the note. The game
quits a second after the report is on disk, so a dev run always ends. Release builds ignore both (DevArgs). Proof runs used `open -g` launches, never focus-taking:
`--boot=york@20,20`, `--battle=croakle` (with a note), `--menu=settings` (with a note), `--menu=pancake:dev`,
`--boot=york@20,20 --talk=sign:17,7` (the half-typed sign text landed in `dialogue`). All wrote the three files
with the right facts and a clean frame; no errors in the logs. The note box and toast were checked on screen.

## Tests
`tools/test.sh test_problem_report` (11) and `tools/test.sh test_report_key` (5). Full `tools/test.sh`: 2982 passed,
0 failed, validate 0 errors, no SCRIPT ERROR. `test_accessibility`'s
`_all_distinct` helper now allows an optional empty pad list.

## Notes for the integrator
- Early proof runs used a launcher whose kill step was broken (`pgrep -f "--report-tag..."` read as an option), so
  nine games were left running until the coordinator killed them. Fixed at the source: `--report-now` quits by itself.
- `tools/shot.sh` timing is not reliable for this on a busy machine: a long first load can count as one huge
  timer step, so the shot (and any scene timer) can fire mid-fade. That is why `--report-now` counts real time.
- While the note box is open the tree is paused and `Router.hold_menus(true)` makes the menu layer pausable (menus
  normally run through a pause because the Router is PROCESS_MODE_ALWAYS). Game's own `_process` is ALWAYS, so the
  clock and play time keep ticking for those few seconds. The Pedia popup, battle intro and journey scene are also
  ALWAYS; a note typed during one of those is the one rough edge.
- Reports are written for players too (it is a harmless folder). If that is not wanted in release builds, gate
  `add_child(ReportKey.new())` in `core/game_state.gd` on `OS.is_debug_build()`.
- Nothing is uploaded anywhere; Settings > Report a bug (the GitHub link) is untouched.
# w50-battle handoff

Branch `w50-battle`. Battle playback correctness and feel: plates that showed the end of a turn early, attacks that
landed after their hit, and some polish. The full list of paths checked is `docs/audit/w50_battle.md`.

## The cause, and the rule now
`Battle.take_turn` works out the whole turn before the UI plays it back, so a creature's own hp, status and stages
are already the end of the turn during playback. Every plate write a cue makes now goes through
`BattleFX.plates(cue, battle)`, which only reads the cue (so the event). If you add an event that changes what a
plate shows, put the value in the event (as `damage`, `switch` and `item` do) and handle it in `plates()`.
`tests/battle_ui/test_playback_plates.gd` will fail otherwise: it plays 120 seeded battles through the real HUD and
checks no plate changes before (or without) its own event.

## What changed
- Engine (`battle/battle.gd`): `item` events carry the target's `hp` and `status` after the item; `switch` events
  carry `status`; `cure_team` carries `cured` (field positions); a multi-hit's `hits` event goes before the first
  faint it caused.
- `battle_ui/event_player.gd`: item and switch cues pass those fields on; `hp_after_item` is gone (it guessed, and
  missed recoil, pricks and heals). `EventPlayer.verb()` for pair keepers ("send out", "want to battle").
- `battle_ui/fx.gd`: `plates()`, `heal_pos()`, `hit_time()`; an item on a benched creature no longer glows over the
  one on the field; a faint fades its plate; song, wave and Tidal Surge (`fx_signatures.gd`) land before the hit.
- `battle_ui/hud.gd`: plates track `hp_to` (where the bar is heading) and `status`; `sync(b)` (moved from the scene)
  compares with `hp_to`, so it no longer restarts a hit's drain; level-up grows bar and max together (no dip), and
  "gained XP" no longer bumps the plate's level before the bar fills; prick and heal numbers; `fade_out`.
- `battle_ui/battle_scene.gd`: the item special case is gone; `_sync_hud` calls `hud.sync`.
- `battle_ui/battle_flow.gd`: a meal's stat buff plays as a charm event so its pill shows with its line.

## Layout
Nothing in the layout session's area: no sizes, fonts or positions changed. The new number colour (heal green) and
the faint fade are in `hud.gd` but only touch modulate and a label colour. `Plate.set_creature` now resets the
plate's `modulate.a` (for the fade); if the layout session animates plate modulate, keep that in mind.

## Not done
- Victory music still starts after the XP and prize lines: the jingle is 3 s and does not loop. A looping victory
  track would let it start with the last faint.
- I could not reach a level-up with the dev `--battle` lead in a traced run; the level-up path is unit-tested.

## Results
- Full `tools/test.sh`: 2982 passed, 0 failed, `validate: 0 error(s)`, no SCRIPT ERROR (the "Parse JSON failed"
  lines are the corrupt-save tests). The pair-keeper wording commit landed during that run; its two test files
  (`test_flow`, `test_event_player`) were run again on their own afterwards and pass.
- `tools/playtest.sh slice 2`: PLAYTEST PASS, 85 wins / 3 losses in 90 battles, brook badge, no SCRIPT ERROR.
# w50-tf-menus handoff

Branch `w50-tf-menus`: text that fits on every menu, screen and minigame at 1280x720 (the other half, battle UI,
overworld and HUD toasts, is the other session's). Full findings in `docs/audit/w50_text.md`. (The previous
HANDOFF.md, w49-games, is in git history at 83dd13d5.)

## What I built
- `core/text_fit_audit.gd` (TextFitAudit): walks the visible text under a node and lists what doesn't fit: wide,
  trimmed, lines, cut, spills, overlap, under, small (< 18 px), box (a framed panel cut off), stuck (words only a
  mouse can scroll to).
- `tools/dev/text_audit.gd` (+ `_body.gd`): opens all 122 screens with DevMenu's sample journey, headless, no window,
  and prints one line per problem. Exits 1 if anything was found.
- `tests/ui/test_text_fit.gd`: the audit over eight key screens in a second headless Godot (about ten seconds), plus
  unit tests for the 18 px floor and `UIKit.fit_column`.

## How to run it
```
.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/text_audit.gd -- all
    [screen ...] [--summary] [--stress] [--text=large] [--kind=cut,box]
```
After adding a `class_name`, run `--import` once or the audit can't see it (it quits with code 2).

## Numbers
Before (528d58a9): 331 problems on 70 screens, plus a Gazetteer script error. After: 0 on all 122 screens. Large
text still has about 160 on 43 screens (see the audit doc).

## Notes for the integrator
- Shared files touched: `ui/ui_kit.gd` (MIN_TEXT floor in `label`, `fit_size`, `fit_block`; new `scroll_list`,
  `fit_column`, `keep_fitted`, `fit_width`, `key_scroll`, `read_on`, `line_height`, `ink_label`) and `ui/menu_base.gd` (hint bar
  fit, HINT_MIN 18, Cancel honours a `back_to` meta). The floor means any `UIKit.label(x, 16)` is now 18 px.
  Outside my scope the only small literal is `ui/parish_toast.gd`'s 17 px heading (now 18); battle_ui and world pass
  18 or more, so their layouts should be unchanged.
- Not audited (the other session's): overworld toasts and HUD, `ui/parish_toast.gd`, battle UI.
- `ui/gazetteer_tab.gd` had a real bug (row 0 vs 1) that threw on every Gazetteer open and hid the "How these isles
  work" row: fixed here.
- Pause's Today's Walk line is now optional in the Where next? card: it shows when there is room at a readable size
  (it was 12 px before).
- Fieldbook: at the 18 px floor a long entry no longer fits one box, so Confirm reads on down it (hint "Read on")
  before opening the map; same on the Words tab before revision. `tests/ui/test_fieldbook_teaching.gd`'s fit test
  now allows two boxes instead of one (it used to rely on 15 px text).
- Before/after shots of the worst five: `docs/screens/w50-text-*-before.png` / `-after.png`.
# w50-tf-world handoff

Branch `w50-tf-world`. Text that renders badly while walking about and in battle: building signs, the overworld HUD
and the battle UI. Findings, numbers and what is left are in `docs/audit/w50_text_world.md`; before and after shots
are `docs/screens/w50-world-*.png`. The previous handoff (w49-games) moved to `docs/audit/w49_handoffs.md`.

## What changed
- **Signs** (`world/sign_sight.gd`, new; `world/signage.gd`): a building's name goes where you can read it from its
  door. Boards find the front's real face (jettied York fronts, Chester's Rows, porticoes no longer swallow them),
  keep off porches and oriels, and move along the front out from behind a neighbour standing further forward
  (Pierhead Building, Norwegian Church). Boards on posts stand clear of verandas; station totems in front of the
  canopy beam. 331 of 1539 signs were cut from their own door; 5 now are, each partly (9 to 18%).
- **OccluderFade** (`world/occluder_fade.gd`): a tall building fades from further back (a house is unchanged), so you
  and the sign behind it no longer vanish behind Blackpool's Illuminations Depot.
- **Dialogue** (`ui/dialogue_box.gd`): the choice list stands on the box's top edge, so a four-line page's first line
  is no longer under it (same bug as the speaker's tab, fixed earlier on this branch).
- **Toasts and zone card** (`ui/parish_toast.gd`, `ui/zone_card.gd`): news waits for the town's name card instead of
  covering it, wraps past 640 px clear of the route chip, 18 px header; a very long zone name shrinks to fit.
- **Battle** (`battle_ui/message_box.gd`, `menus.gd`, `hud.gd`, `battle_scene.gd`): a long line takes a smaller size
  instead of growing the message box off the screen, and keeps left of a picker opened over it; Bag and Team open on
  the left so both HP plates stay in view; doubles plates end long names in an ellipsis; small type raised (weather
  plate and singles plates 18 px, nothing under 16).
- **Dev**: `tools/dev/sign_audit.gd` (every sign, from its door) and `--text-check` beside `--shot`
  (`core/text_check.gd`, one hook in `core/game_state.gd`): writes `<shot>.text.txt` listing text a player can't read
  whole. `CameraRig.clamp_to`/`eye_for` are the rig's clamp as statics, for the sight lines.

## How to see it
- `tools/shot.sh out.png 30 --boot=cardiff@48,32` (the owner's view), `--boot=york@57,29` (Bettys on its jetty),
  `--boot=blackpool@55,6` (the station through the faded depot).
- `tools/shot.sh out.png 28 --battle=puffkin:20 --battle-menu=bag --stress --text-check` (and `team`, `fight`,
  `--double --battle-menu=target`, `--weather=sunshine --battle-stages`).
- `.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/sign_audit.gd` (a minute).
- Tests: `tools/test.sh signage`, `occluder`, `dialogue`, `battle_text_fit`.

## Notes for the integrator
- Shared files touched, all small: `core/game_state.gd` (the `--text-check` hook after `--audit`),
  `world/camera_rig.gd` (`_clamped` now calls the static), `battle_ui/battle_scene.gd` (two signal connects).
- Sign placement adds about 20 ms to a zone load here (sight lines are cast once at build, never per frame).
- `test_signage::test_town_signs_read_whole_from_their_doors` builds ten real towns (a few seconds): if a later map
  edit puts a taller building in front of a sign, it names the sign.
- Not fixed, by design: a sign seen from somewhere other than its own door can still be behind a roof; the place
  chip carries the reading. Props (a lamp post before London's Vane Tower) aren't in the sight check.
- The stage pills, doubles HP/XP tags and move-row type chips stay at 16 px capitals (a row of six pills wouldn't
  fit the plate at 18). `--text-check` lists them.
- For the menus session: `UIKit.fit_size` measures with the fallback font even when the readable font is on.
# w50-world handoff

Branch `w50-world`. "The world doesn't match what it says": Deep Places drawn as their lines describe, cave entrances
that look like caves, and a checker in the validator for the rest. Full write-up, counts and leftovers in
`docs/audit/w50_world.md`. The w49-games handoff moved to the end of `docs/audit/w49_handoffs.md`.

## What changed
- **Deep Places** (`core/deep_place.gd`, new `world/deep_meshes.gd`): a closed gate is a solid prop on the room's own
  floor (cave gate, grille, timber gate, barrier, oak door, slab, basalt, flowstone), an open one is the floor; levers,
  crates and plates have looks too (wheel, winch, weir board, handle, column, crack; boulder, tub, block, slab, column).
  The look comes from the line's words or a `"look"` key. Gate tiles are no longer rewritten, so `tile_at` on a gate is
  the room's floor; tests check `walkable` and the gate prop instead. Facing a closed gate reads its line
  (`world/deep_scene.gd`).
- **Cave rooms** (`world/zone_builder.gd`): low rubble on the camera side, lower side walls, no stalactite in front of
  a prop, sign or person. New point props `deep_gate`, `deep_lever`, `deep_crate`, `deep_plate`, `cave_cleft`.
- **Checker** (`data_api/world_consistency.gd`, called from `tools/validate.gd`; `tools/world_check.gd` lists all):
  object, near, stairs, cave, entrance, blocker and text rules. Findings that are right as they stand go in
  `data/world_consistency.json` with the reason. Tests: `tests/core/test_world_consistency.gd`, `test_deep_place.gd`;
  `test_fingals_cave.gd`, `test_dan_yr_ogof.gd` and `test_wookey_hole.gd` follow the gate props and moved levers.
- **Data**: see the audit. Zones: aillwee_entry, blue_john_entry, jersey_tunnels, pit_cave (cave stage, stone floor),
  castleton, jersey_country, dover (cave mouths), mendips (Wookey cleft, sign), wookey_hole, wookey_river,
  staffa_columns, blaenavon_bigpit_east, shetland_mainland (gate), chat_moss, ring_of_kerry (signs), chatmoss_signalbox
  and nym_signalbox (lever frames). Dialogue: dover_museum, plymouth_smeaton, three sanctuaries, brighton_rockshop,
  oxford_bodleian, oxford_camera, pennine_grouse_moor.

## Verified
`tools/test.sh`: 2975 passed, 0 failed, `validate: 0 error(s)`, no SCRIPT ERROR. `tools/playtest.sh slice 2`: PLAYTEST
PASS. Every Deep Place zone and every fixed outdoor entrance screenshot and looked at.

## How to see it
`tools/shot.sh out.png 60 --boot=blue_john_entry@6,6` (add `--flag=dp_blue_john_entry_gate` for open),
`--boot=staffa_columns@7,5 --ride=lantern`, `--boot=mendips@62,39`, `--boot=castleton@45,22`. The machine was very
loaded (load average over 100), so 30 s delays often caught the title screen; 60 s worked. Run shots one at a time:
parallel `open -n` runs sometimes drop their arguments. Screens: `docs/screens/w50-world-consistency-*.png`.

## Notes for the integrator
- The w50-tf-world session owns sign text sizing; I didn't touch `world/signage.gd` or landmark labels. Building style
  changes (cave_mouth) keep their labels.
- The playtest bot never applied Deep Places and still doesn't; nothing here makes a new tile solid except the Shetland
  field gate, which replaces a wall tile (same solidity) and is a zone prop the bot already loads.
- `data/world_consistency.json` will need an entry, or a fix, for any new line that points at something not drawn.
