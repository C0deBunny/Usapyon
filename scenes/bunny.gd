extends Node2D

## Blinking is driven from here rather than from an AnimationPlayer, because
## each eye now owns its own texture: an eye being held shut by a finger has to
## sit the blink out while the other one blinks as normal.
##
## The feeding reaction lives here too. It tweens the Bounce node rather than
## Visual, because the idle animation writes Visual:position and Visual:scale
## every frame on loop — a tween on those loses to the AnimationPlayer silently,
## with no error to explain why. Same split ear.gd already uses for the drag.

const BLINK_DELAY_MIN: float = 2.0
const BLINK_DELAY_MAX: float = 6.0
## How often a blink is followed by a second one.
const DOUBLE_BLINK_CHANCE: float = 0.15
const DOUBLE_BLINK_GAP: float = 0.1
## How long the eyes stay shut during a blink.
const BLINK_CLOSED_TIME: float = 0.08

## The happy hop: up, land with a squash, settle.
const HOP_HEIGHT: float = 55.0
const HOP_RISE_TIME: float = 0.18
const HOP_FALL_TIME: float = 0.2
const HOP_SETTLE_TIME: float = 0.18
const HOP_STRETCH: Vector2 = Vector2(0.93, 1.07)
const HOP_SQUASH: Vector2 = Vector2(1.08, 0.92)

@onready var blink_timer: Timer = $BlinkTimer
@onready var bounce: Node2D = $Bounce
@onready var eye_left: Eye = $Bounce/Visual/EyeLeft
@onready var eye_right: Eye = $Bounce/Visual/EyeRight

var _eyes: Array[Eye] = []
var _hop: Tween


func _ready() -> void:
	_eyes = [eye_left, eye_right]
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	_schedule_next_blink()
	# `fed`, not `changed` — `changed` also fires when it gets hungrier.
	GameState.fed.connect(celebrate)


## A happy hop with the eyes squeezed shut. The eyes are held for exactly as long
## as the hop lasts, so a blink cannot open them halfway through.
func celebrate() -> void:
	if _hop != null and _hop.is_valid():
		_hop.kill()
	for eye in _eyes:
		eye.hold_shut(HOP_RISE_TIME + HOP_FALL_TIME + HOP_SETTLE_TIME)

	_hop = create_tween()
	_hop.tween_property(bounce, "position:y", -HOP_HEIGHT, HOP_RISE_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop.parallel().tween_property(bounce, "scale", HOP_STRETCH, HOP_RISE_TIME)
	_hop.tween_property(bounce, "position:y", 0.0, HOP_FALL_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_hop.parallel().tween_property(bounce, "scale", HOP_SQUASH, HOP_FALL_TIME)
	_hop.tween_property(bounce, "scale", Vector2.ONE, HOP_SETTLE_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
