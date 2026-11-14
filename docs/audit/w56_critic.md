# Wave 56, critic: what waves 54 and 55 look like to a player

Read-only pass over the data and scripts (no Godot, no tests, no screenshots). Walked as a new player and as a
late-game returner: the cat's two arrivals, the first coracle moment, the first battle cues and teaching card, the
discovery card, three contracts (mink, bog, kelpie, every branch of mink), two story chains (Gweedore pub, Bushmills
counter), the Trader's Ledger, a Deed's monthly matters and managers, and a town project's three stages. Facts in the
twelve contracts' "real story" fields and the 22 flotsam bottles were re-checked and hold.

## Text fixed in this branch (10 string edits, JSON re-parsed)
1. `data/dialogue/liverpool_club.json`: Ray's Stone speech and the "learned Brook-wade" line now say you can walk into
   any river or lake and a coracle is under you (it said only "deep water can now be crossed").
2. `data/dialogue/galway_docks.json`: "received the Tide Stone!" now adds that Tide-ride paddles the coracle on the sea
   near land (the Galway scene said nothing about the ability at all).
3. `data/deed_asks.json`: "Meet them halfway" said they take the other job, then rolled a 30% risk of the same thing;
   the base outcome now says they stay.
4. `data/town_projects.json`: Whitby plaque said "who was not asked to", but the Skipper asks you; Dingle's ask said
   "pound notes" in an Irish town.
5. `data/legend_hunts.json`: Hairy Hands clue sent the Fieldbook reader to "over Dartmoor", but the creature stands in
   `exe_estuary`, where the map ring is.
6. `data/deed_managers.json`: thrifty blurb ("takes less and keeps a lot more") was unreadable.
7. `core/trade_ledger.gd` (two strings): the Ledger said a glut made fish "cheap" and a shortage made it "dear", which
   reads as buying advice; news only moves what the halls PAY. Now "pays less for ..." and "pays more for ...".

## Findings, ranked (what a player hits, file, fix, size)

1. **Nobody ever tells you that you have a boat.** Brook-wade and Tide-ride were announced as "deep water can now be
   crossed" or not at all; the block hint is the only mention of a coracle, and it comes before you can have one. Text
   now patched (above). Still missing: an Intros card on the first step onto water ("Walk into any river and you paddle.
   Fish from it. Look for things floating.") and one on the first flotsam sight. `core/intros.gd` (two cards, one hook
   each). S.
2. **Contract repute is mostly decoration.** Each choice moves two groups, but the fee only reads the poster's own
   group (`Contracts.fee`, core/contracts.gd:150), and no contract has `wardens` or `keepers` as its poster group (seven
   are `farmers`). So "wardens +3 / -3", the most visible trade-off in all twelve, changes nothing, and "How people see
   you" is a number with no use. Fix: fee uses the mean of the two groups the picked choice moved, or add one shop or
   noticeboard effect per group. One function plus one test. S.
3. **Town projects mostly do not change anything.** Per the enterprise audit, 13 of 15 change the place only through
   standing 4 to 8, one food item, and (7 of them) a 4 to 20 per cent Deed bonus that the Deed screen never mentions.
   Carlisle library costs 5,500 base for standing 4 and nothing else; Whitby costs 37,000 for a parkin. Fix: show
   "Town projects: +4% takings" on the Deed counter (`ui/deed_screen.gd`, from `TownProjects.deed_fx`), and give each
   project a keepsake or a recipe the way the story chains do. M.
4. **The two footbridges are made pointless by the coracle.** `lancaster_mill` (hidden warps 57,34 to 57,42) and
   `inverness_footbridge` (21,34 and 26,34) each cross four tiles of `~` water that any player at the project's badge
   count (4 and 8) already paddles. The ask and stage text promise "no more long way round". Fix: reword the promise
   to what is true (a dry, encounter-free crossing, and the bridge on the map), or put the bridge where water is `o`
   deep or a `no_ride` rect. `data/town_projects.json` text, S; or a zone edit, S.
5. **Story letters arrive in three days and speak of months.** The chains' post lands after three in-game days or the
   next real day (`Quests.later`), but the letters say "first January", "May to September", "three hundred and forty
   shares" and "since Easter". CHANGELOG 5.5.0 says the post "tells you months later". Fix: either the release note
   ("tells you a few days later, in the voice of the months") or lengthen `later_<flag>_3` to 14 days; text in the
   letters is fine if the delay is longer. S.
6. **"Where next?" names roads you cannot walk.** `WhereNext._wander` (core/where_next.gd:64) offers any linked, unfound
   route ("X is just down the road, and you have never set foot there") with no gate check, so a Warden-blocked
   w55 road is advertised from the pause card and the map promises (`MapLogic.promised_towns` has the same blind spot).
   Fix: skip routes where `RideCheck.is_gate`-style NPCs stand, or where the road's gate flag is unset
   (`ZoneIndex` could carry `gate`). S.
