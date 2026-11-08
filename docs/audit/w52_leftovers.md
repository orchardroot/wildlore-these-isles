# w52-left: the bug hunts' leftovers

Branch `w52-left` (from int-w51). The "left" lists of `w51_critic2`, `w51_places`, `w51_hud`, `w50_critic` and
`w50_world`, each checked on the merged build first. Every change was screenshot with `tools/shot.sh` (`open -g`,
no focus taken, quits by itself) and looked at. Before/after pairs: `docs/screens/w52-*.png` (map, shed, mill,
sign).

## Fixed

| What | Where | Fix |
|---|---|---|
| The world map's info panel sat over Ireland and the west, and the "Where next?" strip over London and Cambridge; the map could not scroll them out because it was clamped to its own edges | `ui/map_view.gd`, `ui/world_map.gd` | `MapView.inset`: the part of the view a panel keeps. The map centres the picked town in what is left and its edges may come out from under the panels, so Dingle (far west), London, Cambridge and St Helier (low down) all sit clear when picked. The Journal's "Show on map" keeps clear of its step strip too. `--menu=map:post:<town>` puts the cursor on any town. `map-before/after` |
| Deed huts behind other buildings' doors: York's allotment shed was an unseen second door in the Minster's west front, Lancaster's in the Castle, Whitby's boat hut in Whitby Station (whose own door it took, so the station's door opened the hut, not the departures), Dingle's in The Dolphin Gifts | `data/zones/{york,lancaster,whitby,dingle}.json`, the four rooms, `data/deeds/*` | each has a little building of its own: an allotment shed outside York's walls (69,10) and below Lancaster Castle (20,12); a tarred boat hut by Pannett Park in Whitby (17,41) and on the strand by the cove in Dingle (50,33). The rooms' way out and the Deeds' doors follow. The Castle, Minster and Dolphin Gifts now draw their real door (a building draws its last door), Whitby Station's door is the station again. `shed-before/after` |
| Mills drawn as Lancashire cotton mills | new `world/landmarks_works.gd` (`WorksStyles`) | Llynnon Mill: a stone tower windmill, dark cap, four sails, the door at its foot. The Laxey Wheel: the red wheel with white spokes on its white stone case, the tall pier with its gallery. Starcross Pumping House: red sandstone, round-headed windows and the square Italianate tower. Penzance's Engine House and Snailbeach (a plain cottage before): a Cornish engine house, roofless gables, the bob-wall arch and a round stack, brick at the top. `mill-before/after` (Laxey) |
| Name boards cut short abroad | `anguilla`, `turks_caicos`, `douglas`; `world/landmarks.gd` `_cave_mouth` | `tools/dev/sign_audit.gd` finds none of them cut from the building's own door; all four were cut from a little way off. Anguilla: Fountain Cavern sits on a two-deep plot and a shallow cave mouth piles its rocks lower, so "WALLBLAKE HOUSE" reads from the quay. Grand Turk: the two palms three tiles in front of the Ripsaw Bar step east. Douglas: the bunting along the Horse Tram Depot hangs two rows out, off the name. Stanley's Christ Church Cathedral was the screen edge from the spawn; it reads whole from the street, nothing to do. `sign-before/after` (Anguilla) |
| Guizer Magnus ("Viking gear, torches blazing") wore Blackpool's pink flower crown | `data/festivals.json`, new `art/recipes/chars/guizer.json`, `tools/spritegen/character.gd` | a guizer: winged steel helmet (new `viking_helmet` hat), beard, red cloak, a lit torch. Lerwick's Guizer Olaf, Jarl Sigurd and the Gathering Guizer (a bobble hat and two deerstalkers) wear it too |
| The Braemar Gathering (early September) was held on the snow by the Cairngorm ski centre | `data/festivals.json` | Caber Callum stands in the green glen at the west end of the zone (7,27) |
| Grytviken's Norwegian church was a white box with a small block and a thin rod on top | `world/landmarks_ice.gd` `_church` | a boarded tower over the door from the ground up, louvred belfry, a tall dark eight-sided spire and a gilt finial (Baddeck's Parish Hall shares the style) |
| Coracle and snorkel: a tie showed a silver rosette with "Not this time.", a near tie "You win by 0.0 seconds." | `ui/coracle_screen.gd`, `ui/snorkel_screen.gd` | "A dead heat. You need to beat the time, not match it." and "You win by a whisker." |
| The map's Standing line and the job hand-in lines said "in The Channel Islands" | `core/standing.gd` `mid_name`, `core/parish.gd`, `core/jobs.gd`, `ui/map_logic.gd` | "in the Channel Islands" |

Checked and already fine on int-w51: the Standing toast over the zone card (w51-hud), York Minster's colour (the
`minster` style), the crypt arrival, Wookey Hole's lamp posts, the moor bollards, Kyteler's back door, the starter
picker's "Field Station", sanctuary dressing; `sign_audit` finds 0 cut at Liverpool, Glastonbury and Belfast.

Tests: `test_map_view` (every town clear of a panel on either side), `test_deeds_boat_allotment` (each hut its own
building, one door, out on the step), `test_visual_qa` (the mills' styles, a tall mill, a low shed),
`test_festivals` (Braemar on the green, the guizer sprite), `test_coracle` (the dead heat), `test_first_hour`
(`mid_name`).

## Still left

1. With York picked, the info panel still covers Galway, Limerick and the far west: at the map's zoom the free
   part can't show York and Galway at once. Every town is clear when it is picked, and stepping west scrolls them
   out; a smaller panel or a lower zoom would show more at once.
2. Stanley's Christ Church Cathedral is the white `chapel` box; the real one is red brick with a square tower.
3. The `cathedral` style is one west tower and a nave for every church that shares it (w51-places).
4. Signs behind tree belts that need a hand-picked spot, and props on one-tile paths (w50-critic 7 and 8).
5. Interiors where the keeper waits right inside the door; dense woods round two field pieces; crowded arrivals at
   Diego Garcia and Pitcairn (w51-critic2 6, 7, 9): read as deliberate, left.
6. The Gazetteer header with dev-save numbers (w51-critic2 8), only reachable on a dev save.
7. Exeter's "Six bells up the stairs" against a real ring of twelve; compass directions to other places unchecked
   (w50-world).
8. The cold open's humming stone against the pub wall, and the Vane Tower summit nook (w50-critic 9, 10): cosmetic.
