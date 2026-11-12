# The shape of the economy (4.0)

How money moves in Wildlore, what the numbers are, and what stops any of it being a tap. The harness is `core/economy_sim.gd`
(prints with `godot --headless --path . -s res://tools/dev/economy_sim.gd -- 20`; pinned by `tests/core/test_economy.gd`).
It plays a perfect, diligent player through a year of in-game days (360; the story ends about day 90, a game day is 24
real minutes) and reads the real numbers from `Jobs`, `Deeds`, `DeedsSim`, `Trade`, `Punt`, `Racing`, `Stud`, `Leases` and
friends. Only the player's habits are assumed, and they are generous, so what holds here holds for everyone. The earlier
harnesses (`MarketSim` for shares, Doggerel and the bureau; `DeedsSim` for Deed payback; `SocietySim` for the Building
Society) still own their corners.

## Money in

| Source | Gate | Size (sterling) | Scales with |
|---|---|---|---|
| Noticeboard jobs | board day (real day, or 4 hours of play) | 100 per job at 0 badges, about 2,200 at 10 | badges |
| Pub quiz | once a real day per pub | 150 or 300, or a cream tea or Whitby Jet | flat |
| Crossword | once a real day | 150 | flat |
| Novice race | once a real day | 400 + 100 per badge for first, 2/5 and 1/5 for 2nd and 3rd | badges |
| Standing at stud | once a real day, after a Breed Class win | half the stud fee: 30 x (100 + 90 badges) / 10 / 2 | badges |
| Show classes, darts purse | once a real day | 10 to 40 | flat |
| Gazetteer, Visitors' Book, quiz league | once | about 44k in all if you explore half the towns | exploration |
| Residents' sightings and photographs | once each (`Wants`, kinds `seen` and `photo`) | 120 to 250, about 6k in all | visiting |
| Deeds | passive, per in-game day, needs stock | see below | badges (price and takings) |
| Cooking and selling dishes | foraging time, glut | a dish is 350 base, 175 at a shop, up to 567 at a festival | flat |
| Trade Ledger | only shop-stocked goods can be bought low | jute fibre: about 990 for a full load at the festival cap | flat |
| Shares, Doggerel, bureau | stake | MarketSim: shares drift up a little, Doggerel loses, the spread eats round trips | n/a |
| Casino, racing | daily stake limit 300 + 450 per badge | negative expectation on every game (RTP tests in `test_casino_games.gd`, `test_racing.gd`) | badges |
| Building Society | credit limit by badges | savings pay a few per cent a year; borrowing to save or sit loses (SocietySim) | n/a |

A diligent real day (four jobs, two quizzes, the crossword, the race, stud) is worth about 1,250 at badge 0, 5,000 at badge 4
and 11,700 at badge 10. Jobs are three quarters of it by the end. The Deeds are the passive engine on top: six archetypes, one
each, pay back in 12 to 20 in-game days at the cheap early price (five to seven hours of play, as designed) and 26 to 58 at the
late price; the last tier of each pays back in 13 to 38. Six Deeds at the top tier take about 6,400 a game day (about 16,000 an
hour of play), less 5 to 8% rates and up to 20% self assessment.

## Money out

Charms (up to 4,200, one per creature), the Trader's Pannier (2,000), rods, Deed prices and tiers (800 to 50,000 each, rising in
bands at 4 and 8 badges), the Building Society's interest, rates and tax, and the big one: the ten Enclosure leases (38k to 90k
reserve, a winning bid about a quarter over, three stages at 8% of the reserve times the stage, weekly upkeep), about 100,000 each
all in, a million for the set. Nothing in the story costs money: the pounds buy comfort and the post-game, never progress.

## What the sim found, and what changed

1. **The Market Halls were a tap.** The sell flow paid `sell_price x quantity` and never recorded the sale, so the glut
   (8% per unit, fading over three days) that the shop screen applies was missing at the halls: 99 dishes in a town that wants
   them paid the top price for every one, again and again. `MarketHall.payout` now quotes `Trade.sell_total`, `MarketHall.settle`
   records the sale, and the hall counts toward the Trader trade (`TrainerStats.sold`) as the shop does. A 99-unit stack now
   fetches under a quarter of the flat figure, and a second visit the same day pays less than the first.
2. **A recipe turned shop twine into three snares.** `jute_snare` (2 jute fibre from a Dundee or St Andrews shop, 36 each at
   home) made 3 wicker snares that sell for 100 each: a 4x return on a craft you can repeat. It now makes 1 snare for 2 hanks and
   40 for the twisting, which is still a saving on the 200 shop price but no longer pays to sell on.
   `EconomySim.recipe_loops` fails the test if any recipe made wholly of shop goods ever sells for more than it costs.
3. **No change, by design:**
   - Deeds snowball, and are meant to. A diligent saver has about 146k by the credits, a Deed player about 320k.
   - The sink is the leases: with all six Deeds at the top tier and the Ledger worked, all ten take about 45 game days after
     the credits (18 hours); a pure saver buys five by day 175 and all ten by day 315. If post-game ever feels too cheap, the lever
     is the lease reserves (the design range is 30k to 150k and the average is 58k) or a fourth stage, not the Deeds.
   - Cooking is the best early income per minute (1,000 to 2,200 a real day at badge 0 against 400 for jobs) and fades as
     jobs scale; it is under a third of a year's earnings in the richest career.
   - The daily quiz is flat money and so a good early help, a rounding error by badge 4.
   - Casino and racing lose on average with a daily limit; the sim stakes the whole limit every real day for a year and loses.

## Guard rails (all in `test_economy.gd`)

No all-shop recipe profits; the hall cannot be flooded; the one stocked-and-listed good is a modest run; the daily purses other
than jobs stay within 1.5x of jobs and a first day pays well under any Deed; the casino loses over a year; Deeds at most about
triple a saver's cash by the credits and nobody is rich a month in; all ten leases never land inside 30 days of the credits
for the richest career (60 for five, for a saver); and cooking stays a minor share of lifetime earnings.
