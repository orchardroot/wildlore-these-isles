# Wave 54, types: what beats what

## What was built

**In battle**
- Every damaging move row has a second line saying how it lands on the foe, from the very first meeting (the
  "seen before" gate is gone). Shape and words, never colour alone (`ui/effect_mark.gd`, drawn in code like `TypeGlyph`):
  - two up triangles + "Super effective x4", one up triangle + "Super effective x2"
  - a flat bar + "Normal hit"
  - one down triangle + "Not very effective x1/2", two + "Not very effective x1/4"
  - a cross + "No effect"
  - status moves say nothing.
  - Doubles: one group per foe in short form ("x2 Spikkin", "x1 Starlet"); if both foes get the same answer it is
    said once in full. Colour-blind palette: blue and orange instead of green and orange.
- Both plates carry the creature's type chips (glyph and name). The player plate moved up 22 px in singles and 28 in
  doubles to stay clear of the move picker.
- The move footer moved out of the picker into its own panel on the left, over the message box (the picker was out of
  height). Line 1 numbers, line 2 what it does, line 3 "Strong against ... Weak against ... No effect on ...", and
  "Esc: type chart" (the Menu key, as bound) at the foot.
- The switch menu ("Send out who?", also the forced replacement) takes the foes: each member that can be picked shows
  two cues between name and HP: attack ("Hits hard" up, "Hits evenly" bar, "Hits weakly" down, "Can't hurt it" cross,
  "No attack moves") from its best damaging move with PP left, and defence ("Weak to it" down, "Holds even" bar,
  "Resists it" up, "Immune" two ups) from the foes' own types. Doubles: best over both foes, worst over both foes.
- Menu (Esc/Tab/Start) on any battle picker opens the type chart scoped to the creatures in front of you.

**Outside battle**
- Fieldbook species page: "Weak to", "Resists", "No effect from" chip rows under the type row (names and glyphs,
  "x4" / "x1/4" after a double). They fit in the info column beside the sprite, so the entry text did not lose room.
- Summary: the same rows in the stats card, as glyph-only chips (name in a tooltip) because the page is full; and the
  selected move's "Strong against ... Weak against ..." line under its description.
- Bag, chapbook description: the same move line.
- Shared helpers: `TypeChart.weak_to/resists/immune` (and `strong_against/weak_against/no_effect_on`,
  `mult_words`), `TypeRows` for the rows, `MoveText.cues/cue_kind/cue_words/matchup_line/suits`.

**The chart page** (`ui/type_chart_screen.gd`, menu `typechart`): sixteen types on the left, pick one for what it hits
hard / weakly / not at all and what it is weak to / resists / is immune to, as chips. Reached from the Almanac
(always listed, after Fieldbook), the pause menu ("Types", between Almanac and Map), and Menu inside a battle (then a
"In this fight" card for both creatures comes first and the list opens on the foe's first type; Left/Right scrolls).
Added to the text audit SCREENS (plain and scoped).

**Teaching**
- Intros card `types`, shown once at the first hit that lands super effective, not very effective or with no effect
  (either side): "Types decide fights: Hearth beats Hedgerow beats Brook beats Hearth. Menu in a fight shows the whole
  chart." Card `typechart` the first time the chart screen opens.
- Starter picker: Garside's panel header shows HEARTH beats HEDGEROW beats BROOK beats HEARTH (not at Large text,
  there is no room beside his words).
- Kit's lines in `macc_fieldstation.json` now say Hearth, Hedgerow and Brook.

## First meeting, what changed
Before: a wild species you had never met got no hint at all, and a neutral hit never did. Now every damaging move says
how it lands on whatever is in front of you (types are on the plate anyway), including "Normal hit". `BattleFlow.move_hint`
now returns the cue array and no longer looks at `data.seen`.

## How to see it
- `tools/shot.sh out.png 30 --battle=stagbeet:12 --battle-menu=fight --lead=kindlet` (x4 and x1/2 in one picker)
- add `--double` for doubles, `--battle-menu=team` for the switch menu, `--text=large` for Large text
- `--menu=typechart`, `--menu="typechart:Holtling=brook+kin;Kindlet=hearth"`, `--menu=pedia:spikkin`,
  `--menu=summary:0`, `--menu=starter`, `--menu=pause`
- Screens: `docs/screens/w54/types_*.png`. On this loaded Mac the battle shots need a delay of 30 s or more.

## Tests
New: `tests/ui/test_type_chart_screen.gd`; extended `tests/data_api/test_type_chart.gd`, `tests/battle_ui/test_qol_battle.gd`
(the first-meeting gate test is now "covers a first meeting"), `tests/ui/test_layout_fit.gd` (twelve pause rows).

## Unsure about / for the integrator
- Knacks can change a hit's real damage (`Knacks.defend_mult`); the cues use the chart alone, as the old hint did.
- The pause menu now has up to twelve rows with the Ark; `ROW_MIN` went 42 to 38 so they fit (eleven rows unchanged).
- Summary's rows are glyph-only chips; the Fieldbook page has the names.
- `tests/ui/test_text_fit.gd::test_worst_screens_fit_with_large_text_and_the_readable_font` fails because of
  `races:dev` (four cuts at Large), nothing I touched. The `summary:0` audit at Large is clean. At "largest" text the
  Summary already overflows (the Evolves line, charm lines); I did not check whether the new rows add to it.
- Shared files touched beyond one line: `core/almanac.gd` (one entry in each of ORDER, NAMES, MENUS and a blurb case:
  the explore session adds its atlas page in the same lists), `core/intros.gd` (two cards and a MENUS entry),
  `core/scene_router.gd` (one MENUS entry), `ui/pause_menu.gd` and `ui/menu_logic.gd` (Types row).
- Not done: the Relearner screen's move description has no matchup line (not in the brief).

## Screenshots
All of the brief's list was taken before the integrator's limit arrived (picker against a dual-type foe, doubles, switch
menu, chart plain and scoped, Fieldbook rows, Large text for the picker and the chart), plus the Summary, starter
picker and pause menu. No further shots were taken after it. Not shot at all: the chapbook description with the new
matchup line (the dev menu opens it with the teach-picker up), the Summary at Large text (checked with the text audit
instead, clean), the types card in the message box, and the pause menu with the Ark row.
