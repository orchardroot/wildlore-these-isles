# w55 roads-celtic handoff

Branch `w55-roads-celtic` (from `int-w55`). A choice of road in Wales and Ireland: eight new routes, each turning a line into a loop, and a test that proves none of them is a sequence break.

## Missing links found
Neighbouring real places with no direct way between them (from `core/zone_graph.gd` and the zone edges, after allowing for the four Enclosure lease edges, which take Beacons north, Antrim Coast west and Lough Gur east at runtime):
- Wales: Yr Wyddfa and the Cambrian Coast (only via Llanberis); Yr Wyddfa and Ogwen; Llangollen and Aberystwyth; Swansea and Cardiff (only via the Beacons). Also dead ends: Holyhead, Gower, Blaenavon, Hafod Cwm.
- Ireland: Cork and the Ring of Kerry (only the one road); Kilkenny and Limerick; the Burren and Limerick; Wicklow and the Comeraghs (the Wexford and Waterford coast).
- Northern Ireland and Donegal: Lough Neagh and Bushmills; Enniskillen and Donegal Town; Derry and Enniskillen.
- Not buildable: the Valleys (Merthyr, Rhondda, Blaenavon) have no free border facing the Beacons; Dublin to Kilkenny (Kilkenny's only free north edge went to the Cashel road); Enniskillen's north is Lough Erne itself; the Isle of Man is a single zone (Douglas) and I did not attempt it.

## Routes built (8)
| id | real road or path | joins | gate |
|---|---|---|---|
| `aberglaslyn` | Aberglaslyn Pass, A498 and the Welsh Highland trackbed, by Beddgelert | Yr Wyddfa (west edge) and Cambrian Coast (east) | `ch3_ddraig_woke`, Wardens at the Yr Wyddfa end |
| `pen_y_gwryd` | A5 into Capel Curig, A4086 past Pen-y-Gwryd, the Miners' Track | Ogwen (south) and Yr Wyddfa (east) | none (both open on the road to Llanberis) |
| `llyn_tegid` | A5 and A494 by Corwen and Bala, on towards the coast | Llangollen (south) and Aberystwyth (east) | `ch3_ddraig_woke`, Wardens at the Llangollen end |
| `glamorgan_coast` | Wales Coast Path on the Heritage Coast, back through the Vale by Llantwit Major | Swansea (east) and Cardiff (south) | none |
| `healy_pass` | R574 Healy Pass and the Beara Way | Cork (south) and Ring of Kerry (west) | none |
| `golden_vale` | the road through Thurles and Cashel | Kilkenny (north) and Limerick (east) | none |
| `clare_road` | the old N18 by Bunratty and Ennis | Burren (south) and Limerick (north) | none |
| `hook_head` | the Wexford coast road to Hook Head, then west to the Waterford Greenway | Wicklow (south) and Comeraghs (east) | none |

Each: 9 to 11 grass and 4 to 7 water encounter entries of existing species at the par of the places it joins (`scaled_floor`, lifts with the story), three trainers (files in `data/trainers/`, `scaled_floor` set), three or four plaques with true history, four or five signs, two people to talk to, a den and a stone or cache (`data/poi/w55_celtic.json`), a field spot (`data/field_spots/w55_celtic.json`), and a place on the world map. Nothing the story needs is on them. Rail, ferry and Where next? are untouched.

Existing zones changed: only a three-wide gap cut in the border at the join (written as text, rows and heights only) and the new edge; any other walkable tile on that border is closed with a tree, since an edge makes every one an exit. Zones touched: `yr_wyddfa`, `cambrian_coast`, `ogwen`, `llangollen`, `aberystwyth`, `swansea`, `cardiff`, `cork`, `ring_of_kerry`, `kilkenny`, `limerick`, `burren`, `wicklow`, `comeraghs`. `data/world_map.json` gained eight `places` on its one line.

## Never a sequence break
`tests/world/test_w55_roads_celtic.gd` with `tests/support/w55_reach.gd` and the baseline `tests/fixtures/w55_roads_celtic_reach.json`, written from the unchanged game and committed before any route. It walks the zone graph at every story step (`data/objectives.json`): edges and warps tile by tile, standing NPCs with `hide_if` or `show_if` as in the bot's `_routing_zones`, every field ability granted, ferries and trains modelled by seeding the player at each story step's town. The outdoor places reachable at each step must equal the baseline apart from the new zones. It reproduces the real gates (Cambrian Coast after the dragon, Ireland after `badge_kin`, Belfast after `ch7_judged`, the Antrim coast after `badge_iron`). `test_w55_celtic_routes.gd` adds a check with teeth: take the Wardens off a gated road and the place beyond it opens a step early. Gated roads use the same flag as the existing gate in front of the same place. The new Wardens are ordinary NPCs, so the bot's `_routing_zones` already treats them; no bot edit.

## Test results (my own fragments only)
- `w55` (both files, 9 tests): `9 passed, 0 failed` after the last route.
- `tools/validate.gd`: `validate: 0 error(s)` after every route.
- Earlier, with route 1: `test_zone_data` 34 passed, `test_coverage` 5, `test_world_consistency` 7, `test_leases` 24, `test_p6_story` 38, `test_field_spots` 8, all 0 failed.
- **Skipped on the integrator's instruction:** the full `tools/test.sh`, `tools/playtest.sh slice 2`, and the economy simulation. Also not re-run after routes 2 to 8: the six named suites above (validate and `w55` were).
- No screenshots taken.

## Economy
No new way to earn that repeats. The new trainers pay once: 24 trainers, about 30,700 in sterling in purses in all (money by top level, the formula the other trainers use), spread over the story. No camps, no cash caches (items only). `EconomySim` reads jobs, deeds, trade and the rest, none of which this branch touches, so its output is unchanged; I did not run it. Integrator: please run it once.

## Unbuilt
`tools/zones/w55_lower_bann.py` (Lough Neagh to Bushmills, gate `badge_iron`) and `w55_erne_shore.py` (Enniskillen to Donegal Town, gate `badge_iron`) are written and pass the generator's own checks but were never run into the game or validated, and are not in the runner's list. Their entries already sit in `ROUTES` of `test_w55_celtic_routes.gd` (skipped while the zone file is absent). To build one: add it to `ROUTES` in `w55_celtic.py`, run `python3 tools/zones/w55_celtic.py <name>`, then `tools/test.sh w55` and the validator.

## Unsure of
- Healy Pass: "built as relief work" and the Tim Healy naming; kept vague.
- Dursey cable car (sheep and cattle carried), Nash Point (two lights, one since switched off, no dates), Hook lighthouse ("among the oldest working", built by the Marshal family), Brian Boru crowned "in the 970s", the Welsh Highland and Glaslyn osprey dates (2004 first nest). All widely stated; worth one more eye.
- Welsh and Irish kept to words I am sure of: Gorllewin, Dwyrain, Gogledd, Croeso, Bore da, Bedd, "Dw i'n dysgu Cymraeg", Sláinte, céilí, sliotar, camán, Caiseal, Inis.
- The generator wires a wanderer into one-tile gaps if I let it; every person on these routes stands still.
- Scenery is generated; I looked at the ASCII, not the render. The integrator's pictures will show if a building sits oddly.

## Notes for the integrator
- Generator: `tools/zones/w55_celtic.py` with `w55_lib.py` and one `w55_<name>.py` per route; safe to re-run.
- Shared files touched: `data/world_map.json` (eight places), the fourteen zone files above (a gap and an edge each).
- Merge order: the England and Scotland sessions' baselines are their own; mine compares every outdoor zone in the world, so another session's road that opens a place early will fail my test too, which is the point.
