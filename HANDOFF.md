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
