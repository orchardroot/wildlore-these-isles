# Wave 57, critic2: wave 56 read as a player

Reading only: no Godot, no tests, no screenshots. Read: `data/secrets.json`, the fifteen `secret_*` zones, the fifteen
residents and four examine spots that reveal them, `data/eggs.json` and `core/eggs.gd`, `data/contracts/mare.json`, the
two Northern Ireland zones and their dialogue, `core/intros.gd`, `data/town_projects.json` (all fifteen keepsakes),
`macc_home`, `macc_fieldstation`, `cat_and_fiddle`, the bench and clock code, and the 5.6.0 notes.

## Text fixed in this branch (9 string edits, every file re-parsed with python3)
1. `data/dialogue/bath.json`: "Every honey-coloured house in Bath came out of the hill at Combe Down" overclaimed; now "A great many".
2. `data/zones/secret_mortimers_hole.json`: sign said Edward "went on to reign for forty-seven years"; he reigned fifty
   (1327 to 1377). Now "rule for another forty-seven years" (1330 to 1377).
3. `data/dialogue/erne_shore.json`: Hydro Engineer said "forty years" of electricity; the scheme dates from the 1940s and
   50s. Now "Seventy years".
4. `data/dialogue/erne_shore.json`: "Three kilometres of boardwalk" is a figure I could not stand behind; now "Miles of".
5. `data/zones/erne_shore.json`: Belleek "split in two by the border" is not something I am sure of; now "right up
   against the border".
6. `data/zones/tintagel.json`: the bottle said "LOW WATER ONLY ... NOT IF THE SWELL IS UP". The game has no tide and no
   swell, so a player would wait for something that never comes. Now "COME BY THE SEA SIDE, AND MIND THE SWELL."
7. `data/dialogue/skye.json`: the Strathaird crofter told you to go at low water (twice). Now "so real walkers go at
   low water" and "Mind the tide, remember." The sign keeps the true fact that the sea fills the mouth at high water.
8. `data/dialogue/anglesey.json`: the Early Riser said "come at dawn" and never said when that is. Now "between five and
   eight by the clock".
(8 files touched, 9 strings; the Skye crofter's two lines count as two. Total string edits: 9.)

Facts checked and holding: Paviland (Buckland 1823, young man, over 30,000 years), Spar Cave and Scott 1814, Herbert and
Cuthbert 687, Mortimer's Hole October 1330, Gatti and the Norwegian ice, the 1585 Act, Oxburgh's priest hole, Bryn Celli
Ddu as "Mound in the Dark Grove", Crannogs on Loch Tay, Belleek 1857, Erne scheme at Cathaleen's Fall and Cliff,
Cuilcagh boardwalk 2015, Mount Sandel, Lough Neagh and the Finn McCool tale, Toome eel fishery, the Aberystwyth, Jubilee
Pool, Kinvara and Keswick launch keepsakes, the Alderley Edge legend in the Mare's `real`, the Caesar shift (SXW WKH NHWWOH
RQ does decode to PUT THE KETTLE ON), the speaking clock phrasing, Schrodinger at the DIAS 1939 to 1956, Carroll born at
Daresbury 1832. Nothing in the eggs is unkind. Nothing in the new text uses a dash.

## Findings, ranked (what a player hits, file, small fix, size)

