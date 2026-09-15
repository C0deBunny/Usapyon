extends CanvasLayer

## The hunger display and the one feeding control.
##
## It reads GameState and keeps no hunger value of its own — the bar is redrawn
## from `changed`, whatever moved it. Both the bar and the label show
## care_value(), the same rounded number the feeding rule judges, so what is on
## screen always predicts whether the button will do anything.
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
	var shown: int = BunnyCareRules.care_value(GameState.hunger)
	_hunger_bar.value = shown
	_hunger_value.text = "Hunger %d" % shown


## Section 2.8's flow diagram, all of which lives in GameState.try_feed().
##
## It returns false when the Usapyon is too full for the whole carrot to fit, and
## that is deliberately silent — the button stays enabled and nothing happens.
## The Usapyon refusing for itself is a later milestone; a greyed-out button
## would be a different answer to undo, not a step towards that one.
func _on_feed_pressed() -> void:
	GameState.try_feed(BunnyCareRules.CARROT)
