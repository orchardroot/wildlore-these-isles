# Wave 48, session G3: bog snorkelling + coracle racing

Branch `w48-g3-bog`.

## Built
- **Bog snorkelling** (Llanwrtyd Wells, Waen Rhydd): `core/snorkel.gd` (pure), `ui/snorkel_screen.gd/.tscn`, `data/snorkel.json`.
  Two 60-yard lengths, Left/Right in turn on a beat ring, silt and breath, Confirm blows the snorkel, a swimming ghost of the local.
  Host: Bog Marshal at the pond in `data/zones/beacons.json` (62,30), plus bunting, flagpole, noticeboard, sign.
- **Coracle racing** (Severn at Ironbridge; real racing at Cilgerran on the Teifi): `core/coracle.gd` (pure, physics-lite),
  `ui/coracle_screen.gd/.tscn`, `data/coracle.json`. Top-down river, eight buoy gates, each stroke turns the boat away from it,
  Confirm braces, +3 s per missed gate, a ghost coracle for the local, the Iron Bridge as the finish.
  Host: Coracle Racer at `ironbridge_gorge` (39,31), plus buoys, bunting, sign.
- Story commands `snorkel` and `coracle` (`story/bog_run.gd`, `story/commands.gd`, `data_api/story_validator.gd`), menus in
  `core/scene_router.gd`, dialogue `data/dialogue/w48_g3_bog.json`. Daily-stamped purse, first-win prize, Standing, TrainerStats
  (`snorkel_swims`, `snorkel_best_tenths`, `coracle_races`, `coracle_best_tenths`). Easier minigames (`Settings.easy_darts`) widens
  the beat window and the gates and calms the spin.
- Party pieces: `data/party_pieces/g3.json` (`snorkel`: bog/brook, move Peat Plunge, field verb `snorkel`; `coracle`: brook/tide,
  move Coracle Spin, field verb `paddle`) and `data/moves/pieces_g3.json`. Both screens call `PiecePrompt.after_game(self, id, time)`.
  Lower time is better (`lower_better: true`).

## Integrator notes
- The first commit "STUB party pieces" (core/party_pieces.gd, ui/piece_prompt.gd, `GameStateData.pieces`) is session P's contract
  stub: drop it when P lands. My code only uses `PiecePrompt.after_game(host, game_id, score)`.
- Field spots for `snorkel` and `paddle` (session F) could go by the Beacons pond (53-61, 28-33) and the Severn bank (39-45, 29-36).

## See it
- `tools/shot.sh out.png 14 --menu=snorkel:dev` / `--menu=coracle:dev` (mid-game); `:dev_end` finishes on the next frame (tests the prize/party piece path).
- `--boot=beacons@60,30` and `--boot=ironbridge_gorge@41,32` for the hosts (use a long delay, 30, on a busy machine).
- Screens in `docs/screens/w48-g3-*.png`. Tests: `tools/test.sh snorkel`, `tools/test.sh test_coracle` (tests/g3).
