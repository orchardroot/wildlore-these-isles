# Wave 48 G5: gurning, welly wanging, Games League

Branch w48-g5-gurning.

## Built
- Gurning (Egremont Crab Fair): `core/gurning.gd`, `ui/gurning_screen.gd`, `data/gurning.json`. Simon-style faces, four directions, own note each. Keswick Gurning Judge (28,29) plus plaque.
- Welly wanging (Upperthong): `core/welly_wang.gd`, `ui/welly_wang_screen.gd`, `data/welly_wang.json`. Hold Confirm to spin, release in the gap, wind. Saddleworth Moor Wang Steward (27,22) plus plaque. Separate from the fete power-and-angle welly.
- Games League: `core/games_league.gd`, `ui/league_card.gd`. Stamps per game with plays > 0, from PartyPieces entries and state. Letters from the Isles Games Society at 10, 20 and all stamps ("all" needs at least 12 games listed). Keswick Games Secretary NPC (36,29) opens it. Not yet a tab of P's Almanac page: hook `menu "league"` or embed `LeagueCard` rows there.
- Story commands `gurn`, `wang`, `league` (`story/contest_run.gd`, one case each in `story/commands.gd`, listed in `data_api/story_validator.gd`). Router menus `gurning`, `wang`, `league`. TrainerStats `gurn_best`, `welly_best` (+ Stats lines).
- Pieces: `data/party_pieces/g5.json` (gurning: fae/night, move `gurn`; welly_wang: gale/brawn, move `welly_wang`), `data/moves/pieces_g5.json`.
- Tests: `tests/g5/test_contests.gd`.

## Integrator
- Drop my STUB `core/party_pieces.gd` and `ui/piece_prompt.gd` for P's real ones. Both screens call `PiecePrompt.after_game(self, id, score)` once at finish. `GamesLeague` reads `data.pieces` when it exists (else the stub flag).
- Move id `welly_wang` is mine; P's fete one was renamed gumboot_fling.

## See it
`tools/shot.sh out.png 14 --menu=gurning:dev` (also `wang:dev`, `league:dev`). Screens in `docs/screens/w48-g5-*.png`.
