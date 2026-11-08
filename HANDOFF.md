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
