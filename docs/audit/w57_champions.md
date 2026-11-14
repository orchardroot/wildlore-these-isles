# Wave 57: champions (the Walkers' League)

Branch `w57-champions`. Each of the thirty roads from waves 55 and 56 has a champion, its strongest trainer. Beat them as before; after that they can be challenged once a week.

## How a rematch works
- The champion NPC gets `"champion": "<trainer id>"`. Once the trainer's flag is set, talking to them runs the zone's dialogue script `champ_<id>` (a greeting, then the `rchamp` story command, `story/champion_run.gd`) instead of the one-line `after`.
- Open once beaten and when no rematch was won this calendar week (Monday to Sunday, `WeeklyChallenge.week_number`, stored in `rc_week_<id>`). Declining costs nothing. A loss is the usual whiteout and does not use the week; a win does.
- The team is four creatures: two stayers, one for the season (`Calendar.season_today`) and one for the weather of the day (wet: drizzle, downpour; rough: gale, fog, frost, snow; fair: the rest). The team is said aloud before you choose.
- Levels are authored at the road's floor and lifted by `ParLevel` (the existing `scaled_floor` route), so every creature is at the player's par, the last a step above, evolved to suit.
- Prize: `par x 3` sterling (about 290 at the end), paid by the battle scene on a win only. A Keeper rematch pays 16,500 a day.
- The first win is dated (`rc_first_<id>`, hook in `Commands._battle`). Old saves: a beaten trainer simply counts, with no date ("before the League kept dates"), and a title already earned is announced the next time a champion is met.

## Titles and keepsakes
10: Waymarker (Walking Stick Badge). 20: Long Distance Walker (Tin of Kendal Mint Cake). 30: Freeman of the Footpaths (Well-Worn Boot). Keepsakes join `HomeExtras.SOUVENIRS` (ids `wl_10`, `wl_20`, `wl_30`) and are unlocked by count.

## The page
Almanac, "Walkers' League" (`ui/league_tab.gd`, `Almanac` page id `walkers`, sprouts at the first champion). `walkers` is in `tools/dev/text_audit_body.gd` SCREENS; `text_audit walkers` reports 0 problems and `tools/test.sh text_fit` passes (9/0). Preview: `--menu=walkers`.

## The thirty
| Route | Trainer id | Champion | Line |
|---|---|---|---|
| Aberglaslyn Pass | `ag_osprey` | Osprey Watcher Bethan | Watcher of the Glaslyn nest |
| Healy Pass | `hp_cornish` | Heritage Volunteer Jago | Cornish blood, Beara road |
| Trotternish | `trt_guide` | Guide Calum | Under the Old Man of Storr |
| Pen-y-Gwryd | `pyg_climber` | Climber Gareth | Trains where Everest trained |
| Llyn Tegid | `tg_angler` | Angler Elis | After the gwyniad |
| Glamorgan Heritage Coast | `gc_keeper` | Lighthouse Keeper Aled | Still checks the light |
| Golden Vale and Cashel | `gv_hurler` | Hurler Seán | Walks to Thurles on match days |
| Bunratty and Ennis | `cr_musician` | Musician Aoife | Plays between the sessions |
| Hook Head and the Waterford Coast | `hh_lighthouse` | Lighthouse Keeper Éamon | Talks about the light as if he lit it |
| The Lower Bann | `lb_eelfisher` | Eel Fisher Brendan | The eel's life story |
| The Erne Shore Road | `es_boatman` | Boatman Colm | More islands than he can count |
| Pendle Hill | `pn_fellrunner` | Fell Runner Gwen | Up Pendle before breakfast |
| Swaledale | `sw_historian` | Castle Warden Hugh | Guards a ruin, gladly |
| Humber Bridge | `hb_legionary` | Centurion Dai | Marches Ermine Street in full kit |
| Hadrian's Wall Path | `hp_warden` | Wall Warden Fiona | Has seen everyone try to climb it |
| The Debatable Land | `rr_rider` | Rider Joanne | Rides the marches |
| The Black Country | `bc_foundry` | Foundryman Ken | Missed the noise |
| Cranborne Chase | `cc_hillfort` | Digger Rhiannon | Finds something every week |
| The Varsity Line | `vl_scholar` | Don Priscilla | Walks where the trains used to run |
| Romney Marsh | `rm_martello` | Coastguard Carol | Watches the Martello towers |
| Offa's Dyke | `od_walker_t` | Walker Haf | End to end, more than once |
| The Southern Upland Way | `swy_stalker` | Deerstalker Anne | Coast to coast, on foot |
| The West Highland Way | `whw_guide` | Guide Eilidh | Ninety-six miles, mostly in the rain |
| The Devil's Staircase | `dev_aluminium` | Foreman Dougie | Missed the smelter |
| The Pass of Brander | `brn_forester` | Forester Ian | Knows the hollow mountain |
| The Rob Roy Way | `rrw_historian` | Historian Margaret | Rob Roy's biographer, in a way |
| The Angus Coast | `ang_birder_t` | Warden Isobel | Counts the cliff birds |
| The Uig Road | `uig_beachcomber` | Beachcomber Iain | Still looking for the rest of the chessmen |
| The Scalloway Road | `sca_knitter` | Knitter Ina | Knits while she walks |
| The Machars | `mac_farmer_t` | Farmer Jock | Farms by the book town |

