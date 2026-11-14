# Wave 56: the playtest bot and the full story

## Causes
1. Points of interest are solid in the real game (PoiScene.dress sets `z.blocked`), but the bot's routing copies
   (`_routing_zones`) only knew about standing NPCs, field spots and flotsam. It planned straight through standing stones
   and camps and then reported `blocked repeatedly at (59, 25) in chat_moss`. Two of those sat ON the one-tile path.
2. `Poi.tile` was only `landing_near(near)`, so the generator's habit of using `path` tiles put solid props on paths.
3. `Pathfinder.route` treated every (zone, arrival tile) as its own search node. A walk-off edge gives one arrival per
   border tile, and each was flooded again; with the loops added by the 28 new routes a plan became 7 to 10 seconds.
4. `_find_grass` could choose a tall-grass tile that is a stone, field spot or flotsam tile as the training spot.

## Changes
- bot.gd: pois are solid in `_routing_zones`; `_find_grass` skips solid tiles.
- pathfinder.gd: remember which tiles each zone's earlier floods reached and skip a node that arrives on one of them
  (everything reachable from it was reachable already). Same legs, far fewer floods.
- poi.gd: `Poi.tile` now picks the nearest open ground (grass, tall grass, flowers, sand) that is not a doorstep, the
  station or ferry tile, the border or a one-tile gap, and whose being solid does not cut the zone in two. Cached per
  poi. New `Poi.placeable` and a validator rule in `Poi.check`. The sense cue, field-spot overlap check and PoiScene all
  go through `Poi.tile`, so they agree.
- tests/world/test_w56_poi_off_path.gd.

## Not a bug
`no route from liverpool to wirral_way` in `from` runs is a gate: Wardens stand on Liverpool's south edge (26..28, 55)
until the Liverpool beat is done. The grind-zone picker counts hops ignoring gates, so it soft-fails and picks again.

## Also fixed
- from-mode saves skipped the Geevor scene that posts the ferry ticket, so `holyhead/hh_sailor` could never sail:
  `_build_state_at` now sets the flag and gives the item once `ashcombe2_done` is behind it.
- `_plan` returns no route at once when the goal is across the sea (not in the gate-blind hop graph); proving it used
  to flood the whole map for about 4 seconds, four times per attempt.

## Proof
- `tools/playtest.sh from manc_bikes/bev+2 2`: PASS, no `blocked repeatedly`, no `slow route`.
- `from cardiff/kit+2`, `from holyhead/hh_sailor+2`, `from stonehenge/kit+1`: PASS. (`from edinburgh/kit+2` passes its
  beats but flags a soft-lock because a from-save has no `station_*` flags, so after a whiteout the bot cannot rail home.)
- GitHub full story, run 43640277475 on w56-bot: PLAYTEST PASS, 31h53m game time, 699 s wall. Only soft notes remain:
  gated training zones ("no route", expected) and `blocked repeatedly at (1, 16) in lake_district heading up` (3x).
- `tools/test.sh poi` 0 failed, `tools/test.sh w55_` 0 failed, `validate: 0 error(s)`.
