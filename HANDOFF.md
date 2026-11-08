# w49 portraits

## Built
- `ui/portrait_motion.gd` (PortraitMotion): a tiny canvas-item vertex shader (shift, squash about the feet) plus `frame_for`, the pure maths over `Motion.idle`. One ShaderMaterial per picture, three uniforms set per frame, no allocation in the loop.
- `AnimSprite.animate(species)` makes a front picture idle in its Motion style. Silhouettes, icons and unseen entries stay still.
- Hooked into: Summary, Fieldbook entry (caught only), new-entry popup, relearn screen, nickname screen, starter picker. Party list icons, pairing and rumours stay still.
- Reduce Flashing: travel scaled by `Settings.flash_scale()` (0.3) and the clock slowed to 0.4x, so flutter does not shimmer.
- Portraits travel at 0.7 of the battle amount, and a floater's lift is subtracted so it rests where the art was drawn.
- Per-sprite phase from the species id, so a row of the same style does not move in lockstep.

## See it
`tools/shot.sh out.png 30 --menu=summary:0`, `--menu=pedia:snowhare` (hop), `pedia:linenwisp` (flutter), `pedia:haarling` (drift), `pedia:bullmoose` (stomp). Shots in `docs/screens/w49-portraits-*.png` (single frames, so the motion is a mid-cycle pose).

## Notes
- Touched other files by a line or two each: summary_screen, pedia_screen, pedia_popup, relearn_screen, name_entry, starter_picker (one `animate` call each).
- Tests: `tests/ui/test_portrait_motion.gd`.
