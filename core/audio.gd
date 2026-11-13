extends Node
## Autoload Audio: two music players for real crossfades, a small pool for sound effects, and one ambience player
## (the bed and the weather layer are two voices of one polyphonic stream, each crossfaded when it changes).
## Looks for res://audio/music/<id>.ogg|.wav, res://audio/sfx/<id>.wav and res://audio/ambience/<id>.wav;
## missing files are silently skipped. Looping comes from the loop points baked into the WAV files
## (see tools/sfxgen.gd and tools/audio/ambgen.gd). What plays where is picked by Ambience.

const SILENT_DB := -60.0
const MUSIC_BUS := &"Music"
const AMB_BUS := &"Ambience"  # beds, layers and emitters: fog and frost close a low-pass over it
const MUFFLE_HZ := 650.0      # the town tune heard through the walls of a house
const OPEN_HZ := 20000.0
const MUFFLE_DB := -4.0
const AMB_FADE := 1.5
const STEP_DB := -9.0         # footsteps sit under everything else
const RUN_STEP_DB := -13.0    # quicker steps, so softer ones
const BIKE_DB := -12.0
const TALK_DB := -6.0
const CRY_DB := -2.0          # a touch under the other effects: it plays over the send-out chime
const BELL_DB := -4.0         # tolls on the hour; quiet-ish, it is across town
const HORN_DB := -12.0        # a ship out in the harbour
const HORN_GAP := Vector2(70.0, 160.0)
const BLIP_DB := -15.0        # the tick for each letter of speech: well under the voice of the world
const TOLL_GAP := 2.1         # seconds between strokes of an hour
const TOLL_PITCH := {"bell": 1.0, "bell_small": 1.4}
const POLL := 1.0             # seconds between looks at the clock (night falling, the hour striking)

var _players: Array = []
var _active := 0
var _music_id := ""
var _sfx: Array = []
var _tweens: Array = [null, null]

var _amb: AudioStreamPlayer
var _amb_tween: Tween
var _slots := {"bed": {}, "layer": {}}   # slot -> {"id", "vid", "db", "tween"}
var _zone: ZoneData
var _weather := "clear"
var _outside := "clear"       # the weather last seen outdoors: what you hear on the roof
var _accents: Array = []
var _minute := -1
var _horn_t := 0.0
var _poll_t := 0.0
var _in_battle := false
var _muffled := false
var _muffle_tween: Tween
var _rng := RandomNumberGenerator.new()  # its own dice: the game's rng stays deterministic
var _last_step_ms := 0
var _damp_tween: Tween
var _thunder_token := 0       # bumped to call off thunder already on its way (a new zone, a battle)
var _tolling := false
var _blip_n := 0

func _ready() -> void:
	_ensure_music_bus()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = SILENT_DB
		p.bus = MUSIC_BUS
		add_child(p)
		_players.append(p)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)
	_ensure_ambience_bus()
	_amb = AudioStreamPlayer.new()
	_amb.bus = AMB_BUS
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = 4  # bed + layer, and the two on their way out during a crossfade
	_amb.stream = poly
	_amb.volume_db = _amb_db()
	add_child(_amb)
	_rng.randomize()
	Bus.settings_changed.connect(_apply_volume)
	Bus.battle_started.connect(_on_battle_started)
	Bus.battle_ended.connect(_on_battle_ended)

func play_music(id: String, fade := 0.6) -> void:
	if id == _music_id:
		return
	_music_id = id
	var stream := _find("res://audio/music/" + id)
	var old: AudioStreamPlayer = _players[_active]
	var old_idx := _active
	_fade(old_idx, SILENT_DB, fade, true)
	if stream == null:
		return
	_active = 1 - _active
	var p: AudioStreamPlayer = _players[_active]
	p.stop()
	p.stream = stream
	p.volume_db = SILENT_DB
	p.play()
	_fade(_active, _music_db(), fade, false)

