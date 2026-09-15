extends Control

## The stats popover: a button in the top-left corner and the card it opens.
##
## Not a modal. Nothing is dimmed and nothing is blocked — the Usapyon stays
## tappable, its ears stay draggable, and the care tiles stay live while the
## popover is up. The button is a plain toggle.
##
## It also opens itself whenever a care action lands, which is the point: you tap
## Feed and the popover arrives in time to show you the bar filling. A popover
## that opened on its own tidies itself away again; one the player opened by hand
## is on no clock and stays until they close it.
##
## The button's face is the Usapyon's, not the popover's. It follows the worst of
## the three stats, so the corner of the screen says how things are going without
## the popover being open at all.
##
## The popover reads GameState and keeps no values of its own. It refreshes while
## closed too, so opening it never shows a stale bar sliding into place.

## Long enough to read as a pop, short enough not to be in the way.
const OPEN_TIME: float = 0.18
const CLOSE_TIME: float = 0.12
## What the popover scales up from. Not zero — a card that grows from nothing
## reads as a puff of smoke rather than as something unfolding.
const START_SCALE: Vector2 = Vector2(0.85, 0.85)
## How long a self-opened popover stays up. Long enough to watch a bar finish
## filling (BAR_TWEEN_DELAY + BAR_TWEEN_TIME) and then read it.
const AUTO_CLOSE_SECONDS: float = 2.5

## The three faces, set in the scene so the art stays out of the script.
@export var face_happy: Texture2D = null
@export var face_sad: Texture2D = null
@export var face_angry: Texture2D = null

@onready var _popover: Control = %Popover
@onready var _button: Button = %MoodletButton

@onready var _hunger: Moodlet = %HungerMoodlet
@onready var _cleanliness: Moodlet = %CleanlinessMoodlet
@onready var _happiness: Moodlet = %HappinessMoodlet

var _is_open: bool = false
var _motion: Tween = null
var _auto_close: Timer = Timer.new()


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)
	GameState.changed.connect(_refresh)
	GameState.cared.connect(_on_cared)

	_auto_close.wait_time = AUTO_CLOSE_SECONDS
	_auto_close.one_shot = true
	_auto_close.timeout.connect(close)
	add_child(_auto_close)

	# Stated rather than left to the default: the popover must grow out of the
	# button, which means scaling about the corner nearest it. Centred — Godot's
	# behaviour if anyone nudges this in the editor — would read as the card
	# inflating in mid-air.
	_popover.pivot_offset = Vector2.ZERO

	_snap_to_current()
	_refresh_face()
	_popover.visible = false


func open() -> void:
	if _is_open:
		return
	_is_open = true
	_popover.visible = true

	if _motion != null and _motion.is_valid():
		_motion.kill()
	_popover.scale = START_SCALE
	_motion = create_tween()
	_motion.tween_property(_popover, "scale", Vector2.ONE, OPEN_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not _is_open:
		return
	_is_open = false

	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = create_tween()
	_motion.tween_property(_popover, "scale", START_SCALE, CLOSE_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Hidden only once it has finished shrinking, or it would vanish mid-tween.
	_motion.tween_callback(_hide_popover)


## Redraws from GameState. Runs while closed as well, so the popover is already
## correct the instant it opens and nothing slides into place in front of the
## player.
func _refresh() -> void:
	_hunger.set_value(BunnyCareRules.care_value(GameState.hunger))
	_cleanliness.set_value(BunnyCareRules.care_value(GameState.cleanliness))
	_happiness.set_value(BunnyCareRules.care_value(GameState.happiness))
	_refresh_face()


## The worst stat decides the face, so one neglected stat is enough to show — a
## Usapyon that is fed but filthy should not look delighted.
func _refresh_face() -> void:
	var worst: int = mini(
		BunnyCareRules.care_value(GameState.hunger),
		mini(
			BunnyCareRules.care_value(GameState.cleanliness),
			BunnyCareRules.care_value(GameState.happiness)
		)
	)

	if worst < BunnyCareRules.CRITICAL_VALUE:
		_button.icon = face_angry
	elif worst < BunnyCareRules.LOW_VALUE:
		_button.icon = face_sad
	else:
		_button.icon = face_happy


## The first draw. Sliding up from whatever the scene was saved with would read
## as three stats being restored at once the moment the game starts.
func _snap_to_current() -> void:
	_hunger.snap_value(BunnyCareRules.care_value(GameState.hunger))
	_cleanliness.snap_value(BunnyCareRules.care_value(GameState.cleanliness))
	_happiness.snap_value(BunnyCareRules.care_value(GameState.happiness))


## A care action landed. Show the bar moving.
##
## The countdown only starts if the popover was closed: a player who opened it by
## hand has said they want it up, and feeding should not then take it away.
func _on_cared() -> void:
	var was_closed: bool = not _is_open
	open()
	if was_closed:
		_auto_close.start()


func _on_button_pressed() -> void:
	# Whatever happens next was asked for by hand, so cancel any countdown left
	# over from a care action.
	_auto_close.stop()
	if _is_open:
		close()
	else:
		open()


func _hide_popover() -> void:
	_popover.visible = false
