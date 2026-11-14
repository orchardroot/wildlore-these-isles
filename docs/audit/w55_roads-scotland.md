# Wave 55, roads-scotland: a choice of road in Scotland

Branch `w55-roads-scotland` (from `int-w55`). Ten new roads that turn the lines of Scotland and its islands into loops.
England to Scotland border crossings are the England session's, the Celtic nations are the other session's; none of
their files are touched.

## What was missing (found before building)

From `core/zone_graph.gd` and the zone `edges`, the Scottish outdoor zones joined like this before the wave: a long
spine (Cairnryan, Galloway, Glasgow, Glencoe, Fort William, the Great Glen, Inverness, then the Cairngorms to Aberdeen),
with Loch Lomond and Oban, the Central Belt and Edinburgh, Fife and Dundee, the Borders and the far north hanging off it.
Neighbouring real places with no way between them, and dead ends that could be joined up:

| Dead end or gap | Why it hurt |
| --- | --- |
| Scottish Borders (one edge, to Edinburgh) and Galloway | the Southern Upland Way between them did not exist |
| Loch Lomond and Glencoe | no West Highland Way over Rannoch Moor |
| Glencoe and Fort William | only the one road; no Devil's Staircase, no Kinlochleven |
| Loch Lomond and Oban | one road; no Pass of Brander |
| Central Belt and Dundee | Dundee was a dead end off St Andrews; nothing through the Trossachs or Strathearn |
| Dundee and Aberdeen | no Angus coast road; Aberdeen reached only through the Cairngorms |
| Skye and Portree | one road; no Trotternish |
| Stornoway and Harris | one road; west Lewis and Uig missing |
| Lerwick and the Shetland Mainland | one road; no Scalloway |
| Galloway and Cairnryan | one road; the Machars (Wigtown, Whithorn) missing |

Left alone: Kirkwall and Tobermory (a single town zone each, no neighbour to join), Thurso to the Pentland coast and the
Flow Country (dead ends at the top of the map; nothing real to join them to that is not already there), and the
Cairngorms to Royal Deeside: Aberdeen has only one free side (north), which the Angus coast uses, and the Cairngorms'
south is the Coire Dubh lease's gap, so the Lairig Ghru and Deeside would have had to be a cul-de-sac. Not built.

## The ten routes

All are `kind: route`, `region: scotland`, `scaled_floor` at the par of the places they join (so the walk lifts them with
the story like their neighbours), three-tile mouths, two edges whose offsets cancel. Each has 10 or 11 grass entries and 6
or 7 water entries (15 to 17 species, existing species only), two or three plaques, three or four trainers (one new
trainer file each, `scaled_floor` set), four or five talkers, and a point of interest trio plus one field spot.

| id | Real road or path | Joins | Gate |
| --- | --- | --- | --- |
| `southern_upland_way` | Southern Upland Way: Wanlockhead, St Mary's Loch, Tibbie Shiels Inn | Galloway east, Scottish Borders west | none (both ends open at ch9_started) |
| `west_highland_way` | West Highland Way over Rannoch Moor, Bridge of Orchy | Loch Lomond north, Glencoe east (south half) | none |
| `devils_staircase` | the Devil's Staircase and Kinlochleven | Glencoe west (north half), Fort William east | none |
| `pass_of_brander` | Rest and Be Thankful, Loch Awe, Pass of Brander under Ben Cruachan | Loch Lomond south, Oban north | none |
| `rob_roy_way` | the Rob Roy Way: Loch Katrine, Balquhidder, Doune Castle, Strathearn | Central Belt north, Dundee west | none |
| `angus_coast` | the Angus coast road: Arbroath, the Bell Rock, Dunnottar | Dundee east, Aberdeen north | three Wardens (`gate_angus_a/b/c`, `hide_if badge_frost`) across the Aberdeen end, the same flag as the Inverness gates |
| `trotternish` | the Trotternish loop: the Storr, Quiraing, Kilt Rock, Staffin, Kilmuir | Skye south, Portree west | none (both open at badge_frost) |
| `uig_road` | west Lewis: Gearrannan, Dun Carloway, Uig sands | Stornoway west, Harris east | none |
| `scalloway_road` | the A970 to Scalloway, Tingwall | Lerwick north, Shetland Mainland west | none |
| `the_machars` | Wigtown, Whithorn, the Solway shore | Galloway west, Cairnryan east | none |

Plaques (23, all new `w55_sc_*` ids): Wanlockhead, Tibbie Shiels, the West Highland Way, Rannoch Moor's floating railway,
the Devil's Staircase, Kinlochleven, Rest and Be Thankful, the Pass of Brander, Loch Katrine, Rob Roy at Balquhidder, the
Declaration of Arbroath, the Bell Rock, Dunnottar, Flora MacDonald, the Storr, Staffin's dinosaurs, the Lewis Chessmen,
Dun Carloway, Scalloway Castle, the Shetland Bus, Tingwall, Wigtown, Whithorn and St Ninian. They feed the Gazetteer
total (the "every plaque" milestone is now 23 plaques further off; its payout is unchanged).