1. **The coracle secrets announce themselves long before you can paddle.** Three of them need the Tide Stone (Galway,
   par 60: Paviland, Merlin's Cave, Spar Cave) and two the Urban Stone (par 22). The rumour sets the flag the moment you
   talk, so a walker in Gower, Tintagel or Skye at par 25 gets the gold "!" over the follower, the Intros card "a way in
   that you were told about", and a ringed keyhole on the map for a door they cannot reach for another thirty levels.
   Fix: `Secrets.near`/`Secrets.marks` (core/secrets.gd lines 105 to 121) skip a `coracle` secret until the ability flag for
   its water (sea or lake) is set; the rumour's last line stays. S, one function and a test.
2. **The dawn secret cannot be waited for.** The clock is one game minute per real second, dawn is 05:00 to 08:00, so
   Bryn Celli Ddu opens for three real minutes in twenty-four. The bench fast clock stops at 23:45
   (`BenchSit.MIDNIGHT_GUARD`), nothing sleeps through a night, and no line tells you any of this (the hours are now in
   the Early Riser's text). Fix: let a seated player on a bench carry on to 05:00 only when they sat down after 21:00 (the
   guard exists to stop skipping days, not to stop dawn), or give the Early Riser a "Wait for dawn?" choice that sets the
   clock to 05:10 once. S. Same hole for the Mare's "dusk or night" clue, but that window is eleven hours so it is fine.
3. **Mum's recipe book is a second conversation most players never have.** `macc_home.json` "mum": the first talk sets
   `mum_done`; "Oh, before you go ... your gran's recipe book" plays only on a second talk. Everyone who talks once and
   walks out of the door at 4,6 reaches Maud's Stone without a recipe, and the Mum-and-cat egg (`Eggs.hook`) never wakes
   because it waits on `mum_recipes`. Fix: move the `mum_done` hunk to follow the first-morning lines inside the same
   script, so the book is the last thing she says. S, JSON structure only.
4. **The first morning is eight pieces of news before you reach the door.** Mum: Garside rang, the cat, the Field Station,
   the noticeboard, the garden, the tea, the mirror. Garside then says the noticeboard again, the Pigeon Lady a third
   time, and then Keepers, Stones, Esc, Kit and a battle. Fix in `macc_home.json`: drop the garden line (the
   `garden_ready` note says it when it matters) and the noticeboard line (Garside has it twice). S, deleting two `say`s.
5. **Two of the cat eggs need her in front.** `box` and `grin` require `FamilyCat.is_lead`. She joins at the back, behind a
   starter the player has just chosen and named, so most players never put her first and never see either (the grin is the
   better of the two). Fix: `needs: "cat_party"` (she is in the party, any slot) for the grin; the basket needs a
   sleepy cat only. `core/eggs.gd` `_spot`/`step_script`, one predicate, `FamilyCat.in_party` already exists. S.
6. **The midnight phone rings for one real minute in twenty-four.** `phone` is `hour: 0` and reach 2. You must be
   outdoors, within two tiles of a box, between 00:00 and 00:59. Fix: `hour` becomes a range (0 to 2), the answer's
   "an hour fast" still works. S in `Eggs.step_script`, data one line.
7. **Nine of the fifteen reveals do all the work for you.** The resident's chat sets the flag, then the cue, the map and
   the Atlas all point at the door. Only six (the four examine spots, the dawn stone, the bottle) ask the player to look.
   Combe Down, Mortimer's Hole and the pele tower are the easy trio: let the rumour hint only and put an examine spot on
   the true tile, as Sgwd yr Eira and the Burren do. S each, data and a prop; test `w56_secrets` changes its "nine
   rumours" expectation.
8. **The poster lines quote a percentage the nudge now makes untrue.** 31 `poster` lines in 13 contract files say "Eighty
   per cent" or "Sixty per cent". `Contracts.report` pays fee x choice fee x `ending_nudge`, which moves the pay up or
   down by as much as 20 per cent. Fix: either cut the number from the 31 lines ("a fair fee, and a scone") and let
   the paid toast say what you got, or show the toast with the percentage actually paid. M (text only).
9. **A new player's first contract is three trips.** The notice is in Macclesfield from the first Stone (Buxton),
   the clues are in `macc_forest` and want dusk, and the Mare is level 16 against a par-14 team (floor_par 13, no lift
   until par passes 13). Fair, but nothing in the game has said "contract" before. Fix: an `Intros` card `contract`
   ("A notice with a person beside it is a contract: take it, find the leads in the Journal, then decide what to do"),
   shown when the poster first speaks. S, `core/intros.gd` plus the one hook in `ContractTalk.offer`.
10. **Hidden-place rewards vary from a pup to a view.** Three places (Bryn Celli Ddu, Merlin's Cave, Doolin) give a
    plaque and a view and nothing in the bag. A walker who paddled out for Merlin's gets a good line and an empty hand.
    Fix: one small item each (a pressed flower, a shell, a stalactite drip bottle) via `find` on the existing examine spot,
    like Mortimer's chapbook. S each, data.
11. **The "secret" Intros card says "you were told about".** Four places are found by looking, not by being told; the card
    is nearly right. Fix: "Your creature has noticed a hidden way in you had a clue about." S, `core/intros.gd`.
12. **Both Northern Ireland roads open late and look identical.** `lower_bann` and `erne_shore` are shut until
    `badge_iron` (par 65) with the same two Warden lines ("Works on the Bann/Erne ... a cone"), the same grass tables at
    65 to 67 and the same three-walker structure. Fine as a pair, but the gag has now run on the Cat and Fiddle road and
    thirty others. Fix: change the second line for the pair ("The cone has been joined by a second cone."). S.
13. **Bottles still pay in a way that does not fit the place.** 22 bottles all pay food now (good), but Bath's "Please send
    soap" returns a cup of tea, and the Severn reply egg says soap was "sent" and sends none. Fix: let the egg's second
    slip give a bar of soap (an item, 0 value) or make the line "soap not found, enclosed: one cup of tea". S.
14. **Flotsam repetition.** Six finds share "A crate roped to a plastic float", six "A fish box with a crew's initials".
    They name the place now, but a walker with ten finds meets the same sentence five times. Fix: seed two more
    sentence variants in `tools/flotsam/gen_flotsam.py`. S.
15. **The new-place card counts to 217.** "1 of 217" on the first road is a large number for an hour-one player and the
    tally feels like a chore. Fix: show the count only from the fifth place found (`ZoneCard.show_card`). S.

## The first hour, as a new player meets it

Today: cold open, Mum (eight items), the street, Garside (stones humming, Fieldbook, starter, snares, Keepers, Stones,
Esc, a rival battle that teaches types), the noticeboard (jobs card), the Forest (first outdoor place card, wild
battle card, field spots and POI cues), the Cat and Fiddle road (the cat scene and the naming choice, then the
Wardens), Buxton and Maud. Up to a dozen one-line Intros cards arrive in about forty minutes, which is acceptable
because they are one line each and can be turned off; the load is the talking, not the cards.

Proposed order and load:
1. Mum: tea, the Field Station, the saucer for the cat. Nothing else. Then the recipe book as the last thing she says (finding 3).
2. Garside: Fieldbook, starter, snares, Keepers. Drop "Press Esc" to the first time a menu is needed; the cards say it.
3. Kit and the first battle. The types card fires at the first super effective hit, which is the right moment.
4. The Forest and the noticeboard (jobs): first outdoor place card, first wild catch, the rabbit job.
5. The cat, on the road, once a battle or two has been fought. She is the best scene of the hour; she should land when
   nothing else is being explained (she does, today, but the Wardens' joke follows straight on).
6. Buxton, Maud, first Stone. Only now the Mare's notice, with a contract card (finding 9).
7. Later and off the path: the Field Station's extras, the coracle (Liverpool), hidden places, eggs.
The cat is the right length. The first new-place card is fine ("Your team is chuffed" is a good line). Nothing in the first
hour is the wrong size by itself; the problem is Mum's list and a recipe scene that is easy to miss.

## What the 5.6.0 notes claim that the game does not do
- "A friend waiting at Mum's is no longer also stood in their own town": true except for a Regular bound to a resident,
  who is that resident and still stands in their own town (w56_loose-ends item 1, "not handled").
- "Only cathedrals (and Cambridge) ring the hours": abbeys also do (style `cathedral`), and the Bell list holds only Cambridge.
- "Each holds something that isn't money": three of the fifteen (Bryn Celli Ddu, Merlin's Cave, the Great Stalactite) hold a
  view and a plaque, nothing for the bag.
- "Something in the world has to show you each one": true, but nine do it with a chat that opens the way for you (finding 7).
- "The Journal says when a clue wants dusk or rain": true (`Contracts.when_words`).
- "Letters ... a month on": true (`later_*_30`), "the fee follows your name": true (`Contracts.ending_nudge`), keepsakes and
  Deed lines: true, footbridges and the bike: true, thirty new routes: true (28 + 2), five coracle places: true.
