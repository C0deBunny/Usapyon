# Plan: A theme for Usapyon

## Goal

Give the game a visual system instead of per-node styling. One `Theme` resource
covers the three button shapes on the Button reference sheet — primary,
secondary and interaction tile — and every colour, radius and font size in it
comes from a single set of named constants.

The feed button stops being a lone `Button` with inline font overrides and
becomes the first tile in a centred action row, so that adding Play and Clean
later is dropping two more instances into a container.

> Open the app → the feed control is a cream, navy-outlined tile with a big
> carrot over the word "Feed" → hold it → it fills with soft pink and the shadow
> drops away → let go → it feeds, exactly as it does today.

## Non-goals

- **The hunger readout stays as it is.** `HungerValue` and `HungerBar` keep
  their inline `theme_override_*` and Godot's stock grey `ProgressBar`. The
  theme defines no `Label` or `ProgressBar` entries. See `decisions.md` 5.

  One deliberate leak: the theme sets `default_font`, which is theme-wide rather
  than a `Label` entry, so once Fredoka is installed the hunger label *will*
  render in it. Its size and colour overrides still win. Left that way on
  purpose — the alternative is pinning the label to Godot's default sans to
  defend a scope line, and a screen in two unrelated typefaces would read as
  broken rather than as unfinished.
- **The top bar is not built.** The Lv badge and settings gear from the UI
  reference sheet do not exist and are not added here.
- **The debug panel is deliberately excluded**, and keeps Godot's default grey.
  That grey is useful — it reads as "not the game". The exclusion is structural,
  not a flag: see `decisions.md` 2.
- **No gloss, sheen or sparkles.** The reference sheet's primary button has an
  inner highlight and the pressed tiles throw sparkles. `StyleBoxFlat` draws one
  fill, one uniform border and one shadow, and that is all this plan delivers.
  See `decisions.md` 1.
- **`project.godot` is not touched.** No project-wide default theme, no renderer
  or resolution change.
- **`PrimaryButton` is defined but unused.** Nothing in the game needs a
  confirm-style button yet. It exists so the theme is complete when the first
  dialog arrives.

## Context

`CLAUDE.md` owns the engine, renderer, resolution and coding rules, and
`docs/design/04-ui-architecture.md` owns UI construction — read both rather than
this section restating them. What is specific to this change:

- **`scenes/hud.tscn` is full of inline styles.** Every
  `theme_override_font_sizes/font_size` in it is the Godot equivalent of
  `style="font-size: 52px"` and beats anything a theme says. The feed button's
  overrides come off as part of this work; the hunger panel's stay, because the
  hunger panel stays unthemed.

- **`scenes/hud.gd` documents a load-bearing input rule** in its header comment —
  everything in the HUD that is not the button is `mouse_filter = IGNORE`, so the
  touch surface over the Usapyon stays as small as possible. The new action-bar
  containers must follow it. A container that forgets is an invisible tap-blocker
  across the bottom of the screen, and it will not look like a bug in the theme.

- **`hud.gd` reads `%FeedButton` typed as `Button`** and connects its `pressed`
  signal. `tile_button.tscn` is rooted on a `Button`, and the instance keeps the
  name `FeedButton` with `unique_name_in_owner`. The contract therefore holds
  and `hud.gd` is not edited at all.

- **`DebugPanel` is instanced under `Main` at `scenes/main.gd:8`.** `Main` is a
  `Control`, so a theme on `Main` would reach the debug panel. The theme goes on
  `Hud/Root`.

- **Asset layout follows `docs/design/04-ui-architecture.md`.** Every sprite
  category is a folder under `assets/sprites/` — `bunny/`, `ui/`, `background/` —
  with `fonts/` and `audio/` beside it, because they are not sprites.

## Approach

Treat the palette as design tokens with a build step, the way a front-end
project treats CSS custom properties.

`palette.gd` holds every colour, radius, border width, gap and font size as a
typed `const`. `build_theme.gd` reads those constants, constructs a `Theme`, and
saves it to `usapyon_theme.tres`. Run it whenever a token changes:

```sh
"$GODOT" --headless --path "C:/Coding/usa-pyon" --script res://scenes/ui/theme/build_theme.gd
```

The `.tres` is generated output — committed, editor-previewable, but not
hand-edited.

`palette.gd` also exposes a static factory, `Palette.box()`, returning a
configured `StyleBoxFlat`. Both the generator and `tile_button.gd` call it, so
the pressed-state box a tile builds at runtime is produced by the same code as
the one baked into the theme. That is what makes "no drift" literal rather than
a convention someone has to remember. It also sidesteps a real trap: theme
lookups made before a node enters the tree silently return the *default* theme,
so a tile that read `get_theme_stylebox()` too early would come out grey with no
error.

The theme mounts on `Hud/Root` and nowhere else. Scoping by attachment point is
the only clean way to exclude a subtree, because Godot's theme lookup is
per-property and falls through — assigning an empty `Theme` to the debug panel
would block nothing.

Within the theme, type variations are the component variants: `PrimaryButton`
and `TileButton` both set `base_type = Button`, inherit the border, radius and
margins, and override only what differs. This is `.btn-primary {}` layered on
`button {}`.

See `decisions.md` for the alternatives that were rejected along the way.

## Components

- **`assets/fonts/`** — `Fredoka-SemiBold.ttf`, `Fredoka-Bold.ttf`, `OFL.txt`
  and a `README.md` explaining the wiring. Two faces out of the 25-static family
  pack; the rest were dropped rather than committed, because Godot exports
  everything under `res://` whether referenced or not. See `decisions.md` 11.
  Godot 4.7's default import settings turned out to be right already —
  `Antialiasing = Gray`, mipmaps off, MSDF off — so nothing was overridden.

