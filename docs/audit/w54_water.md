# Wave 54, water: take the coracle

Branch `w54-water`. The whole of the water is now somewhere a player can go, with a boat that looks like one, a few
reasons to paddle, and a validator rule that keeps it from skipping a single story gate.

## The rules as built

- **Rivers and lakes.** With Brook-wade (the Urban Stone from Keeper Ray in Liverpool, unchanged) every `~` tile is
  crossable, as `o` always was. Old saves get it at once: it derives from the badge.
- **The sea.** New ability `tide_ride`, from the Tide Stone (`FROM_BADGE["tide"]`, Keeper Nuala in Galway, which is the
  `badge_tide` she hands over in `galway_docks`). It crosses `$` tiles within 3 tiles (a square) of anything that is not
  sea or void. Old saves with the Tide Stone get it at once.
- **Never across a zone edge.** A `~` or `$` tile on a border side that has an edge stays solid; the block hint is
  "The current's too strong here. You'd be swept off into the next county." `o` is left as it was (it never had the rule,
  and is the validator's baseline).
- **Never indoors or in a Deep Place** (`ZoneData.ride_zone()`), and never inside a zone's `no_ride` rects (a list of
  `[x, y, w, h]` in the zone JSON; absent = none).
- **Where it lives.** `ZoneData.can_ride`, `ride_zone`, `in_no_ride`, `sea_near_shore` (data_api/zone_data.gd); `walkable`
  asks it for `water` and `sea` tiles, so every consumer (Pathfinder, `reachable`, the bot, the overworld) agrees.
  `ZoneData.NO_RIDE` is a marker an ability list can carry to turn riding off: `GATE_ABILITIES` carries it, so the
  validator's existing layout checks (corks, ferry, examine spots, gates) keep meaning "on foot" and a river never opens
  a route for them. `GATE_NAMES` is the list of valid `gate` names.
- **Block hints.** `FieldMoves.verdict` and `block_hint` cover `water` and `sea`: "Too wet to cross on foot, but a coracle
  would do it. You'd need Brook-wade, which comes with the Urban Stone from Keeper Ray in Liverpool." and "The sea, and
  you've no boat for it. You'd need Tide-ride, which comes with the Tide Stone from Keeper Nuala in Galway." Open sea far
  from any shore, and water indoors, is simply a wall with no speech. A bump says it once per kind per visit
  (`FieldMoves.hint_key`), not once per tile, so walking along a riverbank is not a lecture.
- **Encounters.** `Encounters.roll` maps `water` and `sea` tiles, as well as `deep_water`, to the zone's `water` table at
  5 per cent a step (sachets and lures apply as on grass); no table, no encounter. Fishing is untouched (`sea` tiles stay
  salt, and you can fish from the coracle).
- **People stay out.** `Overworld.can_enter` now answers `"wade"` (not `"ok"`) on a ride tile and `Npc._can_step` wants
  `"ok"`, so wanderers and pacers never paddle. (This also stops them wading into `o` on a save with Brook-wade, which they
  could before.)

## Tiles and zones that became crossable

Outdoor zones only (rooms are never crossable).

| | tiles now crossable | of | zones |
|---|---|---|---|
| fresh (`~`, Brook-wade) | 25,797 | 25,977 | 129 (every zone with `~`) |
| sea (`$` within 3 of a shore, Tide-ride) | 28,778 | 65,606 | 85 (every zone with `$`) |

180 fresh tiles stay solid because they are on an edge side. 179 of the 202 outdoor zones now have some crossable water.
135 outdoor zones have a `water` encounter table that could never fire; those with ride water now roll it.

## `no_ride` rects, and why

One zone: **inverness** (`[[47, 0, 1, 4], [53, 0, 1, 4]]`, 8 tiles). The Kessock bridge at the top of town is a road
over the Beauly Firth with the Bridge Engineers (`kessock_works`, hide on `badge_frost`) stood across it. The sea within
three tiles of the bridge is ridable, so with Tide-ride you could paddle round the engineers to the bridge's north end
(the warp and the north edge beyond) and, from the bridge, down to every door in town. Two one-tile walls of sea along
the bridge's flanks close it, with the rest of the Moray Firth still open.

The audit's other leaks (galway, cardiff, tintagel, belfast, dublin) were all border tiles: with the edge rule switched off
the check finds one leak each in belfast, cardiff, galway and tintagel and two in dublin; with it on, none. So the edge
rule did that work and they need no rects. The check also runs a "lacking one Stone" scenario for every ability gate in a
zone (chat_moss hedge_lay, enniskillen, mendips and ring_of_kerry brook_wade, yr_wyddfa fell_scramble): none leak.

## The validator rule

`data_api/ride_check.gd` (`RideCheck`), called from `tools/validate.gd`. For every outdoor zone with water: the story's gate
NPCs are solid; from every way in (the spawn, each warp that lands there, each land border tile of a neighbour across an
edge, one per walking region if the zone has no ledges) the warps and edges reachable with the coracle must be the warps
and edges reachable without it. A leak is an error naming the exit and the entry, and the fix is a `no_ride` rect.
Dev: `godot --headless --path . -s res://tools/dev/ride_leaks.gd` lists leaks with timings (about 10 s).

