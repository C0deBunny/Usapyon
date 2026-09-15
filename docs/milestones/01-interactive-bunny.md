# Milestone 1 — A Usapyon You Can Touch 🐰

**Status: complete.** This documents what the project actually does today.
Milestone 2 builds on it.

## Goal

Prove the thing worth proving first: one cute creature on a phone screen that
feels good to touch. No stats, no saving, no progression — just presence and
reaction.

> Open the app on the phone → a Usapyon is idling there → touch it → it responds
> in a way that feels alive.

------------------------------------------------------------------------

## 1.1 — Project Setup

| Setting | Value | Why |
| --- | --- | --- |
| Engine | Godot 4.7 | |
| Renderer | GL Compatibility (OpenGL ES3) | Cheap Android GPUs and battery |
| Viewport | 1080 × 1920 | Portrait design resolution |
| Stretch | `canvas_items`, aspect `expand` | Other aspect ratios gain space rather than letterboxing |
| Orientation | Portrait, locked | |

Repository layout as built:

``` text
res://
├── scenes/          main.tscn, bunny.tscn + their scripts beside them
├── autoloads/       music.tscn / music.gd
├── assets/
│   ├── sprites/bunny/   the layered rig
│   └── audio/           Usapyon_main.ogg
└── docs/            design notes, milestones, plans (.gdignore'd)
```

Scripts live next to the scene they belong to rather than in a separate
`scripts/` folder. GDScript is statically typed throughout.

------------------------------------------------------------------------

## 1.2 — Android Build

A single export preset named `Android`:

``` text
arm64-v8a only
non-gradle template
output → builds/usapyon-debug.apk
```

`builds/` and `.godot/` are gitignored. Deploying to a real phone and running
there is part of this milestone — the touch interactions below were tuned on
the device, not on desktop.

------------------------------------------------------------------------

## 1.3 — The Bunny Rig 🐰

The Usapyon is **not** a set of whole-pose images. It is a layered rig, so that
expressions, and later accessories and customization, are swapped per part
rather than redrawn as complete sprites.

``` text
Bunny (Node2D)
└── Visual
    ├── EarRightPull → EarRight    (Sprite2D)
    ├── EarLeftPull  → EarLeft     (Sprite2D)
    ├── Body                       (Sprite2D)
    ├── Face                       (Sprite2D)
    ├── EyeLeft                    (Sprite2D, own script)
    └── EyeRight                   (Sprite2D, own script)
```

Sprites in `assets/sprites/bunny/`: `body_base`, `ear_left`, `ear_right`,
`face_neutral`, and `eye_{left,right}_{neutral,closed}`. The master art file is
[`../design/psd/usapyon-master-rig.psd`](../design/psd/).

`Visual` exists as a wrapper so the idle animation can move and squash the whole
creature without fighting the per-part transforms underneath it.

------------------------------------------------------------------------

## 1.4 — Idle Animation

An `AnimationPlayer` autoplays a looping 1.6s `idle` animation — a breath, not a
bounce. `Visual:position` bobs to `-10`, `Visual:scale` inflates to
`(1.013, 1.02)`, and each ear sprite counter-rotates ±1.7°.