func stop_music(fade := 0.6) -> void:
	_music_id = ""
	for i in 2:
		_fade(i, SILENT_DB, fade, true)

func sfx(id: String) -> void:
	sfx_at(id)

## A sound effect `gain_db` louder or softer than usual, at `pitch` (1 = as recorded).
func sfx_at(id: String, gain_db := 0.0, pitch := 1.0, volume := -1.0) -> void:
	var stream := _find(AudioIds.sfx_file(id).get_basename())
	if stream == null:
		return
	play_stream(stream, gain_db, pitch, volume)

## A species' cry (synthesised and cached by Cries), at sound effect volume.
func cry(species: Dictionary, gain_db := CRY_DB) -> void:
	var stream := Cries.stream_for(species)
	if stream != null:
		play_stream(stream, gain_db)

## Any stream on a free sound effect player.
func play_stream(stream: AudioStream, gain_db := 0.0, pitch := 1.0, volume := -1.0) -> void:
	for p in _sfx:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(maxf(Settings.sfx_volume if volume < 0.0 else volume, 0.0001)) + gain_db
			p.pitch_scale = pitch
			p.play()
			return

func _music_db() -> float:
	return linear_to_db(maxf(Settings.music_volume, 0.0001))

func _fade(idx: int, to_db: float, secs: float, stop_after: bool) -> void:
	var p: AudioStreamPlayer = _players[idx]
	if _tweens[idx] != null and _tweens[idx].is_valid():
		_tweens[idx].kill()
	if secs <= 0.0:
		p.volume_db = to_db
		if stop_after:
			p.stop()
		return
	var tw := create_tween()
	_tweens[idx] = tw
	tw.tween_property(p, "volume_db", to_db, secs)
	if stop_after:
		tw.tween_callback(p.stop)

func _apply_volume() -> void:
	var p: AudioStreamPlayer = _players[_active]
	if p.playing and _music_id != "":
		p.volume_db = _music_db()
	if not _in_battle and _amb:
		if _amb_tween and _amb_tween.is_valid():
			_amb_tween.kill()
		_amb.volume_db = _amb_db()

func _find(base: String) -> AudioStream:
	for ext in [".ogg", ".wav"]:
		if ResourceLoader.exists(base + ext):
			return load(base + ext)
	return null

# --- ambience ------------------------------------------------------------------------------------------------------

## The overworld calls this whenever a zone loads. `owner` going away (back to the title) silences it all.
func enter_zone(owner: Node, z: ZoneData, weather: String) -> void:
	var arrived := _zone != null
	if z.kind != "interior":
		_outside = weather
	_zone = z
	_weather = weather
	_accents = Ambience.accents(z)
	_minute = Game.data.clock_minutes
	_horn_t = _rng.randf_range(HORN_GAP.x * 0.3, HORN_GAP.y * 0.5)
	if owner and not owner.tree_exiting.is_connected(_on_scene_gone):
		owner.tree_exiting.connect(_on_scene_gone)
	_refresh()
	if arrived and z.id.ends_with("_shop"):
		sfx_at("shop_bell", -6.0)  # the bell over the door

## Sets the ambience bed ("" for none), crossfading from whatever was playing.
func play_ambience(id: String, fade := AMB_FADE) -> void:
	_set_slot("bed", id, fade)

## Sets the weather layer that plays over the bed ("" for none).
func play_ambience_layer(id: String, fade := AMB_FADE) -> void:
	_set_slot("layer", id, fade)

func stop_ambience(fade := AMB_FADE) -> void:
	play_ambience("", fade)
	play_ambience_layer("", fade)

func ambience_ids() -> Dictionary:
	return {"bed": _slots.bed.get("id", ""), "layer": _slots.layer.get("id", "")}

## Muffles the music (a low-pass on the Music bus) as if heard from indoors, or opens it up again.
func set_music_muffled(on: bool, secs := 0.6) -> void:
	if on == _muffled:
		return
	_muffled = on
	_apply_muffle(on and not _in_battle, secs)

