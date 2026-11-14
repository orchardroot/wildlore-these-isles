class_name SoundEmitters
extends Node
## Sounds that come from somewhere: the crackle of a hearth, the tick of a clock on the wall, a stream, the shore.
## One polyphonic player holds a looping voice per kind, and a few times a second the nearest source of each kind
## sets how loud its voice is, falling away with distance (the same curve as RailTraffic's trains). Sources are
## found once, when the zone is dressed; the poll itself walks a short list and allocates nothing.

## kind -> [loop id, near (full volume within this many tiles), range (silent beyond)]
const KINDS := {
	"fire": ["em_fire", 1.5, 9.0],
	"clock": ["em_clock", 1.5, 7.0],
	"stream": ["em_stream", 2.0, 11.0],
	"shore": ["em_shore", 3.0, 15.0],
}
const FIRE_PROPS := ["fireplace", "brazier", "range_cooker"]
const CLOCK_PROPS := ["clock"]
const STREAM_TILES := ["water", "shallow"]
const SHORE_TILES := ["sea"]
const MAX_SOURCES := 48   # per kind: more than the ear could tell apart
const POLL := 0.25        # seconds between looks at where the player stands
const EASE := 6.0         # how quickly a voice follows its target level (per second)
const SILENT := -80.0
const BASE_DB := 0.0

var follow: Node3D
var sources := {}         # kind -> Array of Vector2 (tile centres)
var _player: AudioStreamPlayer
var _voices := {}         # kind -> voice id in the polyphonic playback
var _target := {}         # kind -> dB it is easing to
var _level := {}          # kind -> dB it is at
var _t := 0.0
var _paused := false

## Dresses a freshly built zone with whatever it can hear. Hangs a node under the scenery (freed with it); nothing if the zone is silent.
static func dress(z: ZoneData, zone_node: Node3D, follow_node: Node3D) -> void:
	var found := plan(z)
	if found.is_empty():
		return
	var se := SoundEmitters.new()
	se.name = "SoundEmitters"
	se.follow = follow_node
	se.sources = found
	zone_node.add_child(se)

## Where each kind of sound comes from in a zone: {kind: [Vector2 tile centres]}, only the kinds that are there.
static func plan(z: ZoneData) -> Dictionary:
	var out := {}
	var fires := []
	var clocks := []
	for pr in z.props:
		var t := str(pr.get("type", ""))
		var at := Vector2(int(pr.get("x", 0)) + 0.5, int(pr.get("y", 0)) + 0.5)
		if t in FIRE_PROPS:
			fires.append(at)
		elif t in CLOCK_PROPS:
			clocks.append(at)
	if not fires.is_empty():
		out["fire"] = thin(fires)
	if not clocks.is_empty():
		out["clock"] = thin(clocks)
	if z.kind != "interior":
		var streams := []
		var shores := []
		for y in z.height:
			var row = z.tiles[y]
			for x in z.width:
				var t: String = row[x]
				if t in STREAM_TILES:
					if (x + y) % 2 == 0:
						streams.append(Vector2(x + 0.5, y + 0.5))
				elif t in SHORE_TILES and _edge_of_sea(z, x, y):
					shores.append(Vector2(x + 0.5, y + 0.5))
		if not streams.is_empty():
			out["stream"] = thin(streams)
		if not shores.is_empty():
			out["shore"] = thin(shores)
	return out

## Sea with something that is not sea beside it: where the waves actually break.
static func _edge_of_sea(z: ZoneData, x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var p: Vector2i = Vector2i(x, y) + d
		if z.in_bounds(p) and not (str(z.tile_at(p)) in SHORE_TILES):
			return true
	return false

## At most MAX_SOURCES of `all`, evenly spread (a long river is one voice however many tiles it has).
static func thin(all: Array) -> Array:
	if all.size() <= MAX_SOURCES:
		return all
	var out := []
	for i in MAX_SOURCES:
		out.append(all[i * all.size() / MAX_SOURCES])
	return out

## The level in dB of a source `d` tiles away: full within `near`, falling off after it, gone past `reach`.
static func gain_db(d: float, near: float, reach: float) -> float:
	if d >= reach:
		return SILENT
	var db := -18.0 * log(maxf(d, near) / near) / log(10.0)
	var edge := reach - 4.0
	if d > edge:
		db -= 40.0 * (d - edge) / 4.0
	return maxf(db, SILENT)

## The nearest distance from `ear` to any of `points` (INF for none).
static func nearest(points: Array, ear: Vector2) -> float:
	var best := INF
	for p in points:
		best = minf(best, (p as Vector2).distance_squared_to(ear))
	return sqrt(best) if best < INF else INF

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "EmitterSound"
	_player.bus = Audio.AMB_BUS
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = 4
	_player.stream = poly
	add_child(_player)
	_apply_volume()
	Bus.settings_changed.connect(_apply_volume)
	Bus.battle_started.connect(_on_battle_started)
	Bus.battle_ended.connect(_on_battle_ended)
	_start()
	_look()

func _exit_tree() -> void:
	if Bus.settings_changed.is_connected(_apply_volume):
		Bus.settings_changed.disconnect(_apply_volume)
	if Bus.battle_started.is_connected(_on_battle_started):
		Bus.battle_started.disconnect(_on_battle_started)
	if Bus.battle_ended.is_connected(_on_battle_ended):
		Bus.battle_ended.disconnect(_on_battle_ended)

func _start() -> void:
	_player.play()
	var pb := _player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if pb == null:
		return
	for kind in sources:
		var stream := load("res://audio/ambience/%s.wav" % KINDS[kind][0]) as AudioStream
		if stream == null:
			continue
		_level[kind] = SILENT
		_target[kind] = SILENT
		_voices[kind] = pb.play_stream(stream, randf() * stream.get_length(), SILENT)

func _apply_volume() -> void:
	if _player:
		_player.volume_db = linear_to_db(maxf(Settings.ambience_volume, 0.0001)) + BASE_DB

func _on_battle_started(_kind: String) -> void:
	_paused = true
	for kind in _target:
		_target[kind] = SILENT

func _on_battle_ended(_result: Dictionary) -> void:
	_paused = false
	_look()

## Sets what each voice is easing towards, from where the player stands now.
func _look() -> void:
	if follow == null or _paused:
		return
	var ear := Vector2(follow.global_position.x, follow.global_position.z)
	for kind in sources:
		var k: Array = KINDS[kind]
		_target[kind] = gain_db(nearest(sources[kind], ear), float(k[1]), float(k[2]))

func _process(delta: float) -> void:
	_t += delta
	if _t >= POLL:
		_t = 0.0
		_look()
	var pb := _player.get_stream_playback() as AudioStreamPlaybackPolyphonic if _player and _player.playing else null
	if pb == null:
		return
	var k := minf(1.0, EASE * delta)
	for kind in _voices:
		var cur: float = _level[kind]
		var to: float = _target[kind]
		if is_equal_approx(cur, to):
			continue
		cur = lerpf(cur, to, k)
		if absf(cur - to) < 0.2:
			cur = to
		_level[kind] = cur
		if pb.is_stream_playing(_voices[kind]):
			pb.set_stream_volume(_voices[kind], cur)
