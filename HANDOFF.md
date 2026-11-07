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
# Wave 48 A: creatures that move like themselves

Built
- `core/motion.gd` (`Motion`, pure): nine styles (hover, hop, slither, sway, bob, pulse, stomp, flutter, drift). Species
  JSON `"motion"` overrides; else id/sprite words (`Motion.WORDS`), else first type (`Motion.BY_TYPE`). Idle maths,
  shadow breathing and `lunge_kind` live here. Seven species carry explicit overrides (puffkin, grandpuff, sphagnet,
  dubhlet, mustling = pulse; raylette, sandbarray = drift). New lines from M get styles automatically.
- `battle_ui/creature_actor.gd`: per-style idle (sprite offset, squash, shadow shrinks as it rises), per-style lunge
  (swoop, strike, charge, leap, dash). A stomper's charge emits `thump`, the diorama nudges the camera (scaled by
  Settings.flash_scale).
- `world/follower.gd`: the standing idle uses the lead's style.
- `battle_ui/fx_pieces.gd` (`FXPieces`): signature flourish for any move with a `"piece"` key, chosen by
  `FXPieces.KIND[piece id]` (skip, arrow, tumble, slide, swing, notes, wall, hook, cheer, flip, whirl), unknown ids
  get a gold fanfare. Then the move's own shape plays. Hooked with one branch in `BattleFX._attack`.
  P's real game ids may differ from my guesses: edit `FXPieces.KIND` after merging `data/party_pieces/p.json`.
- Not done: summary/dex portrait motion (static art there; judged not cheap).

See it
- `tools/shot.sh out.png 26 --battle=puffkin:20 --lead=croakle --battle-auto --battle-slow` (a 14 s delay catches the
  grass wipe on this machine; use 26+).
- Dev: `--fx-piece=<game id>` makes every attack play that piece's flourish, with `--fx-move=<move id>`, and
  `--fx-freeze=attack:0.8`. Screens: `docs/screens/w48-a-*.png`.
- Tests: `tools/test.sh motion` (tests/world/test_motion.gd).
