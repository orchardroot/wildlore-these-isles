# Wave 56, secrets: places that are not on the way to anywhere

Branch `w56-secrets`. Fifteen hidden places, each a small room behind an ordinary `hidden` warp, each a real kind of place at
a real spot with one thing worth the trip that is not money. Everything is additive and every new flag defaults to "not
yet", so an old save sees nothing change until it walks up to something.

## The mechanism

- **`core/secrets.gd` and `data/secrets.json`** list the fifteen: the room (`secret_*`), the outdoor zone that hides it, the
  tile of the hidden warp, the reveal flag, how it is revealed, whether it needs the coracle, and what is inside.
- **The way in** is the existing `hidden` warp with a `reveal` flag (`ZoneData.warp_state`). Until the flag is set the warp
  is simply not there: the tile is ordinary ground. Nothing else leads to a room (the tests check there is exactly one
  warp to each, no edge and no script).
- **What sets the flag** is something in the world: nine are a resident's rumour (a new resident in the outdoor zone, who
  tells you and sets the flag), four are an examine spot in the outdoor zone, one a message in a bottle among the rocks and
  one only at dawn (each of those six has a new resident who hints where to look). The dawn one is a new optional `phase` on an examine spot (and an
  `off` line for the wrong hour), read by `ExamineScene`.
- **Coracle** warps carry `"coracle": true` and sit on a water tile. `ZoneData.validate` proves each is reachable with both
  rides (`CORACLE_ABILITIES`) and every other warp on foot. `RideCheck.exits` skips a warp into a `secret_*` room, because a
  dead end is not a gate and the coracle opening it is the point. `RideCheck` is still at 0 errors. You step back out on to
  the shore.
- **First entry** is a "HIDDEN PLACE  ·  3 of 15 found" zone card (`Secrets.note`, held by `Discovery.note`; the card
  gains a `label` and a `sub`, the outdoor zone's name), with the same small treat for the party that a new place gives.
  A hidden place is not in the places tally, is not a room of any town (the tourist board does not wait on one: `ZoneIndex`
  leaves them out of `town_rooms`) and is not a room in the Atlas.
- **Examine finds** of a curio now also tick the Curios page (`Examine.read`, three lines); chapbooks and curios are
  ordinary items.

## How the three screens show them

- **Sense cue.** `Discovery.nearby_unfound` gains a `secret` kind: a revealed place you have not been into, not yet sensed,
  within five tiles of its way in. It is the first thing the list returns, and it also runs in towns (three of the places are
  in towns), which meant `SenseCue` no longer returns early there when a zone has secrets. The gold "!" rises over your
  follower, once per find, and the first time says one line (`Intros` card `secret`). Unrevealed places are never offered.
- **Atlas.** The header reads "N of 217 places found  ·  hidden places 3 of 15". Each region that hides any shows a
  "Hidden places  1 of 2" bar below its six. It is deliberately outside the six, so no stamp waits on one
  (`Atlas.hidden_rows`; `Atlas.rows` and the stamps are untouched).
- **Map.** A ringed keyhole at the outdoor zone that hides each place you know how to open, filled gold once you have been in
  (`Secrets.marks`, one line in `MapLogic.marks`, a `secret` icon in `MapView`).

## The fifteen

| Place | Zone it hides in | Reveal | Inside | Coracle |
|---|---|---|---|---|
| Sgwd yr Eira, the cave behind the Fall of the Snow | `beacons` (Wales) | examine the water where it drops into the pool; a walker hints | chapbook: Drench | no |
| Paviland Cave, the Red Lady's sea cave | `gower` (Wales) | an old fisherman's rumour | Selklet pup (grey seals pup in sea caves) | yes, sea |
| Bryn Celli Ddu, passage tomb aimed at the midsummer sunrise | `anglesey` (Wales) | examine the wall stone at dawn only; an early riser hints | a view and plaque (the light in the chamber) | no |
| Merlin's Cave, the sea cave under Tintagel Island | `tintagel` (England) | a message in a bottle among the rocks | a view and plaque (Tennyson, 1848) | yes, sea |
| Combe Down stone mine | `bath` (England) | an old stonecutter's rumour | Flittermouse (stone mines are bat hibernation sites) | no |
| Mortimer's Hole, the passage under Nottingham Castle | `nottingham` (England) | the castle rock guide's rumour | chapbook: Dark of the Moon | no |
| A priest hole (Oxburgh Hall) | `the_fens` (England) | a hall guide's rumour | a letter that starts a trail (a tin by the water, a pocket watch) | no |
| Gatti's ice well, beside the Regent's Canal | `london` (England) | examine the old brick by the water; a canal boater hints | curio: Jar of Old Pennies (on the Curios page) | no |
| St Herbert's cell, on the lake island | `keswick` (England) | a lakeside angler's rumour | a letter that starts a trail (three stones, pressed flowers) | yes, lake |
| Spar Cave, the calcite cave on Strathaird | `skye` (Scotland) | a Strathaird crofter's rumour | chapbook: Moon Pull | yes, sea |
| A Loch Tay crannog | `rob_roy_way` (Scotland) | a young archaeologist's rumour | Ospret (ospreys of Perthshire's lochs) | yes, lake |
| A border tower's undercroft | `reivers_road` (Scotland) | a border farmer's rumour | Moolet calf (the cattle slept under the family) | no |
| A souterrain | `boyne_valley` (Ireland) | examine the flat stone by the old hedge; a farmer hints | curio: Tara Brooch Copy | no |
| The Great Stalactite, Doolin | `burren` (Ireland) | examine the gap in the limestone; a cave guide hints | a view and plaque (seven metres of stone) | no |
| The smugglers' store on the Brandy Pad | `mournes` (Northern Ireland) | a hill walker's rumour | a letter that starts a trail (the third stone, a tea caddy) | no |