func music_muffled() -> bool:
	return _muffled

## A footstep on `tile` (one per tile: the overworld calls this once per step).
func footstep(tile: String, on_bike: bool, running: bool) -> void:
	if _zone == null:
		return
	var id := Ambience.footstep(tile, _weather, _zone.kind == "interior", on_bike)
	if id == "":
		return
	var now := Time.get_ticks_msec()
	if now - _last_step_ms < 60:
		return
	_last_step_ms = now
	var db := BIKE_DB if on_bike else (RUN_STEP_DB if running else STEP_DB)
	sfx_at(id, db, _rng.randf_range(0.92, 1.08))

## A small sound for pressing confirm at `p`: a creak for signs, a blip for people, a bell at the shop counter,
## a chime at the Sanctuary desk. `ow` is the overworld (zone, npc_at, player).
func interaction(ow: Object, p: Vector2i) -> void:
	var z: ZoneData = ow.zone
	var sign := z.sign_at(p)
	var def := {}
	if sign.is_empty():
		var n: Node = ow.npc_at(p)
		if n == null and z.tile_at(p) == "counter":
			n = ow.npc_at(p + GridMotion.dir_vec(ow.player.facing))
		if n != null and "def" in n:
			def = n.def
	var id := Ambience.interact_kind(sign, def)
	if id != "":
		sfx_at(id, TALK_DB if id == "talk_blip" else -3.0)

func _amb_db() -> float:
	return linear_to_db(maxf(Settings.ambience_volume, 0.0001))

func _refresh() -> void:
	if _zone == null:
		return
	var pick := Ambience.pick(_zone, _weather, Game.phase(), _outside)
	play_ambience(pick.bed)
	play_ambience_layer(pick.layer)
	set_music_muffled(pick.muffle)
	_apply_damp(pick.damp)

func _process(delta: float) -> void:
	if _zone == null or _in_battle:
		return
	if "horn" in _accents:
		_horn_t -= delta
		if _horn_t <= 0.0:
			_horn_t = _rng.randf_range(HORN_GAP.x, HORN_GAP.y)
			sfx_at("ship_horn", HORN_DB, _rng.randf_range(0.9, 1.04), Settings.ambience_volume)
	_poll_t += delta
	if _poll_t < POLL:
		return
	_poll_t = 0.0
	var now := Game.data.clock_minutes
	if Ambience.hour_struck(_minute, now):
		for kind in ["bell", "bell_small"]:
			if kind in _accents:
				_toll(Ambience.strokes(now), TOLL_PITCH[kind])
				break
	_minute = now
	_refresh()  # night falls, dawn comes

## The hour: `count` strokes of the bell, TOLL_GAP apart. Stops if you leave the town or a battle starts.
func _toll(count: int, pitch: float) -> void:
	if count <= 0 or _tolling:
		return
	_tolling = true
	var zone := _zone
	for i in count:
		if _zone != zone or _in_battle or not is_inside_tree():
			break
		sfx_at("bell_toll", BELL_DB, pitch, Settings.ambience_volume)
		await get_tree().create_timer(TOLL_GAP).timeout
	_tolling = false

## Thunder: heard from out in the open (`indoors` false) or through the roof, either close or over the next hill.
## It arrives `delay` seconds after the flash (light is quicker).
func thunder(close: bool, indoors: bool, delay := 0.0) -> void:
	if _in_battle:
		return
	var token := _thunder_token
	if delay > 0.0 and is_inside_tree():
		await get_tree().create_timer(delay).timeout
	if token != _thunder_token or _in_battle:
		return
	var id := "thunder" if close and not indoors else "thunder_far"
	sfx_at(id, -9.0 if indoors else -4.0, 1.0, Settings.ambience_volume)

