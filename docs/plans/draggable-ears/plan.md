# Plan: Draggable ears

## Goal

Let the player grab either of the bunny's ears with a finger and pull it. The ear
rotates, stretches and shifts slightly toward the finger, strictly limited so it
always reads as attached to the head, and springs back when released. Both ears work
independently under multitouch, and a mouse drives one of them on desktop so the
feature is testable without a device.

The existing idle ear wobble must keep running underneath, unchanged — not
reapproximated, not disabled during a drag.

## Non-goals

- **No change to the eye system.** `scenes/eye.gd` and the eye nodes are untouched.
  The two features coexist purely because both key their state to a touch index.
- No reaction from the bunny to having its ears pulled — no expression change, no
  stat, no sound. The ear moves and springs back; that is the whole feature.
- No squash. Pushing a finger toward the head returns the ear to resting length and
  no further; the ear never compresses below 1.0 scale.
- No physics simulation. The spring-back is a `Tween`, not a solver.

## Context

Read `CLAUDE.md` first — renderer, resolution, touch-only input, scene-editing rules
and the `uid://` handling all apply and are not repeated here.

What this touches:

- **`scenes/bunny.tscn`** — `Visual` holds `Body`, `EarRight`, `EarLeft`, `Face`,
  `EyeLeft`, `EyeRight`. The ear sprites are full-canvas 1222x1222 sheets with no
  `offset` and no `position`, so each one's origin is the centre of the sheet —
  roughly the middle of the head, *not* the base of the ear.
- **The `idle` animation** on `AnimationPlayer` (autoplaying, looping) owns
  `Visual/EarLeft:rotation` and `Visual/EarRight:rotation`, wobbling them ±0.026 rad
  (±1.5°). `RESET` keys the same two properties to 0. That is the exact property a
  drag wants to write, which is why the two transforms have to live on different
  nodes.
