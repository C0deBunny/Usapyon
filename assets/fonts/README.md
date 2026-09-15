# Fonts

Fredoka, from [Google Fonts](https://fonts.google.com/specimen/Fredoka).
Licensed SIL OFL 1.1 — `OFL.txt` ships with it and must stay.

```
Fredoka-SemiBold.ttf   the default face — labels and body text
Fredoka-Bold.ttf       button and tile text
```

These are two files out of the 25-static family pack. The rest — Light, Medium,
Regular, and the Condensed / SemiCondensed / SemiExpanded / Expanded widths, plus
the variable `Fredoka[wdth,wght].ttf` — were dropped rather than committed. They
came to about 1.3 MB of faces nothing references, and Godot exports every
resource under `res://` whether or not anything uses it. Re-download the family
if you ever want another weight or width.

Two static faces rather than the variable font on purpose: the design needs
exactly two weights, and this avoids `FontVariation` entirely. See
`docs/plans/ui-theme/decisions.md` 4.

## Import settings

Godot 4.7's defaults are already right for this: **Antialiasing = Gray**,
mipmaps off, MSDF off. Nothing needed changing.

If the text looks muddy or uneven on the phone, the two knobs worth trying in the
**Import** dock are **Hinting** (try `None` — hinting distorts rounded display
faces at large sizes) and **Subpixel Positioning**. Reimport after changing
either.

## Wiring

`scenes/ui/theme/build_theme.gd` loads both faces by path and bakes them into
`usapyon_theme.tres`. If a face is missing it warns and falls back to Godot's
default face — the theme still builds, it just looks wrong. After moving or
renaming a font, update the paths there and re-run:

```sh
godot --headless --path . --script res://scenes/ui/theme/build_theme.gd
```
