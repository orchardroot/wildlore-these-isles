# Wave 54: Off the Beaten Track (target 5.4.0)

The owner's direction (2026-11-13): make the whole game more immersive; a black cat creature only the player has, who
joins early in the story; more of the water crossable; make it obvious which types beat which; make the world feel more
like an RPG, so people want to explore and not only go Keeper to Keeper; creative liberty; a few Easter eggs.

Four read-only audits fed this brief (type clarity, exploration, immersion, water). Their main findings are quoted in
each session below so you don't have to redo them.

Base branch `int-w54` (from main at 5.3.1). Each session works in its own worktree `.claude/worktrees/w54-<name>` on
branch `w54-<name>`, commits small and often, and pushes (`git -c http.postBuffer=524288000 push -u origin w54-<name>`)
after every working step.

## House rules (all sessions)
- Read CONTRIBUTING.md first. UK English (Irish English in Ireland), warm and a bit wry, no em-dashes in anything a
  player reads. Rated 16+. Real places and real facts only: if you are not sure, leave it out.
- Code reads like the code around it: same naming, comment density and idiom. Small additive edits to shared files;
  new logic in new files. 60 fps on a 2013 iMac: no per-frame allocations in hot paths; respect Settings (Reduce
  Flashing, text size, colour-blind palette, hints).
- Never break a save: new state defaults sensibly when an old save loads (absent flag = the old behaviour). The owner
  plays a real late-game save, so everything new must also reach a player who is already past the opening.
- Keep each JSON file's existing formatting; change only the keys you own. NPC dialogue lives in
  `data/dialogue/<zone>.json` or `common.json`; no other dialogue file is loaded.
- Scripts the validator loads must not name autoloads (Bus, Game, Settings, UIKit).
- Tests: write them (tests/ mirrors the code tree). Run `tools/test.sh <fragment>` for yours and for the existing test
  files your session names, in the FOREGROUND with a long timeout (up to 10 minutes). Do NOT run the full suite: six
  sessions doing that at once takes an hour; the integrator runs it after merging. Do not background a test run and
  poll it with timers. A run is good when it prints `0 failed`, `validate: 0 error(s)` and no `SCRIPT ERROR`.
  macOS has no `timeout` command.
- Screens: only `tools/shot.sh <out.png> 30 <args>` (it never takes focus). After adding a `class_name`, run
  `$(tools/get_godot.sh) --headless --path . --import` first or the shot shows an empty world. Every dev launch must
  quit by itself. Look at every screenshot you take and fix what looks wrong. Save them in `docs/screens/w54/`.
- New menu screens go in `tools/dev/text_audit_body.gd` SCREENS and must pass `tests/ui/test_text_fit.gd`; battle UI
  must pass `tests/battle_ui/test_battle_text_fit.gd` and `test_hud_fit.gd`.
- Anything that makes tiles solid or walkable differently must be mirrored in the playtest bot's own zone copies
  (`tools/playtest/bot.gd`, `_routing_zones`), or CI's slice playtest fails.
- Do the work yourself. If you hand any writing to a sub-agent, read every line it returns before committing it.
- Don't touch files another session owns beyond a one-line hook; say so in your handoff if you had to.
- Finish: write `docs/audit/w54_<name>.md` (what you built, how to see it, numbers, what you were unsure of, notes for
  the integrator), commit, push, and stop. No HANDOFF.md, no CHANGELOG or README edits, no merge into int-w54.

## Phase 1 (six sessions in parallel)

### cat: the family cat
Owns: a new `data/creatures/<line>.json` and its sprite recipes, a new `core/family_cat.gd`, additions to
`data/dialogue/cat_and_fiddle.json` and `data/dialogue/macc_home.json`, the `npcs` of `data/zones/macc_home.json`, one
knack in `data/knacks.json`, at most one new move, and small hooks.

