# Wave 55: facts, people and tone review

A reading pass over the contracts, the six story chains, trade news and the enterprise text. Text values only. The seal, Bodmin and turf points were checked with web searches. No Godot, tests or screenshots.

## Read

| Area | Read |
|---|---|
| Contracts | 12 files in full (notice, clues, choices, real story, idle lines), plus the NPC lines they put in the zones |
| Story chains | 6 quests, about 560 dialogue lines in 17 zone files, 18 keepsake items |
| Trade | all 14 news events (wire, stall, board lines), orders and report text, string literals in `core/trade_news.gd`, `core/trade_orders.gd`, `core/trade_ledger.gd` |
| Enterprise | 15 town projects, 21 Deed matters, 11 Deed files (upgrades and own matters), managers, post letters |

No em-dashes or en-dashes in anything a player reads (the one hit in `core/trade_news.gd` is a validator check, left alone). No American spellings found.

## Fixes, before and after

### Contracts
1. `seal.json` real story. Before: "In recent years Scotland has stopped licensing the shooting of seals to protect fisheries." After: "Since 2021 Scotland has not licensed the shooting of seals to protect fisheries." (Checked: licences for fishery protection ended 1 February 2021, Animals and Wildlife (Penalties, Protections and Powers) (Scotland) Act 2020.)
2. `bog.json` real story, turf ban. Before: "Since 2011 turf cutting has been banned on many protected bogs, with compensation". After: "...stopped on the protected raised bogs, with compensation or a new bank elsewhere". (Checked: the 2011 cessation scheme covered raised bog SACs, not Connemara's blanket bog, which the story is set on.)
3. `bog.json` real story, folklore. Before: "In Irish and Scottish folklore the light is Stingy Jack". After: "In Irish folklore". And "which is where the carved pumpkin of Halloween comes from" became "which is one root of the carved Halloween pumpkin".
4. `bodmin.json` real story. Before: "A popular theory is that owners released exotic cats after the Dangerous Wild Animals Act of 1976 made keeping them costly and licensed." After: "One popular theory is that owners let exotic cats go after the Dangerous Wild Animals Act of 1976 made keeping them licensed and costly. It is only a theory." (The 1995 inquiry wording stands: no verifiable evidence. The theory is widely reported but I could not find a primary source, so it is flagged as a theory.)
5. `puca.json`: "Poll an Phuca" and "puca" given fadas (Poll an Phúca, púca) in the real story, the lair line and the Dublin resident line (`data/dialogue/dublin.json`). The drowning date "in the 1940s" became "around 1940". The teenager's line "Those Doyle lads" became "Those two village lads" (Doyle is the old farmer, Noreen Byrne's lads were the ones blamed).
6. `marten.json`: ranger said "the foxes and the grey squirrels are having a bad time of it"; the foxes claim is not established, now grey squirrels only. "closing every gap smaller than a fist" (backwards and too big) became "closing every gap you could post an egg through".
7. `knockers.json`: poster said the old level is "on the Rhondda side"; Blaenavon is in the Eastern Valley, not the Rhondda. Now "up the hill".
8. `corncrake.json`: the Portree poster sent you "on the Skye and Harris side, out on the machair"; corncrakes are a Hebridean islands bird and Harris is not on Skye. Now "out west on the islands, on the machair".

### Story chains
9. `nym_moorcock.json`: habitat scheme "a modest, steady income for fifteen years" became "ten years" (agri-environment agreements are five to ten).
10. `bushmills_postoffice.json`: "On Mondays nothing is posted anywhere in the town" (the post still goes) became "On Mondays there is no counter anywhere in the town".

### Trade
11. `trade.json` gales_hull stall line: "Nothing has gone out of Hull for days" became "out of the harbour", since Hull's fleet is small now and the event also covers Whitby and the Tyne.

### Enterprise
12. `town_projects.json` Carlisle: "shut on Saturdays since the cuts" (a claim about a real service) became "for a good while now".
13. Kirkwall: "The little ferry across the bay stops sailing in the winter" (reads as a charge against the real Orkney ferries) became "sails only a day or two a week in the winter"; the resident's line to match.
14. Blaenavon: the real Workmen's Hall is a named building and the text said it was boarded up. The project's displayed name is now "Blaenavon Old Miners' Hall".
15. `boat_whitby.json`: "five bass" became "five cod" (bass are not a Whitby day-boat catch).
16. `bnb_portree.json`: "where the ferry passengers look" (Portree has no ferry; there is a bridge) became "where the visitors look".
17. `deed_asks.json` inspector: "Five out of five on the door" and "A four" became "Top marks" and "Good marks". Scotland and Ireland do not use the 0 to 5 hygiene scheme.

## Checked and left alone
- Beavers (River Otter 2014, trial from 2015, stay 2020, flood study), mink (farmed from the late 1920s, five toes), kites (Tudor London, 1930s Wales, 1989 releases), Blaenavon (1789, WHS 2000, Big Pit 1980, Coal Authority), Causeway (1986, Fingal's Cave, the Oonagh tale), Kelpies sculpture (Andy Scott, 2013), pine marten and red squirrel, corncrake payments (cut from the centre, late mowing), seal belly-biting.
- Story chains are balanced: each of the three answers has someone with a decent case and nobody is a villain (the builder, the hotelier, the convenience group and the estate manager each get their reasons). No real organisation or living person is named in them.
- Real bodies used generically and doing true things: the Wildlife Trust (mink rafts, beavers), the Trust at the Causeway (rope, closing the cliff path), the Coal Authority.

## For a human
- Contract lair zones: Old Three-Taps' lair is in the `rhondda` zone while the notice is at Blaenavon. The text no longer says Rhondda, but the placement is a design choice to look at.
- Hull in the gales event and Portree and Kirkwall in the Deeds are real towns with simplified economies; fine for a game, but a Hull or Orkney reader may smile.
- Irish name `Orla Gallagher` (hotelier) shares a surname with Pádraig Ó Gallchóir (Gallagher in Irish). Not an error, but a reader may think they are related. Changing it touches many lines, so I left it.
- Bodmin: I could not verify the Dangerous Wild Animals Act theory against a primary source. It is worded as a theory only.
- Kelpie: the bridle "with a cross on it" is folklore I did not trace to a source.
- Hall minutes keepsake: "four abstained, three said aye, one wrote under protest" does not match the chain's "four against four". Harmless; item text left.
- Some Irish given names (Eilis, Padraig) have no fada in the contract text. Left, as the validator and tests may key on names.
