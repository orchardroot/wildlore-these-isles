# Wave 50 world: the world matches what it says

Session "world", branch `w50-world`. The owner found a cave guide saying "pull the lever by the desk" with the lever
across the room drawn as a street bollard, caves drawn as cottages, and a cave gate drawn as a field fence on grass
that opened on to a garden path. Those three were fixed on the base branch. This pass looks for every other case,
systematically: a checker over all the data, then a look at every fixed place in the game.

Reproduce: `.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/world_check.gd` prints every
finding (open and kept) with a count per rule, about ten seconds after the zones load. `tools/validate.gd` runs the same
check and fails on any finding not kept in `data/world_consistency.json`.

## 1. Deep Places look like their lines

`core/deep_place.gd` used to set a closed gate's tile to `fence` (a green field fence on grass) and an open one to
`path` (a brown garden path), with every crate a pallet of roofing slates, every plate a patch of limestone pavement and
every lever the same lever. Now:

- A closed gate is a solid prop on the room's own floor, and an open one is just that floor. The gate is drawn as its
  line says (`DeepPlace.LOOKS`, `look_of`): cave gate (bars, padlock), grille (rusty lattice), timber gate (planks,
  braces, a chain), barrier (striped arm), oak door (banded, in a stone frame), slab, basalt slab or flowstone. It always
  faces the camera, so a gate across a passage that runs east and west still reads as a gate.
- A lever is a lever, a sluice wheel (verdigris rim, brass hub), a winch (drum on trestles, crank, rope), a weir board
  (lifts in its frame), a brass handle in a wall box, a basalt column with a hollow, or a crack in a lump of rock for the
  hidden pockets the Lantern finds. Each shows its pulled state.
- A crate is a boulder, a coal tub on rails, a slab on a little bogie, a block on a timber skid, or a basalt column-end.
  A plate is an iron plate in a stone rim, lower and darker once pressed.
- The look comes from the piece's own words (first matching word in its line; a crate's id), or a `"look"` key, which
  `DeepPlace.problems` checks is a known one. Old saves need nothing: the state is still only flags.
- Facing a closed gate and pressing Confirm reads its line, so "a lever by the desk, perhaps" is said where you look.
- Meshes in `world/deep_meshes.gd`; `ZoneBuilder` builds them like any point prop.

Seventeen zones have a `deep` block, all screenshot before and after (lantern light, gate in view): aillwee_entry,
aillwee_gallery, aillwee_haven, blaenavon_bigpit_east, blue_john_chamber, blue_john_entry, blue_john_stream,
dyo_cathedral, dyo_entry, dyo_river, marblearch_cladagh, marblearch_deep, staffa_columns, staffa_hollow, wookey_chamber,
wookey_hole, wookey_river. Between them: 17 gates, 19 levers, 7 crates, 7 plates and 6 floods.

Data fixes in the deep zones:

- Blue John and Aillwee entrances had stage null, so plaster walls and a tiled floor: now `"stage": "cave"` with a
  stone cave floor. Dan yr Ogof's entry is a visitor centre, as the real one is, and keeps its floor.
- Wookey Hole: the hatch lever was at the far wall by the guide while its sign and the gate both say "by the water's
  edge"; it and its sign now stand at the water's edge.
- Wookey Hole, River Axe passage: the sluice wheel stood on a wall tile, buried in rock; it is on the floor beside it.
- Fingal's Cave: the crate is the "loose column-end" the sign describes (`"look": "column"`).
- Big Pit: the sign spoke of "a tram of 1936 timber" and "a crate on rails"; it now names the coal tub on rails that is
  there.

Cave rooms, for all 39 cave interiors (`ZoneBuilder.is_cave`): the rock wall in front of the camera is now a low
rubble lip (as a plaster room has a low skirting there) and the side walls are lower, so the room and its gate can be
seen. Stalactites hang only in the dark caves, and never in the three tiles in front of a prop, sign, person, gate or
way out: in the lit show-cave entrances a hanging cone and its hard brazier shadow read as a post standing in front of
the gate.

## 2. The checker

`data_api/world_consistency.gd` (`WorldConsistency`), seven rules. Fast enough to run in the validator (about ten
seconds over 1,540 zones and 1,532 dialogue files on a loaded machine), deterministic (sorted zone order, no clocks).