## One soft tick for a letter of speech (the dialogue box calls this every few letters), if the setting is on.
func text_blip() -> void:
	if not Settings.text_blip:
		return
	_blip_n += 1
	sfx_at("text_blip", BLIP_DB, 0.9 + 0.05 * float(_blip_n % 5))

func _on_scene_gone() -> void:
	_thunder_token += 1
	_zone = null
	stop_ambience(0.5)
	set_music_muffled(false, 0.3)

func _on_battle_started(kind: String) -> void:
	_in_battle = true
	if kind == "wild" and not Engine.has_meta("autopilot"):
		sfx("encounter")  # something in the grass: the sting plays over the swirl into battle
	_thunder_token += 1
	_battle_ambience(true)
	_apply_muffle(false, 0.2)

func _on_battle_ended(_result: Dictionary) -> void:
	_in_battle = false
	_battle_ambience(false)
	_apply_muffle(_muffled, 0.4)

## A battle hushes the bed, but the rain you were standing in carries on, faintly; afterwards it all comes back.
func _battle_ambience(on: bool) -> void:
	var pb := _playback()
	if pb == null:
		return
	var bed: Dictionary = _slots.bed
	var layer: Dictionary = _slots.layer
	if bed.is_empty() or layer.is_empty():
		return
	if on:
		_fade_voice(pb, bed, SILENT_DB, 0.4, false)
		var keep := Ambience.battle_layer_db(str(layer.get("id", "")))
		_fade_voice(pb, layer, SILENT_DB if keep < -50.0 else keep, 0.5, false)
	else:
		_fade_voice(pb, bed, 0.0, 1.0, false)
		_fade_voice(pb, layer, 0.0, 1.0, false)

func _playback() -> AudioStreamPlaybackPolyphonic:
	if _amb == null or not _amb.is_inside_tree():
		return null
	if not _amb.playing:
		_amb.play()
	return _amb.get_stream_playback() as AudioStreamPlaybackPolyphonic

func _set_slot(slot: String, id: String, fade: float) -> void:
	var cur: Dictionary = _slots[slot]
	if str(cur.get("id", "")) == id:
		return
	var pb: AudioStreamPlaybackPolyphonic = null
	if id != "" or not cur.is_empty():
		pb = _playback()
	if not cur.is_empty():
		_fade_voice(pb, cur, SILENT_DB, fade, true)
	var v := {"id": id, "vid": -1, "db": SILENT_DB, "tween": null}
	_slots[slot] = v
	if id == "" or pb == null:
		return
	var stream := _find("res://audio/ambience/" + id)
	if stream == null:
		return
	# start somewhere different each time, so walking in and out never replays the same gull
	v.vid = pb.play_stream(stream, _rng.randf() * stream.get_length(), SILENT_DB)
	_fade_voice(pb, v, 0.0, fade, false)

func _fade_voice(pb: AudioStreamPlaybackPolyphonic, v: Dictionary, to_db: float, secs: float, stop_after: bool) -> void:
	var vid: int = v.vid
	if pb == null or vid < 0:
		return
	var old = v.tween
	if old is Tween and old.is_valid():
		old.kill()
	var tw := create_tween()
	v.tween = tw
	var set_db := func(db: float) -> void:
		v.db = db
		if pb.is_stream_playing(vid):
			pb.set_stream_volume(vid, db)
	tw.tween_method(set_db, float(v.db), to_db, maxf(secs, 0.01))
	if stop_after:
		tw.tween_callback(func(): pb.stop_stream(vid))

func _ensure_ambience_bus() -> void:
	if AudioServer.get_bus_index(AMB_BUS) < 0:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, AMB_BUS)
		AudioServer.set_bus_send(i, &"Master")
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = Ambience.OPEN_HZ
		AudioServer.add_bus_effect(i, lp, 0)
		AudioServer.set_bus_effect_enabled(i, 0, false)

