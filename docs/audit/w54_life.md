# Wave 54, life: a world that answers

Branch `w54-life`. All seven items built.

## What was built
1. **Quiet saving.** Every autosave still writes; `SaveToast.due` lets "Saved" show at most once a minute (`core/game_state.gd` hook, `ui/save_toast.gd`). Manual saves keep their own note on the save screen.
2. **Follower indoors.** `SMALL_INTERIOR` 200 to 60. After 5 s of standing still (also while sitting) it curls up (squash, slow breath) if a fireplace or brazier is within 7 tiles, or at night. Any step stands it up.
3. **See it, then fight it.** `RoamingCreatures.spring_out` runs after the grass roll in `overworld.gd`: a roamer within 4 tiles whose species is on the zone's grass table replaces the species (level pulled into that entry's range; no extra Rng draws), leaps at you, and goes back to grass nearby. Roamers that bolt give a faint cry (rate-limited).
4. **People react.** New `world/npc_bubble.gd`, driven from `Npc._react` every 0.35 s and only for people within 6 tiles: gold "!" for an errand start or open swap, heart for a Regular at favour 2+, sparkle for a child who spots the follower (turns to look, 30 s cooldown). Umbrellas on non-trainer, non-animal NPCs outdoors in drizzle and downpours. Pixel icons are made on demand and cached; bobbing is off under Reduce Flashing.
5. **Streets with people.** `tools/life/pick_strollers.gd` picks plain say-only residents (no gate, quest, shop, Regular, trainer, hours, routine, or id referenced anywhere in data or code) and checks each beat with `ZoneData.roamer_problem`; `apply_strollers.py` edits the zone JSON as text so formatting is kept. 138 NPCs changed. Towns now: 105 towns, 371 moving NPCs, 104 towns with someone moving (31 had none before). Mesh_gallery has none (no eligible resident). Short of target 3 or 4: carlisle, haworth, nicosia_south and a few more (the picker printed the list). Not done: people with opening hours walking to a door at closing (not cheap; left out).
6. **The ground answers.** `world/footfalls.gd`: a pool of 10 preallocated quads (ripples in shallows, boot prints on sand and in frost), one particle burst for tall grass and flowers, and a vertex push in `foliage.gdshader` (uniforms `pusher`, `push`) so low growth bends away from the feet. Nothing allocated per step; off on Low and indoors.
7. **Sit down.** `world/bench_sit.gd`: confirm facing a bench. You settle onto it, camera eases in, hint line shown, any key/button/click stands you up (also after 5 min). The clock runs 15 game minutes per second via `Game.time_boost`, capped at 240 min per sitting and 360 per day, never past 23:45, so it cannot skip days. The bot never sits. 2,323 benches are now seats.

## Shared files touched (one-line hooks)
`world/overworld.gd`: `Footfalls.attach(self)` after `RoamingCreatures.attach`, the `spring_out` block after the roll, and `BenchSit.interact` before `FishingScene.interact`. `core/game_state.gd`: the toast gate and `time_boost` (clock line). Nothing in the water parts of `overworld.gd` or `follower.gd`.

## Tests
New: `test_save_toast_quiet`, `test_see_then_fight`, `test_streets_alive`, `test_npc_bubble`, `test_footfalls`, `test_bench_sit`; `test_follower` extended. `tools/playtest.sh slice 2` printed PLAYTEST PASS.

## Screenshots (docs/screens/w54/)
Taken: `life_bench_dusk.png` (seated at dusk, lamps and windows lit, camera in), `life_drizzle_umbrellas.png` (umbrellas, walkers). Skipped on the integrator's instruction to spare the owner's Mac: follower in a home, curled by the fire, bubbles, grass parting, prints and ripples, a town with walkers beyond what the two shots show. The umbrella height was lowered slightly after the drizzle shot.

## Unsure / for the integrator
- Bubbles and curling were not seen on screen; logic is unit-tested only.
- Children are detected by id/name words (`NpcBubble.CHILD_WORDS`); there are no child sprites.
- Sitting sets `Router.busy`, so NPCs freeze while you sit.
- Strollers may stand in front of an interactable for a moment; the cork rule only protects lanes and doorsteps.
- `dev_sit` (`-- --sit`) is a dev switch called from `Footfalls.attach`.
- Screenshot runs on a loaded machine need a long delay (30 to 50 s) or they catch the title.
