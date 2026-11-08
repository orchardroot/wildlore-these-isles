# Wave 50: text that fits (menus, screens and minigames)

The owner's report: text "renders poorly throughout the game in most situations" and "puts people off playing". This
half of the job covered everything under `ui/` that the Router opens (menus, the Fieldbook and Almanac, shops, the
pub and casino games, the party-piece minigames, title, name entry, credits). Battle UI, the overworld, 3D signs and
the HUD toasts were the other session's.

## The audit

`tools/dev/text_audit.gd` opens every screen the way `--menu=<name>[:arg]` does (DevMenu's sample journey, so lists
have realistic lengths), waits for slide-ins to settle, then walks every visible Label, Button and RichTextLabel
(`core/text_fit_audit.gd`). It runs headless in a few minutes for all 122 screens, or a second or two per screen:

```
.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/text_audit.gd -- all
... -- pause bag:first travel:all          # some screens
... -- all --summary                       # counts per screen
... -- all --stress                        # 12-letter W nicknames, a full purse (DevMenu.stress)
... -- all --text=large                    # the Large text setting, for this run only
... -- all --kind=cut,box                  # only some kinds
```

The screen list (`SCREENS` in `tools/dev/text_audit_body.gd`) covers every Router menu plus the arguments that change
what is on it: Almanac pages and ledgers, Fieldbook tabs (Stud Book, Casebook, Words, Rumours, stamps), the long
travel list, shops, jobs, every minigame's `:dev` state, title, name entry and credits. A headless window has no size,
so the script keeps the 1280x720 canvas with `CONTENT_SCALE_ASPECT_KEEP`; no window opens and nothing takes focus.

One line per problem: screen, kind, node path, the words, sizes. The kinds:

