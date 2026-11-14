# Wave 55: Roads and Reasons (target 5.5.0)

The owner's direction (2026-11-13): expand the game. More routes between places. Think about what gives Pokemon,
but also games like The Witcher, their reasons to play. Expand the economy and make that side more engaging.

Wave 54 (docs/briefs/wave54.md on `int-w54`: the family cat, the coracle on rivers, lakes and near-shore sea, type
clarity, discovery moments and an atlas, a livelier world, sound and sky) is being built at the same time on other
branches and will be merged BEFORE this wave. Don't redo it, and keep off its files where you can:
`world/overworld.gd`, `world/player.gd`, `world/follower.gd`, `world/npc.gd`, `battle_ui/*`, `ui/map_*.gd`,
`core/discovery.gd`, `core/ambience.gd`, `world/sky_and_light.gd`.

Base branch `int-w55` (from main at 5.3.1). These sessions run in the cloud. Each works on its own branch
`w55-<name>` cut from `int-w55`, commits small and often, and pushes
(`git -c http.postBuffer=524288000 push -u origin w55-<name>`) after every working step.

## What the two kinds of game give people (the thinking behind the sessions)
- **Pokemon**: a team that is yours, collecting, the pull of the next route and what lives on it, trainers to test
  yourself on, a rival who keeps turning up. Wildlore has most of this, but its world is a line: of 202 outdoor
  zones, 69 have one way in and 84 have two. There is rarely a choice of road.
- **The Witcher**: work with a story in it. A notice board, a contract, an investigation, a monster you prepare
  for, and a decision at the end that somebody has to live with. Side quests that are remembered. A world that
  changes because of what you chose, and money that matters because there are things worth spending it on.
  Wildlore has notice-board jobs, a Casebook, legends, Regulars, Deeds and a Trade Ledger, but jobs are errands, no
  quest asks the player to choose, and the economy is mostly a set of taps and tills.

## House rules (all sessions)
- Read CONTRIBUTING.md first. UK English (Irish English in Ireland), warm and a bit wry, no em-dashes in anything a
  player reads. Rated 16+. Real places and real facts only: if you are not sure, leave it out. Local language only
  where you are sure of it.
- Code reads like the code around it. Small additive edits to shared files; new logic in new files. 60 fps on a
  2013 iMac: no per-frame allocations in hot paths.
- Never break a save: new state defaults sensibly when an old save loads (absent flag = the old behaviour), and
  everything new must reach a player who is already late in the game.
- Keep each JSON file's existing formatting; change only the keys you own. NPC dialogue lives in
  `data/dialogue/<zone>.json` or `common.json`; no other dialogue file is loaded.
- Scripts the validator loads must not name autoloads (Bus, Game, Settings, UIKit).
- Godot: `tools/get_godot.sh` fetches it (Linux works; CI uses it). Import once
  (`$(tools/get_godot.sh) --headless --path . --import`), then `tools/test.sh <fragment>` for your tests and the
  existing test files your session names. Run the full `tools/test.sh` ONCE at the end (you have your own machine).
  A run is good when it prints `0 failed`, `validate: 0 error(s)` and no `SCRIPT ERROR`. Where your work touches
  the main road or the first hours, also run `tools/playtest.sh slice 2` once.
- **No screenshots.** Prove things with tests, the validator and the playtest bot. The integrator takes the few
  pictures the release needs.
- New menu screens go in `tools/dev/text_audit_body.gd` SCREENS and must pass `tests/ui/test_text_fit.gd`.
- Anything that changes which tiles are solid must be mirrored in the playtest bot (`tools/playtest/bot.gd`,
  `_routing_zones`).
- Money: every pound moves through `Wallet` and `Purse`. Any new way to earn must be bounded (daily stamps, gluts,
  one-offs) and you must run the economy simulation (`core/economy_sim.gd`, `tools/dev/economy_sim.gd`) before and
  after and record both in your handoff. Read `docs/design/economy.md` first.
- Do the work yourself. If you hand any writing to a sub-agent, read every line it returns before committing it.
- Don't touch files another session owns beyond a one-line hook; say so in your handoff if you had to.
- Finish: write `docs/audit/w55_<name>.md` (what you built, how to reach it in play, numbers, test results, what
  you were unsure of, notes for the integrator), commit, push, and stop. No HANDOFF.md, no CHANGELOG or README
  edits, no version bump, no pull request.

