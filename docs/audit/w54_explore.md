# Wave 54, explore: a reason to leave the road

Branch `w54-explore`. Seven things were asked for; all seven are in. Everything is additive, every new flag defaults to
"not yet", and the owner's late-game save catches up without being paid twice.

## What was built

### 1. Discovery is a moment (`core/discovery.gd`, `world/travel.gd`, `ui/zone_card.gd`)
- The first time the player enters any outdoor zone, or a Deep Place, `Travel.note_visit` calls `Discovery.note`. It sets
  `found_<zone>`, and the zone card gains a gold line, "NEW PLACE  ·  14 of 217 found", a line about the party
  ("Kindlet is chuffed to be somewhere new."), and a soft harp run (the existing `harp_gliss`; no new audio).
- The reward goes to the whole party through a growth path that already works outside battle: +2 friendship (the same
  field the 128-step walk bonus feeds) and `Poi.train` (the standing stones' four training points) in one stat, picked
  by hashing the place so a long walk spreads them about. Both are capped by the existing caps, so it cannot run away.
  Paid once, because the flag is the guard.
- 217 findable places: 200 outdoor zones plus 17 Deep Place rooms. Rooms stay the Visitor's Book's business.
- Tally lives in the card, the Atlas header and the Almanac blurb ("20 of 217 places found").

### Old saves
`Discovery.catch_up` runs once (flag `disc_init`), the first time the tally or a zone entry asks, before anything is
paid. It marks as found, with no reward: every town with `visited_<town>`, every Deep Place with a `seen_` or `dp_`
flag, and, for a save past half an hour (the Intros veteran rule), every route that links two found places (you must
have walked it to get between them), repeated to a fixpoint. A new save infers nothing. What is not caught up is a
dead-end route off a visited town (Loch Ness, say): it will give one small "New place" the first time it is entered,
which is true to the player's own account of it. Atlas stamps already earned are paid on the first open.

### 2. The map makes promises (`ui/map_logic.gd`, `ui/map_view.gd`, `ui/world_map.gd`)
- **Names for neighbours.** `MapLogic.promised_towns`: the town at the far end of the roads out of any visited town
  (through routes only, one hop), the other end of a ferry from one, and a town where a legend you have heard of
  stands. Drawn the way the "Where next?" town already was: a small ring and a name with a question mark ("Buxton?").
- **Rings.** Places you were told about get a dashed heather ring: legends (new `legend` mark: a star on a ring, ticked
  when caught), Deep Places once the place with the way in is found (new `deep` mark: a cave mouth, filled when you
  have been in), and treasure-trail ends (the existing `trail` mark, now ringed). Residents' mentions of points of
  interest already drew "?" marks (`Poi.marks`) and still do.
- `MapLogic.mark_point` falls back to `ZoneIndex.pos_of`, so caves and routes with no spot of their own can be marked.

### 3. The legend hunt (`data/legend_hunts.json`, `core/rumours.gd`, `tools/explore/gen_legend_hunts.py`)
29 legends, 30 rumours, each told once by a named resident in a town of that region, appended after what they would
have said (one line in `ScriptHooks.wrap`, as the Poi mention is). Hearing one sets `legend_<id>_<n>`, rings the
legend's place, names its town on the map if you haven't been, and puts the clue in the Fieldbook in place of
"somewhere secret" ("Rumour: ..."; for a legend you have only heard of, the "Not met yet" line carries it). Nothing is
told for a legend you have already caught. The validator (`Rumours.check`, one line in `tools/validate.gd`) checks that
every hunt names a real species and zone, every teller is a real, ungated, non-shop resident, no resident tells two,
and there are no dashes.

| Legend | Place | Told by | Clue the Fieldbook gets |
|---|---|---|---|
| Black Shuck | Whitby | Whitby old fisherman; York night baker | The clifftop by Whitby Abbey, when the sea fog rolls in. (2nd: he is choosy about company) |
| Lambton Worm | Penshaw Hill | Newcastle baker | Penshaw Hill, round the monument. They say it coils there. Sundays, mostly. |
| Tchian | Jersey Countryside | St Helier local | The cliff path above Bouley Bay, after dark or in the fog. |
| Cù-Sìth | Faerie Glen | Portree harbour hand | Faerie Glen on Skye, among the cone hills. It barks three times. |
| Nessie | Loch Ness | Inverness astronomer | Out on the loch by the island, on a still day. |
| Y Ddraig Goch | Dinas Emrys | Llanberis castle guide | Dinas Emrys, near Beddgelert: the pool under the hill. |
| Manannán's Horse | Giant's Causeway | Bushmills post clerk | The Giant's Causeway, where the surf runs along the rocks. |
| Balor | Tory Island | Gweedore fisherman | The east end of Tory Island: Balor's fort, the headland. |
| Hereward | The Fens | Cambridge tour guide | Out in the Fens, by the beacon: Hereward's island. |
| Herne the Hunter | Sherwood | Nottingham jogger | Sherwood Forest, near the Major Oak. Listen for a horn. |
| The Green Man | Glastonbury Tor | Glastonbury crystal seller | The old orchard on Glastonbury Tor, among the apple trees. |
| Bran's Raven | London | London lamplighter | The Tower of London, on the green with the ravens. |
| The Morrígan | Newgrange | Newgrange archaeologist | The inner chamber of Newgrange, among the crows. |
| Nuckelavee | Pentland Coast | Thurso mason | The Pentland shore, after dark. Fresh running water is said to turn it. |
| Knucker | South Downs | Brighton old salt | A still pool on the Downs, after dark. A pie is part of the old story. |
| Silvershod | Lough Gur | Limerick Treaty Stone guide | Lough Gur at night: a pale horse with silver shoes on the water. |
| Eildonmare | Scottish Borders | Edinburgh lamplighter | The Eildon Tree in the Borders: a white horse with silver bells. |
| Taywraith | Dundee | Dundee Law walker | The stumps of the old Tay Bridge, at night. |
| Hairy Hands | Exe Estuary | Exeter gran | A lay-by on the B3212 over Dartmoor, after dark. |
| The Cailleach | Oban | Oban pier porter | The end of Oban pier, when it is bitterly cold. |
| Lincoln Imp | Lincoln | Lincoln spire guide | Minster Yard, Lincoln, on the wall: a small stone imp. |
| Fingalith | Fingal's Cave | Tobermory artist | Fingal's Cave on Staffa, where the columns hum. |
| Twaface | Enniskillen | Enniskillen local | The two-faced stone in Caldragh graveyard, Lough Erne. Leave a coin. |
| Ormwyrm | Gower | Swansea tide man | The Worm's Head end of Gower, when the swell hits the blowhole. |
| Tylwyth | Fairy Bridge, Douglas | Douglas guide | The Fairy Bridge outside Douglas. Say good morning. |
| Cobblet | Big Pit | Blaenavon old man | Ninety metres down in Big Pit: listen for knocking at the coal face. |
| Roachroo | The Roaches | Macclesfield hiker | The Roaches at dawn or dusk, up in the bracken. |
| Diaboulder | Shropshire Hills | Shrewsbury drover | The Devil's Chair on the Stiperstones, when the mist comes down. |
| Dodo | Oxford Museum | Oxford guide | Oxford's Museum of Natural History, behind glass. |

Left out on purpose, because I could not vouch for the folklore: Megalorn, Shivertor (Blue John), the natterjack
quest. The rumours stay within what the game's own text already says or what is well attested (Adomnán and the River
Ness, Dracula landing at Whitby, Vortigern's two dragons, Thomas the Rhymer's bells, Gearóid Iarla's silver shoes,
the Cù-Sìth's three barks). Every line is voiced as a resident's opinion and several are deliberately wry.

### 4. The atlas (`core/atlas.gd`, `ui/atlas_screen.gd/.tscn`, Almanac page "Atlas")
- Per region you have found a place in: places found, rooms visited, plaques read, points of interest, field spots, and
  creatures recorded (seen or caught, appendix species excluded), as counts and a bar each. A region's percentage is the
  average of its bars, so a town full of rooms cannot drown out one plaque and one standing stone.
- A stamp at half (a star in the list) and at all (two): `flask_of_tea` at half, `kendal_mint_cake` at all. Existing
  items, no money. Flags `atlas_<region>_half` / `_full`. Paid on opening the page, which is also how an old save
  catches up; a stamp the bag has no room for waits for the next look.
- Registered in the Router, the Almanac (after the Quest log; it appears once a place is found), the text audit, and a
  `--menu=atlas` dev setup. Passes the text audit at Normal, Large and Largest; the right pane scrolls (Right moves in).

### 5. Your creature notices things (`world/sense_cue.gd`, `Discovery.nearby_unfound`)
Within five tiles of an unfound point of interest or field spot, on a route only, a gold "!" rises over the follower
(or the player if it is hidden) with a soft chime (`cursor` at +1.9 pitch, -7 dB). Once per find (`sensed_<id>`),
never in towns, never with Hints off. It looks every third step, not every frame, and works the poi tiles out once per
zone. One hook line in `Overworld._on_step`. `Discovery.nearby_unfound` is the list phase 2 can add flotsam and
secrets to.

### 6. "Where next?" wanders, and the intro cards
- `WhereNext` gains a `wander` line (second in priority, after the story): a road next door you have never walked
  ("Macclesfield Forest is just down the road, and you have never set foot there."), else "Still to find off the road near
  X: 2 points of interest and a field spot." It is shown wherever `WhereNext` is (the pause card).
- `Intros` gains cards for the Atlas, points of interest, field spots, plaques and the Visitor's Book. The poi and
  field-spot cards come a moment after the cue; the plaque card when you are within three tiles of one; the Visitor's
  Book after the third room. Hints off says nothing; a save past half an hour is treated as a veteran and told nothing.

## How to see it
- Discovery card: `tools/shot.sh docs/screens/w54/explore_discovery_card.png 20 --boot=macc_forest --clock=12:00`
- Atlas: `--menu=atlas`. Map: `--menu=map:rumours`. Fieldbook clue: `--menu=pedia:shuck` (also `nessie`, `lambton`).
- Sense cue: `--boot=macc_forest@28,16 --shot-from-zone --sense` (a dev switch added to `GameState._dev_cues`).

## Screenshots
All five on the brief's list were taken before the integrator's request to stop (discovery card, atlas, map with
rumoured places, legend clue in the Fieldbook, sense cue), in `docs/screens/w54/explore_*.png`. None skipped, and
none taken since. Not taken: the plaque/Visitor's Book/poi intro cards (plain one-line dialogue boxes).

## Numbers
- 217 places (200 outdoor zones + 17 Deep Place rooms), 47 regions, 29 hunts, 30 rumours, 6 atlas measures, 2 stamps
  per region (flask of tea, Kendal mint cake).
- Per step, the sense cue is a counter increment; every third step a handful of squares compared. No per-frame work.

## Tests
New: `tests/core/test_discovery.gd` (11), `tests/core/test_legend_hunts.gd` (8), `tests/core/test_atlas.gd` (8),
`tests/core/test_wander.gd` (8), `tests/ui/test_map_promises.gd` (6). See the end of this file for the run lines.

## Things I was unsure of
- Tchian: I used "the Black Dog of Bouley Bay" and the game's own "dog" gloss rather than the Jérriais spelling of the
  local name, which I could not be certain of.
- Roachroo: the wallaby escape from Swythamley is real; I did not give a date or say how long they lasted.
- Knucker: told as "a poisoned pie, or pudding, depending who's telling it" because the surviving versions differ.
- The "NEW PLACE" reward is deliberately tiny. If it feels invisible in play, raise `Discovery.FRIENDSHIP`.
- Veteran catch-up infers routes between two found places only. Dead-end routes off visited towns will pay once.
- The Deep Place mark appears when the place with the way in is found, not when someone mentions it: no resident
  mentions them today and I did not edit dialogue I do not own.

## Notes for the integrator
- Shared files touched, each by a line or two: `world/overworld.gd` (one hook line in `_on_step`),
  `story/script_hooks.gd` (one line: `Rumours.hook`), `tools/validate.gd` (one line: `Rumours.check`),
  `core/scene_router.gd` (one menu entry), `core/almanac.gd` (the page), `core/intros.gd` (five cards),
  `core/game_state.gd` (the `--sense` dev switch), `core/zone_index.gd` (two additive keys per zone: `deep`, `links`),
  `ui/pedia_screen.gd` (`found_in` takes a clue; the "Not met yet" line carries it), `ui/dev_menu.gd` and
  `tools/dev/text_audit_body.gd` (dev setups and the screen list).
- `WhereNext` kind `wander` has no colour in `ui/pause_menu.gd` (it falls back to cream); the types session owns that
  file, so I left it.
- The Atlas takes the half/full stamp text from `FieldbookGoals.region_name`; new regions appear automatically.

## Test run lines
- `test_discovery`: 11 passed, 0 failed; `validate: 0 error(s)`
- `test_legend_hunts`: 8 passed, 0 failed; `validate: 0 error(s)`
- `test_atlas`: 8 passed, 0 failed; `validate: 0 error(s)`
- `test_wander`: 8 passed, 0 failed; `validate: 0 error(s)`
- `test_map` (cursor, promises and the rest): 29 passed, 0 failed; `validate: 0 error(s)`
- `test_zone` (zone card, data, index): 72 passed, 0 failed; `test_intros` 6, `test_almanac` 11, `test_fieldbook_teaching` 7: all passed
- `test_text_fit`: 5 passed, 1 failed. The failure is `races:dev` on Large text with the Readable font (4 cut-off labels in
  the race screen, not mine). The Atlas passes the text audit at Normal, Large and Largest (`text_audit: 0 problem(s)`).
- Not run: `tools/playtest.sh slice 2` and the full suite (the machine was saturated); the integrator's run covers them.
