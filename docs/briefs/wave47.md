# Wildlore: These Isles 5.0, wave 47: "Every Door"

The owner's direction (2026-10-30), after walking round early-game houses: "Most houses or buildings have nothing to
do. Give the player a REASON to check every home. I find myself not bothering because all there is is dialogue.
Moves animate the same in battle. It's not immediately obvious what move types work against each Keeper. There's
no mechanic to buy special moves (TMs). On the map, add a feature where you click a town and get a GPS route there.
I want players to be able to spend hours in a single region. Make the game deep and special." The reference game
the owner named is **The Witcher 3**: loot behind every door, letters and diaries that tell small stories and start
treasure hunts, notice-board errands, merchants trading out of front rooms, a bestiary that says plainly what beats
each monster, question marks on the map worth walking to, and Gwent (a card in every innkeeper's pocket).

Base: branch `polish-5.0` (4.6.0 + the HP bar fix + `story/script_hooks.gd`). You work in a git worktree already on
your branch `w47-<letter>-<name>`; commit there, don't push. Read docs/briefs/wave34.md (house rules, Finish) and
docs/briefs/qol_common.md first, then only the files your part needs. Be token-efficient: grep and `sed -n` over
whole-file reads, long output to files, scripts (python3) over hand edits for anything repeated.

## House rules that matter most here
- Rated 16+, warm and wry, UK English (Irish English in Ireland), no em-dashes anywhere in player-facing text,
  accurate real-world facts only (if unsure, leave it out). Never preachy. Teach by doing.
- Never break saves: new state is flags or new GameStateData fields with safe defaults in from_dict. The owner is
  mid-playthrough on an old save; everything you add must appear for them without a new game.
- 60 fps on a 2013 iMac, Compatibility renderer. Nothing per frame that allocates. Render once, cache.
- Validator-loaded scripts (anything core/game_state_data.gd or tools/validate.gd reaches, and every core/*.gd
  you add) must not name autoloads (Game, Bus, Router, Settings, Audio) or UIKit. Pure logic in core/, the
  scene glue in world/ or ui/.
- Hot shared files (core/game_state_data.gd, story/commands.gd, story/script_hooks.gd, world/overworld.gd,
  ui/almanac_screen.gd, core/almanac.gd, ui/menu_logic.gd, tools/validate.gd, data/items/*.json you don't own,
  data/zones/*.json, data/dialogue/*.json): small additive edits only, one line where one line will do; new logic
  in new files. Zone and dialogue JSON: ONLY session D may edit data/zones/*.json and data/dialogue/*.json (its
  chapmen). Everyone else attaches behaviour at runtime by zone id, npc id or prop type (see Hooks below).
- `story/script_hooks.gd`: `ScriptHooks.wrap(zone_id, npc_id, commands, data)` runs before every NPC script.
  Add ONE line there calling your own `static func hook(zone_id, npc_id, commands, data) -> Array` in your own
  core file. It must be cheap (a dictionary lookup) and return `commands` unchanged when you have nothing.
- The overworld interact chain (world/overworld.gd `interact`): add ONE `if await <YourScene>.interact(self, p): return`
  line, placed before the `var s := zone.sign_at(p)` line, with your logic in world/<yours>_scene.gd (copy
  world/examine_scene.gd + core/examine.gd: a pure core class decides, the scene talks and plays sounds).
- The Almanac (core/almanac.gd `pages`, ui/almanac_screen.gd) is the player's book of pages. A new page = your own
  ui/<x>_tab.gd (copy ui/gazetteer_tab.gd) plus one entry in Almanac.pages/NAMES and one line in the screen.
- Shared 4-core machine with eight other agents: targeted tests while you work (`tools/test.sh <fragment>`), the
  full `tools/test.sh` once at the end (0 SCRIPT ERROR, 0 failed, "validate: 0 error(s)"). Screenshots ONLY with
  `tools/shot.sh <out.png> 14 <game args>` (silent, off-screen, no focus; e.g. `--boot=macclesfield@20,20`,
  `--menu=<name>`, `--battle=spikkin:12 --battle-auto`). Look at every new screen you add.
- Each session adds its own tests under tests/<area>/test_w47_<letter>.gd (new files, so merges don't clash).
  Pure core classes take a seeded `Rng` (core/rng.gd) so tests are deterministic.
- Dev switches: `--menu=<x>` opens a menu (ui/dev_menu.gd), `--boot=zone@x,y`, `--flag=k=v`. Add what your
  screenshots need to ui/dev_menu.gd (small additive edits).
- Items: new items go in your own data/items/w47_<letter>.json (every file in data/items is loaded; copy the shape
  of data/items/field.json: id, name, kind, price, desc, plus whatever your kind needs). Selling: items with a
  price sell at half in any shop. A new `kind` needs a one-line case wherever kinds are matched (grep `"repel"`).
- Dialogue commands available to scripts you build at runtime: say, choice (sets a flag to the index), if
  (flag / not), set, give_item, take_item (check story/commands.gd for the exact names), shop, sfx, battle. Build
  command lists in code with these; don't invent new commands unless you own them.

## Sessions

### A: Behind every door (searchable furniture and loot)
Interiors have 1,177 bookshelves, 349 kitchen dressers, 776 display cases, 238 beds, 2,166 tables; today you can
only look at them. Make the furniture of every interior searchable, Witcher style: face a bookshelf, dresser, display
case, bed, sofa, fireplace, piano or clock and press confirm; it says what you find and gives it to you.
- core/search.gd (`Search`, pure): `static func stash(zone: ZoneData, prop: Dictionary, data, rng_seed) -> Dictionary`
  returns `{"item": id, "n": 1, "line": "..."}` or `{"money": pence}` or `{"nothing": true, "line": "..."}` or
  `{"curio": id}` deterministically from hash(zone.id, prop x,y, week stamp): the same drawer holds the same
  thing until it restocks. A searched prop is flagged (`Search.flag_key(zone_id, x, y)` -> value = the week stamp
  from Calendar.today_key or data.day_count / 7) and restocks after 7 in-game days. About 1 prop in 3 holds
  nothing ("Socks. Only socks."), 1 in 3 a common forage or craft material or a snack (pull ids from
  data/items/materials.json, healing.json, snares.json), 1 in 5 coin (20p to £3), 1 in 8 a curio (below), 1 in 40 a
  real find: a charm (data/items/charms.json), a rare snare, or a chapbook id from
  data/items/w47_d.json if that file exists at runtime (read it with FileAccess; don't depend on session D's code).
  The loot table leans on the house kind and region: kitchens give food, a study gives curios and chapbooks, a
  Sanctuary cupboard gives healing, a shop's back room gives its own stock. The zone's `kind` string and the
  interior's id (e.g. `*_home_*`, `*_sanctuary`, `*_shop`, `*_pub`, `*_church`) tell you which.
- Curios: a new item kind "curio" in data/items/w47_a.json, 60 of them, each a small real thing of these isles with
  a one-line description and a price (£1 to £40): a Toby jug, a Staffordshire flatback, a Goss crested china pot
  with a town's crest, a Bakelite radio, a brass miner's lamp, a Clarice Cliff saucer, a Wade Whimsie, a Victorian
  stereoscope card, a Dinky toy, a Penny Black (fake), a ration book, a ticket from the 1966 final. Curios do
  nothing but sell, and the Fieldbook "Curios" page (ui/curios_tab.gd, an Almanac page) shows the ones you have found
  with their descriptions, out of 60, with a pat on the back at 20, 40 and 60. The owner wants collectables.
- Residents react: if the resident of a home is in the room when you search (any npc in the zone), the first search
  of each visit gets a wry line from them via Search.quip(zone, data) ("Help yourself, everyone else does.") shown
  before the find, no permission mechanic, no consequence. Keep it light.
- world/search_scene.gd: interact hook; sfx "item" or "bump"; the line then the find. TrainerStats: count searches
  and curios found (small additive edit to core/trainer_stats.gd, a new tally).
- Dev: `--menu=curios` opens the page with 12 found (dev_menu.gd).
- Tests: deterministic stash, restock after 7 days, every item id in the tables exists in the ItemDB, every curio
  has a price and desc, no em-dashes.

### B: Letters, diaries and treasure trails
Witcher's best door is a letter on a table that starts something. Author ~180 short papers (letters, diary
pages, shopping lists, a child's drawing described, a telegram, a pools coupon, a will) in data/letters/<region>.json
and lay them on tables in interiors at runtime; ~40 of them start a treasure trail that ends at a dig spot on a
route or a hidden cache in another building.
- Schema (you own it): `{"papers": [{"id": "ltr_<slug>", "zone": "<interior zone id>", "title": "Letter from Aunt Nell",
  "lines": ["...", "..."], "trail": {"zone": "<outdoor zone id>", "near": [x, y], "clue": "Under the lone oak where the
  path forks.", "reward": {"item": "<id>", "n": 1} | {"money": 1500} | {"curio": "<id from data/items/w47_a.json>"}}}]}`.
  `trail` is optional. Papers go on the first `table` or `kitchen_dresser` prop of the zone (runtime: core/letters.gd
  `static func at(zone_id) -> Array`, `prop_for(zone: ZoneData) -> Vector2i`), one visible paper sprite (a small
  white quad on the table; a flat mesh is fine, see how Forage draws props) until read; reading is once, after
  that it says "You've read this one." Reading a paper with a trail puts it in the Papers page with the clue and
  marks the trail zone on the world map as a "?" (MapLogic.marks: add a mark kind, small additive edit).
- Dig spots: in the trail zone, within 2 tiles of `near`, on a walkable grass/earth/sand tile with no prop,
  npc, warp or sign (use ZoneData.landing_near as the fuzz), a faint disturbed-earth decal appears once the paper
  is read; interact: "You dig." then the reward. world/trails_scene.gd. The validator checks every trail zone
  exists and `near` is in bounds (small additive edit to tools/validate.gd; pure checks in core/letters.gd).
- Voice: these are the game's best writing, 2 to 6 lines each, period-correct and placeable (a 1947 letter from a
  Bevin Boy, a lighthouse keeper's log, a note from a Land Girl, a Traveller's notice, a Troubles-era school letter
  handled with care, an Irish emigrant's letter home, a Welsh chapel minute). Humour where it fits. No real
  private individuals. Cover every region in data/zones (read `region` from the zone files; every region gets 4+).
- ui/papers_tab.gd (Almanac page "Papers"): read papers, with trail status (clue / dug). Stats tally for papers read.
- Dev: `--menu=papers` with 8 read, 2 trails open. Tests: schema validation of every file, trail tiles in bounds,
  reading once, reward delivery, no em-dashes.

### C: Residents with wants (trades, errands, front-room traders)
Give the residents something to want and something to sell. All runtime via the ScriptHooks line; no dialogue edits.
- data/trades/<region>.json: `{"trades": [{"id": "tr_<slug>", "zone": "<interior id>", "npc": "<npc id from the zone
  file>", "wants": {"item": "<id>", "n": 2}, "gives": {"item": "<id>", "n": 1} | {"money": 800}, "ask": "I'd give my
  good teapot for two Bilberries.", "thanks": "You're a love. Here.", "repeat": false}]}`. The hook appends to the
  resident's script: if the player has the wants, a choice "Give them the X?" then the swap, flag `tr_<id>_done`;
  otherwise the ask line is added at the end of their chat (once per day, DailyKey-stamped, so it doesn't nag).
  ~160 trades across every region: residents want forage, craft materials, dishes, fish, curios (ids from
  data/items/w47_a.json), wear items; they give charms, rare snares, dishes, money, a chapbook (ids from
  data/items/w47_d.json: read the file, don't import D's code), a wear item. Prices fair, a few bargains.
- Errands: ~40 two or three step errands using the existing quest shape (data/quests/w47_<region>.json, see
  data/quests/abroad_baddeck_frolic.json and how steps are driven by flags): "Take this parcel to my sister in
  Buxton", "Find out if the ferry still runs", "My cat's gone to the Sanctuary, bring word". Steps complete when
  you talk to the named npc in the named zone (the hook sets the step flag). Rewards modest, one memorable item each.
- Front-room traders: ~45 homes become informal shops after the chat: data/shops/home_<zone>.json (the existing
  shop shape, see data/shops/aberdeen_corner_shop.json) and data/trades/traders.json `{"traders": [{"zone", "npc",
  "shop": "home_<zone>", "line": "I do a bit of jam, if you're buying."}]}`; the hook appends the line then a
  choice "Have a look?" -> the `shop` command. Stock: things the corner shop doesn't sell: a jam maker, an egg
  man, a secondhand charm dealer, a fly-tying widow, a knitter (wear items), a chapbook peddler in 6 of them
  (chapbook ids from data/items/w47_d.json), a fossil hunter (curios).
- core/trades.gd (pure: hook, can_pay, pay), core/errands.gd (pure), one test file. The Almanac's Quest log
  already lists quests; errands appear there. Dev: `--flag` is enough. Validator: every trade's zone, npc and item
  ids exist (additive edit).

### D: Chapbooks (the TM system) and the chapmen
A chapbook was a cheap pamphlet sold by travelling chapmen; here one teaches a creature a move.
- data/items/w47_d.json: kind "chapbook", `"move": "<move id>"`, name "Chapbook: <Move Name>", price by power
  (£400 to £3,000), desc in a ballad-sheet voice. 60 chapbooks: 3 or 4 per type across all 16 types plus 8 kin
  moves everyone can use, chosen from data/moves/*.json (a spread of power, a few status moves). Never signature
  moves (grep `signature` in data/creatures and data/knacks.json).
- Rules in core/chapbooks.gd (pure): `can_learn(c: Creature, move_id, move_db) -> bool`: the move's type is one of
  the creature's types, or the type is "kin", or the species lists it in an optional `"chapbooks": [...]` key (you
  may add that key to up to 40 species in data/creatures for off-type flavour: a Hedgerow bird that can learn a
  Gale move). Already known -> no. Chapbooks are reusable (a book you keep). Use from the Bag on a creature
  (ui/bag_screen.gd `_use` path: add the kind to Bag.use_on in core/, which returns `{"learn": move_id}`; the Bag
  then runs the existing learn/forget prompt used on level-up (see ui or battle `forget` flow) outside battle).
  The Summary's move list shows nothing new; the Bag's picker shows "Can learn" / "Knows it" / "Can't" beside each
  creature when a chapbook is pending (small edit in bag_screen `_open_picker`).
- Chapmen: 14 chapmen NPCs standing by market stalls in 14 towns (Macclesfield, Buxton, Manchester, Chester,
  Shrewsbury, Cardiff, Bristol, York, Newcastle, Edinburgh, Inverness, Belfast, Dublin, Galway): you MAY edit those
  towns' data/zones/<town>.json (add an npc on a free tile beside a `market_stall` prop, sprite "shopkeeper" or any
  existing sprite id) and data/dialogue/<town>.json (their script: a greeting then `shop` on
  data/shops/chapman_<town>.json). Each stocks 10 to 14 chapbooks, 4 shared staples and the rest regional, so the
  full set needs the whole map. Chapmen rotate 3 of their books each real week (Calendar.today_key based pick in
  core/chapbooks.gd `stock(town, week) -> Array`; the shop command can take a stock override or you build the shop
  file at runtime: check ui/shop_screen.gd for how stock is read and add the least invasive hook).
- Validator: every chapbook's move exists, every chapman zone/npc/stall placement is on a free walkable tile
  (reuse the npc checks already there). Tests: can_learn cases, rotation determinism, every chapman file loads.
- Dev: `--menu=bag:chapbook` opens the Bag on a chapbook with the picker up (dev_menu.gd).

### E: Know your Keeper (the briefing)
The owner: "it's not immediately obvious what move types work against each Keeper". Witcher's bestiary states
weaknesses plainly. Do the same for Keepers and County Show aces.
- core/keeper_intel.gd (pure): for each Keeper (grep data/trainers for the ten Stone holders and the Moot; the
  badge ids in data and story tell you which), `types(keeper) -> Array` (the types their team leans on),
  `beats(keeper, chart) -> Array` (types super-effective against most of their team, from core TypeChart),
  `hints(data, keeper) -> Array` (the lines gathered so far), `team_known(data, keeper) -> Array` (species revealed).
- Gossip via the ScriptHooks line: data/keeper_gossip.json `{"<keeper id>": [{"zone": "<town or interior id>",
  "npc": "<npc id>", "line": "Mabon's lot are all Hedgerow. Take something with a bit of fire."}]}`, 4 per Keeper
  in their town's homes and pub (pick real npc ids from the zone files), appended to that resident's chat once;
  hearing one records it (flag) and reveals one team member in the briefing.
- The hall door: every Keeper hall has a sign or the warp into it; add a runtime line when the player reads the
  hall's sign or stands at its door (the sign lines go through `_sign_lines` in overworld: small additive hook that
  appends KeeperIntel.door_line(zone_id, data), e.g. "Keeper Mabon, Hedgerow and Brook. Fire and Gale moves bite.").
  If a hall has no sign, add one at runtime beside the door (a sign dictionary pushed onto zone.signs at load is
  fine if ZoneData allows; otherwise the door warp's first use says it).
- Pre-fight check: when a Keeper battle starts (BattleIntro / the VS splash, battle_ui), the splash shows the
  Keeper's types as chips and the "beats" types in gold; if NO move in the party is of a "beats" type, the splash
  adds a one-line warning in amber: "Nothing in your bag bites. Chapbooks and the Sanctuary are a walk away."
- Almanac page "Keepers" (ui/keepers_tab.gd): each Keeper met or in a visited town: portrait sprite, types, what
  beats them, team revealed so far (silhouettes for the unknown), gossip lines gathered, record (beaten / not).
- The existing in-battle move hint (`move_hint`) stays. Dev: `--menu=keepers`. Tests: beats() from the chart for
  every Keeper, gossip ids exist, no em-dashes.

### F: Moves that look like themselves (battle FX)
The owner: "moves animate the same in battle". Today FX go by move kind (battle_ui/fx.gd "attack" cue with
move_type). Make every move look like its type and its shape, and give signatures their own choreography.
- Add `"fx": {"shape": "<shape>", "colour": "<hex, optional>"}` to every move in data/moves/*.json by a python
  script over name, type and category: shapes `bolt` (one projectile), `volley` (3 to 5 small), `beam`, `slash`
  (melee arc at the target), `pounce` (the user lunges), `burst` (expanding ring on the target), `cloud` (lingering
  particles on the target, status moves), `rain` (falls from above the target), `quake` (ground shake + dust on
  both), `wave` (sweeps from user to target), `self` (glow on the user, buffs), `song` (notes drifting), `bite`,
  `wing`. The existing weather_tactics.json moves keep their weather look plus a shape.
- battle_ui/fx.gd: a palette per type (16, in one dictionary: core colour, highlight, particle shape index) and a
  renderer per shape using the existing pooled sparks (`burst(...)`), the actors' nod/hit, and a few new cheap
  primitives (a stretched quad for beam/slash, a textured quad for bolts). No new textures over 64x64; generated
  in code or tools/sfxgen style. The hit flash tints by type. Keep every move under 1.2 s at normal speed and
  honour Settings.battle_speed and reduce_flashing.
- 16 signature moves (one per type; grep `signature` in data/creatures and data/knacks.json, pick the best known)
  get hand-written sequences in battle_ui/fx_signatures.gd (a dictionary move id -> Callable) that layer two or
  three primitives with a beat between.
- Sound: Audio.sfx already has hit variants; add type-flavoured swishes only if tools/sfxgen.gd makes them cheap.
- Verify with `tools/shot.sh out.png <delay> --battle=<species>:<lv> --battle-auto --battle-slow` at several delays
  and look at them. Tests: every move has a valid fx shape, every type has a palette, signatures map to real moves.

### G: Click a town, get a route (map GPS)
- core/zone_graph.gd (pure): build the graph once from every data/zones file: edges, warps between outdoor zones,
  rail (stations and the lines in data: grep `station`, `rail`, data/ferries.json for ferries) with a cost per hop
  (walk 1, rail 2 for the whole line, ferry 3). `route(from_zone, to_town, data) -> Array` of zone ids (BFS/Dijkstra),
  honouring what the player can use (ferries and rail you have used or that need no ticket; flight ignored). The
  playtest bot has `_zone_adj` in tools/playtest/bot.gd; lift it, keep the bot working on your class.
- ui/world_map.gd: on the cursor's town, a new action "Route here" (next to Fly), which stores
  `data.flags["route_to"] = town`, draws the route on the map as a dotted line between the towns along the way (the
  view already draws dots and marks; add a polyline layer in ui/map_view.gd), and shows the hop count and the
  modes ("3 zones, then the train from Stockport"). Picking the same town again clears it.
- In the overworld, a small breadcrumb chip top-left under the place indicator (ui/place_indicator.gd is the
  pattern): "To Buxton · 3 to go" and an arrow that points at the exit of this zone leading to the next zone on the
  route (the edge side, or the warp tile, or the station door). Re-computed on zone entry (Bus.zone_entered),
  hidden indoors, cleared on arrival with a soft chime. If the player wanders off route, re-route silently.
- Pad/keyboard: the Map's hint strip lists "Route". Tests: routes between known towns, rail preferred over a
  long walk, no route across the sea without a ferry, arrival clears.

### H: Question marks on the map (points of interest on routes)
Witcher's "?": dens, guarded treasure, places of power. Four kinds, all runtime-placed from data/poi/<region>.json
(you author ~120 across all regions, 2 to 4 per outdoor route zone): `{"pois": [{"id": "poi_<slug>", "zone":
"<outdoor zone id>", "near": [x, y], "kind": "den" | "camp" | "stone" | "cache", ...}]}`:
- `den`: a creature den (a dark mound prop); interact: three wild battles back to back (species from the zone's
  encounter table, levels +3), then the den's resident: one uncommon-coat creature of a species not otherwise
  met in that zone (`"species": "<id>"`), catchable. Restocks after 14 in-game days.
- `camp`: an Enclosure poachers' camp (a tent prop + 2 or 3 trainer NPC sprites at runtime, trainers built with
  TrainerParty from a small party def in the poi, levels scaled by core/par_level.gd); beat them all without
  leaving and a strongbox opens: money + one good item. Once.
- `stone`: a standing stone (prop exists) that gives a one-time training boost to the lead (+4 training points in
  a stat the stone names, via Progression.add_training style edit) and a line of lore about standing stones of
  that region (real ones: Arbor Low, Castlerigg, Callanish, Avebury, Drombeg; say where the real one is).
- `cache`: a hidden box behind a rock or in a hollow tree, a real item (charm, rare snare, wear item, curio from
  data/items/w47_a.json by reading the file) and sometimes a paper (one line of lore you write). Once.
- Map: a "?" ring appears on the world map for a poi once you have stood within 6 tiles of it or a resident has
  mentioned it (a `"mentioned_by": {"zone", "npc"}` optional field, via the ScriptHooks line: the resident adds a line
  "There's a den up past the stile, if you're brave."); it becomes the kind's icon once done. MapLogic.marks gets
  a mark kind (small additive edit; session B adds one too, keep yours to one `if`).
- core/poi.gd (pure: placement with ZoneData.landing_near fuzz, state flags, rewards), world/poi_scene.gd (props,
  interact, battles via Router.battle like the trainer and wild paths). Validator checks zones and bounds.
- Tests: placement determinism, den restock, camp once, stone once per stone, cache once.

### I: Trumps (the card game, the Gwent of these isles)
A collectable card game played against residents all over the isles: the one reason above all others to knock on
every door. One card per species (200 + the appendix is fine to leave out), stats derived in code, no card data to
author beyond the holders.
- core/trumps.gd (pure, class `Trumps`, seeded Rng): a card is `{"species": id}` with five stats computed from the
  species (`card(species: Dictionary) -> Dictionary` with `size` 1-10 from Cries.size_of or base hp, `speed`,
  `lore`, `grit` ((def+ward)/2) each scaled 1-10 from base stats against the 200-species spread, and `rarity` 1-10
  from the species' encounter rarity / legend status). A game: both sides hold 5 cards; the leader picks a stat,
  higher value wins the pair, the winner takes the loser's card into their hand and leads; a tie means the leader
  picks another stat on the same cards; 12 rounds or until one side is empty; most cards wins. AI: picks its
  card's best stat compared to the 200-species average, with a 20% random pick. Wagers: win and you get the
  resident's held card (first win) and then a £ prize (small, once a day); lose nothing. Each game is once a day
  per resident (DailyKey).
- Holders: generated, not authored: `Trumps.holder(zone_id, npc_id, idx) -> String` picks, for residents in
  interior homes (zone kind interior and id containing "home" or "pub" or "inn"), one species card from the
  region's encounter tables (MapLogic.nearby_species style, plus 1 in 6 a card from a neighbouring region, and in
  the 10 Keeper towns' pubs a legend card) so each region's residents hold its set. ~1 resident in 2 plays
  (hash). Their chat gets, via the ScriptHooks line, "Fancy a game of Trumps?" (choice) which opens the game.
- data.trumps (new GameStateData field, a Dictionary {"cards": {species: n}, "wins", "losses", "streak"}; from_dict
  default {}). The player starts with 5 cards of their own: the first game is offered by Mum at macc_home (hook
  on her npc) who gives the starter five (lead species + 4 Cheshire commons).
- ui/trumps_screen.gd + .tscn: two rows of cards (yours face up, theirs face down bar the top card), card art =
  the species' front sprite in a framed card with the five stats; pick a stat with up/down + confirm; a short beat
  as the opponent's card flips; the taken card slides across. Keyboard, pad, mouse. The Almanac page "Cards"
  (ui/cards_tab.gd): the album, by region, silhouettes for the missing, a region's full set gives a prize (a coat
  for a species of that region, via Creature.variant, or a chapbook id read from data/items/w47_d.json), and
  `Trumps.region_complete(data, region) -> bool`.
- Story command `"trumps"` (one additive case in story/commands.gd that opens menu "trumps:<zone>:<npc>").
- Tests: card stat scaling covers 1-10 across the dex, a game is deterministic with a seeded Rng, holders are
  stable, region sets computable, the album never shows appendix species.
- Dev: `--menu=trumps:dev` (a game vs a dev deck), `--menu=cards`. Screenshots of both.

## Finish (every session)
Run `$(tools/get_godot.sh) --headless --path . --import` once, then
`tools/test.sh > /tmp/t_w47_<letter>.log 2>&1; grep -c "SCRIPT ERROR" /tmp/t_w47_<letter>.log; grep -E "passed|validate:" /tmp/t_w47_<letter>.log`:
0 SCRIPT ERROR, 0 failed, "validate: 0 error(s)"; and `tools/playtest.sh slice 2` passes. Do NOT run the full-story
playtest. Add your feature to CHANGELOG.md under a new "## What's new in 5.0: Every Door" heading (create it if
absent; 2 to 4 bullets in the file's voice). Commit with trailers
`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` and
`Claude-Session: https://claude.ai/code/session_01RxdRQyoNPdS3Yb2zkKyXDT`. Do not push. Report in under 150
words: what you built, files touched outside new files, test counts, screenshots' paths, anything left undone.
