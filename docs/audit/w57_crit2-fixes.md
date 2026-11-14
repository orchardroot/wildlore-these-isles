# Wave 57, crit2-fixes: the critic's findings, fixed

One commit per item, in the order asked. Findings 8 and 12 skipped as instructed.

1. **Coracle secrets stay quiet until you can paddle there** (critic 1). `Secrets.known` = revealed and, for a coracle
   place, the Stone for its water is in `badges` (Tide for a sea tile, Urban for a lake; read off the tile, so no data
   change). `nearby` (the sense cue and so the Intros card) and `marks` (the map keyhole) use it. The rumour still sets
   its flag, and everything appears the moment the Stone is won. Test in `test_w56_secrets.gd`.
2. **Dawn is waitable** (2). `BenchSit`: a sitting begun at 21:00 or later may run on through midnight to 05:10, once
   per night (`_night_day`), exempt from the 240 minute sitting cap, the 360 minute day cap and the 23:45 guard. The
   bench hint then reads "Sitting a while, and it will run through to dawn". The Early Riser's known-branch line says
   a bench after nine at night does it. The fast clock crosses midnight, so day-end settlements (building society,
   deeds, leases) run as they would on a real night. Earlier sittings in the evening behave as before.
3. **Mum's first morning** (3, 4). The garden, the noticeboard and "I said you were busy" are gone; it is now the
   morning, Garside rang, the cat's untouched breakfast, the Field Station, tea, then the recipe book as the last thing
   she says (sets `mum_recipes`, so the Mum-and-cat egg works from the next talk). The old "second talk" hunk is kept for
   saves that have `mum_done` but not `mum_recipes`. The bot's script (`_talk macc_home mum`, then Garside) is unchanged
   and still works because it only needs one talk. `tools/zones/recipes.py` still has the old scene; it is a one-off
   generator and was not re-run.
4. **Cat eggs** (5, 6). New `Eggs.cat_ok`: `needs: "cat_party"` (anywhere in the party); `cat_lead` still supported.
   `box` and `grin` now use `cat_party`. The phone egg takes an optional `to` hour: rings from 00:00 to 02:59.
5. **Three reveals found by looking** (7). Combe Down (Bath, 9,4), Mortimer's Hole (Nottingham, 6,11) and the pele
   tower (Reivers Road, 55,58) each have an examine spot that sets the flag; the resident's line is now a hint
   ("have a look along the slope / the foot of the rock / in the bank") and no longer sets it. `how` is `examine` in
   `secrets.json`; the existing secrets tests cover it.
6. **Intros** (9, 11). New `contract` card, shown the first time a notice is read (`ContractTalk._offer`, through a new
   `hints_on()` on the story host and fake host, so Settings stays out of story code). The `secret` card now says "a
   hidden way in that you had a clue about".
7. **Keepsakes** (10). `data/items/w57_keepsakes.json`: Spiral Rubbing (Bryn Celli Ddu), Cave Shell (Merlin's Cave),
   Bottle of Cave Drip (Doolin), all curios at 150 (not money, sellable like any curio), taken once from the existing
   "view" examine spot, each with one extra line of text. Nobody takes a stalactite.
8. **Soap and flotsam** (13, 14). The Severn reply now gives `w57_bath_soap` (a key item, price 0), via a `give` on the
   bottle egg (`Eggs.bottle_lines`, validated in `Eggs.check`), and the slip says where it is. For flotsam,
   `gen_flotsam.py` has 9 more sentence variants (crates 3, sea pots 2, fresh pots 2, caches 2). I did not re-run the
   generator (it reads the live world and could move finds); `data/flotsam.json` was recomputed with the generator's own
   hash formula, after first checking that the formula reproduces all 44 old texts exactly. Only `text` changed; ids,
   flags, tiles and rewards are untouched. The worst repeat went from 6 to 5 (the hash still picks; more variants would
   thin it further).
9. **New-place tally** (15). `ZoneCard.new_line`: "NEW PLACE" alone until the fifth place, then "N of M found".
   Hidden places keep theirs (15 in all, never a chore).
10. **Bells and the Regular** (release-note check). `Ambience.rings(prop)`: a cathedral, or a building labelled Abbey
    (church or chapel style, or kind church), rings; anything labelled ruin does not, and "Abbey Walk" is only a street.
    Side effect: Whitby and Melrose abbey ruins (style `cathedral`) no longer ring. **Regular at Mum's, bound resident:
    left alone.** A bound Regular is the resident, and 44 of 55 are named by quests or trade asks (and Eddie in Liverpool
    is the `keeper` id), so hiding them while they wait at Mum's could stall a quest step. The notes' claim stays "true
    except bound Regulars".

## Unsure
- Item 2 lets one sitting per night skip up to about nine game hours (about 36 real seconds). It does cross midnight, so
  daily stamps re-arm; that is the point, but the integrator may want to look.
- Whitby and Melrose ruins going quiet is my reading of "abbeys ring"; easy to put back (drop the `ruin` test).
- The pele-tower, Combe Down and Mortimer's Hole examine tiles are placed from the map rows; I did not look at them in
  game (no screenshots allowed). The validator confirms each can be reached and faced.
- Flotsam variety is only mildly better, for the reason given above.

Test results: `w56_` 21, `eggs` 16, `intros` 8, `bench` 11, `flotsam` 14, `w55_` 34, all 0 failed with `validate: 0 error(s)`; also `family_cat` 38, `contracts` 24, `ambience` 32, `zone_card` 4. `tools/playtest.sh slice 2`: PLAYTEST PASS.
