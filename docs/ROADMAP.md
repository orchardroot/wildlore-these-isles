# Wildlore: These Isles, roadmap

The game is meant to be looked after for years. This is the running plan beyond whatever release is in progress. The
reasoning behind it (what the game is now, the economy design, depth, minigames, the name) is in
[docs/design/2026-10-21-deeper-wildlore.md](design/2026-10-21-deeper-wildlore.md). Work items for the next release are
GitHub issues labelled with its milestone.

The identity line everything is judged against: **a walking holiday round the real Isles that turns into a life
there.** A feature belongs if it makes a place more knowable, makes the player more of a local, or makes the land
richer.

## Done
- **3.0 Wider Isles**: the walled-off edges opened, 72 towns, quests, 900+ plaques and the Gazetteer, 131 regional
  creatures, euros and markets, the casino and Aintree, par-level scaling.
- **3.1 Seasons & Streets**: local architecture for the original towns, real-date festivals, regional cooking, home
  souvenirs and garden, weather that matters.
- **3.2 Shetland and Small Mercies**: Shetland and Up Helly Aa, yearly festivals, the game says why it won't do things,
  visual fixes.
- **3.3 Overseas**: RAF Brize Norton and 18 overseas destinations, Jersey, Guernsey and Sark, real currencies; the game
  renamed Wildlore: These Isles.
- **3.4 Market Day**: place-set prices, 25 real market halls, the Building Society, Trades, fishing, Windows and Linux
  builds, report-a-bug, CONTRIBUTING.
- **3.5 Open for Business**: Deeds (a chippy, a B&B, a boat, a stall), rates and the HMRC envelope, twelve Regulars,
  darts, crabbing, the allotment show and sheepdog trials.
- **3.6 Good Stock**: real genetics and breeding, hybrids where they happen, the Roslin Institute, the Stud Book.
- **3.7 Behind Doors**: examine spots, locked doors and hidden rooms, Deep Places (Blue John first), the Casebook,
  guilds, the lead creature lending a hand, bells and walling.
- **3.8 and 3.9 The Long Game and Long Roads**: the Enclosure leases, a long arc for each nation, the quiz league,
  Highland games, hurling and shinty, shanties, conkers, NPC routines, the Year in the Isles epilogue.
- **4.1 Voices of the Isles**: the local language where it's spoken, regional music, accessibility (text sizes, the
  readable font, easier minigames), postcards and the weekly challenge.
- **4.2 Far and Wide**: local time abroad, regional forms of creatures, more overseas places.
- **4.3 Deeper**: four more Deep Places, four more Casebook mysteries, nine more festivals.
- **4.4 Settling In**: the Almanac, Where next?, gentle hints, fairer market money, tidier settings; save fixtures from
  every released version load in the current build.
- **4.5 Learn as You Go**: smoother creature art, optional lessons in Welsh, Gaelic, Irish and Scots, 33 evolutions,
  biology challenges, People of these isles, how these isles work (politics, economics, borders, invention).

## Now: 4.6 Dressed for the Weather (docs/briefs/wave46.md)
- **Your own character**: male or female, skin tone, hair style and colour, chosen at the start and changed at the
  mirror at home or in the Wardrobe; clothes of these isles bought in fourteen boutiques (Harris Tweed, Fair Isle,
  Aran, Welsh wool, flat caps, kilts, wellies and more) and worn in the world, on the VS card and in photos.
- **Male and female creatures** shown wherever a creature is named, above all on the summary screen and when
  breeding; real dimorphism in the art for forty-odd species.
- **Seven more minigames** at the places they really happen: crown green bowls, stone skimming at Easdale, the
  seaside arcade (2p pusher, claw, penny falls), cheese rolling at Cooper's Hill, bog snorkelling at Llanwrtyd Wells,
  welly wanging, curling, and Cumberland and Westmorland wrestling at Grasmere.
- The approved Welsh lessons and wave 45 facts go live; the Dee Valley fuzz failure is fixed.

## Then (candidates, in no fixed order)
- **More of the Isles to wear and own**: outfits as rewards from quests and festivals, a few haircuts only a
  particular barber does, NPCs who remember what you wore.
- **Minigame leagues**: the darts league pattern for bowls and curling, and a fete circuit through the summer.
- **Localised building styles** for the towns 3.1 didn't reach, regional items and local curiosities.
- **A fresh first-hour audit** with the character creator in it, and the periodic scan for anything too close to
  Pokémon.
- **Android**, once touch controls and a small-screen UI pass exist (see Parked).

## Parked
- **Android**: Godot exports it easily, but it needs touch controls and a UI pass for small screens first.

## Long term (not in the current version)
- **Multiplayer.** A PvP battle server: link battles between friends, ranked play with sensible rules (level caps, banned
  items), spectating.
- **Trading.** Trade creatures between players (with evolution-on-trade and anti-cheat checks on what is traded), and
  a way to share Fieldbook progress.
- Needs: an account or friend-code system, a server (Cloud Run fits what we already use), save integrity checks so
  traded creatures are legitimate, and a protocol that keeps battles deterministic (the battle engine already runs
  from a seeded Rng).