## Sessions

### roads-england, roads-scotland, roads-celtic: a choice of road
Three sessions with the same job in different places. **roads-england**: England, plus the England to Wales and
England to Scotland border crossings. **roads-scotland**: Scotland and its islands. **roads-celtic**: Wales,
Ireland, Northern Ireland and the Isle of Man. Each owns its new zone files, their dialogue files, the `edges` and
the minimal tile changes at the new gap of the existing zones it connects to, its entries in the world map data,
and a generator script in `tools/zones/` (see `tools/zones/README.md`, `zlib.py`, and how leases cut a gap in
`docs/leases.md`).
- Start by listing, from `core/zone_graph.gd` and the zone `edges`, which neighbouring real places in your area
  have no direct way between them, and which dead-end towns could be joined up. Put the list in your handoff.
- Build **eight to ten new routes** that turn lines into loops, each a real road, path or pass a walker would know
  (for example the Pennine Way, Hadrian's Wall Path, the Snake Pass, the West Highland Way, the Lairig Ghru, Offa's
  Dyke Path, the Wicklow Way, the Antrim coast road): real landscape, the wildlife that is really there (existing
  species only, at the par level of the places it joins), six or more encounter entries, trainers with something to
  say, at least two plaques with true history, signs, and something off the path worth finding (a point of
  interest, a field spot or a letter trail, using the existing systems and their generators).
- **Never a sequence break.** A new route must not let the player reach any place earlier than the story allows.
  Join places that open at the same point in the story, or put a gate on the route that uses the same flag as the
  existing gate between them. Prove it: a test that walks the zone graph with the flags a player has at each story
  step (`data/objectives.json` gives the order) and shows that the set of places reachable at each step is the
  same as before, apart from your new routes themselves.
- Routes are optional: nothing the story needs may be only on them. Rail, ferry and "Where next?" keep working.
- Keep green: `tests/world/test_zone_data.gd`, `tests/data_api/test_coverage.gd`,
  `tests/core/test_world_consistency.gd`, `tests/core/test_leases.gd`, `tests/story/test_p6_story.gd`,
  `tests/field/test_field_spots.gd`. Run `tools/playtest.sh slice 2`.

### contracts: work with a story in it
Owns a new `core/contracts.gd`, `data/contracts/*.json`, a new `story/contract_talk.gd`, a Contracts tab in the
Journal, and the dialogue and zone additions each contract needs. Reuse what exists: notice boards
(`core/jobs.gd`, `world/noticeboard.gd`), evidence (`core/casebook.gd`, `core/examine.gd`), the `legend` command
for a creature stood in the world, `core/standing.gd`, `core/rumours.gd`.
- A contract is posted on a town's notice board by a named person with a problem: something is taking the hens,
  the lambs, the washing, the sleep of a whole village. Four beats: **take it** (the fee is agreed, and can be
  haggled if your standing there is good); **look into it** (two to four clues: tracks and leavings to examine,
  witnesses who disagree, a place to visit at the right hour or in the right weather); **prepare** (the Journal
  records what you have worked out: what it is, its types, what it dislikes; a wrong guess makes the fight harder,
  never impossible); **face it** in its lair, a named creature of an existing species above the local par, stood
  in the world.
- **Then a decision that somebody has to live with.** At least two real options per contract (drive it off, catch
  it, leave it be and tell the truth, take the landowner's side, take the creature's), none of them simply
  correct. The choice changes something that stays changed: who is at the next market, what a resident says for
  the rest of the game, a field that is fenced or left, your standing with two groups in opposite directions,
  whether a later contract appears at all.
- **Twelve contracts**, at least two in each of England, Scotland, Wales and Ireland and one in Northern Ireland,
  each built on a real local tale or a real kind of trouble (the Beast of Bodmin, the Buckland shag, the black dog
  of Bungay, a kelpie at a ford, a pine marten in a hen house, a seal blamed by a fishery), with the real story in
  the Journal afterwards. Spread across the story so there is always one within reach; late-game players see all.
