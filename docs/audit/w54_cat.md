# Wave 54, cat: the family cat

## What was built
- A three-stage line only the player can have, `data/creatures/sootkit.json` (appendix, no habitat, kindred `uncanny` so nothing breeds):
  - **Sootkit** (night, 310 total, speed 80 / HP 38): evolves at level 16 or bond 220.
  - **Grimalkin** (night/fae, 430): evolves at level 32 or bond 240.
  - **Cat-Sìth** (fae/night, 530, white spot on the chest): final.
  - Knack **Nine Lives** (`endure_once`: once a battle a knockout blow leaves 1 HP). Signature move **Black Cat Crossing** (night, physical, 55 power, priority +1), learnt by all three at level 12.
  - Names: cy `cath ddu`, ga `cat dubh`, gd `cat dubh` (Cat-Sìth: `cat-sìth`). Facts are the "lucky in Britain" black cat, Graymalkin in Macbeth, and the Highland cat-sìth.
  - Recipes in `art/recipes/creatures/{sootkit,grimalkin,catsith}.json`, sprites rendered with `tools/spritegen.gd`.
- `core/family_cat.gd` (rules, validator rule, her follower lines), `story/cat_talk.gd` (the `family_cat` command), `world/family_cat_scene.gd` (the road scene, her NPC).
- API for phase 2: `FamilyCat.has(data)`, `in_party(data)`, `is_lead(data)` (plus `at_home`, `is_family`, `display_name`).

## How she joins
- **New game**: Mum's first-morning line says the cat has not touched her breakfast since the stones hummed. The first arrival on `cat_and_fiddle` with a party and not yet past the road (`scene_due`: no `cat_met`, no `visited_buxton`, no badge, par at most 7) plays `cat_scene` from `data/dialogue/cat_and_fiddle.json`. She is sat in a clear line a few tiles ahead, trots up, joins at the starter's level, and the family is asked what they call her (Meadow, or Something else which opens the nickname keyboard).
- **Old save**: a save past the road (`visited_buxton`, a badge or par over 7) and without `cat_met` is `waiting`. She is a runtime NPC in `macc_home` by the bowl (sprite is her stage at the time), Mum says she has been in the window since you left, and talking to her joins her at the story's par level, held to the best of the team (par 97 with a team best of 80 gives 80). The stage follows the level. A one-off Parish toast "A note from Mum" is shown on the first zone load outside the house (`cat_note`).
- Full team: she waits at home and is collected there.
- Mum also offers once a day to keep her by the bowl while she is with you; the cat at home offers to come along.

## Exclusive and permanent
- Validator rule `FamilyCat.problems` (called from `tools/validate.gd`): the line is appendix, habitat-free, not a legend, in a non-breeding kindred; no zone encounter table has it; no JSON file in `data/` other than her own file, `dex_order`, `genes`, `knacks` and the two scene files names her ids (this covers trainers, trades, hybrids, dens, field spots, gifts); the two scene files may not use `give_creature` or `starter` on her.
- No release or Ark: `ArkLogic.release_rule` refuses, `GameStateData.deposit` and `swap_with_ark` refuse, `add_creature_swapping` boxes someone else, and `FamilyCat.sync` (run on every zone load) rescues a stray cat from the Ark to home. There is no creature sale in the game. She is "put at home" via Mum, stored as `family_cat_home` (a creature dict flag).

## Hooks in shared files (one-liners or small)
`world/overworld.gd` (two lines: `_side_npcs` and `FamilyCatScene.arrive` in `load_zone`), `world/follower.gd` (her own `talk` lines, one block), `story/commands.gd` (one arm), `story/script_runner.gd` (one Host method), `data_api/story_validator.gd` (command name), `data_api/world_consistency.gd` (tokens `{cat}` and `{lead}`), `core/game_state_data.gd` and `ui/ark_logic.gd` (no-box guards), `tools/validate.gd` (one line), `data/genes.json`, `data/knacks.json`, `data/dex_order.json`, `data/moves/night.json` (one move).

## How to see it
- Road scene: `tools/shot.sh out.png 7 --shot-from-zone --boot=cat_and_fiddle@3,10`
- At home, old save: `--shot-from-zone --boot=macc_home@5,5 --flag=visited_buxton,mum_done,mum_recipes`
- Following: `--boot=macclesfield --cat=lead` (dev switch added in `FamilyCatScene`)
- Screens in `docs/screens/w54/`: `cat_road_scene`, `cat_battle_front`, `cat_battle_back`, `cat_at_home`, `cat_following`.

## Tests
`tests/core/test_family_cat.gd` (35 tests: the line, bond, move, Nine Lives in battle, exclusivity rule and its negative cases, no release or Ark, new game join, naming, full team, old-save join and par, note, saves round trip, leave and collect, Mum, follower lines).

## Unsure
- "Past the road" is inferred from `visited_buxton`, any badge, or par over 7; a player who somehow reached Buxton without ever walking the road gets the home path.
- The Welsh, Irish and Gaelic names are the plain "black cat" words, not folklore names (I was not certain of folklore forms).
- Bond thresholds 220 and 240 are my pick.
- No wild-creature-corners-your-starter variant; the road scene is a walk-up.
- Leaving her at home is only through Mum, once a day (not the Ark by design).

## For the integrator
Run the full suite once merged. The slice playtest was run with the scene active (see handoff reply).
