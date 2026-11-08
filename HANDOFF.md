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
