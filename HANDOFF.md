# Wave 49 session "tune": minigame thresholds and a play-through critic

Branch `w49-tune`. Full write-up with the simulation table and findings: `docs/audit/w49_tune.md`.

## What was done
- `tools/dev/minigame_sim.gd`: drives the ten wave 48 party-piece cores with sloppy, decent and sharp bots over
  many seeds, normal and Easier, and prints the score spread and silver/gold rates against the live thresholds.
  Run: `.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/minigame_sim.gd -- all 80`
  (three minutes; name one game to be quick). `tools/dev/pancake_probe.gd` is the pan-control side study.
- Thresholds reset in `data/party_pieces/g1..g5.json` (good / master): sheepdog 5/7 (was 4/7), worms 32/54 (58),
  cheese 70/125 (115), pancake 58/44 (52/42), snorkel 60/47 (80/56), coracle 34/27 (same), road bowling 10/7 (same),
  poohsticks 3/5 (4), gurning 6/8 (5), welly 22/31 (20/30). `Pancake.GOOD_TIME/MASTER_TIME` kept in step.
- Balance fix in `core/welly_wang.gd`: a dizzy throw now launches at 90% of the speed at the dizzy line. Before,
  holding for full spin and letting go giddy out-threw a clean release by about six metres (median 38 m v 32 m).
- Screen fixes: pancake title card moved onto the road (it collided with START and the pan inset), pancake dev message
  names the real flag, pancake start sign reads thresholds from the piece data; cheese start no longer says the heat
  twice; welly stage no longer stretches past its art (clouds and wall were drawn outside the picture) and the SPIN
  label has a backing. Screens: `docs/screens/w49-tune-*.png`.

## For the integrator
- No existing test pinned an old threshold; all minigame test files pass unchanged. Full `tools/test.sh` at the end:
  2941 passed, 0 failed, validate 0 error(s), no SCRIPT ERROR.
- Findings that are bigger than a tuning pass, all in `docs/audit/w49_tune.md`: the pancake pan is on a knife edge with
  key input (reaction 0.08 s flawless, 0.2 s thirty drops); Easier minigames hands out gold rosettes and the 150 pound
  prize; the sheepdog flock can jam at the gate for bot and probably player alike; coracle and snorkel have fixed
  floors (24.0 s and 42.8 s) with no run-to-run variation.
- Files touched outside my ownership: `core/welly_wang.gd` (the dizzy speed, four lines) and `core/pancake.gd` (two
  constants). Nobody else in wave 49 owns either.
