extends AudioStreamPlayer

## Background music, playing for as long as the app is open.
##
## Looping is the stream's own job — Loop is ticked on the Ogg's import settings —
## so this script only owns the fades.

## Quiet enough to be inaudible, but still a real level, so a fade has somewhere to
## travel from. Fading to -80 spends most of its time in silence.
const SILENT_DB: float = -40.0

## The actual volume knob. Setting `volume_db` in the inspector does nothing lasting,
## because `_ready()` overwrites it before the first fade.
@export var target_volume_db: float = 0.0
@export var fade_duration: float = 1.5

var _fade: Tween


func _ready() -> void:
	volume_db = SILENT_DB
	fade_in()


func fade_in(duration: float = -1.0) -> void:
	stream_paused = false
	if not playing:
		play()
	_fade_to(target_volume_db, duration)


func fade_out(duration: float = -1.0) -> void:
	_fade_to(SILENT_DB, duration).tween_callback(_pause)


## One tween at a time — killing the old one first means an interrupted fade-out
## cannot keep running, and its pending _pause() callback never fires.
func _fade_to(db: float, duration: float) -> Tween:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "volume_db", db, duration if duration >= 0.0 else fade_duration)
	return _fade


func _pause() -> void:
	stream_paused = true
