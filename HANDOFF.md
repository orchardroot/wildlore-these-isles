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
