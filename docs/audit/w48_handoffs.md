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
# Wave 48 F: field pieces (HM half)

Built: out in the world, a creature that knows a field party piece deals with a nook; otherwise a hint names the piece and where it is taught.
- `core/field_spots.gd` (pure: data, flags, hints, map marks, validator `FieldSpots.check`), `world/field_spot.gd` (props, interaction, creature animation, hop).
- `data/field_spots/<region>.json`: 239 spots across 22 regions, generated by `python3 tools/field/gen_field_spots.py` (deterministic, beside the path, reachable, off poi/props/npcs). 3 hop pairs (1 coracle, 2 felled trunks) plus ~19 near minigame venues. Lease zones skipped on purpose.
- Verbs: mend, skim, topple, line, round_up, charm, snorkel, paddle, roll, loft. Props are meshes built once per kind.
- Hooks (one line each): overworld.gd (`FieldSpot.dress`, `FieldSpot.interact`), tools/validate.gd, ui/map_logic.gd and ui/map_view.gd (green ring on the map once seen, ticked once done).
- Tests: tests/field/test_field_spots.gd.

Integrator:
- The "STUB party pieces" commit (core/party_pieces.gd, ui/piece_prompt.gd, GameStateData.pieces) is a stand-in for w48-p-pieces: drop it and keep P's.
- A spot is known-state when `PartyPieces.entries()` has an entry with `"field": "<verb>"` and a party member (not fainted) knows its `move`. Until P's data lands every spot shows its hint (fallback names in `FieldSpots.VERBS`). Needs: P field entries mend (walling), skim, topple (caber), line (crabbing); G1 round_up, charm; G3 snorkel, paddle; G2 roll; G4 loft.
- Not exercised here (no piece data yet): the known-state animation and rewards. Test them once P and G data are merged: give a creature the move and face a spot (e.g. `--boot=wirral_way@13,57`, coracle two tiles north).
- Flags: `<flag>` once-only done (hop spots stay usable), `<flag>_seen` set within 6 tiles.
- Screenshots: docs/screens/w48-f-trunk.png, -coracle.png, -sheep_gate.png, -map.png. Screens need `shot.sh` delay about 45 on a loaded machine.
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
# Wave 48 G4: road bowling and Poohsticks

Built:
- Road bowling: `core/road_bowling.gd`, `ui/road_bowling_screen.gd`, `data/road_bowling.json` (venues cork, armagh). Power and swing, bent lane, Run lofts over the first half of the flight, fetched back from the nettles, the local searches for a good throw each turn. Fewest throws wins (a draw is possible).
- Poohsticks: `core/poohsticks.gd`, `ui/poohsticks_screen.gd`, `data/poohsticks.json` (venues oxford, ashdown). Read the current, pick a lane and a stick, five races, optional stake paid by the story command.
- Story: `story/road_bowl_run.gd` (`road_bowl`, `poohsticks`), one case each in `story/commands.gd`, `data_api/story_validator.gd` known commands and venue checks, router keys `roadbowl` and `poohsticks`, TrainerStats counters `roadbowl_won`, `poohsticks_won`.
- Places: Cork (45,33) and Antrim coast (29,35) for road bowling; Oxford (58,29) and South Downs (27,46) for Poohsticks. Each has a plaque and a dialogue script in the zone's dialogue file.
- Pieces: `data/party_pieces/g4.json` (road_bowling: lofted_bowl, field verb `loft`; poohsticks: under_the_bridge), `data/moves/pieces_g4.json`. Move ids are unique in the tree.

Integrator notes:
- `core/party_pieces.gd` and `ui/piece_prompt.gd` are STUBS (commit "STUB party pieces"); drop P's real files over them. Both screens call `PiecePrompt.after_game(self, "road_bowling" | "poohsticks", score)` once at the end; scores are throws (lower is better) and races won of 5.
- Piece thresholds: road bowling good 10 and master 7 throws (local median is 10); Poohsticks good 3, master 4 wins.
- `tools/test.sh` was left uncommitted (integrator lock).

See it: `tools/shot.sh out.png 26 --menu=roadbowl:dev` and `--menu=poohsticks:dev`; `--menu=roadbowl:armagh` or `poohsticks:ashdown` start a real match. Screens in `docs/screens/w48-g4-*.png`. Tests: `tools/test.sh road_bowling`, `tools/test.sh poohsticks`.
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
