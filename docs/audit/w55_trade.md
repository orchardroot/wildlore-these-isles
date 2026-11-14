# Wave 55, trade: buying low, selling high, and knowing why

Branch `w55-trade` (from `int-w55`). Owns `core/trade.gd`, `data/trade.json`, `core/market_hall.gd`, `core/trades.gd`, the
Market Hall screen, and the new `core/trade_news.gd`, `core/trade_orders.gd` and `core/trade_ledger.gd`.

## Where trading was dull

Played on paper (the sim, the Ledger data and the hall code) before changing anything:

1. **Nothing told you where to go.** The wireless's Money Box said "X is cheap in A and keenly wanted in B" about a random
   good every day, whether or not you had any. The prices at the halls were the same every week, so a good run was a rule you
   learnt once (smokies to Cardiff) and then repeated forever.
2. **No reason to hurry.** Dishes keep eight days and fish three, but nothing paid you for arriving early or fresh, and no one
   was waiting for anything.
3. **The Ledger had no memory.** The hall board shows today's price and forgets it; there was no page that said what you had
   seen where, what was in season or what in the bag was about to go off.
4. **The Trader trade was only a percentage.** Levels 3 and 5 paid 5% and 10% more at shops. Nothing opened.

## What I changed

### Trade news (`core/trade_news.gd`, `data/trade.json` "news")
Fourteen real-place events, each with a kind (`glut`, `shortage`, `widen`), where it bites (towns or trade regions), what it
moves (items or kinds), a size (0.65 to 1.45), how many days it lasts (3 to 6) and how many days ahead it is announced (0 to
2). About three start each in-game week, picked by a seeded hash of the day (so the same save reads the same news twice);
events with `seasons` only come in their season (a late frost in spring, gales in autumn and winter, Edinburgh's festival
crowds in summer). Examples: herring glut at Lerwick (Aberdeen, Inverness and Stornoway sell fish cheap), gales keeping the
Hull boats in (the north east is short of fish), a late frost on beans and peas, the Rhubarb Triangle in full cry, a poor root
harvest, Galway race week, freshers arriving, a big day at Croke Park, a smokie shortage, and a **rail strike** that widens
every spread (dear goods dearer, cheap goods cheaper) and gives orders a premium for getting through.

Effect: a multiplier on the **selling** price only (`Trade._sell_unit` takes a `news` argument). A boost may lift seasonal
demand only up to the existing cap (1.8) and never past it; a glut always bites. So buying and selling in one place still
never pays (tested over three seasons, 44 days, every hall and every listed dish).

Where the player hears it:
- **The wireless** (`Trade.money_box`): up to two bulletins a day (three on a Monday), as "Today:", "Tomorrow:", "In 2 days:" or
  "Still going:". No overworld edit: `money_box` was already the hook.
- **The stall-holder** at a Market Hall says it in their own voice as you walk up (`MarketHall.talk`), or tells you of an order at
  another hall.
- **The price board** says "in the news: short of it" or "in the news: a glut" next to the item.
- Hearing something is remembered (`trade_heard`), so the ledger lists only what you were told.

### The Trader's Ledger page (`core/trade_ledger.gd`)
An Almanac page (`ledger:trade`, "Trader's Ledger", after Trades) with: the news you have heard that still matters (where, what,
how long); orders heard of; the last six prices you saw and how old each is; the widest gap between two towns you have seen
the same good in; what is in season (the Ledger's own seasonal list); and what in your bag is about to go off (days left,
"a bit off"). It remembers prices when a hall's board is shown (`trade_seen`, 60 entries, the stalest forgotten). There is no
all-seeing list: a fresh save's page names no town. The page shows once there is anything to say, or for any save that has
sold goods before.

### Orders (`core/trade_orders.gd`)
Each hall posts an order about one day in four (seeded) for a dish or a British fish its region is short of and the corner
shops do not sell (so nothing can be bought low and delivered): 2 to 6 of it, open for 8 days. A delivery pays what the hall's
own board would pay (so news, season and glut all count) times a premium: 1.10 as a guaranteed buyer, +0.15 if inside three
days of posting, +0.10 if fresh, +0.15 while a rail strike is on. At most 1.5. It is a sale in that town, so it builds the glut,
and it counts toward the Trader trade. **Three deliveries an in-game day at most**, one fill per order, no promise needed.
How you hear: the wireless (one a day), a stall-holder at another hall, the hall's own board. At the hall the order shows
above the goods; Pick delivers if you have them.

### The Trader's standing (`core/trades.gd`)
New perks on the existing Trader trade, none a percentage (the 5% and 10% shop top-ups stay):
- **Level 2, early word:** you hear the news two days before anyone else.
- **Level 3, a bigger pannier:** 15 more of a trade good in the pack (45). The 2,000 Pannier is still the best (99).
- **Level 4, credit at the markets:** a hall will advance a quarter of an order's worth before you have the goods. One advance at
  a time; an advance on an order you let lapse becomes a debt that comes off your next delivery, and no new advance while you
  owe. So credit is a loan, not money.
- **Level 5, a pitch of your own on market day:** every Saturday of the in-game week, the first twelve of a good at each hall sell
  at the glut-free price and build no glut.

## Where it is in play
Wireless (Money Box) and any Market Hall for news and orders; the Almanac (pause menu) for the ledger; the Stats page's Trades card
for the perks. A late save with goods sold sees the ledger at once and the Trader perks at whatever level it has already earned.

## The economy simulation (`tools/dev/economy_sim.gd -- 20`)

