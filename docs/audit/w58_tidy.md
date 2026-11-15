# Wave 58 tidy

1. **`blocked repeatedly at (1, 16) in lake_district`**: the bot's planning, not a game bug. Lake District has no west
   edge of its own; the Armboth Forestry Block lease (`data/leases/armboth_forest.json`, side west, gap at 15, width 3)
   adds one and digs a track at (0..1, 14..16). While the lease is unowned, `Leases.apply` fences the border tiles and
   puts a blocked "Private land" sign at (1, 15). A player can reach (1, 16) but is stopped by the fence and sign, as
   intended. The bot's routing zones were built without `Leases.apply`, so it planned through the gap and walked
   into the sign. Fix: `_routing_zones` blocks an unowned lease's border tiles and sign tile. No edge arrival, `landing_near`
   or route offset is involved (keswick, lancaster and swaledale offsets are all 0 and land on open ground). No test: not a game bug.
2. **`_bad_grind` sticky**: `_pick_grind_zone` clears it whenever the flag hash differs from the one it was built under.
3. **Largest text, `--readable`**: 0 problems on 129 screens. **`--stress`**: 14 problems, now 0:
   - pairing pick/cross/predict (12 x "MW" nickname): at Largest the "female, ark" note is "ark" (the sex mark already says it).
   - bag:chapbook picker: the can/knows tag is 18 px nominal at Largest.
   - races (and the other casinos): "Today's limit" reads "Limit" at Largest.
4. **`tools/zones/recipes.py`**: no longer writes Mum's scene (and `MUM_SCENE` is gone); the docstring marks that part
   retired. The teacher-placing half is untouched and not re-run.

Left: minigame `draw_string` text and popups/HUD still not covered by the audit at Largest.
