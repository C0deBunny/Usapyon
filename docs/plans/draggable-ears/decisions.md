# Decisions: Draggable ears

## 1. Pivot the drag at the ear base, not the sheet centre

- **Date:** 2026-09-13
- **Considered:** ear base · centre of the 1222×1222 sheet (the existing origin)
- **Chosen:** ear base — because the sprites are full-canvas sheets whose origin sits
  roughly in the middle of the head. Rotating there makes the ear slide across the
  skull, and since `scale` is applied about the origin too, a stretch would grow the
  ear in both directions rather than elongating it away from the head. The ±1.5° idle
  wobble is small enough not to expose this; a drag is not.
- **Trade-off:** costs placing one node per ear by eye in the editor, against zero
  setup for the sheet centre.

## 2. Put interaction on a new wrapper; leave idle on the sprite

- **Date:** 2026-09-13
- **Considered:** wrapper carries interaction, sprite keeps idle · wrapper takes over
  idle, sprite freed for interaction
- **Chosen:** wrapper carries interaction — because the sprite then keeps rotating
  about its own sheet centre exactly as it does today, so the idle wobble is
  bit-identical rather than reapproximated, and the wrapper can be placed freely at
  the ear base without touching the art. The inverse would require rebalancing the
  sprite's `offset` against its `position` to move the pivot, which shifts the art if
  mistuned.
- **Trade-off:** either arrangement changes the node depth, so the `idle` and `RESET`
  ear track paths have to be re-pointed regardless. This choice does not avoid that
  cost, it just avoids the offset tuning.

## 3. Soft asymptotic falloff via `tanh`, not a hard clamp

- **Date:** 2026-09-13
- **Considered:** `limit * tanh(x / limit)` · 1:1 tracking then a hard clamp · damped
  follow at a fixed fraction throughout
- **Chosen:** `tanh` — because its derivative is 1 at zero and it asymptotes to the
  limit, which is precisely "follows your finger exactly near neutral, resists more
  and more, never quite reaches the cap". A hard clamp produces a visible moment where
  the ear stops dead against a wall; a damped follow never sits under the finger at
  all and feels disconnected.
- **Trade-off:** the cap is approached but never actually reached, so the documented
  maximum is a limit rather than an attainable value.

## 4. Elastic overshoot on release

- **Date:** 2026-09-13
- **Considered:** `TRANS_ELASTIC` / `EASE_OUT` (whip past neutral and wobble) ·
  `TRANS_BACK` / `EASE_OUT` (one soft overshoot) · `TRANS_CUBIC` / `EASE_OUT` (no
  overshoot)
- **Chosen:** elastic — the most playful and the most obviously springy, which suits a
  bond-focused pet toy where pulling an ear should be fun to repeat.
- **Trade-off:** can read as floppy on a very small pull. The tween transition is a
  one-line change if it does.

## 5. Aim the ear at the finger, rather than mapping drag delta per axis

- **Date:** 2026-09-13
- **Considered:** angle and distance from the ear base to the finger · sideways delta
  drives rotation, outward delta drives stretch, raw delta fraction drives offset
- **Chosen:** aim at the finger — a single coherent physical model, where offset falls
  out of how hard you pull rather than being a third knob tuned in isolation.
- **Trade-off:** less independently tunable than three separate axes, and with a tight
  rotation cap the model spends much of a sideways drag near its limit.

## 6. Track angle and distance relative to the grab point, not absolutely

- **Date:** 2026-09-13
- **Considered:** relative to where the finger first touched · absolute, aiming at the
  finger from the moment of contact
- **Chosen:** relative — because the base-to-finger vector is short and wildly angled
  when the ear is grabbed low, so an absolute aim snaps the ear to a new angle before
  the finger has moved at all. Relative tracking makes a grab anywhere on the ear feel
  identical and guarantees nothing moves until the player does.
- **Trade-off:** the ear no longer literally points at the finger, so a long drag ends
  with a visible angle between finger and ear tip. Caps are still measured against
  rest, so re-grabbing cannot accumulate past them. **Do not "fix" this by switching to
  absolute aim** — the pop on a low grab is what this decision exists to prevent.

## 7. Moderate limits — 15°, 1.12× stretch, 20px offset

- **Date:** 2026-09-13
- **Considered:** subtle (8°, 1.06, 12px) · moderate (15°, 1.12, 20px) · exaggerated
  (25°, 1.22, 35px)
- **Chosen:** moderate — noticeably playful while still obviously anchored to the head.
- **Trade-off:** these are `@export` defaults, not constants, so the real decision is
  only where tuning starts. Pushing toward exaggerated risks a visible seam where the
  ear meets the skull at 1222px art.

## 8. Read rest geometry from a `Marker2D`, not typed numbers

- **Date:** 2026-09-13
- **Considered:** a `Tip` marker node dragged onto the ear tip · `@export` rest angle
  and rest length per ear
- **Chosen:** the marker — the art is a full-canvas sheet with no bounds to derive
  geometry from, so either way the values are eyeballed. Dragging a node against the
  visible art is a far better way to eyeball than typing degrees and pixels.
- **Trade-off:** one extra node per ear in the scene.

## 9. Duplicate the touch-index handling in `ear.gd` rather than extracting a shared helper

- **Date:** 2026-09-13
- **Considered:** duplicate the ~12 lines from `eye.gd` · extract a shared
  `touch_input.gd` with static helpers
- **Chosen:** duplicate — the ear also needs drag events the eye has no use for, so the
  two copies diverge immediately and a shared helper would serve two callers that want
  different things. `CLAUDE.md` explicitly defers shared layers until there is real
  pain.
- **Trade-off:** a genuine ~12-line duplication. A third touch-driven part is the
  signal to extract.
