# Wave 49 tune: the ten party-piece games, simulated and played through

Session "tune", branch `w49-tune`. The silver ("good") and gold ("master") scores in `data/party_pieces/g1..g5.json`
were set by guesswork in wave 48; only worms and the coracle had been simulated. This pass drives every pure core with
three bots (sloppy, decent, sharp) over 80 seeds each, normal and Easier minigames, and resets the thresholds so a
decent player gets silver within a few tries and gold needs real skill. Then every screen was shot at the start, part
way through and (where a dev arg exists) at the end.

Reproduce: `.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/minigame_sim.gd -- all 80`
(about three minutes; a single game by name is seconds). The bots are described at the top of each `_play_*` in
`tools/dev/minigame_sim.gd`; `tools/dev/pancake_probe.gd` is the side study of the pancake pan.

## Thresholds, before and after

Rates are the share of 80 runs that reach the rosette on normal difficulty, decent bot / sharp bot.

| Game | Score | Before (good / master) | After | Silver: decent / sharp | Gold: decent / sharp | Why |
|---|---|---|---|---|---|---|
| Sheepdog trials | sheep penned of 7 | 4 / 7 | 5 / 7 | 75% / 88% | 36% / 25% | 4 was below Roy's usual 5.2. Gold stays "pen the lot". The bot's gold rate is noise (see below). |
| Worm charming | worms in 60 s | 32 / 58 | 32 / 54 | 96% / 100% | 6% / 52% | Silver = Pat's 32 is right; 58 needed a 35 ms hand. |
| Cheese rolling | best heat, points | 70 / 115 | 70 / 125 | 48% / 98% | 18% / 92% | At 115 a decent dodger took gold one run in five. 125 is the maximum: win the heat, catch the cheese, stay on your feet. |
| Pancake race | seconds, lower | 52 / 42 | 58 / 44 | 96% / 100% | 0% / 100% | A clean jog is 56 s, so 52 shut joggers out of silver while any clean sprint was gold at 36 s. |
| Bog snorkelling | seconds, lower | 80 / 56 | 60 / 47 | 100% / 100% | 2% / 100% | 80 was slower than a sloppy swim (80.6 median); 56 was a decent swimmer's ordinary time. Floor is 42.8. |
| Coracle racing | seconds, lower | 34 / 27 | 34 / 27 | 53% / 100% | 6% / 100% | Already right once the helmsman has a human reaction delay. |
| Road bowling | throws, lower | 10 / 7 | 10 / 7 | 50% / 83% | 16% / 32% | Already right. |
| Poohsticks | races won of 5 | 3 / 4 | 3 / 5 | 48% / 100% | 2% / 61% | Perfect water reading took 4 of 5 nine times in ten; a clean sweep is the real feat. |
| Gurning | longest clean run | 5 / 8 | 6 / 8 | 55% / 88% | 1% / 40% | Maureen reaches 6; silver should at least match her. |
| Welly wanging | best of 3, metres | 20 / 30 | 22 / 31 | 80% / 100% | 7% / 56% | After the dizzy fix (below). Dave's best of three is about 23 m. |

Easier minigames (Settings.easy_darts) with the new numbers: silver is near-certain for the decent bot in every game
that has an easy mode (poohsticks only marks the quick water, which the bots do not use), and gold is 60 to 90% for
the decent bot in sheepdog, cheese, pancake, snorkel, coracle and road bowling. Easier mode hands out gold rosettes,
and with them the 150 pound prize and `masters_beaten`. That is a design call rather than a tuning one; see findings.

## Balance fix made

- **Welly wanging: dizzy was a bonus.** `WellyWang.wang` took the full launch speed from the spin even past the dizzy
  line, and the screen's wobble is only plus or minus 30 degrees, so holding Confirm for a full spin and letting go
  giddy threw a median 38 m against 32 m for a clean release just under the line. Now a dizzy throw launches at 90%
  of the speed at the dizzy line (`core/welly_wang.gd`): the gambler's median is 25 m and the clean release wins.

## Findings for the integrator (bigger than a tuning pass)