## Closes (or opens) the low-pass over the ambience bus: fog and frost muffle everything outdoors.
func _apply_damp(damp: Array) -> void:
	var bi := AudioServer.get_bus_index(AMB_BUS)
	if bi < 0 or AudioServer.get_bus_effect_count(bi) == 0:
		return
	var lp := AudioServer.get_bus_effect(bi, 0) as AudioEffectLowPassFilter
	if lp == null:
		return
	var to_hz: float = damp[0]
	var to_db: float = damp[1]
	var from_hz := lp.cutoff_hz if AudioServer.is_bus_effect_enabled(bi, 0) else Ambience.OPEN_HZ
	if is_equal_approx(from_hz, to_hz) and is_equal_approx(AudioServer.get_bus_volume_db(bi), to_db):
		return
	if _damp_tween and _damp_tween.is_valid():
		_damp_tween.kill()
	var from_db := AudioServer.get_bus_volume_db(bi)
	AudioServer.set_bus_effect_enabled(bi, 0, true)
	if not is_inside_tree():
		lp.cutoff_hz = to_hz
		AudioServer.set_bus_volume_db(bi, to_db)
		AudioServer.set_bus_effect_enabled(bi, 0, to_hz < Ambience.OPEN_HZ)
		return
	_damp_tween = create_tween()
	var step := func(t: float) -> void:
		lp.cutoff_hz = from_hz * pow(to_hz / from_hz, t)
		AudioServer.set_bus_volume_db(bi, lerpf(from_db, to_db, t))
	_damp_tween.tween_method(step, 0.0, 1.0, 2.0)
	if to_hz >= Ambience.OPEN_HZ:
		_damp_tween.tween_callback(func(): AudioServer.set_bus_effect_enabled(bi, 0, false))

func _ensure_music_bus() -> void:
	# default_bus_layout.tres sets this up; this is the fallback if it is missing
	if AudioServer.get_bus_index(MUSIC_BUS) < 0:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, MUSIC_BUS)
		AudioServer.set_bus_send(i, &"Master")
	var bi := AudioServer.get_bus_index(MUSIC_BUS)
	if AudioServer.get_bus_effect_count(bi) == 0 or not (AudioServer.get_bus_effect(bi, 0) is AudioEffectLowPassFilter):
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = OPEN_HZ
		AudioServer.add_bus_effect(bi, lp, 0)
	AudioServer.set_bus_effect_enabled(bi, 0, false)

func _apply_muffle(on: bool, secs: float) -> void:
	var bi := AudioServer.get_bus_index(MUSIC_BUS)
	if bi < 0:
		return
	var lp := AudioServer.get_bus_effect(bi, 0) as AudioEffectLowPassFilter
	if lp == null:
		return
	if _muffle_tween and _muffle_tween.is_valid():
		_muffle_tween.kill()
	var from_hz := lp.cutoff_hz if AudioServer.is_bus_effect_enabled(bi, 0) else OPEN_HZ
	var from_db := AudioServer.get_bus_volume_db(bi)
	var to_hz := MUFFLE_HZ if on else OPEN_HZ
	var to_db := MUFFLE_DB if on else 0.0
	AudioServer.set_bus_effect_enabled(bi, 0, true)
	if not is_inside_tree():
		lp.cutoff_hz = to_hz
		AudioServer.set_bus_volume_db(bi, to_db)
		AudioServer.set_bus_effect_enabled(bi, 0, on)
		return
	_muffle_tween = create_tween()
	# sweep the cutoff evenly in pitch, not in hertz, so it closes and opens smoothly
	var step := func(t: float) -> void:
		lp.cutoff_hz = from_hz * pow(to_hz / from_hz, t)
		AudioServer.set_bus_volume_db(bi, lerpf(from_db, to_db, t))
	_muffle_tween.tween_method(step, 0.0, 1.0, maxf(secs, 0.01))
	if not on:
		_muffle_tween.tween_callback(func(): AudioServer.set_bus_effect_enabled(bi, 0, false))
