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
