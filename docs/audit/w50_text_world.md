# Wave 50 text fit: the world, the HUD and battles

Session "tf-world", branch `w50-tf-world`. The owner: text "renders poorly throughout the game in most situations"
and it "puts people off playing". This pass covers what you see walking about and in battle: building signs, the
overworld HUD (dialogue, place chip, route chip, zone card, toasts) and the battle UI. The menus, Almanac pages,
shops and minigame screens are the parallel session's (`tools/dev/text_audit.gd`).

The fonts themselves are fine: the UI uses Godot's fallback font with `canvas_items` stretch, which re-rasterises
at the window's scale, and the sign fonts are imported with mipmaps. What went wrong was where the text was put.

## How it was measured

- **Signs:** `tools/dev/sign_audit.gd` builds every outdoor zone headless and, for each building's name, casts
  sight lines from the lettering to the game camera with the player at that building's door (`SignSight.audit`).
  It reports lettering hidden by a building (past the ones the game fades see-through there), lettering wider
  than its building, lettering off the screen edge, and fronts meant for a wall sign that got a board on posts.
  Run: `.godot-bin/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/dev/sign_audit.gd -- [zone ...]`
  (about a minute for all 1539 signs).
- **Screen text:** a new dev switch, `--text-check` beside `--shot`, writes `<shot>.text.txt` listing every visible
  label whose words run past their box, lines a box is too short for, text off the screen, text under a panel
  drawn after it, and type under 18 px (`core/text_check.gd`). Run over Cardiff (plain, long sign, plaque, radio,
  Gazetteer read), ten towns, and battles with `--stress` (12-character nicknames) in the command, fight, bag,
  team, doubles target and weather-with-stages states.

## Signs: 331 of 1539 cut before, 5 after

| What | Before | After |
|---|---|---|
| Lettering hidden from the building's own door | 331 (184 of them completely) | 5, each 9 to 18% |
| Wider than the building | 0 | 0 |
| Off screen from the door | 0 | 0 |

The board sizing was already right (every name was fitted to its board and never wider than its building). The
causes were all about *where* the board went:

1. **Inside its own front (most of the 184 fully hidden).** Boards went on the footprint line, but many fronts
   stand proud of it: York's jettied timber fronts (Bettys, Stonegate, the Shambles, Merchant Adventurers' Hall),
   Chester's Rows, porticoes and porches, bow fronts and verandas. The board was drawn inside the wall.
2. **Behind a neighbour standing further forward.** Cardiff's Pierhead Building lost its G to the block in front;
   the Norwegian Church lost most of its name. Liverpool's Bold Street Books lost 45%.
