# Handoff: wave 48 Q (the critic), branch `w48-q-polish`

## What's here
- **HP bar "starts low after a Sanctuary heal"**: hunted through every path that sets a battle plate (see
  docs/audit/w48_q.md for the full trail). On the plate the bar and the numbers are the same two variables, so
  they cannot disagree; a frame-driven probe over two battles around a heal with the owner's own party never saw a
  mismatch. The one bar that did show "lower, with the right numbers" was the 4.6.0 Summary HP row (stat size out
  of 130), fixed on 30 Oct; the owner's saves are from 27 Oct, before that build. Added the missing regression tests
  (tests/ui/test_w48_q_critic.gd) and a real fix found on the way: `Forms.apply` now keeps a wild creature full
  when its regional form raises max HP (Skomer volet, Guernsey/Kerry moolet, seven overseas forms), so a foe's
  plate no longer starts part-drained.
- **Map route line** follows the drawn railway and ferry crossings (`MapLogic.route_legs`, used by
  ui/world_map.gd). Screenshot: docs/screens/w48-q-map-route.png.
- **Summary**: the selected move's info line now leads with the move's full name, so a long name trimmed in its
  row ("Bramble La...") can still be read.
- A critic's pass over pause, Team, Bag, shop, Settings, darts, bowls, Summary, battle menus, a town and a house:
  screenshots in docs/screens/w48-q-*.png; nothing else needed fixing.

## How to see it
- Route: `tools/shot.sh out.png 25 --menu=map:route` (Macclesfield to York: on foot to Stoke, then the railway
  via Sheffield and Leeds).
- HP probe (ticks real tweens, unlike the unit runner):
  `godot --headless --path . -s res://tools/dev/hp_probe.gd -- --battle-auto --foe-level=38 --save=<save.json>`
  prints `MISMATCH` on any frame where a plate's bar disagrees with its creature.
- Tests: `tools/test.sh w48_q`.

## For the integrator
- Small, additive edits only: core/forms.gd (`apply`), ui/map_logic.gd (new functions at the end),
  ui/world_map.gd (one call), ui/summary_screen.gd (one line), tools/dev/hp_probe.gd (new), tests (new file).
- On this loaded Mac, `tools/shot.sh` boots and battles need a 25 to 35 s delay or the shot catches the title.
