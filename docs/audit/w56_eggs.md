# Wave 56: eggs (spoilers)

Ten Easter eggs. None is needed for anything, none is mentioned in a menu or the Atlas. Each is a flag in the save
(`egg_*`, absent = not found); the title cat has no flag because nothing is saved on the title screen. Data is
`data/eggs.json`, logic is `core/eggs.gd` (pure, returns Commands lists), the in-world hooks are in
`world/eggs_scene.gd`, tests are `tests/core/test_eggs.gd`.

| Egg | Flag | Where | How to trigger | What is true in it |
|---|---|---|---|---|
| The box | `egg_box` | Trinity (Dublin), wicker basket at 3,7 (new prop) | Cat (`FamilyCat.is_lead`) first in the party, face the basket. Without her it is just a warm basket. | Schrödinger lived in Dublin 1939 to 1956 and worked at the Institute for Advanced Studies; the cat in the box is a 1935 thought experiment. |
| The grin | `egg_grin` | Macclesfield, Macclesfield Forest, Chester, Cat and Fiddle road | Cat in front, dusk (18:00 to 21:00), 12 steps into the zone. She vanishes, the grin stays a moment. | Lewis Carroll born at Daresbury, Cheshire, 1832; "grinning like a Cheshire cat" is older than Alice. |
| MONSTERQUEST cabinet | `egg_cabinet` | Golden Mile Amusements, Blackpool, cabinet at 11,2 (new prop) | Face it. Coin slot taped over; high-score table of one name: JIM. | Nothing factual claimed. |
| The Caesar slip | `egg_caesar`, item `w56_bp_slip` | Hut 8, Bletchley Park, table at 2,2 | Read the note (SXW WKH NHWWOH RQ, shift of three) and choose PUT THE KETTLE ON. Wrong picks say why and can be retried; "Leave it be" is free. Gives a key item once. | Caesar's shift of three for private letters (Suetonius). |
| The phone | `egg_phone` | Any outdoor zone with a `phone_box` prop | Within two tiles of a box, 00:00 to 00:59 local. It rings once; answer to hear the speaking clock, an hour fast. Walking on leaves it unfound and it does not ring again that visit. | Speaking-clock phrasing ("At the third stroke ... precisely"). |
| 42 | `egg_forty_two` | Cambridge, the phone box at 39,30 | Face it (any time). A card inside the glass. | Douglas Adams born in Cambridge 1952, studied at St John's, said 42 was a joke. |
| The bench | `egg_bench` | Blackpool, bench at 25,33 | Sit down before 19:00 (after 16:00) and stay until 21:00 or later (one sitting, so about 16 real seconds on the fast clock). Someone sits at the far end and says one thing, as you stand up. | Blackpool Tower opened 1894, inspired by the Paris tower, has a ballroom, about half the height. |
| Mum on the name | `egg_names` | Mum's kitchen (`macc_home`) | Call the cat Bagpuss, Schrödinger or Macavity (case and the umlaut do not matter); talk to Mum once the recipe book scene is done. Works for a cat at home too. | Eliot wrote a poem about a cat of that name. Characters are not named by the game, only by the player. |
| Bottle reply | `egg_bottles` | The Severn Crossing bottle | Find the Bath bottle ("Please send soap") first, then the Severn Crossing one: a second slip answers it. | The Avon (Bath) runs into the Severn. |
| Title cat | none | Title screen | Up Up Down Down Left Right Left Right B A. A small black cat (Sootkit's icon) walks across the bottom, nothing else. | Nothing. |

## Hooks (all one line each)
- `world/overworld.gd`: `EggsScene.arrive` after `FamilyCatScene.arrive`; `EggsScene.on_step` after the `Router.busy` guard in `_on_step`; `EggsScene.interact` before `ExamineScene.interact`.
- `world/bench_sit.gd`: `EggsScene.bench_stood` in `stand()` after the tween (loose-ends is editing this file too, so expect a trivial merge).
- `world/flotsam_scene.gd`: `Eggs.bottle_lines` appended to a find's lines.
- `story/script_hooks.gd`: `Eggs.hook` (Mum), before the offers are gathered.
- `ui/title.gd`: `_input` feeds `Eggs.feed`; `ui/title_cat.gd` is the walking cat.
- `tools/validate.gd`: `Eggs.check` (flags unique, zones and tiles exist, items real, no dashes, lines at most 150 characters).
- New props: `creature_basket` in `dublin_trinity`, `slot_machine` in `blackpool_arcade`. New item file `data/items/w56_eggs.json`.

## Unsure of
- The Blackpool bench: it is outdoors on the front but I did not check what it faces, so the Tower line is about the town, not a view.
- The `choice` command stores the pick in `egg_pick` (a leftover int in the save). Harmless; a small cleanup would be an `erase` op.
- The Cat and Fiddle road is on the Cheshire side of the Derbyshire border; I counted it as Cheshire.
- The cat's vanishing is text only (the follower sprite is not hidden), to avoid fighting `Follower`'s own visibility rules.
- A player who finds the Severn bottle before the Bath one misses the reply (it is not retroactive).
- The Mum hook is skipped until `mum_recipes` is set, so it never interrupts the first morning; a cat named before then gets her opinion on the next visit home.
- Playing the scenes in the real overworld was not exercised (no screenshots, no playtest): the Commands lists are tested against a fake host.