Off the path, each road has a cache, a stone or a den and a camp (30 POIs in `data/poi/w55_scotland.json`) and a field
spot (10 in `data/field_spots/w55_scotland.json`, each a verb the game already has: mend, line, topple, round_up, charm,
loft). Rewards follow the existing numbers (field money is 32 times the route's top level; camps 300 + 40 times it).

## How to reach them in play

Step off the named side of the named zone: for instance, the east side of Galloway toward the north end leads onto the
Southern Upland Way; Loch Lomond's north-west road leads onto the West Highland Way; Aberdeen's north side leads onto the
Angus coast (and is held by Wardens until the Frost Stone is won). The "Where next?" card, rail and ferry are untouched.
The new places are on the world map (`data/world_map.json` places, one text edit to that line).

## Never a sequence break: how it is proved

`tests/support/story_walk.gd` (new, pure) walks the zone graph tile by tile with the flags a player has at each step of
`data/objectives.json`: every still NPC holds its tile unless its `hide_if` flag is set or its `show_if` is not, hidden and
locked warps are shut, edges and open warps are followed, and a station and (inside Scotland) a ferry quay start a walk
again. Between nations a ferry is taken only when the story sends you (`ARRIVALS`: visited_dublin, ch9_started), and the
two gates whose flag a battle sets rather than a story step are bridged with `IMPLIED` (strachan1_done to
trainer_strachan_1, badge_frost to trainer_keeper_isla). No field abilities are granted (the main road never needs one).
`tests/world/w55_walk_baseline.json` records the first step at which each of 154 outdoor zones can be walked to, made on
the unchanged game and committed with the test BEFORE the first route (`tools/dev/w55_walk_baseline.gd` regenerates it).
`tests/world/test_w55_roads_scotland.gd` then asserts that every one of them is still first reachable at the same step,
that no zone that was unreachable is now, and that each new zone opens no sooner than the earlier of the places it joins.

What the baseline says about Scotland: Cairnryan and everything south of the Great Glen from Fort William down, plus Dundee,
Fife, Oban and Tobermory, open at step 17 (ch9_started); Inverness and Loch Ness at 18; Skye, Portree, Harris, Stornoway,
the Cairngorms, Aberdeen, Lerwick, the Shetland Mainland, Kirkwall and the far north at 20 (badge_frost). So nine roads
join places that open together, and the Angus coast is the one that would have let a player from Dundee (step 17) reach
Aberdeen (step 20) early: its Wardens hide on `badge_frost`, which is why Aberdeen is still step 20.

Nothing the story needs is only on a road: every new zone is a loop beside an existing way.

## Tile changes to existing zones (all by text patch, so the rest of each file is byte for byte as it was)

Each joined zone gets one `edges` entry (put first, so it does not sit beside an entry another session appends) and a
three-tile path cut through the border rows to the land behind (two to nine tiles deep, and the heights of those tiles
set to match, in the zones that have heights). Three zones also lost stray walkable border tiles on the side that now
leads somewhere (a bit of beach at Aberdeen's north edge, a pier end at Stornoway's west and on the Mainland's west),
turned into the blocked tile beside them. `tools/zones/w55_sc_roads.py` rebuilds all of it (`w55_sc_lib.py`, `w55_sc_kit.py`,
`w55_sc_hills.py`, `w55_sc_coast.py`); it is idempotent. Zones touched: galloway, scottish_borders, loch_lomond, glencoe,
fort_william, oban, central_belt, dundee, aberdeen, skye, portree, stornoway, harris, lerwick, shetland_mainland, cairnryan.
The playtest bot builds its routing blockers from the zone files and the flags, so it picks the new tiles and the new
Wardens up with no change to `tools/playtest/bot.gd`.

## Economy

No new way to earn beyond the existing once-only field spots and camps, priced as the neighbours', and the Gazetteer's
milestone payouts are unchanged. `tools/dev/economy_sim.gd 20` run on the base (`int-w55`) and on this branch gives
byte-identical output (lumps 51,840; first lease day 81; all ten leases day 132 to 315 by strategy; d360 cash 164,868
for the plain run). The sim reads nothing this wave changed.

## Tests

RESULTS

## What I was unsure of

- Facts, all written to the Gazetteer's standard (plain, checkable, no figures I was not sure of): the Wanlockhead miners'
  library (no date given), Tibbie Shiels "from the 1820s", Kinlochleven's smelter closing "in the 1990s" and the old works
  now holding an ice-climbing centre, the Staffin footprints at "about 170 million years", red kites "from 2001" in
  Galloway, Loch Awe "about twenty-five miles". Worth a second pair of eyes from someone who has been.
- Gaelic is only the handful of words everyone knows (Failte, Moran taing, Slainte mhath, Beannachd leibh), each in a line
  that says what it means.
- The gates: the model finds Strachan's blocker in Glencoe is not a chokepoint (Fort William is step 17, not 18), so the
  Devil's Staircase needed no gate of its own; if that blocker is meant to be airtight, the Staircase and the Glencoe
  west edge need `strachan1_done` Wardens like the Angus road's.
- Map coordinates for the ten new "?" places are placed by eye between their neighbours.
- Layouts, sprites and props were checked by the validator and tests only (no screenshots, per the brief), so the look of
  each road is untested by eye. Several are blocky (the Staircase's zigzag in particular).

## Notes for the integrator

- Shared files touched: `data/world_map.json` (one line, ten places added), the sixteen zone files above (edges and a few
  border rows), and new files only otherwise (`data/poi/w55_scotland.json`, `data/field_spots/w55_scotland.json`,
  `data/trainers/{swy,whw,dev,brn,rrw,ang,trt,uig,sca,mac}_*.json`, `data/dialogue/<zone>.json`).
- No `tools/playtest/bot.gd`, `tools/validate.gd` or `CHANGELOG`/`README` edits, no version bump.
- A merge conflict is possible in `scottish_borders.json` (the England session adds a south edge to the same `edges`
  block) and `aberdeen.json`; mine is the entry at the top of the block.
- Aberdeen has one free side (north) and Fort William one (east): both are now spoken for, so the next road that wants them
  has to go through a new zone rather than through them.
