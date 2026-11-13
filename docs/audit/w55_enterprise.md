# Wave 55 enterprise: money that changes the place

Branch `w55-enterprise` (from `int-w55`). Deed upgrades, the monthly matter, managers with a character, and fifteen town projects. No screenshots were taken. The Trade Ledger, markets and `core/trade*.gd` were left alone.

## What was built

### Running a Deed (new `core/deed_choices.gd`, hooks in `core/deeds.gd`)
- **Upgrades** (`data/deeds/<id>.json`, key `upgrades`): three a Deed, on top of the tiers, each with a catch. Fields: `cost` (grows with the badge band and inflation, like the Deed's own price), `tier` (the tier it needs), `group` (one of a pair, never both), and effects `takings`, `use` (stock eaten), `rates` (points added to or taken off the council's share), `shield` (how much of a bad day's loss is avoided; negative makes it worse), `boom` (extra from a good day), `carry` (days the till keeps filling while you are away), `upkeep` (a wage, per day). Examples: a second fryer (more takings, eats a third more fish and potatoes); a ten-year lease on the quay against a late-night licence (steadier and cheaper rates, or more takings with a wage to pay and rougher bad days); extra rooms against evening meals at the B&B; bigger nets and a second hand against an ice hold on the boats.
- **The monthly matter** (`data/deed_asks.json` shared, plus one of its own in each Deed file under `asks`): about once a month (30 days, seeded, plus or minus 6) something wants an answer. 21 matters in all: the health inspector, the supplier putting prices up, a coach party, a bad review, a rise for the staff, the local paper, a do in town, a neighbour's complaint, a hard week's weather, storm damage (winter), and each Deed's own (the Whitby Goth Weekend, the Blackpool Illuminations, the Skye Highland Games weekend, walkers off the fell, the Bath Christmas market pitch, and so on). Three or four answers each (tagged safe, bold, frugal, ignore), priced in quiet days of takings so they scale with the Deed, with a spell of better or worse days, and a change to the Deed's name in the town (reputation, -5 to 5, one point is 1% of takings). Some answers carry a risk, rolled from the save's seed, so a reload cannot re-roll it. A letter in the post box says one has come; the Deed screen has an "A matter needs an answer" button. You have 10 days. Left alone, it goes the worst way; with a manager it is answered by their style on the third day (so you can still step in).
- **Managers who matter** (`data/deed_managers.json`): each Regular is dealt one of five temperaments from the letters of their id (careful, a bit of a showman, thrifty, a charmer, steady as a rock; an `assign` map can name anyone). They change takings (1.10 to 1.21, averaging the old flat 1.15), how bad days bite (`shield`), how good days stretch, how much stock is used, how long the till fills when you are away, what they answer to the monthly matter and what their answers cost, and whether the name of the place grows by itself. A Regular who is from or visits the Deed's town adds 0.03, one who likes what the Deed stocks adds 0.02 and wastes a tenth less, favour 5 adds 0.02. The offer scene tells you what they would be like before you choose; the Deed's books show "Their way"; "Let the manager go" is on the counter (`Deeds.release_manager`, `Regulars.release`). Someone who is not a Regular (the old tests use `reg_pat`) is just a manager at 1.15.
- Old saves: every new key (`ups`, `ask`, `next_ask`, `mods`, `rep`, `asked`, `last_ask`) is absent until used, and an old Deed's first matter is 8 to 30 days after the update, never on the day.

### Town projects (new `core/town_projects.gd`, `data/town_projects.json`, `ui/project_screen.gd`, `story/project_talk.gd`)
A resident of the town speaks for the project (a line added to their talk by one hook in `ScriptHooks.wrap`, three voices: asking, building, done), and offers the plans. The plans are a screen with three stages (25, 35, 40 per cent), each paid in full; the work then takes 4, 6 and 8 days before the next can be paid, or you can pay everything left in one go (the work still takes its time). Costs scale with `ParLevel` (factor 0.45 at the start, 1.0 at par 60, 1.37 at the credits), fixed at the day each stage is paid, in the town's own money. When the last stage is built (`TownProjects.tick`, riding the daily `Deeds.tick`): the flag `project_<id>` is set, standing in that nation rises, a keepsake is added to the bag, the wireless says so, the resident thanks you by name, and the plaque (name taken on the day) is on the screen.

| Town | Project | Min Stones | Cost at par 60 | What it changes for good |
|---|---|---|---|---|
| Whitby | A new house for the lifeboat | 3 | 37,000 | Whitby boats: bad days bite 15% less. England +8 standing. Parkin. |
| Keswick | A proper landing stage for the Launch | 3 | 16,000 | Keswick B&B takings +4%. England +6. Kendal mint cake. |
| Bath | Bring the bandstand back | 3 | 9,500 | Bath stall takings +4%. England +5. |
| Lancaster | The old mill: workshops, cafe, allotment barn | 4 | 30,000 | **Hidden footbridge opens** over the water at the east end of the town (two warps, `project_lancaster_mill`). Lancaster allotment takings +5%. England +8. Lancashire hotpot. |
| York | A flood gate for the river path | 3 | 21,000 | York allotment: bad days bite 20% less. England +6. Parkin. |
| Carlisle | The library, open on Saturdays again | 3 | 5,500 | England +4 and the Reader's thanks. Nothing else; it is the cheap one. |
| Penzance | Mend the sea-water lido | 3 | 26,000 | England +7. A pasty. |
| Portree | A pontoon for the visiting boats | 6 | 20,000 | Portree B&B takings +4%. Scotland +6. Tablet. |
| Kirkwall | A winter ferry to the island across the bay | 8 | 23,500 | Scotland +8. Tablet. |
| Inverness | A footbridge over the Ness | 8 | 28,000 | **Hidden footbridge opens** by the Ness Islands sign (two warps, `project_inverness_footbridge`). Scotland +8. Tablet. |
| Blaenavon | The workmen's hall, open again | 5 | 22,500 | Wales +7. Bara brith. |
| Aberystwyth | A winter overhaul for the Cliff Railway | 4 | 25,000 | Wales +7. Welsh cakes. |
| Dingle | An ice plant and a slipway for the pier | 6 | 21,000 | Dingle boat: bad days bite 10% less, takings +4%. Ireland +7. Barmbrack. Paid in euros. |
| Galway | A boat shed for the hookers | 6 | 17,500 | Ireland +7. Barmbrack. Paid in euros. |
| Enniskillen | A boathouse on the Erne | 7 | 16,000 | Northern Ireland +7. Ulster fry. |

Total 318,500 at par 60 (216,400 at par 28, 436,400 at the credits). Each is a real kind of project for a real place; none is needed for the story. All fifteen towns have a noticeboard and the resident exists in the zone.

### How to reach it in play
- Deeds: the counter in any Deed you own, "Fit out the place" and "A matter needs an answer" (and a letter at the post box). Appoint a manager through the Regular as before; the offer now says what they are like. "Let the manager go" is on the counter.
- Projects: with the Stones in the table, talk to the named resident (`wby_skipper`, `kes_boatman`, `bridge_busker`, `lan_boater`, `yrk_guide`, `carl_reader`, `lido_swimmer`, `por_harbourhand`, `kwl_sailor`, `castle_walker`, `bla_old`, `cliff_op`, `boat_skipper`, `hooker_skipper`, `en_canoeist`), say yes to "Have a look at the plans". Dev: `--menu=project:<id>`.

## Simulations, before and after
`tools/dev/economy_sim.gd -- 20` (20 seeded careers), the lines that moved. Before is the tip of `int-w55`; after has upgrades and the monthly matters in the Deeds' net, upgrades bought when they pay back inside 60 days, and the town projects bought cheapest first once the purse holds 1.5 times the cost (`EconomySim.PROJECT_CASH`).

| Strategy | First lease day | Five leases | All ten | Cash d78 | Cash d360 |
|---|---|---|---|---|---|
| dailies, before | 81 | 171 | 312 | 153,335 | 164,868 |
| dailies, after | 162 | 270 | 8 of 10 by d360 | 30,435 | 30,324 |
| deed_rush, before | 81 | 93 | 141 | 335,858 | 2,381,658 |
| deed_rush, after | 84 | 120 | 162 | 25,996 | 2,293,984 |
| trader, before | 81 | 144 | 261 | n/a | 412,382 |
| trader, after | 132 | 222 | 339 | 40,461 | 95,313 |
| cook, before | 81 | 156 | 285 | n/a | 284,668 |
| cook, after | 147 | 243 | 9 of 10 by d360 | 39,073 | 58,225 |
| everything, before | 81 | 87 | 132 | 399,780 | 2,634,963 |
| everything, after | 81 | 108 | 149 | 129,649 | 2,640,074 |

- Deeds earned over the year: deed_rush 2,375,297 before, 2,622,730 after (+10%); everything 2,387,621 before, 2,705,508 after (+13%). Upgrades cost 36,800 (deed_rush) and 32,600 (everything) of that.
- Town projects take 323,200 from deed_rush (all fifteen by day 78), 301,700 from everything (day 71), and 355,000 to 385,000 from the careers without Deeds (all fifteen between day 114 and 145). The money leaves the careers at the credits, which is exactly when the leases start, so the careers that depend on jobs and dailies alone see the leases come 50 to 80 days later; the Deed careers see them come 3 days later (first) and 20 days later (all ten).
- The Deed payback table (`tools/dev/deeds_sim.gd`) is unchanged for the tiers (the monthly matters add about nothing when answered well: -0.10 to +0.25 quiet days a month; ignored they cost 0.85 to 1.3). Upgrades pay back in 15 to 60 days at the top tier at either price where the sim can see their value, and never under 14 (a test). Several are insurance (water butts, standing orders, a lease, a vet on retainer) whose value is in the bad days, which the sim does not model; the sim therefore never buys them, a player may.
- One existing guard changed: `test_economy::test_deeds_are_the_engine_but_not_a_runaway_before_the_story_ends` compared cash at day 78; the projects are now a sink in both careers, so it compares cash plus what has gone into the towns (`held` in the sim result). The 3.5 limit is unchanged.

## Tests
- New: `tests/core/test_deed_choices.gd` (upgrades, groups, tiers, the matters, risk, lapse, managers, old saves, sim guards) and `tests/core/test_town_projects.gd` (data, stages, costs by par, euros, the three voices, plaques, standing, Deed effects, hidden warps, a save round trip).
- Validator: `DeedChoices.problems` and `TownProjects.problems` are in `tools/validate.gd`.
- RESULTS_PLACEHOLDER

## Notes for the integrator
- Shared files touched, small and additive: `story/script_hooks.gd` (one line), `story/commands.gd` (the `project` command, two lines), `core/scene_router.gd` (one menu line), `tools/validate.gd` (two lines), `tools/dev/text_audit_body.gd` (one screen), `story/regular_talk.gd` (the offer scene says what they are like), `core/regulars.gd` (`release`), `core/economy_sim.gd` and `tests/core/test_economy.gd` (above), and the two zone files `data/zones/inverness.json` and `data/zones/lancaster.json` (two hidden warps each, `reveal: project_...`; no tile changed).
- The `project_<id>` flags are for anyone to read. The brief suggested "a market gains a stall"; `core/markets.gd` is the trade session's, so no market reads these flags yet. `project_bath_bandstand` or `project_keswick_launch` are the obvious ones if trade wants a stall.
- Deed data keys added: `upgrades`, `asks`. Nothing was removed. `data/deeds_post.json` has one new letter (`ask`) and a `{title}` placeholder.
- No playtest bot run: nothing here touches the main road or the first hours, and no tile is made solid. The two hidden warps are in the zones' open ground at the river's edge; the validator's reachability checks pass with them.

## What I was unsure of
- The temperament a Regular gets is arbitrary (a stable hash of their id). It is shown to the player as their character, so it may not fit someone whose scenes already read a certain way. `assign` in `data/deed_managers.json` is there to fix any that jar.
- Real facts I leaned on, all general: Whitby has an RNLI lifeboat; Keswick has boats on Derwentwater (the Launch); Bath has a bandstand and a Christmas market; York floods from the Ouse and the Foss; Penzance has an art deco sea-water lido; the Ness Islands have footbridges; Aberystwyth has a Cliff Railway on Constitution Hill; the Galway hooker is a black-hulled brown-sailed workboat; the Skye Highland Games are at Portree in the summer; the Whitby Goth Weekend and the Blackpool Illuminations. I did not state dates, owners or histories beyond that. The Kirkwall ferry is described as "the island across the bay" and the Blaenavon hall as "the workmen's hall"; I did not name a specific island or building.
- Most towns here are compact loops, so a shortcut only made sense in two (Inverness, Lancaster). The other thirteen change the place through the Deeds, the standing, the people and the plaque rather than a path.
- The pure-saver careers wait 50 to 80 days longer for their first lease, because the cheapest projects are bought first. The lever is `cost` per project in the data (or `PROJECT_CASH`, or gating the dearer ones behind more Stones); the Deed careers hardly notice.
