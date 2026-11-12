# HANDOFF: regulars (#147)

## What I built
- A Regular can now be a home resident: give the entry in `data/regulars.json` a `zone` and `npc` (instead of `x`/`y`).
  No NPC is spawned for it. `Regulars.hook` appends `{"do":"regular","id":...,"bound":true}` after the resident's own
  lines; the scene then plays the intro / offer / gift prompt as before. Chat only plays from favour 2, so strangers
  just get the resident's usual lines. The `away` town still spawns an NPC for the "meet" beat.
- `short` (optional) is how lines and prompts name them ("Old Tom", "Mrs Hale"); default is the first word of `name`.
- Hook: ONE line at the top of `ScriptHooks.wrap` (`commands = Regulars.hook(...)`). Nothing in home zones or home
  dialogue was touched.
- Validator: `Regulars.problems` (one line in `tools/validate.gd`, after `Errands.check`): unique ids, real item for
  `likes`, real home and away zones, away tile in bounds, bound `zone`/`npc` exist and are not double-booked, all
  beats present, no em-dashes.
- `Deeds.summary` now shows the manager by name rather than the raw Regular id.

## Numbers
66 Regulars: the original 12, Old Tom (Bath) and 53 new, all bound to existing home residents. Tests: 19 in
`tests/core/test_regulars.gd` (new ones cover binding, the hook via `ScriptHooks.wrap`, intro in the house, quiet talk
for strangers, bad bindings caught, one manager per Deed and one Deed per manager, old-save defaults).

## Deeds managers and favour 4 and 5
Only 10 Deeds have `manager_slot`, so at most 10 Regulars can ever manage. `appoint` refuses a taken Deed or a busy
Regular, and the offer beat only appears with a free Deed, so 66 Regulars cannot clash. Side effect: a favour-4
Regular repeats the offer on each visit while a Deed is free and they have not been appointed. Favour 5 only caps
favour in code; the "scene at Mum's" from the design is not implemented.

## Not done / notes
- No Regular in Fort William, Holyhead, Llangollen or Skye: every home resident there is called "Resident" (the people
  session is renaming them). Once they have names, add an entry bound to one of them.
- Macclesfield's only candidate is the player's Mum, so it has no Regular.
- Existing spawned Regulars Morag and Sean stand on tiles that are not walkable (the overworld nudges them), so the
  validator only checks spawn tiles are in bounds.
- Manx, Welsh, Gaelic and St Helenian words in the new beats were written by a model from the residents' own
  vocabulary: worth a human glance (Douglas, Aberystwyth, Llanberis, St Helena).
- The Regular's `name` in a letter is their full name; the resident's on-screen speaker name is unchanged (people
  session may rename "Resident" speakers only).
