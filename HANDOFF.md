# w50-battle handoff

Branch `w50-battle`. Battle playback correctness and feel: plates that showed the end of a turn early, attacks that
landed after their hit, and some polish. The full list of paths checked is `docs/audit/w50_battle.md`.

## The cause, and the rule now
`Battle.take_turn` works out the whole turn before the UI plays it back, so a creature's own hp, status and stages
are already the end of the turn during playback. Every plate write a cue makes now goes through
`BattleFX.plates(cue, battle)`, which only reads the cue (so the event). If you add an event that changes what a
plate shows, put the value in the event (as `damage`, `switch` and `item` do) and handle it in `plates()`.
`tests/battle_ui/test_playback_plates.gd` will fail otherwise: it plays 120 seeded battles through the real HUD and
checks no plate changes before (or without) its own event.

## What changed
- Engine (`battle/battle.gd`): `item` events carry the target's `hp` and `status` after the item; `switch` events
  carry `status`; `cure_team` carries `cured` (field positions); a multi-hit's `hits` event goes before the first
  faint it caused.
- `battle_ui/event_player.gd`: item and switch cues pass those fields on; `hp_after_item` is gone (it guessed, and
  missed recoil, pricks and heals). `EventPlayer.verb()` for pair keepers ("send out", "want to battle").
- `battle_ui/fx.gd`: `plates()`, `heal_pos()`, `hit_time()`; an item on a benched creature no longer glows over the
  one on the field; a faint fades its plate; song, wave and Tidal Surge (`fx_signatures.gd`) land before the hit.
- `battle_ui/hud.gd`: plates track `hp_to` (where the bar is heading) and `status`; `sync(b)` (moved from the scene)
  compares with `hp_to`, so it no longer restarts a hit's drain; level-up grows bar and max together (no dip), and
  "gained XP" no longer bumps the plate's level before the bar fills; prick and heal numbers; `fade_out`.
- `battle_ui/battle_scene.gd`: the item special case is gone; `_sync_hud` calls `hud.sync`.
- `battle_ui/battle_flow.gd`: a meal's stat buff plays as a charm event so its pill shows with its line.

## Layout
Nothing in the layout session's area: no sizes, fonts or positions changed. The new number colour (heal green) and
the faint fade are in `hud.gd` but only touch modulate and a label colour. `Plate.set_creature` now resets the
plate's `modulate.a` (for the fade); if the layout session animates plate modulate, keep that in mind.

## Not done
- Victory music still starts after the XP and prize lines: the jingle is 3 s and does not loop. A looping victory
  track would let it start with the last faint.
- I could not reach a level-up with the dev `--battle` lead in a traced run; the level-up path is unit-tested.

## Results
- Full `tools/test.sh`: 2982 passed, 0 failed, `validate: 0 error(s)`, no SCRIPT ERROR (the "Parse JSON failed"
  lines are the corrupt-save tests). The pair-keeper wording commit landed during that run; its two test files
  (`test_flow`, `test_event_player`) were run again on their own afterwards and pass.
- `tools/playtest.sh slice 2`: PLAYTEST PASS, 85 wins / 3 losses in 90 battles, brook badge, no SCRIPT ERROR.
