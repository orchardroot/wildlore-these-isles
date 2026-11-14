# Wave 57: Second Helpings (target 5.7.0)

More of what waves 55 and 56 started, and a pass at the biggest text size. Read docs/briefs/wave55.md and wave56.md
and the notes in docs/audit/w55_*.md and w56_*.md for what exists.

Base branch `int-w57` (from int-w56 at 5.6.0). Each session works in its own worktree `.claude/worktrees/w57-<name>` on
branch `w57-<name>`, commits small and often, and pushes (`git -c http.postBuffer=524288000 push -u origin w57-<name>`).

## House rules (all sessions)
- Read CONTRIBUTING.md first. UK English (Irish English in Ireland), warm and a bit wry, no em-dashes in anything a
  player reads. Rated 16+. Real places and real facts only: if you are not sure, leave it out.
- Code reads like the code around it. Small additive edits to shared files; new logic in new files. 60 fps on a 2013
  iMac. Never break a save (absent flag = the old behaviour); everything must reach a late-game player.
- Keep each JSON file's formatting; change only what you own. Dialogue lives in `data/dialogue/<zone>.json` or
  `common.json`. Scripts the validator loads must not name autoloads.
- **You share a 4-core Mac with other sessions.** One Godot process at a time; never `pkill` Godot or tests (other
  sessions' runs die). Run only your own test fragments (`tools/test.sh <fragment>`, foreground, long timeout) and the
  validator. NEVER the full suite or the playtest: the integrator runs both once after merging. No screenshots.
- New tiles, doors or routes must never be a sequence break: `tools/test.sh w55_` stays green and the validator
  (`RideCheck`, `Poi.check`) stays at 0 errors. Older per-region tests assert some towns are dead ends: if you join
  one, update that test to allow exactly your new edge.
- Money: bounded (daily or weekly stamps, one-offs); run `tools/dev/economy_sim.gd -- 20` before and after if you
  add any way to earn, and record both.
- Do the work yourself; if you hand writing to a sub-agent, read every line it returns.
- Finish: write `docs/audit/w57_<name>.md`, commit, push, stop. No HANDOFF.md, CHANGELOG, README or version edits.

## Sessions

### contracts2: contracts that don't all go the same way
Owns `core/contracts.gd`, `story/contract_talk.gd`, `ui/contracts_tab.gd`, `data/contracts/*`, and the zone and
dialogue additions contracts need. The critic (docs/audit/w56_critic.md, finding 8): all thirteen share one shape:
two look-spots, a wrong witness then a right one, the same four endings.
- **Shape.** Add three small things the data can ask for, each used by at least three contracts: a witness who is
  simply wrong and stays wrong (and the Journal lets you strike a lead out); a third look-spot that only opens once
  another clue is found; a clue that is a creature's own behaviour seen from the coracle or at a hidden place
  (wave 56: `secret_*` zones). Rework five of the existing contracts to use them, keeping every existing save's
  progress valid (a contract already decided stays decided; one in progress keeps its found clues).
- **A contract that follows from another.** Use the `needs` mechanism the first session built and never used: two
  follow-ups whose notice appears only after a particular ending of an earlier one (the mink goes to the next farm;
  the kelpie's ford gets its footbridge and something new uses it).
- **Five new contracts where there are none**, each on a real local tale you are sure of: the Isle of Man (the
  Buggane of St Trinian's is a real one), Orkney or Shetland (a hogboon, trows), the Channel Islands, East Anglia or
  the Fens, and the English Midlands. Existing species only. Fees modest and one-off.
- Tests: every branch of every contract still finishes; old saves; the follow-ups. Reply with the list.

### champions: a reason to walk a road twice
Owns a new `core/route_champions.gd`, `data/route_champions.json`, a page in the Almanac, and one trainer's
dialogue on each new route. Read how Keeper rematches (`core/daily_key.gd`, the Keepers' rematch scripts) and the
County Shows (`core/tournament.gd`) work first.
- Each of the thirty wave 55 and 56 routes (docs/audit/w55_roads-*.md, w56_loose-ends.md) names its strongest
  trainer the route's champion: a walker with a name, a reason for being on that road, and a team of existing
  species that suits the place. Once beaten the first time (as now), they can be challenged again once a week at
  the player's par level, with a team that changes with the season and the weather on the day.
- A Walkers' League page: who you have beaten and when, a title at ten, twenty and all thirty, and a keepsake for
  the home shelf at each. Prize money small and weekly-stamped; nothing that out-earns a Keeper rematch.
- Kit, the rival, turns up on three of the new roads at fitting story points with a line and an optional battle.
- Tests: weekly stamp, par scaling, the titles, old saves (already-beaten trainers count as beaten once).

### bigtext: the Largest text size
Owns layout fixes in `ui/*` screens only (no battle UI). docs/audit/w50_text.md recorded 144 problems on 43 screens
at `--text=largest`, mostly minigame side panels and detail columns. Run the audit one screen at a time
(`tools/dev/text_audit.gd`, see tools/dev/text_audit_body.gd for the screen list and `--text=largest`; each run
launches Godot, so batch screens sensibly and never run two at once), list today's problems by screen, and fix them
worst first with the kit's own tools (`UIKit.row_label`, `fit_width`, `scroll_list`, autowrap; see ui/ui_kit.gd and
how ui/race_screen.gd was fixed in 5.4.0). Normal and Large must stay clean: after each batch run
`tools/test.sh text_fit`. When a screen is clean at Largest, add it to a new Largest list in
tests/ui/test_text_fit.gd so it stays that way. Aim to clear the 20 worst screens; say what is left.

### critic2: read wave 56 as a player
READ-ONLY for code; may edit text. No Godot at all. As the wave 56 critic did (docs/audit/w56_critic.md is the
model), go through what wave 56 added: the fifteen hidden places (each reveal: would a player ever find it? is the
hint enough, and is it too much?), the ten eggs (docs/audit/w56_eggs.md: is each findable by accident, and is
anything about them unkind or untrue?), the Macclesfield contract, the two Northern Ireland routes, the coracle
cards, the project keepsakes. Then read the first hour again from a new player's side with everything since 5.3
in it (Mum, the Field Station, the cat on the Cat and Fiddle road, the first contract notice, the first new-place
card, the first type card): is it too much at once, and in what order would you rather meet it? Fix text
yourself; rank everything else in `docs/audit/w57_critic2.md` with file and a small concrete fix.
