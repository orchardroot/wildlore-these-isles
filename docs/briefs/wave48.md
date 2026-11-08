# Wildlore: These Isles, wave 48: "Party Pieces"

The owner's direction (2026-11-07): more minigames, more varied monsters, and a new way to learn moves in place of
Pokémon's TMs and HMs, perhaps learnt through minigames. General improvements across the board are welcome.
Creative liberty. Commit early and often, and push.

Base: `origin/polish-5.1` (5.0.0 + this brief). You work in a git worktree already on your branch
`w48-<letter>-<name>`. **Commit after every working step and push your branch (`git -c http.postBuffer=524288000
push -u origin HEAD`) at least after each commit that passes your targeted tests.** Never push to main.

Read docs/briefs/wave34.md (house rules, Finish), docs/briefs/qol_common.md and the "House rules" of
docs/briefs/wave46.md first (they all still apply: 16+, warm and wry, UK English, no em-dashes in player-facing text,
accurate facts only, never break saves, 60 fps on a 2013 iMac, validator-loaded scripts must not name autoloads, hot
shared files get small additive edits only, minigame pattern = core/<game>.gd + ui/<game>_screen.gd + a dialogue
command, honour "easier minigames", daily-stamped modest prizes, TrainerStats, a plaque or line saying where the real
thing happens). Be token-efficient: grep and `sed -n`, not whole-file reads; long output to files.
Screenshots ONLY with `tools/shot.sh <out.png> 14 <game args>` (silent, never takes focus). Check each new screen.
Targeted tests while you work (`tools/test.sh <fragment>`); the full `tools/test.sh` once at the end (0 SCRIPT ERROR,
0 failed, "validate: 0 error(s)"). Your own tests go in new files under tests/<area>/.

## The big idea: party pieces (the TM/HM replacement)

Your lead creature watches every minigame you play. Do well and it picks up that game's **party piece**: a move
nobody can buy, themed on the game (skimming teaches *Ducks and Drakes*, a multi-hit brook move; darts teaches
*Treble Twenty*, high crit; the caber teaches *Toss the Caber*, a big brawn hit with recoil). Every minigame in the
Isles teaches one, so the minigames become the way to build a moveset, and every region's games are worth a visit.

Some party pieces are also **field pieces** (the HM half): out in the world a creature that knows *Round Up* can
herd the sheep blocking a gate, *Paddle* crosses a pond in a coracle to an islet, *Charm the Worms* brings up what is
buried in a molehill. These open optional nooks with loot, lore and shortcuts, never the main road.

### Contract (session P owns it; everyone else codes against it exactly)

`core/party_pieces.gd`, `class_name PartyPieces`, pure, no autoloads:
- Data: every `res://data/party_pieces/*.json` is a dict `{"<game_id>": entry}` merged together. entry =
  `{"name": "Stone skimming", "move": "<move id>", "types": ["brook", "gale"] (empty = any creature),
  "zone": "<zone id where it is played>", "where": "<player-facing place>", "good": <score>, "master": <score>,
  "lower_better": false, "unit": "bounces", "master_name": "<the local champion>", "field": "<field verb or "">"}`.
- Moves: party piece moves live in `data/moves/pieces_<letter>.json` (an array, the usual move format; MoveDB loads
  every file there). Add `"piece": "<game_id>"` to each. Effects must use effect ids the battle code already has
  (grep battle/ for the effect switch); no new battle mechanics outside session P.
- State: `GameStateData.pieces: Dictionary` = `{game_id: {"best": float, "plays": int, "rosette": 0..3}}` (P adds
  the field, default `{}`, round-trips in to_dict/from_dict).
- `static func record(data, game_id: String, score: float) -> Dictionary` returns
  `{"rosette": int (new rosette, 0 if unchanged), "unlocked": bool (this play unlocked the piece)}`.
  Rosettes: 1 bronze = finished a game, 2 silver = reached `good` (unlocks the piece), 3 gold = reached `master`
  (beat the champion: a small one-off prize and a TrainerStats tally `masters_beaten`).
- `static func unlocked(data, game_id) -> bool`, `static func can_learn(c: Creature, game_id, move_db) -> bool`
  (types empty or overlapping, not already known), `static func party_knows(data, move_id) -> bool`,
  `static func entries() -> Dictionary`, `static func problems(move_db) -> Array` (validator check: every entry's
  move exists and has the matching "piece" key, every zone exists, good/master ordered right).
- `ui/piece_prompt.gd`, `class_name PiecePrompt`: `static func after_game(host: Node, game_id: String, score: float)
  -> void` (awaitable). Calls record, shows the rosette toast, and if the piece just unlocked offers it to the lead
  creature ("Bramble watched every throw. Teach it Ducks and Drakes?"), then the existing chapbook/relearner "which
  move makes way?" flow (ui/bag_screen.gd `_teach`-style; reuse, don't copy). **Every minigame screen calls this once
  when a game finishes.** If the lead can't learn it, say so and point at the Almanac page.
