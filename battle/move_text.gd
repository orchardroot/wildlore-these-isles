class_name MoveText
extends RefCounted
## Plain-English words for the battle menus: what a move does (built from its effect data, so it always matches
## what Battle and StatusFX really do), how well it lands on a foe, and how likely a snare is to hold.

const STAT_NAMES := {"atk": "Attack", "def": "Defence", "lore": "Lore", "ward": "Ward", "spd": "Speed", "acc": "Accuracy"}

## status -> [doing it, as a chance ("20% chance to ..."), what it means, the same in brackets after a chance]
const STATUS_TEXT := {
	"asleep": ["Puts the foe to sleep", "put the foe to sleep", "it can't move for 1 to 3 turns", "can't move for 1 to 3 turns"],
	"soaked": ["Soaks the foe", "soak the foe", "it slows down and storm moves hit it harder", "slower, and hurt more by storm moves"],
	"chilled": ["Chills the foe", "chill the foe", "now and then it is too cold to move", "now and then too cold to move"],
	"muddled": ["Muddles the foe", "muddle the foe", "for a few turns it may hurt itself instead", "may hurt itself for a few turns"],
	"hexed": ["Hexes the foe", "hex the foe", "it loses 1/16 of its HP each turn", "loses 1/16 of its HP each turn"],
	"stung": ["Stings the foe", "sting the foe", "it loses 1/8 of its HP each turn", "loses 1/8 of its HP each turn"],
}

## One or two short sentences. A "desc" in the move data wins, for moves that need a hand-written line.
static func describe(mv: Dictionary) -> String:
	if str(mv.get("desc", "")) != "":
		return str(mv.desc) + (" High chance of a critical hit." if int(mv.get("crit", 0)) > 0 else "")
	var parts: Array[String] = []
	var cat := str(mv.get("category", "status"))
	var fx: Dictionary = mv.get("effect", {"id": "none"})
	if cat != "status":
		parts.append("A %s hit." % cat)
	var chance := int(fx.get("chance", 100))
	match str(fx.get("id", "none")):
		"status":
			var st: Array = STATUS_TEXT.get(str(fx.status), ["Inflicts %s" % fx.status, "inflict %s" % fx.status, "", ""])
			if chance < 100:
				parts.append("%d%% chance to %s (%s)." % [chance, st[1], st[3]])
			else:
				parts.append("%s%s: %s." % ["Also " if cat != "status" else "", st[0] if cat == "status" else str(st[0]).to_lower(), st[2]])
		"stat":
			var stages := int(fx.get("stages", 0))
			var who := "the user's" if str(fx.get("target", "foe")) == "self" else "the foe's"
			var what := "%s %s by %s" % [who, STAT_NAMES.get(str(fx.stat), str(fx.stat)), "one stage" if absi(stages) == 1 else "%d stages" % absi(stages)]
			if chance < 100:
				parts.append("%d%% chance to %s %s." % [chance, "raise" if stages > 0 else "lower", what])
			else:
				parts.append("%s%s %s." % ["Also " if cat != "status" else "", ("Raises" if stages > 0 else "Lowers") if cat == "status" else ("raises" if stages > 0 else "lowers"), what])
		"drain":
			parts.append("Heals the user by %s of the damage dealt." % _share(int(fx.get("frac", 50))))
		"recoil":
			parts.append("The user takes %s of the damage dealt in recoil." % _share(int(fx.get("frac", 25))))
		"multi_hit":
			if fx.has("hits"):
				parts.append("Strikes %s." % ("twice" if int(fx.hits) == 2 else "%d times" % int(fx.hits)))
			else:
				parts.append("Strikes %d to %d times." % [int(fx.get("min", 2)), int(fx.get("max", 5))])
		"heal_self":
			parts.append("Restores %s of the user's HP." % _share(int(fx.get("frac", 50))))
		"protect":
			parts.append("Blocks every move aimed at the user this turn. Fails if used twice in a row.")
		"flinch":
			parts.append("%d%% chance to make the foe flinch and lose its turn, if the user moves first." % chance)
		"set_weather":
			var w := str(fx.get("weather", "clear"))
			var turns := int(fx.get("turns", MoveFX.DEFAULT_TURNS))
			parts.append("%s %s for %d turns." % ["Also calls up" if cat != "status" else "Calls up", MoveFX.weather_phrase(w), turns])
		"cure_team":
			parts.append("Cures the status of everyone on the user's team.")
	var wb: Dictionary = mv.get("weather_bonus", {})
	if not wb.is_empty():
		var where := MoveFX.weather_list(wb.get("weather", []))
		var mult := float(wb.get("mult", 1.0))
		if mult != 1.0:
			var how := "Twice as strong" if mult == 2.0 else ("Half as strong again" if mult == 1.5 else "Stronger")
			if str(fx.get("id", "")) == "heal_self":
				how = "Heals half as much again" if mult == 1.5 else "Heals more"
			parts.append("%s in %s." % [how, where])
		if bool(wb.get("sure_hit", false)):
			parts.append("Never misses in %s." % where)
	if int(mv.get("crit", 0)) > 0:
		parts.append("High chance of a critical hit.")
	if int(mv.get("priority", 0)) > 0:
		parts.append("Usually strikes first.")
	if str(mv.get("target", "")) == "all_foes":
		parts.append("Hits both foes in a double battle, a bit weaker.")
	if parts.is_empty():
		parts.append("Does nothing much.")
	return " ".join(parts)

