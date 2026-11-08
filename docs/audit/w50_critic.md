# w50-critic: a new player's walk along the story

Branch `w50-critic` (from int-w50). A play-through by screenshot along `data/objectives.json`, looking at what a
player sees that the menu, battle, HUD/sign text, large-text and world-consistency sessions don't cover. Every shot
was a `tools/shot.sh` run (`open -g`, no focus taken, quits by itself). Shots were looked at one by one.

## Route covered

- Opening: title, name entry (`--menu=name`), starter picker (`--menu=starter`), cold open at three moments
  (`--menu=new_game`), the Field Station (Garside's first chat), Pause with "Where next?".
- Macclesfield (spawn, Field Station front in drizzle at 17:00, the south side by Paradise Mill), Macclesfield
  Forest (noon, and fog at 09:00), Cat and Fiddle road, Buxton (spawn, Spa front), Buxton Spa (Keeper Maud and her
  welcome line), Buxton Sanctuary and shop.
- Liverpool (spawn, the Cavern (ish) front, club interior and Ray's welcome), Sanctuary, shop, Wirral Way, Chat Moss.
- Chester (fog at 08:00), Sanctuary, shop, Dee Valley. Llanberis (rain at 16:00), Dinorwic Quarry Gates and
  quarry, Sanctuary, shop. Yr Wyddfa.
- Cardiff (spawn, Arena front, Arena), Sanctuary, shop, Severn Crossing, Brecon Beacons.
- Glastonbury (20:00), St Michael's Tower front, the Tor, Sanctuary, shop, Somerset Levels.
- Holyhead. Dublin (spawn, Dublin Hall front and hall), Sanctuary, shop, Wicklow.
- Galway (fog), Galway Docks Arena front and arena, Sanctuary, shop, Connemara.
- Belfast (spawn, Belfast Yard front and yard, the Hands Mill doorstep), Sanctuary, shop, the Mournes.
- Inverness (rain), Ice Rink front and rink, Sanctuary, shop, Loch Ness.
- York (20:00), York Minster front and crypt, Sanctuary, shop, Sheffield.
- The end: Stonehenge gate, London (drizzle), Vane Tower front, Vane Tower summit.
- Battles: wild Croakle, wild Binfox. Chats: Garside, Maud, Ray, the Silk Fan, the Jodrell Bank plaque.
- Data sweeps (scripts, all 1,500 zones): spawn arrays, trees in front of doors, signs behind tree belts,
  doorsteps over a tree belt, NPCs on props, props on one-tile paths, US spellings, doubled words, em-dashes.

## Fixed (worst first)

| What | Where | Fix |
|---|---|---|
| Stepping out of a building on a town's south edge, the tree belt in front hid you completely | Manchester (4 doors), Belfast Hands Mill, Liverpool (2), Edinburgh (3), Keswick (3), Dublin, Cork, Llangollen, St Helier, Yorkshire Dales (2), Bletchley, Faerie Glen | the trees right in front of those doorsteps are low hedges now. `docs/screens/w50-critic-doorstep-*.png` |
| Arriving at the Tor (Keeper Morwen) you were hidden behind the bottom two rows of trees | `glastonbury_tor` rows 30 and 31 | hedges. `w50-critic-tor-*.png` |
| Every `cathedral` building was a blank wall: the nave's windows and the tower window were drawn inside the stone | `world/landmarks.gd` `_cathedral` (York Minster, Chester, 20 more; `limestone_church`, `pennine_church`) | windows at the real face. `w50-critic-minster-*.png` |
| Same for Leeds Town Hall, behind its colonnade | `_leeds_town_hall` | same |
| All 102 shops were a counter, a bookshelf and a plant: they read as a reading room | `data/zones/*_shop.json` | new `shop_shelf` prop (tins, packets, bottles, price strips) in both back corners. `w50-critic-shop-*.png` |
| The Percy French plaque ("The Mountains of Mourne") had been pasted into the spawn array, so it never stood | `mournes.json` | a sign again at 38,51; `ZoneData` now reports a spawn that isn't `[x, y]` (test) |
| A tree in front of Buxton Spa hid its name board (the first Keeper's door) | `buxton` 38,32 | removed. `w50-critic-buxton-spa-*.png` |
| Trees on the doorstep diagonal hid doors and boards | Llanberis, Cardiff, Glastonbury, Inverness, Manchester, Chat Moss signal box, Cairngorms Reindeer Centre, Jamestown (3) | moved a few tiles along |
| Signs and plaques standing right behind a tree belt (you could not see them to read them) | Mournes (3), Belfast (Chaim Herzog), Buxton (Solomon's Temple), Chat Moss, Liverpool, London, The Roaches, Stoke, Merthyr, Shrewsbury, Ironbridge, St Andrews, Forth Bridges, Flow Country, Ring of Kerry | moved one or two rows clear |
| "parking lot" | Brize Norton sign | "car park" |

Tests: `tests/world/test_shop_shelves.gd` (new), `tests/world/test_zone_data.gd` (spawn shape).

## Left (findings)

1. **Standing toast lands on the zone name card and runs off the right edge.** On first arrival in a nation the
   "Someone in England has noticed you..." toast (ui/parish_toast.gd, layer 61, top centre) is drawn over the
   zone card (ui/zone_card.gd, also top centre), so neither reads; the panel is also not centred and its right end is
   clipped (it is sized before the label has laid out). Seen in Macclesfield 46,18, Glastonbury spawn, Galway spawn
   and docks, Belfast spawn and yard, York spawn. HUD text is w50-tf-world's, so not touched. Shots:
   macc_e, glastonbury, galway, galway_venue_out, belfast, york in the scratch set; easy to repeat with
   `--boot=galway@35,25`.
2. **York Minster crypt arrival is hidden behind a wall of tall stone blocks** (`york_minster_crypt`, spawn).
   The crypt's south wall is the cave-rock wall. w50-world's change to `_interior_walls` (a low rubble lip on the
   south side) should cure it; check after the merge with `--boot=york_minster_crypt@<spawn>`.
3. **York Minster is red sandstone** (the `cathedral` style is Chester's stone). It should be pale magnesian
   limestone. `limestone_church` has the right colour, but switching the style loses the gold Keeper board over
   the door (signage decides by style), so it needs a word in `world/signage.gd` first (w50-tf-world).
4. **Starter picker header says "Professor Garside's field station"**; everywhere else it is the Field Station
   (`ui/starter_picker.gd:21`, a menu, so left).
5. **Venue name boards cut short**: "THE CAVERN (ISH" and "PORT OF LIVERPOOL BUILDIN" (Liverpool spawn),
   "ST MICHAEL'S TOWER" squeezed small (Glastonbury), "Sandwich B" fascia (Belfast). Sign label code, w50-tf-world.
6. **Sanctuaries are as bare as the shops were**: a counter, a nurse, a plant. A healing machine or a creature bed
   behind the counter would say what the place is. Not done here (102 more files and a new prop).
7. **More signs behind tree belts** where there was no clear tile above to move them to (Armboth Forest 24,15 and
   30,8; Cambridge 38,53; Canterbury 43,55; Chester 2,20; Douglas 44,49; Edinburgh 17,60; Keswick 22,41; Leeds
   17,52; Llangollen 14,32; Sefton Coast 36,101, 27,50, 46,63; Sherwood 29,7; Tintagel 37,40; Jamestown plantation
   46,44). Each needs a hand-picked spot.
8. **Props on one-tile paths**: about 300 (bollards on quays, lamp posts, benches; the list is from a script).
   Most are deliberate street furniture beside a wider pavement, and the bot finds every route, but a few make a
   path you can see but not walk (Dee Valley 6,9 18,9 45,9 57,9 bollards; Wicklow 14,20 and 14,26). Worth a
   look by eye.
9. **Cold open**: the humming standing stone stands right against the Cat and Fiddle's wall end (it reads as part
   of the pub). Cosmetic.
10. **Vane Tower summit arrival** puts you in a one-tile nook at the bottom left with black below and the room
    off to the right; it reads as a corridor rather than the top of a tower. Cosmetic, the end of the game.

Nothing odd in the text sweep beyond the car park: no em-dashes, no placeholders; the doubled words are all real
(Crex crex, James James, Stone Stone, Yeah yeah yeah). Facts checked in passing: Lovell Telescope 76 m, 1957,
Sputnik's rocket, UNESCO 2019; Buxton water 28°C; Belfast to Cairnryan ferry.
