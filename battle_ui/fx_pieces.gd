class_name FXPieces
extends RefCounted
## Signature looks for party piece moves (wave 48 A). A piece move carries "piece": "<game id>"; its flourish is chosen
## by that id, drawn from the game it came from (a skimmed stone skips, a dart flies true), then the move's own shape
## plays as usual in its type palette. Unknown piece ids get a gold rosette fanfare, so a new game never plays blank.

## piece id -> flourish kind. Ids not listed use "fanfare". Kinds: skip, arrow, tumble, slide, swing, notes, wall, hook,
## cheer, flip, whirl.
const KIND := {
	"skimming": "skip", "stone_skimming": "skip", "darts": "arrow", "caber": "tumble", "bowls": "slide", "curling": "slide",
	"conkers": "swing", "wrestling": "whirl", "ringing": "notes", "bell_ringing": "notes", "shanty": "notes", "singing": "notes",
	"walling": "wall", "dry_stone": "wall", "crabbing": "hook", "fishing": "hook", "tug": "cheer", "tug_of_war": "cheer",
	"hurling": "swing", "shinty": "swing", "arcade": "flip", "quiz": "flip", "crossword": "flip", "trumps": "flip",
	"forecasting": "whirl", "races": "slide", "science": "flip",
	"sheepdog_trials": "whirl", "worms": "notes", "cheese": "tumble", "pancake": "flip", "snorkel": "skip", "coracle": "whirl",
	"fete_cheese": "tumble", "fete_bog": "skip", "fete_welly": "tumble",
}

var fx: BattleFX

static func kind_for(piece: String) -> String:
	return str(KIND.get(piece, "fanfare"))

## True for a move dictionary that is a party piece.
static func is_piece(move: Dictionary) -> bool:
	return str(move.get("piece", "")) != ""

func play(move: Dictionary, side: int, pos: int, other: int, hit_pos: Array, t_pos: int, spread: bool, pal: Array, col: Color) -> void:
	var u := fx._chest(side, pos)
	var tp := fx._chest(other, t_pos)
	var hi: Color = pal[1]
	var shape := BattleFX.shape_for(move)
	var kind := kind_for(str(move.get("piece", "")))
	var feet := fx._actor(side, pos).global_position
	var tfeet := fx._actor(other, t_pos).global_position
	match kind:
		"skip":  # a flat stone skipping across the water: four hops, a ring at each landing
			for i in 4:
				var k := (i + 1) / 4.0
				var at := feet.lerp(tfeet, k) + Vector3(0, 0.15, 0)
				var d := 0.12 * i
				fx._spawn(feet.lerp(tfeet, i / 4.0) + Vector3(0, 0.15, 0), Vector3.ZERO, Color(0.85, 0.85, 0.8), 0.34, 0.12, 0.0, BattleFX.PATH, d, at, 0.35 - 0.06 * i, true)
				fx.get_tree().create_timer(d + 0.12).timeout.connect(func(): fx._ring(at, hi, hi.lightened(0.4), 1))
		"arrow":  # three quick darts in a tight group
			for i in 3:
				var off := Vector3(0, (i - 1) * 0.22, 0)
				fx._spawn(u + off, Vector3.ZERO, Color("f2e6c0"), 0.2, 0.2, 0.0, BattleFX.PATH, 0.09 * i, tp + off, 0.0, false, 3.0, 3)
				fx.get_tree().create_timer(0.09 * i + 0.2).timeout.connect(func(): fx.burst(tp + off, Color("ffe08a"), 6, 2.0, 0.12, 0.3, -2.0, Vector3.UP, 2))
		"tumble":  # something heavy turned end over end, then a thud
			for i in 9:
				var k := i / 8.0
				fx._spawn(u.lerp(tp, k) + Vector3(0, sin(k * PI) * 1.8, 0), Vector3.ZERO, Color("8a6a3c").lerp(hi, 0.2), 0.45, 0.14, 0.0, BattleFX.HANG, k * 0.38, Vector3.ZERO, 0.0, false, 2.4, 3)
			fx.get_tree().create_timer(0.42).timeout.connect(func(): fx._dust(tfeet, hi))
		"slide":  # a stone or bowl sliding low with a trail of frost-white scuffs
			for i in 14:
				var k := i / 13.0
				fx._spawn(feet.lerp(tfeet, k) + Vector3(0, 0.2, 0), Vector3(0, 0.3, 0), hi.lightened(0.3), 0.3, 0.35, 0.0, BattleFX.FLY, k * 0.3, Vector3.ZERO, 0.0, true)
		"swing":  # a wide arc swung across the target
			for i in 10:
				var a := lerpf(-1.2, 1.2, i / 9.0)
				fx._spawn(tp + Vector3(sin(a) * 1.2, cos(a) * 1.0 - 0.2, 0.3), Vector3.ZERO, Color("fff2d0"), 0.3, 0.14, 0.0, BattleFX.HANG, 0.02 * i, Vector3.ZERO, 0.0, true, 1.6, 3)
		"notes":  # notes drifting up from the user, a ring of them at the target
			for i in fx._n(8):
				fx._spawn(u + Vector3(randf_range(-0.5, 0.5), 0.2, 0), Vector3(randf_range(-0.6, 0.6), 1.6, 0), hi, 0.3, 0.7, 0.0, BattleFX.FLY, 0.05 * i, Vector3.ZERO, 0.0, false, 1.0, 5)
			fx._ring(tp, hi, hi.lightened(0.3), 5)
		"wall":  # stones stacking up in front of the target
			for i in 6:
				var c := Vector3((i % 3 - 1) * 0.45, (i / 3) * 0.4 - 0.5, 0.4)
				fx._spawn(tp + c + Vector3(0, 2.0, 0), Vector3.ZERO, Color("9a958a"), 0.4, 0.18, 0.0, BattleFX.PATH, 0.06 * i, tp + c, 0.0)
				fx.get_tree().create_timer(0.06 * i + 0.18).timeout.connect(func(): fx._dust(tfeet, Color("b8b0a0")))
		"hook":  # a line cast out and reeled in
			fx._thread(u, tp, hi)
			fx.get_tree().create_timer(0.3).timeout.connect(func(): fx._thread(tp, u, hi))
		"cheer":  # a surge of stars from the user's side
			fx.burst(u, Color("ffd870"), 18, 3.2, 0.2, 0.7, -1.0, Vector3.UP, 2)
		"flip":  # cards or tiles flicking into the air over the target
			for i in 5:
				fx._spawn(tp + Vector3((i - 2) * 0.35, -0.4, 0), Vector3(0, 3.0, 0), Color("f2f0e0"), 0.34, 0.5, -4.0, BattleFX.FLY, 0.05 * i, Vector3.ZERO, 0.0, false, 1.3, 3)
		"whirl":  # a spinning ring of sparks round the user
			for i in fx._n(16):
				var ang := TAU * i / 16.0
				fx._spawn(u, Vector3(cos(ang), 0.3, sin(ang)) * 2.4, hi, 0.2, 0.5, 0.0, BattleFX.FLY, 0.015 * i, Vector3.ZERO, 0.0, true)
		_:  # fanfare: a gold rosette ring and a spray of stars
			fx._ring(u, Color("e0b040"), Color("fff0b0"), 2)
			fx.burst(tp, Color("ffd870"), 10, 3.0, 0.16, 0.5, -2.0, Vector3.UP, 2)
	await fx._wait(0.22)
	await fx.play_shape(shape, side, pos, other, hit_pos, t_pos, spread, pal, col)
