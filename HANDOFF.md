# w49-games handoff

Branch `w49-games` (from int-w49). Fixes three gameplay problems from the tune session; numbers and reasoning are in
`docs/audit/w49_tune.md` under "Follow-up". Earlier handoffs moved to `docs/audit/w49_handoffs.md`.

## What changed
- **Pancake race** (`core/pancake.gd`): lean push 13 to 9, pan drag 0.9 to 2.2, lean rate eased. A 0.15 s reaction on a
  keyboard now drops it 0.2 times a race (was 9), 0.2 s about 7 (was 31), 0.3 s still about 20. Rosette thresholds
  reset to 40 / 36.5 s (`data/party_pieces/g2.json`, `Pancake.GOOD_TIME`/`MASTER_TIME`), champion 37 to 39.5 s.
- **Sheepdog trials** (`core/sheepdog_trials.gd`): the jam was cohesion towards the global flock centre (a split flock
  held itself still), no pull on a calm straggler, and a dead zone at the pen mouth. Fixed (local cohesion, gentle calm
  lure, lure back to the gate, pen lure to the mouth). Clocks cut to 50 s Longshaw and 60 s lakes
  (`data/sheepdog_trials.json`) because the fix made it easy. The simulator's own bot also dithered and is fixed.
- **Coracle and snorkel**: seeded per-run river level and eddies (coracle) and set and springs (snorkel); seed 0 keeps
  the plain behaviour. Screens seed from the clock.

## How to see it
`tools/shot.sh out.png 30 --menu=pancake:dev` (also `coracle:dev`, `sheepdog:longshaw`, `snorkel:dev`). Simulator:
`.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/minigame_sim.gd -- <game> 80`.

## Notes for the integrator
- Sheepdog gold (pen all 7) is still too easy for the bots (decent 72%); see the follow-up for the option of scoring
  with the clock left. Left alone as a design call.
- No lean ease-in beyond the fast-then-gentle rate: a slower ease made late reactions fatal.
- Touched beyond the three games: `tools/dev/minigame_sim.gd` (bots seed the new fresh(); sheepdog bot fixes).
- Easier-mode gold rosettes (finding 2 of the tune session) untouched.