| Rule | What it flags | Found | Fixed | Kept, with reason |
|---|---|---|---|---|
| object | a line points at a findable thing ("pull the lever", "mind the levers", "the boat behind me", "the judge is by the gate") and the zone, its outside and up to three rooms on through the cave or building, has nothing like it | 30 | 8 | 19 (figures of speech, recipes, history) |
| near | "the lever by the desk", "a lever near the water": both exist here but not within two tiles | 0 after the base fix and the Wookey move | 1 (Wookey hatch) | 0 |
| stairs | upstairs, downstairs, down the steps, through the back, the back room, the back door, in a room with one way out | 39 | 6 | 33 (the real building's other floors) |
| cave | a warp into a cave, mine or tunnel (dark, cave stage, or the name says so) whose outside is not drawn as an entrance (`ENTRANCE_STYLES` or a portal prop beside it) | 10 | 4 | 6 (real visitor centres and buildings) |
| entrance | an outdoor warp with no building, no door tile, no portal, not on the map edge and not at the end of a path | 4 | 1 | 1 (the Skye fairy ring) |
| blocker | a warp you can only reach with a Stone's ability (or a warp `gate`), and no sign or person within 8 tiles of the first blocking tile names the Stone or the ability | 3 | 3 | 0 |
| text | unknown `{tokens}`, stray braces, TODO/XXX/FIXME/TBD, a doubled little word, odd double quotes, " ,", " ." and ".." | 1 (19 before the doubled-word rule was narrowed to little words: "crex crex", "James James", "Aye aye" are meant) | 0 | 1 (A A B B A, the limerick) |

Also in `DeepPlace.problems`: an unknown `"look"` is an error.

Fixed by rule:

- object: Dover Museum ("the boat behind me": now "the boat in these cases", which flank the curator); Smeaton's Tower
  ("Up the ladders to the lantern if you dare": no way up, now the keepers went up ladders between the rooms); Shetland
  (the show judge "by the gate": there was a gap in the wall and no gate, now a field gate stands in it); the Chat Moss
  and North York Moors signal boxes ("Mind the levers": a counter, now a lever frame of seven levers); the Enclosure
  agent on the Pennine grouse moor ("Mind the gate, it bites": no gate, now the grouse are spoken for); Big Pit and
  Fingal's Cave as above.
- stairs: the Ark at Brize Norton, La Linea and Sheffield is behind the counter (was through the back, or up the
  stairs); the Brighton rock maker sends you to the counter, not a shop through the back; the Bodleian librarian and the
  Radcliffe Camera clerk send you to the Eagle and Child on St Giles', not to a back room it hasn't got.
- cave: Blue John Cavern in Castleton (a grit terrace), the Jersey War Tunnels and Dover's Secret Wartime Tunnels (stone
  buildings) are cave mouths; Wookey Hole had nothing (below). Christian's Cave on Pitcairn and the Jersey War Tunnels
  inside were plaster rooms: now rock.
- entrance: Wookey Hole on the Mendips was a path tile between two rocks in a cliff: now a dark cleft in a rock outcrop
  (`cave_cleft`), open right through so it reads from the camera's side, on the warp's own tile so arrival is unchanged.
- blocker: signs naming the Stone, ability and Keeper by the water at Wookey Hole (added to the existing sign), by the
  Chat Moss brambles (added to the existing sign) and on the Ring of Kerry shore facing Innisfallen (new sign).

## Leftovers

- `kilkenny_kyteler`: the examine spot "The back door" is a bare wall; there is no wall-door prop yet. Kept in the list.
- `lake_slatemine` ("Slate Mine") is furnished as a house (dresser, rug); kept as Honister's visitor centre, but it
  could do with a mine-office look. `mendips_cave` ("Cave Tours") is a museum hall where the guide says "found a
  skeleton here"; kept as the Cheddar ticket office and museum.
- Wookey Hole's show cave has street lamp posts and green grass inside (encounter grass); not a text mismatch, left.
- Street bollards stand in odd places (one on the Pennine grouse moor at 16,30); they may be stand-ins for waymarks.
  Not checked: no line points at them.
- Exeter Cathedral's ringer says "Six bells up the stairs". The real ring is twelve bells (fourteen in the tower); it
  matches the minigame, so it is a facts question for whoever owns the bells, not a world one.
- Compass directions to other places ("Newgrange is just east of here", "the kirkyard to the south-west") are not
  checked: they need the world map, not the zone.
- The object rule looks across the zone and the rooms beyond, not near the speaker; the near rule covers "X by the Y".
