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

## Every border in the UI is this colour.
const OUTLINE: Color = Color("6b4e57")
## Body and button text.
const TEXT_PRIMARY: Color = Color("24345f")
## Text on a disabled control.
const TEXT_MUTED: Color = Color("8a7279")

## Behind everything.
const BACKGROUND: Color = Color("fff8f5")
## A panel or card sitting on the background.
const SURFACE: Color = Color("fffdf9")

## The fill of any control that is switched off.
const DISABLED: Color = Color("e8e0e1")

# --- Accents -----------------------------------------------------------------
# The candy palette. Each colour comes with the darker fill it takes while held.

const RED: Color = Color("f19595")
const RED_PRESSED: Color = Color("ec7171")

const BLUE: Color = Color("c0d3eb")
const BLUE_PRESSED: Color = Color("a1bde1")

const PURPLE: Color = Color("ccb8de")
const PURPLE_PRESSED: Color = Color("b89cd1")

const GREEN: Color = Color("b8d9b8")
const GREEN_PRESSED: Color = Color("9dcb9d")

const ORANGE: Color = Color("f0b678")
const ORANGE_PRESSED: Color = Color("eca253")

const YELLOW: Color = Color("f9da7f")
const YELLOW_PRESSED: Color = Color("f7cf58")

const PINK: Color = Color("f6a6c1")
const PINK_PRESSED: Color = Color("e986aa")

# --- Buttons -----------------------------------------------------------------
# The primary button is pink; the secondary button is the cream one, and a tile
# is a secondary button in a squarer shape.

const PRIMARY: Color = PINK
const PRIMARY_PRESSED: Color = PINK_PRESSED

const SECONDARY: Color = Color("fff1e8")
const SECONDARY_PRESSED: Color = Color("f1ddd3")

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
	style.border_color = OUTLINE
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
