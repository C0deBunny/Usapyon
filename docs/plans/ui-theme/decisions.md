# Decisions: A theme for Usapyon

## 1. Draw buttons with StyleBoxFlat, not 9-patch art

- **Date:** 2026-09-15
- **Considered:** `StyleBoxFlat` only · 9-patch textures via `StyleBoxTexture` ·
  a flat theme now with an art layer added later
- **Chosen:** `StyleBoxFlat` only — the palette stays data rather than pixels, so
  a colour change is one constant and not a Photoshop session. It is also
  resolution-independent, which matters on the range of Android screens the
  design resolution has to stretch across.
- **Trade-off:** the reference sheet's inner gloss highlight and the sparkles on
  a pressed tile cannot be drawn. `StyleBoxFlat` gives one fill, one uniform
  border and one shadow. We ship the shape and the colour, not the sheen. The
  third option — adding that art later as child nodes inside `tile_button.tscn` —
  stays open, because nothing in the flat theme forecloses it.

## 2. Scope the theme to Hud/Root instead of a project default theme

- **Date:** 2026-09-15
- **Considered:** `Project Settings → GUI → Theme → Custom` (global) · a theme on
  `Main` · a theme on `Hud/Root`
- **Chosen:** `Hud/Root` — it covers the whole game UI subtree and nothing else.
  `DebugPanel` is instanced under `Main` at runtime, a sibling branch, so it
  inherits nothing and keeps Godot's stock grey. That grey is desirable: it reads
  as "not the game".
- **Trade-off:** any future UI that lives outside the `Hud` subtree has to opt in
  by assigning the theme itself. Accepted, because the alternatives are worse —
  a project default theme has no clean per-node opt-out at all (theme lookup is
  per-property and falls through, so an empty local `Theme` blocks nothing and
  you would have to re-specify every property back to grey), and `Main` is a
  `Control` that `DebugPanel` hangs off, so theming it would catch the panel too.

## 3. Generate the theme from palette constants

- **Date:** 2026-09-15
- **Considered:** `palette.gd` consts plus an `EditorScript` generator ·
  hand-authoring the `.tres` in Godot's Theme panel · treating the theme itself
  as the sole source of truth with a custom `Palette` theme type
- **Chosen:** consts plus a generator — it is the only one of the three that
  actually guarantees no drift. A `.tres` cannot reference a value by name, so
  the same pink is a literal in every stylebox that uses it; hand-authoring means
  nothing enforces that those literals match. Generating from typed constants
  makes mismatch impossible by construction, and it is the design-tokens build
  step the developer already knows from front-end work.
- **Trade-off:** `usapyon_theme.tres` becomes generated output. Editing it in
  Godot's Theme panel works and is then silently destroyed on the next run of
  `build_theme.gd`. It also adds a pattern `CLAUDE.md` says to ask about; the
  developer was asked and agreed. The theme-as-sole-source option was the runner
  up and stops *code* drift, but not drift between styleboxes inside the `.tres`.

## 4. Ship Fredoka as static weights, not the variable font

- **Date:** 2026-09-15
- **Considered:** the variable `Fredoka[wdth,wght].ttf` with `FontVariation` ·
  two static files, SemiBold and Bold
- **Chosen:** two statics — it skips the `FontVariation` concept entirely for a
  developer new to Godot, and the design needs exactly two weights: body text and
  heavier button text.
- **Trade-off:** intermediate weights are unavailable without adding a third
  file, and the width axis is unreachable. Both are easy to switch to later; the
  font is referenced in one place.

## 5. Leave the hunger readout unthemed

- **Date:** 2026-09-15
- **Considered:** theming `HungerValue` and `HungerBar` alongside the button ·
  leaving them untouched
- **Chosen:** untouched — the developer drew the scope boundary at the buttons,
  and the hunger display is closer to the unbuilt top bar than to the action row.
- **Trade-off:** the screen is visibly mixed for a while: a themed Fredoka tile
  above a stock grey `ProgressBar` and an inline-styled label. The theme also
  defines no `Label` or `ProgressBar` entries, so whoever themes the readout
  later adds those types rather than merely pointing at them.

## 6. Put the placeholder glyph in the icon slot and keep the caption

> **Superseded by decision 10** — the art arrived, the glyph is gone.

- **Date:** 2026-09-15
- **Considered:** a tile showing a single centred "C" and nothing else · a "C" in
  the icon slot with "Feed" beneath it
- **Chosen:** glyph over caption — it matches the reference sheet's tile shape,
  and it means the icon-over-label layout is actually exercised now rather than
  discovered to be wrong on the day `carrot.png` arrives.
