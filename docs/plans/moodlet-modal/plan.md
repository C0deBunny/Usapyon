# Plan: Moodlet Popover — Cleanliness, Happiness, and a Stats Readout

> **Reworked 2026-09-15**, after seeing the first build running. It was a modal;
> it is now a non-blocking popover that opens itself when you care for the
> Usapyon, at roughly two-thirds the size. See decisions 16-23.

## Goal

Give the Usapyon the other two care stats the design has always called for —
🧽 Cleanliness and 😊 Happiness — and move all three readouts off the main
screen into a popover opened by a button in the top-left corner, so the room and
the Usapyon get the whole screen back.

The popover blocks nothing and dims nothing, and it opens itself whenever a care
action lands so the bar can be watched filling. The button wears the Usapyon's
face, which follows its worst stat.

The reference is `docs/design/reference/Moodlet component reference.png` — a
bunny-face button top-left over a card of three labelled bars. Its dimming and
its tap-outside-to-close did not survive contact with the running game; its
proportions did, and are what the sizing below is measured against.

## Non-goals

- **Care reactions for cleaning and playing.** `fed` keeps driving the happy hop;
  Clean and Play move a bar and nothing else. Deliberate — see decision 7.
- **Numbers on the bars.** The reference has none and neither do we — decision 13.
- **Any feedback on a refused action.** The popover opens on success only —
  decision 20.
- **Care Points, the feeding cooldown, a second food or tool, sickness, the
  garden.** All still deferred by milestone 02's "Not Part Of" list.

## Context

`CLAUDE.md` owns the conventions — renderer, resolution, `uid://` handling,
static typing, script size, "prefer built-in Godot features". This section only
covers what is specific to this change.

**The rules are already stat-agnostic.** Every function in
`systems/bunny_care_rules.gd` takes a plain float and returns one; nothing about
the maths knows it is hunger. Only the *names* are hunger-specific. Generalising
them is therefore a rename, not a rewrite.

**`GameState.hunger` is a hand-written property**, not a plain var: its setter
clamps to 0–100, drops no-op writes so a resting stat does not announce itself
sixty times an hour, and emits `changed`. Whatever hunger does, the two new
stats must do identically.

**Two theme gaps, found while planning.** There is no `Panel` stylebox and no
`ProgressBar` stylebox in `scenes/ui/theme/build_theme.gd`. The existing
HungerBar has been drawing Godot's *default* grey/blue all along, and a
`PanelContainer` would come out default grey too. Both must be defined before
the popover can look like anything.

**Per-instance styleboxes have a rule.** `scenes/ui/tile_button.gd` documents
it: build the stylebox from `Palette` constants, never from a theme lookup,
because a theme lookup made before the node is in the tree silently returns the
*default* theme and the control comes out grey with no error to explain it. The
moodlet bar's fill colour follows the same discipline.

**`usapyon_theme.tres` is generated output.** Change `palette.gd` or
`build_theme.gd` and re-run:

```
godot --headless --path . --script res://scenes/ui/theme/build_theme.gd
```

## Approach

Two halves that barely touch each other.

**Behind the scenes** is almost entirely renaming. `BunnyCareRules` loses its
hunger-specific vocabulary (`fed` → `restored`, `can_eat` → `can_restore`,
`STARTING_HUNGER` → `STARTING_VALUE`) and gains `SPONGE` and `BALL` beside
`CARROT`, all worth 20. `GameState` grows two more hand-written properties that
are line-for-line copies of `hunger`'s, and two more `try_*` functions that are
line-for-line copies of `try_feed` minus the signal. This is deliberate
duplication: the alternative was a stat enum plus a dictionary, which buys
fifteen fewer lines at the cost of every call site becoming
`set_stat(Stat.HUNGER, x)` — see decision 2.

**On screen**, the whole popover is one self-contained scene,
`moodlet_panel.tscn`, owning its button, its card and its tail together, so
`hud.gd` instances it and wires nothing.

It blocks nothing. There is no dim and no input-catching layer: the button is a
plain toggle, and the Usapyon, its ears and the three care tiles all stay live
while the card is up. What replaces tap-outside-to-close is that the popover
mostly manages itself — a care action opens it, and if it opened itself it closes
itself again a couple of seconds later. A popover the player opened by hand is on
no clock.

