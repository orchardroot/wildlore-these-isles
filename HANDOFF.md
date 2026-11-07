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
# Wave 48 M: new monsters (branch w48-m-monsters)

14 new lines, 30 species, all appendix species (the core 200 is unchanged). The brief asked for silhouettes and
colours that look nothing like the existing dex, so none of these is a round furry animal.

| Line | Stages | Types | Notes |
|---|---|---|---|
| Whorlet | Whorlet, Shellhaven | bog/stone | snail; the second stage has a cottage on its shell |
| Moonbell | Moonbell, Aurelian | tide/night | moon jellyfish |
| Slipknot | Slipknot, Gordian | tide/bog | hagfish, mostly knot (Scottish sea lochs) |
| Gawplet | Gawplet, Argusine | fae/gale | peacock butterfly, all eyespots |
| Brewlet | Brewlet, Brownbetty | hearth/stone | teapot golem (Stoke, Ironbridge) |
| Brammel | Brammel, Bramblemaw | hedgerow/spirit | bramble swarm, summer and autumn |
| Dishwight | Dishwight, Dresserwight | spirit/hearth | boggart in a Welsh dresser |
| Sailet | Sailet, Postmill | gale/iron | post mill |
| Raftlet | Raftlet, Rafterweb | bog/brook | fen raft spider, on the water tables; sexes differ |
| Tattybogle | Tattybogle, Mawkin | hedgerow/kin | scarecrow |
| Dishfin | Dishfin, Moladisc | tide/gale | ocean sunfish, with a gull on the big one |
| Barnaclet | Barnaclet, Barnagoose | tide/kin | goose barnacle that hatches a barnacle goose |
| Leatherjack | Leatherjack, Husk, Longlegs | bog (Longlegs bog/gale) | crane fly in three stages; sexes differ |
| Clocklet | Clocklet, Dandylion, Clockmaster | hedgerow/gale | dandelion bud, lion, clock |

Skipped because the dex already has them: selkie, corncrake, kite, hedgehog, Cornish knocker, a plain boggart.

## What changed
- `art/recipes/creatures/<id>.json` and rendered `art/sprites/creatures/<id>_{front,back,icon}.png` (plus `_f`/`_m`
  sheets for longlegs, raftlet, rafterweb). Recipes were generated with a throwaway script; the JSON is the source.
- `data/creatures/<line>.json` (learnsets, evolutions, dex text, a real fact, `real`, Welsh/Irish/Gaelic names only
  where certain). No `"pieces"` hints were added, since P's game ids were not in my tree.
- `data/zones/*.json`: additive `encounters` entries only (40 zones), one per habitat. Habitats match the tables.
- `data/dex_order.json`, `data/genes.json` (line kindreds), `data/knacks.json` (a knack per species),
  `data/dimorphism.json` (three Fieldbook sex notes).
- `tests/data_api/test_w48_monsters.gd` (8 tests: load, chains, stats, moves, sprites, habitat, sexes).

## See them
`tools/shot.sh out.png 14 --battle=shellhaven:20`, `--menu=pedia:longlegs`. Screens: `docs/screens/w48-m-*.png`.

## For the integrator
- `tools/test.sh` shows as modified in my worktree (an import lock added by something else); I did not commit it.
- Appendix species are the existing convention, so these add Fieldbook appendix pages, not core entries.
# Handoff: wave 48 Q (the critic), branch `w48-q-polish`

## What's here
- **HP bar "starts low after a Sanctuary heal"**: hunted through every path that sets a battle plate (see
  docs/audit/w48_q.md for the full trail). On the plate the bar and the numbers are the same two variables, so
  they cannot disagree; a frame-driven probe over two battles around a heal with the owner's own party never saw a
  mismatch. The one bar that did show "lower, with the right numbers" was the 4.6.0 Summary HP row (stat size out
  of 130), fixed on 30 Oct; the owner's saves are from 27 Oct, before that build. Added the missing regression tests
  (tests/ui/test_w48_q_critic.gd) and a real fix found on the way: `Forms.apply` now keeps a wild creature full
  when its regional form raises max HP (Skomer volet, Guernsey/Kerry moolet, seven overseas forms), so a foe's
  plate no longer starts part-drained.
- **Map route line** follows the drawn railway and ferry crossings (`MapLogic.route_legs`, used by
  ui/world_map.gd). Screenshot: docs/screens/w48-q-map-route.png.
- **Summary**: the selected move's info line now leads with the move's full name, so a long name trimmed in its
  row ("Bramble La...") can still be read.
- A critic's pass over pause, Team, Bag, shop, Settings, darts, bowls, Summary, battle menus, a town and a house:
  screenshots in docs/screens/w48-q-*.png; nothing else needed fixing.

## How to see it
- Route: `tools/shot.sh out.png 25 --menu=map:route` (Macclesfield to York: on foot to Stoke, then the railway
  via Sheffield and Leeds).
- HP probe (ticks real tweens, unlike the unit runner):
  `godot --headless --path . -s res://tools/dev/hp_probe.gd -- --battle-auto --foe-level=38 --save=<save.json>`
  prints `MISMATCH` on any frame where a plate's bar disagrees with its creature.
- Tests: `tools/test.sh w48_q`.

## For the integrator
- Small, additive edits only: core/forms.gd (`apply`), ui/map_logic.gd (new functions at the end),
  ui/world_map.gd (one call), ui/summary_screen.gd (one line), tools/dev/hp_probe.gd (new), tests (new file).
- On this loaded Mac, `tools/shot.sh` boots and battles need a 25 to 35 s delay or the shot catches the title.
