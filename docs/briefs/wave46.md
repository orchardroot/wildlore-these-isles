# Wildlore: These Isles 4.6, wave 46: "Dressed for the Weather"

The owner's direction (2026-10-25): more minigames, and real character customisation in the spirit of the newer
Pokémon games: choose who you are (a man or a woman), skin tone, hair, and buy clothes in shops round the
Isles to wear in the world. Male and female creatures should also be obvious at a glance. The owner has approved
every held-back Welsh lesson and every held-back wave 45 fact.

Base: `origin/main` (4.5.1). You work in a git worktree already on your branch `w46-<letter>-<name>`; commit there,
don't push. Read docs/briefs/wave34.md (house rules, Finish) and docs/briefs/qol_common.md first, then only the
files your part needs. Be token-efficient: grep and `sed -n` over whole-file reads, long output to files.

## House rules that matter most here
- Rated 16+, warm and wry, UK English (Irish English in Ireland), no em-dashes in player-facing text, accurate facts
  only (if unsure, leave it out). Never preachy. Teach by doing.
- Never break saves: new state is new fields or flags with safe defaults (core/game_state_data.gd from_dict).
- 60 fps on a 2013 iMac, Compatibility renderer. Render player sprites once and cache; never per frame.
- Validator-loaded scripts (anything core/game_state_data.gd or tools/validate.gd reaches) must not name autoloads
  (Game, Bus, Router, Settings, Audio) or UIKit.
