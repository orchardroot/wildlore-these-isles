# Wave 53 rooms (#145) handoff

## What I built
- `world/home_props.gd` (new): three cheap meshes, `range_cooker`, `settle`, `box_bed`; registered with one line each in
  `ZoneBuilder.POINT_PROPS`, the `_ctor` dispatch and `CONTACT_SHADOWED` (`world/zone_builder.gd`).
- `tools/zones/home_packs.py` (new): dresses every home, deterministic on the existing `furnish:<zid>` seed, props only.
  Run `python3 tools/zones/home_packs.py data/zones [--dry]`. Not idempotent: `git checkout data/zones` before a re-run.
  It keeps each file's own JSON style (round-trip checked), uses furnish.py's `Room` reachability checks, and never touches
  an NPC, warp, sign, spawn, `examine` tile or the prop under one. Only sofas, plant stands and pot plants may make way.
  Beds and sofas are converted in place (same tile and turn), so an `examine` spot on them stays valid.
- Regional: Welsh dresser (Wales; slate heap in Llanberis); range cooker (Ireland, Stornoway, Harris, Portree, Skye);
  box bed (Kirkwall); settle plus kettle table (Cumbria, Yorkshire); wall map and sometimes a telescope in harbour towns.
- Occupation (from the resident's dialogue file): fisher (creels or map), stargazer (telescope), teacher (bookshelf or map),
  student (posters), music (harp or piano), weaver (loom), slate, artist, sport (dartboard), cat/dog/farm (bowl), books.
  Everyone also gets one small piece (window, cat bowl, kettle table or map).
- Tests: `tests/world/test_home_props.gd`, `tests/world/test_home_rooms.gd` (spawn, doors, NPC talkability, landing).

## Numbers
145 homes dressed (of the 166 "home/house/cottage" interiors; the other 21 are not residences: lighthouses, bakehouses,
boathouses, warehouses, a park, testbed, etc., listed in `NOT_HOMES`). Pieces: 44 ranges, 17 settles, 4 box beds,
7 dressers, 6 slate heaps, 72 wall maps, 21 telescopes, about 55 windows, about 50 cat bowls, 46 kettle tables.

## Room shapes: not done
`ZoneData.landing_near` already moves a loaded player off a blocked tile, so shapes would be save-safe, but
I kept this wave to props so `rows` stays untouched for the other sessions. Peat fire has no prop of its own: Hebridean
and Irish homes get the range beside the existing fireplace. Brass has no prop either.

## Notes for the integrator
- Only `props` changed in home zones (checked against HEAD for every file).
- looks session: I never remove a fireplace, bookshelf, table, dresser, bench, bed or wall picture; bed/sofa only change type.
- Screens: `docs/screens/w53/room_*.png` (Kirkwall box bed, Llanberis slate, Dingle range, Keswick settle, Aberystwyth map and
  telescope, Stornoway range).
- Tests: full `tools/test.sh` 3052 passed, 0 failed, `validate: 0 error(s)`; `test.sh home_` 32 passed, 0 failed.
