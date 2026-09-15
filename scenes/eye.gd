class_name Eye
extends Sprite2D

## One eye. It owns its own texture: neutral normally, closed while a finger
## holds it down and for `release_delay` seconds after the finger lifts.
##
## Blinking is driven from bunny.gd, which asks every eye that is not already
## busy with a hold to close briefly. That is why the eye — not an
## AnimationPlayer — is the one thing that decides which texture is showing.

## Stands in for "no finger". Real touch indices start at 0; the mouse has no
## index of its own, so it borrows MOUSE_INDEX while you test on desktop.
const NO_TOUCH: int = -2
const MOUSE_INDEX: int = -1

@export var closed_texture: Texture2D
## How long the eye stays shut after the finger lifts.
@export var release_delay: float = 0.5

var _neutral_texture: Texture2D
var _held_by: int = NO_TOUCH

@onready var _click_area: Area2D = $ClickArea
## Counts down the gap between the finger lifting and the eye opening again.
var _release_timer: Timer = Timer.new()


func _ready() -> void:
	_neutral_texture = texture
	_release_timer.one_shot = true
	_release_timer.timeout.connect(_on_release_timer_timeout)
	add_child(_release_timer)
	_click_area.input_event.connect(_on_click_area_input_event)


## True while a finger is down or the release delay is still running. Blinking
## leaves a busy eye alone so it cannot pop open underneath the finger.
func is_busy() -> bool:
	return _held_by != NO_TOUCH or not _release_timer.is_stopped()


func close() -> void:
	texture = closed_texture


## Ignored while the eye is busy, so a blink that started just before a touch
## cannot undo the hold when it finishes.
func open() -> void:
	if is_busy():
		return
	texture = _neutral_texture


## Closes the eye and keeps it shut for `seconds` — the happy eyes during a
## feeding hop. It borrows the release timer rather than adding a state, because
## is_busy() already watches that timer, so blinking already knows to leave the
## eye alone for exactly this long.
func hold_shut(seconds: float) -> void:
	close()
	_release_timer.start(seconds)


## Only presses arrive here — a release that happens off the eye would never
## reach the Area2D, so releases are caught globally in _unhandled_input.
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	var index: int = _touch_index(event, true)
	if index == NO_TOUCH:
		return
	# Tapping again during the release delay simply resumes the hold, so the
	# eye never flickers open between the two touches.
	_release_timer.stop()
	_held_by = index
	close()


func _unhandled_input(event: InputEvent) -> void:
	if _held_by == NO_TOUCH:
		return
	if _touch_index(event, false) != _held_by:
		return
	_begin_release()


func _notification(what: int) -> void:
	# Android can take the touch away (a call, the notification shade) without
	# ever sending the release, which would leave the eye shut for good.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _held_by != NO_TOUCH:
		_begin_release()


func _begin_release() -> void:
	_held_by = NO_TOUCH
	_release_timer.start(release_delay)


func _on_release_timer_timeout() -> void:
	texture = _neutral_texture


## The touch index of `event` if it is a press (or release, when `pressed` is
## false) of the kind this eye tracks, and NO_TOUCH for anything else.
func _touch_index(event: InputEvent, pressed: bool) -> int:
	if event is InputEventScreenTouch and event.pressed == pressed:
		return event.index
	if event is InputEventMouseButton and event.pressed == pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		return MOUSE_INDEX
	return NO_TOUCH
