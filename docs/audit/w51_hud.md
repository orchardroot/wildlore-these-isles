# Wave 51: the overworld HUD and sign sight, on the merged build

Session "w51-hud", branch `w51-hud` (from int-w50, every w50 branch merged). It follows up w50-tf-world's HUD and
sign work and w50-critic's finding that the Standing toast landed on the zone card and ran off the right edge. Each
shot below was a `tools/shot.sh` run (`open -g`, no focus taken, quits by itself) and was looked at.

## How it was checked

- **`--shot-from-zone`** (new): the shot's delay counts in real seconds from the first zone entry, not from launch.
  On this machine a cold load takes 10 to 25 s, so a toast that lives three seconds was hit or miss before.
- **`--hud=<what>`** (new, `ui/dev_hud.gd`): holds HUD boxes up with the longest words each can get in play, and
  writes `<shot>.hud.txt` listing boxes that overlap or leave the screen (`--hud-check` writes it for any shot).
  `all` is the zone card, route chip, place chip, Saved toast and F9 report toast at once; `news` the same with a
  parish toast instead of the card (in play they take turns); `toast:<n>` each kind of parish news at its longest;
  `talk:long|name|choice|many` the dialogue box at its worst. With `--text-check` (w50-tf-world) beside it.
- **`--text=large|largest` and `--readable`** (the same lines as w50-tf-large, so they merge cleanly).
- **`--backdrop=<zone>`**: picks the title screen's backdrop.
- **Signs:** `tools/dev/sign_audit.gd` over all 1539 signs, now with props counted (below).

## The toast that ran down the screen

On this merged build the first-arrival Standing toast waited for the name card as w50-tf-world intended, but it
was 840 x 700 px: a wrapping Label works out its height from the width it has at that moment, which was none, so it
measured one word a line and the panel ran to the bottom of the screen (`docs/screens/w51-hud-toast-before.png`).
`ParishToast.lay_out` now gives the body its wrap width before the panel is measured, and narrows a wrapped line
while that keeps the same number of lines, so two lines come out even and no word sits alone on the last
(`w51-hud-toast-after.png`).

Checked by screenshot: first arrival in York, Cardiff, Inverness, Dublin, Galway, Douglas and Stanley (card, then
toast), York with the Standing, Gazetteer and New quest toasts queued at once (one after another, none on the card),
and all eleven kinds of parish news at Large text (`toast:0` to `toast:10`: Standing, a tier line, Job ready, Job
done, Euros, Gazetteer, Gazetteer milestone, Poets' Corner, Quest complete, Timeline of Invention, New gadget).

Also fixed in the toasts:
- "Someone in Britain Overseas has noticed you" (Stanley). It says "out here" now (some of that standing is Spain,
  Cyprus or Oxfordshire), "in the Channel Islands" (not "in The Channel Islands") and "among the Kin Abroad".
  The line also gets its full stop.
- Gazetteer prizes read "£10000"; they use `Wallet.fmt` like every other price ("£10,000").

## HUD boxes together

| Problem | Fix |
|---|---|
| A wide route chip ("To Boston (Massachusetts) · 12 to go", or any route at Large text) ran under the zone card and under a wrapped toast | The chip steps down below whichever reaches across it and back up after (`RouteChip.clear_y`) |
| Walking into the next town while a toast showed put the name card under it | The toast steps aside for the card and comes back after it |
| The Saved toast and the F9 "Reported" toast share the bottom-right corner and lay on top of each other | They stack; while a dialogue box covers the bottom of the screen they go top right |
| Saved/Reported/Photo saved stayed 22 px at Large text | They follow the Text size |
| Photo mode hid only the zone card: the route chip, the place chip, news and the Saved toast were in the photo | All of them tuck away and come back |

`--hud=all` and `--hud=news` report nothing overlapping or off the screen at normal, Large and Largest text
(Galway, the dark Blue John Cavern for the cave light). The darkness is a layer under the HUD, so it never dims a
toast or chip. There are no follower speech bubbles as such: the follower's mood line is a dialogue box (covered
below) and a trainer's "!" is a 3D label over their head, clear of the HUD.

## Signs: props in the sight check

`SignSight` only knew about buildings, so a lamp post, a tree or a phone box between a name and the camera went
unnoticed (London's Vane Tower lost its O to a lamp post). It now takes the props standing up to eight tiles south
of a building, at least a metre tall: a thin one (a lamp post, a flagpole) by its whole box so rays a column apart
can't slip past, the rest by their mesh. Prop positions ride on the MultiMesh node as metadata, because a headless
MultiMesh can't give its transforms back. Zone build time is unchanged (London 384 ms, York 424 ms, within noise).

| | Signs cut from their own door |
|---|---|
| int-w50, buildings only (as w50-tf-world counted) | 5 |
| int-w50, counting props | 61 |
| Placement that knows about props | 11 |
| After the fixes below | 1 (Carfax Tower, 9%, reads whole on screen) |

- London: the lamps either side of the Vane Tower's door stand a tile further out.
- Llangollen: the harp moves along the Eisteddfod Pavilion's front, off its name.
- Thurso: the phone box steps off the Meadow Well. Low hedges instead of the one tree in front of the boards at
  Thurso station, Blackpool North, Shrewsbury School and Glenashen's Ruined Cottage.
- A building without a door got its board on posts at mid-front, which is where you stand to read it, so your
  own sprite covered it (the Finnieston Crane, the Spanish Frontier Post). It goes to one side now
  (`w51-hud-sign-before.png`, `-after.png`).
- Boards on posts are tried with 33 sight lines, as finely as the audit looks (15 let a lamp post slip between).

The five partly cut signs from w50: Tŷ Te, Lord Street Tea Rooms, the Spanish Frontier Post and the Finnieston
Crane now read whole; Carfax Tower is the one left (a building five tiles south takes 9% from the door; the
screenshot reads "CARFAX TOWER" whole). A follower can still stand in front of a board for a moment.

## Title screen

The bunting strung in front of Macclesfield's Silk Museum crossed its fascia from the title's higher camera. It
hangs two tiles further out (`w51-hud-title-before.png`, `-after.png`); in play it still reads.

## Dialogue box

| Case | Result |
|---|---|
| A long line (`talk:long`, and Tiger Bay's plaque via `--talk=sign:18,33`) | Pages at sentence breaks; fine at normal and Large |
| A choice with a speaker (`talk:choice`, Keeper Maud via `--talk=maud`) | Fine |
| A very long speaker name (`talk:name`) | The tab grows to fit; fine up to Largest |
| More choices than fit (`talk:many`, 14 stations) | **Ran off the top of the screen.** Now a window of as many as fit (7 at normal), with arrows, scrolling with the selection (`w51-hud-choices-before.png`, `-after.png`) |
| Large text | **The box ignored it** (30 px text, 26 px tab, 28 px choices whatever the setting). All three follow the Text size now |
| Readable font | **Never showed on a fresh launch.** Settings changed `ui/theme.tres` at startup while nothing held it, so it was freed and the first screen loaded it plain. `Settings` keeps the theme loaded; the Atkinson font now shows in the box (and everywhere else that uses the theme) |

## Tests

`tests/ui/test_hud_fit.gd` (new: a long toast is a two-line panel, even line breaks, the route chip's clearance),
`test_dialogue_qol` (choice window and rows), `test_signage` (a lamp post blocks a sight line), `test_access` (the
Readable font outlives the first load), `test_first_hour` (the Standing line's wording), `test_gazetteer` (£10,000).
