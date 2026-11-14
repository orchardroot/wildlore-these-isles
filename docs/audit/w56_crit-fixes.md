# Wave 56, crit-fixes: what was done about docs/audit/w56_critic.md

One commit per finding, in the order asked. Findings 8 (contract shapes) and 11 (discovery reward card) were left alone.

| # | Finding | What changed | Where to see it |
|---|---------|--------------|-----------------|
| 1 | Nobody says you have a boat | Two Intros cards, `coracle` and `sea`, shown by `Intros.boat_card` the first time you paddle onto `water` or `sea` (`world/overworld.gd` step hook). Hints setting and the veteran rule apply as for every card. | Walk into any river; later, into the sea with the Tide Stone. |
| 2 | Contract repute is decoration | `Contracts.ending_nudge`: at the report the pay is multiplied by 1 + 5% x the mean repute (clamped to +/-4) of the groups the chosen ending moved. The take-time fee still reads the poster's group. `fees_through` (economy sim upper bound) allows for it. | Close a contract after earning or losing standing with the groups it names. |
| 6 | "Where next?" names shut roads | `ZoneIndex` now records each zone's `gates` (flags of `RideCheck.is_gate` NPCs). `WhereNext.gates_open` skips a route with a gate still shut in `_wander` and in `MapLogic.promised_towns`. | Pause card near a Warden-gated road. |
| 9 | Weather/time clues stall | `Contracts.when_words`; the Journal's "Still to find" row ends "Needs it at dusk or at night, in rain." | Journal, Contracts tab. |
| 10 | Hairy Hands | Clue now reads "...after dark, once Cranmere's letterbox is stamped." (`q_devon_letterbox_3` is what shows the creature; the validator caps clues at 110 characters). | Fieldbook entry after the gran's rumour. |
| 4 | Footbridges pointless with a coracle | Text now promises what a coracle cannot do: the bike goes over (wading makes you dismount the bike, `overworld.gd` line 233; a same-zone warp keeps it). The "long way round" promise is gone. | Lancaster Mill, Inverness Footbridge screens, resident's "done" line, plaque. |
| 3 | Town projects change little | Deed screen shows "Town project, Lancaster Mill: takings +5%." (`TownProjects.deed_lines`). Each of the 15 gains `effects.keepsake` (name, shape, colours, one line of local colour), which `HomeExtras` adds to the souvenir list as `kp_<project>`; it is unlocked by the project being done and goes on the Mum's-house shelf like any souvenir. Validator checks them. | Finish a project, then Mum's souvenir shelf. |
| 5 | Story letters in three days | The six chains now wait `later_..._30`: 30 in-game days (Leases.SEASON), or a real week away, whichever first. `Quests.later`: waits under 14 days still honour "the real date changed". The postie's "not yet" lines say "in a month or so". | Make the choice, sleep. |
| 13 | Mum asks about the cat daily | New condition `cat_tired` (`FamilyCat.wants_rest`: she is in the party and below full HP). Mum's offer is inside it, still once a day. | Visit Mum with a hurt cat. |
| 14 | Six upgrades with no catch | water_butts (upkeep 4), listings (uses 10% more stock), ice_hold (upkeep 15), standing_orders (takings -3%), long/quay lease (upkeep 10), show_yard (uses 10% more stock), in every Deed that has them. | Deed "Fit out the place". |
| 15 | Manager temperaments by hash | `assign` filled for ten: Ned and Mervyn steady, Gwenllian and Hilda careful, Dessie and Morag thrifty, Pauline and Tamsin charmers, Fiona and Dot showmen. | Appoint them as managers. |
| 7 | Flotsam repeats | Every non-bottle find names its zone (`{place}` templates in `tools/flotsam/gen_flotsam.py`, data migrated in place). Bottles pay a small local food (22 mapped, 80 to 300 pence-value, nothing dearer than the crates' pasty) instead of sea glass or slate chips. | Any find. |
| 12 | Long lines | Split in two: forsinard `flows_warden`, the contract clues for beavers, corncrake (two), giant, seal, puca, bodmin, bog, marten, and the marten parish-hall decision. `Contracts.look` now returns a clue's lines separately, so a split clue is two boxes in the world (the Journal still joins them). A test caps contract clue lines at 270. | Any look-spot. |

## Things I was unsure of

- **Item 5, "a season".** I used 30 in-game days, the code's own `Leases.SEASON`. A real season would be about 90 days; say if you want that. An old save mid-chain gets its letter 30 days after the stamp, or after a real week away, so nobody waits for ever.
- **Item 4.** The bridges are still shortcuts; the new promise is "the bike goes over". If you want a stronger reward (a new door, a shop) it needs zone work I did not attempt.
- **Item 7 flotsam.** Re-running the generator is not idempotent against the current zones (it reshuffles 74 lines and would change flags), so I edited `data/flotsam.json` in place with the same templates and kept the generator in step. Do not regenerate over it without checking.
- **Item 2.** The nudge is the mean of the two groups, so an ending that moves one group up and one down by the same amount nets to nothing for a fresh player; it only bites once reputations differ.
- **Item 3 keepsakes.** I stated true facts I am fairly sure of (Jubilee Pool 1935, Aberystwyth longest electric cliff railway in Britain, Kinvara hooker races each August, Fungie in Dingle for nearly forty years, the Orkney vole, Luguvalium). Worth a second pair of eyes. The shelf has 12 slots and now 36 souvenirs; that was already true for 21.
- Edited a gate-sensitive area (`ZoneIndex` gains a `gates` key): `RideCheck` is untouched.
- Longer lines that remain: 15 more dialogue `say` strings over 270 (older `landsky_*`, guild and museum content) and the marten/kites/seal decision lines between 259 and 292; I only touched the critic's list plus what the new test caught.
