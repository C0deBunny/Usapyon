extends SceneTree

## Builds usapyon_theme.tres from the constants in palette.gd.
##
## The theme is generated output. Editing it in Godot's Theme panel works, and is
## then destroyed the next time this runs — change palette.gd instead, and
## re-run:
##
##     godot --headless --path . --script res://scenes/ui/theme/build_theme.gd
##
## It is a SceneTree script rather than an EditorScript so it runs without the
## editor, which means Claude and CI can regenerate the theme too.

const OUTPUT_PATH: String = "res://scenes/ui/theme/usapyon_theme.tres"
const FONT_BODY_PATH: String = "res://assets/fonts/Fredoka-SemiBold.ttf"
const FONT_BUTTON_PATH: String = "res://assets/fonts/Fredoka-Bold.ttf"


func _initialize() -> void:
	var theme := Theme.new()
	_define_defaults(theme)
	_define_button(theme)
	_define_primary_button(theme)
	_define_tile_button(theme)
	_define_icon_button(theme)
	_define_panel(theme)
	_define_progress_bar(theme)
	_define_containers(theme)

	var error: Error = ResourceSaver.save(theme, OUTPUT_PATH)
	if error == OK:
		print("Wrote ", OUTPUT_PATH)
	else:
		push_error("Could not write %s (error %d)" % [OUTPUT_PATH, error])
	quit(OK if error == OK else 1)


func _define_defaults(theme: Theme) -> void:
	theme.default_font_size = Palette.FONT_BODY
	var body: Font = _load_font(FONT_BODY_PATH)
	if body != null:
		theme.default_font = body


## The secondary button, and the look anything unstyled falls back to.
func _define_button(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", Palette.box(Palette.SECONDARY, Palette.RADIUS_BUTTON, true))
	theme.set_stylebox("pressed", "Button", Palette.box(Palette.SECONDARY_PRESSED, Palette.RADIUS_BUTTON, false))
	theme.set_stylebox("disabled", "Button", Palette.box(Palette.DISABLED, Palette.RADIUS_BUTTON, false))

	theme.set_color("font_color", "Button", Palette.TEXT_PRIMARY)
	theme.set_color("font_pressed_color", "Button", Palette.TEXT_PRIMARY)
	theme.set_color("font_disabled_color", "Button", Palette.TEXT_MUTED)

	theme.set_font_size("font_size", "Button", Palette.FONT_BUTTON)
	var button_font: Font = _load_font(FONT_BUTTON_PATH)
	if button_font != null:
		theme.set_font("font", "Button", button_font)

	_silence_pointer_states(theme, "Button")


func _define_primary_button(theme: Theme) -> void:
	theme.set_type_variation("PrimaryButton", "Button")
	theme.set_stylebox("normal", "PrimaryButton", Palette.box(Palette.PRIMARY, Palette.RADIUS_BUTTON, true))
	theme.set_stylebox("pressed", "PrimaryButton", Palette.box(Palette.PRIMARY_PRESSED, Palette.RADIUS_BUTTON, false))
	theme.set_stylebox("disabled", "PrimaryButton", Palette.box(Palette.DISABLED, Palette.RADIUS_BUTTON, false))
	_silence_pointer_states(theme, "PrimaryButton")


## A tile is a secondary button in a squarer shape. A tile that wants a colour
## while held gets it per instance from tile_button.gd, because it differs per
## tile and only shows when held.
func _define_tile_button(theme: Theme) -> void:
	theme.set_type_variation("TileButton", "Button")
	theme.set_stylebox("normal", "TileButton", Palette.tile_box(Palette.SECONDARY, true))
	theme.set_stylebox("pressed", "TileButton", Palette.tile_box(Palette.SECONDARY_PRESSED, false))
	theme.set_stylebox("disabled", "TileButton", Palette.tile_box(Palette.DISABLED, false))
	_silence_pointer_states(theme, "TileButton")


## Chrome: an icon and no caption. Same family as a tile, tighter margins,
## because at 160² a tile's margins would leave nowhere for the icon to go.
func _define_icon_button(theme: Theme) -> void:
	theme.set_type_variation("IconButton", "Button")
	theme.set_stylebox("normal", "IconButton", Palette.icon_button_box(Palette.SECONDARY, true))
	theme.set_stylebox("pressed", "IconButton", Palette.icon_button_box(Palette.SECONDARY_PRESSED, false))
	theme.set_stylebox("disabled", "IconButton", Palette.icon_button_box(Palette.DISABLED, false))
	_silence_pointer_states(theme, "IconButton")


## Any card sitting on the background — the moodlet modal today. Without this a
## PanelContainer draws Godot's default grey box, with no error to explain it.
func _define_panel(theme: Theme) -> void:
	theme.set_stylebox("panel", "PanelContainer", Palette.panel_box(Palette.SURFACE))
	theme.set_stylebox("panel", "Panel", Palette.panel_box(Palette.SURFACE))


## A stat bar. Only the empty track is defined here — the coloured fill is what
## tells one stat from another, so moodlet.gd builds it per instance from
## Palette, exactly as tile_button.gd does for a tile's pressed colour.
##
## The fill is still defined, in the neutral secondary, so a bare ProgressBar
## dropped anywhere looks deliberate rather than broken.
func _define_progress_bar(theme: Theme) -> void:
	theme.set_stylebox("background", "ProgressBar", Palette.bar_box(Palette.DISABLED))
	theme.set_stylebox("fill", "ProgressBar", Palette.bar_box(Palette.SECONDARY_PRESSED))


func _define_containers(theme: Theme) -> void:
	theme.set_constant("separation", "HBoxContainer", Palette.GAP)


## The game is touch-only, so hover and focus must never be visible — but
## *undefined* is not *absent*. Left alone, Godot draws its own grey default
## through a pink button the moment a tap registers as a hover. Silence them.
func _silence_pointer_states(theme: Theme, type: String) -> void:
	theme.set_stylebox("hover", type, theme.get_stylebox("normal", type))
	theme.set_stylebox("hover_pressed", type, theme.get_stylebox("pressed", type))
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_color("font_hover_color", type, Palette.TEXT_PRIMARY)
	theme.set_color("font_hover_pressed_color", type, Palette.TEXT_PRIMARY)
	theme.set_color("font_focus_color", type, Palette.TEXT_PRIMARY)


func _load_font(path: String) -> Font:
	if not ResourceLoader.exists(path):
		push_warning("Font not found: %s — the theme falls back to Godot's default face." % path)
		return null
	return load(path)