The breath is asymmetric: it inhales over 0.6s, exhales over 0.9s, then holds
the rest pose for the last 0.1s. That held beat is what reads as breathing
rather than oscillating. Shaping comes from per-key `transitions` of `-2.0`
(ease-in-out in Godot's `Math::ease`) on tracks that stay `interp = 1`
(linear). Cubic interpolation is deliberately *not* used: a catmull-rom arriving
at the rest key with a non-zero tangent overshoots past the baseline and dips
the bunny below it.

**The bob is derived, not chosen.** `Visual:scale` pivots on the `Bunny` origin,
which measures 508px above the body's bottom edge, so `scale.y = s` pushes that
edge down by `508 × (s − 1)`. Keeping

	bob_y = 508 × (scale_y − 1)

cancels the two, and the bunny's bottom stays planted while the body grows
upward out of it (measured: 0.16px of drift at the peak, and the head rises
20.5px). Scale the bob without the squash and the bunny levitates; scale the
squash without the bob and it sinks as it inhales.

The ear peak sits 0.12s after the body's, so the ears are still rising while the
body has begun its exhale — follow-through. They have no hold of their own: the
0.12s lag would push their rest key past the end of the loop, so the ear tracks
carry three keys and ease into rest exactly on the loop seam. The ease-out has
them within 3% of rest by the time the body parks at 1.5s, so nothing lingers.

Note that an ear *sprite's* origin resolves back onto the `Bunny` origin,
121–526px *below* the ear art, so the rotation is a lever: ±1.7° sweeps the tip
~16px sideways. It is a sway, not a tilt, which is why the angle stays small.

The ear *sprites* carry the idle rotation; the ear *pull nodes* above them carry
the drag. Two different nodes, so the idle wobble and a finger never write the
same property.

------------------------------------------------------------------------

## 1.5 — Blinking

Driven from `bunny.gd`, not from the AnimationPlayer, because each eye owns its
own texture and an eye held shut by a finger has to sit the blink out while the
other blinks normally.

``` text
wait 2–6s  →  every non-busy eye closes  →  80ms  →  they open
              15% of the time, a second blink follows 100ms later
```

------------------------------------------------------------------------

## 1.6 — Interaction: Holding an Eye 👆

Touch an eye and it closes; lift and it stays shut for another 0.5s before
opening. Touching again during that delay resumes the hold without a flicker.

Each eye tracks its own touch index, so both eyes can be held independently.

------------------------------------------------------------------------

## 1.7 — Interaction: Pulling an Ear 👆

Drag an ear and it rotates about its base and stretches along its own length.
Release and it springs back with an elastic tween.

- Rotation and stretch approach their limits without reaching them (`tanh`
  softening), so the ear never hits a hard stop.
- Only the outward component of the drag lengthens the ear — dragging sideways
  rotates, dragging inward does nothing.
- The base stays pinned to the head; it gives by at most 3px.

------------------------------------------------------------------------

## 1.8 — Touch Handling Rules

Both interactions follow the same pattern, and it is the pattern to reuse:

- **Press** is caught on the node's own `Area2D` (`input_event`).
- **Drag and release** are caught globally in `_unhandled_input`, so a finger
  that wanders off the node still works.
- Every gesture stores the **touch index** that started it, so two fingers on two
  different parts never interfere.
- `NOTIFICATION_APPLICATION_FOCUS_OUT` releases the gesture — Android can take a
  touch away (a call, the notification shade) without ever sending the release,
  which would otherwise strand an ear mid-pull or an eye shut for good.
- Mouse input borrows a fake index so the same code is testable on desktop.

------------------------------------------------------------------------

## 1.9 — Background Music 🎵

A `Music` autoload (`AudioStreamPlayer`) plays `Usapyon_main.ogg` on its own
`Music` audio bus. Looping is the Ogg's own import setting; the script owns only
`fade_in()` / `fade_out()`, tweening `volume_db` and pausing the stream once
faded out.

Direction for the track itself lives in
[`../design/03-music-direction.md`](../design/03-music-direction.md).

------------------------------------------------------------------------

## 1.10 — Placeholder Environment

`main.tscn` is a full-rect `Control` with a plain pale-cyan `ColorRect`
background and the bunny centred at `(540, 1050)`. No room art, no UI, no
`CanvasLayer` yet — Milestone 2 adds the first UI layer.

------------------------------------------------------------------------

## What Milestone 1 Deliberately Does Not Have

No stats, no save file, no time passing, no feeding, no UI, no coins, no
progression. The Usapyon does not need anything from you yet — it just exists
and reacts.

Everything in that list is Milestone 2 or later. See
[`02-persistent-pet.md`](02-persistent-pet.md).
