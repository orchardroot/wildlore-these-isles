class_name PortraitMotion
extends RefCounted
## Idle motion for the creature pictures on the Summary and Fieldbook pages (wave 49). The same Motion styles as the
## battle actor and the follower, drawn by a tiny vertex shader so a picture inside a container can still travel and
## squash. Pure maths in `frame_for`; `attach` puts the shader on an AnimSprite.

const SHADER_CODE := """
shader_type canvas_item;
uniform vec2 shift = vec2(0.0);
uniform vec2 squash = vec2(1.0);
uniform vec2 pivot = vec2(0.0);
void vertex() {
	VERTEX = (VERTEX - pivot) * squash + pivot + shift;
}
"""

## Portraits travel less than a battle sprite does: the frame has to hold them.
const TRAVEL := 0.7
## Reduce Flashing keeps the idle but slows and shrinks it (and a flutter's shimmer with it).
const GENTLE_SPEED := 0.4

static var _shader: Shader

static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader

## A fresh shader material (one per picture, so each keeps its own shift).
static func material_for() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader()
	return m

## Pixel shift and squash for a picture `height` px tall at time t. The floating height of the style is taken off so the
## creature rests where its picture was drawn; `gentle` (flash_scale) shrinks the travel and slows the clock.
static func frame_for(style: String, t: float, height: float, phase := 0.0, gentle := 1.0) -> Dictionary:
	var slow := 1.0 if gentle >= 1.0 else GENTLE_SPEED
	var r := Motion.idle(style, t * slow, phase)
	var lift: float = Motion.params(style).lift
	var px := height / 2.2 * TRAVEL * gentle  # Motion works in world units; a battle sprite is 2.2 tall
	var off: Vector2 = r.pos
	var sq: Vector2 = r.squash
	return {"shift": Vector2(off.x * px, -(off.y - lift) * px), "squash": Vector2.ONE.lerp(sq, gentle)}