**What counts as a gate NPC** is my own reading: the repo has no list of "the 21 gate scripts". A still NPC in an outdoor
zone with a `hide_if` and no `show_if`, whose flag is `badge_*`, `trainer_*`, `chN_*`, `champion`, `moot_won`,
`kit1_fought`, `starter` or `ashcombe1_done` (`RideCheck.is_gate`). That is every Warden, Marshal, Bridge Engineer and RAF
Police scripts plus their silent `hide_if` walls (London's south gate, Stonehenge). Widening it to every still `hide_if`
NPC finds nothing more.

## It looks and feels like a boat

`world/coracle_boat.gd` replaces the brown cylinder: a lathed round hull in tarred dark brown with a wicker inside and a
withy rim, a paddle held out over the right-hand rim that dips as you move, a slow bob and roll, a soft ring of ripple
(CPUParticles3D, off on Low) that stays where the boat was. The rider stands still in it. Height: `Overworld.ground_y`
puts the rider at the water surface for every ride tile (a rider used to sink 0.3 to 0.5 under on `~` and `$`). The
paddle sound is the existing `splash` sample, quiet and pitched up, alternating; I did not add a sample because
`tools/audio` and `core/audio_ids.gd` belong to the air session. Speed: the run key paddles briskly (5 tiles a second, not
7 on foot). The follower: a brook, tide or gale lead swims (sits low) or flies (hovers) alongside; other leads stay hidden
as before. The bike rules are unchanged (no bike on the water; you hop off and push off).

## Flotsam

`core/flotsam.gd`, `world/flotsam_scene.gd`, `data/flotsam.json` (written by `tools/flotsam/gen_flotsam.py`, which mirrors
the ride rules in `tools/flotsam/ridemap.py`; the validator re-checks every find with the real ones).

**66 finds in 65 zones**: 22 messages in bottles, 18 crates, 14 lobster pots and eel traps, 12 caches on islets and far
banks. Every bottle is a one-line place joke with a fact in it (Aquae Sulis, the Mathematical Bridge's date, the Ha'penny
Bridge toll, Up Helly Aa, Neptune's Staircase, ...). Rewards are one small item, never money (food from the existing
healing items, fish, sea glass or a slate chip, honey, berries, a snare, a bag of hazelnuts).

Each find is a flag (`flotsam_<zone>_<n>`, absent = not found). A floating find stands solid on its tile until taken (face
it, confirm); a crate, pot or bottle bobs on the swell (the `bobbing` material), a cache is a cairn with a tin.
Validator: unique ids and flags, real items, no money, no dashes; each find is on water a coracle can float on (with at least
three open sides, so it never corks a channel) or on land, never within a step of anything reachable on foot from any
entry, reachable by coracle from the spawn, and not under a prop, person, sign, door or field spot. The 30 water-hop field
spots are untouched and still the way across before the Stone.

## Test results

Run singly in the foreground-equivalent, no full suite: test_zone_data 34/0, test_field_moves 9/0, test_pathfinder 6/0,
test_coverage 5/0, test_world_consistency 7/0, test_field_spots 8/0, test_leases 24/0, test_p6_story 38/0, test_fishing 17/0,
test_follower 23/0, test_qol_world 9/0, test_economy 8/0, test_ambience 22/0, test_galway_docks 3/0, test_yr_wyddfa 4/0,
test_deep_place 13/0; new: test_ride 20/0, test_flotsam 13/0, test_ride_check 8/0 (run with test_ride earlier).
`validate: 0 error(s)`, no SCRIPT ERROR. `tools/playtest.sh slice 2`: PLAYTEST PASS (Keeper Maud beaten, 96 battles, 3025 bot s).

## How to see it

- Lake: `tools/shot.sh out.png 30 --boot=keswick@20,11 --ride=coracle --lead=dolphlet --quality=high`
- River: `--boot=chester@34,48 --ride=coracle` ; sea: `--boot=penzance@52,43 --ride=coracle`
- A find: `--boot=penzance@50,43 --ride=coracle --find=49,43` (use a shot delay of 60: the text types slowly under load)
- A block hint: `--boot=penzance@43,43 --hint=47,43`
- New dev switches: `--ride=coracle` (badges brook, urban, tide), `--lead=<species>` in an overworld boot, `--find=x,y`,
  `--hint=x,y` (an overworld `_dev_radio` branch each).

All five screenshots on the brief's list (lake, river, sea, a find, a block hint) were taken before the integrator asked for
fewer; none were skipped and no more were taken after the request (the follower swimming and the wake in motion were
not photographed, so those are judged from the code and one idle frame only).

Screenshots in `docs/screens/w54/`: `water-lake.png`, `water-river.png`, `water-sea.png`, `water-find-bottle.png`,
`water-block-hint.png`.

## Files touched outside my own

`world/overworld.gd` (`ground_y`, `can_enter`, `blocked_hint`, `_on_step`, `load_zone`, one `dress` and one `interact`
hook, two dev switches), `world/player.gd` (the coracle and paddle speed), `world/follower.gd` (water parts only),
`world/encounters.gd`, `world/field_moves.gd`, `core/game_state.gd` (two dev lines), `tools/validate.gd` (two lines),
`tools/playtest/bot.gd` (flotsam tiles solid in its zone copies, like field spots), `data/zones/inverness.json` (the one
key). `world/npc.gd` is not touched.

## Unsure / for the integrator

- The gate-NPC definition above is mine. If the integrator has the real list of 21, swap it into `RideCheck.is_gate`.
- Rewilding sites (`Rewild.apply`) and leases change tiles at load time and the validator can't see them; a rewilded pond
  would be ridable. They sit in towns and routes, not behind gates.
- The paddle sound reuses `splash`. A real sample would be a `tools/audio` job for the air session.
- Flotsam text is in the bottles' case ten or so lines of fact-checked joke; worth a second read for the
  "real facts only" rule (Fungie's dates, the Forth Bridge's repaint, Neptune's Staircase's hour and a half).
- `Rng` draw order is unchanged: a water encounter roll uses the same `chance`, `roll`, `roll_int` calls as grass.
