# Wave 57, contracts2: contracts that do not all go the same way

Branch `w57-contracts2`, cut from `int-w57`. Only my own test fragments (`contracts`, `w55_`, `w56_secrets`,
`tile_clash`, `text_fit`), the validator and one economy sim run were used. No full suite, no playtest, no screenshots.

## The three shapes

Each is a field the contract data can ask for on a clue. All three live in `core/contracts.gd` (state and validation),
with small hooks in `story/contract_talk.gd`, `world/examine_scene.gd`, `ui/contracts_tab.gd`, `ui/quests_screen.gd` and
`data_api/zone_data.gd`.

| Shape | Data | Used by |
|---|---|---|
| A witness who is simply wrong, and stays wrong | clue `"wrong": true` (points at something that is not the truth, rules nothing out, and some lead it points at is not ruled out by any other clue, so it matters). The Journal lets you strike any found lead out (Confirm on a contract under way opens the list; flag `ct_<id>_struck_<clue>`), and a struck lead stops counting towards the working theory. A wrong lead can make the theory look sure of the wrong thing until you strike it or find more. Once decided, the Journal says "this one was wrong all along". | mink (Ted, "otter"), bog (the ranger, "gas"), kelpie (the surveyor, "spate"), mink_next (Alan, "rats"), bridge_otter (Dugald, "the horse"), buggane (Corlett, "wind"), tchian (Colin, "his Labrador"), hereward (Dennis, "mist"), chair (Rob, "a camper"), hogboon (Gavin, "the parlour") |
| A third look-spot that only opens once another clue is found | clue `"needs_clue": "<id>"` (or a list). Until then the spot reads as ordinary ground, the witness gives only their idle line, the Journal does not list it. The validator refuses a cycle, a missing id, and a required clue behind an optional one. | mink (the droppings after the prints), bog (the unscorched heather after the bog hole), beavers, kelpie and seal (the coracle clues below), mink_next, bridge_otter, buggane, tchian, hereward, hogboon, chair |
| A clue that is the creature's own behaviour, seen from the coracle | clue `"from": "coracle"` plus `"optional": true`; the examine spot carries `"coracle": true`. Ashore it says only that there is something to see out there (`hint_ashore`); afloat (`Player.wading`) it reads. It is always optional: the plain clues make the theory sure on their own, so nobody needs the Tide or Urban Stone for a contract. `ZoneData.validate` looks for somewhere afloat to face it from (coracle abilities). | beavers (the lodge on the Exe estuary), kelpie (the grey shape at the burn mouth, from the loch), seal (the seal at the net buoys off Thurso harbour), bridge_otter (the otter family at dusk), hereward (the watcher at the sluice, from the lode) |

A clue in a `secret_*` zone is a hidden place's, and the code treats it as any other zone. I did not use one: none of
the fifteen hidden places is somewhere a creature of an existing contract would honestly be, and I would not move a
tale to the wrong coast to use a mechanism.

The theory logic is now `Contracts.theory_of(contract, clue ids)`, which the validator uses to check that every
contract is sure from its plain clues alone, and from every clue with the wrong ones struck, and that a wrong witness
can leave the truth tied but never behind.

## The five reworks

Every old clue and all four endings are kept, so a save part-way keeps its found clues and a decided one stays decided
(the new clues are simply not found yet; there is a test).

- **mink**: Ted now says "otter" (the tracks point at an otter too, so Ted plus the tracks looks sure and is wrong).
  New third look-spot, the droppings at the culvert, opens once you have the prints.
- **bog**: the ranger is the wrong witness ("gas"); I removed the line in which he half-undoes himself. New spot, the
  unscorched heather where the light hung, opens after the bog hole.
- **beavers**: new optional coracle clue, the lodge out on the pond, opens after the stumps.
- **kelpie**: the river surveyor is the wrong witness; new optional coracle clue from the loch, opens after the hoofprints.
- **seal**: new optional coracle clue at the net buoys, opens after the bitten salmon.

## The two follow-ups (`needs`)

