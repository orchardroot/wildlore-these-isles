# w55 stories: side quests people remember

Branch `w55-stories` (from `int-w55`). Six quest chains about real pressures on real kinds of places, each with one
decision that has no clean answer, made after hearing more than one side, and a consequence that arrives later.

## What was built

**Six chains** (`data/quests/w55_<chain>.json`, one quest each, 4 to 5 steps). Every one: a person asks you to hear the
others out (you are "nobody's cousin"), two or three more people argue their side, you choose from three real answers
(or "I need to think", which decides nothing), the same night nothing has changed, and a letter comes later. Each
branch has its own ending line in the Journal, its own keepsake, and changes who stands where in the rooms.

| Chain | Where | The people | The decision | Branches |
|---|---|---|---|---|
| England, "Who Takes the Moor Farm" | Moor Farm, Rosedale Farm, the Moorcock Inn (North York Moors) | Farmer Dale (67, tenant), his daughter Hannah, neighbour Joe Hartley, a moor ranger | who takes a hill farm's tenancy at lambing | Hannah (the flock stays, thin money); Joe (flock stays hefted, Dale moves to the village, a shepherd in the house); a habitat scheme (forty ewes not 130, more curlews, payments cover the rent and little else) |
| Scotland, "The Hall Roof and the Flows" | the Flagstone Bar (Thurso), Forsinard Flows Visitor Centre | Isobel Mackay (hall books), Calum Ross (estate manager), the Flows Warden, young mum Kirsty | a wind farm on the Flats: back it, object, or back it with the turbines moved off the deep peat | support (roof slated, lunch club doubled, greenshank move back); object (refused, tarpaulin stays, Kirsty leaves for Inverness, "it was the school run"); compromise (eight built, six moved, smaller fund, roof but no minibus) |
| Wales, "The Keys to Bethania" | Bethania Chapel, the Miners' Institute, Bryn Terrace (the Rhondda) | Eirlys Bevan (secretary, nine members), Kieran Rees (local builder), Elwyn Prosser (the choir) | sell the chapel for flats, keep it and raise the money, or sell only the old schoolroom | six flats and the choir in the Institute; nine members, a thermometer at forty per cent and a ladder; two flats at the back and the choir stops at nine |
| Ireland, "Sell the Pub" | the pub at Gweedore | Pádraig Ó Gallchóir (71), Niamh (young couple), Bríd (community co-op), Orla (hotelier) | who buys the licence | the couple (kitchen, snug gone); the co-op (340 shares, a rota, a lower price); the hotelier (open every day, six rooms, not Pádraig's) |
| Northern Ireland, "The Counter" | the post office and the craft shop, Bushmills | Maeve Hanna (postmaster, 38 years), Margaret Cuthbert (volunteers), Gareth Boyd (a convenience group), Joanne Hill (craft shop) | who takes on the counter when she retires | volunteers (three mornings, a biscuit tin); the group (seven days, three local jobs, no one knows the dog's name); a hatch in the craft shop (Tuesday to Saturday) |
| Islands, "The Isle Boat" | the wool shop, Harbour Tea Room and Town Hall in Lerwick | Eila Jamieson (an islander), Magnie Tulloch (skipper), Ruth Leask (council transport officer) | what the isle should ask the council for | the full boat (money found by delaying a mainland road); a lean three-day timetable (children board in Lerwick); a smaller new boat (no sheep, a charter twice a year) |

All the people are invented. No real organisation or living person is named: the developer, the estate, the council,
the convenience group, the hotel and the "scheme" are generic. Places are real; nothing is claimed about any real
building, pub, chapel, shop or boat (the isle is not named, the chapel is "Bethania" as the game already has it, and the
pub is "the pub" in a parish with several). Facts used are the ones the game already states or that are widely known
(hefting, curlews and greenshank on the moors, peat as a carbon store, the 1980s forestry on the Flow Country, chapel
choirs and conversions, rural pub and counter closures, lifeline ferries).

**How the player finds out, and when.** The choice is made in one conversation. In that conversation the person only says
what it will mean for them. The world changes later, in two stages:
1. at once, the person at the door says a different line (every script branches on the flag), and the post waiting
   (a Postwoman, Postie, Postman or Boat hand, who only appears once you have decided);
2. when `later_<stamp>_3` ripens (three in-game days, one night's sleep, or the next real day, whichever is first) the
   post is read: a letter in the voice of the person, the keepsake, an outfit piece and a recipe, and the rooms change
   (people gone, people arrived, a new person behind the bar or the counter).

**Rewards are things.** Per branch a keepsake (key item, 18 in all, `data/items/w55_stories.json`). For everyone who
finishes, an existing outfit piece from `wear.json` handed over by the letter (a Yorkshire flat cap, green wellies, a Welsh
wool shawl, a Donegal tweed cap, a Belfast linen shirt, a Shetland lace shawl) and an existing recipe (parkin, clootie
dumpling, Welsh cakes, boxty, soda farl, stovies). No money, no standing. (I first wrote six new wear items. The
boutique tests require every wear item to be `wear.json`'s and sold in a boutique, so I used the existing ones rather
than touch the boutiques.)

## What I added to the quest code

- `core/quests.gd`: `Quests.outcome(d, q)` and an optional `"endings": [{flag, text}]` on a quest, shown as the last line of
  the Quest Log once it is done (`log_steps`); `Quests.stamp(d)`, `Quests.later(d, key, n)`, `Quests.later_cond(d, cond)`:
  a flag holding a stamp (`DailyKey.stamp`) ripens after `n` in-game days or when the real date changes; `Quests.validate`
  checks each ending has a flag and a text and that the flag is set somewhere. Quests without `endings` behave exactly as before.
- `story/commands.gd`: two small hooks. `{"do":"set","flag":k,"value":"@now"}` stores the stamp; the condition
  `later_<flag>_<n>` (for `when`) asks `Quests.later_cond`.
- `data_api/story_validator.gd`: one `elif` so `when` accepts `later_<flag>_<n>`.
- Branching itself needs nothing new: a `choice` with `set`, then `if ... eq`, then boolean flags per branch.

Nothing in the save format changed. Every flag is absent until a chain is started, and absent means the old behaviour.

## Touching other people's content

- Old NPCs with a flag gate added (`hide_if` on the world flag set when the letter is read): `moorfarm_farmer`
  (Dale, hidden when Joe has the farm), `gp_barman` (Pádraig, retired), `bush_postmaster` (Maeve, retired).
- Lines added to old scripts: put in front (the new part runs once and ends the talk; after that, and while the chain is
  not yet at that person, the old talk plays as before): `moorfarm_farmer`, `rhn_conductor` (Elwyn), `flows_warden`; put after the old welcome: `gp_barman`, `bush_postmaster`. Each block carries
  a `_w55` tag; `tools/zones/w55_stories_lib.py` replaces its own block when re-run and leaves the rest alone.
- The zones changed are interiors only: `nym_moorfarm`, `nym_rosedale`, `nym_moorcock`, `thurso_pub`,
  `forsinard_centre`, `rhondda_chapel`, `rhondda_institute`, `rhondda_home`, `gweedore_pub`, `bushmills_postoffice`,
  `bushmills_craftshop`, `lerwick_wool`, `lerwick_tearoom`, `lerwick_townhall`. NPCs that are always there stand on
  free tiles away from the door line; the rest have `show_if` or `hide_if`, so no tile is solid that was not.
  The playtest bot's `_routing_zones` is not affected (no outdoor zone, no solid tile on a route).

## Reaching them in play

Every chain starts by talking to the person named in the table (Hannah in Moor Farm's kitchen, Isobel in the Flagstone
Bar, Eirlys in Bethania, Pádraig behind the bar at Gweedore, Maeve behind the counter at Bushmills, Eila in the Lerwick
wool shop). They are open from the first hours of the game: none is behind a story gate, because they are in rooms
that anyone can walk into, so a player who is late in the game finds all six. Sequence-break check: no new warp, edge
or gate.

## Numbers

- Money: none paid or taken, so the economy simulation is unchanged (not re-run). The six outfit pieces already exist
  in the boutiques; getting one free from a letter is a one-off.
- 6 quests (4 to 5 steps each), 18 branches, 41 new scripts and 41 new NPCs (about 7 per chain), 3 existing NPCs gated,
  3 old scripts with lines in front, 2 with lines after, 18 new items (all keepsakes).

## Tests

`tests/story/test_w55_stories.gd`: the mechanism (`later` after days or a new real date, the `@now` stamp and the
condition, the Journal ending line, validate), then for each chain every branch finished (one of the three also tries
"I need to think" first and checks it decides nothing), not decided before everyone has been heard, not done in the same
conversation, the post says nothing the same night and delivers after three nights, only that branch's keepsake, the
shared gifts and recipe, no second letter, the choice and the finish survive a save and a load, and who stands where in
each world (`Npc.should_spawn` on the real zone data). A fresh save: hearing the neighbours starts nothing, and every
new person is where they were.

**Results.** `tests/story/test_w55_stories.gd` (fragment `w55_stories`): see the last line below. Earlier on this branch,
before the reward items were swapped to existing wear items and Dale/Elwyn/the Warden were made to fall through, the same
file gave `14 passed, 0 failed` and the validator gave `validate: 0 error(s)` after two data fixes it found (an NPC on an
unwalkable tile in `rhondda_home`, the phrase "the back room" in a one-door room). The full `tools/test.sh` found one
failure of mine, `tests/looks/test_boutiques.gd` (wear items must be `wear.json`'s), fixed by using existing wear items.

**Skipped, by the integrator's instruction:** the full `tools/test.sh`, the validator after the final edits, and
`tools/playtest.sh slice 2`. Please run them once after merging. Things worth watching: `test_boutiques`,
`test_world_consistency` / the `world:` validator rules (they read every NPC line), `test_quests`.
Final fragment runs: `w55_stories` 14 passed, 0 failed; `test_boutiques` 11 passed, 0 failed. The economy simulation was not run: no money moves.

## What I was unsure of

- Real-world detail. I kept the facts general (see above) and invented every number inside the stories (14 turbines,
  nine members, 340 shares, forty ewes). The Rhondda chapel, the Gweedore pub, Bushmills counter and the Lerwick isle boat
  are real kinds of place standing in real rooms the game already had, and say nothing about the real buildings or boats.
  Please check these before release if you want any of them to be a real, named place.
- The Northern Ireland chain avoids any politics on purpose and is about a counter and a shop. A Gaelic-medium school,
  which the brief mentions, is not used: I judged it the most delicate to tell even-handedly in a few lines. The
  Scottish chain is a wind farm.
- "Later" is in-game days or a real day, so a player who sleeps three times gets the letter in minutes, and one who quits
  and returns tomorrow always does. Months later is in the voice of the letters ("the end of April"), not the clock.
- NPC gating (`hide_if`, `show_if`) only takes effect when a zone loads, so the people in a room change the next time the
  player walks in, not while they stand there. The post is read where the Postwoman, Postie and the rest stand, and she
  vanishes on the next visit.
- Irish in the Gweedore chain is a few words ("a chara", "Slán go fóill", names with fadas), all well known.

## Notes for the integrator

- Shared files touched: `core/quests.gd`, `story/commands.gd`, `data_api/story_validator.gd`, plus the zones and dialogue
  files listed above (each only the keys named). New files: `data/quests/w55_*.json`, `data/items/w55_stories.json`,
  `tests/story/test_w55_stories.gd`, `tools/zones/w55_stories_*.py` (a library and one script per chain).
- Wave 54 touches no file I touched. If a later session adds NPCs to these interiors, check the free tiles named in the
  generators.
