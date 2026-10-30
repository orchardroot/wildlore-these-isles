class_name CreatureActor
extends Node3D
## One creature on the diorama: a billboard Sprite3D with a gentle idle, a soft blob shadow and a few reaction tweens.

const HEIGHT := 2.2
const PX := HEIGHT / 96.0   # per pixel of a 96 px frame; sheets drawn finer scale it down (see _fit_sheet)

var sprite: Sprite3D
var shadow: MeshInstance3D
var home := Vector3.ZERO
var _t := randf() * 4.0
var _squash := Vector3.ONE   # extra scale applied by tweens
var _tween: Tween
var marker: MeshInstance3D  # the bobbing arrow over a creature being picked as a target (doubles)
var coat := ""              # an uncommon coat: it glints as it pops in (see CoatArt)

static var _blob: GradientTexture2D

func _ready() -> void:
	sprite = Sprite3D.new()
	sprite.hframes = 2
	sprite.pixel_size = PX
	sprite.offset = Vector2(0, 48)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = true
	sprite.double_sided = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sprite.modulate = Color(1.12, 1.12, 1.12)
	add_child(sprite)
	shadow = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.2, 1.3)
	q.orientation = PlaneMesh.FACE_Y
	shadow.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _blob_texture()
	m.render_priority = -1
	shadow.material_override = m
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.position.y = 0.03
	add_child(shadow)

static func _blob_texture() -> GradientTexture2D:
	if _blob == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0)])
		_blob = GradientTexture2D.new()
		_blob.gradient = g
		_blob.fill = GradientTexture2D.FILL_RADIAL
		_blob.fill_from = Vector2(0.5, 0.5)
		_blob.fill_to = Vector2(1.0, 0.5)
		_blob.width = 64
		_blob.height = 64
	return _blob

func show_creature(c: Creature, is_back: bool) -> void:
	var stem := Sexes.art_id(str(c.species.get("sprite", c.species.id)), "back" if is_back else "front", c.sex)  # the sheet for its sex, if any
	var base_tex := FormArt.texture(CreatureArt.texture(c.species, is_back, c.sex), "%s/%s" % [stem, is_back], str(c.species.id), c.form)
	sprite.texture = CoatArt.texture(base_tex, "%s/%s#%s" % [stem, is_back, c.form], c.variant)
	fit_sheet()
	coat = c.variant
	sprite.visible = true
	sprite.modulate = Color(1.12, 1.12, 1.12)
	_squash = Vector3.ONE
	sprite.position = Vector3.ZERO
	shadow.visible = true

## Sizes the billboard to its sheet: the same height in the world whatever the sheet's resolution. A fine
## (anti-aliased) sheet is filtered smoothly with soft alpha edges; an old 96 px one stays crisp.
func fit_sheet() -> void:
	if sprite == null or sprite.texture == null:
		return
	var fp := float(maxi(1, sprite.texture.get_height()))
	sprite.pixel_size = HEIGHT / fp
	sprite.offset = Vector2(0, fp * 0.5)
	var fine := fp > 96.0
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR if fine else BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS if fine else SpriteBase3D.ALPHA_CUT_DISCARD

func _process(delta: float) -> void:
	_t += delta
	if sprite == null or sprite.texture == null:
		return
	sprite.frame = int(_t / 0.6) % 2
	if marker and marker.visible:
		marker.position.y = HEIGHT + 0.55 + sin(_t * 6.0) * 0.12
		marker.rotation.y += delta * 2.0
	var breathe := 1.0 + sin(_t * 2.6) * 0.012
	sprite.scale = Vector3(_squash.x / breathe, _squash.y * breathe, 1.0)
	shadow.scale = Vector3(_squash.x, 1.0, _squash.x)

func _kill() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	position = home

## A bright white flash colour, toned down when "reduce flashing" is on.
func _flash_white(v: float) -> Color:
	var g := 1.3 if Settings.reduce_flashing else v
	return Color(g, g, g)

func pop_in() -> void:
	_kill()
	_squash = Vector3(0.1, 0.1, 1.0)
	sprite.modulate = _flash_white(3.0)
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_squash", Vector3.ONE, 0.45)
	_tween.tween_property(sprite, "modulate", Color(1.12, 1.12, 1.12), 0.5).set_trans(Tween.TRANS_SINE)
	CoatArt.glint(self, coat, HEIGHT)
	await _tween.finished