1. **Pancake: the pan is on a knife edge with keys.** The lean is `Input.get_axis`, so on a keyboard it is all or
   nothing, and the pan pushes back with 13 units of lean against a sway of 8 at a sprint. `tools/dev/pancake_probe.gd`:
   a bot that reacts in 0.08 s and anticipates the swing never drops it (36 s); the same bot at 0.15 s drops it nine
   times (52 s) and at 0.2 s thirty times (93 s). Human reaction is 0.15 to 0.25 s. Anticipating the 0.55 Hz sway helps
   a real player, so it is playable, but the difficulty swings wildly between people. A gentler fix in `core/pancake.gd`
   would be to make the lean a rate (hold to lean further, with the pan's own damping) or to cut the lean authority to
   about 8 and add a little velocity damping to `pv`. The thresholds above assume the game as it is.
2. **Easier minigames and gold.** Easier mode is an accessibility setting and should stay one, but gold rosettes carry a
   150 pound prize and the `masters_beaten` stat. Options: count Easier rosettes as silver at most, or let them stand
   and accept it. Nothing in `PartyPieces` knows about the setting today.
3. **Sheepdog trials: the bot gets stuck, and so might people.** Even the sharp bot pens nothing one run in ten (the
   flock splits round the dog and the last two sheep circle the gate until the clock goes). The sloppy bot's random
   dashes free it, which is why its gold rate reads higher than the sharp bot's. A sheep that has been within 18 units
   of a gate for more than 20 s could be lured through a little harder, or the clock could pause for the last sheep.
4. **Pancake thresholds lived twice.** `Pancake.GOOD_TIME` and `MASTER_TIME` are pinned by the tests; the rosette uses
   `data/party_pieces/g2.json`. The start screen now reads the data (`ui/pancake_screen.gd`) and the constants are
   kept in step by hand (58/44) with a comment saying so.
5. **Coracle and snorkel floors.** A perfect coracle run is 24.0 s and a perfect swim 42.8 s with no spread at all, so
   gold is a fixed distance from a hard floor. Fine for now; a little per-run variation (current, silt) would make the
   times feel less like a lap record.

## Screens

Every game shot at the start (`--menu=<game>:<venue>`), part way through (`:dev`) and, for snorkel and coracle, at the
finish with the rosette card (`:dev_end`); 22 screens at 30 s. Fixed here (small, in the screens):

- **Pancake race**: the "Olney, Shrove Tuesday" title card sat on top of the START banner and ran under the pan
  close-up. It now sits on the empty road (`docs/screens/w49-tune-pancake-start.png`). The dev state said "Flag 3 is
  coming" while the HUD said flag 7; it now names the real flag. The start sign reads the thresholds from the data.
- **Cheese rolling**: the start screen said "Heat 1 of 3." twice (info line and message). Once now.
- **Welly wanging**: the stage control was stretched wider than its 1040 px art, so clouds and wall stones were drawn
  out in the dark to the right of the picture; it now keeps its size and the clip holds. The SPIN label was cream on
  the dark hill and all but invisible; it has a dark tab behind it (`docs/screens/w49-tune-welly.png`).

Looked at and left alone: sheepdog (clear, though the direction hint shows as "-" in the key bar, a shared hint-bar
quirk), worms (the "Perfect!" pop sits over the BEAT label for a moment, fine), snorkel, coracle (+3s penalty flash
reads well), road bowling (POWER label is tiny but legible), poohsticks, gurning. Rosette cards fire at both dev_end
screens and read correctly.

Not seen: the finish screens of the eight games without a `dev_end` arg; they only end after a real play.

## Follow-up (session "games", wave 49)

Three findings from the list above were fixed in the game code. Numbers are the simulator (`minigame_sim.gd`, 80 seeds,
normal difficulty), decent bot / sharp bot unless stated.

### Pancake race (findings 1 and 4)

`core/pancake.gd`: the lean now pushes back with 9 units instead of 13 (`LEAN_PUSH`), the pan has more drag (`PAN_DRAG`
was 0.9, now `PAN_DAMP` 2.2) and the lean follows the key with a rate that is quicker when far from it
(`LEAN_EASE`). A longer ease-in was tried (constant 6, 8 and 10 a second) and made a late reaction fatal, so the lean
still arrives in about a tenth of a second; the gain is in the lower authority and the damping. Keyboard bot, 20 seeds
(`tools/dev/pancake_probe.gd`), drops per run:

| Reaction | Before | After |
|---|---|---|
| 0.08 s | 0 | 0 |
| 0.15 s (look 0.5 s) | 9.1 | 0.2 |
| 0.20 s | 30.6 | 6.8 |
| 0.30 s | 175 | 19.6 |

An attentive player now keeps it on, a 0.2 s one drops it a few times, a careless one still drops it a lot. The
sprint is no longer a trap, so the clock decides: a clean run is still 36 s, so thresholds moved to 40 / 36.5
(was 58 / 44), champion's time 37 to 39.5 (was 46 to 50). `Pancake.GOOD_TIME` and `MASTER_TIME` follow.

| | Silver decent / sharp | Gold decent / sharp |
|---|---|---|
| Before (58 / 44) with the old pan | 96% / 100% | 0% / 100% |
| New pan, old thresholds | 100% / 100% | 100% / 100% |
| New pan, 40 / 36.5 | 88% / 100% | 13% / 98% |

Easier mode: sloppy 52% silver, decent 100% / 90% gold (was 0% silver sloppy).

### Sheepdog trials (finding 3)

The real file is `core/sheepdog_trials.gd` (`core/sheepdog.gd` is an older, unused model). Causes found by tracing the
sharp bot's failed runs:

1. **Cohesion pulled towards the flock's global centre.** With the flock split in two (one half past the gate, one half
   in the corridor), the centre sat on empty grass between them and each half was tugged towards it at 1.6, which
   cancelled the dog's drive and the pull of the gate. Now each sheep clings to the neighbours within 16 units
   (`COHESION_R`).
