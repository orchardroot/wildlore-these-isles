# Wave 53 handoffs

## asks
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

## people
# Wave 53 handoff: people (#146, #143)

## Built
- **28 names (#146).** Every home resident whose speaker was "Resident" now has a real name, in the dialogue `who` and as the zone NPC `name` (only that key added to each zone file). Table below. Five non-home rooms also speak as "Resident" (birmingham_rotunda, manchester_h5, llangollen_brynteg, llangollen_stationterrace, sheffield_parkhill); left alone, as the issue counts 28 homes.
- **Return visits (#143).** `core/visits.gd` (class `Visits`) plus `data/visits/1..4.json`, keyed `"<zone>|<npc>"`. One line added to `ScriptHooks.wrap` (`commands = Visits.hook(...)` at the top).
  - The first talk to a resident with an entry appends `set talked_<zone>_<npc>`; the talk is otherwise unchanged. Later talks append at most one extra `say` (speaker = entry `who`), picked from the kinds that apply right now: weather, morning/evening, season, then `again` (always applies). The pick is stable within half an hour of a day.
  - Time: `Timezones.local_minutes(data, data.tz_zone)`; morning is 05:00 to 11:59, evening 18:00 to 04:59. Season: `Calendar.season_today()` (real date). Weather: `data.weather` (the saved outdoor weather; interiors inherit it). There is NO snow weather in the game, so weather keys are the ones dialogue `when` already uses: rain (drizzle, downpour), fog, gale, frost, sunshine.
  - Save safety: absent flag = first visit, so old saves behave as today. The only new state is the `talked_*` flags.
  - Validator: `Visits.check` (in tools/validate.gd) requires non-empty lists of strings, valid season/weather keys, real zone and npc, `who` equal to the NPC `name` when it has one, no em-dashes. `Visits.missing_again` (tested, not a validator error) lists home residents lacking an `again`; it is empty.
- "Home residents" = the 187 non-teach_/non-case_ NPCs of the zones whose id has home/house/cottage (matches the brief's definition, so bakehouse, lighthouse and so on are in).

## Numbers
187 residents with `again`; 83 of them also carry time, season or weather lines. Line keys: morning 24, evening 14, season 13, weather 34.

## See it
Talk to anyone in a home, leave, talk again. `--date=MM-DD` and the clock/weather dev args change which kinds apply.

## Notes for the integrator
- HANDOFF.md replaces the previous wave's file of the same name (still in git history).
- Zone generators in tools/zones/*.py would drop the new NPC `name` if re-run for those zones; the names live in the JSON.
- The regulars session must avoid these 28 (ids below).
- Tests: tests/story/test_w53_visits.gd (picking, save default, one-line cap, validator, shipped data).

## The 28 renamed residents
| zone | npc id | new name (was "Resident") |
|---|---|---|
| aberdeen_home_a | abdn_home_a_quine | Kirsty Cruickshank |
| aberdeen_home_b | abdn_home_b_dad | Alan Mitchell |
| aberdeen_home_c | abdn_home_c_gran | Davie Duthie |
| aberdeen_home_d | abdn_home_d_mum | Jessie Ritchie |
| fw_home_a | fw_home_a_woman | Catriona Cameron |
| fw_home_b | fw_home_b_mum | Morag MacDonald |
| fw_home_c | fw_home_c_man | Ewen MacMillan |
| holyhead_home3 | hh3_lad | Gethin Hughes |
| inverness_home_a | inv_home_a_mum | Isobel Fraser |
| inverness_home_b | inv_home_b_grandad | Hamish Munro |
| inverness_home_c | inv_home_c_mum | Fiona Macrae |
| inverness_home_d | inv_home_d_man | Callum Ross |
| kirkwall_home_a | kwl_home_a_woman | Ingrid Flett |
| kirkwall_home_b | kwl_home_b_man | Magnus Rendall |
| kirkwall_home_c | kwl_home_c_dad | Billy Drever |
| kirkwall_home_d | kwl_home_d_mum | Thora Linklater |
| llanberis_home1 | lh1_mam | Eirlys Roberts |
| llanberis_home2 | lh2_dad | Dewi Parry |
| llanberis_home3 | lh3_gran | Menna Owen |
| llanberis_home4 | lh4_lad | Rhys Evans |
| llanberis_home5 | lh5_nain | Olwen Thomas |
| llangollen_home1 | llh1_mam | Bethan Davies |
| llangollen_home2 | llh2_dad | Gareth Lloyd |
| portree_home_a | portree_home_a_mum | Seonaid Nicolson |
| portree_home_b | portree_home_b_man | Norman MacAskill |
| portree_home_c | portree_home_c_mum | Mairead MacLeod |
| portree_home_d | portree_home_d_kid | Ruairidh Beaton |
| skye_house | skye_house_woman | Peigi MacKinnon |
