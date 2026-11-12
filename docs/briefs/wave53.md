# Wave 53: Houses (target 5.3.0)

From issues #143 to #149 ("Houses: ..."). Going into a house today is talk-and-leave: the same room, the same two to four
lines for ever, nothing to look at, nothing living there. This wave gives homes a reason to go back.

Base branch `int-w53` (from main at 5.2.4). Each session works in its own worktree `.claude/worktrees/w53-<name>` on
branch `w53-<name>`, commits small and often, and pushes (`git -c http.postBuffer=524288000 push -u origin w53-<name>`)
after every working step.

"Homes" below means the 166 interior zones whose id contains `home`, `house` or `cottage` (69 towns have one). Write a
small helper if you need the list; don't hard-code it.

## House rules (all sessions)
- Read CONTRIBUTING.md first. UK English (Irish English in Ireland), warm and a bit wry, no em-dashes in anything a
  player reads. The game is rated 16+: a mild adult joke is fine.
- Real facts only. If you are not sure, leave it out. Names, dialect words and history must be right for the place.
- Code reads like the code around it: same naming, comment density and idiom. Small additive edits to shared files;
  new logic in new files.
- Keep the JSON formatting the files already use (`json.dump(..., indent=1, ensure_ascii=...)` as found), so other
  sessions' edits to the same file merge cleanly. Never rewrite a file you only add one key to.
- Tests: `tools/test.sh <fragment>` for your own tests; the full `tools/test.sh` once before you finish. A run is good
  when it prints `0 failed`, `validate: 0 error(s)` and no `SCRIPT ERROR`. The script takes an import lock, so it may
  wait while another worktree imports; that is fine. macOS has no `timeout` command. Test only what you changed: no
  long full-story playtest runs.
- Screens: `tools/shot.sh <out.png> 30 <args>` (it never takes focus; use a 30 s delay). Look at every screenshot you
  take and fix what looks wrong. Never launch Godot any other way that could take focus.
- Dialogue scripts must live in `data/dialogue/<zone>.json` or `common.json`; no other file is loaded.
- Never break a save: new state defaults sensibly when an old save loads (absent flag = the old behaviour).
- Don't touch files another session owns (below) beyond a one-line hook; say in HANDOFF.md if you had to.
- Finish: write `HANDOFF.md` at the repo root (what you built, how to see it, numbers, notes for the integrator),
  commit, push, and stop. Don't merge into int-w53.

## Sessions

### rooms (#145): stop every home being the same room
Owns `tools/zones/furnish.py`, `tools/zones/zlib.py`, and the `props` (and `rows` only if shapes change) of home zones.
About 85% of homes come from the same two presets. Add regional packs and occupation hints, deterministic on the
existing `furnish:<zid>` seed:
- regional: Welsh dresser and slate in north Wales; range and peat fire in Ireland and the Western Isles; box bed in
  Orkney; settle and brass in the north of England; wall_map and telescope in harbour towns. Use props the renderer
  already draws (`cat_bowl`, `window`, `mirror`, `dartboard`, `washing_line`, `wall_map`, `kettle_table`, `harp`,
  `owl_perch`, `back_door`, ...). If a piece needs a new mesh, keep it to a few and make it cheap.
- occupation: read what the resident talks about (their dialogue file) to pick one or two hints (a fisher's nets, a
  teacher's marking pile, a student's posters).