The hook is already in the game: Mum's kitchen has a `cat_bowl` and she says "Mind the cat's bowl", but no cat has
ever been seen. The first road out of Macclesfield is the real Cat and Fiddle road (`cat_and_fiddle` zone).
- **Who she is.** A small, black, fast house cat, female, who went up on the moor the night the stones hummed (the
  cold open) and came back slightly more than a cat. A three-stage line only the player can ever have. Suggested
  names, change them if they collide or you find better: Sootkit (night), Grimalkin (night/fae; a real old word for
  a cat, Shakespeare's witches have a "Graymalkin"), and a final form after the cat-sith of Highland folklore
  (fae/night, a great black fairy cat with a white spot on its chest; the game already has its counterpart
  `cusith`). Evolution follows the house ruling: bond is an early alternative to the level, never the only way.
  Fast and frail, starter-tier totals. One knack of her own (for example Nine Lives: once a battle, a hit that
  would faint her leaves 1 HP) and at most one signature move. Each stage needs dex text, a real `fact`, and
  Welsh, Irish and Gaelic names like other species. `"appendix": true` so she never counts towards the 200, the
  diploma or milestones. Read how wave 48's monsters session added species and sprites (`docs/briefs/wave48.md`,
  `tools/spritegen`), and draw front and back sprites and the overworld icon.
- **New game.** Mum mentions on the first morning that the cat hasn't touched her breakfast since the stones
  hummed. The first time the player walks onto the Cat and Fiddle road with a starter, the cat is there (your call
  how: on the pub wall, or dropping in on a wild creature that has cornered your starter). She joins the party at
  the starter's level. The player is asked what the family calls her; the default answer is **Meadow**.
- **Old saves.** A save that is already past that road finds her at home by her bowl: Mum says she has been sat in
  the window since you left, and she joins at the party's par level. Tell such a player once that something is
  waiting at home (the post or letters pipeline, or a one-off note on load; pick what exists).
- **Exclusive and permanent.** No encounter table, trainer, breeding result, trade or gift may produce the line: add
  a validator rule. She can't be released or sold (see `ArkLogic.release_rule`). When she isn't in the party she is
  at home by her bowl and can be collected there. As the follower she has her own lines.
- Expose `FamilyCat.has(data)`, `FamilyCat.in_party(data)` and `FamilyCat.is_lead(data)` for phase 2.
- `tools/playtest.sh slice 2` must still pass (the bot must get through the scene and the naming prompt); run it
  once at the end. Tests for joining, the old-save path, exclusivity, no release. Screenshots: the scene, her in
  battle (front and back), at home by the bowl, following you.

### water: take the coracle
Owns: ride-tile logic in `data_api/zone_data.gd`, `world/field_moves.gd`, the water parts of `world/overworld.gd`
(`can_enter`, `ground_y`, `set_wading`), the coracle in `world/player.gd`, the water parts of `world/follower.gd`,
`world/encounters.gd` water mapping, the validator rule, a new `core/flotsam.gd` with `data/flotsam.json` and its
generator, and `no_ride` data in the few zones that need it.

