# w50 battle playback audit

The owner: "the HP bar reduction being visible before the move hits is still a problem", and battles need polish.
This is what I checked in how a battle plays back, what was wrong, and what I left.

## How playback works
`Battle.take_turn` works the whole turn out, then `BattleScene.play_events` plays the event list back: for each
event `hud.on_event` (stat pills, crit flash, numbers), then the cue (`BattleFX.play`) runs alongside its text lines,
and the next event waits for both. So a creature's own `hp`, `status` and `stages` are already the end of the turn
during playback. Anything a plate reads from the creature shows the future.

Every plate write a cue makes now goes through `BattleFX.plates(cue, battle)`, which only reads the cue (so the event).
The end-of-batch `hud.sync` is a safety net that the new test proves changes nothing.

## Traces
Temporary `Time.get_ticks_msec` prints in `fx.play`, `Plate.tween_hp`, `hud.on_event`, `msg.say`, `animate_xp`,
run with `--battle=<species> --battle-auto` via `open -g` (never takes focus): a wild single (spikkin 8, seed 3),
a 2v2 (spikkin 12 `--double`, seed 5), a multi-hit loss (starlet 12, seed 4), a prick knockout (spikkin 9, seed 6)
and a win to the end screen (starlet 10, seed 8). In all of them the bar tween starts on the hit cue, after the
attack cue. So the plain path was right; the owner's case is one of the others below.

## Checked, by path
| Path | Verdict |
|---|---|
| Plain hit, crit, super/not very effective | In step: number, flash and bar start together on the hit cue. |
| Projectile and shaped attacks reaching the target before the hit | **Bug**: song (14 damaging moves) burst before its first note landed and its notes kept arriving 0.3 s into the hit; wave (27 moves) and Tidal Surge trailed by about 0.2 s. Fixed. The other 12 shapes and 15 signatures land in time; party pieces end on their shape. |
| Item (tea etc.) on the active creature | **Bug**: the bar went to a guess (`hp_after_item`: end hp plus later damage) that missed recoil, pricks and heals later in the turn. In doubles a tea on the partner showed its own recoil or prick damage before its move hit. Fixed: the item event carries the hp and status it left. |
| Item cure (smelling salts etc.) | **Bug**: the chip only cleared at the end of the batch. Fixed (same event fields). |
| Item on a benched creature | **Bug**: the heal sparkle played on the creature on the field (singles). Fixed. |
| Switch-in hit later in the turn | Fixed earlier today (hp in the event). |
| Switch-in statused later in the turn | **Bug**: its chip showed on arrival. Fixed: the switch carries its status. |
| Team cure (Lavender Bag) | **Bug**: only the user's chip cleared, and a cure of everything would wipe a fainted partner's chip. Fixed: the event names the positions cured. |
| End-of-batch sync | **Bug**: it compared with the bar mid-drain and restarted the last hit's drain at 0.25 s. Fixed: compares with where the bar is heading. |
| Level-up | **Bug**: the new max landed before the HP it brought, so the bar dipped then rose. Also "gained XP" set the plate's level before the bar had filled. Fixed: bar and max grow together, the level goes up with the bar. Not the turn-order issue the brief suspected: XP is only given after a batch has played. |
| Meal stat buff | **Bug**: its pill appeared a turn late (the sync). Now a charm-style event. |
| Status damage, recoil, self-hit (muddled), drain, self-heal, regen charm, healing knacks, switch-out knack heal, foe tea, thorns and prickly | Correct: each event carries `hp` and its cue moves that plate. Pricks and heals had no number: now "-3" on the attacker and a green "+6". |
| Multi-hit | **Bug**: on a knockout, "X fainted!" came before "Hit once!". Fixed in the engine. Back-to-back blows restart the drain from where it is, which reads fine. |
| Faint | Bar empties first. **Polish**: the plate now fades with the creature (it sat at 0 HP until a replacement, and in doubles for the rest of the battle). |
| Faint then forced switch | Separate batch; the new plate slides in. Correct. |
| Doubles spread moves | One damage event per target, played in turn. Correct. |
| Stat stages and opening charms/knacks | Pills move with their own event. Correct. |
| Weather call, weather end, weather plate | Set by the weather cue, synced at batch end. Correct. No weather chip damage exists. |
| Catching (fail and success), running | No plate reads; the caught foe is skipped by the sync. Correct. |
| Pair keepers' lines | **Bug**: "Aoife and Orla wants to battle!" and "...sends out...". Fixed: a pair takes "want" and "send". |
| End of battle | Faint, XP line then bar, level lines, prize or gleaning lines, victory jingle, fade. In step. |

## Guarded by
`tests/battle_ui/test_playback_plates.gd`: 120 seeded battles (singles wild and keeper, doubles) with moves picked
to reach drain, recoil, multi-hit, self-heal, team cure, weather, status and stats, random charms (thistle,
shamrock, horseshoe, Brigid's cross, acorn), keeper teas, items on field and bench, switches, catches and runs.
Every event is played through the real `BattleHUD` as `play_events` does (`hud.on_event`, then `BattleFX.plates`),
and the test fails if any plate's HP, status, stages or creature changes on an event that is not about it, a hit or
switch shows anything but the event's value, or a plate differs from its creature once the batch is over (without
the sync). It checks it covered every hp-touching event type. Reverting the switch or item fix makes it fail on
a dozen seeds. Plus targeted tests: item then hit, a switch-in stung the turn it arrives, level-up without a dip,
sync leaving a running drain alone, a team cure, the meal pill, multi-hit order.

## Left alone (not mine, or a judgement call)
- Victory music starts after the XP and prize lines. Starting it with the last faint would be nicer, but the jingle
  is 3 s and does not loop, so the XP lines would play in silence. Wants a looping victory track.
- A charm that boosts or blunts a hit ("The Leek boosts...") is said after the hit lands, as the engine orders it.
  Reads acceptably.
