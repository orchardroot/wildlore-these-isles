# w50-tf-menus handoff

Branch `w50-tf-menus`: text that fits on every menu, screen and minigame at 1280x720 (the other half, battle UI,
overworld and HUD toasts, is the other session's). Full findings in `docs/audit/w50_text.md`. (The previous
HANDOFF.md, w49-games, is in git history at 83dd13d5.)

## What I built
- `core/text_fit_audit.gd` (TextFitAudit): walks the visible text under a node and lists what doesn't fit: wide,
  trimmed, lines, cut, spills, overlap, under, small (< 18 px), box (a framed panel cut off), stuck (words only a
  mouse can scroll to).
- `tools/dev/text_audit.gd` (+ `_body.gd`): opens all 122 screens with DevMenu's sample journey, headless, no window,
  and prints one line per problem. Exits 1 if anything was found.
- `tests/ui/test_text_fit.gd`: the audit over eight key screens in a second headless Godot (about ten seconds), plus
  unit tests for the 18 px floor and `UIKit.fit_column`.

## How to run it
```
.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/text_audit.gd -- all
    [screen ...] [--summary] [--stress] [--text=large] [--kind=cut,box]
```
After adding a `class_name`, run `--import` once or the audit can't see it (it quits with code 2).

## Numbers
Before (528d58a9): 331 problems on 70 screens, plus a Gazetteer script error. After: 0 on 121 screens; the Words tab's
learnt-word list still only scrolls with a mouse. Large text still has 162 on 43 screens (see the audit doc).

## Notes for the integrator
- Shared files touched: `ui/ui_kit.gd` (MIN_TEXT floor in `label`, `fit_size`, `fit_block`; new `scroll_list`,
  `fit_column`, `keep_fitted`, `fit_width`, `key_scroll`, `line_height`, `ink_label`) and `ui/menu_base.gd` (hint bar
  fit, HINT_MIN 18, Cancel honours a `back_to` meta). The floor means any `UIKit.label(x, 16)` is now 18 px.
  Outside my scope the only small literal is `ui/parish_toast.gd`'s 17 px heading (now 18); battle_ui and world pass
  18 or more, so their layouts should be unchanged.
- Not audited (the other session's): overworld toasts and HUD, `ui/parish_toast.gd`, battle UI.
- `ui/gazetteer_tab.gd` had a real bug (row 0 vs 1) that threw on every Gazetteer open and hid the "How these isles
  work" row: fixed here.
- Pause's Today's Walk line is now optional in the Where next? card: it shows when there is room at a readable size
  (it was 12 px before). The Fieldbook's "Found in" line is the optional one there; the map (Confirm) shows the places.
- Before/after shots of the worst five: `docs/screens/w50-text-*-before.png` / `-after.png`.
