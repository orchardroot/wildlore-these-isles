# Wave 53 "looks" (issue #144): every home gets one thing of its own to look at

## What was built
- One authored `examine` spot in each of the 166 interior home zones (ids with `home`, `house` or `cottage`), two to
  four short lines about what the resident actually talks about, on an existing prop tile. Two (`belfast_palmhouse`,
  `dublin_customhouse`) already had one and were left as they were. `testbed_house` (an empty test room, no props, no
  resident) is skipped by the rule below, so 165 are covered by new or existing spots and 163 are new.
- 41 spots carry a small once-only `find` (modest existing materials, charms or snacks: sea glass, peat, slate chip, sheep
  wool, hawthorn berry, a leek, a cup of tea...) or a `flag` (named `looked_<thing>`, nothing reads them yet, so a later
  letter or trade can).
- `core/home_looks.gd` (`HomeLooks`): what counts as a home, the uncovered list, and an error check (a `find` that is not a
  real item, an em-dash in the text). `tools/validate.gd` gets two lines: it prints `validate: warning: N home(s) have no
  examine spot` (a warning, not an error) and appends the `HomeLooks.errors`.
- `tests/core/test_home_looks.gd`: the coverage rule, the checks, every real home covered, and the "about a quarter carry a
  find or flag" band.
- `world/overworld.gd`: one dev switch, `--examine=x,y`, reads that spot at once (next to `--search=`), for screenshots.

## How the data is kept
`tools/zones/home_looks.py` plus the tables `tools/zones/hl_<nation>.py` (zone -> prop type, lines, optional find or flag).
Run `python3 tools/zones/home_looks.py` from the repo root: it appends the `examine` key as text at the end of the zone
file (so the rest of the file's formatting is untouched) and skips any zone that already has one. It is a one-off
authoring helper; the JSON is the source of truth. To change a spot, edit the JSON directly.

## How to see it
`tools/shot.sh out.png 30 --boot=thurso_cottage@5,2 --examine=5,1 --clock=12:00`. Screens in `docs/screens/`:
`w53-looks-belfast-riveter.png`, `w53-looks-thurso-gunns.png`, `w53-looks-bath-herschel.png`.

## Notes for the integrator
- Only the `examine` key of home zone JSON was added (always the last key). The rooms session keeps today's props, and the
  spots sit on the prop types listed in `hl_*.py`. If rooms moves a prop, check the spot still sits on something: the
  zone validator already errors if a spot is blocked off.
- Spots are on solid furniture (fireplace, dresser, bookshelf, table, wall picture, trophy shelf...). `thurso_bakehouse` uses
  the fireplace because the dresser sits behind the counter.
- Homes with no real furniture got something stand-in: `plymouth_homepark` (a stadium) uses a flagpole, `pit_boathouse`
  and the two lighthouses use their chart or telescope.
- `bath_home2` mentions the old telescope but the room has none today: the rooms session may add one. The spot is on the
  bookshelf, so it does not depend on it.
- Facts left out when unsure: exact dates for Fungie's arrival at Dingle (1983 or 1984), the height of the Poolbeg
  chimneys, how many miles of canal Birmingham has against Venice (the text only repeats the family's claim), the exact
  Oxford versus Cambridge punt-standing rule, and any claim about where Handel landed in 1742 (Wirral boathouse). Each
  of those homes uses a simpler true statement instead.
