class_name LookArt
extends RefCounted
## Paints the player's look (a character recipe, see Looks) into a walk sheet at runtime, through the same painter
## the sprite generator uses (tools/spritegen/character.gd, in the export). Rendered once per recipe and cached by
## the recipe's content, so walking about never paints; a change of hat paints one sheet.

const Character = preload("res://tools/spritegen/character.gd")
const MAX_CACHED := 24

static var _cache: Dictionary = {}  # recipe key -> ImageTexture
static var _order: Array = []
static var renders := 0  # how many sheets have been painted (tests)

## A stable key: the recipe as JSON with sorted keys.
static func key(recipe: Dictionary) -> String:
	return JSON.stringify(recipe, "", true)

## The 96x192 walk sheet for a recipe (3 columns x 4 rows of 32x48, see CharSprite).
static func texture(recipe: Dictionary) -> ImageTexture:
	var k := key(recipe)
	if _cache.has(k):
		return _cache[k]
	var img: Image = Character.render(recipe)
	var tex := ImageTexture.create_from_image(img)
	renders += 1
	_cache[k] = tex
	_order.append(k)
	while _order.size() > MAX_CACHED:  # the oldest goes; a sheet is 72 KB, so this is tidiness, not thrift
		_cache.erase(_order.pop_front())
	return tex

## One standing frame of the sheet facing `facing` (down, left, right, up), for portraits and previews.
static func frame(recipe: Dictionary, facing := "down") -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = texture(recipe)
	a.region = Rect2(32, CharSprite.ROWS.get(facing, 0) * 48, 32, 48)
	return a

## A TextureRect showing one frame at `scale` times pixel size (menus).
static func frame_rect(recipe: Dictionary, facing := "down", scale := 4.0) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = frame(recipe, facing)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(32, 48) * scale
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

static func clear_cache() -> void:
	_cache.clear()
	_order.clear()
	renders = 0
