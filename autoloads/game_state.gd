extends Node

## What your Usapyon's values ARE, and when they advance. How *much* they change
## by lives in BunnyCareRules and is never decided here.
##
## Autoload. It must be registered before SaveManager, because SaveManager's
## _ready() writes into this — autoload order is instantiation order.
##
## The load-bearing idea is that offline progression is not a special case:
## catch_up_to() is the only thing that moves the clock, and launch, the
## heartbeat, resume-from-background, Reload From Disk and the debug time
## buttons all call it. Double-charging the same seconds and losing a session's
## hours are therefore not bugs this code has a shape for.

## Anything that redraws listens to this. It fires on the heartbeat and on every
## debug tweak too, so it is not a "something nice happened" signal.
signal changed

## The one moment that deserves a reaction. Separate from `changed` so a Usapyon
## cannot end up bouncing happily because it got hungrier.
signal fed

## Long enough to cost nothing, short enough that an unsaved gap stays small.
const HEARTBEAT_SECONDS: float = 60.0

## The raw value. `hunger` below is the only thing that should ever write it.
var _hunger: float = BunnyCareRules.STARTING_HUNGER

## Assignment has side effects, which is unusual enough to say out loud: writing
## `GameState.hunger = 5` clamps to 0..100 and emits `changed`. That is the
## point — the debug panel assigns to it directly, and a convention nobody can
## enforce would let that write skip both.
var hunger: float:
	set(value):
		var clamped: float = clampf(
			value, BunnyCareRules.MIN_HUNGER, BunnyCareRules.MAX_HUNGER
		)
		# Silence when nothing moved: once hunger sits at 0 the heartbeat would
		# otherwise announce no change sixty times an hour.
		if is_equal_approx(clamped, _hunger):
			return
		_hunger = clamped
		changed.emit()
	get:
		return _hunger

## When time was last accounted for — which is not the same question as when the
## file was last written, since saves only happen at meaningful checkpoints.
var last_ticked_at: int = 0

var _heartbeat: Timer = Timer.new()


func _ready() -> void:
	last_ticked_at = now()
	_heartbeat.wait_time = HEARTBEAT_SECONDS
	_heartbeat.timeout.connect(_on_heartbeat)
	add_child(_heartbeat)
	_heartbeat.start()


## The device clock, in whole seconds. Every caller reads time through here.
func now() -> int:
	return int(Time.get_unix_time_from_system())


## Advances the world to `now`, whether that is one minute or three weeks away.
func catch_up_to(current_time: int) -> void:
	# A clock moved backwards — a timezone, DST, or a curious player — would
	# otherwise hand out free food.
	var elapsed: int = maxi(0, current_time - last_ticked_at)
	hunger = BunnyCareRules.decayed(hunger, float(elapsed))
	last_ticked_at = current_time


## Eats `amount`, if the Usapyon has room for all of it. Returns whether it ate.
##
## The whole action lives here rather than in the button that happens to trigger
## it today, because `fed` is this object's signal and nothing outside should be
## emitting it — and because dragging a carrot onto the Usapyon, which the
## milestone already anticipates, would otherwise have to repeat the rule.
##
## Refusing a feed that would overcap is what stops food being wasted, and later
## what stops Care Points being farmed by tapping a full Usapyon forever. The
## limit is not a threshold anyone wrote down: it comes from the food's own size.
##
## The return value is unused today. It is what a refusal reaction will read.
func try_feed(amount: float) -> bool:
	if not BunnyCareRules.can_eat(hunger, amount):
		return false
	hunger = BunnyCareRules.fed(hunger, amount)
	fed.emit()
	SaveManager.save()
	return true


## A brand-new Usapyon. The starting value is a gameplay number, so it comes from
## BunnyCareRules rather than from SaveManager.
func reset_to_new() -> void:
	hunger = BunnyCareRules.STARTING_HUNGER
	last_ticked_at = now()


func _on_heartbeat() -> void:
	catch_up_to(now())


func _notification(what: int) -> void:
	# Android's own backgrounding notification. FOCUS_OUT is deliberately not
	# used for saving: it fires on every desktop window switch, and ear.gd and
	# eye.gd already use it to release a stranded gesture.
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		catch_up_to(now())
