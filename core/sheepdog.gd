class_name Sheepdog
extends RefCounted
## The sheepdog trials: steer your lead creature (the dog) round a field and drive four sheep through two gates
## into the pen before the clock runs out. Pure rules; ui/sheepdog_trial.gd draws it and feeds in the direction.
## Sheep drift away from the dog (the closer, the faster), huddle a little, and can only go through a gate's gap:
## the rest of each gate is hurdle. Once through a gate a sheep stays through. "Easy" widens the gates, slows the
## sheep and gives more time. A faster lead creature is a touch quicker, never so much that it decides it.

const W := 12.0
const H := 7.0
const GATES := [5.0, 8.5]      # x of each gate
const PEN_X := 10.0            # past the last gate and beyond this x, a sheep is penned
const SHEEP := 4
const FLEE_R := 2.4
const SHEEP_SPEED := 1.7
const DOG_SPEED := 3.3
const TIME := 75.0
const EASY_TIME := 110.0

## {dog, sheep: [{p, stage}], gap: half-width of a gate, time, left, easy, rng, speed}
static func start(seed_text: String, lead_speed: int, easy: bool) -> Dictionary:
	var rng := Rng.new(absi(hash("sheepdog/" + seed_text)))
	var sheep := []
	for i in SHEEP:
		sheep.append({"p": Vector2(rng.roll_range(1.8, 4.0), rng.roll_range(1.6, H - 1.6)), "stage": 0})
	return {"dog": Vector2(0.8, H * 0.5), "sheep": sheep, "gap": 1.5 if easy else 1.0,
		"time": EASY_TIME if easy else TIME, "left": EASY_TIME if easy else TIME, "easy": easy, "rng": rng,
		"speed": DOG_SPEED * (1.0 + clampf(float(lead_speed), 0.0, 100.0) / 500.0),
		"gate_y": H * 0.5}

static func penned(st: Dictionary) -> int:
	var n := 0
	for s in st.sheep:
		if int(s.stage) >= GATES.size() and s.p.x >= PEN_X:
			n += 1
	return n

static func done(st: Dictionary) -> bool:
	return penned(st) >= SHEEP or float(st.left) <= 0.0

## Advances `dt` seconds with the dog heading `dir` (any length up to 1).
static func step(st: Dictionary, dir: Vector2, dt: float) -> void:
	if done(st):
		return
	st.left = maxf(0.0, float(st.left) - dt)
	var d: Vector2 = dir.limit_length(1.0)
	st.dog = (st.dog + d * float(st.speed) * dt).clamp(Vector2(0.3, 0.3), Vector2(W - 0.3, H - 0.3))
	var speed := SHEEP_SPEED * (0.7 if st.easy else 1.0)
	var centre := Vector2.ZERO
	for s in st.sheep:
		centre += s.p
	centre /= st.sheep.size()
	for s in st.sheep:
		var v := Vector2.ZERO
		var away: Vector2 = s.p - st.dog
		var dist := away.length()
		if dist < FLEE_R and dist > 0.001:
			v += away / dist * speed * (1.0 - dist / FLEE_R + 0.25)
		v += (centre - s.p).limit_length(1.0) * 0.12
		v += Vector2(st.rng.roll_range(-1.0, 1.0), st.rng.roll_range(-1.0, 1.0)) * 0.1
		# sheep shy off the walls, so none gets pinned in a corner
		v.y += clampf(1.2 - s.p.y, 0.0, 1.2) * 0.9 - clampf(s.p.y - (H - 1.2), 0.0, 1.2) * 0.9
		_move(st, s, s.p + v * dt, dt)

static func _move(st: Dictionary, s: Dictionary, to: Vector2, dt: float) -> void:
	to = to.clamp(Vector2(0.25, 0.25), Vector2(W - 0.25, H - 0.25))
	var gate_i := int(s.stage)
	# one-way gates: never back through one already passed
	if gate_i > 0:
		to.x = maxf(to.x, float(GATES[gate_i - 1]) + 0.15)
	if gate_i < GATES.size():
		var gx: float = GATES[gate_i]
		if to.x >= gx:
			if absf(to.y - float(st.gate_y)) <= float(st.gap):
				if to.x >= gx + 0.15:
					s.stage = gate_i + 1
			else:
				# a sheep nosing a hurdle shuffles along it towards the gap
				to.x = gx - 0.05
				to.y += signf(float(st.gate_y) - to.y) * 0.6 * dt
	s.p = to

## 1 (red) to 3 (yellow) by how many were penned and how much clock is left; 0 for none placed.
static func place_for(st: Dictionary) -> int:
	var n := penned(st)
	if n >= SHEEP:
		return 1 if float(st.left) >= float(st.time) * 0.3 else 2
	if n >= SHEEP - 1:
		return 2
	if n >= 2:
		return 3
	return 0