7. **Flotsam repeats itself.** 44 non-bottle finds share about ten sentences ("A crate roped to a plastic float",
   "A fish box with a crew's initials", "An eel trap, forgotten and half sunk", each 5 to 6 times), and 20 of 22 bottles
   pay a slate chip or sea glass (price 0, only used in two recipes), often at odds with the place (slate chip from a
   Dingle bottle). Fix: put the zone's name or one local noun into each find's text in `tools/flotsam/gen_flotsam.py`
   and re-run, and pay bottles in an item that matches (honey, a recipe card, a postcard). S to M.
8. **Contracts are all one shape.** Every file is two look-spots plus two witnesses, the first witness is always the wrong
   one ("Fox. It's always a fox"), the second is always the right one, and every end has the same four options with the
   catch ending always costing wardens 2 to 3. After two contracts a player can predict clue order. Fix: in four of
   the twelve, make one witness unreliable about a fact the other clue corrects, and give two contracts a third look-spot.
   Data only. M.
9. **Weather-gated clues can stall a contract.** Kites need a clear daytime, bog needs a wet or foggy dusk, kelpie needs
   rain; `hint_wait` says so but nothing in the Journal says the wait is intended, and a bench does not change weather.
   Fix: the Journal clue row should say "needs rain" in words (`ui/contracts_tab.gd`, from `when`), and the wireless
   forecast should name the lair's zone once. S.
10. **Hairy Hands is a three-step trail with one step missing.** The clue (now fixed) points at the lay-by, but the
    creature only appears at night once `q_devon_letterbox_3` is set, and no rumour says so. Fix: add "once the
    letterboxers have shown you the way" to the clue string. S.
11. **The discovery reward is invisible and the Atlas stamps are tiny.** +2 friendship and a training point say
    nothing on the card (loose-ends item 4 covers it); a half-stamp is a flask of tea and a full region a Kendal mint
    cake. Fix after item 4: make the full stamp a recipe or a wear piece. S.
12. **Long lines.** 145 new `say` or `text` strings exceed 150 characters (105 at 150 to 199, 34 at 200 to 249, six
    over 270: `forsinard_centre` flows_warden x3, `beavers`, `corncrake`, `giant`, `seal`, `puca` clue 1). The box
    pages at four lines, so nothing is cut, but a clue arrives as two or three presses. Fix: halve the six above. S.
13. **Mum asks the same question every day** (`macc_home.json` `cat_mum_offer`, once per day, every day you pass).
    Fix: ask once per cat stage change, or only when the party is full. S.
14. **Three Deed upgrades per kind have no catch**, against the release note's "upgrades with trade-offs": water_butts,
    listings, ice_hold, standing_orders, quay or long lease, show_yard. Fix: give each an `upkeep` or a `use` cost
    (`data/deeds/*.json`) or soften the note. S.
15. **Manager temperaments are dealt by a hash of the Regular's id**, so a warm, wry Regular can be dealt "careful"
    and read as someone else. `assign` in `data/deed_managers.json` is empty. Fix: fill `assign` for the ten
    Regulars whose Mum-tea lines are loudest. S.

Smaller: the block hint names "Keeper Ray in Liverpool" and "Keeper Nuala in Galway" before they are met (fine as a
signpost, but "Brook-wade" names an ability while the tile needs a coracle; say "Brook-wade (the coracle)"); Aberglaslyn
and Llyn Tegid wardens share one line verbatim; `Deed` allotment files for Lancaster and York are word-for-word
duplicates.

## Contradicting the release notes
- 5.5.0 "the post tells you months later how it went": it arrives after three in-game days or the next real day.
- 5.5.0 "Every Deed has upgrades with trade-offs": six upgrades have none (item 14).
- 5.5.0 "Pay in stages; the town changes for good": for 13 of 15 it is standing and a Deed bonus the Deed screen
  never shows (item 3).
- 5.5.0 "Nobody's answer is simply right": the Pooka's "tell Eilis it was the village lads" is a lie with no upside but
  the fee, so it is an answer a player can safely call wrong; that is fine, but the notes read as if all are defensible.
- 5.5.0 lists twenty-eight routes; none is in Northern Ireland (Lower Bann and Erne Shore are unbuilt, loose-ends 7).
- 5.4.0 "179 of the 202 outdoor places" and "a running tally (of 217)": after 5.5.0 the tally is 247 (230 outdoor plus
  17 Deep Places). Nothing in code hard-codes it, so only old notes are stale.
- 5.4.0 "a gold ! near something unfound ... and it now comes indoors": only in rooms of 60 tiles or more (the cramped
  ones keep it outside).

Not checked: anything that needs the game running (feel of the paddle, the sense cue's timing, the Atlas layout).
