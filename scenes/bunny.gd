extends Node2D

## Blinking is driven from here rather than from an AnimationPlayer, because
## each eye now owns its own texture: an eye being held shut by a finger has to
## sit the blink out while the other one blinks as normal.

const BLINK_DELAY_MIN: float = 2.0
const BLINK_DELAY_MAX: float = 6.0
## How often a blink is followed by a second one.
const DOUBLE_BLINK_CHANCE: float = 0.15
const DOUBLE_BLINK_GAP: float = 0.1
## How long the eyes stay shut during a blink.
const BLINK_CLOSED_TIME: float = 0.08

@onready var blink_timer: Timer = $BlinkTimer
@onready var eye_left: Eye = $Visual/EyeLeft
@onready var eye_right: Eye = $Visual/EyeRight

var _eyes: Array[Eye] = []


func _ready() -> void:
	_eyes = [eye_left, eye_right]
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	_schedule_next_blink()


func _schedule_next_blink() -> void:
	blink_timer.start(randf_range(BLINK_DELAY_MIN, BLINK_DELAY_MAX))


func _on_blink_timer_timeout() -> void:
	await _blink()
	if randf() < DOUBLE_BLINK_CHANCE:
		await get_tree().create_timer(DOUBLE_BLINK_GAP).timeout
		await _blink()
	_schedule_next_blink()


func _blink() -> void:
	var blinking: Array[Eye] = []
	for eye in _eyes:
		if not eye.is_busy():
			blinking.append(eye)
	for eye in blinking:
		eye.close()
	await get_tree().create_timer(BLINK_CLOSED_TIME).timeout
	for eye in blinking:
		eye.open()