- **`assets/sprites/ui/`** — 256² PNGs in the reference sheet's outlined style.
  `carrot.png` is the feed tile's icon; `controller.png` and `broom.png` are
  waiting for Play and Clean. Godot's default texture import (lossless, no
  mipmaps) is correct for flat UI art and was left alone.

- **`scenes/ui/theme/palette.gd`** — `class_name Palette`. Every design token as
  a typed `const`: ink and surface colours, primary pink, the three tile
  accents, shadow, radii, border width, row gap, and the font scale. Plus the
  static `Palette.box(fill, radius, with_shadow)` stylebox factory shared with
  the tile. Never instantiated; it is a namespace.

- **`scenes/ui/theme/build_theme.gd`** — a `SceneTree` script, so it runs
  headlessly with `--script` and needs no editor. It builds the `Theme` from
  `Palette` and `ResourceSaver.save()`s it. Defines:

  ```text
  default_font       Fredoka-SemiBold
  default_font_size  Palette.FONT_BODY

  Button                                  the secondary look, and the safe default
    normal    cream fill, navy border, rounded, soft drop shadow
    pressed   darker cream, shadow removed — reads as sinking under the finger
    disabled  desaturated fill, border and font
    hover     = normal
    focus     = StyleBoxEmpty

  PrimaryButton   base_type Button   pink fill, deep pink pressed
  TileButton      base_type Button   larger radius, square minimum, taller margins
  ```

  `hover` and `focus` are silenced on purpose. The UI architecture doc says not
  to style them because there is no cursor — but *undefined* is not *absent*.
  Godot still draws the inherited defaults, and a tap would flash Godot's grey
  through a pink button. Every box also sets `corner_detail` above the default
  8, which renders visibly faceted at these radii.

- **`scenes/ui/theme/usapyon_theme.tres`** — generated, committed. Mounted on
  `Hud/Root`.

- **`scenes/ui/tile_button.tscn` + `tile_button.gd`** — a `Button` carrying
  `theme_type_variation = "TileButton"` with a centred `VBoxContainer` child
  holding an icon `TextureRect` and a caption `Label`.
  All children `mouse_filter = IGNORE`; the `Button`'s own `text` stays empty so
  it does not draw a second caption.

  The script is `@tool`, so the tile previews correctly in the editor, and
  exports `caption`, `icon_texture` and `accent`. `accent` overrides only the
  `pressed` stylebox, built via `Palette.tile_box()`.

  The caption explicitly borrows the theme's `Button` font. It is a `Label`, so
  left alone it would take the theme's *default* face rather than the heavier one
  the theme sets for button text — and it is button text.

  Built now, before Play and Clean exist, because a component shaped by one
  caller is a component shaped by its real constraints. See `decisions.md` 9.

- **`scenes/hud.tscn`** — the only modified file. `Root` gains the theme.
  `FeedButton` is replaced by:

  ```text
  Root (Control)                          theme = usapyon_theme.tres
  ├── HungerPanel                         untouched
  └── ActionBar (MarginContainer)         anchored bottom, full width
      │                                   mouse_filter = IGNORE
      └── Tiles (HBoxContainer)           mouse_filter = IGNORE
          alignment = CENTER
          separation = Palette.GAP
          └── FeedButton                  tile_button.tscn, unique_name_in_owner
  ```

  Per `CLAUDE.md`, the new `ext_resource` entries are written without `uid=` and
  the new nodes without `unique_id=`; Godot fills both in on next save.

## Risks

- **The drop shadow may clip.** A `StyleBoxFlat` shadow draws outside the box
  but still inside the `Control`'s rect. If the tile's rect is tight the shadow
  is cut off. Mitigated by `expand_margin` or by giving the tile more room —
  but it needs eyes on it, which means the developer running it.

- **Fredoka's import settings are taste.** Godot 4.7's defaults were kept. If the
  text looks muddy on the phone, `Hinting` and `Subpixel Positioning` in the
  Import dock are the two knobs worth trying — see `assets/fonts/README.md`.

- **`usapyon_theme.tres` is generated output.** Tweaking it in Godot's Theme
  panel works, and is then silently destroyed the next time anyone runs
  `build_theme.gd`. Accepted: the file carries a comment saying so, and the
  alternative — hand-authoring — reintroduces exactly the drift this plan
  exists to prevent.

- **Claude cannot see the result.** Headless runs prove the scenes parse and
  nothing throws; they prove nothing about how it looks. The developer must run
  it and check: Fredoka actually rendering rather than Godot's default sans; the
  tile cream with a navy outline and the carrot above the caption; the fill
  turning soft pink and the shadow vanishing while held; no grey flash or focus
  ring on tap; the Usapyon still tappable in the bottom area beside the tile;
  and the shadow not clipped.

## Open questions

- **Which milestone owns this.** `CLAUDE.md` makes `docs/milestones/` the only
  build authority, and `02-persistent-pet.md` does not mention theming. This
  work either extends Milestone 2 or wants a milestone document of its own —
  a call for the developer, not for the implementer of this plan.

- **Whether the tile's minimum size survives three tiles.** Sized for one today.
  At 1080 wide with two gaps and the action bar's own margins, three tiles have
  to fit; the number may need revisiting when Play and Clean arrive, and that is
  expected rather than a defect.