## "half", "a quarter", "a third" or "N%", to go before "of".
static func _share(pct: int) -> String:
	match pct:
		100: return "all"
		75: return "three quarters"
		50: return "half"
		33: return "a third"
		25: return "a quarter"
	return "%d%%" % pct

static func effectiveness_label(mult: float) -> String:
	if mult == 0.0:
		return "No effect"
	if mult > 1.0:
		return "Super effective"
	if mult < 1.0:
		return "Not very effective"
	return ""

## How a damaging move will land. foes: the standing foes, each {"name", "types"}. One foe (or the same answer for
## every foe): just the label. Otherwise each foe that isn't a plain hit is named. "" when there is nothing useful
## to say (status moves, and plain hits: the move picker marks those itself, see `cues`).
static func versus(mv: Dictionary, foes: Array, chart: TypeChart) -> String:
	if str(mv.get("category", "status")) == "status" or int(mv.get("power", 0)) <= 0:
		return ""
	var labels := []
	for f in foes:
		labels.append([str(f.name), effectiveness_label(chart.effectiveness(str(mv.get("type", "")), f.types))])
	if labels.is_empty():
		return ""
	var same := labels.all(func(l): return l[1] == labels[0][1])
	if foes.size() == 1 or same:
		return labels[0][1]
	var bits := []
	for l in labels:
		if l[1] != "":
			bits.append("%s on %s" % [l[1] if bits.is_empty() else str(l[1]).to_lower(), l[0]])
	return ", ".join(bits)

## The shape a multiplier gets (EffectMark): up1/up2 for x2/x4, dn1/dn2 for x1/2 and x1/4, none, or even.
static func cue_kind(mult: float) -> String:
	if mult == 0.0:
		return "none"
	if mult >= 4.0:
		return "up2"
	if mult > 1.0:
		return "up1"
	if mult <= 0.25:
		return "dn2"
	if mult < 1.0:
		return "dn1"
	return "even"

## The words beside the shape. `short` leaves off the verdict ("x2" for "Super effective x2"), for crowded rows.
static func cue_words(mult: float, short := false) -> String:
	if mult == 0.0:
		return "No effect"
	if is_equal_approx(mult, 1.0):
		return "x1" if short else "Normal hit"
	return TypeChart.mult_words(mult) if short else "%s %s" % [effectiveness_label(mult), TypeChart.mult_words(mult)]

## What the move picker shows under each move that does damage: one {"kind", "words", "who"} per foe standing
## ("who" is "" when one answer covers every foe), and [] for a status move. foes: [{"name", "types"}].
static func cues(mv: Dictionary, foes: Array, chart: TypeChart) -> Array:
	if str(mv.get("category", "status")) == "status" or int(mv.get("power", 0)) <= 0 or foes.is_empty():
		return []
	var out := []
	for f in foes:
		out.append(chart.effectiveness(str(mv.get("type", "")), f.types))
	var same: bool = out.all(func(m): return is_equal_approx(m, out[0]))
	if same:
		return [{"kind": cue_kind(out[0]), "words": cue_words(out[0]), "who": ""}]
	var rows := []
	for i in foes.size():
		rows.append({"kind": cue_kind(out[i]), "words": cue_words(out[i], true), "who": str(foes[i].name)})
	return rows

## "Strong against Hedgerow, Frost and Iron. Weak against ..." for a move's description, from its type alone ("" for
## a move with no type or no damage). Type names are the game's own (Hearth, Brook), capitalised.
static func matchup_line(mv: Dictionary, chart: TypeChart) -> String:
	var t := str(mv.get("type", ""))
	if t == "" or str(mv.get("category", "status")) == "status" or int(mv.get("power", 0)) <= 0:
		return ""
	var bits := []
	var strong := chart.strong_against(t)
	if not strong.is_empty():
		bits.append("Strong against %s" % _names(strong))
	var weak := chart.weak_against(t)
	if not weak.is_empty():
		bits.append("Weak against %s" % _names(weak))
	var none := chart.no_effect_on(t)
	if not none.is_empty():
		bits.append("No effect on %s" % _names(none))
	return ". ".join(bits) + ("." if not bits.is_empty() else "")

static func _names(ids: Array) -> String:
	return ", ".join(ids.map(func(i): return str(i).capitalize()))

## The odds of one snare holding, in words rather than numbers.
static func catch_band(chance: float) -> String:
	if chance < 0.2:
		return "Long shot"
	if chance < 0.5:
		return "Worth a try"
	return "Good odds"

## The odds as a rough fraction ("About 1 in 3"), shown once the species is in the Fieldbook.
const ODDS_FRACTIONS := [[1, 2], [3, 5], [2, 3], [3, 4], [4, 5], [9, 10]]

static func catch_odds(chance: float) -> String:
	if chance >= 0.95:
		return "A dead cert"
	if chance < 0.02:
		return "Under 1 in 50"
	if chance < 0.5:
		var n := maxi(2, int(round(1.0 / chance)))
		return "About 1 in %d" % (n if n <= 10 else int(round(n / 5.0)) * 5)  # past 1 in 10, to the nearest 5
	var best: Array = ODDS_FRACTIONS[0]
	for f in ODDS_FRACTIONS:
		if absf(float(f[0]) / f[1] - chance) < absf(float(best[0]) / best[1] - chance):
			best = f
	return "About %d in %d" % best
