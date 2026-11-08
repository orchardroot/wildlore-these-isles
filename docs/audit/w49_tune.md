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