2. **No pull on a calm sheep.** A sheep alone, not being walked on, only grazed; a straggler sat by the gate or in the
   corridor for the rest of the run. Calm sheep near a gap now amble towards it (`CALM_LURE`, 0.5), and one pushed back
   out through a gate is drawn back to it.
3. **Gap between the pen and the lure.** The pen lure started at the pen's outer edge (x = 18) but a sheep counts as
   penned only inside it (x < 16.6), so a sheep at the mouth had nothing drawing it in.
4. The simulator's bot (not the game) hovered 18 units from a lone straggler, dithered between going round either side
   and could not get behind a sheep against the right wall. Fixed in `_sheep_goal` (commit to a side, keep to a
   radius, aim right up to x = 94.8); this was most of the "pens nothing" runs.

Result: the sharp bot pens nothing 0 times in 80 (was 1 in 10 before). With the jam gone the game became very easy
(even the sloppy bot penned 7 in nearly every run in 150 s), so the clocks were cut: Longshaw 150 to 50 s, the lakes
140 to 60 s (the easier mode still takes 1.35x). Decent bot at 50 s: silver 73%, gold 72%; sloppy 53% / 47%; sharp 45% / 43%.

Not at target: gold ("pen all 7") is bimodal (the flock tends to arrive together, so a run is 0 or 7) and the bots read
the field perfectly, so the decent bot's gold rate stays far above 20%. A human with the real keys will be slower; if
gold feels too soft in play, score the piece with `SheepdogTrials.score()` (sheep plus the share of the clock left)
and set master to about 7.4, which needs `PiecePrompt` to format a decimal score. The thresholds are left at 5 / 7.

### Coracle and snorkel floors (finding 5)

Both games now take a seed (`Coracle.fresh(course, seed)`, `Snorkel.fresh(seed)`; seed 0 is the old plain course, used
by the tests and dev screens, and the screens seed from the clock):

- Coracle: the river's level is 0.5 to 1.2 of the old current, it gusts and slackens along the course (eddies), and
  the stream is stronger in mid-channel than under the banks, so a good line pays. Sharp bot: 24.0 s flat, now 23.2 to
  24.4 s (p10 23.2, median 23.9). Decent bot medians 33.5 s (silver 57%, gold 8%, was 53% and 6%).
- Snorkel: each swim has its own set (a kick carries 0.96 to 1.04 of normal) and springs and slacks along the trench
  (plus or minus 7%). Sharp bot: 42.8 s flat, now 41.5 to 44.6 s (median 42.8). Decent 100% silver, 1% gold.

Floors fell by about 0.8 s (coracle) and 1.3 s (snorkel), so thresholds are unchanged (coracle 34 / 27, snorkel 60 / 47).
Tests: `tests/g3/test_coracle.gd`, `test_snorkel.gd`, `tests/minigames/test_sheepdog_trials.gd`,
`test_g2_cheese_pancake.gd`.