Five need the coracle (three on the near-shore sea, two on lakes). That needs the Tide Stone for the sea (Keeper Nuala,
Galway) and the Urban Stone for the lakes (Keeper Ray, Liverpool), which is the same as the rest of the coracle. Nine
rewards are things (a creature, a curio, a chapbook), three are letters, three are views. Each room has a sign with a true
plaque, and examine text.

## How to get at each in play

Talk to the person (their id is `sec_*` in the outdoor zone's `data/dialogue/<zone>.json`), or look at the spot, then follow
the sense cue's "!" to the way in. After that: step on the tile. The tile of each is in `data/secrets.json`; the examine spots
are the outdoor zone's examine entries with a `secret_*_known` flag.

## Tests and validator

`tests/core/test_w56_secrets.gd` (run with `tools/test.sh w56_secrets`): data lines up and `Secrets.problems` is empty; at
least five coracle, two on the sea, five nations; the warp is hidden at the start and open once revealed; nothing else leads
in; foot places are walked to and coracle places are not; the reveal can happen (the examine spot reads, the rumour sets the
flag, the dawn spot has its off line); each rumour is spoken by a resident; the HIDDEN PLACE card pays once and is not in the
places tally; they are no room of a town or the Atlas; the sense cue calls you once revealed and not before, once, in range;
the map marks and ticks; the Atlas line and region row; old saves and the catch-up see nothing; each room holds its
creature, item, letter or view; a field-found curio ticks the Curios page; no dashes and every `say` fits two lines.

Results, on this branch:

- `tools/test.sh w56_secrets`: `16 passed, 0 failed`, then `validate: 0 error(s)`, no `SCRIPT ERROR`.
- `tools/test.sh w55_` (the three story-order tests and the rest of the wave 55 files): `34 passed, 0 failed`, `validate: 0 error(s)`.
- Run directly with the runner (no import): `test_discovery` 11, `test_atlas` 8, `test_intros` 6, `test_ride` 20, `test_zone_data` 34, `test_coverage` 5,
  `test_world_consistency` 7, `test_letters` 4, `test_examine` 11, `test_map` 29, all 0 failed.
- The validator's `RideCheck` stays at 0 errors with all fifteen in. I did not run the full suite or the playtest, as briefed.

## What I was less sure of

- **Placement is a stylisation.** The outdoor zones are abstractions of an area, so each warp is put by a script
  (`tools/zones/w56_secrets.py`, spots kept in `w56_secrets_spots.json`) next to the right kind of feature (water for the
  waterfall and the coracle places, a cliff for Mortimer's Hole, a hedge for the souterrain), clear of every sign, resident,
  warp and prop. The Beacons has a pool, not a waterfall; London's well is by buildings, not at King's Cross. I would
  rather say so than pretend. Moving one is a one-line edit of the spots file and a re-run.
- **Facts I am sure of**: Buckland at Paviland 1823 and the Red Lady being a young man; Edward III, Mortimer and
  Nottingham Castle in October 1330, Edward seventeen; Bede on Herbert and Cuthbert dying on the same day, 687; Scott at
  Spar Cave in 1814; Tennyson at Tintagel in 1848; Gatti shipping Norwegian ice to the Regent's Canal from the 1850s; the Brandy
  Pad as a smugglers' track over the Mournes; the 1585 Act making it treason to be a seminary priest in England; Johnnie
  Armstrong of Gilnockie hanged in 1530.
- **Facts I am fairly sure of, worded loosely so they stay true**: Oxburgh Hall has a priest hole (I do not say where the way
  in is); the Combe Down mines and Bath's greater horseshoe bats (a Special Area of Conservation; I say "bats, including the
  greater horseshoe"); about eighteen crannogs in Loch Tay and the oldest "about two and a half thousand years"; the Great
  Stalactite is seven metres ("one of the longest free-hanging in Europe"); souterrains "from about the 700s" and "thousands
  known"; Bryn Celli Ddu "about five thousand years" and the midsummer sunrise down the passage; grey seals pupping in sea
  caves round Wales; ospreys at the Loch of the Lowes; "the Borders were raided for centuries".
- **The letters are invented** (as every paper in `data/letters` is), but each is plausible for the place and the trail is a
  dig spot in a nearby outdoor zone. Their curio rewards go in the bag and are not ticked on the Curios page (`Letters.dig`
  does not, and I left it alone).
- **Level of the creatures.** Each is a `give_creature` with the outdoor zone's average encounter level as both level and
  `scaled_floor`, so it lifts with the story like every other off-the-line gift and evolves to suit.
- **Not done**: a contract's clue as a reveal, and real tide tables for the sea caves (the game has no tide; the sea places
  are simply near-shore sea, coracle only). The dawn reveal uses the game's own hours (5 to 8).
- **Shared files touched**, each a few lines: `core/discovery.gd`, `core/atlas.gd`, `core/zone_index.gd`, `core/examine.gd`,
  `core/intros.gd`, `world/sense_cue.gd`, `world/examine_scene.gd`, `ui/atlas_screen.gd`, `ui/map_logic.gd`, `ui/map_view.gd`,
  `ui/zone_card.gd`, `data_api/zone_data.gd` (the `coracle` warp check), `data_api/ride_check.gd`, `tools/validate.gd`, and
  `data/world_consistency.json` (fifteen "the way in is hidden on purpose" entries for the `cave` rule). Fifteen outdoor zone
  files and their dialogue files gained one resident each, and some an examine spot.
