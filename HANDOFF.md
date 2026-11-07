# Wave 48 session P: party pieces

Built: `core/party_pieces.gd` (PartyPieces), `ui/piece_prompt.gd` (PiecePrompt.after_game / teach), `GameStateData.pieces`
(round-trips, sanitised), TrainerStats counter `masters_beaten`, the Almanac "Party Pieces" page (`ui/pieces_tab.gd`, ledger
`pieces`), validator check (`PartyPieces.problems`), 23 pieces in `data/party_pieces/p.json` with moves in
`data/moves/pieces_p.json`, and one `PiecePrompt.after_game` call in each skill minigame screen (darts, bowls, skimming,
crabbing, curling, wrestling, conkers, ringing, walling, shanty, crossword, quiz, games x4, arcade, fete x3, forecasting,
trumps, science fair). Roulette, fruit machine, hi-lo, blackjack, races left out on purpose.

See it: `tools/shot.sh docs/screens/w48-p-pieces.png 14 --menu=almanac:pieces`.

For the integrator and other sessions:
- Score per game (lower_better where marked): ladders (darts, curling, wrestling) 0 lost, 1 won, 2 beat the top rung;
  bowls = shot margin; skimming = best skips; crabbing = crabs in bucket; ringing/shanty = % on time; quiz/forecasting = %;
  crossword = seconds (lower); caber = points; tug = pull 0..100; hurling/shinty = points; fete cheese/bog = seconds (lower),
  welly = metres; arcade = toys won so far; science = puzzles solved so far; trumps 0/1/2.
- Gold pays PartyPieces.GOLD_PRIZE (150) once and bumps `masters_beaten`.
- Field verbs defined: mend (walling), skim, topple (caber), line (crabbing). `PartyPieces.field_known(data, verb)` is true
  when the verb's piece is unlocked and someone in the party knows the move; `game_for_field(verb)` names the game.
- No crit mechanic exists, so "high crit" pieces use plain power. Other sessions: put new entries in `data/party_pieces/<letter>.json`
  and moves in `data/moves/pieces_<letter>.json` with `"piece": "<game_id>"`.
- `PiecePrompt.after_game` sets the host's `_locked` while its card is up and restores it; call it before `close`.
