# Wave 55: roads-england (a choice of road, England and the two borders)

Branch `w55-roads-england`, cut from `int-w55`. Ten new routes, each joining two real places that had no direct way
between them, none of which lets anyone reach anywhere earlier than the story allows.

## The missing links I found

From `core/zone_graph.gd` and the zone `edges`: England's outdoor zones are mostly a line (Macclesfield, Buxton,
Manchester, Liverpool, then everything north of Sheffield is behind one set of Wardens). Dead-end towns, one edge each:
Blackpool, Haworth, Stoke, Hull, Lincoln, Poole, Plymouth, Exeter, Penzance, Brighton, Dover. Real neighbours with no
direct way between them, and what I did about each:

| Pair | Real link | Built? |
| --- | --- | --- |
| Haworth and Blackpool | Pendle Way, Ribble Valley | yes (road 1) |
| Lake District and North York Moors | Wainwright's Coast to Coast | yes (road 2) |
| Hull and Lincoln | Humber Bridge, Ermine Street | yes (road 3) |
| Carlisle and Hadrian's Wall | Hadrian's Wall Path (west) | yes (road 4) |
| Carlisle and the Scottish Borders | Border Reivers' road, Gretna | yes (road 5, England to Scotland) |
| Ironbridge Gorge and Birmingham | Black Country, canals | yes (road 6, gated) |
| Poole and Stonehenge | Wessex Ridgeway, Cranborne Chase | yes (road 7, gated) |
| Bletchley Park and Cambridge | Varsity Line | yes (road 8) |
| Brighton and Dover | Cinque Ports, Romney Marsh | yes (road 9, gated) |
| Shrewsbury and Llangollen | Offa's Dyke Path | yes (road 10, England to Wales) |
| Macclesfield and Manchester | Middlewood Way, Macclesfield Canal | no: Manchester's only free side is north |
| Chester and Macclesfield | the Cheshire plain, salt towns | no: free sides would need a long invented zone |
| Leeds and York / Sheffield | Calder Valley, Trans Pennine Trail | no: would open York early; needs a badge_spirit gate and a free Leeds side |
| Manchester and Sheffield | Snake Pass | no: Sheffield's only free side is east |
| Exeter and Glastonbury | Parrett Trail, Blackdown Hills | no: sides do not line up |
| Bath and the Cotswolds | Cotswold Way | no: Bath's only free side is south |
| Lancaster and Blackpool | Fylde coast, Morecambe Bay | no: kept for the next wave |

## The routes

All zones are `kind: route`, with `scaled_floor` so they lift with the story, `region` as noted, six or more encounter
entries per zone (16 to 20 here), four or five trainers each (50 in all), three or four plaques (36 in all, ids start
`w55e_`), four or more plain signs, one stone, one cache, one den or camp, one field spot (see `data/poi/w55_england.json`,
`data/field_spots/w55_england.json`). Each is on the world map (`data/world_map.json` places).

| # | Zone id | Real road or path | Joins | Gate |
| --- | --- | --- | --- | --- |
| 1 | `pendle_hill` | Pendle Way over Pendle Hill, Brontë moors, Leeds and Liverpool Canal | Haworth (west) to Blackpool (east) | none, both open at `starter` |
| 2 | `swaledale` | Coast to Coast Walk: Nine Standards Rigg, Keld, Richmond | Lake District (east) to North York Moors (west) | none, both `badge_spirit` |
| 3 | `humber_bridge` | Humber Bridge and Ermine Street | Hull (south, a bridge laid across the estuary) to Lincoln (north) | none |
| 4 | `hadrians_wall_path` | Hadrian's Wall Path: Lanercost, Irthing gorge, Birdoswald | Carlisle (east) to Hadrian's Wall (west) | none |
| 5 | `reivers_road` ("The Debatable Land") | Border Reivers' road: Esk, Debatable Land, Gretna, Hermitage | Carlisle (north) to Scottish Borders (south), England to Scotland | none |
| 6 | `black_country` | Black Country canals: Netherton anchors, Cradley Heath chain, Dudley | Ironbridge Gorge (east) to Birmingham (west) | Wardens across the road until `badge_spirit` |
| 7 | `cranborne_chase` | Wessex Ridgeway: Badbury Rings, Knowlton, Pitt Rivers | Stonehenge (south) to Poole (north) | Wardens until `badge_spirit` |
| 8 | `varsity_line` | Varsity Line: Cardington sheds, Bunyan, Sandy | Bletchley Park (east) to Cambridge (west) | none |
| 9 | `romney_marsh` | Cinque Ports coast: Hastings, Rye, military canal, Dungeness | Brighton (east) to Dover (west) | Wardens until `moot_won` |
| 10 | `offas_dyke` | Offa's Dyke Path: Welshpool, Chirk, Pontcysyllte | Shrewsbury (west) to Llangollen (south), England to Wales | none, both open at `badge_urban` |

Gated routes use the same flags as the existing gates between the same places (`sheffield_warden` is the model: still
`warden_grunt` NPCs with `hide_if`, in a gap in a hedge bank that runs right across the zone, so nothing can walk round).
The gate NPCs are `bc_gate_*`, `cc_gate_*`, `rm_gate_*`.

