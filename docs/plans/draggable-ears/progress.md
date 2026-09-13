# Progress: Draggable ears

<!-- Living log. Append newest entries at the top:
     ## YYYY-MM-DD
     - Did: <what changed> (<sha>)
     - Verified: <how>
     - Next: <what remains> / Blocked: <on what>
-->

## 2026-09-13 (3) — stretch driven by outward pull only

- Did: dragging downward lengthened the ear, because stretch keyed off raw distance
  from the pivot and dragging past the base increases that distance. Stretch now
  keys off the drag's projection onto the ear's own axis: `_rest_axis` (the tip
  direction in parent space, alongside the existing local `_rest_angle` used for the
  stretch basis), with `_grab_along` replacing `_grab_distance`. The projection is
  floored at zero, so pulling toward the head can never lengthen the ear. The 3px
  base offset now runs along that axis too, rather than toward the finger.
- `max_stretch` default 1.12 → 1.04.
- Verified by temporary self-test driving `_grab`/`_pull` with synthetic finger
  positions, 200px in four directions: outward → stretch 1.0400, rotation 0.00°,
  offset 3.00px; downward → stretch 1.0000, rotation 0.00°, offset 0.00px; sideways
  → stretch 1.0000, rotation −14.57°; sideways+down → stretch 1.0000, rotation
  −14.99°. Test code removed, final `--quit-after 200` run clean.
- Known feel caveat: because `_soft()` ties its ramp to its limit, and the stretch
  limit is now only 0.04, stretch saturates after roughly 25px of outward pull — it
  reads as a small fixed lengthening rather than a progressive one. Decoupling would
  mean a separate ramp distance rather than normalising by `_rest_length`. Not done;
  nobody has judged whether it is noticeable at 4%.

## 2026-09-13 (2) — base pinned, stretch moved onto the ear axis

- Did: the ear base visually detached from the head on a pull. Two causes, both
  removed. `ear.gd` no longer writes `rotation`/`scale`/`position`; it composes the
  node transform as `rest · rotate(pull) · stretch_along(rest_angle)`, so rotation
  and stretch both happen about the node origin and the base cannot move. The
  `scale.y` stretch — which elongated along the node's vertical rather than the ear's
  length — is replaced by `_stretch_along()`, a `rotate(a) · scaleX(k) · rotate(-a)`
  basis. This resolves the known limitation logged below; `Tip`'s direction is now
  used, not just its length.
- `max_offset` default dropped 20px → 3px and is now hard-clamped in `_apply()` via
  `limit_length()`, so the cap holds no matter what value reaches the property rather
  than relying on `_soft()` never exceeding it.
- The three pull values became properties with setters that recompose the transform,
  so the spring tween animates them directly. Relative-drag behaviour, elastic
  spring-back, touch-index handling and the idle animation are all unchanged.
- Verified by temporary self-test, measured in the node's own parent space (global
  space is distorted by the idle bob and its non-uniform `Visual:scale`): stretch of
  1.12 gives length ratio 1.12000 with 0.0 angle drift and zero base movement;
  rotation of 0.3 rad gives 0.29999 with length ratio 1.0 and zero base movement; an
  absurd 1414px offset clamps to exactly 3.000px; after the spring, rotation and
  stretch are back at 0.0/1.0 with the base at its rest position. Test code removed,
  final `--quit-after 200` run clean.
- Next: unchanged — all node placement is still placeholder (see below), and nobody
  has judged the feel.

## 2026-09-13 (1)

- Did: added `scenes/ear.gd` and restructured `scenes/bunny.tscn` — a `Node2D` pull
  wrapper per ear carrying `ear.gd`, with `ClickArea`, `Tip` and the reparented ear
  `Sprite2D` beneath it. All four ear rotation track paths (`idle` and `RESET`)
  re-pointed by hand in the `.tscn` rather than relying on the editor to rewrite
  them, which was the plan's top risk. `bunny.gd` and `eye.gd` untouched. Uncommitted.
- Deviated from the plan on one point: `ClickArea` sits under the **pull wrapper**,
  not under the sprite. Under the sprite its node path would differ per ear
  (`EarLeft/ClickArea` vs `EarRight/ClickArea`), so the shared script could not reach
  it with a single `$ClickArea`. The plan's stated reason for putting it under the
  sprite — inheriting the idle wobble — is worth ±1.5°, and the grab is tracked by
  touch index from the moment of press anyway.
- Known limitation not in the plan: stretch is applied as `scale.y` on the wrapper,
  so it elongates along the wrapper's local **vertical**, not along the ear's actual
  resting direction. For upright ears the difference is invisible. For a strongly
  diagonal ear the stretch will look off-axis; fixing it properly needs a composed
  `rotate(θ) · scaleY · rotate(-θ)` transform instead of plain node properties.
  `Tip` is currently read only for its length, not its direction — that direction is
  what a fix would use.
- Verified: `--headless --import` clean; `--quit-after 300` runs with no errors; a
  temporary `print` in `_ready()` confirmed both wrappers initialise, resolve
  `ClickArea` and `Tip`, and compute `rest_len = 322.49`. Print removed afterwards.
- Next: all node placement is still placeholder and must be tuned in the editor —
  wrapper position to the true ear base (with the sprite's `position` kept at exactly
  its negative), `Tip` onto the ear tip, and the `CollisionShape2D` capsules over the
  ear art. Feel — pull strength, spring elasticity, whether the caps are right — is
  unjudged; nobody has seen this run.
