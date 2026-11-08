# Wave 49: loose ends from Party Pieces (target 5.2.0)

Base branch `polish-5.2` (from main at 5.1.0). Each session works in its own worktree
`.claude/worktrees/w49-<name>` on branch `w49-<name>`, commits small and often, and pushes
(`git -c http.postBuffer=524288000 push -u origin w49-<name>`) after every working step.

## House rules (all sessions)
- Read CONTRIBUTING.md first. UK English, real facts only, no em-dashes in anything a player reads.
- Code reads like the code around it: same naming, comment density and idiom.
- Tests: `tools/test.sh <fragment>` for your own tests; the full `tools/test.sh` once before you finish.
  A run is good when it prints `0 failed`, `validate: 0 error(s)` and no `SCRIPT ERROR`.
  The script takes an import lock, so it may sit waiting while another worktree imports; that is fine.
  macOS has no `timeout` command.
- Screens: `tools/shot.sh <out.png> 30 <args>` (it never takes focus; use a 30 s delay on this machine).
  Look at every screenshot you take and fix what looks wrong.
- Dialogue scripts must live in `data/dialogue/<zone>.json` or `common.json`; no other file is loaded.
- Never break a save: new save fields default sensibly and are sanitised on load.
- Don't touch files another session owns (below) beyond a one-line hook; say in HANDOFF.md if you had to.
- Finish: write `HANDOFF.md` at the repo root (what you built, how to see it, notes for the integrator),
  commit, push, and stop. Don't merge into polish-5.2.

## Sessions

### crit: critical hits (owns battle/damage_calc.gd, battle/battle.gd crit bits, data/moves effects)
The game has no critical hits. Add them, modestly: a base chance (about 1 in 24), a "high crit" move flag
(about 1 in 8), and stages from a move effect or a held charm if one fits the existing charm data.
A crit does 1.5x, ignores the target's positive defence stages and the attacker's negative attack
stages, and the battle text says so ("A critical hit!"). Wire it through the battle event stream so the
battle UI can show it (a short extra flash or shake, gentler with Reduce Flashing). The AI should value
high-crit moves sensibly. Give Treble Twenty (darts piece) high crit, as its description promises, and
look through all moves for others whose description implies it (keen, precise, pinpoint...) and flag them.
Update MoveText so the move description shows "High chance of a critical hit." Tests for the maths and
determinism (battle/rng.gd seeds). Keep fights about as hard as before: a quick check that the story bot's
win rate doesn't fall off a cliff (a short `tools/playtest.sh slice 2` is enough).

### portraits: creatures move on the Summary and Fieldbook pages (owns ui/summary_screen.gd portrait,
ui/pedia*.gd portrait, new ui/portrait_motion.gd)
Wave 48 added `core/motion.gd` (Motion: nine styles, idle maths) used in battle and by the follower.
Creature pictures on the Summary and Fieldbook (pedia) pages are still static. Make them idle in their
style, cheaply (a TextureRect with a small per-frame offset/scale, or a shader), respecting
Settings.flash_scale / Reduce Flashing and the 60 fps-on-a-2013-iMac rule. Check every place a creature
portrait is shown (party list icons can stay still). Screenshot a hover, hop, stomp and drift creature.

### crossings: more field crossings (owns tools/field/gen_field_spots.py, data/field_spots/*.json,
core/field_spots.gd, world/field_spot.gd)
Wave 48 field pieces made 239 spots but only 3 "hop" pairs (a coracle or felled trunk that carries you
across water or a gap inside one zone). Make crossings feel like HM routes: aim for 20 to 30 well placed
pairs across the regions, where the far side is worth reaching (a cache, a shortcut, a nice view with a
plaque, a rare encounter patch) and never the only way to anything the story needs. Consider new hop kinds
that fit verbs we already have (paddle = coracle, topple = felled trunk, loft = road bowling... skim =
stepping stones?). Keep the generator deterministic. Each pair must pass the validator and the playtest
bot must plan round solid spots (tools/playtest/bot.gd `_routing_zones` already marks spots blocked).
Screenshot a few crossings in play.

### tune: minigame thresholds and a play-through critic (owns data/party_pieces/*.json thresholds and
small fixes in minigame screens; anything bigger goes in HANDOFF.md as a finding)
Silver ("good") and gold ("master") scores for the ten wave 48 games were set by guesswork; only worms and
coracle were simulated. For each of sheepdog_trials, worms, cheese, pancake, snorkel, coracle,
road_bowling, poohsticks, gurning and welly_wang: drive the pure core logic (core/<game>.gd) with simple
bots of three skill levels (sloppy, decent, sharp) over many seeds and set thresholds so a decent player
reaches silver within a few tries and gold needs real skill. Do the same sanity check for "Easier
minigames" (Settings.easy_darts). Then play each game's screen through with `tools/shot.sh` (dev args are
in docs/audit/w48_handoffs.md), look at start, middle and end, and fix small things (text overflow,
unclear prompts, overlapping art). Write findings in docs/audit/w49_tune.md.