Strongest = the top purse on the road (ties broken by which story I could tell truthfully); a test pins it.

## Kit
Three optional meetings (an NPC with a script, never a sight-challenge; a battle once, with a win that pays once):
- Pen-y-Gwryd after `ch3_ddraig_woke`, until `badge_storm` (filming "Training Like Hillary").
- Hook Head after `badge_kin`, until `badge_tide`.
- West Highland Way after `strachan1_done`, until `badge_frost`.
Trainers `kit_road_pyg`, `kit_road_hook`, `kit_road_whw` at the road's par.

## Economy sim (`tools/dev/economy_sim.gd -- 20`)
`EconomySim.dailies` gained a `champions` line (every road open at that par, rematched every week, as a per-real-day figure; a very generous ceiling).
Before: b0 1257, b2 3099, b4 5017, b6 6910, b8 9127, b10 11724 a day; dailies earned over a year: no champions (jobs 932,857, shows 6,300 ...).
After: champions 0, 28, 137, 201, 390, 1056 a day, totals 1257, 3128, 5154, 7111, 9517, 12780; a year of `dailies` earns 104,733 from champions (jobs 932,857 unchanged). Cash columns move run to run because the sim is seeded per strategy but charm and lease timing shift with income; d360 for `dailies` was 84,388 and is 81,867. (The first pass at 6 a level gave 209,465 a year; halved.)

## Tests (my own fragments only)
`w57_champions` 23/0, `text_fit` 9/0, `w55_` 34/0, `test_almanac` 11/0, `test_home_extras` 9/0, `test_economy` 8/0, `test_p7_postgame` 23/0, `test_town_projects` 23/0, `test_zone_data` 34/0, `test_coverage` 5/0, `test_all_scripts_parse` 1/0, `test_world_consistency` 7/0, `test_tournament` 39/0; `validate: 0 error(s)` throughout. No full suite, no playtest, no screenshots.

## Shared files touched
`core/almanac.gd`, `core/home_extras.gd`, `core/economy_sim.gd`, `story/commands.gd` (two small hooks), `world/npc.gd`, `data_api/story_validator.gd` (command whitelist), `tools/validate.gd`, `ui/almanac_screen.gd`, `ui/dev_menu.gd`, `tools/dev/text_audit_body.gd`, `tests/world/test_home_extras.gd` (allows a League keepsake), thirty-three zone and dialogue files (an NPC key; a script; three Kit NPCs).

## Unsure of
- Facts in champion lines I kept to well known ones (Thurles 1884, Everest 1953 at Pen-y-Gwryd, 96 and 177 miles, Cruachan, Kinlochleven smelter, Lewis Chessmen 1831, gwyniad only in Llyn Tegid, Kendal Mint Cake in 1953). Worth one more eye.
- The week is a calendar week, so Sunday then Monday gives two rematches a day apart.
- Kit's spots were chosen from the ASCII, not a render.
