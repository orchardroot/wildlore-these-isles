# Wave 55: contracts (work with a story in it)

Branch `w55-contracts`, cut from `int-w55`. Twelve notice-board contracts, the system under them, a Contracts tab in
the Journal, and the people and look-spots each one needs in the zones. No screenshots were taken.

## What was built

| Piece | File |
|---|---|
| The logic (state, fee, haggle, clues, working theory, fight level, decision, report, validation) | `core/contracts.gd` |
| The conversations (the board notice, the poster, a witness, the lair) | `story/contract_talk.gd`, command `{"do": "contract", "as": "board" \| "poster" \| "clue" \| "lair"}` |
| The Journal tab | `ui/contracts_tab.gd`, one tab added in `ui/quests_screen.gd` |
| The twelve contracts | `data/contracts/*.json` (the file is the source of truth for the people and look-spots it needs) |
| Putting people and look-spots in the zones | `tools/zones/contracts_w55.py` (text insertion, keeps each file's formatting) |
| Tests | `tests/core/test_contracts.gd` |

### Hooks in shared files (all small)

- `world/noticeboard.gd`: three lines. A board with a contract pinned on it runs the notice first, then opens the jobs.
- `world/examine_scene.gd`: nine lines. An examine spot with a `"clue": "<contract>.<clue>"` key adds the clue's words,
  at the right hour and in the right weather.
- `story/commands.gd`: the `contract` command (two lines).
- `data_api/story_validator.gd`: `contract` added to COMMANDS and a case that checks its id and role.
- `ui/quests_screen.gd`: a fourth tab, `contracts`, in the Journal (`setup("contracts")` opens on it).
- `tools/validate.gd`: runs `Contracts.validate`.
- `core/economy_sim.gd`: one line, the contracts' fees join the once-only lumps.
- `tools/dev/text_audit_body.gd` and `ui/dev_menu.gd`: `quests:contracts` is a screen, with a sample contract under way.
- Zones and dialogue: only NPCs and `examine` entries were added (24 zones, 24 dialogue files). No tile, edge, warp or
  prop was changed, so nothing in the playtest bot's routing moved.

None of the wave 54 files (`overworld.gd`, `player.gd`, `follower.gd`, `npc.gd`, `battle_ui/*`, `ui/map_*.gd`,
`core/discovery.gd`, `core/ambience.gd`, `world/sky_and_light.gd`) was touched.

## How a contract works in play

1. **Take it.** Walk up to a town's parish noticeboard. If a contract is pinned over the odd jobs you are asked
   "Read the notice, or just the jobs?". Reading it gives the person who posted it (named, with a trade and a
   voice), the notice and the trouble, and the fee. In a nation where you are a Regular or better you can **haggle**
   (+15%, +25%, +35% by standing tier). The poster stands in the same town and will make the offer in person too.
   It needs the badges for the place (gate in the table below). Taking it opens a card in **Journal > Contracts**.
2. **Look into it.** Three or four clues. Each is either a **look-spot** (an examine spot in the zone: tracks,
   leavings, a stretch of bank; some answer only at a certain hour or in certain weather, and say so if you come
   at the wrong time) or a **witness** (a person who tells you what they think, and two of them disagree).
   Nothing counts until the contract is taken, so an old save's walkers just give the idle line.
3. **Prepare.** Each clue points at some of three or four hypotheses and rules out others. The Journal shows what
   the clues justify, and only that: nothing, then "one of these", then once one hypothesis is clearly ahead, "what it
   is, its types, and what it is weak to" (read from the type chart). Every contract is solvable from its clues, and
   no clue ever rules out the truth.
4. **Face it.** Its lair is in a nearby zone, and the creature stands there in the world once the contract is taken
   (and goes when it is decided). At the lair you are told what you have worked out, then asked what you reckon it
   is. Naming it right meets it at its authored level, saying you cannot say adds 2 levels, naming it wrong adds 4. It is a named creature of an
   existing species, authored above the par it was written for and lifting with the story (`ParLevel.lift`). A
   whiteout leaves the contract open; you can come back.
5. **Decide.** If you beat it you choose between **two or three real options**, none of them simply right, or
   "think it over" (it waits). If you catch it instead, that is a fourth ending. Each choice changes things that
   stay: flags that residents' `show_if` and lines read, your **repute** with two groups in opposite directions
   (farmers against wardens, townsfolk against miners, walkers against crofters ...), and your standing in the nation.
6. **Tell the poster.** The fee (a share, set by the choice) is paid once, in the local money, with the standing
   change, and the poster says what they make of it. Afterwards they have an `after` line for the choice.
   The Journal then adds **what you did** and **the real story** behind the tale.

Repute is a small new thing: `ct_rep_<group>` moves the poster's fee by 5% a point (within four points either way).
It is visible in the Journal under "How people see you".

## The twelve

Gate is the badges needed to see the notice. Fee is the base in pounds (one-off; Irish contracts pay in euros at
the local rate), before haggling and repute. England 3, Scotland 3, Wales 2, Ireland 3, Northern Ireland 1.
Each ending also moves repute with two groups and your standing in the nation, and the catch ending is a
fourth way to finish. "Shown" says which resident or line carries the change.

### England

1. **Something in the Hen House** (`mink`). Manchester board, 2 badges, fee 560. Maureen Hulme's hens are being
   killed in a shut shed on Chat Moss. Real thing under it: American mink, farmed for fur from the late 1920s,
   wild on our rivers, and the water vole's undoing. Creature: **Houdini**, a Minkshade (brook, night), lair on
   Chat Moss. Suspects: a fox, an otter, a mink. Choices: *trap it and take it away* (farmers up, wardens down;
   an egg seller in Manchester; "hens safe"), *mink-proof the shed and leave it* (wardens up a little, farmers down;
   a neighbour on the Moss who has lost his hens instead), *give it to the Wildlife Trust's mink raft scheme*
   (wardens up; a vole counter appears on the Moss).
2. **The Orchard Under Water** (`beavers`). Exeter board, 4 badges, fee 1,380. Roger Hockin's apple trees are
   gnawed and his bottom field is a pond. Real thing: wild beavers found on the River Otter in Devon in 2014, a
   five year trial, and the decision in 2020 that they could stay. Creature: **Brunel**, an Afanc (brook, brawn),
   lair in the Exe estuary meadows. Suspects: a beaver, an otter, deer. Choices: *have them caught and taken away*
   (farmers up, wardens down; an angler who misses the frogs), *back the Trust and have Roger paid* (wardens up;
   a cider seller whose label now has a beaver on it), *wire the trees and fit a flow device* (both a little;
   the pond stays, the cider seller says so).
3. **The Beast of Bodmin** (`bodmin`). Penzance board, 5 badges, fee 2,200. Jory Tregenza has lost eleven ewes,
   hidden under the gorse. Real thing: the 1995 inquiry that found no verifiable evidence of a big cat on Bodmin
   Moor, and a tale that is worth a good deal to the Cornish tea trade. Creature: **The Beast**, a Bodminax
   (night, brawn), lair on the Tintagel moor. Suspects: a big cat, a pack of dogs, foxes. Choices: *organise a night
   watch* (flocks come in at dusk, the Beast moves on to somebody else's parish), *say nothing and leave it a rumour*
   (townsfolk up, farmers down; a stallholder selling Beast tea towels), *report it and have it taken to a sanctuary*
   (the moor goes quiet; a regular who misses it).

### Wales

4. **Who's Taking the Lambs** (`kites`). Aberystwyth board, 3 badges, fee 1,110. Gwilym Rees finds dead lambs with a
   big brown bird on every one. Real thing: red kites, down to a handful of pairs in the Welsh hills in the 1930s,
   and mostly scavengers. Creature: **Tag Seven**, a Forkwing (gale, hearth), lair on the Cambrian coast fields.
   Suspects: a kite, a raven, a fox. Choices: *scare the kites off the lambing fields* (farmers up, wardens down; the
   sky over the top fields is empty), *tell Gwilym the kite did not kill them* (wardens up a lot, farmers down; a
   kite sits on his gate), *ask the Trust for a lambing shed and a feeding post* (both a little, a neighbour behind;
   walkers stop to watch the kites at the post).
5. **Knocking in the Old Level** (`knockers`). Blaenavon board, 3 badges, fee 1,110. Gwen Pritchard of the Workmen's
   Institute: tapping from an old level, and the lights go out. Real thing: Blaenavon's ironworks and Big Pit, the
   knockers and coblynau of the mining tales, and the real danger of old workings. Creature: **Old Three-Taps**, a
   Tapknock (spirit, stone), lair on the Rhondda side. Suspects: coblynau, rotten timbers, water in old pipes. Choices:
   *let the council seal the level* (townsfolk up, old mining families down; a resident saying it is too quiet),
   *fence it and leave the knockers a crust* (miners up; a crust on a stone every Friday), *open it to guided visits
   with Elwyn as the guide* (both a little; tours leave the Institute at ten).

### Ireland

6. **The Black Horse at the Lake** (`puca`). Dublin board, 6 badges, fee 1,920. Eilis Kavanagh's mares bolt and a
   rider ends up in the Wicklow reservoir. Real thing: the pooka, Poll an Phuca (the Pooka's Hole), and the valley
   drowned for the Poulaphouca reservoir. Creature: **The Pooka**, a Pooka (night, fae), lair at the lake. Suspects: a
   pooka, a stray stallion, village lads with a sheet. Choices: *mark the drowned pool with a stone* (townsfolk up; a
   guide tells of the stone), *fence the shore and bring the horses in at dusk* (farmers up; a stable hand), *tell
   Eilis it was the village lads* (a lie: the lads shovel stables every Saturday and are not speaking to you).
7. **The Hens on the Roof** (`marten`). Sligo board, 7 badges, fee 2,190. Declan Gallagher has lost eleven hens
   through the roof. Real thing: the pine marten's return to Ireland, protected, and its link to the return of the
   red squirrel. Creature: **Gallagher's Ghost**, a Pinewraith (hedgerow, night), lair in Glenveagh. Suspects: a fox, a
   hawk, a pine marten. Choices: *trap it and move it forty miles* (farmers up, wardens down; hens safe, the problem
   is someone else's), *marten-proof the henhouse* (both a little; the Ghost tries the roof every evening),
   *leave it and tell the parish what martens do for the squirrels* (wardens up a lot, farmers down; red squirrels
   at the feeder).
8. **Lights Over the Cutting** (`bog`). Galway board, 7 badges, fee 2,190. Padraig Joyce's brother nearly lost in a
   Connemara bog hole, following a light. Real thing: will-o'-the-wisps and Stingy Jack, and the argument over
   cutting turf on protected bogs. Creature: **Jack of the Lantern**, a Wispet (fae, spirit), lair on the cutting.
   Suspects: a wisp, marsh gas, a turf thief with a lamp. Choices: *side with the cutters and mark safe banks*
   (farmers up; dry turf for sale in Galway), *side with the Park and let the bog rewet* (wardens up; the lights are
   seen more often), *lay a boardwalk and keep one bank for the family* (both; walkers on the planks).

### Northern Ireland

9. **The Giant Is Moving the Stones** (`giant`). Bushmills board, 8 badges, fee 3,280. Colm McAteer's guests find the
   Causeway columns in a new order each morning. Real thing: the forty thousand basalt columns, Fionn and
   Benandonner, and wear and falls on a World Heritage coast. Creature: **Fionn**, a Finnmacool (brawn, stone),
   lair at the end of the Causeway. Suspects: a giant, the sea, visitors. Choices: *fence it and close the cliff
   path* (wardens up, townsfolk down; a rope and a resident's complaint), *keep it open with guided night walks*
   (townsfolk up; a night walker), *show him the Larne ferry and send him to Scotland* (both a little; he is gone
   and the ferry is late).

### Scotland

10. **The Grey Horse at the Ford** (`kelpie`). Fort William board, 8 badges, fee 3,280. Morag Cameron of the mountain
    rescue: three walkers pulled out of one ford, all offered a lift by a grey horse. Real thing: kelpie tales and the
    speed of a hill burn in spate. Creature: **The Water Horse**, a Kelpie (brook, spirit), lair at the ford in the Great
    Glen. Suspects: a kelpie, the river, a stray pony. Choices: *build a footbridge* (walkers up, crofters down; a
    walker with dry boots), *mark the ford and leave it* (both; a sign and a rope), *bridle it the old way and make
    it carry the stones* (crofters up; a bridle that is never dry on the estate wall).
11. **Nobody Is Sleeping on the Township** (`corncrake`). Portree board, 9 badges, fee 3,640. Catriona MacLeod's hay
    field rasps all night. Real thing: the corncrake, late mowing payments in the Hebrides, and cutting from the
    middle out. Creature: **Crex**, a Corncrake (hedgerow, gale), lair in the hay meadows on Harris. Suspects: a
    corncrake, an owl, a rusty gate. Choices: *cut now and save the crop* (crofters up, wardens down; the township
    sleeps), *leave it until August and take the payment* (wardens up; the calling goes on), *mow from the middle
    outwards and leave cover* (both a little; the chicks get away).
12. **Who Is Eating the Salmon** (`seal`). Thurso board, 10 badges, fee 5,000. Hamish Sutherland's salmon come out of
    the nets with the bellies bitten. Real thing: grey seals and netsmen, warming rivers, and the sound of an
    acoustic scarer under water. Creature: **Auld Willie**, a Greyhaul (tide), lair at the river mouth on the Pentland
    coast. Suspects: a seal, an otter, poachers. Choices: *fit an acoustic scarer* (fishers up, wardens down; full
    nets), *tell the fishery the seals are not the whole story* (wardens up a lot, fishers down; Willie stays on his
    rock), *rebuild the nets so a seal cannot reach them* (both a little; the new nets hold).

Spread across the story: 2 badges (1), 3 (2), 4 (1), 5 (1), 6 (1), 7 (2), 8 (2), 9 (1), 10 (1). There is nothing at
0 or 1 badge: England's early zones (Cheshire, the Peak) already have a Wallaby Watcher quest on the Roaches, so a
contract there would have repeated it, and I chose to start at Manchester.

## Economy

Fees are one-off and bounded. A contract pays what `pay` jobs (2 to 5) pay at the badge count of **its own gate**
(`Jobs.money_for`), not at the player's, so waiting does not inflate it. The fee is paid once, by `Contracts.report`,
through `Wallet.earn_here` (euros in the Republic). It can move: a Regular or better can haggle (+15%, +25%, +35% by
tier), repute with the poster's group moves it 5% a point within four points either way, and each ending pays a
share (0.5 to 1.0). The twelve base fees add up to **27,860** (560, 1,110, 1,110, 1,380, 2,200, 1,920, 2,190,
2,190, 3,280, 3,280, 3,640, 5,000). The sim's upper bound assumes the best-paying ending and a Regular's haggle
(+15%): **32,039**, paid as the badges arrive (the sim's run pays 31,662 by badge 10). The theoretical ceiling for a
Pillar of every nation with the best repute is about 45,000. For scale, jobs pay 932,857 a year in the sim, so the
contracts are about 3% of a diligent year's job money and 2.4% of the 'dailies' player's year.

`EconomySim.run` now has a `contracts` income line (`Contracts.fees_through(badges)`, paid once as each badge
arrives). Nothing else in the sim moved. `tools/dev/economy_sim.gd -- 20`, before this branch and after:

| strategy | cash d30 | d78 | d90 | d180 | d360 | first lease | five leases | all ten |
|---|---|---|---|---|---|---|---|---|
| dailies, before | 3,792 | 153,335 | 3,243 | 37,799 | 164,868 | 81 | 171 | 312 |
| dailies, after | 3,489 | 179,246 | 34,448 | 67,636 | 192,726 | 81 | 162 | 306 |
| deed_rush, before | 2,688 | 335,858 | 71,228 | 443,514 | 2,381,658 | 81 | 93 | 141 |
| deed_rush, after | 2,420 | 361,806 | 1,915 | 474,147 | 2,412,291 | 81 | 90 | 138 |
| trader, before | 20,302 | 208,561 | 66,816 | 62,436 | 412,382 | 81 | 144 | 261 |
| trader, after | 23,499 | 234,472 | 98,478 | 92,729 | 441,457 | 81 | 138 | 255 |
| cook, before | 10,922 | 180,973 | 34,828 | 99,449 | 284,668 | 81 | 156 | 285 |
| cook, after | 14,119 | 206,884 | 66,338 | 28,579 | 313,135 | 81 | 150 | 279 |
| casino, before | 3,024 | 150,939 | 44,986 | 31,509 | 155,419 | 81 | 173 | 315 |
| casino, after | 2,896 | 176,851 | 30,926 | 61,543 | 183,399 | 81 | 165 | 307 |
| everything, before | 2,553 | 399,780 | 41,245 | 572,926 | 2,634,963 | 81 | 87 | 132 |
| everything, after | 2,250 | 425,691 | 72,778 | 603,721 | 2,665,758 | 81 | 85 | 129 |

(Cash on a given day jumps about because the sim spends as soon as it can afford a charm, a Deed tier or a lease, so
the day-90 and day-180 columns say more about what was bought that day than about the fees. The columns that
matter are the last three.) The **first lease day is 81 before and after in every strategy**; five leases and all
ten arrive 2 to 9 days earlier, the most for a pure saver (five leases at day 171 becomes 162), because 31,662 is
about a third of one lease. Nobody is rich a month in (day-30 cash for every strategy is within 3,200 of before),
and the lease guard rails in `test_economy.gd` still hold (see Tests).



## Tests

- `tests/core/test_contracts.gd` (final tree): `21 passed, 0 failed`. It covers: the data validates against the real zones and
  dialogue, every branch of every contract finishing (take, every clue, lair, fight, decision, report, pay once, save
  round trip), wrong-guess levels, clues solving every contract, hour-gated look-spots, fees, haggling, the board
  notice, witnesses, a lost fight, a beaten-but-undecided creature, residents showing each choice, standing, the
  lair NPC's `show_if`/`hide_if`, and a contract that waits on another's ending.
- Full `tools/test.sh` run once earlier on the tree two commits before the last, with one Bodmin clue too many:
  `3119 passed, 2 failed`, `validate: 0 error(s)`, no `SCRIPT ERROR`. The two failures: `test_contracts::test_the_files_validate`
  (Bodmin had five clues, limit four; **fixed** since, and the final `test_contracts` run above is green) and
  `test_text_fit::test_worst_screens_fit_with_large_text_and_the_readable_font`, which reports only `races:dev`
  at Large text (screens I did not touch; I did not check it against `int-w55` and believe it is not mine).
- `tools/dev/text_audit.gd -- quests:contracts quests quests:done`: `text_audit: 0 problem(s) on 3 screen(s)`.
- `tools/dev/economy_sim.gd -- 20` before and after: see Economy.

**Skipped, by the integrator's instruction:** the full suite on the final commit, and `tools/playtest.sh slice 2`
(Manchester and Chat Moss are on the England route; only NPCs were added, none cut anything off by the generator's
own reachability check, but the bot has not walked them). Please run both after merging, and
`tools/test.sh test_zone_data` for the 24 zones.

## What I was unsure of

**Facts to check before release** (each is in a contract's "real story", the Journal text after the decision).
I kept to things I am sure of, but these are the ones a reader could test:
- Mink: farmed for fur in Britain from the late 1920s; mink rafts with a clay pad; a mink kills more than it eats.
- Beavers: found on the Otter in 2014, a five year trial from 2015, allowed to stay in 2020, "first time a mammal lost
  from England was officially allowed to live wild again"; hunted out by the sixteenth century.
- Bodmin: the 1995 inquiry by the Ministry of Agriculture finding no verifiable evidence; the 1976 Dangerous Wild
  Animals Act theory (presented as a theory); Jamaica Inn trading on the Beast.
- Red kites: scavenging in Tudor London; a handful of pairs in mid Wales by the 1930s; releases of Spanish and Swedish
  birds from 1989; illegal poisoning still a danger.
- Blaenavon: ironworks founded 1789, World Heritage Site 2000, Big Pit closed as a colliery in 1980 and now a
  museum with former miners as guides; knockers and coblynau; the Coal Authority sealing old mine entries.
- Pooka: Poll an Phuca on the Liffey, drowned by the 1940s Poulaphouca reservoir (water for Dublin, power for
  the ESB); the rule about blackberries after the first of November.
- Pine marten: protected, back in Ireland from the late twentieth century, grey squirrel decline and red squirrel
  return where it recovered (researchers' finding, stated with "probably").
- Bog: marsh gas as the best explanation of will-o'-the-wisps; Stingy Jack and the turnip lantern; the 2011 turf
  cutting ban on many protected bogs with compensation.
- Causeway: about forty thousand columns, about sixty million years, Fingal's Cave on Staffa, World Heritage 1986,
  Fionn, Benandonner and Oonagh's trick.
- Kelpie: the horse that carries you under, the bridle; The Kelpies at Falkirk by Andy Scott, 2013; a hill burn rising
  a metre in an hour (an illustration, not a measurement of any burn).
- Corncrake: crex-crex heard a mile off; late mowing payments in the Hebrides; cutting from the middle out; Orkney and
  north-west Ireland as other strongholds.
- Seal: grey seals biting the bellies of netted salmon; Britain holding a large share of the world's grey seals;
  "in recent years Scotland has stopped licensing the shooting of seals to protect fisheries" (I believe the licences
  ended in 2021 but left the year out); acoustic scarers disturbing porpoises.

**Other things I was unsure of, or chose:**
- **The early gap.** The first notice is at 2 badges. England's Cheshire and Peak ground is already covered (the
  Roaches wallaby has its own quest and the Cat and Fiddle has plaques about hares and grouse), and I could not find
  a tale there I was sure of. A 0 or 1 badge contract would be the first thing to add. There is no contract in the
  Channel Islands or the Isle of Man either.
- **A fight comes before the decision.** Beating (or catching) the creature is how you reach the decision. A player who
  would rather not fight has no way to resolve a contract. I judged it better than letting a contract be solved by
  a conversation alone, but "meet it and talk" as a second approach would be a good follow-up.
- **The `needs` field** (a contract that appears only after a given ending of another) is built, validated and
  tested on a synthetic pair, but no real contract uses it. The twelve are all independent.
- **Haggling always works** once you qualify; there is no roll. It is a reward for standing, not a gamble.
- **Placement is automatic.** `tools/zones/contracts_w55.py` chooses free reachable tiles near each "near" anchor in the
  contract file (checking the NPC does not cut anything off, stays three tiles from the map border and a tile from
  every door or other thing). I took no screenshots, so a few people may stand somewhere odd (on cobbles by a road,
  say). To move one: check out the original zone and dialogue file, change the anchor in `data/contracts/<id>.json`,
  and run `python3 tools/zones/contracts_w55.py <id>`.
- **Journal tab labels** read "Contracts  N" with N the contracts taken and not yet reported. The text fit audit has a
  `quests:contracts` screen; see the test lines.
- **Merge risks.** Roads sessions edit `edges` and tiles of zones like Penzance, Tintagel, Exeter and the Peak; I add only
  NPCs and `examine` entries, but they sit in the same arrays the roads sessions might also extend. A textual
  merge should be fine, but run `tools/test.sh test_zone_data` after.
- **Sprites.** Every NPC uses an existing character sprite and every creature `creature:<species>` art that exists. A
  contract creature keeps its authored species even when the story lifts its level (no evolution), so the types in
  the Journal always match what you meet.