The sim's trader strategies now read the news and take an order a day: `EconomySim.dish_pay(haul, traded)`. Habits (all generous,
all named at the top of `core/economy_sim.gd`): the dishes in the bag are what the news says is short somewhere on 30% of real
days (+35% before the cap); the first four dishes of the day are an order's and earn the whole premium (1.35); the order shares the
town's glut, so it is not credited with a second outlet.

| | before | after |
|---|---|---|
| Dishes a real day: where you stand / hauled | 1063 / 2201 | 1063 / 2201 |
| Dishes a real day, hauled with news and orders | n/a | 2927 (+33% on a haul) |
| Shop-stocked goods, a full load at the festival cap | jute 990 | jute 990 |
| Cooking earned over the year, trader strategy | 264,120 | 351,234 (22% of all earned, under the 30% guard) |
| **First lease (every strategy)** | **day 81** | **day 81** |
| Trader: five leases / all ten | day 144 / 261 | day 138 / 249 |
| Everything: five leases / all ten | day 87 / 132 | day 87 / 129 (the guard is 120) |
| Deed rush, dailies, cook, casino | unchanged | unchanged (they do not trade) |
| Trader cash at day 30 / 78 / 90 / 180 / 360 | 20,302 / 208,561 / 66,816 / 62,436 / 412,382 | 27,561 / 227,435 / 88,595 / 3,765 / 495,997 |

The first-lease day does not move (it is 81 in every strategy, set by the jobs and the badges). Day 90 and 180 cash for a strategy that
buys a lease jumps about with the day a lease lands, which is why those columns are noisy; the day-78 and day-360 columns are the
honest ones. The bounds are in the data, not in the sim's generosity: three deliveries a day, shop goods excluded, premium at most 1.5,
the pitch twelve units a hall, the advance a quarter and repaid.

Full before and after output is in the session's scratch (`sim_before.txt`, `sim_after.txt`); the lines above are copied from them.

## Test results
- Full suite (`tests/run_tests.gd`, once, before the last small edits to the ledger's row text and the sim's habits): `3127 passed, 1 failed`. The one failure
  is `test_text_fit::test_worst_screens_fit_with_large_text_and_the_readable_font` on the `races:dev` screen at Large text (the racing screen's right-hand
  column is off screen); nothing in this session touches it, but I did not run the base branch to prove it was already failing.
- After the last edits: `tests/run_tests.gd -- trade`: `59 passed, 0 failed` (this wave's 28 plus `test_trade`, `test_trades`, `test_market_hall` and the rest
  that match); `-- economy`: `8 passed, 0 failed`.
- `validate: 0 error(s)` (it now also runs `TradeNews.problems()` and `TradeOrders.problems()`).
- `text_audit: 0 problem(s) on 3 screen(s)` for `almanac:ledger:trade`, `market:leeds_kirkgate` and `stats:trades`.
- `tools/playtest.sh slice 2` was not run: nothing here changes the main road, the first hours or a solid tile.

## Tests written
`tests/core/test_trade_w55.gd`, 28 tests: the news data is sound; about three events a week and the same every time; a glut lowers a
price where it says and nowhere else; a shortage raises it but never past the demand cap; a strike widens the gap; buying and
selling in one place never pays under any news (three seasons, every hall and dish); the Trader's early word; the wireless and the
stall-holder carry the news and the player remembers it; a fresh ledger names no town; the ledger's memory, its age, its cap and
its widest gap; what is about to go off; a late save sees the page; orders seeded, wanted where posted and never shop goods; they open
for a week; delivery pays the board plus the premium and builds the glut; fast and fresh pay more; the strike adds to the premium; three
a day; the goods are needed; credit is a loan; a lapsed advance is repaid from the next delivery; the perks; the pitch; every new flag
absent on an old save and surviving a JSON round trip.

## Unsure, and notes for the integrator
- **`hash()` and the calendar.** The news and orders are seeded with GDScript's `hash()` of strings, deterministic within an engine
  build; a Godot upgrade could reshuffle which day has which news (harmless, nothing is saved but what you heard). News with `seasons`
  follows the real calendar like the rest of the Ledger's seasonal demand.
- **Orders do not need accepting.** I chose a hall board you simply deliver to, with the wireless and stall-holders as the way you hear
  of far-off ones, rather than a take-it-and-travel quest. The routes and the coracle matter through the speed premium (three days from
  posting) and the strike premium; the order does not name a start hall, so no route is forced.
- **Credit** is a loan against an order, the only reading of "credit at a market" I could make without a second price list. Worst case
  a player takes one advance and never delivers: they keep it and cannot borrow again until a later delivery repays it.
- **The pitch** is market day (Saturday, `day % 7 == 5`), in-game days.
- **Shared files touched beyond new ones:** `core/almanac.gd` (one page: three constants, `sprouted`, `blurb`, `ledger`),
  `tools/validate.gd` (two lines), `tools/dev/text_audit_body.gd` (one screen), `tests/` (new file only). I did not touch
  `world/overworld.gd`: the Money Box already runs there. `ui/market_hall_screen.gd` gained the order rows and the stall-holder's talk.
- The Almanac constants are one line each, so a merge with another session adding a page there will conflict in those lines.
- No screenshots were taken. The machine was heavily loaded by other sessions' imports, so `tools/test.sh`'s own import was skipped and the
  suite was run with `tests/run_tests.gd` against a cache copied from the main checkout; the class cache gained the three new classes
  by hand. CI will do it properly.
- I killed one other session's `--import` process by mistake while clearing a stuck import (pid 12856, in a sibling worktree). It was
  restarted by its owner.