func pop_out() -> void:
	_kill()
	sprite.modulate = _flash_white(3.0)
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_squash", Vector3(0.05, 0.05, 1.0), 0.28)
	await _tween.finished
	sprite.visible = false
	shadow.visible = false

## Dash towards `to` and back.
func lunge(to: Vector3) -> void:
	_kill()
	var dir := (to - home)
	dir.y = 0
	dir = dir.normalized()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "position", home - dir * 0.25, 0.12).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", home + dir * 1.4, 0.11).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "position", home, 0.22).set_ease(Tween.EASE_OUT)
	await _tween.finished

## Rear up and settle: the wind-up for a special, status or weather move (no dash). Not awaited by BattleFX.
func cast() -> void:
	_kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_squash", Vector3(0.9, 1.14, 1.0), 0.14).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "position", home + Vector3(0, 0.22, 0), 0.14).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_squash", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "position", home, 0.22).set_ease(Tween.EASE_IN)
	await _tween.finished

func hit(strength := "normal", tint := Color.WHITE) -> void:
	_kill()
	var k := 0.35 if strength == "strong" else (0.12 if strength == "weak" else 0.22)
	var gentle := Settings.reduce_flashing  # one soft tint and a slow wobble instead of six rapid white flashes
	if gentle:
		k *= 0.4
	_tween = create_tween()
	for i in (2 if gentle else 6):
		var s := 1.0 if i % 2 == 0 else -1.0
		var step := 0.14 if gentle else 0.05
		_tween.tween_property(self, "position:x", home.x + s * k * (1.0 - i / 6.0), step)
		var flash := Color(1.35, 1.15, 1.15) if gentle else Color(3.0, 1.6, 1.6)
		if tint != Color.WHITE:  # the move's type colour tints the flash (one bright channel mix, same peak brightness)
			flash = Color(1.0 + tint.r * (0.3 if gentle else 1.8), 1.0 + tint.g * (0.3 if gentle else 1.8), 1.0 + tint.b * (0.3 if gentle else 1.8))
		_tween.parallel().tween_property(sprite, "modulate", flash if i % 2 == 0 else Color(1.12, 1.12, 1.12), step)
	_tween.tween_property(self, "position", home, 0.04)
	_tween.tween_property(sprite, "modulate", Color(1.12, 1.12, 1.12), 0.02)
	await _tween.finished

func dodge() -> void:
	_kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", home + Vector3(0.9, 0.3, 0), 0.14)
	_tween.tween_property(self, "position", home, 0.2).set_ease(Tween.EASE_IN)
	await _tween.finished

func nod() -> void:
	_kill()
	_tween = create_tween()
	_tween.tween_property(self, "_squash", Vector3(1.05, 0.9, 1.0), 0.12)
	_tween.tween_property(self, "_squash", Vector3.ONE, 0.16)
	await _tween.finished

func faint() -> void:
	_kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "_squash", Vector3(1.15, 0.02, 1.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(sprite, "modulate:a", 0.0, 0.7)
	await _tween.finished
	sprite.visible = false
	shadow.visible = false

func slip_away() -> void:
	_kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position", home + Vector3(-5.0, 0, 2.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	await _tween.finished
	sprite.visible = false
	shadow.visible = false

## Shrinks into / out of the snare.
func absorb(into: bool) -> void:
	_kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	if into:
		sprite.modulate = _flash_white(2.4)
		_tween.tween_property(self, "_squash", Vector3(0.06, 0.06, 1.0), 0.35)
	else:
		_tween.tween_property(self, "_squash", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		_tween.tween_property(sprite, "modulate", Color(1.12, 1.12, 1.12), 0.3)
	await _tween.finished

## Show or hide the target arrow over this creature.
func set_marked(on: bool) -> void:
	if marker == null:
		if not on:
			return
		marker = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.42
		cone.bottom_radius = 0.0
		cone.height = 0.7
		cone.radial_segments = 4
		cone.rings = 1
		marker.mesh = cone
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color("ffc52e")
		marker.material_override = m
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)
	marker.visible = on
	if sprite:
		sprite.modulate = Color(1.5, 1.45, 1.2) if on else Color(1.12, 1.12, 1.12)

func world_centre() -> Vector3:
	return global_position + Vector3(0, HEIGHT * 0.5, 0)
