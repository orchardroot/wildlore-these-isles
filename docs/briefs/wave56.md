# Wave 56: Secrets (target 5.6.0)

The second half of the owner's 2026-11-13 direction: real secrets to find, a few Easter eggs, and a critic's pass over
everything waves 54 and 55 added. Read docs/briefs/wave54.md and wave55.md for what now exists (the family cat and
`FamilyCat`, the coracle and `can_ride`, `Discovery.nearby_unfound`, the Atlas, flotsam, contracts, town projects).

Base branch `int-w56` (from main at 5.5.0). Each session works in its own worktree `.claude/worktrees/w56-<name>` on
branch `w56-<name>`, commits small and often, and pushes (`git -c http.postBuffer=524288000 push -u origin w56-<name>`).

## House rules (all sessions)
- Read CONTRIBUTING.md first. UK English (Irish English in Ireland), warm and a bit wry, no em-dashes in anything a
  player reads. Rated 16+. Real places and real facts only: if you are not sure, leave it out.
- Code reads like the code around it. Small additive edits to shared files; new logic in new files. 60 fps on a 2013
  iMac. Never break a save (absent flag = the old behaviour); everything must reach a late-game player.
- Keep each JSON file's formatting; change only what you own. Dialogue lives in `data/dialogue/<zone>.json` or
  `common.json`. Scripts the validator loads must not name autoloads.
- **You share a 4-core Mac with other sessions.** One Godot process at a time. Run only your own test fragments
  (`tools/test.sh <fragment>`, foreground, long timeout) and the validator. NEVER the full suite or the playtest: the
  integrator runs both once after merging. **No screenshots at all.**
- A new route or door must never be a sequence break: `tools/test.sh w55_` (the three story-order tests) must stay
  green, and `RideCheck` in the validator must stay at 0 errors.
- Do the work yourself; if you hand writing to a sub-agent, read every line it returns.
- Finish: write `docs/audit/w56_<name>.md` (what you built, how to reach it in play, what you were unsure of), commit,
  push, stop. No HANDOFF.md, CHANGELOG, README or version edits.

## Sessions

### secrets: places that aren't on the way to anywhere
Owns new small interior zones `data/zones/secret_*.json`, their dialogue, the `hidden` warps into them, and a
`secret` kind in `core/discovery.gd` (`nearby_unfound`) and the Atlas.
- **Fifteen hidden places**, spread over the nations, each a real kind of place at a real spot: a cave behind a
  waterfall, a smugglers' tunnel, a priest hole, an ice house, a hermit's cell, a sea cave reached only by coracle, a
  pele tower's undercroft, a souterrain. Use the existing `hidden` warp with a `reveal` flag: something in the world
  reveals it (an examine spot, a rumour from a resident, a message in a bottle, a contract's clue, low tide or a
  time of day). At least five need the coracle and two the near-shore sea.
- Each holds one thing worth the trip that is not money: a creature of an existing species found nowhere near (with
  a true reason it would be there), a curio for the home shelf, a chapbook, a letter that starts a trail, a view
  with a plaque. A true plaque or examine text in every one.
- Add them to the sense cue (once revealed) and to the Atlas as "hidden places 3 of 15", and give the map a mark
  once found. Tests: each can be revealed and entered, none is reachable before its reveal, old saves are fine.

### eggs: a few things we are not telling anyone about
Owns a new `core/eggs.gd`, `data/eggs.json`, and one-line hooks. About ten Easter eggs, harmless and findable, none
needed for anything, none mentioned in menus. No brand or character names from other people's work: nods only, and
facts must be true. A starting list (change any that don't fit the code):
- With the cat at the front of the party (`FamilyCat.is_lead`): a box in Dublin she gets into, with a line about
  Schrödinger, who worked at the Dublin Institute for Advanced Studies from 1939 to 1956 (true), and whether she is
  in the box until you look; somewhere in Cheshire at dusk, a grin that stays a moment after she has gone (Lewis
  Carroll was born at Daresbury in Cheshire in 1832; the phrase "grin like a Cheshire cat" is older than the book).
- A dusty cabinet in the seaside arcade called MONSTERQUEST that does not take coins, with a high-score table of
  one name: JIM.
- At Bletchley Park, a plaque or note with a short Caesar-shifted line that decodes to something kind. Solving it
  (an examine choice) gives a small keepsake.
- A red phone box that rings once as you pass at midnight. Answering gets the speaking clock, wrong by an hour.
- In Cambridge, something with the number 42 (Douglas Adams was born in Cambridge in 1952).
- On the title screen, a classic cheat-code key sequence that makes a small black cat walk across the title and
  nothing else.
- Sit on a particular bench for a whole in-game evening and someone sits down beside you and says one true thing.
- Name the cat "Bagpuss", "Schrödinger" or "Macavity" and Mum has an opinion.
- A message in a bottle that answers another message in a bottle.
Tests for each trigger; each is a flag, absent = not found. A spoiler list goes in `docs/audit/w56_eggs.md` only.

### critic: read what the last two waves made
READ-ONLY for code; may edit text. No Godot at all. Go through the player-facing flow of waves 54 and 55 as a new
player and as a late-game returner, from the data and scripts: the cat's two arrival paths; the first coracle
moment and its hints; the first battle's type cues and the teaching card; the first discovery card; a contract from
notice to decision (pick three and read every branch); a story chain end to end (pick two); the Trader's Ledger
text; a Deed's monthly matters; a town project's three stages. Look for: anything a player would not understand
without having read a brief; hints that name a thing the player hasn't met; rewards that feel like nothing; a
choice whose consequence the player could never see; repeated jokes; text that will not fit a two-line box (over
about 150 characters in one `say`); places where two new systems say contradictory things. Fix text problems
yourself; list everything else in `docs/audit/w56_critic.md`, ranked, each with the file and a concrete fix small
enough for one sitting.

### loose-ends: small things left over
Owns only what each item names. Each is small; do them in order and stop when they are done.
1. A Regular waiting at Mum's (`Regulars.mums_visitor`, 5.3.1) still also stands in their own town: don't spawn
   them there while they are at Mum's.
2. Sitting on a bench (`world/bench_sit.gd`) freezes every NPC because it sets `Router.busy`: let the street carry
   on while you sit.
3. Every town with a chapel rings a bell (`Ambience.accents`): keep cathedrals and a handful of famous peals, drop
   the rest.
4. The discovery reward is invisible in play: say what the party got on the card in a few words.
5. The Relearner's move description has no "Strong against" line (`ui/relearn_screen.gd`); add it with
   `MoveText.beats_line`.
6. The first contract needs two Stones: add a thirteenth, small one for a new player, at Macclesfield or Buxton,
   built on a real local tale you are sure of (the wallabies of the Roaches are already a quest; choose another).
7. Two Northern Ireland routes were scripted but never built (`tools/zones/w55_lower_bann.py`,
   `w55_erne_shore.py`, see docs/audit/w55_roads-celtic.md): build them, gated as the audit says, with the
   story-order tests green.