- **`scenes/eye.gd`** is the pattern to follow for touch handling: an `Area2D` named
  `ClickArea` parented under the sprite with a hand-placed `CollisionShape2D`; press
  captured via `Area2D.input_event`; release caught globally in `_unhandled_input`
  and matched by touch index so a finger that slides off still releases cleanly;
  `InputEventScreenTouch.index` on device and a `MOUSE_INDEX` sentinel for
  `InputEventMouseButton` on desktop; a force-release on
  `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- The root viewport has `physics_object_picking = true` by default (verified
  headlessly this session), so `Area2D.input_event` fires with no project setting
  change.

## Approach

Split the idle transform from the interaction transform by inserting a node, and
give each one its own pivot.

A new `Node2D` wrapper per ear is positioned **at the ear base** and carries every
property the drag writes — `rotation`, `scale`, `position`. The existing `Sprite2D`
becomes its child with a compensating `position` so the art does not move, and keeps
the idle rotation about its own sheet centre exactly as before. The idle animation
therefore produces a bit-identical wobble; only its track path gets deeper. The
alternative — moving idle onto the wrapper and freeing the sprite for interaction —
was rejected because pivoting the sprite at the ear base would mean rebalancing its
`offset` and `position` against each other, shifting the art if mistuned. See
`decisions.md` 1 and 2.

The ear's resting geometry comes from a `Marker2D` named `Tip`, dragged onto the ear
tip in the editor. `Tip.position` is local to the wrapper, so its `normalized()` is
the resting direction and its `length()` the resting length — no numbers typed
against art that can only be eyeballed.

The drag model is "the ear aims at your finger", but measured **relative to the
grab**. On press the script records the angle and distance from the base to the touch
point; each drag event applies only how much those have changed since. Grabbing low
on the ear therefore behaves identically to grabbing at the tip, and nothing moves
until the finger does — an absolute aim would pop the ear to a new angle the instant
a low grab produced a short, wildly-angled vector.

Every mapped value passes through `limit * tanh(x / limit)`: derivative 1 at zero, so
the ear tracks the finger exactly near neutral, and asymptotic to `limit`, so it
approaches the cap without ever reaching it and without a moment where it visibly
locks. Caps are measured against rest, not against the grab, so no amount of
re-grabbing accumulates past them. Offset falls out of the pull rather than being a
third independent axis: the base drifts toward the finger in proportion to how far
past resting length the finger is, through the same `tanh` cap.

Release runs an elastic `Tween` (`TRANS_ELASTIC` / `EASE_OUT`) back to identity.
Grabbing mid-spring kills the running tween and re-grabs from wherever the ear
currently is, mirroring how `eye.gd` stops its release timer on a re-tap.

Input is event-driven throughout — `InputEventScreenDrag` on device,
`InputEventMouseMotion` on desktop — so nothing runs in `_process`.

## Components

- **`scenes/ear.gd`** *(new)* — one script attached to both pull wrappers, the way
  `eye.gd` is attached to both eye sprites. Owns: press/drag/release handling keyed
  to a touch index, the angle/distance-since-grab math, the `tanh` limiting, the
  spring-back `Tween`, and a focus-loss force-release. Exports the three caps
  (`max_rotation_degrees`, `max_stretch`, `max_offset`) and the spring duration.
- **`scenes/bunny.tscn`** — per ear: a new `Node2D` pull wrapper under `Visual` at the
  ear base; the existing ear `Sprite2D` reparented under it with a compensating
  `position`; a `Marker2D` named `Tip` at the ear tip; an `Area2D` named `ClickArea`
  with a hand-placed `CollisionShape2D` under the sprite. The two `idle` tracks and
  the two `RESET` ear tracks re-point to the deeper node paths.
- **`scenes/bunny.gd`** — unchanged. The bunny does not need to know its ears are
  draggable; each ear is self-contained.
- **`scenes/eye.gd`** — unchanged, deliberately.

## Risks

- **Reparenting may break the animation track paths.** Godot usually rewrites
  `AnimationPlayer` track paths when a referenced node is reparented in the Scene
  dock, but not dependably. If it does not, the `idle` and `RESET` ear tracks go
  invalid and the wobble silently stops — no error, just a still ear. Mitigation:
  inspect all four ear tracks immediately after reparenting; if broken, fix the path
  strings directly in the `.tscn`, which is a small text edit on a plain-text file.
- **Base and tip are placed by eye.** The 1222x1222 full-canvas art gives no bounds to
  derive them from. A `Tip` marker placed short makes the rest length too small, which
  inflates the computed stretch ratio and makes the ear balloon on a light pull.
  Mitigation: both are draggable in the editor and all caps are `@export`, so this is
  tuned by running rather than by calculation.
- **Stretching the wrapper also stretches the `ClickArea`'s collision shape**, and a
  non-uniformly scaled `CollisionShape2D` is exactly what Godot warns about. In
  practice this is benign here: the grab is captured on press and tracked by touch
  index from then on, so the hit area's accuracy mid-drag never matters. Accepted.
- **Input coordinates must be converted under `canvas_items` stretch.** Raw
  `event.position` is in viewport pixels, not the 1080×1920 design space. Getting this
  wrong yields a drag that tracks at an offset or a wrong scale. Mitigation: convert
  through the wrapper's *parent* (`Visual`), never the wrapper itself — the wrapper's
  own transform changes as you drag, which would feed back into the input it is
  reading.
- **Exaggerated caps may reveal a seam** where the ear meets the skull. The chosen
  moderate defaults should stay clear of it, but it is the first thing to look at if
  a pulled ear looks detached.

## Open questions

- Resting geometry, the wrapper positions and the compensating sprite positions are
  all editor values, not code. They are settled by placing nodes, not by this plan.
- The idle wobble rotates the sprite ±1.5°, which moves the true ear tip slightly away
  from where `Tip` sits. Assumed negligible and ignored in the geometry. Revisit only
  if a drag started at the extreme of the wobble feels off.
- Whether a pulled ear should eventually provoke a reaction from the bunny. Out of
  scope per `CLAUDE.md`'s milestone rule; noted because the hook would live in
  `ear.gd`'s release path.
