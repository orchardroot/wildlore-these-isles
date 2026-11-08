# w51-critic2: a new player's walk round the side content

Branch `w51-critic2` (from int-w50). The w50-critic walk covered the story route; this one covers everything off
it: the overseas territories and the islands, the Party Pieces venues and getting in and out of a minigame,
travel scenes and the map, the Journal and jobs board, festivals, the post-game menus and field pieces. Every shot
was a `tools/shot.sh` run (`open -g`, no focus taken, quits by itself) and every one was looked at. Data sweeps
(scripts over all 1,540 zones) backed up what the shots showed, and each sweep that found something is now a test.

## Covered

- Overseas arrivals (`data/overseas`): Gibraltar, Falklands (Stanley, Camp), Diego Garcia, Ascension, St Helena,
  Tristan, Pitcairn, Rothera, Grytviken, Akrotiri, Bermuda, Anguilla, Tortola, Montserrat, Turks and Caicos,
  Cayman, Gaiman, Baddeck, Boston, Bristol TN, Roscoff; RAF Brize Norton.
- Islands: Douglas (and Laxey), Kirkwall (and St Magnus), Lerwick, Shetland Mainland in fog, St Helier, Jersey Zoo,
  St Peter Port, Guernsey country.
- Venues: Cooper's Hill (and the Race Starter's welcome), Oxford pancake race and Poohsticks bridge, the practice
  bog, the coracle at Ironbridge, Saddleworth welly wanging, Macc Forest sheepdog trials, Macclesfield worm plot,
  Lakeland wrestling, Sherwood conkers, Keswick games, Blackpool darts. Minigames: cheese, curling, darts, and
  coracle and snorkel run to the finish (`:dev_end`) to see the prize and the way out.
- Travel: train (York), ferry (Douglas), Fly (Gibraltar), the departures list, the map (`map:quest`, `map:post`).
- Journal (Active, Gazetteer), the jobs board, the lease auction, a festival a nation: Up Helly Aa (and Guizer
  Magnus's chat), Tynwald Day, Cup Match, Braemar, Falklands Liberation Day.
- Field pieces: a coracle (Shrewsbury), a glint (Harris), a cheese (the Broads), the Douglas bale hop, a wall gap
  (Galloway), a dead trunk (Mendips), a skim post (Dartmoor), a sheep gate (Kent Downs), a bog pool (South Downs);
  and the hint text for every verb.

## Fixed (worst first)

| What | Where | Fix |
|---|---|---|
| Arriving put you inside the guide (you vanished behind them) | `exeter_passages` 3,10, `castle_of_mey` 7,7 | guides step aside. `w51-critic2-exeter-passages-*.png` |
| Someone stood right in front of a doorstep or the flight's landing, hiding you as you arrived and blocking the way | Ascension (Movements Officer), Grytviken, Stanley, Cayman, Chat Moss (2), Bushmills (2), Llanberis, Mendips, Lee Moor, the Mournes, the Wirral, the Lake District | each takes one step to the side and faces the door |
| Signs nobody could read: in the sea off St Peter Port (Sark) and Dundee (the bridge welcome), in the Exe (Topsham), the Gallos plaque on a sealed bit of Tintagel headland, the Llangollen Eisteddfod sign boxed in by a bench | those zones | moved ashore, a way up the headland, the bench moved. A lone grass square left in the sea off St Peter Port is sea again |
| 28 props inside buildings: an oak through a house by Oxford's pancake race, a flagpole out of Anguilla's Salt Cottage roof, benches and flags in walls in Bermuda, Tortola, Turks and Caicos, Montserrat, lamp posts inside Manchester's Royal Exchange | 20 zones | street furniture moved to the pavement, stray trees, rocks and bushes removed; ruins (Jarlshof, Blaenavon) keep theirs. `w51-critic2-oxford-oak-*.png`, `w51-critic2-anguilla-*.png` |
| Houses abroad wore the town's own name: six GAIMAN boards, ROSCOFF, BADDECK, BOSTON, BRISTOL, Tristan's EDINBURGH, Adamstown's HOME | 7 zones | doorless houses go without a board (`show_label: false`). `w51-critic2-gaiman-*.png` |
| November turned St Helena's trees russet (and every tropical island's); a January frost could roll in Cayman | `Calendar`, `Seasonal`, `SkyAndLight` | no autumn colour or frost in the tropics, the southern year (six months on) in the Falklands, South Georgia, Tristan, Antarctica and Patagonia. `w51-critic2-st-helena-*.png` |
| The sheepdog trials steward "in the meadow" was ringed by pines; you and he were lost behind them | `macc_forest` rows 29 to 32 | a clearing. `w51-critic2-sheepdog-*.png` |
| Five darts pubs had a darts player and no dartboard | Blackpool, Donegal, Enniskillen, Oban, Swansea | new `dartboard` wall prop. `w51-critic2-darts-after.png` |
| Field piece hint: "You learn it at The practice bog..." and "The move is Coopers Roll" | `FieldSpots.hint` | "Where to learn it: ..." and the move's own name ("Cooper's Roll") |
| "rock candy" (US) at Salthill | `galway_salthill` | sticks of rock |