How to reach them in play: walk off the named side of the named town or route. Haworth west, Blackpool east,
Lake District east, North York Moors west, Hull south, Lincoln north, Carlisle east and north, Hadrian's Wall west,
Scottish Borders south, Ironbridge Gorge east, Birmingham west, Stonehenge south, Poole north, Bletchley Park east,
Cambridge west, Brighton east, Dover west, Shrewsbury west, Llangollen south.

## Proof that nothing opens early

`tests/world/test_w55_roads_england.gd` with `tests/world/w55_reach.gd` (the flood) and `tests/world/w55_england_golden.json`.
The golden file records, for the unchanged base (written before the first road, test passing, commit "sequence-break test"),
the first story step at which each of 121 places can be walked to. The flood walks zone to zone through edges and warps,
across every walkable tile of each zone with all field abilities counted as known, with the standing `hide_if` NPCs
(the Morris Men, Wardens, Marshals) blocking until their flag is set. The 28 states are the start, then after each
objective in `data/objectives.json`, with an extra state between `starter` and the rest for the Kit fight, and the
trainer flags the objectives do not list (`kit1_fought`, `trainer_strachan_1`, `champion`). With all ten roads in, every
old place has the same first step, and the ten new places are all reachable by the end. Rail and ferry are untouched.
This models walking only, as the zone graph does; rail needs a rail pass and a known station, so it is as before.

The test also checks each road: joined both ways with mirrored offsets, validates clean, par scaled, 6 or more
encounter entries and levels near the floor, 2 or more plaques with unique `w55e_` ids and no dashes, 4 or more trainers
whose files carry the same `scaled_floor`, on the world map, a point of interest and a field spot, the gate flag matches
the table, and the zone builds.

## Edits to existing files

* Zones that gained an edge and a 3-tile-wide cut through their border (text edits of `rows`, `heights` and `edges` only):
  `haworth`, `blackpool`, `lake_district`, `north_york_moors`, `hull` (a road laid across the estuary), `lincoln`,
  `carlisle` (two edges, one over the river), `hadrians_wall`, `scottish_borders`, `ironbridge_gorge`, `birmingham`,
  `stonehenge`, `poole`, `bletchley_park`, `cambridge`, `brighton`, `dover`, `shrewsbury`, `llangollen`. In `brighton` one
  stray shallow tile on the east edge became sea, because the validator wants every walkable border tile to land somewhere
  walkable. The edits are made by `tools/zones/w55_lib.py` (`link`, `cut_gap`).
* `data/world_map.json`: ten entries appended to `places` (this is one very long line, expect a trivial merge conflict
  with the other roads sessions; keep both sets).
* Three tests asserted that Haworth, Blackpool and Poole were dead ends; each now allows the new edge:
  `tests/world/test_pennines.gd`, `tests/world/test_lancashire.gd`, `tests/world/test_channel_islands.gd`.
* Border crossings necessarily touch two other nations' zones: the south edge of `scottish_borders` (Scotland) and the
  south edge of `llangollen` (Wales). Neighbouring sessions should treat those two sides as taken. `beacons` north
  turned out to be a lease edge (`hafod_hill_farm`), so Offa's Dyke does not go there.

Generators: `tools/zones/w55e_<road>.py` each, `w55_lib.py` shared, `w55_plan.py` (dry run of where a gap would go),
`w55_view.py` (ASCII view). Run from the repo root, e.g. `python3 tools/zones/w55e_pendle.py`; each is idempotent.
`tools/dev/roads_golden.gd` rewrites the golden file (only on purpose).

## Economy

Roads add no recurring income. What they add is one-off: 50 trainers (£1,213.90 in all, each paying once, par scaled
like their neighbours), 3 camps (£110 in all), field spot money (£19.60) and a handful of items from caches. A run of
`tools/dev/economy_sim.gd` before the first road and after the last gives identical lines, because the simulation
models the repeatable earners (jobs, quiz, stud, shows, dishes, trade) and none of this:

```
b0   = 1257 / day,  b2 = 3099,  b4 = 5017,  b6 = 6910,  b8 = 9127,  b10 = 11724 (pence per real day)
```

The one-off total is under a week of mid-game earnings and is spread over ten optional roads.

## Tests

See the final handoff message and the bottom of this file for the result lines.

## Unsure of

* Plaque facts are written from memory and kept to well-known claims, but a pair of eyes on these would help: Lanercost
  (Edward I's winter and where he died), Birdoswald (turf wall west of the Irthing), Dudley Castle (surrender 1646),
  Llanthony was dropped with the Hay route, Eliseg's Pillar (copied 1696), Chirk Castle (1290s, Roger Mortimer),
  Cardington (48 of 54 died), Gretna (1754 act), Hermitage Castle (Mary, October 1566).
* The Welsh used is `Croeso i Gymru`, `Chwarae teg`, `Tref-y-clawdd` only.
* The dens use species that are not on their route's table (`hobthrust`, `eildonmare`, `megalorn`, `longman`, `tormane`);
  `megalorn` and `longman` are legend-adjacent lines, so check you are happy with those two.
* Gates: I model a gate as "the standing NPCs hide_if flag". If a later wave uses an ability gate (bramble, scree) the
  flood counts every ability as known, so such a gate would not show up as a gate in the test.
* The bot (`tools/playtest/bot.gd`, `_routing_zones`) reads the zone files itself, so the new gaps and gates are picked up
  without edits; I made no change to it.