- **The Next Farm Along** (`mink_next`), Manchester board, 3 badges, appears only after Mink-proofing the shed (the
  `fence` ending of the first contract). Ted Barlow's hens go next, along the same lane. Suspects: the same mink, a
  fox, rats (Alan is wrong, "rats"). Choices: trap it properly (and learn a live mink cannot lawfully be released),
  put both farms on one scheme (raft, rota, traps where the prints are; Maureen and Ted end up friends), or bolt Ted's
  shed too (and the mink goes on to the Harpers'). Catch ending too. Three new residents show the results.
- **Wet Prints on the New Bridge** (`bridge_otter`), Fort William board, 8 badges, appears only after the `bridge`
  ending of the kelpie contract. Something new uses the footbridge: an otter (Bridie, a Holtling). The village thinks
  the water horse is back (Dugald is wrong). Choices: fit a dry ledge under the bridge, a bench and a sign for watching
  at dusk, or let the horse story stand. Catch ending too.

## The five new contracts

| Contract | Board | Tale | Creature | Choices |
|---|---|---|---|---|
| The Roof That Will Not Stay On (`buggane`) | Douglas, Isle of Man, 5 badges | the Buggane of St Trinian's, the roofless church near Crosby in Marown | The Buggane, a Cloughgart | put a roof on (it comes off the first night), fence it and leave it, tell the tale at the gate on dark nights |
| The Milk Has Gone Off the Mound (`hogboon`) | Kirkwall, Orkney, 9 badges | the hogboon, the mound-dwelling guardian of an Orkney farm who is owed the first of the milk | The Hogboon, a Gruagach | put the stone back and pour the milk, fence the mound and call Historic Environment Scotland, move the pit and say nothing |
| The Dog on the Bay Road (`tchian`) | St Helier, Jersey, 5 badges | the Black Dog of Bouley Bay (Jerriais *tchian*) | The Tchian, a Tchian | a lamp and a rail, a sign, the old rule (walk on, do not look round, say good night) |
| The Man in the Bottom Field (`hereward`) | Norwich, 6 badges | Hereward the Wake rising when the Fens are threatened, set against drainage, peat shrinkage and the Ouse Washes | Hereward | raise the bank and pump, flood it on purpose as a washland, rewet it as fen and cut reed |
| Somebody Is Sitting in the Chair (`chair`) | Shrewsbury, 7 badges | the Devil's Chair on the Stiperstones, where he sits when the mist is down | Old Nick, a Diaboulder | mark the ridge with posts, a notice at the car park, move the path and put a bench lower down |

Every contract has the catch ending as a fourth way out, residents who show what the choice changed, a "real story"
paragraph, and fees that are one-off and modest (pay 3 at the gate's badge count).

Additions to the world: a notice board in `st_helier` (44,25) and `shrewsbury` (40,28), because neither had one though
both towns already had jobs; no tile, edge or warp changed. Their people and look-spots went in with
`tools/zones/contracts_w57.py` (`add` for new clues of an old contract, `new` for a whole one; `contracts_w55.py` now
honours an exact `"at"` tile and sets `"coracle"`).

## Poster lines no longer quote a share (integrator's item, critic2 finding 8)

Thirty-two poster lines across all thirteen older contracts said "Eighty per cent" and the like, or "half the fee".
The pay at the report is nudged by repute, so the spoken number could be wrong. I took every number out, keeping the
jokes ("and a scone", "and a bed for the night", "because the committee would have my head"). A test now fails if any
poster line says "per cent" or has a percent sign. The new contracts never had them.

## Tests

`tests/core/test_w57_contracts.gd` (new, 15 tests): the three shapes on a sample contract (strike and put back, saved,
only while open; a clue that follows another; a witness who waits; the coracle ashore and afloat; the plain clues being
enough; the shape rules catching a bad clue), each shape used by at least three contracts, the old clues and endings
kept and an old save still having a theory, a wrong witness misleading mink until struck, the coracle spots existing,
the follow-ups appearing only after their ending (and not for any other), one read off the board, and no poster
quoting a share. `tests/core/test_contracts.gd` now sets up a follow-up's earlier ending and counts island pounds as
money, so every branch of every contract (all 20) still finishes, is paid once and survives a save.

## Economy

`tools/dev/economy_sim.gd -- 20`, contracts income line (the sim pays `Contracts.fees_through(badges)` as badges arrive;
every strategy shares it):

| | contracts earned over the run |
|---|---|
| before (13 contracts) | 45,908 |
| after (20 contracts) | 67,999 (+22,091, a one-off lump; jobs alone earn 932,857 over the same run) |

All other lines are unchanged. Fees are one-off, paid once by `Contracts.report`, so this is a one-time lump, not a
way of earning over and over.

## Result lines

- `tools/test.sh contracts` (test_contracts, test_w57_contracts): 39 passed, 0 failed, `validate: 0 error(s)`.
- `tools/test.sh w55_`: 34 passed, 0 failed, `validate: 0 error(s)` (RideCheck and Poi.check at 0 errors).
- `tools/test.sh w56_secrets`: 16 passed, 0 failed.
- `tools/test.sh tile_clash`: 2 passed, 0 failed (the two new notice boards).
- `tools/test.sh text_fit`: 9 passed, 0 failed.
- No `SCRIPT ERROR` lines in any of them.

## What I was unsure of

- **The tailor in the Buggane tale.** The roofless church, the buggane and the roof torn off are firm. The tailor who
  sews trousers overnight is "Timothy" in the versions I know, and I have kept it to "a tailor, Timothy" in one witness's
  words. Check it before release if you want it certain.
- **Douglas stands in for the whole island.** It is the only Manx outdoor zone, so St Trinian's stands in the fields in
  the south of the Douglas map, as the Tynwald guide and the Fairy Bridge harpist already do. A real Manx countryside zone
  would let the ruin be at Crosby.
- **Bouley Bay.** I used only what the Tchian's own dex entry says (the black dog, the cliff path, the lights for eyes,
  that it walks beside you and does not look round). "Say good night at the top" is my invention, labelled as a rule the
  game's old woman gives, not a recorded custom.
- **The hogboon details.** Haugbui (mound dweller), a mound on a farm, the first of the milk and a drop of ale at the
  brewing, bad luck for the farm that forgets: I am sure. The bowl-stone and the granny are fiction around it.
- **Heritage and scheduling.** The Historic Environment Scotland woman says it is a Bronze Age burial mound that cannot
  be moved, ploughed or built on. That is how scheduling works in Scotland, but the mound itself is invented.
- **Fens.** Hereward at Ely 1070 and 1071 and the Fen Tigers are from the game's own dex entries; Holme Fen's post,
  1851, roughly four metres out of the peat and the lowest land in Great Britain, the Ouse Washes flooding by design and
  Wicken Fen's sedge cutting for thatch are all well known. The notice (a figure at the edge of a field the Board may
  flood) is invented.
- **A "sure" theory can be wrong.** Because a wrong witness can lead the theory, the Journal can say "You have worked it
  out: an otter" while it is wrong, until you strike Ted out or find more. That is the point of the shape, but it is the
  one place the Journal says something false with confidence. Striking a true lead is also allowed and weakens the theory.
- **The strike-out list** (`ContractsTab.strike_panel` and `QuestsScreen._open_strike`) has been built and
  reviewed by reading only: I took no screenshots and did not open the Journal in the engine. `text_fit` covers the
  Contracts page but not the new overlay.
