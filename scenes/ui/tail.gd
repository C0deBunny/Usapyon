@tool
extends Control

## The popover's little triangle, pointing up at the button above it.
##
## Drawn rather than textured: it has to match the panel's fill and outline
## exactly, and a PNG would drift the moment [code]palette.gd[/code] changed.
##
## It must be ordered [i]after[/i] the panel it belongs to, because the whole
## trick is that its fill covers the panel's top border across the tail's base —
## that is what turns a triangle sitting on a box into one continuous bubble.
##
## The node is [constant Palette.TAIL_HEIGHT] tall plus one border width of
## overlap, and is positioned so that overlap sits exactly on the panel's border
## band. Any deeper and the fill would eat into the panel's outline further along
## than it should; any shallower and a seam would show.
##
## [b]@tool[/b] so it is visible in the editor, where the popover is laid out.

## Base width, apex height, and the border-width overlap that reaches into the
## panel.
const SIZE: Vector2 = Vector2(
	Palette.TAIL_WIDTH, Palette.TAIL_HEIGHT + Palette.BORDER
)


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w: float = SIZE.x
	var h: float = SIZE.y

	# Fill first, base included: that base is what covers the panel's top border
	# and opens the bubble.
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, h), Vector2(w * 0.5, 0.0), Vector2(w, h)
	])
	draw_colored_polygon(body, Palette.SURFACE)

	# Only the two slanted edges get an outline — the base has none, or the
	# bubble would look like a triangle parked on top of a box. Antialiased
	# because a bare diagonal at this size reads as a staircase on a phone.
	var edges: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, h), Vector2(w * 0.5, 0.0), Vector2(w, h)
	])
	draw_polyline(edges, Palette.OUTLINE, float(Palette.BORDER), true)
