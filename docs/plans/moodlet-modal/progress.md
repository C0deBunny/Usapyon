# Progress: Moodlet Modal

<!-- Living log. Append newest entries at the top:
     ## YYYY-MM-DD
     - Did: <what changed> (<sha>)
     - Verified: <how>
     - Next: <what remains> / Blocked: <on what>
-->

## 2026-09-15

- Did: built the whole plan in one pass — uncommitted.
  - `bunny_care_rules.gd` generalised: `care_value` / `can_restore` / `restored`
    / `decayed`, `STARTING_VALUE`, `MIN_VALUE` / `MAX_VALUE`, and `CARROT` /
    `SPONGE` / `BALL` at 20 each.
  - `game_state.gd` gained `cleanliness` and `happiness` as hand-written
    properties, `try_clean()` / `try_play()`, and decays all three from the one
    `last_ticked_at`.
  - `save_manager.gd` at `VERSION = 2` with the two new keys.
  - `debug_panel.tscn` / `.gd` at full parity: three readouts, three ± rows,
    Fresh / Hungry / Neglected.
  - `palette.gd` gained `DIM`, `RADIUS_PANEL`, `RADIUS_BAR`, `BAR_HEIGHT`,
    `ICON_BUTTON_SIZE`, `MOODLET_ICON_SIZE`, `BAR_TWEEN_TIME`, plus
    `icon_button_box()`, `panel_box()` and `bar_box()`.
  - `build_theme.gd` gained `_define_icon_button()`, `_define_panel()` and
    `_define_progress_bar()`; theme regenerated.
  - New `scenes/ui/moodlet.tscn` / `.gd` and `scenes/ui/moodlet_panel.tscn` /
    `.gd`.
  - `hud.tscn` lost the top-centre HungerPanel and gained Clean and Play tiles
    plus the modal; `hud.gd` lost `_refresh()`.
  - Milestone 02 rewritten through §2.1–2.10, the checklist, the Definition of
    Done and the "Not Part Of" list.
- Verified: headlessly, all of it.
  - `--import` clean; theme regenerated and contains `IconButton/*`,
    `Panel/styles/panel`, `PanelContainer/styles/panel`,
    `ProgressBar/styles/{background,fill}`.
  - Pure rules probed with a throwaway `SceneTree` script:
    `care_value(80.4)=80`, `can_restore(80.4, SPONGE)=true`,
    `can_restore(81, BALL)=false`, `restored(70.6, CARROT)=91.0`,
    `decayed(100, 25h)=0.0`, `decayed(100, 60s)=99.933`.
  - Temporary prints in the live scene confirmed the panel script runs, the dim
    colour and button icon load, the per-instance bar fill override is applied at
    runtime, `try_clean` / `try_play` restore correctly, and open/close toggle
    the dim and panel. Prints removed afterwards.
  - The version-1 save path was exercised for real by the existing debug save:
    hunger loaded at 88.8 from disk while cleanliness and happiness defaulted to
    70 and decayed by the same 10.2 as everything else.
  - Final `--import` and a 300-frame run: no errors, no warnings.
- Next: everything visual needs the developer on a real phone — see the checklist
  in milestone 02 §"Moodlet Panel" and §"Android". Specifically unjudged from
  here: the dim alpha, the panel's width and top-left offsets, whether the pop-in
  reads as growing out of the button, and whether three tiles feel crowded.
  Nothing is committed yet.

## 2026-09-15 — second pass: modal → popover

- Did: reworked it after seeing the first build running. Still uncommitted.
  - **Not a modal any more.** The `Dim` node is gone, nothing is blocked, and the
    button is a plain toggle. `_on_dim_input()` and `Palette.DIM` deleted.
  - **Opens itself.** New `GameState.cared`, emitted by all three `try_*` on
    success; `fed` stays feeding-only. A self-opened popover closes again after
    `AUTO_CLOSE_SECONDS` (2.5); a hand-opened one is on no clock, and pressing the
    button cancels any leftover countdown.
  - **Much smaller.** Measured the reference against the build: the *width* was
    already right, the internals were ~1.4× too big. Card 424 × 378 → **384 × 267**
    (verified at runtime, exact). Icon 96→60, bar 44→22, bar border 4→3, label
    font 36→26, row gap 28→22, card padding 40/36→24/20, panel radius 40→28. All
    named in `palette.gd`; `moodlet.gd` applies them so the scene hard-codes
    nothing.
  - **The tail.** New `scenes/ui/tail.gd` — a `_draw()` filling the triangle in
    `SURFACE` and stroking its two slanted edges antialiased in `OUTLINE`. Ordered
    after the card, overlapping its top border by exactly one border width so the
    fill opens the bubble without spilling onto the card. Needed a new `Popover`
    wrapper node so the tail scales with the card during the pop-in.
  - **The face follows the worst stat.** `LOW_VALUE` (30) and `CRITICAL_VALUE` (5)
    added to `BunnyCareRules`; `moodlet_panel.gd` picks happy / sad / angry from
    three exported textures.
  - **Bar slide delayed.** `BAR_TWEEN_DELAY` 0.15 then `BAR_TWEEN_TIME` 0.4, so the
    fill runs after the pop-in lands rather than behind it.
  - **`Hungry` preset deleted** — a leftover from the one-stat build. Fresh and
    Neglected remain.
  - Docs: decisions 16–23 appended and 9/10/11 marked superseded; `plan.md`
    reworked (goal, approach, components, sizing table, risks, open questions);
    milestone §2.3, §2.4, §2.5, §2.7, §2.8, §2.9 and the checklist rewritten.
- Verified: headlessly, with temporary prints since removed.
  - Card measured **384.0 × 267.0** at runtime — the target exactly.
  - `Popover` children order confirmed `[Panel, Tail]`, so the tail draws last.
  - Face thresholds exercised live: hunger 25 → `bunny_sad`, 3 → `bunny_angry`,
    90 → `bunny_happy`.
  - `try_clean` → popover open, auto-close timer running.
  - Bar min `(258, 22)` and icon min `(60, 60)` applied from `Palette`.
  - Theme regenerated; final `--import` and a 300-frame run: no errors, no
    warnings.
- Next: still all visual, still needs the phone — the new checklist sections
  "Moodlet Popover", "Auto-open" and "The face" are the list. Unjudged from here:
  whether 26px labels read at arm's length, whether 2.5s is the right auto-close,
  whether the tail's 44 × 18 is the right weight, and whether the pop-in now reads
  as growing out of the button. Nothing is committed.
