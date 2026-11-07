# Wave 48 session G2: cheese rolling and the pancake race (branch w48-g2-cheese)

## Built
- Cheese rolling (Cooper's Hill): `core/cheese_roll.gd`, `ui/cheese_screen.gd`. Three downhill races; steer, hold Run to dig
  in, dodge tussocks, rabbit holes and puddles, chase the cheese, mind the camber. Points = place + cheese catch - tumbles.
  Painted backdrop (sky, hills, crowd, bunting, finish tape), screen shake and callouts, existing sfx only.
- Pancake race (Olney): `core/pancake.gd`, `ui/pancake_screen.gd`. 415 yards of High Street, sprint with Run, lean the pan
  to keep the pancake on, flip at nine flags (ring closes on a close-up pan), champion ghost, lowest time wins.
- Shared drawing: `ui/folk_art.gd`. Story runner: `story/g2_run.gd` (class FolkRaceRun), commands `cheese` and `pancake`
  (one arm each in story/commands.gd, names added to data_api/story_validator.gd, menus in core/scene_router.gd).
- Venues: Cotswolds `cw_hill_marshal` (13,59) + plaque (15,59), Oxford `ox_pancake_marshal` (28,23) + plaque (30,23);
  dialogue added to data/dialogue/cotswolds.json and oxford.json (scripts must live in the zone's own file).
- Party pieces: `data/party_pieces/g2.json` (cheese -> Cooper's Roll, stone/brawn, field "roll"; pancake -> Shrove Toss,
  hearth/kin) and `data/moves/pieces_g2.json`. Scores: cheese points (good 70, master 115), pancake seconds, lower
  better (good 52, master 42). Both screens call `PiecePrompt.after_game` once when the game finishes.
- TrainerStats: cheese_best, cheese_wins, pancake_wins, pancake_best (tenths of a second); two Stats lines.
- Tests: `tests/minigames/test_g2_cheese_pancake.gd` (17, bots for both games).

## Integrator
- The first commit "STUB party pieces" adds `core/party_pieces.gd`, `ui/piece_prompt.gd` and `GameStateData.pieces`. Drop those
  for session P's versions (the stub PiecePrompt only toasts and learns into a free slot). The G2 code needs only the contract.
- Add `masters_beaten` to TrainerStats.COUNTERS if P has not (the stub calls TrainerStats.add with it; add() works for any key but
  sanitise drops unknown keys on load).
- Field verb `roll` (cheese) is for session F; no field spots written here.

## See it
- `tools/shot.sh out.png 14 --menu=cheese:dev` and `--menu=pancake:dev` (screenshots in docs/screens/w48-g2-*.png).
- In game: Cotswolds south-west by the cheese wheels (Race Starter); Oxford north of the High Street (Pancake Marshal).
- "Easier minigames" (Settings.easy_darts): gentler hill and shorter tumbles, calmer pan and wider flip windows.