- **Trade-off:** a bare "C" over the word "Feed" looks odd until there is art.
  Accepted as visibly temporary, which is better than invisibly untested.

## 7. Make the tile accent an instance override, not a theme variation

- **Date:** 2026-09-15
- **Considered:** three theme variations (`TileFeed`, `TilePlay`, `TileClean`) ·
  `self_modulate` on the button · a per-instance stylebox override built from
  `Palette`
- **Chosen:** the instance override — reading the reference sheet closely, all
  three tiles are cream by default and only the *pressed* state carries the
  action colour. So exactly one stylebox differs per tile, which does not justify
  a whole theme type per action, and would not scale as Brush, Pet and Sleep
  arrive. `self_modulate` was rejected outright: it tints everything the node
  draws, including the navy border and the caption.
- **Trade-off:** one colour now lives outside the theme resource. Mitigated by
  building it with `Palette.box()` — the same factory the generator uses — so the
  value still comes from `palette.gd` and the box is still constructed by shared
  code. This also avoids a trap the theme-lookup approach would have hit: theme
  lookups before tree entry silently return the *default* theme, so a tile that
  read `get_theme_stylebox()` too early would come out grey with no error.

## 8. Centre the action row rather than stretching tiles to fill

- **Date:** 2026-09-15
- **Considered:** `alignment = CENTER` with fixed tile sizes ·
  `size_flags_horizontal = EXPAND_FILL` on each tile
- **Chosen:** centred with fixed sizes — it reads correctly at any count. One
  tile sits centred; three sit centred with gaps between them.
- **Trade-off:** the tiles will not automatically fill the bar's width, so three
  tiles leave whatever margin the fixed size implies rather than dividing the
  space exactly. `EXPAND_FILL` was rejected because with today's single tile it
  would stretch one button across the entire screen.

## 9. Build tile_button.tscn now, before Play and Clean exist

- **Date:** 2026-09-15
- **Considered:** styling the existing `FeedButton` directly and extracting a
  component when the second tile arrives · building the reusable tile immediately
- **Chosen:** build it now — this was the developer's explicit ask, and a
  component written against one real caller is shaped by real constraints rather
  than by guesses about the other two.
- **Trade-off:** it is scope slightly ahead of need, which `CLAUDE.md` warns
  about. Bounded deliberately: the tile gets the four exports the feed button
  actually uses and nothing speculative — no variant system, no state machine, no
  action registry.

## 10. Drop the placeholder glyph now that icon art exists

- **Date:** 2026-09-15
- **Considered:** keeping the glyph as a fallback for future tiles whose art is
  not drawn yet · removing it
- **Chosen:** removed — it **supersedes decision 6**, which only existed because
  there was no art. `assets/sprites/ui/` now holds `carrot`, `controller` and `broom`,
  so every tile the design calls for has its icon. Keeping placeholder machinery
  for a hypothetical future missing icon is exactly the speculative scope
  `CLAUDE.md` warns against.
- **Trade-off:** a tile added before its icon is drawn shows an empty slot rather
  than a letter. Acceptable — it is a one-line `@export` to add back, and an
  empty slot is at least as visible a reminder as a stray letter.

## 11. Keep two Fredoka faces and delete the rest of the pack

- **Date:** 2026-09-15
- **Considered:** committing the whole 25-static family plus the variable font ·
  keeping only the two faces the theme references
- **Chosen:** two faces — Godot exports every resource under `res://` whether or
  not anything references it, so the other 23 statics and the variable font were
  about 1.3 MB of dead weight in the APK.
- **Trade-off:** reaching for Light, Medium, or a Condensed width later means
  re-downloading the family. Cheap, and noted in `assets/fonts/README.md`.

## 12. Skip the tile's theme overrides in the editor

- **Date:** 2026-09-15
- **Considered:** leaving `tile_button.gd` fully `@tool` · dropping `@tool`
  entirely · keeping `@tool` but returning from `_refresh()` before the stylebox
  overrides when `Engine.is_editor_hint()`
- **Chosen:** the early return. A theme override applied by a `@tool` script is a
  real property change, so the editor serialises it into every scene that
  instances the tile. Opening and saving `hud.tscn` had already baked two
  `StyleBoxFlat` sub-resources carrying the accent as a literal
  `Color(0.98, 0.86, 0.90, 1)` — precisely the drift `palette.gd` exists to
  prevent, and it would have gone stale the moment a token changed.
- **Trade-off:** the editor no longer previews a tile's accent. Costs nothing in
  practice — a pressed state is invisible at rest anyway — and the icon, caption
  and tile size still preview, which is what laying out the action bar needs.
  Dropping `@tool` altogether would have fixed the baking too, but at the price
  of a tile that shows as an empty box in the editor.