- Hot shared files (core/game_state_data.gd, story/commands.gd, ui/menu_logic.gd, core/settings.gd, the dev menu,
  tools/validate.gd, data/items/*.json you don't own): small additive edits only; new logic in new files.
- Shared 4-core machine with other agents: targeted tests while you work (`tools/test.sh <fragment>`), the full
  `tools/test.sh` once at the end (0 SCRIPT ERROR, 0 failed, "validate: 0 error(s)"). Screenshots ONLY with
  `tools/shot.sh <out.png> 14 <game args>` (silent, off-screen, no focus). Check every new screen you add.
- Each session adds its own tests under tests/<area>/ (new files, so merges don't clash).
- Minigames: pure rules in core/<game>.gd (class <Game>, no autoloads, seeded Rng so tests are deterministic), the
  screen in ui/<game>_screen.gd + .tscn, started by a dialogue command in story/commands.gd that opens the menu
  (copy the darts pattern: core/darts.gd, ui/darts_screen.gd, story/commands.gd "darts", data/dialogue/*). Every
  timing game honours the Accessibility "easier minigames" setting (see how Darts reads it). Prizes are modest and
  once a day (DailyKey stamp flags like Games.FLAG_DONE), stats go through TrainerStats, and the game says where the
  real thing happens and when (a plaque or a line from the NPC). Fairness first: no twitch skill wall.

## Contracts (implement exactly)

**Looks** (session A owns `core/looks.gd`, class `Looks`, pure logic, no autoloads):
- The player's look is a character recipe (see the header of tools/spritegen/character.gd) stored as
  `GameStateData.look: Dictionary` (new field; empty on old saves, and `Looks.recipe(data)` then returns the recipe
  of the flag `player_sprite` (player_a or player_b) so nothing changes for existing players).
- `static func recipe(data: GameStateData) -> Dictionary`: the full recipe to render, = base look + worn items.
- `static func base(data) -> Dictionary` has keys `build` ("slight" = the old child build, "adult"), `skin` (index
  into data/looks.json "skins"), `hair` (style id), `hair_colour` (index into "hair_colours"), `sex`
  ("m" or "f"; letters use Mr / Ms), and `wearing: {slot: item_id}`.
- Wear items are data/items/wear.json entries `{"id","name","kind":"wear","slot","price","desc","look":{...}}` with
  slot one of `hat, top, bottom, shoes, coat, neck, face, hands, back`, and `look` a recipe delta: palette keys to set
  (`"palette": {"top": "#..."}`), scalar keys to set (`"hat": "flat_cap"`, `"bottom_style": "kilt"`,
  `"sleeves": "short"`), and `"accessories": ["aran"]` to add. `Looks.recipe` applies deltas in slot order
  `bottom, shoes, top, coat, neck, back, hands, face, hat` (later wins), accessories are unioned.
- `static func valid_delta(d: Dictionary) -> bool` checks a delta against the vocabulary in character.gd (hats,
  hair, bottom styles, accessories); tools/validate.gd runs it over every wear item (A adds that check).
- `static func pronoun(data, form: String) -> String` with forms `he, him, his, Mr, man` returning the he/she,
  him/her, his/her, Mr/Ms, man/woman word for the player's sex.
Session B authors wear items and shops to this contract and may stub `core/looks.gd` with these signatures in ONE
commit whose message starts "STUB looks.gd", for the integrator to drop.

**Creature sex art** (session C): a creature recipe may carry `"dimorph": {"f": {<recipe overrides>}}` (and/or
`"m"`); tools/spritegen.gd renders `<id>_f.png` (front, and `_f_back.png` where back sprites exist) alongside the
usual files, and the sprite lookup (wherever `art/sprites/creatures/<id>.png` is chosen for a Creature) prefers the
sex file when it exists. Coats (ui/coat_art.gd) still apply on top.

## Sessions

- **A. Looks (the owner's character)**: `core/looks.gd` + `data/looks.json` (8 to 10 skin tones from very fair to
  very dark; all hair styles character.gd knows plus new ones you add to character.gd: afro, braids, locs, undercut,
  mohawk, buzz; 12 hair colours incl. grey and two dyed ones; the two builds). Make tools/spritegen/character.gd
  render at runtime: `CharSprite.setup_recipe(recipe)` producing a cached ImageTexture (cache by recipe hash; the
  painter is already in the export, tools/spritegen.gd is not). Use the look everywhere the player is drawn:
  world/overworld.gd, ui/battle_intro.gd (VS card), world/journey.gd / ui/journey_scene.gd, ui/photo_mode.gd if it
  draws the player, the follower code if it reads the player sprite. Character creation: extend ui/name_entry.gd
  (new game) into a proper creator: sex (male or female), body, skin, hair, hair colour, starting top colour, a Randomise
  button, a live 4-direction preview, pad and keyboard friendly. A **Wardrobe** screen (ui/wardrobe_screen.gd,
  `--menu=wardrobe`) opened from the pause menu and from a mirror in Mum's house (macc_home; add a prop + a
  dialogue command `wardrobe`): change hair style and colour (free at the mirror), choose what to wear per slot
  from owned wear items (Bag kind "wear"), with a live preview and "Take off". The shop screen shows a try-on
  preview when the highlighted item is kind "wear" (ui/shop_screen.gd, small edit). Pronouns: add a
  dialogue substitution so NPCs can say "{he}", "{him}", "{his}" etc. (story/commands.gd `_sub`), and make the letters that address
  the player (post box, Building Society, HMRC) use `Looks.pronoun(data, "Mr")`. Mum: one line that fits whichever
  you picked. Keep `player_sprite` flag working. Tests: recipe merge order, defaults for old saves, valid_delta,
  pronoun forms, cache hit. Screenshots of the creator, the Wardrobe, and the VS card.
- **B. The boutiques (clothes to buy)**: data/items/wear.json, 60+ items that are of these isles, each with a
  one-line true fact in the desc: Harris Tweed jacket (Stornoway), Fair Isle jumper (Lerwick), Aran jumper (Galway),
  Guernsey and Jersey jumpers, Welsh wool shawl and a Welsh tapestry coat (Aberystwyth / Cardiff), Donegal tweed cap,
  Derry shirt (the shirt factories), Belfast linen shirt, Nottingham lace collar, Northampton brogues and cherry-red
  boots, Luton straw boater and panama, flat caps (Yorkshire), bobble hats, bucket hat (Manchester), waxed jacket
  (Northumberland), wellies in colours, kilts in a few named public tartans (Black Watch, Royal Stewart, Hunting
  Stewart, no clan you'd need permission for), a sou'wester and oilskin (Whitby), a Cornish fisherman's smock,
  Paisley-pattern scarf (Paisley), a Morris sash, a hi-vis, a lab coat, football scarves by colour not club, a
  Burns-night bonnet, a flat Mann "three legs" T-shirt, Shetland lace, Cheshire cheese-roller's ribbon... no real
  brand names. Reuse character.gd's existing vocabulary in the `look` deltas (colours via palette), and add a few
  new accessories/hats to character.gd ONLY if session A's branch is your base (it will be: the integrator starts
  you after A lands). Boutiques: a dialogue `shop` in 14 cities (Manchester Northern Quarter, London Carnaby Street,
  Edinburgh Grassmarket, Glasgow, Cardiff arcades, Dublin Grafton Street, Belfast, Leeds, Birmingham, Bristol,
  Galway, Inverness, Stornoway tweed shop, Lerwick knitwear) each stocking regional pieces + a few staples, using an
  existing unused building door where there is one (never move existing warps), with a shopkeeper who has a line
  about what you're wearing (`Looks` tells you the hat/coat worn). A dozen NPC compliments scattered in dialogue
  that fire on a worn slot (`"if_wearing": "hat"` or a specific item id: add a small condition to story/commands.gd
  if there isn't one). Tests: every wear item valid (Looks.valid_delta), every boutique stock id exists, prices
  sensible (120 to 2400). Screenshots of two boutiques.
- **C. Male and female creatures**: the owner's words: "it's not even obvious what gender a monster is from their
  summary, and to breed it obviously needs to be m with f". So, first: the **summary screen** shows the sex next to
  the name as the glyph AND the word (Male / Female), on the first page, impossible to miss; the **pairing screen**
  and any breeding talk say plainly that a pair needs one male and one female, name the sex of each creature as you
  pick it, and explain in one line when a pick can't pair (same sex, or a kindred that doesn't breed) instead of
  silently refusing. Then show sex everywhere a creature is named: party screen, summary, battle HUD (both
  sides), catch/nickname flow, Fieldbook entry, pairing (already has chips), the Stud Book: a small ♂ (blue-ish) /
  ♀ (rose) glyph via a `UIKit.sex_mark(c)` helper (check the UI font has U+2642/U+2640; if not, draw it with
  Line2D/polygons). Dimorphism art for 40+ species whose real animal differs (mallard, pheasant, red deer stag
  antlers vs hind, roe, blackbird, chaffinch, bullfinch, black grouse, capercaillie, peafowl if present, stickleback
  in breeding red, salmon kype, lion-maned anything, newts' crests, orange-tip butterfly, adder colouring,
  bullfinch...) via the `dimorph` contract: recipe overrides in art/recipes/creatures/<id>.json, spritegen +
  lookup changes, back sprites too. Fieldbook: a "Males and females" line per dimorphic species (true, short) and
  a tick for "seen both". Encounters and gifts already roll sex via Genetics; make sure every creature of a sexed
  kindred shows one (fix any path that leaves it ""), and that kindreds without sex show nothing (not "-").
  Tests: lookup prefers `_f`, mark text per sex, dimorph recipe validity. Screenshots: party screen, a battle, a
  Fieldbook entry.
- **D. Bowls and skimming**: **crown green bowls** (a crown in the middle of the green, the jack set by the player,
  bias curve on each wood; three ends against a local; venues at the Waterloo Hotel Blackpool, a Potteries pub
  green, a Yorkshire park, a Cheshire bowling club) and **stone skimming** (Easdale Island, Argyll, home of the World
  Stone Skimming Championships: pick a stone, set angle and power, count the skips; also a lochside spot in Wales).
  Two NPCs each, a plaque each, Trainer stats `bowls_ends_won`, `skims_best`.
- **E. The seaside arcade**: one screen with three machines, at Blackpool, Brighton, Southend, Scarborough, Rhyl,
  Bray and Portrush (arcade interiors as rooms: use existing interior patterns and an unused door): a **2p pusher**
  (drop timing against a moving shelf; coins and the odd prize token), a **claw grabber** (position, then a claw
  with honest weakness, prizes from a per-town list incl. one wear item from data/items/wear.json if session B's
  items exist, else a soft toy key item), and **penny falls**. Change machine: pounds to 2ps at the counter; a
  daily cap so it never becomes a money printer (add a MarketSim-style check, see core/market_sim.gd). A line
  about Blackpool's Golden Mile and the slot-machine rule of 2026 Britain (category D machines, kids allowed) that
  is actually true.
- **F. The village fete**: **cheese rolling** (Cooper's Hill, Gloucestershire, Spring Bank Holiday Monday: chase a
  Double Gloucester downhill, lean left/right to stay up, hold to dive), **bog snorkelling** (Llanwrtyd Wells, Powys,
  August bank holiday: a breath/stroke rhythm along two lengths of the trench), **welly wanging** (a Yorkshire
  fete: angle + power + wind). All playable any day at their home spot with a small prize, and bigger on the real
  date (core/calendar.gd); a steward explains each one in two lines. Plaques with the true history.
- **G. Curling and wrestling**: **curling** at a Scottish rink (Stirling, Kinross, or Perth: a 4-stone end against
  a club skip, weight and line, then sweep taps to carry the stone; the house, the button, the hog line taught by
  doing) and **Cumberland and Westmorland wrestling** at Grasmere Sports (a read-and-react game: the opponent
  telegraphs a hipe, a buttock or a cross-buttock, you answer in time; best of three falls; the embroidered
  costumes get a line).
- **H. Approved content goes live**: the owner approved everything in docs/lang_review/cy.md (Welsh lessons cy_03 to
  cy_06 and the held-back cy_01/02 points: add Sut mae as the northern hello, keep Plîs) and every held-back fact in
  docs/audit/facts_w45*.md. Work out how lessons and facts were kept out (a list, a flag, or simply not written
  in) and put them in, exactly as those docs propose (fix the Trefor and Pontcysyllte points with the standard
  derivations: Pontcysyllte is pont + cysyllte "the joining", Trefor is a personal name, not tref + fawr). Then
  rewrite the two cy.md sections and the facts docs as a short "Approved on 2026-10-25" note so no one asks twice.
  Other languages' review docs stay as they are. Tests: lessons load and validate, no duplicate ids.
- **I. Nightly fuzz**: the Nightly fuzz has failed two nights running with "PLAYTEST FAIL: player stands on
  unwalkable fence at (49, 29) in dee_valley". Find the cause (a tile, a landmark overlay, a warp landing or a
  bot move onto a fence), fix the real thing (not the check), and add the regression to the zone validator if it
  is a data shape that could recur. Run `tools/playtest.sh` on dee_valley only (see the fuzz workflow for the
  exact invocation and seed 202).

## Finish (every session)
Run `tools/test.sh > /tmp/t46_<letter>.log 2>&1; grep -c "SCRIPT ERROR" /tmp/t46_<letter>.log; grep -E "passed|validate:"
/tmp/t46_<letter>.log`: 0 SCRIPT ERROR, 0 failed, validate 0 errors. Do NOT run the full-story playtest. Commit on
your branch with the trailer `Co-Authored-By: Claude <your model name> <noreply@anthropic.com>`. Don't push.
Report in under 150 words: what you built, files touched outside new files, test counts, anything skipped and why.
