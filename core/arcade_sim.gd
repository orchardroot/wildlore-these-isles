class_name ArcadeSim
extends RefCounted
## Plays the arcade the way a keen, shrewd and a hopeless player would, many seeds over, to check it can't print
## money: pounds only ever go IN (nothing converts coins or tokens back), the pusher and falls hand back fewer
## coins than they take, and the daily cap bounds the spend. tests/minigames/test_arcade.gd runs a small batch.

const STRATEGIES := ["pusher_perfect", "pusher_random", "falls_fullest", "falls_random", "claw_aimed", "mixed"]

## One real day of play from `pounds` of change: {coins_in, coins_out, money, toys, tokens}. `money` is the purse change.
static func day(strategy: String, seed_value: int, pounds: int) -> Dictionary:
	var rng := Rng.new(seed_value)
	var d := GameStateData.new()
	d.money = 1000
	var start := d.money
	Arcade.buy(d, pounds)
	var st := Arcade.pusher_new()
	var fa := Arcade.falls_new(rng)
	var coins_in := 0
	var coins_out := 0
	var t := 0.0
	var guard := 0
	while Arcade.coins(d) > 0 and guard < 5000:
		guard += 1
		t += 0.37 + rng.roll() * 1.9
		var pick := strategy
		if strategy == "mixed":
			pick = ["pusher_perfect", "falls_random", "claw_aimed"][rng.roll_int(0, 2)]
		match pick:
			"pusher_perfect", "pusher_random":
				Arcade.spend(d, 1)
				coins_in += 1
				var x := Arcade.shelf_pos(t, false) if pick == "pusher_perfect" else rng.roll()
				var r := Arcade.pusher_drop(st, x, t, false, rng)
				coins_out += int(r.out)
				Arcade.win_coins(d, int(r.out))
				if r.token:
					Arcade.win_tokens(d, 1)
			"falls_fullest", "falls_random":
				Arcade.spend(d, 1)
				coins_in += 1
				var lane := rng.roll_int(0, Arcade.LANES - 1)
				if pick == "falls_fullest":
					var most := 0
					for i in Arcade.LANES:
						if fa.ledge[i] > fa.ledge[most]:
							most = i
					lane = most
				var r2 := Arcade.falls_drop(fa, lane, rng)
				coins_out += int(r2.out)
				Arcade.win_coins(d, int(r2.out))
				if r2.token:
					Arcade.win_tokens(d, 1)
			"claw_aimed":
				if not Arcade.spend(d, Arcade.CLAW_COST):
					break
				coins_in += Arcade.CLAW_COST
				var r3 := Arcade.claw_play(0.5, [0.2, 0.5, 0.8], Arcade.miss_streak(d), false, rng)
				Arcade.claw_result(d, r3, "blackpool", rng)
		while Arcade.tokens(d) >= Arcade.TOKENS_PER_TOY and Arcade.redeem(d, "blackpool") != "":
			pass
	var toys := 0
	for id in ["toy_donkey", "toy_tower_bear"]:
		toys += int(d.bag.get(id, 0))
	return {"coins_in": coins_in, "coins_out": coins_out, "money": d.money - start, "toys": toys, "tokens": Arcade.tokens(d)}
