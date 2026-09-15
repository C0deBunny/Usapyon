extends CanvasLayer

## The three care controls, and the modal that shows what they are for.
##
## It holds no values and draws no stats — the moodlet panel is self-contained
## and reads GameState itself, so all this script does is turn three taps into
## three gameplay actions.
##
## Everything here that is not a button is mouse_filter = IGNORE, so the touch
## surface over the Usapyon stays as small as it can be.

@onready var _feed_button: Button = %FeedButton
@onready var _clean_button: Button = %CleanButton
@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	_feed_button.pressed.connect(_on_feed_pressed)
	_clean_button.pressed.connect(_on_clean_pressed)
	_play_button.pressed.connect(_on_play_pressed)


## Section 2.8's flow diagram, all of which lives in GameState.
##
## Each returns false when the Usapyon is too full, clean or content for the
## whole amount to fit, and that is deliberately silent — the button stays
## enabled and nothing happens. The Usapyon refusing for itself is a later
## milestone; a greyed-out button would be a different answer to undo, not a
## step towards that one.
func _on_feed_pressed() -> void:
	GameState.try_feed(BunnyCareRules.CARROT)


func _on_clean_pressed() -> void:
	GameState.try_clean(BunnyCareRules.SPONGE)


func _on_play_pressed() -> void:
	GameState.try_play(BunnyCareRules.BALL)
