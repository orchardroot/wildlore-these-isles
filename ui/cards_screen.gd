extends MenuBase
## The Trumps album as a screen of its own (Almanac page "Trumps cards", menu "cards"; `cards:<region>` opens on one).

var _tab: CardsTab

func _build() -> void:
	set_title("Trumps cards")
	Trumps.use_dex(Game.dex)
	header_right.text = Game.data.player_name
	_tab = CardsTab.new(self)
	_tab.build(content)
	set_hints([["updown", "Regions"], ["cancel", "Back"]])
