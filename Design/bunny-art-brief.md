# Bunny art brief

How to generate Usapyon assets with ChatGPT so they stay on-model and work in Godot.

The authority on style is **`Design/Style reference sheet.png`**. This file only
covers how to *use* it.

## The two constraints that shape everything

**1. AI image generation cannot reliably produce matching separate parts.** Ask
for a body, then ears, then a face as three prompts and you get three slightly
different bunnies — line weight, palette and proportions drift every time.

So: generate **one complete bunny**, use it whole for the prototype
(squash-and-stretch works fine on a single sprite), and **cut it into layers
later** in an image editor, once we know which parts need to move independently.

**2. Always attach the reference sheet.** Uploading
`Design/Style reference sheet.png` with every prompt does more for consistency
than any amount of prose description. Never generate a variant from a blank
slate — always give it the sheet, and for edits give it the approved asset too.

## Palette (sampled from the reference sheet)

| Role | Hex |
|---|---|
| Outline / eyes | `#14183B` |
| Fur | `#FEF9F7` |
| Inner ear | `#FDBDBE` |
| Pink | `#FDB8C7` |
| Peach | `#FDCDB3` |
| Yellow | `#FEE5A4` |
| Green | `#B3D791` |
| Blue | `#B5D8F7` |
| Lavender | `#C5BEEC` |
| Greige | `#DACECA` |

The outline is a **deep navy**, not black and not brown.

## Style rules

Per the sheet's own summary: cute rounded kawaii shapes, clean dark outlines,
soft pastels, simple expressive forms, **minimal shading**, consistent
proportions, readable on small screens, cozy mood. No realism, no pixel art, no
complex texture.

Note "minimal shading" — the reference does carry a soft inner shadow. Don't ask
for *completely* flat colour, and don't let it drift into rendered 3D shading
either.

## Technical requirements

- **Square canvas.** ChatGPT ignores exact pixel requests; accept 1024×1024 and
  we scale in-engine.
- **Flat solid background in a colour the bunny never uses** — pure magenta
  `#FF00FF` is ideal. Do *not* ask for a transparent background: image models
  tend to render a fake grey checkerboard as actual pixels. Key the magenta out
  yourself afterwards.
- Whole bunny visible with margin, filling ~80% of canvas height. Nothing
  cropped at the edge.
- No ground shadow, no background scenery, no text, no border.
- Export **PNG** with real alpha once the background is removed.

## What the prototype needs

Exactly one asset: **the Idle pose**, front-facing, matching the sheet.

The sheet already shows it, but only ~150px wide — too small for a 1080-wide
screen. So regenerate it at full size with the sheet attached:

> Using the attached Usapyon style reference sheet, draw the Idle pose of this
> exact bunny character as a single large centred figure. Front-facing,
> symmetrical, sitting upright, whole body visible with margin. Match the
> reference exactly: same proportions, same deep navy outline weight, same
> off-white fur, same pink inner ears and blush, same eye style, same minimal
> soft shading. Solid flat pure magenta background. No shadow, no scenery, no
> text, no border. Square image.

Save the exact prompt you settle on — reusing it verbatim keeps later assets
on-model.

## After generating

1. Remove the magenta background, export PNG with alpha.
2. Trim transparent margins, keep the bunny centred horizontally.
3. Save to `assets/bunny/bunny.png`.
4. In Godot, set the `Sprite` node's texture to it. Nothing else needs changing —
   the pivot is computed from the texture at runtime.

## Not needed yet

Blinking, expressions, poses and cosmetics all need parts on their own layers,
which means cutting the image up. That happens after the tap loop feels right —
not before.

Items, furniture, UI and the room are all on the sheet, but they are expansion
scope. See `general.MD`.
