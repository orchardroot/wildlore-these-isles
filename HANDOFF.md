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
