# Progress: A Usapyon that needs you

<!-- Living log. Append newest entries at the top:
     ## YYYY-MM-DD
     - Did: <what changed> (<sha>)
     - Verified: <how>
     - Next: <what remains> / Blocked: <on what>
-->

## 2026-09-15 (2) — the milestone, built

- Did: the whole care loop (`72b149e`). `systems/bunny_care_rules.gd`,
  `autoloads/game_state.gd`, `autoloads/save_manager.gd`, `scenes/hud.tscn`,
  `scenes/debug_panel.tscn`, `scenes/main.gd`, a `Bounce` node in `bunny.tscn`,
  `celebrate()` in `bunny.gd` and `hold_shut()` in `eye.gd`. Both autoloads are
  registered with `GameState` before `SaveManager`, with a comment in
  `project.godot` saying why, since nothing else would reveal that ordering.
- Verified by temporary instrumentation, then removed — a clean headless exit
  proves the project parses, not that anything ran. Every number below is from
  that run:
  - **Rules.** `fed(70,20)=90`, `fed(95,20)=115` (uncapped by design — the
    GameState setter clamps), `decayed(100, 1h)=96`, `decayed(100, 25h)=0.0`
    exactly, which is the 25-hour figure `decisions.md` 4 was chosen for.
  - **The setter.** `150 → 100`, `-50 → 0`. Assigning 0, then 42, then 42 again
    starting from 0 emitted `changed` exactly once, so the "only when it moved"
    rule holds in both directions.
  - **The clock.** +6 h from 100 → 76, +24 h from 100 → 4, +24 h from 10 → 0
    rather than negative, and a clock moved two hours *backwards* left hunger at
    50 rather than handing out free food.
  - **Persistence across processes, which is the actual milestone.** A second
    launch read the file written by the first and reported hunger 69.92 with the
    stored `last_ticked_at` 70 seconds old — 70 s at 4/hour is 0.078. Offline
    progression is demonstrably running off a real file, not a simulated gap.
  - **The float survives.** 72.4 written, 72.4 read back. The HUD label rounds
    to `Hunger 72` and never writes the rounded number anywhere.
  - **Atomic write and recovery.** After two saves the `.bak` exists and no
    `.tmp` is left behind. Deliberately corrupting the main file made the next
    load fall back to the backup and recover the real value.
  - **Reset.** Back to 70, backup gone, file rewritten.
  - **The idle animation still animates.** This is the failure the plan called
    out as silent: `Visual.y` moved between -7.71 and -0.99 over 40 frames, so
    all eight `Bounce/` NodePaths in `idle` and `RESET` resolve. Had one been
    wrong there would have been no error anywhere — only a Usapyon that had
    stopped breathing.
  - **The hop.** `Bounce.position.y` reached -54.99 against a 55 constant, the
    scale moved, both eyes reported `is_busy()` immediately after `fed`, and
    0.8 s later everything was back at position (0,0), scale (1,1) and the eyes
    no longer busy. So it runs *and* it cleans up after itself.
  - **Wiring.** The debug panel is instanced in a debug build, and a HUD feed
    press took hunger 70 → 90 with the label following.
- Note for future runs: headless frames are faster than 60 fps, so a loop of
  `await process_frame` covers less tween time than the frame count suggests.
  Sample against a `create_timer()` when the timing matters.
- The leak baseline is unchanged: still `4 ObjectDB instances` and
  `2 resources still in use`, which is the `Music` autoload from
  `../background-music/progress.md` and not a regression from this work.

### One deviation, and it needs a decision

- **The debug toggle says `DBG`, not 🛠, and the hunger label says `Hunger`, not
  🥕 `Hunger`.** Godot's default theme font has no emoji glyphs, so both would
  render as an empty box rather than as the icon `decisions.md` 19 pictures.
  Nothing about the decision changes — it is still a small always-visible
  toggle, top-right, clear of the centred hunger bar — only the glyph. Fixing it
  properly means either an emoji-capable font in the theme or a small icon
  texture, and neither is Milestone 2 work. Worth a look on the phone before
  choosing.

### What could not be verified from here

Everything in this list needs the developer, and most of it needs the phone.

1. **The input-stealing test, `decisions.md` 13.** The one real risk in the
   milestone. Pull an ear, drag the finger over the `FEED CARROT` button, lift.
   Springs back → nothing to change. Stays stretched → move `ear.gd` and
   `eye.gd` from `_unhandled_input` to `_input`. Then repeat over the `DBG`
   button in the top-right corner. Every non-button node in both new scenes is
   `mouse_filter = IGNORE`, so the buttons are the only surfaces that can eat a
   release — but that is a reading of input ordering, not an observation.
2. **Backgrounding.** `NOTIFICATION_APPLICATION_PAUSED` only fires on Android,
   so the save-on-background path has never executed. Feed, background the app,
   force-stop it, reopen: hunger should be the fed value minus the time away.
3. **Atomic rename on Android.** It worked on Windows, where Godot deletes the
   destination and renames; on Android it maps to POSIX `rename`, which should
   be atomic. Confirm no stray `.tmp` survives in the app's private storage.
4. **Whether 4 hunger/hour feels right.** Needs real days on the phone, not a
   debug button. One constant in `bunny_care_rules.gd`.
5. **Anything visual.** Whether the hop reads as happy rather than twitchy;
   whether the bar at y≈90–230 sits clear of the ears; whether `FEED CARROT` is
   in comfortable thumb reach; whether the debug panel fits on a real screen.

The desktop save lives at
`%APPDATA%\Godot\app_userdata\UsaPyon\savegame_debug.json` if you want to read
the raw stored values — `Reload From Disk` runs the catch-up, so it will not
show them to you (`decisions.md` 18).

## 2026-09-15 (1) — the milestone doc, reconciled first

- Did: brought `docs/milestones/02-persistent-pet.md` in line with the plan
  (`fbe1132`), before any code. `CLAUDE.md` makes milestones the only build
  authority, so leaving it naming `BunnyStats` and `last_saved_at` would have
  pointed the next session at names that no longer exist.
- All seven rows of the plan's reconciliation table, plus two more found while
  reading the doc end to end: the data-flow block said "BunnyStats / Actions
  modify state", which is exactly the mutating shape `decisions.md` 9 rejected,
  and §2.1 drew the state nested under a `bunny` sub-object while every other
  section — and the whole plan — says `GameState.hunger`.
- Worth recording because the numbers do not match on inspection: the plan's
  table counts *sections*, not occurrences. The file actually held four
  `last_saved_at` and eight `BunnyStats` (§2.6 mentions the timestamp twice,
  §2.3 mentions the module three times). Nothing was missed; `grep` now returns
  zero of either.
- Verified: by reading the diff. It is a documentation change with no code in
  it, so there is nothing to run.