| kind | means |
|---|---|
| `wide` | one-line text wider than its own box, drawn over whatever is beside it |
| `trimmed` | text cut short by `clip_text` or an ellipsis: the player loses words |
| `lines` | wrapped text with more lines than its box shows |
| `cut` | text partly off the screen, or outside a clipping parent (a menu's content area, a scroll box sideways) |
| `spills` | text partly outside the panel it sits in |
| `overlap` | two pieces of text drawn over each other (siblings in a container are skipped; slanted lettering too) |
| `under` | a panel drawn over part of some text (a panel that covers it all is a popup, and is fine) |
| `small` | font below 18 px at 1280x720 |
| `box` | a framed panel running past the screen or its clip, so its border (and maybe its last line) is cut |
| `stuck` | a scroll box with more words than it shows and nothing the keyboard can focus to scroll it |

Text in a ScrollContainer is judged by what scrolls: off the bottom of a list is fine, sideways is not. Credits roll
on purpose (`set_meta("rolls")`); a scroll box the screen pages itself on a key says so with `set_meta("pages")`.
Words drawn with `draw_string` in minigame stages are invisible to it; those were checked by hand (below).

## What it found (before, at 528d58a9, normal text)

331 problems on 70 of 122 screens (not counting the credits roll, which the old code had no way to mark):

- **231 `small`**. The worst single bug: the **hint bar on every menu sat at 15 px**. `MenuBase._fit_hint` measured the
  label before the bar had laid it out (a sliver of a width), shrank to the floor, and never looked again. Then the
  Fieldbook's words (13 to 17 px: "Found in" at 13), the pause card's Today's Walk (12 px), every type chip in
  Settings (13 px), summary chips and charm (16), crossword clue numbers, card counts, Keepers, the racecard, Exchange
  percentages, the league card (16).
- **71 `cut`, 13 `box`**. Lists and pages running off the bottom: the Almanac hub (Guilds, Deeds, Building Society,
  Economist and Keepers off screen), the Region stamps (54 lines below the screen), the Enclosure's lots, the Stud Book
  (Mendel's line under the hint bar), Stats > Standing, Party Pieces (a fixed 560 px row), and the pause menu (both
  cards' bottoms cut, the list's rows sized from a list that was already too tall).
- **6 `trimmed`**: the pairing screen's names clipped to 1 px wide, a summary move name, a long Isles topic.
- **5 `overlap`**: the stamps and the Stud Book running under the hint bar.
- **5 `stuck`** (word boxes only a mouse can scroll): the league card (2,600 px of it), the card album, quest and
  plaque pages, the Words tab.
- A script error on every Gazetteer open: the "How these isles work" row was built from the wrong row, so it never
  showed (`ui/gazetteer_tab.gd`).

With `--stress` a few more: long nicknames pushing the party preview and the bag's chapbook picker off the screen.

## What was fixed

Shared fixes first (so the same pattern is fixed everywhere it is used):

- `MenuBase`: the hint bar fits its real width when the label is resized (20 px on every menu now) and never goes
  below 18 (`HINT_MIN`).
- `UIKit.MIN_TEXT := 18`: `UIKit.label`, `fit_size`/`fit_label` and `fit_block`/`words_box` never go below it.
  Word boxes that can't fit at 18 drop their optional lines first, then scroll.
- `UIKit.scroll_list` (a column that scrolls past its room, following focus), `UIKit.fit_column` and
  `UIKit.keep_fitted` (a detail pane steps its words down together, to 18 at least, then closes its gaps),
  `UIKit.fit_width` (a one-line label shrinks to its width before it trims), `UIKit.read_on` (Confirm pages down long words before its usual job), `UIKit.key_scroll` (a box of words
  takes the focus and scrolls on up/down; Cancel returns to the list via MenuBase's `back_to`), `UIKit.line_height`
  (hand-set row heights grow with Large text), `UIKit.ink_label` (no drop shadow for dark text on paper).

Then per screen: pause (rows sized from the panel, two stats per row, Today's Walk kept when it fits at a readable
size), Settings (rows scroll above the preview; chips get two rows), Almanac hub and ledgers (scroll), Party Pieces,
Stud Book and the other Fieldbook tabs (fit), Region stamps (Confirm moves into them to scroll), Stats > Standing (two
abreast; job lines wrap), Stats tallies (fit their column), Enclosure's lots (scroll; statement fits), Noticeboard
(job words fit their panel, titles shrink before trimming), summary (move names shrink, charm effect gets its own
line, the middle card is snug), party preview and bag picker (long nicknames), pairing names, Isles topics and
postcard place names (shrink before trimming), quests and Gazetteer pages (fit), league card and card album (keys
scroll; league words lose the smearing shadow), Fieldbook entries and the Words tab (at 18 px most entries still fit
one box; a long one shows "Read on" in the hint bar and Confirm pages down it before it opens the map or revision, as
the Gazetteer's Isles topics already did; `test_fieldbook_teaching` now holds every entry to two boxes at most).
Settings and Accessibility rows grow with Large text instead of overlapping.

Minigame stages (`draw_string`, not seen by the audit): words under 18 px raised to 18 (isobar labels and "Isobars every
4 millibars", the bowling POWER label and distance marks, the league progress bar, "stuck" in Poohsticks, the cheese
slope hints, "Spin", "yards"). Icon glyphs inside small markers (the "?" on the map, saddle-cloth numbers, the FINISH
flag) were left as drawn.

After, normal text: **0 problems on all 122 screens**. `--stress` adds only
12-letter "MWMW..." nicknames trimmed with an ellipsis in three tight rows, which is the fallback working.

## What's left

- **Large text** (`--text=large`): 162 problems remain on 43 screens (normal had the priority; the owner
  plays at normal). The worst: summary (three columns too tall), racecard, Exchange and Crypto (trimmed figures),
  crossword grid, world map's info card, jobs, pairing predict, shop boutique. Fixed so far at Large: Settings,
  Accessibility, Stats tallies.
- `fit_size` measures with `ThemeDB.fallback_font`, so with the Readable font setting its sizes are approximate.
- The audit can't see `draw_string` text; the minigame stages were checked by hand and by screenshot.

Test: `tools/test.sh text_fit` runs the audit on eight key screens (pause, bag, settings, a Fieldbook entry, summary,
Almanac, the long travel list, Standing) in a second headless Godot, about ten seconds, and fails on any problem.

## Large text, long names and the Readable font (w50-tf-large)

Branch `w50-tf-large`. Where the first pass left off: 168 problems on 41 screens with `--text=large` (at 6c5340a7),
and with `--stress` 7 trimmed 12-letter nicknames at normal text, 32 problems at Large.

### What was wrong underneath

- **The Readable font never stayed on.** `Settings.apply_access` set the font (and the theme's Large button size) on
  `ui/theme.tres` and let go of it; once no menu held the theme it was freed, and the next `load` came back plain.
  Dev runs and the audit never saw the Readable font at all, and in play it held only while something kept the theme
  alive. Settings now keeps the theme (`_theme`). This also made buttons draw at their real Large size in the audit,
  which turned up a dozen more problems (casino side columns, name entry keys, the Cage), fixed below.
- **Fitted names grew after fitting.** `fit_label` and the hint bar worked out a size at normal text, then
  `UIKit.label` scaled it by a quarter. New `UIKit.fit_scaled(text, width, big, small)` starts from the Large size and
  may shrink to `small` (unscaled); `UIKit.sized(n)` is what `UIKit.label(t, n)` draws at.
- **Measured with the wrong font.** `fit_size`, `line_height` and the word boxes measured with
  `ThemeDB.fallback_font`. `UIKit.font()` is the font in use (the Readable font when it is on); trump cards draw with
  it too, so their names fit.
- **Word boxes ignored Large text** (`fit_block` set unscaled sizes). They scale now, and lines can be optional in
  tiers (`add_words(..., optional = 2)` goes before `1`).
- `fit_column` measured rows by their old minimum sizes (a container's minimum lags its labels' new fonts), so it
  shrank much further than needed; it now measures rows, stacks, grids and panels from their labels.
- `fit_width` only refitted on resize, so a label whose words changed later kept the old size; it refits on redraw.
- `keep_fitted` fitted once per refill, sometimes before layout had settled (too small for good); it also refits
  when its box resizes.
- A word box that stopped needing its scroll bar kept showing it (Godot only rechecks when the box's own minimum
  size is asked for): `fit_block` rechecks.

### New shared pieces

- `MenuBase.header_right` takes the room beside the title and shrinks (to 18 px) before it would run off: the
  casino purse-and-limit line, page counts.
- `UIKit.row_label`: a row's name that takes the room the rest of the row leaves, shrinks, then trims.
- `UIKit.big_text()`: for the few layouts that trade a little picture or bar for the words.
- `CasinoBase.fit_side(column)`: a table's side column steps its words down to fit, and with Large text its buttons
  lose their top and bottom padding.
- Dev switches `--text=normal|large|largest` and `--readable` for the game (screenshots) and `--readable` for the
  audit. Neither is ever saved.

### Per screen

Summary (picture and stat bars a little smaller with Large text, the three cards step down together, the knack
shares the entry's card and the entry gives way to it if need be, move names share one size); racecard (runners
scroll, side column wraps and steps down); Exchange and the Doggerel kiosk (figure columns size to their widest
entry, names shrink, the detail pane steps down around the deal slip, the portfolio fits); crossword (letters take
the largest size that fits the square); world map town card (steps down to the room above Where next?); Noticeboard
(with Large text the standing card sits under the list); bag (the run of tabs that fits round the current one, item
card fits, the picker's HP bar sits over its numbers); shops (names take the room the price leaves, card fits,
try-on a touch smaller); pairing (rows, plates, Dr Keir's card); casino tables (Cage, fruit machine, Higher or
Lower, Blackjack, roulette); pause (the top card keeps under half the page, Where next? shrinks to 18 px and Right
reads down it if it still runs on); quests and Gazetteer plaques and peoples (Confirm reads on, as Isles topics
did); controls, Keepers, Biology, relearn, starter, Ark, Stud Book, Rumours and stamps, the Words tab, Papers,
credits and name entry.

Long nicknames: the bag's picker, pairing, the summary (may step to 20 px) and the Team rows now show a 12-letter
"MWMW..." name in full at both text sizes. Ellipsis is left only where nothing else fits.

### After

| run | before | after |
|---|---|---|
| `--text=large` | 168 on 41 screens | 0 on 122 |
| `--readable` | (font never applied) | 0 |
| `--readable --text=large` | (font never applied) | 0 |
| `--stress` | 7 | 0 |
| `--stress --text=large` | 32 | 0 |
| `--stress --readable --text=large` | | 0 |
| normal | 0 | 0 |

`--text=largest` was not a target: 144 problems on 43 screens (mostly minigame side panels, and the same detail
panes one step further).

Under heavy machine load the Noticeboard once showed a problem at Large that a rerun didn't (its detail fits a frame
after it settles; the audit waits 0.7 s).

`tests/ui/test_text_fit.gd` now also audits summary, racecard, Exchange and world map with Large text and the
Readable font (a second audit run, about 8 s, 15 s on a busy machine), and checks `fit_scaled` and the held theme.

Before and after: `docs/screens/w50-large-{summary,races,exchange}-{before,after}.png`.
