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