Audit: only `o` (deep_water) is crossable, 2,972 tiles in 35 outdoor zones. `~` (26,161 tiles, 127 outdoor zones) and
`$` sea (65,606 tiles) are walls. 135 outdoor zones have a `water` encounter table that can never fire. The player on
water is their sprite on a brown cylinder (`world/player.gd:49-60`).
- **Rivers and lakes.** With Brook-wade (the second Stone, id `brook_wade`, unchanged) the player can cross every `~`
  tile as well as `o`. **The sea** near the shore (`$` within 3 tiles of anything that isn't sea) opens with a new
  ability, `tide_ride`, from the Tide Stone (`FROM_BADGE`; find the Keeper and town for `WHERE`). Abilities derive
  from badges, so old saves get both at once. Update the block hints.
- **Never across a zone edge.** A ride tile on a border side that has an edge stays solid ("the current's too strong
  here"). Border tiles on a side with no edge already just bump.
- **No sequence breaks.** New validator rule, an error: for every outdoor zone, with story gate NPCs treated as solid
  (the 21 gate scripts and their `hide_if` walls), and from every way into the zone, the set of warps and edges the
  player can reach must be the same with riding as without. The audit's simulation found leaks in galway, cardiff,
  tintagel, belfast, inverness and dublin. Fix a leak with a `no_ride` list of rects in that zone's JSON (keep it as
  small as possible, so the rest of that zone's water still works), never with an exception list. NPC wanderers and
  roamers must stay out of the water (they path without abilities; keep it that way).
- **It should look and feel like a boat.** Replace the cylinder with a proper little coracle (tarred hull, a paddle),
  bobbing, with a wake or ripple, a soft paddle sound, and the right height on `~` and `$` (today a rider would sink
  0.3 to 0.5 under the surface, see `overworld.gd:204`). The follower: a brook, tide or gale creature swims or flies
  alongside; others stay hidden as now. Keep the bike rules.
- **Encounters.** On any ride tile, roll the zone's `water` table where it has one (5% a step, sachets apply as on
  grass); no table, no encounter. Fishing stays as it is (`sea` tiles stay salt).
- **Reasons to paddle.** Flotsam: about 60 one-off finds across at least 40 zones, on or beside water that is only
  reachable by coracle: floating crates, lobster pots, and messages in bottles (short, funny, true to the place),
  plus caches on islets and far banks. Deterministic generator, seeded like the field-spot one
  (`tools/field/gen_field_spots.py`); each find is a flag, absent = not found. Modest rewards, no money faucet
  (`core/economy_sim.gd` must stay happy). Don't make the 30 water hop field spots pointless: they remain the way
  across before the Stone.
- Keep green: `tests/world/test_zone_data.gd`, `test_field_moves.gd`, `test_pathfinder.gd`,
  `tests/data_api/test_coverage.gd`, `tests/core/test_world_consistency.gd`, `tests/field/test_field_spots.gd`,
  `tests/core/test_leases.gd`, `tests/story/test_p6_story.gd`, `tests/core/test_fishing.gd`. Mirror the new rules in
  the playtest bot and run `tools/playtest.sh slice 2` once at the end. Screenshots: on a lake, on a river, on the
  sea, a flotsam find, a block hint.

### types: what beats what
Owns: `battle_ui/menus.gd`, `battle_ui/hud.gd`, `battle_ui/battle_flow.gd` (`move_hint`), `battle/move_text.gd`,
`data_api/type_chart.gd`, a new `ui/type_chart_screen.gd`, its registration in `core/almanac.gd` and the pause menu,
the weak and resist rows on `ui/summary_screen.gd` and `ui/pedia_screen.gd` (`_show`, after the type row), a types
card in `core/intros.gd`, the starter picker's triangle line, and Kit's lines in `data/dialogue/macc_fieldstation.json`.

Audit: 16 types, 407 of 465 species have two. The only matchup cue in battle is a footer line under the highlighted
move; it is blank the first time you meet a species, and blank for a neutral hit too. Neither creature's types show
on the battle plates. The switch menu takes no foe. No type chart screen exists. Kit says "Fire" and "Water", which
are not the game's type names (Hearth, Brook). Each type already has its own glyph shape (`ui/type_glyph.gd`) and
there is a colour-blind palette.
- **Every move row says how it will land**, always, including the first meeting (drop the seen-before gate and
  update the test that pins it): a symbol and words, for example up arrows with "x2" or "x4", down arrows with
  "x1/2" or "x1/4", a cross with "No effect", and a plain mark for a normal hit. Never colour alone. Status moves
  say nothing. Doubles: per foe, and it must fit.
- **Both creatures' type chips on the battle plates**, glyph and name.
- **The switch menu says who suits this fight**: for each party member, a word for attack (its best move against
  the foe) and one for defence (the foe's types against it).
- **Outside battle**: "Weak to", "Resists" and "No effect from" rows on the Fieldbook species page and the Summary;
  "Strong against" and "Weak against" on a move's description (Summary, the Bag's chapbooks, the move footer). One
  shared helper on `TypeChart` (`weak_to`, `resists`, `immune`).
- **A type chart page**: in the Almanac, linked from the pause menu, and reachable from inside a battle (scoped to
  the creatures in front of you). Pick the layout that reads best at 1280x720 and passes the text audit at Large.
- **Teach it early**: a types card (`Intros`) the first time a hit lands super effective or not very; the starter
  picker shows Hearth beats Hedgerow beats Brook beats Hearth; Kit uses the real type names.
- Screenshots: the move picker against a dual-type foe, a double battle, the switch menu, the chart page, the
  Fieldbook rows, Large text.

### explore: a reason to leave the road
Owns: a new `core/discovery.gd`, `world/travel.gd` (`note_visit`), `ui/zone_card.gd`, `ui/map_view.gd`,
`ui/map_logic.gd`, `ui/world_map.gd`, `core/where_next.gd`, `core/rumours.gd`, the "Found in" lines of
`ui/pedia_screen.gd` (about lines 392 and 475 only), cards in `core/intros.gd`, a new atlas page, and a new
`world/sense_cue.gd` with one hook line in the overworld.

Audit: there is a lot off the road (167 points of interest, 304 field spots, 194 quests, 44 letter trails, 7 Deep
Places, 31 legends stood in the world), but the game hides it. "Where next?" is nearly always the next Keeper and only
shows on the pause card. First entry to a place is silent. The map draws unvisited towns as unnamed rings. Legends
have no hunt: the Fieldbook says "somewhere secret". Region stamps pay nothing. Points of interest, field spots,
plaques and the Visitor's Book are never introduced.
- **Discovery is a moment.** The first time the player enters any outdoor zone or Deep Place: a "New place" zone
  card, a short sting, a line in a new places-found tally, and a small reward for the whole party through a growth
  path that already works outside battle (find one; don't build level-up screens). Towns already carry
  `visited_<town>`; treat those as found, without the reward, on old saves.
- **An atlas.** Per region: places found, rooms visited, plaques read, points of interest and field spots found,
  creatures recorded, as counts and a bar, with a stamp and a modest one-off reward at half and at all (existing
  items; no money faucet). Old saves catch up on first open.
- **The map makes promises.** Name the unvisited neighbours of places you have been ("Buxton?"), ring places a
  resident, letter or rumour has told you about, and mark Deep Places and legends once heard of.
- **Legends are hunted.** Each of the legends gets one or two rumours with real folklore, told by residents of its
  region once you have been there (`Rumours`); hearing one sets a flag, rings the place on the map and replaces
  "somewhere secret" in the Fieldbook with the clue.
- **Your creature notices things.** Within about five tiles of an unfound point of interest or field spot, a small
  cue over the follower (or the player if there is none) and a soft chime, at most once per find and not in towns.
  Build it on a `Discovery.nearby_unfound(zone, pos, data)` list so phase 2 can add flotsam and secrets to it.
- **"Where next?" wanders.** A `wander` line for what is unfound nearby, and intro cards the first time the player
  meets a point of interest, a field spot, a plaque and a Visitor's Book.
- Tests for old-save catch-up, the reward once only, the map naming, the hunt flags. Screenshots: a discovery card,
  the atlas, the map with rumoured places, a legend clue in the Fieldbook, the sense cue.

### life: a world that answers
Owns: `world/npc.gd`, `world/follower.gd` (all but the water parts), `world/roaming_creatures.gd`, the encounter roll
in `world/overworld.gd` (about lines 392 to 403), the autosave toast (`ui/save_toast.gd`, `core/game_state.gd:133-141`),
new `world/footfalls.gd` and `world/bench_sit.gd`, `art/shaders/foliage.gdshader`, and the `move` field of plain
townsfolk in town zones.

Audit: 4,058 of 4,500 NPCs stand still; 31 of 105 towns have nobody moving. NPCs only turn their heads. The follower
is hidden in 1,297 of 1,338 interiors (`SMALL_INTERIOR := 200`; the median home is 99 tiles). The creatures roaming in
the grass are unrelated to what you then fight. "Saved" flashes at every door. 2,323 benches can't be sat on. Nothing
answers your feet.
- **The follower comes indoors** (down to about 60 tiles), and curls up by a fire or at night when you stand still.
- **See it, then fight it.** If a roamer within about 4 tiles is on the zone's table when a grass encounter rolls,
  that species is the one, and it springs out of the grass at you. Keep the Rng draws as they are (the bot and
  seeded tests depend on them). A faint cry when roamers bolt.
- **People react.** Bubbles over heads, created on demand: someone with a quest or errand to give, a Regular who
  likes you, a child who has spotted your follower. Umbrellas in drizzle and downpours.
- **Streets with people in them.** In every town, a few plain townsfolk (say-only scripts, not gates, corks, quest
  or shop NPCs) stroll or pace instead of standing; the validator's cork check must stay green. If it is cheap,
  people with opening hours walk to a door at closing instead of vanishing.
- **The ground answers.** Grass parts and rustles round the player, ripples in the shallows, prints on sand and
  frost from a small preallocated pool. Off on low settings.
- **Sit down.** Confirm on a bench to sit; the camera eases in and time runs fast for a while so dusk, lamps and
  windows play out; any key stands you up.
- **Quiet saving.** Keep every save write, but only show "Saved" for a manual save or at most once a minute.
- Tests where logic is pure. Screenshots: follower in a home, curled by the fire, bubbles, umbrellas, a bench at
  dusk, a town with walkers.

### air: sound, sky and season
Owns: `core/ambience.gd`, `core/audio.gd`, `tools/audio/*`, a new `world/sound_emitters.gd`, `world/sky_and_light.gd`,
`world/seasonal.gd`, `art/shaders/ground.gdshader`, and a blip in `ui/dialogue_box.gd`.

Audit: 1,229 of 1,338 rooms share one near-silent bed; 459 fireplaces and 880 clocks make no sound; ten interiors
name music that has no file. Only countryside has a night bed. Fog, frost and the seasons change no sound; there is no
thunder. The sky is a flat colour with no stars or moon. The season tints tree canopies only, so autumn trees stand on
summer-green grass. Battle cuts all ambience.
- **Rooms sound like rooms**: a bed per building kind (pub, church, shop, home, works), fire crackle and clock tick
  that fade with distance (copy `world/rail_traffic.gd:21-23`), streams and the shore outdoors. One polyphonic
  player, a nearest-emitter poll a few times a second. Fix the ten silent music ids.
- **Night, weather and season you can hear**: night beds for town, coast and city; thunder in a downpour or gale
  (sound always; a gentle sky lift only when Reduce Flashing is off); fog and frost muffle the bed; faint rain
  carries into battle.
- **A sky**: stars at night and a moon in its real phase for the date, twinkle off under Reduce Flashing.
- **Season on the ground**: ochre autumn, pale winter, fresh spring, fed beside `Seasonal.tint`.
- **Small things**: church bells strike the hour, a soft text blip in dialogue with a setting to turn it off.
- New audio goes through the existing generators (`tools/audio`, sfxgen, ambgen); no downloaded samples.
- Screenshots: a starry night with the moon, the four seasons on one zone. For sound, list in the handoff exactly
  how to hear each thing (`--boot=` and `--clock=` args).

## Phase 2 (after phase 1 is merged; briefed then)
- **secrets**: a dozen named optional bosses stood in out-of-the-way spots (some only by coracle), fifteen or so
  hidden rooms and caves behind `hidden` warps with reveal flags, all real places with real tales, added to the sense
  cue and the atlas.
- **eggs**: about ten Easter eggs, a couple that only happen with the cat at the front of the party. Not listed in
  the release notes.
- **critic**: a play-through of the first hour and of an old save, looking for anything that breaks the spell.
