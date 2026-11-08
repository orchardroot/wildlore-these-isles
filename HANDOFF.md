# w50-world handoff

Branch `w50-world`. "The world doesn't match what it says": Deep Places drawn as their lines describe, cave entrances
that look like caves, and a checker in the validator for the rest. Full write-up, counts and leftovers in
`docs/audit/w50_world.md`. The w49-games handoff moved to the end of `docs/audit/w49_handoffs.md`.

## What changed
- **Deep Places** (`core/deep_place.gd`, new `world/deep_meshes.gd`): a closed gate is a solid prop on the room's own
  floor (cave gate, grille, timber gate, barrier, oak door, slab, basalt, flowstone), an open one is the floor; levers,
  crates and plates have looks too (wheel, winch, weir board, handle, column, crack; boulder, tub, block, slab, column).
  The look comes from the line's words or a `"look"` key. Gate tiles are no longer rewritten, so `tile_at` on a gate is
  the room's floor; tests check `walkable` and the gate prop instead. Facing a closed gate reads its line
  (`world/deep_scene.gd`).
- **Cave rooms** (`world/zone_builder.gd`): low rubble on the camera side, lower side walls, no stalactite in front of
  a prop, sign or person. New point props `deep_gate`, `deep_lever`, `deep_crate`, `deep_plate`, `cave_cleft`.
- **Checker** (`data_api/world_consistency.gd`, called from `tools/validate.gd`; `tools/world_check.gd` lists all):
  object, near, stairs, cave, entrance, blocker and text rules. Findings that are right as they stand go in
  `data/world_consistency.json` with the reason. Tests: `tests/core/test_world_consistency.gd`, `test_deep_place.gd`.
- **Data**: see the audit. Zones: aillwee_entry, blue_john_entry, jersey_tunnels, pit_cave (cave stage, stone floor),
  castleton, jersey_country, dover (cave mouths), mendips (Wookey cleft, sign), wookey_hole, wookey_river,
  staffa_columns, blaenavon_bigpit_east, shetland_mainland (gate), chat_moss, ring_of_kerry (signs), chatmoss_signalbox
  and nym_signalbox (lever frames). Dialogue: dover_museum, plymouth_smeaton, three sanctuaries, brighton_rockshop,
  oxford_bodleian, oxford_camera.

## How to see it
`tools/shot.sh out.png 60 --boot=blue_john_entry@6,6` (add `--flag=dp_blue_john_entry_gate` for open),
`--boot=staffa_columns@7,5 --ride=lantern`, `--boot=mendips@62,39`, `--boot=castleton@45,22`. The machine was very
loaded (load average over 100), so 30 s delays often caught the title screen; 60 s worked. Run shots one at a time:
parallel `open -n` runs sometimes drop their arguments. Screens: `docs/screens/w50-world-consistency-*.png`.

## Notes for the integrator
- The w50-tf-world session owns sign text sizing; I didn't touch `world/signage.gd` or landmark labels. Building style
  changes (cave_mouth) keep their labels.
- The playtest bot never applied Deep Places and still doesn't; nothing here makes a new tile solid except the Shetland
  field gate, which replaces a wall tile (same solidity) and is a zone prop the bot already loads.
- `data/world_consistency.json` will need an entry, or a fix, for any new line that points at something not drawn.
