# Overnight resume notes (2026-10-22)

Installed: 4.4.0. Next release: 4.5.0 "Learn as you go" = wave 45 (docs/briefs/wave45.md), base origin/polish-4.4.

Branches (origin):
- Done/handed off: claude/w45-p-welsh, q-irish (data/lang/lessons/<code>.json), r-fieldbook (+ cloud wiring), s-audit,
  e-gaelic, f-scots (done, CI green; both carry a "STUB" langs.gd commit to drop if D's lands), i-economics, m-borders, o-crossbreeds.
- Cloud continuations (CLOUD_SESSIONS.md, /tmp/wl/handoff_launched.txt): e f g h i j l m n o + t-arts, u-land, v-fixes, r-fieldbook.
- Local agents still running at 03:50: a-sprites, b-graphics, c-evolutions, d-language, k-life (worktrees in .claude/worktrees/w45-*).

Integration plan: new worktree off origin/polish-4.4; /tmp/wl/integ2.sh DIR polish-4.4 <branches> in order
d, p, q, e, f, (drop STUB commits), c, r, n, o, a, b, g, h, i, j, k, l, m, t, u, v. Then: README 4.5 section,
bump to 4.5.0, push, PR (CI = tests), dispatch story.yml on the branch, merge, tag v4.5.0, /tmp/wl/install440.sh pattern.
Owner decisions: leveret = brown hare; capercaillie x ptarmigan and toad crosses stay refused. Lessons light, only in their country.
