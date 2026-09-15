extends CanvasLayer

## The hunger display and the one feeding control.
##
## It reads GameState and keeps no hunger value of its own — the bar is redrawn
## from `changed`, whatever moved it. The float stays internal; only the label
## rounds, and the rounded number is never written back.
##
## Everything here that is not the button is mouse_filter = IGNORE, so the touch
## surface over the Usapyon stays as small as it can be.

@onready var _hunger_value: Label = %HungerValue
@onready var _hunger_bar: ProgressBar = %HungerBar
@onready var _feed_button: Button = %FeedButton


func _ready() -> void:
	_feed_button.pressed.connect(_on_feed_pressed)
	GameState.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_hunger_bar.value = GameState.hunger
	_hunger_value.text = "Hunger %d" % roundi(GameState.hunger)


## Section 2.8's flow diagram, read top to bottom.
func _on_feed_pressed() -> void:
	GameState.hunger = BunnyCareRules.fed(GameState.hunger, BunnyCareRules.CARROT)
	GameState.fed.emit()
	SaveManager.save()
