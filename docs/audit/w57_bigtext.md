# Wave 57 bigtext: the Largest text size

Session `w57-bigtext`, layout fixes in `ui/*` only (no battle UI). Audit: `tools/dev/text_audit.gd -- all --text=largest`.

## Before and after at Largest

| run | before (aa24e005) | after |
|---|---|---|
| `--text=largest`, all 128 screens | 149 problems on 49 screens | 0 |
| `--text=large` | 3 (one screen, `market:leeds_kirkgate`, there from before this wave) | 0 |
| normal | 0 | 0 |

Before, by kind: 65 cut, 40 box, 28 overlap, 7 trimmed, 5 under, 4 stuck.

## Underneath: why most of them were one problem

At Largest every nominal size is scaled by 1.5 and `UIKit.sized` floors the nominal size at 18 first, so the smallest a
`UIKit.label` can be is 27 px. Detail columns, side panels and cards built at Large then came out taller than the
527 px menu content area (`box` and `cut`, then `overlap` on the hint bar). `fit_column` and `fit_block` could only step
down by a quarter or to 27 px.

- **`ui/text_squeeze.gd`** (new; `MenuBase` starts it, Largest only). When something under `Content` is taller or wider
  than the content area, every label and button under it steps down together (92%, 85%, ... 60%, never below 18 px)
  until it fits. A step is chosen from the panels' minimum sizes at once and then checked against the real layout a
  frame later, so it settles in a few frames and gives the same answer on a loaded machine. Buttons give their fixed
  heights back too (never below what is inside them). It restarts from the full sizes when the content is rebuilt or
  resized, leaves clipped one-line labels (`row_label`, `fit_width`) to their own fitting, and does nothing for a screen
  that already fits. Mark a node `set_meta("no_squeeze", true)` to exclude it. Normal and Large are untouched.
- **`UIKit.fit_column`** has five more steps (down to 40%, floored at 18 px) and **`UIKit.fit_block`** scales words down
  together past the 27 px floor at Largest. **`UIKit.largest()`** is the one new check.
- **`MenuBase.set_title`** steps a long title down (never under 26 px) instead of running off the screen (the wrestling
  screen's 1290 px title widened the whole frame).

## By screen (what each was and what fixed it)

- Squeeze alone cleared: controls, pause, party, pedia (3 pages), Fieldbook Stud Book, wardrobe, starter, relearn,
  stats (5 pages), craft (2), keepers, economist, crossword (2), bureau, crypto, society, deed, trumps, fruit, blackjack,
  bowls, skim, sheepdog, worms, forecasting, almanac Gazetteer plaque. (About 100 of the 149.)
- **accessibility**: the five setting rows are buttons holding a row; the squeeze now shrinks a button to what is inside.
- **summary**: move names may reach 18 px at Largest (were stopping at 20 and trimming "Bramble Lash"); the knack and
  entry box scales down past 27 px (`fit_block`).
- **world map** (3 states): the town card was never fitted because it was measured before layout (fit again a frame later
  at Largest); and it sat over "Where next?" because the strip's wrapped height was not counted.
- **pedia Rumours and Stamps**: the place name beside a creature trimmed ("Macclesfield Forest"); it steps down first
  now (`fit_width`).
- **quests:contracts**: the town beside a title is 20 px at Largest so "Something in the Hen House" fits.
- **jobs**: the chip is 18 px at Largest so long notice titles fit; the job card at Largest reads on with Right (it was
  a scroll box only a mouse could use) and Back returns to the list.
- **exchange / crypto**: the "held" star column was 12 px wide (a trimmed `*`); it is a smaller mark at Largest, and
  names keep their room.
- **cards**: the "18 / 25" tags ran out of the narrow group list sideways; 22 px at Largest.
- **almanac:pieces**: the detail words step down, and Right reads down a long piece; Back returns to the list.
- **typechart**: its Left/Right paging was invisible to the audit's "stuck" check; the box is marked `pages`.
- **races**: the side column's three buttons are 22 px at Largest and the column fits 14 px under the content bottom.
- **wrestling**: the long title (above).
- **market:leeds_kirkgate** (Large and Largest): the empty-board line did not wrap and widened its list by 600 px.

## Protected by the test

`tests/ui/test_text_fit.gd`: new `LARGEST_SCREENS`, 50 screens, every one that had a problem at Largest at the start of
the wave, audited with `--text=largest` (`test_screens_that_overflowed_fit_at_the_largest_text_size`). All 128 screens
are clean today; the other 78 were clean before and still are.

## What is left

- The audit cannot see `draw_string` text in minigame stages (arenas, the crossword grid's letters); not checked at
  Largest by eye (no screenshots this wave).
- Largest is not audited with `--readable` (the wider font) or `--stress` (12-letter nicknames, a full purse); both
  were clean at Large in wave 50. Worth one run each.
- At Largest, dense screens now draw some words at 18 to 22 px (the floor) beside 27 px headings: legible and
  complete, but a screen like Standing or the world map card looks busier than at Large. A design pass could trim
  words on those screens instead of shrinking them.
- The squeeze only watches the menu `Content` area. Popups and the HUD are not covered.