- Fees are modest and one-off; run the economy simulation. Tests: each contract can be finished by every branch,
  flags default safely, choices persist and change what they say they change.

### stories: side quests people remember
Owns `data/quests/w55_*.json` and the dialogue and zone additions they need, plus the smallest additions to
`core/quests.gd` that branching needs (read it and `data/quests/` first: 194 quests exist; almost none asks the
player to choose).
- **Six quest chains**, one each for England, Scotland, Wales, Ireland, Northern Ireland and the islands, three to
  five steps each, about people: a ferry that is to be withdrawn, a chapel being sold for flats, a wind farm on a
  moor, a family farm with no one to take it on, a Gaelic-medium school short of pupils, a pub that is the last
  one. Real pressures on real kinds of places, told even-handedly, with nobody a cartoon.
- Each chain turns on **one decision with no clean answer**, made by the player after hearing more than one side,
  and each ends with the world visibly different: a building open or shut, a person who has moved away or come
  back, a notice on a board, a line other residents now say, a letter months later that tells you how it went.
  Use the calendar and the post so consequences arrive later, not in the same conversation.
- Rewards are things (a keepsake for the home shelf, a recipe, an outfit piece, a Regular's favour), not cash.
- Tests: every branch can be finished, consequences persist, old saves are untouched until the player starts one.

### trade: buying low, selling high, and knowing why
Owns `core/trade.gd`, `data/trade.json`, `core/market_hall.gd`, `core/markets.gd`, their screens, and a new
`core/trade_news.gd`. Read section 2 of `docs/design/2026-10-21-deeper-wildlore.md` and `docs/design/economy.md`
first, then play the numbers: where is trading dull today?
- **Prices have reasons.** Trade news: a few seeded events a week that really move prices in real places (a poor
  apple harvest in Herefordshire, a herring glut at Lerwick, a festival crowd, a rail strike that widens every
  spread, a late frost). The player hears them on the wireless, from stall-holders and on market boards before or
  as they happen, so that acting on news is the skill.
- **A ledger worth opening.** A trader's ledger page: what you last saw each good sell for and where, the best
  spread you know of, what is in season, what in your bag is about to go off. Only what the player has seen or
  been told; no all-seeing price list.
- **Orders.** Stall-holders and businesses post delivery orders (bring six Arbroath smokies to Cardiff Market by
  Friday) with a premium for speed and for arriving fresh. Bounded per day; they should make the new routes and
  the coracle worth using.
- **A trader's standing.** Make the existing Trader trade (`core/trades.gd`) open things that change how you
  trade, not just a percentage: a bigger pannier, credit at a market, first sight of the news, a stall of your own
  on market day.
- Keep it a game of friction, not a tap. Economy simulation before and after; the first-lease day must not move by
  more than a few days. Tests for the news seeding, the orders, the ledger's memory, save defaults.

### enterprise: money that changes the place
Owns `core/deeds.gd`, `core/deed_yield.gd`, `data/deeds/*`, their screens, and a new `core/town_projects.gd` with
`data/town_projects.json`. Read the Deeds part of the design doc and `core/deeds_sim.gd` first.
- **Running a business is a series of small decisions.** Each Deed gets two or three upgrades with trade-offs (a
  second fryer or a longer lease; rooms or a restaurant), a monthly event that needs an answer (the health
  inspector, a supplier putting prices up, a coach party, a bad review), and a manager whose character matters
  (the Regulars already manage Deeds: make who you appoint change what happens).
- **Town projects: things worth being rich for.** In about fifteen towns, something the place needs that the
  player can pay towards, alone or in stages: a footbridge washed out in a flood, a ferry that stopped running, a
  lifeboat, a bandstand, a library's opening hours, a derelict mill. Real kinds of project for the real place.
  Finishing one changes the world for good: a shortcut opens (coordinate by using a `project_<id>` flag on a gate
  or a hidden warp inside an EXISTING zone; don't create new zones, the roads sessions own those), a market gains
  a stall, residents say so, your name goes on a plaque, the town's standing with you rises.
- Costs scale by par (`ParLevel`), the way Jobs do. These are sinks: the simulation must show late-game money
  draining into them at a sensible rate without starving the mid game. Tests for upgrades, events, project stages,
  save defaults.