Rules: never move or remove an existing NPC, warp, sign, `examine` spot, or the prop under an examine spot (the looks
session places examine spots on today's props). Keep the door, spawn and NPC tiles free and the reachability checks
furnish.py already does. Room shapes (L-shaped, parlour plus kitchen, back door to a yard) only if a player saved on a
tile that becomes furniture is moved to the nearest free tile on load; check whether that already happens, add it
(small, tested) if not, otherwise leave shapes out and say so. Screenshot at least six homes from different regions.

### looks (#144): every home gets one thing of its own to look at
Owns the `examine` key of home zones and a coverage warning in `tools/validate.gd`.
One authored `examine` spot per home (see `core/examine.gd`, and `liverpool_h5` for a good one), on a prop tile that
exists today (fireplace, bookshelf, wall picture, dresser, table...), about what that resident actually talks about:
Mr Gillen's granda's rivet gun in Belfast, the Kellehers' good china in Cork, the Caithness flagstone floor in Thurso,
Old Tom's telescope and Herschel finding Uranus from Bath in 1781. Two to four short lines each. About one in four
carries a small `find` (an existing item, modest) or a `flag`. Add a validator warning (not an error) for a home with
no examine spot. Split the authoring by nation if it helps, but you write them all. Screenshot three being read.

### people (#146 and #143): real names, and residents who notice you've been before
Owns home dialogue files (`data/dialogue/<home>.json`), the NPC `name` field in home zones, a new data file and a new
`core/` script, plus one line in `story/script_hooks.gd`.
1. Give the 28 residents whose speaker is `"who": "Resident"` a real name in their town's voice (Gaelic in the Western
   Isles, Norse-derived surnames in Orkney, Welsh in Gwynedd...). Make the zone NPC `name` match. List the 28 and
   their new names in HANDOFF (the regulars session needs it).
2. Return visits. `seen_<zone>` (core/visitors_book.gd) is set when you walk in, so it can't tell a first visit from a
   later one: add a per-resident "talked before" flag, set by the hook after the first talk (absent = first visit, so
   old saves behave as now). Optional per-resident lines, all falling back to today's lines when absent: `again` (any
   visit after the first), `morning` / `evening`, `season` (keyed by season), `weather` (rain or snow). One hook in
   `ScriptHooks.wrap` picks at most one extra line; no new dialogue command. Find where the game keeps time of day,
   season and weather (don't invent them). Validator rule: the keys are optional, but if present each must be a
   non-empty list of strings. Author at least one `again` line for every home resident, and time, season or weather
   lines for about a third. Tests for the picking and the save default.

### regulars (#147): a Regular in every town
Owns `data/regulars.json`, `core/regulars.gd`, `data/dialogue/regulars.json`, and any Regular bits of the validator.
Today's 12 Regulars are spawned NPCs (an `x`, `y` in their home town). Add a way for a Regular to be an existing home
resident instead (say `zone` and `npc`): talking to that resident runs the Regular beats; no duplicate NPC is spawned.
Then add one Regular for each of the 69 towns with homes that has none yet, chosen from that town's home residents.
Don't pick any of the 28 residents called "Resident" (the people session is renaming them). Each needs the full set
of beats the existing 12 have (intro, meet in an `away` town, letter, offer, thanks, chat, hint), written in the
resident's own voice and consistent with what they already say. `likes` uses an item the region already has (Trade
Ledger regional goods, local dishes, local fish). Check what favour 4 (managing a Deed) and 5 mean in code today and
make sure 80-odd Regulars don't break them (for example the Deeds manager picker). Validator rule: every Regular
points at a real zone and NPC (or a walkable spawn tile), `likes` is a real item, `away` a real town. Tests.

### asks (#148 and #149): asks that use the rest of the game, and something living in the house
Owns `core/wants.gd`, `core/trades*.gd` trade-kind matching, `data/trades/*`, `core/search.gd`, the `encounters` key
of home zones, and one line in `ui/photo_mode.gd`.
1. New `wants` kinds: `seen` (a species is in the Fieldbook as seen or caught; check which the Fieldbook records)
   and `photo` (a flag `photo_<zone>` set when the player takes a photo in that zone: a one-line hook in photo mode's
   take). Dishes and fish are already items, so asks for them use the existing item wants: author some of those too
   ("Cook me a cullen skink"). Add a one-line case wherever trade kinds are matched, and the ask/thanks text. Author
   about two per nation of each new kind, in homes that have no trade. Rewards stay modest and daily-stamped as the
   money rules require; run the economy sim (`core/economy_sim.gd`) and record the result.
2. Indoor folklore: a small, rare, time- or weather-gated `encounters` entry in a few homes per region, using only
   species that already exist and are real folklore of that place (check data/creatures: brownie, hobling, bogglet...
   and what each is based on). No new species.
3. Family drawer: one stash per home in `core/search.gd` that always holds that household's own thing (a curio, a
   letter, a photo), found once (a flag, absent = not found). Data in a new file keyed by zone; write the lines for
   every home, tied to what the resident talks about.
Tests for the new kinds, the drawer and the save defaults.
