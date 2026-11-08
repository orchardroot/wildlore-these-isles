# Wave 49 crossings: HANDOFF

## Built
- `tools/field/gen_field_spots.py` now makes 24 hop pairs (was 3) across 24 zones, deterministic:
  paddle 5 (coracle over water), topple 5 (trunk over narrow water), skim 5 (new stepping stones over water),
  snorkel 1 (bog, flow_country), loft 8 (bale over a hedge, fence or wall). Max 8 per kind, max 3 per region.
- Every pair is a real shortcut (walking round is 24+ tiles or impossible) and the far side has a once-only cache
  spot (charm/mend/topple/round_up/roll/loft, 23 of 24 pairs) within 3 tiles of the landing. Nothing the story needs sits behind a crossing.
- New prop `stepping_stones` (core/field_spots.gd PROPS, mesh in world/field_spot.gd).
- Connectivity guard: the generator checks that making any spot tile solid never cuts a walkable tile off from
  the rest of its component (`cuts()`), for ordinary spots and pairs alike. Total spots 304 (was 242).
- Screens: docs/screens/w49-crossing-{galway,hadrians_wall,norwich,flow_country}.png.

## Notes
- Old wirral_way and other w48 pair placements changed (regenerated). Flags for the old pairs are gone; they were never reachable in shipped saves of note.
- Not done: "view with plaque" and "rare encounter patch" far sides; caches only. Stones are small in the screenshot; they sit on the banks.
- Hadrian's Wall loft hops the Roman wall itself; change the obstacle set if that reads badly.
- Verified: `tools/test.sh field` 71 passed, validate 0 errors; `tools/playtest.sh slice 2` PLAYTEST PASS. The full test result is below.
Full test: 2941 passed, 0 failed, validate 0 error(s), no SCRIPT ERROR (JSON parse ERROR lines are pre-existing test noise; RID leaks at exit are harmless).
