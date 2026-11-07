# Wave 48 M: new monsters (branch w48-m-monsters)

14 new lines, 30 species, all appendix species (the core 200 is unchanged). The brief asked for silhouettes and
colours that look nothing like the existing dex, so none of these is a round furry animal.

| Line | Stages | Types | Notes |
|---|---|---|---|
| Whorlet | Whorlet, Shellhaven | bog/stone | snail; the second stage has a cottage on its shell |
| Moonbell | Moonbell, Aurelian | tide/night | moon jellyfish |
| Slipknot | Slipknot, Gordian | tide/bog | hagfish, mostly knot (Scottish sea lochs) |
| Gawplet | Gawplet, Argusine | fae/gale | peacock butterfly, all eyespots |
| Brewlet | Brewlet, Brownbetty | hearth/stone | teapot golem (Stoke, Ironbridge) |
| Brammel | Brammel, Bramblemaw | hedgerow/spirit | bramble swarm, summer and autumn |
| Dishwight | Dishwight, Dresserwight | spirit/hearth | boggart in a Welsh dresser |
| Sailet | Sailet, Postmill | gale/iron | post mill |
| Raftlet | Raftlet, Rafterweb | bog/brook | fen raft spider, on the water tables; sexes differ |
| Tattybogle | Tattybogle, Mawkin | hedgerow/kin | scarecrow |
| Dishfin | Dishfin, Moladisc | tide/gale | ocean sunfish, with a gull on the big one |
| Barnaclet | Barnaclet, Barnagoose | tide/kin | goose barnacle that hatches a barnacle goose |
| Leatherjack | Leatherjack, Husk, Longlegs | bog (Longlegs bog/gale) | crane fly in three stages; sexes differ |
| Clocklet | Clocklet, Dandylion, Clockmaster | hedgerow/gale | dandelion bud, lion, clock |

Skipped because the dex already has them: selkie, corncrake, kite, hedgehog, Cornish knocker, a plain boggart.

## What changed
- `art/recipes/creatures/<id>.json` and rendered `art/sprites/creatures/<id>_{front,back,icon}.png` (plus `_f`/`_m`
  sheets for longlegs, raftlet, rafterweb). Recipes were generated with a throwaway script; the JSON is the source.
- `data/creatures/<line>.json` (learnsets, evolutions, dex text, a real fact, `real`, Welsh/Irish/Gaelic names only
  where certain). No `"pieces"` hints were added, since P's game ids were not in my tree.
- `data/zones/*.json`: additive `encounters` entries only (40 zones), one per habitat. Habitats match the tables.
- `data/dex_order.json`, `data/genes.json` (line kindreds), `data/knacks.json` (a knack per species),
  `data/dimorphism.json` (three Fieldbook sex notes).
- `tests/data_api/test_w48_monsters.gd` (8 tests: load, chains, stats, moves, sprites, habitat, sexes).

## See them
`tools/shot.sh out.png 14 --battle=shellhaven:20`, `--menu=pedia:longlegs`. Screens: `docs/screens/w48-m-*.png`.

## For the integrator
- `tools/test.sh` shows as modified in my worktree (an import lock added by something else); I did not commit it.
- Appendix species are the existing convention, so these add Fieldbook appendix pages, not core entries.
