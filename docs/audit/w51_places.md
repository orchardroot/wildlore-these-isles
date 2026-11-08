# w51-places: places that look like what they are

Branch `w51-places` (from int-w50). The w50 critic's and world sessions' leftovers: buildings and rooms that didn't
look like what they are. Every change was screenshot with `tools/shot.sh` (`open -g`, no focus taken, quits by
itself) and looked at. Before/after pairs: `docs/screens/w51-places-*.png`.

## Fixed

| What | Where | Fix |
|---|---|---|
| York Minster (Keeper Hester's venue) was the red sandstone `cathedral` block and read as a mill | `data/zones/york.json`, new `world/landmarks_minster.gd` (`MinsterStyle`) | its own `minster` style in pale magnesian limestone: twin west towers with pinnacles and parapets, the great west window (mullions, transom, the heart in its head) over a pointed portal, stepped buttresses, the nave under a lead roof, a central tower over the crossing taller than the west towers, transepts with lancets and the Rose Window in the south transept. `minster-before/after/after-wide` |
| Switching the Minster's style lost its gold Keeper board: a style with no wall mode got a lectern | `world/signage.gd` `_sign` | a keeper's hall always gets its black and gold board: the style's own front where there is room (`MinsterStyle.sign_front`: over the portal, under the window), else `_keeper_front`, centred over the door and standing just proud of whatever is there. This also gave Belfast Yard its keeper board back (it was a lectern; `ulster_terrace` has no wall mode). `belfast-yard-before/after` |
| St Michael's Tower (Glastonbury's Keeper venue) had a keeper board with its name 0 high: the gatehouse face between the drum towers is half a tile wide | same | the board moves out across the towers when the name would be under `KEEPER_MIN_EM` (0.15). `keeper-board-before/after` |
| Names squeezed past reading on their own board (no board cut a name: the critic's "THE CAVERN (ISH" and "PORT OF LIVERPOOL BUILDIN" are the screen edge from Liverpool's spawn; both read whole from their doors) | `Signage.MIN_EM`, `_wall_em`, `_proud_front` | a heritage or attraction name whose capitals would be under 0.1 of a tile high goes on a lectern (the small mills' roofline panels: Starcross Pumping House 0.036, Laxey Wheel 0.039, Llynnon Mill 0.066, Penzance Engine House 0.081; Clifton Suspension Bridge 0.022); a castle gate carries a stone tablet across its drum towers (Micklegate, Bootham, Walmgate and Fishergate Bars, St Michael's Mount: 0.08 to 0.10, now 0.21 to 0.25) |
| The sign audit couldn't see a name that didn't fit its board | `world/sign_sight.gd` `audit`, `tools/dev/sign_audit.gd` | `audit` now reports each name's height (`em`) and `overhang` (a ray behind each end of the lettering finds no board); the tool lists "RUNS OFF ITS BOARD" and "TOO SMALL" (under 3/4 of `MIN_EM`). Over all 1,539 outdoor signs: 0 now (10 too small before) |
| Every `cathedral`, `limestone_church` and `pennine_church` front (Chester, Liverpool and about 30 more) had square windows on a flat wall | `world/landmarks.gd` `_cathedral` | pointed lancets between buttresses, a pointed belfry light; kept under the name band. Checked Chester and Liverpool by eye |
| All 103 Sanctuaries were a counter, a bookshelf and two plants: a reading room | `data/zones/*_sanctuary.json`, new `world/sanctuary_props.gd` (`SanctuaryProps`) | the restoring cabinet behind the counter (green cross, a tray of six glowing hollows, a heartbeat on its screen), a shelf of medicines, bandages, treats and towels, two creature baskets (one with a sleeper), the noticeboard and two posters. Placed by script only where every person, the counter and the door stay reachable. `sanctuary-before/after` |
| Kyteler's Inn: "The back door" examine spot was a bare wall | `kilkenny_kyteler` 1,3 | a planked back door on the west wall (new `back_door` prop, `world/place_props.gd`, turned with `rot`) |
| Wookey Hole's show cave was lit by street lamp posts | `wookey_hole` 13,17 and 18,17 | braziers. `wookey-before/after` |
| A street bollard on the Pennine grouse moor (two, flanking the track at 12,30 and 16,30) | `pennine_grouse_moor` | stone gateposts (`standing_stone` 0) |
| Honister's Slate Mine furnished as a house (dresser, rug, plants, floorboards) | `lake_slatemine` | stone floor, stacked slates, a slate wagon; the slate heap, table, clock and picture stay |
| Starter picker header "Professor Garside's field station" | `ui/starter_picker.gd` | "Field Station" |
| York Minster crypt arrival hidden behind tall stone blocks | `york_minster_crypt` | checked: w50-world's low rubble lip has cured it, nothing to do |

Dev: `--photo-view=yaw,pitch,zoom` with `--photo` (e.g. `0,-14,1.35`) frames a tall front whole for a screenshot.

Tests: `tests/world/test_minster.gd`, `test_sign_fit.gd`, `test_sanctuary_dressing.gd`, `test_place_looks.gd`.

## Found, not fixed

1. **Deed huts behind other buildings' doors.** York's allotment shed is reached through a second door in the
   Minster's west front (`york` 33,18); Lancaster's allotment shed through Lancaster Castle, Whitby's boat hut
   through Whitby Station, Dingle's through The Dolphin Gifts. Each wants its own little shed or hut on the map.
2. **Mills that are not mills.** Llynnon Mill (Anglesey) is a tower windmill drawn as a Lancashire cotton mill;
   the Laxey Wheel (Douglas) a waterwheel drawn the same; Starcross Pumping House and Penzance's Engine House too.
   `windmill_black` is a tower mill but draws no door (Llynnon has one, to `anglesey_mill`); `engine_house` is the
   Swansea copper works' (its stack is capped in copper slag), so neither is a straight swap.
3. **Signs still hidden from their doors** (the audit's other list, unchanged by this branch, sign sight is
   w51-hud's): Clifton Suspension Bridge (81%, now a lectern behind the tree there), Tŷ Te in Gaiman, Spanish
   Frontier Post, Lord Street Tea Rooms (18% each), Finnieston Crane and Carfax Tower (9%).
4. Station platform totems are small by design (names 0.08 to 0.09 high, the big board on the canopy carries the
   name); lectern names run 0.08 to 0.12. Neither is flagged.
5. The `cathedral` style is still a single west tower and a nave; it suits Chester and Liverpool (both red
   sandstone), less so the limestone churches that share it.
