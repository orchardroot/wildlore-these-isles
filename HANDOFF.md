# Wave 48 G1: sheepdog trials + worm charming

Built (branch w48-g1-sheepdog):
- `core/sheepdog.gd` + `ui/sheepdog_screen.gd` + `data/sheepdog.json`: top-down trials. Walk your lead creature (direction keys), Run dashes (spooks), Confirm lies down (settles). Fences with gates, a pen, a clock. Venues: `longshaw` (Macclesfield Forest, Trials Steward at 20,28) and `lakes` (Lake District, Fell Steward at 50,45).
- `core/worm_charming.gd` + `ui/worm_screen.gd` + `data/worm_charming.json`: rhythm game on a 3x3 plot, 60 s, birds punish a messy beat (Run shoos). Venue `willaston` (Plot Judge at Macclesfield 14,32).
- Story commands `{"do": "sheepdog"|"worms", "venue", "who"}` in `story/trials_run.gd` (one 2-line hook in story/commands.gd); router menu keys `sheepdog`, `worms`.
- Party pieces: `data/party_pieces/g1.json` (`sheepdog` -> Round Up, kin/hedgerow, field `round_up`; `worms` -> Charm the Worms, bog/hedgerow, field `charm`) and `data/moves/pieces_g1.json`. Both screens call `PiecePrompt.after_game` once when a game finishes.
- TrainerStats counters added: `sheep_penned`, `worms_best`.
- Easier minigames (Settings.easy_darts): wider gates, more time, calmer sheep; wider beat windows.

Integrator notes:
- First commit "STUB party pieces" adds `core/party_pieces.gd`, `ui/piece_prompt.gd` and `GameStateData.pieces`: DROP these for session P's versions.
- Field spots (session F) should use verbs `round_up` and `charm`; zone ids macc_forest / macclesfield are the venues.
- Dev: `--menu=sheepdog:dev`, `--menu=worms:dev`, or `--menu=sheepdog:longshaw`.
- Screenshots: docs/screens/w48-g1-*.png