Tests: `tests/world/test_arrivals_clear.gd` (nobody on or in front of an arrival, overseas ones included; every
sign has a tile to read it from; no prop inside a building), `tests/world/test_house_boards.gd`,
`tests/world/test_darts_boards.gd`, and additions to `test_field_spots` and `test_calendar`.

## Left (findings)

For other sessions:

1. **w51-hud / w50-tf-large: the map's info panel covers the west of the map.** On `map:post` Dublin, Newgrange
   and the Irish towns sit under the panel, and Cambridge and London under the "Still to do" strip. Menu layout,
   left alone.
2. **w51-places: building name boards cut short** on the Falklands ("CHRIST CHURCH CATHED..."), Anguilla
   ("WALL...HOUSE" behind the Fountain Cavern rock), Douglas ("...ORSE TRA..."), Turks ("...aw Bar"). Same family
   as the w50 list.
3. **Sprites that don't match the part:** Guizer Magnus (Up Helly Aa, "Viking gear, torches blazing") is the pink
   flower-crown `festival_goer` (right for Blackpool's hen party, wrong for a Jarl squad). A guizer sprite would
   sell the fire festival. Sprite art, not done here.
4. **The Braemar Gathering is held at the Cairngorm ski centre on snow, in September.** The `cairngorms` ground is
   painted snow all year. Either a summer ground for that zone or the festival moved to a Braemar field.
5. **Grytviken's Norwegian Church** is a plain white box with a white block on the roof; the real church is a
   white timber church with a tall spire. Landmark mesh.
6. **Interiors where the keeper waits right inside the door** (you arrive face to face): Burren tower, Haworth
   Parsonage, the Turks capsule, Thurso cottage and pub. Probably meant as a greeting; left.
7. **Dense woods hide you near some field pieces** (the Galloway wall gap is in close pines; Sherwood's conker kid
   too). The pieces themselves read fine from the open side.
8. **Gazetteer header with dev data:** `--menu=quests:gazetteer` shows "422 read ... Next: 100 read makes you a
   Blue Badge Guide". `next_milestone` returns the first unpaid one; in play `record` pays as you go, so only dev
   saves (flags set without the payout) show it. Harmless, noted for whoever next touches the Gazetteer.
9. **Diego Garcia arrival:** two officers right beside you and a plaque in front; crowded but you can move.
   Pitcairn's landing is the same (a crowd at the Landing). Fine for a busy quay.
10. **Coracle `:dev_end` tie** shows a silver rosette with "Not this time." (both 27.6 s). A real tie is unlikely
    at tenths of a second, but the line could say "a dead heat".

Facts checked in passing: Up Helly Aa last Tuesday of January; Tynwald Day 5 July; Liberation Day 9 May (Jersey,
Guernsey) and 14 June (Falklands); Cup Match before the first Monday in August; Braemar first Saturday in
September; Galway Oyster Festival late September; Gallos at Tintagel 2016; the Lewis chessmen found at Uig in 1831.
