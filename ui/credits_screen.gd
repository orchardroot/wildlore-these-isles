extends MenuBase
## The end credits: a slow scroll over the world map, then back to the game. Confirm skips.

const LINES := [
	"WILDLORE", "These Isles", "",
	"A walking holiday round the real Isles that turns into a life there", "",
	"Made by orchardroot", "in Cheshire", "under the supervision of two cats", "",
	"Made with the Godot Engine", "",
	"Every creature, character, building and tune was generated from scratch.", "No downloaded art. No downloaded music.", "",
	"Thanks to the hedgehogs, otters, red squirrels, choughs, puffins, wildcats and midges", "of these islands, who did not ask to be in a game", "",
	"And to the legends: the Ddraig, the Green Man, the Morrígan, Manannán's Horse,",
	"the Cù-Sìth, Nessie, Black Shuck, the Lambton Worm, Herne and Bran's Raven,", "who were here first", "",
	"Go outside. Have a look. Mind the herons.", "", "",
	"Thanks for playing.",
]

var _scroll: VBoxContainer
const SKIP_DELAY := 2.0  # a confirm held over from the dialogue must not skip the credits
var _t := 0.0

static func can_skip(elapsed: float) -> bool:
	return elapsed >= SKIP_DELAY

func _build() -> void:
	set_title("")
	set_hints([["confirm", "Skip"]])
	_scroll = VBoxContainer.new()
	_scroll.add_theme_constant_override("separation", 10)
	_scroll.position = Vector2(0, 720)
	_scroll.set_meta("rolls", true)  # TextFitAudit: these lines roll up through the screen on purpose
	content.add_child(_scroll)
	for l in LINES:
		var lab := UIKit.label(l, 44 if l == "WILDLORE" else 28, UIKit.GOLD if l in ["WILDLORE", "Thanks for playing."] else UIKit.CREAM)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.custom_minimum_size = Vector2(1180, 0)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # a long line wraps (Large text) rather than run off the sides
		_scroll.add_child(lab)
	Audio.play_music("credits", 1.0)

func _process(delta: float) -> void:
	_t += delta
	_scroll.position.y = 720.0 - _t * 38.0
	if _scroll.position.y + _scroll.size.y < -40.0:
		close(null)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		if can_skip(_t):
			close(null)
		return
	super._input(event)