- Almanac page "Party Pieces" (P): every game, where it is, your rosettes, best score, the piece and who can learn
  it; an unlocked piece can be taught again from here to any compatible party member, free.

Sessions G1 to G5, F and M start before P lands. If `core/party_pieces.gd` or `ui/piece_prompt.gd` doesn't exist in
your tree, write a stub with exactly these signatures in ONE commit whose message starts "STUB party pieces", for the
integrator to drop.

## Sessions

**P: party pieces core** (branch w48-p-pieces). The contract above, the Almanac page, the validator check
(tools/validate.gd, small edit), `--menu=almanac:pieces` dev screenshot, tests. Then author party pieces for EVERY
existing minigame (grep ui/*_screen.gd: darts, bowls, skimming, crabbing, curling, wrestling, conkers, ringing,
walling, shanty, crossword, quiz, games: caber/tug/hurling/shinty, arcade, fete stalls, fishing, forecasting, trumps,
races, and the rest that are skill games; leave pure gambling ones like roulette, fruit machine, hi-lo, blackjack
out) in `data/party_pieces/p.json` + `data/moves/pieces_p.json`, and add the one `PiecePrompt.after_game` call to
each of those screens. Spread types so every one of the 16 types has at least two pieces across the game. Mark
field pieces for: walling (`"field": "mend"`, mend a gap in a wall), skimming (`"field": "skim"`), caber
(`"field": "topple"`, fell a dead trunk over a stream), crabbing (`"field": "line"`, fish a thing out of the water).

**F: field pieces** (branch w48-f-field). The HM half. `data/field_spots/<region>.json`: `[{"zone","x","y",
"field": "<verb>", "prop": "<art id>", "text": "...", "reward": {"item": id, "qty": n} | {"money": n} | {"hop": [x, y]}
| {"curio": id}, "flag": "<unique once flag>"}]`. `world/field_spot.gd` renders a small prop (a gap in a wall, sheep at
a gate, a molehill, a dead trunk, reeds at a pond edge, a glint in the water; cheap Meshes or Sprite3D, built once)
and interacts like world/poi_scene.gd (one `if await FieldSpot.interact(...): return` line in world/overworld.gd).
Known piece: a short animation of the creature doing it, then the reward. Unknown: a one-line hint naming the piece
and where it is taught. 70+ spots across every region of the main Isles, more near minigame venues, all on free
walkable tiles next to the player's path (validator check, small edit). Verbs come from all sessions:
`mend, skim, topple, line` (P), `round_up` (G1 sheepdog), `charm` (G1 worm charming), `snorkel` (G3), `paddle` (G3
coracle), `roll` (G2 cheese), `loft` (G4 road bowling). A `"hop"` reward moves the player across water or a gap
inside the same zone (a coracle crossing, a felled-trunk bridge), so add some spots in pairs. Map marks for found
spots on ui/map_view.gd (small edit). Tests.

**G1: sheepdog trials + worm charming** (branch w48-g1). Sheepdog trials (real ones: Bala in Wales, the Lake
District, Longshaw in the Peak): you whistle commands to your lead creature to steer a flock through gates into the
pen against a clock; top-down, simple flocking, fair. Worm charming (the real World Worm Charming Championships are
at Willaston, Cheshire, near the start of the game): tap a rhythm on the ground to bring worms up in a plot, more
worms for steady rhythm, birds steal careless ones. Place each with a host NPC in the nearest existing zones (the
Cheshire one early, Macclesfield region). Pieces: `round_up` (kin/hedgerow) and `charm` (bog/hedgerow), both field.

**G2: cheese rolling + pancake race** (branch w48-g2). Cheese rolling (Cooper's Hill, Gloucestershire): a downhill
tumble chase, steer to stay upright and catch the cheese, wry about the injuries. Pancake race (Olney,
Buckinghamshire, Shrove Tuesday since 1445): run with a pan, flip on the beats without dropping it. Nearest zones in
the south/west of England. Pieces: `roll` (stone/brawn, field) and a hearth/kin piece for the pancake race.

**G3: bog snorkelling + coracle racing** (branch w48-g3). Bog snorkelling (Llanwrtyd Wells, mid Wales): two lengths
of a peat trench, flippers only, breath and rhythm. Coracle racing (Cilgerran on the Teifi, and Ironbridge): paddle a
round boat that spins if you're careless, steering a course. Nearest Welsh/Shropshire zones. Pieces: `snorkel`
(bog/brook, field) and `paddle` (brook/tide, field).

**G4: road bowling + Poohsticks** (branch w48-g4). Irish road bowling (Armagh and Cork): loft an iron bowl down a
country lane in the fewest throws, reading bends and verges. Poohsticks (the World Championships began in
Oxfordshire; A. A. Milne's bridge is in Ashdown Forest): pick where to drop the stick by reading the current, a
gentle game of judgment with bets on the side in pennies. Cork for road bowling and an Ulster spot; Poohsticks in
the south east. Pieces: `loft` (iron/stone, field) and a fae/brook piece for Poohsticks.

**G5: the gurning contest + welly wanging + a minigame league** (branch w48-g5). Gurning (Egremont Crab Fair,
Cumbria, since 1267): a horse collar and a memory game of faces, copy the gurn sequence (Simon-style, fair timing).
Welly wanging (Upperthong, West Yorkshire, and many a fete): spin-and-release throw with wind. Nearest zones in
Cumbria and Yorkshire. Pieces: a fae/night piece and a gale/brawn piece. Then a **Games League** card: a page that
lists every minigame venue by region with a stamp per game played (reads PartyPieces state; put it as a tab of the
Party Pieces Almanac page only if P's page exists in your tree, else as `ui/league_card.gd` the integrator will
hook in) and a reward letter from the Isles Games Society at 10, 20 and all stamps.

**M: new monsters** (branch w48-m-monsters). 14 new lines (about 30 species) with silhouettes the dex doesn't
have yet, folklore-led and accurate: e.g. a snail with a house on its back, an eel that is mostly knot, a moth that
is all eyespots, a moon jellyfish, a hedgehog that curls into a ball, a kite that is half paper, a teapot golem, a
Cornish knocker in the tin mine, a corncrake that is only ever heard, a bramble swarm, a boggart in the dresser, a
selkie (check the dex first: skip any that exist; `grep -h '"name"' data/creatures/*.json`). Recipes in
art/recipes/creatures (copy the layer style of the best existing ones, back sprites, dimorph where nature has it),
sprites rendered with tools/spritegen.gd, data/creatures/<line>.json with learnsets, evolutions, dex text, a real
fact, Welsh/Irish/Gaelic names only if certain, habitats and encounter entries in fitting zones (only `encounters`
keys of zone JSON; additive). Some learnsets may list `"pieces": [game_id]` hints. Balance stat totals against
same-stage neighbours. Screenshot a few in battle and the dex. Tests (the existing creature validators cover most).

**A: creatures that move like themselves** (branch w48-a-motion). Today every creature has the same gentle idle in
battle. Give each a motion style chosen from its recipe/types with an optional override in the species JSON
(`"motion": "hover" | "hop" | "slither" | "sway" | "bob" | "pulse" | "stomp" | "flutter" | "drift"`): hover with a
shadow that breathes, hop with squash, slither side to side, flutter fast, jellyfish pulse, heavy stomp that nudges
the camera on attack. Battle (battle_ui/creature_actor.gd), the follower (world/follower.gd) and the summary/dex
portrait where cheap. Also attack lunges per motion (a flier swoops, a slitherer strikes, a stomper charges). Then
signature FX for party piece moves (battle_ui/fx.gd move kinds; the moves have "piece" keys, so key the FX by
piece id). 60 fps on the old iMac: tweens or a shader uniform, nothing per-pixel on the CPU. Screenshots.

**Q: the critic** (branch w48-q-polish). Play the game through the dev switches and harness like a fussy reviewer
(boot, a few towns, houses, battles, shops, the map, menus, two or three minigames) and fix what's wrong: bugs, UI
text that overflows, rough edges, slow menus, confusing flows. Two known items: (1) the owner sees a monster's
battle HP bar start low after a Sanctuary heal (the numbers are right, the bar isn't; it fixes itself after the next
hit). Earlier attempts could not reproduce it in a harness; look at every path that can set the plate's bar
(battle_ui/hud.gd Plate, the bar control's own value/tween, any cached plate reused between battles, switch-ins,
double battles, follower or summary caches) and fix the cause, with a test. (2) the map route line (ui/world_map.gd,
wave 47 G) draws straight town to town even when the route runs by rail elsewhere; draw it along the real legs.
Keep a list of what you fixed in docs/audit/w48_q.md. No big new features.

## Ownership (to keep merges clean)
- data/zones/*.json: G sessions edit only zones near their venues (NPCs, a plaque, a sign); M edits only
  `encounters`; F doesn't edit zones (its spots are in data/field_spots). Q may edit anything small.
- data/dialogue/*: each G session only its own new files (`data/dialogue/w48_<letter>_*.json` or the house
  convention), plus the NPC entries in the zones it owns.
- core/scene_router.gd menu dict, core/trainer_stats.gd tallies, story/commands.gd commands, ui/dev_menu.gd,
  tools/validate.gd: one line each, additive.
- Each session's moves go in its own `data/moves/pieces_<letter>.json` and entries in its own
  `data/party_pieces/<letter>.json` (letters p, g1..g5).

## Finish
Full suite green, screenshots of every new screen in docs/screens/w48-<letter>-*.png, a HANDOFF.md at the repo root
of your worktree (what you built, how to see it, dev args, anything the integrator must know), committed and pushed.
Report in 10 lines or fewer.
