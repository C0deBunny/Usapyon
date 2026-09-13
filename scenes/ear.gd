extends Node2D

## One pullable ear. This node sits at the base of the ear and stays pinned
## there: a drag rotates the ear about this origin and stretches it along its own
## length, but never moves the base by more than max_offset. The ear Sprite2D is
## its child and keeps the idle animation's own small rotation, so the drag and
## the idle wobble never write the same property.
##
## The transform is composed rather than set through rotation/scale, because a
## stretch has to run along the ear's resting direction, not along this node's
## vertical. See _stretch_along().
##
## Touch handling mirrors eye.gd: the press is caught on ClickArea, but drag and
## release are caught globally, so a finger that wanders off the ear still works.

## Stands in for "no finger". Real touch indices start at 0; the mouse has no
## index of its own, so it borrows MOUSE_INDEX while you test on desktop.
const NO_TOUCH: int = -2
const MOUSE_INDEX: int = -1

## The ear approaches these limits but never reaches them — see _soft().
@export var max_rotation_degrees: float = 20.0
## Kept very tight: length is a hint that the ear is being tugged, not the point
## of the gesture. Only pulling outward along the ear's own direction reaches it.
@export var max_stretch: float = 1.07
## Deliberately tiny. The base is meant to stay pinned to the head; this is only
## enough give to stop the pull feeling completely rigid.
@export var max_offset: float = 3.0
## How long the ear takes to spring back once released.
@export var spring_duration: float = 0.5

@onready var _click_area: Area2D = $ClickArea
@onready var _tip: Marker2D = $Tip

var _held_by: int = NO_TOUCH

## The node's own transform at startup. Every pull is composed on top of this, so
## the base returns to exactly where it was placed in the editor.
var _rest_transform: Transform2D
## Local angle of the ear tip — the axis a stretch runs along, used to build the
## stretch basis, which works in this node's own space.
var _rest_angle: float
## The same direction in the parent's space, where the finger is measured. Drag
## is projected onto this so that only pulling along the ear lengthens it.
var _rest_axis: Vector2
## Distance from this node to the ear tip. Turns a pull in pixels into a stretch
## ratio: pulling one whole ear-length outward would double the ear's length.
var _rest_length: float

## Angle from the pivot to the finger when it touched down, and how far along the
## ear's axis it was. Everything is measured as a change from these, so grabbing
## the ear low feels the same as grabbing it at the tip and nothing moves until
## the finger does.
var _grab_angle: float
var _grab_along: float

var _spring: Tween

# The three values a pull drives, and the three the spring tweens back. Each
# setter recomposes the transform, so tweening them animates the ear.
var _pull_rotation: float = 0.0:
	set(value):
		_pull_rotation = value
		_apply()
var _pull_stretch: float = 1.0:
	set(value):
		_pull_stretch = value
		_apply()
var _pull_offset: Vector2 = Vector2.ZERO:
	set(value):
		_pull_offset = value
		_apply()


func _ready() -> void:
	_rest_transform = transform
	_rest_angle = _tip.position.angle()
	_rest_axis = _rest_transform.basis_xform(_tip.position).normalized()
	_rest_length = maxf(_tip.position.length(), 1.0)
	_click_area.input_event.connect(_on_click_area_input_event)


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	var index: int = _touch_index(event, true)
	if index == NO_TOUCH:
		return
	_grab(index, _finger_position(event))


func _unhandled_input(event: InputEvent) -> void:
	if _held_by == NO_TOUCH:
		return
	if _drag_index(event) == _held_by:
		_pull(_finger_position(event))
	elif _touch_index(event, false) == _held_by:
		_release()


func _notification(what: int) -> void:
	# Android can take the touch away (a call, the notification shade) without
	# ever sending the release, which would strand the ear mid-pull.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _held_by != NO_TOUCH:
		_release()


func _grab(index: int, finger: Vector2) -> void:
	# A re-grab picks the ear up wherever the spring-back had got to.
	if _spring != null and _spring.is_valid():
		_spring.kill()
	var from_pivot: Vector2 = finger - _rest_transform.origin
	_held_by = index
	_grab_angle = from_pivot.angle()
	_grab_along = from_pivot.dot(_rest_axis)


func _pull(finger: Vector2) -> void:
	var from_pivot: Vector2 = finger - _rest_transform.origin
	var turned: float = wrapf(from_pivot.angle() - _grab_angle, -PI, PI)
	# Length responds only to the part of the drag running outward along the ear.
	# Dragging sideways barely projects onto that axis and so mostly rotates, and
	# dragging back toward the head projects negative and is floored at zero, so
	# nothing can ever make the ear longer by pulling it downward.
	var outward: float = maxf(from_pivot.dot(_rest_axis) - _grab_along, 0.0)

	_pull_rotation = _soft(turned, deg_to_rad(max_rotation_degrees))
	_pull_stretch = 1.0 + _soft(outward / _rest_length, max_stretch - 1.0)
	_pull_offset = _rest_axis * _soft(outward, max_offset)


func _release() -> void:
	_held_by = NO_TOUCH
	_spring = create_tween().set_parallel()
	_spring.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_spring.tween_property(self, "_pull_rotation", 0.0, spring_duration)
	_spring.tween_property(self, "_pull_stretch", 1.0, spring_duration)
	_spring.tween_property(self, "_pull_offset", Vector2.ZERO, spring_duration)


## Rebuilds the node transform from the three pull values. Rotation and stretch
## are both applied about this node's origin, which is why the base stays put:
## the only thing that can move it is _pull_offset, capped at max_offset.
func _apply() -> void:
	if not is_node_ready():
		return
	var pulled: Transform2D = _rest_transform \
			* Transform2D(_pull_rotation, Vector2.ZERO) \
			* _stretch_along(_rest_angle, _pull_stretch)
	pulled.origin = _rest_transform.origin + _pull_offset.limit_length(max_offset)
	transform = pulled


## A stretch of `amount` along `axis_angle`, about the origin. Turn the axis onto
## X, scale X alone, turn back — the CSS equivalent of
## `transform: rotate(a) scaleX(k) rotate(-a)`.
func _stretch_along(axis_angle: float, amount: float) -> Transform2D:
	var along_x := Transform2D(Vector2(amount, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	return Transform2D(axis_angle, Vector2.ZERO) * along_x * Transform2D(-axis_angle, Vector2.ZERO)


## Follows `value` exactly near zero, then eases off so the result approaches
## `limit` without ever reaching it — tanh has slope 1 at 0 and asymptote 1.
func _soft(value: float, limit: float) -> float:
	if is_zero_approx(limit):
		return 0.0
	return limit * tanh(value / limit)


## The finger in this node's parent space, which is where the rest origin lives.
## Measuring it in our own space would feed the drag transform back into the
## input that produced it.
func _finger_position(event: InputEvent) -> Vector2:
	return get_parent().make_input_local(event).position


## Touch index of a press — or of a release, when `pressed` is false — and
## NO_TOUCH if the event is not one this ear tracks.
func _touch_index(event: InputEvent, pressed: bool) -> int:
	if event is InputEventScreenTouch and event.pressed == pressed:
		return event.index
	if event is InputEventMouseButton and event.pressed == pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		return MOUSE_INDEX
	return NO_TOUCH


func _drag_index(event: InputEvent) -> int:
	if event is InputEventScreenDrag:
		return event.index
	if event is InputEventMouseMotion:
		return MOUSE_INDEX
	return NO_TOUCH