The tail is drawn, not textured: `tail.gd` fills a triangle in `SURFACE` and
outlines its two slanted edges in `OUTLINE`, and is ordered after the card so its
fill covers the card's top border and the bubble actually opens. That needs a
`Popover` wrapper node, because the tail has to scale with the card during the
pop-in.

See `decisions.md` for the choices and what they cost.

## Components

- **`systems/bunny_care_rules.gd`** — rename to stat-agnostic vocabulary.
  `care_value(value)`, `can_restore(value, amount)`, `restored(value, amount)`,
  `decayed(value, seconds)`. `STARTING_HUNGER` → `STARTING_VALUE` (70),
  `MIN_HUNGER`/`MAX_HUNGER` → `MIN_VALUE`/`MAX_VALUE`, plus `LOW_VALUE` (30) and
  `CRITICAL_VALUE` (5) for the face. `DECAY_PER_HOUR` stays
  4.0 and is shared by all three. `CARROT`, `SPONGE`, `BALL` — each 20.0, named
  separately so the first one that differs costs nothing to split.

- **`autoloads/game_state.gd`** — `cleanliness` and `happiness` as hand-written
  properties beside `hunger`, each with its own backing float and identical
  setter. `catch_up_to()` decays all three from the one `last_ticked_at`.
  `try_clean(amount)` and `try_play(amount)` beside `try_feed(amount)`; all three
  emit `cared` on success, only `try_feed` also emits `fed`. `reset_to_new()`
  sets all three to `STARTING_VALUE`.

- **`autoloads/save_manager.gd`** — `VERSION = 2`, two new keys. A version-1
  save's absent keys read `STARTING_VALUE`, then decay with elapsed time like
  everything else.

- **`scenes/debug_panel.tscn` / `.gd`** — a `%.1f` readout and a ±10 row per
  stat. Presets: Fresh (all 100) and Neglected (all 5) — Hungry was dropped, a
  leftover from when hunger was the only stat. The time
  buttons already cover all three for free, because they rewind the clock and
  let the ordinary catch-up run.

- **`scenes/ui/theme/palette.gd`** — every moodlet measurement (see Sizing
  below), the tail geometry, icon-button size, and `bar_box()` / `panel_box()` /
  `icon_button_box()` beside the existing `box()` and `tile_box()`.

- **`scenes/ui/theme/build_theme.gd`** — new `_define_panel()`,
  `_define_progress_bar()` and `_define_icon_button()`. Regenerated after.

- **`scenes/ui/moodlet.tscn` / `.gd`** — one row:
  `HBox[ icon, VBox[ label, bar ] ]`. Exported `stat_name`, `icon_texture`,
  `fill` colour; `@tool` so it is visible in the editor, same setter-plus-
  `is_node_ready()` guard as `tile_button.gd`. `set_value()` waits
  `BAR_TWEEN_DELAY` then slides the bar over `BAR_TWEEN_TIME`, so the fill is not
  lost behind the pop-in.

- **`scenes/ui/moodlet_panel.tscn` / `.gd`** — a `Popover` wrapper holding the
  card and its tail, plus the bunny-face button beside it. Owns the toggle, the
  pop-in tween, the auto-open on `GameState.cared`, the auto-close countdown, and
  refreshing the three bars and the face from `GameState.changed`.

- **`scenes/ui/tail.gd`** — a `_draw()` on a bare `Control`. Fills the triangle
  in `SURFACE`, outlines its two slanted edges in `OUTLINE`, and overlaps the
  card's top border by one border width so the bubble opens. Ordered after the
  card.

- **`scenes/hud.tscn` / `hud.gd`** — the top-centre `HungerPanel` is deleted;
  `hud.gd` loses `_refresh()` entirely. Three tiles in the action row — Feed,
  Clean, Play — each with its stat's colour as `accent`. The moodlet panel is
  instanced here.

- **`docs/milestones/02-persistent-pet.md`** — Cleanliness and Happiness leave
  the "Not Part Of" list; §2.1's state tree, §2.3's function names, §2.7's UI
  section, §2.8's actions, the test checklist and the Definition of Done all
  widen to three stats.

