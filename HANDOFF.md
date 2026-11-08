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
