# Progress: A theme for Usapyon

<!-- Living log. Append newest entries at the top:
     ## YYYY-MM-DD
     - Did: <what changed> (<sha>)
     - Verified: <how>
     - Next: <what remains> / Blocked: <on what>
-->

## 2026-09-15 (asset reorg)

- Did: moved assets to match `docs/design/04-ui-architecture.md` —
  `assets/icons/` → `assets/sprites/ui/`, and the newly added
  `assets/background/` → `assets/sprites/background/`. Every sprite category is
  now a folder under `assets/sprites/`; `fonts/` and `audio/` sit beside it.
  Each `.png.import` moved with its `.png`, so UIDs survived and no scene
  reference broke beyond the two paths updated by hand.
- Did: updated the doc's own Project Layout block, which claims to describe the
  repo as it actually is, to list `ui/`, `background/` and `fonts/`.
- Did: fixed a real defect the editor exposed. Opening and saving `hud.tscn`
  serialised the `@tool` tile's runtime theme overrides into the scene as two
  `StyleBoxFlat` sub-resources with the accent baked in as a literal colour —
  exactly the drift `palette.gd` exists to prevent. `_refresh()` now returns
  before those overrides when `Engine.is_editor_hint()`, and the baked
  sub-resources were stripped from `hud.tscn`. `decisions.md` 12.
- Verified: probe confirmed both moved paths resolve
  (`assets/sprites/ui/carrot.png`, `assets/sprites/background/bedroom.png`) and
  that `pressed` is still `fadce5` at runtime with nothing baked in the scene.
  Probe removed; `--import` and `--quit-after` clean.
- Did NOT do: restore the autoload-ordering comment the editor stripped from
  `project.godot`. The editor deletes comments on every save, so putting it back
  would surface as a spurious deletion in every future diff, and
  `save_manager.gd:6` already records the constraint durably.
- Note: the developer's own edits in `main.tscn` (bedroom background, Bunny
  moved and scaled) and `hud.tscn` (action bar and hunger panel offsets) were
  left exactly as they were.

## 2026-09-15 (later)

- Did: Fredoka arrived as the full 25-static family pack plus the variable font.
  Kept `Fredoka-SemiBold.ttf` and `Fredoka-Bold.ttf` at `assets/fonts/`, deleted
  the rest (~1.3 MB nothing referenced). `decisions.md` 11.
- Did: icon art arrived at `assets/icons/`. The feed tile now uses `carrot.png`
  and the `glyph` placeholder was removed from `tile_button` entirely, along with
  `Palette.FONT_GLYPH`; added `Palette.ICON_SIZE`. `decisions.md` 10, which
  supersedes 6.
- Did: the caption now borrows the theme's `Button` font explicitly. A probe
  caught it rendering in SemiBold — it is a `Label`, so it was taking
  `default_font` rather than the Bold the theme sets for button text.
- Verified: probe confirmed `carrot.png` loaded, icon drawn at 144², caption in
  `Fredoka-Bold.ttf`, tile 280² centred at the bottom, `normal` = `fdf6f0` from
  the theme, `pressed` = `fadce5` from the accent override. Probe removed, final
  `--import` and `--quit-after` clean.
- Did NOT change: font import settings. Godot 4.7 already defaults to
  `Antialiasing = Gray`, mipmaps off, MSDF off. Its `hinting` and
  `subpixel_positioning` defaults are integers outside the enum ranges I could
  verify, so they were left rather than overwritten with a guess.
- Next: still nobody has seen this run. Same check list in `plan.md`.

## 2026-09-15

- Did: built the whole plan except the font files — `palette.gd`,
  `build_theme.gd`, the generated `usapyon_theme.tres`, `tile_button.tscn`/`.gd`,
  and the `hud.tscn` restructure into `ActionBar → Tiles → FeedButton`.
  `hud.gd` untouched, as designed.
- Did: `build_theme.gd` became a `SceneTree` script rather than the planned
  `EditorScript`, because an `EditorScript` only runs from inside the editor and
  so could be run by neither Claude nor CI. Same command for everyone now.
- Verified: `--headless --import` and `--quit-after 120` both clean. A temporary
  print in the tile confirmed the theme actually resolves at runtime rather than
  merely parsing — caption "Feed", glyph "C" visible, icon hidden, 280×280,
  `normal` = `fdf6f0` from the theme's `TileButton` variation, `pressed` =
  `fadce5` from the per-instance accent override. Print removed.
- Verified: the `ObjectDB instances were leaked` / `resources still in use`
  warnings on headless exit are pre-existing — identical counts with the
  original `hud.tscn` stashed back in.
- Blocked: **Fredoka is not installed.** `assets/fonts/README.md` says which
  three files to download and the import settings. The theme builds without them
  and falls back to Godot's default face, so the screen will look wrong until
  they land and `build_theme.gd` is re-run.
- Next: nobody has seen this run. Needs the developer on desktop and then on the
  phone — see the check list under "Risks" in `plan.md`.