### Stat table

| Stat | Icon | Bar colour | Tile | Tile presses | Amount |
| --- | --- | --- | --- | --- | --- |
| Hunger | `carrot.png` | `ORANGE` | Feed | `ORANGE_PRESSED` | `CARROT` 20 |
| Cleanliness | `sponge.png` | `BLUE` | Clean | `BLUE_PRESSED` | `SPONGE` 20 |
| Happiness | `heart.png` | `RED` | Play | `RED_PRESSED` | `BALL` 20 |

### The button's face

The worst of the three stats picks it, so one neglected stat is enough to show.
Thresholds live in `BunnyCareRules` beside the other pacing numbers; the mapping
from threshold to texture is the popover's.

| Worst stat | Face | Roughly, from full |
| --- | --- | --- |
| 30 or above | `bunny_happy.png` | — |
| below `LOW_VALUE` (30) | `bunny_sad.png` | ~17 h |
| below `CRITICAL_VALUE` (5) | `bunny_angry.png` | ~24 h |

### Sizing

Measured off the reference and then taken further — decision 17. The first build
turned out to have the *width* right already; what read as oversized was every
element inside it being about 1.4× the reference.

| | First build | Now | Reference |
| --- | --- | --- | --- |
| Card | 424 × 378 | **384 × 267** | 427 × 309 |
| Icon | 96 | **60** | 69 |
| Bar height | 44 | **22** | 24 |
| Bar outline | 4 | **3** | ~3 |
| Label font | 36 | **26** | ~28 |
| Row gap | 28 | **22** | 23 |
| Card padding | 40 / 36 | **24 / 20** | 27 |

Every one of those is a named constant in `palette.gd`, and `moodlet.gd` applies
them rather than the scene hard-coding them, so the whole popover retunes from
one file.

## Risks

- **A refused action is still completely silent.** The popover opening is now
  strong feedback for a *successful* Clean or Play, so the success side of
  decision 7's asymmetry is largely closed. The refusal side is not: tap Feed at
  90 and nothing happens anywhere on screen — no popover, no number, no reaction.
  That is decisions 13 and 20 compounding, and it is the first thing that will
  feel wrong on the phone. The proper fix is the Usapyon refusing out loud —
  *"Your Usapyon isn't hungry right now"* — which milestone 02 defers. Accepted,
  and recorded in the milestone as a known gap.

- **The popover can open while the player is doing something else.** Nothing is
  blocked any more, so a care tap can pop the card over the room mid-gesture. It
  is top-left and 384 × 267, well clear of the Usapyon and the action row, so
  there is nothing for it to land on top of — but that stops being true the
  moment anything else moves into that corner.

- **Regenerating the theme rewrites `usapyon_theme.tres` wholesale.** Anything
  anyone tuned by hand in Godot's Theme panel is destroyed. That is the file's
  stated contract, but it is worth knowing before the first run.

- **The bar tween fires on every heartbeat.** `GameState.changed` emits roughly
  once a minute as the raw float drifts, even though `care_value()` rounds to the
  same integer. `set_value()` must no-op when the target already matches, or
  three tweens are created every sixty seconds forever.

- **`@tool` scripts and theme overrides.** `tile_button.gd` documents the trap: a
  theme override applied by a `@tool` script gets serialised into every scene
  that instances it, baking a literal colour in and defeating `palette.gd`.
  `moodlet.gd` must guard its fill override with `Engine.is_editor_hint()` the
  same way.

## Open questions

- Every number under Sizing is measured, not judged. A 26px label and a 22px bar
  need a real phone at arm's length before they are called right.
- Whether `AUTO_CLOSE_SECONDS` (2.5) is long enough to read the bar after it
  lands, and short enough not to be in the way when tapping Feed repeatedly.
- Whether the pop-in reads as growing *out of* the button now the tail points at
  it, or still merely as scaling nearby.
- Whether the tail's 44 × 18 is the right weight against a 384-wide card.

## Assets

No new visuals were produced for this plan. The source of truth is the reference
sheet already in the repo:
`docs/design/reference/Moodlet component reference.png`
