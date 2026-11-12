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
