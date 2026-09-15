extends CanvasLayer

## Developer-only controls. main.gd only instances this when OS.is_debug_build(),
## so it is compiled in but never reaches a player — see docs/conventions.md.
##
## Nothing here writes the save file except Save Current State. That is the whole
## point of the panel: you can put the runtime into a strange state, look at it,
## and then press Reload From Disk to find the real save untouched.
##
## The time buttons do not have their own decay maths. They rewind the clock and
## call the same catch-up a cold launch does, so there is only ever one way for
## time to pass.

const HOUR: int = 3600
const HUNGER_STEP: float = 10.0
const FRESH_HUNGER: float = 100.0
const HUNGRY_HUNGER: float = 5.0

@onready var _panel: PanelContainer = %Panel
@onready var _readout: Label = %HungerReadout


func _ready() -> void:
	%ToggleButton.pressed.connect(_on_toggle_pressed)

	%HungerDown.pressed.connect(_nudge_hunger.bind(-HUNGER_STEP))
	%HungerUp.pressed.connect(_nudge_hunger.bind(HUNGER_STEP))

	%Plus1h.pressed.connect(_skip_hours.bind(1))
	%Plus6h.pressed.connect(_skip_hours.bind(6))
	%Plus24h.pressed.connect(_skip_hours.bind(24))

	%SaveState.pressed.connect(SaveManager.save)
	%ReloadFromDisk.pressed.connect(SaveManager.load_game)
	%ResetSave.pressed.connect(SaveManager.reset)

	%PresetFresh.pressed.connect(_set_hunger.bind(FRESH_HUNGER))
	%PresetHungry.pressed.connect(_set_hunger.bind(HUNGRY_HUNGER))

	GameState.changed.connect(_refresh)
	_refresh()


## The unrounded value, deliberately — this is the one place that should show
## that hunger is a float, so a UI quietly writing a rounded number back would
## be visible here.
func _refresh() -> void:
	_readout.text = "Hunger: %.1f" % GameState.hunger


func _on_toggle_pressed() -> void:
	_panel.visible = not _panel.visible


func _set_hunger(value: float) -> void:
	GameState.hunger = value


func _nudge_hunger(amount: float) -> void:
	GameState.hunger += amount


## Moves the clock back and lets the ordinary catch-up notice, which is exactly
## what a cold launch after that long away does.
func _skip_hours(hours: int) -> void:
	GameState.last_ticked_at -= hours * HOUR
	GameState.catch_up_to(GameState.now())
