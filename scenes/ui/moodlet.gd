@tool
class_name Moodlet
extends HBoxContainer

## One care stat: an icon, its name, and a bar.
##
## It holds no value of its own and reads nothing from GameState — the panel that
## owns it calls [method set_value]. That keeps this a dumb display, reusable for
## any stat the game grows later.
##
## Only [member fill] is per-instance: the bar's track, border and radius come
## from the theme's ProgressBar, and the colour is what tells one stat from the
## next.
##
## [b]@tool[/b] so the icon, name and colour are visible in the editor rather
## than only at runtime.

## The stat's name, as the player reads it.
@export var stat_name: String = "Hunger": set = _set_stat_name

## Named icon_texture for the same reason as TileButton's — consistency with the
## other component, and it never shadows anything by accident.
@export var icon_texture: Texture2D = null: set = _set_icon_texture

## The bar's colour. One of Palette's accents.
@export var fill: Color = Palette.ORANGE: set = _set_fill

@onready var _icon: TextureRect = %Icon
@onready var _label: Label = %StatName
@onready var _bar: ProgressBar = %Bar

var _slide: Tween = null


func _ready() -> void:
	_refresh()


## Slides the bar to `value`. Called by the popover whenever GameState changes.
##
## It waits BAR_TWEEN_DELAY first. A care action pops the popover open, and
## without the wait the first third of the fill happens while the panel is still
## scaling up — which is the one moment the player is meant to watch it move.
##
## The no-op guard is load-bearing rather than tidy: GameState.changed fires on
## every 60-second heartbeat because the raw float always moves, while
## care_value() usually rounds to the same integer. Without this, three tweens
## would be created every minute for the rest of the session.
func set_value(value: int) -> void:
	if is_equal_approx(_bar.value, float(value)):
		return

	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = create_tween()
	_slide.tween_interval(Palette.BAR_TWEEN_DELAY)
	_slide.tween_property(_bar, "value", float(value), Palette.BAR_TWEEN_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## The value the bar is showing, without animating to it. For the first draw,
## where sliding up from zero would look like the stat had just been restored.
func snap_value(value: int) -> void:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_bar.value = float(value)


func _set_stat_name(value: String) -> void:
	stat_name = value
	_refresh()


func _set_icon_texture(value: Texture2D) -> void:
	icon_texture = value
	_refresh()


func _set_fill(value: Color) -> void:
	fill = value
	_refresh()


## Exported setters fire while the scene is still being built, before @onready
## has run — hence the guard. _ready() calls this once everything exists.
func _refresh() -> void:
	if not is_node_ready():
		return

	_icon.texture = icon_texture
	_icon.custom_minimum_size = Palette.MOODLET_ICON_SIZE
	_label.text = stat_name
	_bar.custom_minimum_size = Vector2(Palette.BAR_MIN_WIDTH, Palette.BAR_HEIGHT)

	# Sizes and spacing come from Palette rather than from the scene, so the whole
	# popover can be retuned in one file.
	add_theme_constant_override(&"separation", Palette.MOODLET_ICON_GAP)
	_label.get_parent().add_theme_constant_override(&"separation", Palette.MOODLET_LABEL_GAP)
	_label.add_theme_font_size_override(&"font_size", Palette.FONT_MOODLET)
	_label.add_theme_color_override(&"font_color", Palette.TEXT_PRIMARY)

	# Skipped in the editor for the same reason tile_button.gd skips its accent:
	# a theme override applied by a @tool script is a real property change, so
	# the editor serialises it into every scene that instances this one — baking
	# the colour in as a literal and defeating the whole point of palette.gd.
	if Engine.is_editor_hint():
		return

	# Built from Palette rather than read from the theme on purpose: a theme
	# lookup made before the node is in the tree silently returns the *default*
	# theme, so the bar would come out grey with no error to explain it.
	_bar.add_theme_stylebox_override(&"fill", Palette.bar_box(fill))
