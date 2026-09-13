extends Node2D

## Usapyon's bunny: idles gently, squashes when tapped.
##
## Two nested transform nodes keep the animations from fighting over one scale
## property -- the same reason you'd wrap an element so two CSS animations can
## run independently. Body owns the tap squash, Breath owns the idle breathing.

signal tapped

const BREATH_AMOUNT := 0.025
const BREATH_TIME := 1.8

const SQUASH_SCALE := Vector2(1.22, 0.78)
const SQUASH_IN_TIME := 0.08
const SQUASH_OUT_TIME := 0.5

@onready var _body: Node2D = $Body
@onready var _breath: Node2D = $Body/Breath
@onready var _sprite: Sprite2D = $Body/Breath/Sprite
@onready var _hearts: CPUParticles2D = $Hearts

var _squash_tween: Tween


func _ready() -> void:
	_pivot_at_feet()
	_start_breathing()


## Squash and stretch only reads as weight if it pivots on the ground, so the
## sprite is shifted up until its bottom edge sits on this node's origin.
## Derived from the texture, so swapping in new art needs no other change.
func _pivot_at_feet() -> void:
	if _sprite.texture:
		_sprite.offset.y = -_sprite.texture.get_height() * 0.5


func _start_breathing() -> void:
	var breathing := create_tween().set_loops()
	breathing.tween_property(_breath, "scale",
			Vector2(1.0 - BREATH_AMOUNT, 1.0 + BREATH_AMOUNT), BREATH_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing.tween_property(_breath, "scale", Vector2.ONE, BREATH_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func react_to_tap() -> void:
	if _squash_tween and _squash_tween.is_running():
		_squash_tween.kill()

	_squash_tween = create_tween()
	_squash_tween.tween_property(_body, "scale", SQUASH_SCALE, SQUASH_IN_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(_body, "scale", Vector2.ONE, SQUASH_OUT_TIME) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	_hearts.restart()
	tapped.emit()


## Handles both event types so taps work on device and clicks work in the
## editor, without switching on mouse-to-touch emulation project-wide.
func _on_tap_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var is_press := false
	if event is InputEventScreenTouch:
		is_press = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		is_press = click.pressed and click.button_index == MOUSE_BUTTON_LEFT

	if is_press:
		react_to_tap()
