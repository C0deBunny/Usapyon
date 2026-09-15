class_name Palette
extends RefCounted

## Every colour and measurement in the Usapyon interface, named exactly once.
##
## [code]build_theme.gd[/code] bakes these into [code]usapyon_theme.tres[/code].
## [code]tile_button.gd[/code] reads them directly for the one stylebox that
## varies per instance. Both go through [method box], so a tile's pressed state
## and the theme's pressed state are built by the same code and cannot drift.
##
## Nothing instantiates this — it is a namespace of constants.

# --- Ink and surfaces --------------------------------------------------------

## Outline and text. Every border in the UI is this colour.
const INK: Color = Color("001558")
## Text on a disabled control.
const INK_MUTED: Color = Color("a9b0c6")

## The resting fill of a secondary button and of an untouched tile.
const SURFACE: Color = Color("fdf6f0")
const SURFACE_PRESSED: Color = Color("f0e2dc")
const SURFACE_DISABLED: Color = Color("dcd5d2")

# --- Primary -----------------------------------------------------------------

const PRIMARY: Color = Color("f8a8c4")
const PRIMARY_PRESSED: Color = Color("f06e96")
const PRIMARY_DISABLED: Color = Color("e4cbd5")

# --- Tile accents ------------------------------------------------------------
# Tiles rest cream and only take on their action's colour while held, so each of
# these is a pressed fill and nothing else.

const ACCENT_FEED: Color = Color("fadce5")
const ACCENT_PLAY: Color = Color("d8e6fb")
const ACCENT_CLEAN: Color = Color("e6def7")

# --- Shadow ------------------------------------------------------------------
# A button carries its shadow at rest and loses it while pressed, which reads as
# the button sinking under the finger.

const SHADOW: Color = Color(0.169, 0.227, 0.404, 0.18)
const SHADOW_SIZE: int = 10
const SHADOW_OFFSET: Vector2 = Vector2(0, 7)

# --- Geometry ----------------------------------------------------------------

const BORDER: int = 4
const RADIUS_BUTTON: int = 28
const RADIUS_TILE: int = 32
## Godot defaults corner_detail to 8, which is visibly faceted at these radii.
const CORNER_DETAIL: int = 14
## Gap between tiles in the action row.
const GAP: int = 24
## Thumb-sized and then some — three of these plus two gaps still fit in 1080.
const TILE_MIN_SIZE: Vector2 = Vector2(280, 280)
## Drawn size of a tile's icon. The source art is 256²; this is what it renders at.
const ICON_SIZE: Vector2 = Vector2(144, 144)

# --- Type scale --------------------------------------------------------------

const FONT_BODY: int = 40
const FONT_BUTTON: int = 44


## The one description of a button surface in the project.
static func box(fill: Color, radius: int, with_shadow: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = INK
	style.set_border_width_all(BORDER)
	style.set_corner_radius_all(radius)
	style.corner_detail = CORNER_DETAIL
	style.content_margin_left = 36.0
	style.content_margin_right = 36.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	if with_shadow:
		style.shadow_color = SHADOW
		style.shadow_size = SHADOW_SIZE
		style.shadow_offset = SHADOW_OFFSET
	return style


## A tile is a rounder, squarer, roomier button.
static func tile_box(fill: Color, with_shadow: bool) -> StyleBoxFlat:
	var style := box(fill, RADIUS_TILE, with_shadow)
	style.content_margin_top = 32.0
	style.content_margin_bottom = 32.0
	return style
