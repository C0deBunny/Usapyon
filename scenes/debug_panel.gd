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
## time to pass — and because catch_up_to() decays all three stats, the time
## buttons cover all three for free.

const HOUR: int = 3600
const STEP: float = 10.0
const FULL: float = 100.0
const LOW: float = 5.0

@onready var _panel: PanelContainer = %Panel
@onready var _hunger_readout: Label = %HungerReadout
@onready var _cleanliness_readout: Label = %CleanlinessReadout
@onready var _happiness_readout: Label = %HappinessReadout


func _ready() -> void:
	%ToggleButton.pressed.connect(_on_toggle_pressed)

	%HungerDown.pressed.connect(_nudge_hunger.bind(-STEP))
	%HungerUp.pressed.connect(_nudge_hunger.bind(STEP))
	%CleanlinessDown.pressed.connect(_nudge_cleanliness.bind(-STEP))
	%CleanlinessUp.pressed.connect(_nudge_cleanliness.bind(STEP))
	%HappinessDown.pressed.connect(_nudge_happiness.bind(-STEP))
	%HappinessUp.pressed.connect(_nudge_happiness.bind(STEP))

	%Plus1h.pressed.connect(_skip_hours.bind(1))
	%Plus6h.pressed.connect(_skip_hours.bind(6))
	%Plus24h.pressed.connect(_skip_hours.bind(24))

	%SaveState.pressed.connect(SaveManager.save)
	%ReloadFromDisk.pressed.connect(SaveManager.load_game)
	%ResetSave.pressed.connect(SaveManager.reset)

	%PresetFresh.pressed.connect(_preset_fresh)
	%PresetNeglected.pressed.connect(_preset_neglected)

	GameState.changed.connect(_refresh)
	_refresh()


## The unrounded values, deliberately — this is the one place that should show
## the stats are floats, so a UI quietly writing a rounded number back would be
## visible here. It is also the only readout left that shows a number at all:
## the moodlet bars have none.
func _refresh() -> void:
	_hunger_readout.text = "Hunger: %.1f" % GameState.hunger
	_cleanliness_readout.text = "Cleanliness: %.1f" % GameState.cleanliness
	_happiness_readout.text = "Happiness: %.1f" % GameState.happiness


func _on_toggle_pressed() -> void:
	_panel.visible = not _panel.visible


func _nudge_hunger(amount: float) -> void:
	GameState.hunger += amount


func _nudge_cleanliness(amount: float) -> void:
	GameState.cleanliness += amount


func _nudge_happiness(amount: float) -> void:
	GameState.happiness += amount


## Completely cared for. Not the same as a new game — Reset Save produces that,
## and a new Usapyon starts at STARTING_VALUE so the first carrot has somewhere
## to go.
func _preset_fresh() -> void:
	GameState.hunger = FULL
	GameState.cleanliness = FULL
	GameState.happiness = FULL


## Everything at once — the state the moodlet popover is most worth looking at,
## and the only way to see three nearly-empty bars, and the angry face, without
## waiting a day.
func _preset_neglected() -> void:
	GameState.hunger = LOW
	GameState.cleanliness = LOW
	GameState.happiness = LOW


## Moves the clock back and lets the ordinary catch-up notice, which is exactly
## what a cold launch after that long away does.
func _skip_hours(hours: int) -> void:
	GameState.last_ticked_at -= hours * HOUR
	GameState.catch_up_to(GameState.now())
