# w49-crit handoff

## What was already there
Crits already existed in a basic form: `DamageCalc` rolled a flat 1 in 24 chance, 1.5x, ignoring the attacker's
drops and the defender's boosts; weather (sunshine), Bond and knacks scaled the chance; `event_player.gd` already
said "Right on the nose! A critical hit!" and `hud.gd` already flashed gold (gentler with Reduce Flashing) and
popped a gold number; a crit counts as a "strong" hit for the shake. I left all of that alone.

## What I added
- `DamageCalc.CRIT_STAGES` (1 in 24, 1 in 8, 1 in 2, always), `crit_percent(stage)` and `crit_stage(user, move)`.
  `Battle._strike` now takes its base chance from the stage (the weather/Bond/knack multipliers still apply on top).
- Move field `"crit": N` (0..3, damaging moves only; the validator checks it). `1` is "high crit".
  Flagged: Treble Twenty (darts), Peregrine Plunge, Kestrel Dive (stoop at the target), Flint Flick (keen edge).
- Charm effect `crit {stages}` in `battle/charms.gd` and a new charm, White Heather (`data/items/charms.json`,
  wild-carried like the horseshoe, not in shops): +1 crit stage on all the holder's hits.
- `MoveText.describe` appends "High chance of a critical hit." (also after a hand-written desc).
- `BattleAI.attack_score` scales a move by its extra expected crit damage (about +4% for a high-crit move, so a mild nudge).
- `tests/battle/test_crit.gd`: stage table, 1.5x, stage-ignoring both ways, seeded determinism, rates over 4000
  rolls, move and charm stages, flagged moves, MoveText, AI, and a crit appearing in a seeded battle's events.

## Notes for the integrator
- Touched shared files by small hunks: `data_api/validator.gd` (crit range check), `battle/ai.gd`, `battle/battle.gd` (one line).
- No save changes. No UI changes (nothing needed).
- Test and playtest results: see the end of this file.

## Results
- Full `tools/test.sh`: 2952 passed, 0 failed, validate: 0 error(s), no SCRIPT ERROR (the "Parse JSON failed" lines are the corrupt-save tests, expected).
- `tools/playtest.sh slice 2`: PLAYTEST PASS, 69 wins / 2 losses in 73 battles, brook badge won. Win rate not hurt.
# Wave 49 crossings: HANDOFF

## Built
- `tools/field/gen_field_spots.py` now makes 24 hop pairs (was 3) across 24 zones, deterministic:
  paddle 5 (coracle over water), topple 5 (trunk over narrow water), skim 5 (new stepping stones over water),
  snorkel 1 (bog, flow_country), loft 8 (bale over a hedge, fence or wall). Max 8 per kind, max 3 per region.
- Every pair is a real shortcut (walking round is 24+ tiles or impossible) and the far side has a once-only cache
  spot (charm/mend/topple/round_up/roll/loft, 23 of 24 pairs) within 3 tiles of the landing. Nothing the story needs sits behind a crossing.
- New prop `stepping_stones` (core/field_spots.gd PROPS, mesh in world/field_spot.gd).
- Connectivity guard: the generator checks that making any spot tile solid never cuts a walkable tile off from
  the rest of its component (`cuts()`), for ordinary spots and pairs alike. Total spots 304 (was 242).
- Screens: docs/screens/w49-crossing-{galway,hadrians_wall,norwich,flow_country}.png.

## Notes
- Old wirral_way and other w48 pair placements changed (regenerated). Flags for the old pairs are gone; they were never reachable in shipped saves of note.
- Not done: "view with plaque" and "rare encounter patch" far sides; caches only. Stones are small in the screenshot; they sit on the banks.
- Hadrian's Wall loft hops the Roman wall itself; change the obstacle set if that reads badly.
- Verified: `tools/test.sh field` 71 passed, validate 0 errors; `tools/playtest.sh slice 2` PLAYTEST PASS. The full test result is below.
Full test: 2941 passed, 0 failed, validate 0 error(s), no SCRIPT ERROR (JSON parse ERROR lines are pre-existing test noise; RID leaks at exit are harmless).
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
# w49 portraits

## Built
- `ui/portrait_motion.gd` (PortraitMotion): a tiny canvas-item vertex shader (shift, squash about the feet) plus `frame_for`, the pure maths over `Motion.idle`. One ShaderMaterial per picture, three uniforms set per frame, no allocation in the loop.
- `AnimSprite.animate(species)` makes a front picture idle in its Motion style. Silhouettes, icons and unseen entries stay still.
- Hooked into: Summary, Fieldbook entry (caught only), new-entry popup, relearn screen, nickname screen, starter picker. Party list icons, pairing and rumours stay still.
- Reduce Flashing: travel scaled by `Settings.flash_scale()` (0.3) and the clock slowed to 0.4x, so flutter does not shimmer.
- Portraits travel at 0.7 of the battle amount, and a floater's lift is subtracted so it rests where the art was drawn.
- Per-sprite phase from the species id, so a row of the same style does not move in lockstep.

## See it
`tools/shot.sh out.png 30 --menu=summary:0`, `--menu=pedia:snowhare` (hop), `pedia:linenwisp` (flutter), `pedia:haarling` (drift), `pedia:bullmoose` (stomp). Shots in `docs/screens/w49-portraits-*.png` (single frames, so the motion is a mid-cycle pose).

## Notes
- Touched other files by a line or two each: summary_screen, pedia_screen, pedia_popup, relearn_screen, name_entry, starter_picker (one `animate` call each).
- Tests: `tests/ui/test_portrait_motion.gd`.

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