3. **Lecterns under their own veranda or awning.** Special-shaped buildings (Pitcairn, Diego Garcia, Southport's
   Lord Street, Brighton's Regency fronts) get a board on posts, set 0.2 tiles out: under the veranda roof.
4. **Station totems under the canopy beam.**
5. **Tall buildings that never faded.** OccluderFade let any building hide you for 3.5 tiles behind it, so at
   Blackpool North you, and the station's board, vanished behind the Illuminations Depot.

Fixes (`world/sign_sight.gd`, new; small edits in `world/signage.gd`, `world/occluder_fade.gd`,
`world/camera_rig.gd`):

- `SignSight` builds a TriangleMesh per building (lazily, once per zone build) and finds, for each wall sign, the
  front's real face (the depth most of the front sits at, probed up the band), leaves out columns where something
  sticks further out (a porch, an oriel) or no wall stands behind, and leaves out columns hidden from the camera
  at the door. The board goes on the widest stretch left, nearest the door. If none is wide enough the name goes
  on a board on posts.
- A board on posts tries beside the door, the other side and mid-front, each pushed clear of what the building
  has sticking out at ground level; if all are hidden, the name goes back on the wall where some front shows.
- Totems stand in front of the canopy's beam.
- `OccluderFade.reach(height)`: a building hides you further back the taller it is (a two-storey house is
  unchanged at 3.5 tiles; the Illuminations Depot now 7).
- Cost: about 20 ms per zone load on this machine (rays only test the few buildings that can come between, and the
  facade is probed every other column), nothing per frame.

Still cut (all partial, from the door): Gaiman's Tŷ Te and Southport's Lord Street Tea Rooms (veranda shops, 18%,
lecterns under a deep veranda), the Spanish Frontier Post (18%, its booth), Carfax Tower and the Finnieston Crane
(9%, a letter's edge). Each still reads, and the place chip names them.

By design, not fixed: a sign seen from somewhere other than its own door can still be behind a roof (the place
chip carries the reading, as `ui/place_indicator.gd` says). That includes the owner's own view: from the Pierhead's
door the Norwegian Church is behind the unnamed building in front of both; from the church's door it reads whole.
Signs at the screen edge are the camera's framing: walk towards them.

Also seen, not fixed: London's Vane Tower has its O behind a lamp post. Props (lamps, trees) aren't in the sight
check; a follow-up could add the lamp and tree MultiMeshes as occluders, or keep lamps off sign columns in the
zone data.

## Overworld HUD

| Problem | Fix |
|---|---|
| A four-line dialogue page grows the box upwards, but the choice list stayed at the three-line height: it sat on the first line (same bug as the speaker's tab, fixed earlier on this branch). | The choice list stands on the box's top edge, above the speaker's tab when it would reach across it (`DialogueBox.choice_bottom`). |
| Parish toasts (Gazetteer, quests, standing, jobs) and the zone name card share the top centre; arriving in a new town fires both, and the toast (layer 61) covered the card. | Toasts wait for the card to go (`ZoneCard.showing()`). They queue anyway, so they never stacked on each other. |
| A long toast ("Someone in England has noticed you. Help out and they'll count you as one of their own") ran about 1000 px wide over the route chip. | Toast text wraps past 640 px, keeping the panel clear of the route chip; header up from 17 to 18 px. |
| The longest zone name ("Camp: Gypsy Cove and Volunteer Point") made a 740 px card reaching the route chip. | A name card's title shrinks (down to 28 px) to fit 640 px. |

Checked and fine: the speaker's tab on four-line pages (earlier fix), the place chip stepping aside for dialogue,
long sign text (Tiger Bay, the Coal Exchange), the wireless, the save toast, the pedia popup and piece prompt sizes.

## Battle UI

| Problem | Fix |
|---|---|
| The message box is two lines tall; a line needing a third grew the panel off the bottom of the screen. | A long line takes 26 or 23 px instead (`BattleMessage.size_for`), measured once per line. |
| The words could run under a picker opened over the box (the move menu starts at x 470: "What will MWMWMWMWMWMW do?" ran under it). | Pickers announce the rect they take (`BattleMenus.opened`/`closed`); the box narrows its words to the room left. |
| Bag and Team pickers covered the player's own HP plate: you couldn't see your HP while choosing a cup of tea. | Both open on the left, over your own creature; both plates stay in view. |
| Doubles plates clipped a long name mid-letter. | It ends in an ellipsis. |
| Small type: weather plate sub-line 16, note 15, chips 14; plate chip 16, XP 16; doubles' compact plates down to 11.5 px; move chips 15. | Weather plate 18 throughout; singles plates 18 for every word; compact plates never below 16; move chips 16. |

Left at 16 px on purpose: the capital tags (HP and XP on doubles plates, stage pills such as ATK +2, the type chip
on a move row, OUT). They are short capitals on solid pills, and at 18 a full row of six stage pills would no longer
fit the plate. `--text-check` lists them; nothing else in battle does.

## Notes for the menus session

- `UIKit.fit_size` measures with `ThemeDB.fallback_font`, so with the readable font setting on it measures the wrong
  font (pre-existing; affects anything that calls it, including the zone card now).
- The title screen's backdrop shows the Silk Museum's fascia half behind bunting.
- `--text-check` (`core/text_check.gd`) may be useful beside `tools/dev/text_audit.gd`: it is per-screenshot and
  catches text under later panels, which a per-menu bounds check doesn't.
