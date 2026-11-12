# w53-asks handoff

Branch `w53-asks` (from int-w53). Issues #148 and #149: asks that use the rest of the game, and something living in the house.

## What was built

**New `wants` kinds** (`core/wants.gd`, schema note at the top of the file)
- `{"kind": "seen", "species": "<id>"}`: matched against `GameStateData.seen`, which the Fieldbook fills for both seen and caught (`mark_caught` also marks seen), so either does it. The player is shown a "Show them your <Name> page?" choice; nothing leaves the bag.
- `{"kind": "photo", "zone": "<zone id>"}`: matched against the flag `photo_<zone>`, set by `Wants.note_photo` from one line in `ui/photo_mode.gd` `_take`, only when the PNG saved. Absent flag = no photograph, so old saves are fine.
- Default kind is still the item swap `{item, n}`; dish and fish asks are ordinary item wants.
- `Wants.check(zones, items, dex)` validates the new kinds (dex optional; `tools/validate.gd` passes it). `test_w47_j` got one `w.get("item", "")` so it tolerates wants with no item.
- 41 new asks in `data/trades/asks_w53.json`, all in homes that had no trade: 14 `seen`, 17 `photo` (about 2 or more per nation: England, Scotland, Wales, N. Ireland, Ireland, plus Bermuda, Turks and Caicos, St Helena), 7 dish asks (repeatable, daily-stamped, pay at most half the dish's sell price), 3 fish asks (one-off, no more than market). Seen and photo asks are one-off and pay 120 to 250.
- Economy: `Wants.visit_asks_total()` feeds `EconomySim.lump_total` (+6,040). Sim (5 runs, per `tools/dev/economy_sim.gd`): lumps 45,800 to 51,840; first lease day unchanged (81), all-ten day 132 to 315 per strategy within noise of before; yearly earnings up under 0.5%. `docs/design/economy.md` has a new row.

**Indoor folklore** (`core/indoor_folk.gd`, one line in `world/overworld.gd` step)
- A home's `encounters` may hold an `"indoor"` table (same entry format). Interiors have no tall grass, so `IndoorFolk.roll` gives 1.5% per step and uses the existing `Encounters.candidates` gates. Indoors the weather is always "clear", so the weather gate reads the sky outside (`sky.weather`). Stateless.
- 42 homes, only the `encounters` key of each zone changed. Level = median of the home's town grass table. Species and where:
  brownie (7 homes: Borders, Galloway, Central Belt, Fort William, Inverness, Oban, Thurso; dusk/night),
  cluricaun (4 Irish homes, night), bansheen (3 west of Ireland homes, night and gale or fog),
  bogglet (9: Cumbria, Cheshire, Wirral, Manchester; dusk/night), dresserwight (5 homes with a kitchen dresser in Cheshire, Merseyside, Manchester; night),
  hobling (2 York), dishwight (2 Sheffield), tylwyth (4 north and mid Wales; night),
  marilwyd (4 south Wales; night, winter only), pixiedell (2 Penzance; night, fog or drizzle).
- Left out because no species fits real local folklore: Isle of Man (no fenodyree species exists), Channel Islands, Orkney, Shetland, the Midlands, East Anglia, the South East, overseas.

**Family drawer** (`core/family_drawer.gd`, `data/family_drawers.json`, one hook line in `Search.take`)
- 200 entries (every home by the id rule plus the 35 `_h<n>` homes, minus `testbed_house`): kind photo/letter/keepsake/curio, the furniture it lives in, 2 or 3 lines, and (48 entries) a real curio id that goes in the bag with the Curios page message.
- The drawer is the first piece of the named furniture type in reading order that has no examine spot on it (falls back to any searchable piece). Found once; flag `drawer_<zone>`, absent = not found. Stat `drawers_found`. After that the furniture is the normal weekly lottery.
- No searchable furniture today in `pit_boathouse`, `plymouth_homepark`, `rhondda_bakehouse`, so those drawers cannot be reached until the rooms session adds some (the `_h<n>` homes are included, the brief's 166 are not the whole set).
- Validator: `FamilyDrawer.check` (real interior, lines, searchable `in`, real curio, no em-dash).

## Seeing it
- `tests/story/test_w53_asks.gd` covers the kinds, the validator, the 41 asks' limits, the indoor tables and gates, the drawer and the save defaults.
- Photo ask: take a photo (P, confirm) in the zone, talk to the resident. Drawer: `macc_home`, face the dresser or first piece in reading order.

## Notes for the integrator
- Shared files touched with one or two lines: `ui/photo_mode.gd`, `world/overworld.gd`, `core/search.gd`, `tools/validate.gd`, `core/economy_sim.gd`, `tests/story/test_w47_j.gd`.
- The people session renames the "Resident" speakers: the new asks speak as `Resident` through `Wants.WHO` and name nobody, so they stay correct.
- The drawer lines avoid resident names for the same reason. The looks session's examine spots are honoured at run time (a drawer never sits under one).
- The Irish line in `dingle_home4`'s drawer (`A Mhúinteoir, ...`) would benefit from a native check.
- No screenshots were taken for this session (no new visuals).
