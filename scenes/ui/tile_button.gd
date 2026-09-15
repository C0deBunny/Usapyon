@tool
class_name TileButton
extends Button

## One care action: an icon above a caption.
##
## Shape, border and resting colour come from the theme's TileButton variation.
## Only [member accent] is per-tile, because the tiles all rest cream and take on
## their action's colour only while held.
##
## It is a Button rather than a Control wrapping one, so callers still get
## [signal BaseButton.pressed] and every other button behaviour for free.
##
## [b]@tool[/b] so the icon and caption are visible in the editor rather than
## only at runtime.

## Word under the icon.
@export var caption: String = "Feed": set = _set_caption

## Named icon_texture, not icon, so it does not shadow [member Button.icon].
@export var icon_texture: Texture2D = null: set = _set_icon_texture

## Fill while held. One of Palette's ACCENT_ constants.
@export var accent: Color = Palette.ACCENT_FEED: set = _set_accent

@onready var _icon: TextureRect = %Icon
@onready var _caption: Label = %Caption


func _ready() -> void:
	custom_minimum_size = Palette.TILE_MIN_SIZE
	_refresh()


func _set_caption(value: String) -> void:
	caption = value
	_refresh()


func _set_icon_texture(value: Texture2D) -> void:
	icon_texture = value
	_refresh()


func _set_accent(value: Color) -> void:
	accent = value
	_refresh()


## Exported setters fire while the scene is still being built, before @onready
## has run — hence the guard. _ready() calls this once everything exists.
func _refresh() -> void:
	if not is_node_ready():
		return

	_icon.texture = icon_texture
	_icon.custom_minimum_size = Palette.ICON_SIZE

	# The caption is a Label, so left alone it would take the theme's default
	# face rather than the heavier one the theme sets for button text. It is
	# button text; borrow the Button font. Safe to look up here — is_node_ready()
	# above means we are in the tree and the theme resolves properly.
	_caption.text = caption
	_caption.add_theme_font_override(&"font", get_theme_font(&"font"))
	_caption.add_theme_font_size_override(&"font_size", Palette.FONT_BUTTON)
	_caption.add_theme_color_override(&"font_color", Palette.INK)

	# Skipped in the editor on purpose. A theme override applied by a @tool script
	# is a real property change, so the editor serialises it into every scene that
	# instances this one — baking the accent in as a literal colour and defeating
	# the whole point of palette.gd. Nothing is lost: a pressed state is invisible
	# at rest anyway.
	if Engine.is_editor_hint():
		return

	# Built here rather than read from the theme on purpose: a theme lookup made
	# before the node enters the tree silently returns the *default* theme, so
	# the tile would come out grey with no error to explain it.
	add_theme_stylebox_override(&"pressed", Palette.tile_box(accent, false))
	add_theme_stylebox_override(&"hover_pressed", Palette.tile_box(accent, false))
