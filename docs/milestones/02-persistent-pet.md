# Milestone 2 — A Usapyon That Needs You 🥕

**Status: next.** Builds on [`01-interactive-bunny.md`](01-interactive-bunny.md).

Systems design — what the stats are and where progression goes — lives in
[`../design/01-game-mechanics.md`](../design/01-game-mechanics.md). This file
owns only what gets built in this milestone, and how.

## Goal

Move the Usapyon from a **cute interactive character** to a **persistent
virtual pet with needs and care**.

Milestone 2 is complete when this loop works end-to-end:

> Open app → see the care stats → feed, clean or play with your Usapyon → the
> stat changes → it reacts → save → close app → reopen later → state is
> restored and time-away effects are applied.

------------------------------------------------------------------------

## Core Architecture

| System | Responsibility |
| --- | --- |
| **GameState** | Single source of truth during the current game session |
| **SaveManager** | Loads and saves player data locally |
| **BunnyCareRules** | Pure gameplay rules for the care stats, care actions, and time decay |
| **Bunny / `bunny.gd`** | Presentation, animations, reactions, and interactions |
| **DebugPanel** | Developer-only controls for manipulating/testing state |
| **UI** | Shows the care stats and provides the care controls |

### Data flow

``` text
save file
    ↓
SaveManager
    ↓
GameState  ←── single source of truth
    ↓
Actions apply BunnyCareRules and assign the result back
    ↓
Bunny + UI react to state
    ↓
SaveManager persists important changes
```

The visible Bunny should **not** own the authoritative stats or save
data.

------------------------------------------------------------------------

## 2.1 — GameState

Create a global/autoload `GameState`.

For this milestone, keep the state deliberately small:

``` text
GameState
├── hunger
├── cleanliness
├── happiness
└── last_ticked_at
```

Flat, not nested under a `bunny` sub-object — there is one creature, and
`GameState.hunger` is the name every other section here uses.

Three stats, three hand-written properties. Each has its own backing float and
its own setter, and the three setters are the same eight lines. That duplication
is deliberate: a dictionary keyed by a stat id would save fifteen lines and cost
every reader its plain name, and `CLAUDE.md` puts data-driven layers on the "ask
first" list.

Later this expands with the rest of the design — care points, care stars, coins,
inventory, customization — but none of that is required for Milestone 2.

### Rules

-   `GameState` is the source of truth while the game is running.
-   UI and Bunny read from `GameState`.
-   Gameplay actions and game systems manipulate `GameState`.
-   Do not keep duplicate authoritative stat values elsewhere.

------------------------------------------------------------------------

## 2.2 — SaveManager

Create a global/autoload `SaveManager`.

Responsibilities:

``` text
load save file
write save file
reset save
```

Creating the new-player state is **not** SaveManager's job: it calls
`GameState.reset_to_new()`, which reads `BunnyCareRules.STARTING_VALUE`. That
keeps gameplay numbers out of the module about file I/O, and keeps every number
that decides how the game feels in one file.

Saves go to `user://`, and debug builds write a separate file from release
builds — see [`../conventions.md`](../conventions.md#save-file-separation) for
the paths and why they are split.

### File format

``` json
{"version": 2, "hunger": 72.0, "cleanliness": 64.0, "happiness": 81.0, "last_ticked_at": 1757894400}
```

`version` removes the guesswork the first time a field changes meaning rather
than merely being added. Missing keys read as defaults, so a Milestone 2 save
still opens in Milestone 3.

It went to 2 when cleanliness and happiness arrived. A version-1 file has neither
key, so both read `STARTING_VALUE` — the same value a brand-new Usapyon gets —
and then decay with elapsed time like every other stat. Defaulting them to 100
would hand a returning player two full bars nothing earned.

Writing is atomic: write `savegame.tmp`, keep the current file as `.bak`, then
rename the temp over the real file. An Android kill mid-write then leaves either
the old file or the new one, never half of one. A load that cannot parse the
main file falls back to `.bak`, and only if that fails too does it start a new
game. "Your pet vanished" is the worst failure this game has.

### Startup

``` text
App starts
    ↓
SaveManager loads local save
    ↓
GameState is populated
    ↓
Bunny/UI read GameState
```

### Saving

``` text
Meaningful player action
    ↓
GameState changes
    ↓
SaveManager saves GameState
```

Do **not** save after every tiny state change. Save at meaningful
checkpoints such as feeding, purchases, progression changes, and when
the app is backgrounded.

------------------------------------------------------------------------

## 2.3 — BunnyCareRules / Gameplay Rules

`BunnyCareRules` contains the rules for changing the care stats.

### Every stat reads as a good thing

**100 = completely full, clean or delighted; 0 = starving, filthy or miserable.**
A care action raises the number; time lowers it. All three stats follow this
direction — a full bar is always good news — so one bar can be drawn the same way
for all of them without anyone having to remember which one is inverted.

For Milestone 2 it needs four functions, all **pure** — they take a care value
and return something, and never mention `GameState`. None of them names a stat:
the maths is identical for all three, so hunger, cleanliness and happiness run
through the same four functions.

``` text
care_value(value)           -> int     the rounded value the game and the player share
can_restore(value, amount)  -> bool    false when the action would overcap
restored(value, amount)     -> float
decayed(value, seconds)     -> float
```

What each action is worth *is* named per action — `CARROT`, `SPONGE`, `BALL`,
all 20 today. Three constants rather than one shared `CARE_AMOUNT`, so the first
food worth +40 costs nothing to add and `can_restore()` gives it the right
window on its own.

Two more numbers live here without a function of their own: `LOW_VALUE` (30) and
`CRITICAL_VALUE` (5), the points at which a stat becomes a problem. They are
pacing numbers like everything else in this file — §2.7's face reads them, and
sickness and debuffs will read them later. What a threshold *looks like* is not
decided here.

### The float is a decay accumulator, not the number the game reasons about

Every stat is stored as a float only so decay can accumulate between 60-second
heartbeats. **Every gameplay rule and every player-facing readout runs on
`care_value(value)`** — the bar and the care check both derive from that one
integer, so the screen can never contradict the button. Only `decayed()` sees the
fraction.

This is why `restored()` is `care_value(value) + amount` rather than a plain add:
a care action then lands on an exact integer, so "care never overcaps" is
provable rather than approximate. The float is still what gets clamped, saved and
decayed, and the debug panel's `%.1f` readouts are the one place it stays visible
— the moodlet bars carry no numbers.

Pure functions can be checked with a single `print()` and no autoload, no scene
and no tree, which is exactly the headless verification `CLAUDE.md` asks for
before claiming something works. The caller assigns the result:

``` gdscript
GameState.hunger = BunnyCareRules.restored(GameState.hunger, BunnyCareRules.CARROT)
```

There is no separate `clamp_value()`. Clamping to 0–100 happens inside each of
`GameState`'s three setters, so it holds for *every* write — including
`GameState.cleanliness = 5` typed straight into the debug panel by someone who
has never heard of the rule. `MIN_VALUE` and `MAX_VALUE` live in
`BunnyCareRules` rather than in `GameState`, because `can_restore` needs the cap
and the rules may not name `GameState`. The setters read them from there.

Example:

``` text
Carrot → +20 hunger
Sponge → +20 cleanliness
Ball   → +20 happiness
```

Time progression:

``` text
Time passes
→ all three stats slowly decrease
```

One `DECAY_PER_HOUR` shared by all three, and one `last_ticked_at` — they decay
together. If cleanliness ever wants to fall faster than hunger, that constant
splits into three and nothing else changes.

Keep these rules separate from `bunny.gd`.

### Responsibility split

``` text
GameState      = what your Usapyon's current values ARE (and when they advance)
BunnyCareRules = rules for HOW MUCH those values change
Bunny          = how your Usapyon visually reacts
SaveManager    = how those values persist
```

------------------------------------------------------------------------

## 2.4 — Debug Build + DebugPanel 🛠️

Create a developer-only debug panel.

It should only be available in debug/development builds, for example
using:

``` gdscript
OS.is_debug_build()
```

A first version can be extremely simple:

``` text
┌────────────────────────┐
│ 🛠 USAPYON DEBUG        │
│                        │
│ Hunger: 72.0           │
│ [-10]           [+10]  │
│ Cleanliness: 64.0      │
│ [-10]           [+10]  │
│ Happiness: 81.0        │
│ [-10]           [+10]  │
│                        │
│ TIME                   │
│ [+1 hour]              │
│ [+6 hours]             │
│ [+24 hours]            │
│                        │
│ SAVE                   │
│ [Save Current State]   │
│ [Reload From Disk]     │
│ [Reset Save]           │
│                        │
│ PRESETS                │
│ [Fresh]    [Neglected] │
└────────────────────────┘
```

Every stat gets its own readout and its own ± row. Putting one stat low while
another stays high is exactly the state the moodlet popover is most worth looking
at, and only per-stat controls can produce it.

The time buttons need no per-stat version: `catch_up_to()` decays all three, so
one `+6 hours` covers the lot.

### Debug behavior

Direct stat manipulation can change `GameState` directly:

``` text
Set Cleanliness = 5
    ↓
GameState.cleanliness = 5
    ↓
Bunny/UI immediately react
```

Time simulation should call the **real gameplay logic** — not a parallel copy of
it. It does that by moving the clock backwards and then letting the ordinary
catch-up run:

``` text
Debug: +6 hours
    ↓
GameState.last_ticked_at -= 6 hours
    ↓
GameState.catch_up_to(now)   ← the same call a cold launch makes
    ↓
GameState changes
```

This ensures the debug panel tests the same logic real players use, structurally
rather than by anyone remembering to keep the two in step.

### Debug changes should not automatically save

Example:

``` text
Disk save: hunger = 75

Debug panel:
Set hunger → 5

Runtime GameState = 5
Disk save         = 75

Press Reload
→ GameState returns to 75
```

Only **Save Current State** should intentionally persist injected debug
data.

------------------------------------------------------------------------

## 2.5 — Debug Presets / Mock Data

The debug panel should support predefined test scenarios.

Examples:

``` text
Fresh Bunny
Neglected Bunny
Later: Sleepy Bunny
Later: Rich Player
Later: Everything Unlocked
```

For Milestone 2, `Fresh` and `Neglected` are necessary.

Conceptually:

``` text
Fresh Bunny
hunger = cleanliness = happiness = 100

Neglected Bunny
hunger = cleanliness = happiness = 5
```

There is no `Hungry` preset. It existed while hunger was the only stat and stops
meaning anything with three — the ± rows put any one stat anywhere in a couple of
taps. `Neglected` is the three-bars-empty state the popover is most worth looking
at, and the only way to reach it, and the angry face, without waiting a day.

Presets inject known values into the runtime `GameState`.

`Fresh` means *completely full*, which is **not** the same as a new game. A new
Usapyon starts at `BunnyCareRules.STARTING_VALUE` (70), so the first carrot has
somewhere to go — and two taps then demonstrate both cases: +20 to 90, then the
clamp at 100 rather than 110. `Reset Save` is the button that produces that
new-player state; `Fresh` stays at 100.

This makes it easy to reproduce specific situations without waiting for
them naturally.

------------------------------------------------------------------------

## 2.6 — Offline Progression ⏰

Store:

``` text
last_ticked_at
```

It records **when time was last accounted for**, which is a different question
from when the file was last written — and because saves happen only at
meaningful checkpoints, the two drift apart within a single session. Naming it
after the save is how you get a session that either loses three hours or charges
them twice.

When the game loads:

``` text
current time - last_ticked_at
        ↓
elapsed time (a backwards clock clamps to 0)
        ↓
GameState.catch_up_to(now)
        ↓
BunnyCareRules.decayed(value, elapsed)  ← applied to all three stats
        ↓
hunger, cleanliness and happiness decrease
```

**Offline progression is not a special case.** `catch_up_to(now)` is the only
thing that advances the clock, and launch, a 60-second heartbeat, resume from
background, `Reload From Disk` and the debug time buttons all call it. Offline
time is then just the ordinary case with a large gap — double-charging the same
seconds and losing a session's hours are not bugs the code has a shape for.

The game does **not** need to continuously run in the background.

### Important rules

Clamp every stat:

``` text
0 <= hunger, cleanliness, happiness <= 100
```

Offline progression should not become excessively punishing. The exact
decay rate can be tuned through playtesting.

The DebugPanel should provide:

``` text
+1 hour
+6 hours
+24 hours
```

so offline progression can be tested instantly.

------------------------------------------------------------------------

## 2.7 — The Moodlet Popover

The care stats do not live on the main screen. A button in the top-left corner
toggles a small card showing all three. The reference is
[`../design/reference/Moodlet component reference.png`](../design/reference/Moodlet%20component%20reference.png).

``` text
Closed                           Open
┌─────────────────────┐          ┌─────────────────────┐
│ (🐰)                │          │ (🐰)                │
│                     │          │   ╭╮                │
│                     │   tap    │ ╭─╯╰──────────────╮ │
│        (\_/)        │   ───→   │ │🥕 Hunger        │ │
│       ( •ᴗ•)        │          │ │   ▓▓▓▓▓▓▓░░     │ │
│                     │          │ │🧽 Cleanliness   │ │
│                     │          │ │   ▓▓▓▓▓░░░░     │ │
│                     │          │ │♡  Happiness     │ │
│  🥕     🧽     ♡    │          │ │   ▓▓▓▓▓▓░░░     │ │
│ Feed  Clean  Play   │          │ ╰─────────────────╯ │
└─────────────────────┘          └─────────────────────┘
```

### It is a popover, not a modal

Nothing is dimmed and **nothing is blocked**. The Usapyon stays tappable, its
ears stay draggable and the three care tiles stay live while the card is up.
Darkening the room to glance at three bars is the wrong weight of gesture for a
corner readout.

There is therefore no tap-outside-to-close. What replaces it is that the popover
mostly runs itself:

``` text
a care action succeeds
    ↓
GameState.cared
    ↓
popover opens, bar slides
    ↓
2.5s later it closes again   ← only if it opened itself
```

A popover the player opened with the button is on no clock and stays until they
tap the button again. Pressing the button also cancels any countdown left over
from a care action, so the popover never overrules a decision made by hand.

Opening on a care action is the whole point: you tap Feed and the card arrives
in time to show you the bar filling.

### The pieces

-   **`moodlet.tscn`** — one row: an icon, the stat's name, a bar. It holds no
    value and reads nothing from `GameState`; the popover calls `set_value()` on
    it. Its colour is the only thing that differs per stat, and it is a
    per-instance stylebox override built from `Palette` — never a theme lookup,
    for the reason `tile_button.gd` documents.
-   **`moodlet_panel.tscn`** — a `Popover` wrapper holding the card and its tail,
    plus the button. The button belongs *in here* so the whole thing is one
    component and `hud.gd` wires nothing.
-   **`tail.gd`** — the little triangle, drawn rather than textured: a filled
    polygon in `SURFACE` and an antialiased outline on its two slanted edges. It
    is ordered **after** the card and overlaps the card's top border by exactly
    one border width, which is what lets its fill cover that border and turn a
    triangle-on-a-box into one bubble. It lives inside the wrapper so it scales
    with the card during the pop-in.
-   **`tile_button.tscn`** — already built, now instanced three times.

| Stat | Icon | Bar colour | Tile | Amount |
| --- | --- | --- | --- | --- |
| Hunger | `carrot.png` | `ORANGE` | Feed | `CARROT` |
| Cleanliness | `sponge.png` | `BLUE` | Clean | `SPONGE` |
| Happiness | `heart.png` | `RED` | Play | `BALL` |

Each tile presses in its own stat's colour, so the button and the bar it moves
are visibly the same thing.

### The button wears the Usapyon's face

Not the popover's state — the Usapyon's condition, so the corner of the screen
says how things are going without the card being open at all.

| Worst of the three stats | Face |
| --- | --- |
| 30 or above | `bunny_happy.png` |
| below `LOW_VALUE` (30) | `bunny_sad.png` |
| below `CRITICAL_VALUE` (5) | `bunny_angry.png` |

The **worst** stat decides, so a Usapyon that is well fed but filthy does not
look delighted. From full at 4/hour that is roughly 17 hours to the sad face and
24 to the cross one — a day's neglect, not an afternoon's.

The thresholds live in `BunnyCareRules` beside the other pacing numbers, because
they are about when a stat becomes a problem. Which face goes with which is the
popover's business.

### It is small

Everything in it is smaller and thinner than a control the thumb has to hit,
because it is read at a glance rather than pressed. Measured against the
reference and then taken a little further:

| | Reference | Built |
| --- | --- | --- |
| Card | 427 × 309 | **384 × 267** |
| Icon | 69 | **60** |
| Bar height | 24 | **22** |
| Label font | ~28 | **26** |
| Row separation | 23 | **22** |

Every one of those is a named constant in `palette.gd`, and `moodlet.gd` applies
them rather than the scene hard-coding them, so the popover retunes from one
file.

### The bars carry no numbers

Matching the reference. The cost is real and is written down here rather than
discovered later: a bar cannot distinguish 78 from 82, so a refused tap has
nothing on screen explaining itself. The intended answer is the Usapyon refusing
out loud, which is deferred — see §2.8 and "Not Part of Milestone 2". The debug
panel's `%.1f` readouts are the only numbers left in the game.

### The bars slide, after the card has landed

A value change waits `BAR_TWEEN_DELAY` and then tweens over `BAR_TWEEN_TIME`
rather than snapping. The wait matters: a care action pops the card open, and
without it the first third of the fill happens while the card is still scaling
up — the one moment it is meant to be watched.

One guard is load-bearing: `GameState.changed` fires on every 60-second
heartbeat because the raw float always moves, while `care_value()` usually rounds
to the same integer. The tween must no-op when the target already matches, or
three tweens are created every minute for the rest of the session.

### The UI owns nothing

The popover must read from `GameState` and **not maintain its own stat values**.

``` text
GameState changes
    ↓
UI updates
```

It refreshes while closed as well, so opening it never shows a stale bar sliding
into place in front of the player.

------------------------------------------------------------------------

## 2.8 — Three Care Actions 🥕🧽♡

Add exactly one way to restore each stat:

``` text
Carrot  +20 Hunger
Sponge  +20 Cleanliness
Ball    +20 Happiness
```

Do not build the full inventory, shop, food rarity, tool upgrades, minigames or
economy yet. One starter action per stat, as
[`../design/01-game-mechanics.md`](../design/01-game-mechanics.md) describes:
basic care is always available and never gated behind coins.

The interaction is one tile per action:

``` text
[ 🥕 Feed ]  [ 🧽 Clean ]  [ ♡ Play ]
```

Flow, identically for all three:

``` text
Player taps a care tile
        ↓
GameState.try_feed(CARROT) / try_clean(SPONGE) / try_play(BALL)
        ↓
can_restore? ──no──→ nothing happens, return false
        ↓ yes
the stat = BunnyCareRules.restored(the stat, amount)
        ↓
GameState changes → `changed` → bars redraw, face redraws
        ↓
`cared`           → the popover opens and the bar slides
        ↓
`fed`             → the Usapyon hops   ← feeding only, this milestone
        ↓
SaveManager saves
```

The whole action lives in `GameState`, not in the HUD. `fed` is a `GameState`
signal, so nothing outside `GameState` should be emitting it — and the rule then
applies to every future way of feeding, not just this button.

Three separate `try_*` functions rather than one `try_care(stat, amount)`: a
single function would need a stat id, which is the indirection §2.1 rejected for
the properties. The duplication is six lines each and stays visible.

Later, feeding can evolve into physically dragging a carrot onto your Usapyon.

### A care action is refused when it would overcap

Every action is worth +20, so each can only be used at a `care_value` of 80 or
below on its own stat. Above that the tile does nothing.

``` text
care_value(value) + amount <= MAX_VALUE
```

**Do not write `80` down as a constant.** It is `MAX_VALUE - CARROT`, and it is
only correct while every action happens to be worth 20. Derived, the rule gives
every future action the right window on its own — a +40 lettuce unlocks at 60,
+10 pellets at 90 — and the anti-waste guarantee does not quietly break the first
time a second crop is added.

The reason this exists is Care Points, which arrive later: CP is earned by
caring, so without a gate a player could tap a fully-cared-for Usapyon forever
and earn unbounded CP. Refusing wasted care bounds it structurally — the total
restorable in a day is capped by the total that decays.

**This is not the feeding cooldown.** That rule is about *time since eating* and
is still deferred; see "Not Part of Milestone 2". Eventually a feed will have to
pass both.

**A refused tap is silent.** The tile stays enabled and simply does nothing. The
design wants the Usapyon itself to refuse — *"Your Usapyon isn't hungry right
now"* — and that reaction is not Milestone 2 work. Graying the tile out would be
a different decision to undo later, not a step toward it.

Since §2.7's bars carry no numbers, a refused tap currently produces **no signal
at all** — not even a number the player could reason about. That is the sharpest
edge in this milestone and the first thing the deferred refusal reaction should
fix.

------------------------------------------------------------------------

## 2.9 — Feeding Reaction 🐰✨

Feeding should have visible feedback.

The first version can use:

-   a small happy bounce
-   happy/closed eyes
-   hearts or sparkles
-   a small feeding/happy sound effect

A full eating animation is **not required yet**.

The important thing is that changing the stat produces a satisfying
visible reaction.

### Two signals, one meaning each

``` text
try_feed  success → fed + cared
try_clean success →       cared
try_play  success →       cared
any refusal       →  neither
```

`fed` means *the Usapyon should react* and drives the happy hop. `cared` means
*a care action landed* and is what opens the popover. They are kept apart so a
Usapyon cannot hop because it got cleaner, and so the popover does not have to
know which action it was.

`cared` carries no argument: everything listening redraws from `GameState`
anyway, and a stat id here would be the indirection §2.1 exists to avoid.

### Only feeding gets a reaction, this milestone

Cleaning and playing move a bar and pop the popover, and that is all. The
asymmetry is deliberate, not an oversight. When reactions for them are built, the
shape to reach for is one `cared(stat)` signal absorbing `fed`, so a fourth stat
does not mean a fourth signal.

What is still missing entirely is any response to a **refused** action — see
§2.8.

------------------------------------------------------------------------

## 2.10 — Save Behavior

For Milestone 2, save after meaningful actions such as:

``` text
feeding, cleaning, playing
reset/new bunny
important player-driven stat changes
app background/pause
```

Do not write the save file for every tiny decay tick.

A `dirty` state system can be added later if needed.

------------------------------------------------------------------------

## Milestone 2 Test Checklist

Desktop covers the logic, the phone covers everything a finger or the OS
touches — see [`../conventions.md`](../conventions.md#testing).

### New Game

-   [ ] No save exists
-   [ ] Default bunny state is created
-   [ ] GameState contains the correct default for all three stats
-   [ ] Initial save can be created

### Care Actions

Run each of these three times — once for Feed, once for Clean, once for Play.

-   [ ] Player can perform the action
-   [ ] The stat increases by the intended amount
-   [ ] The stat cannot exceed 100
-   [ ] The action is refused above a `care_value` of 80, and the tap does nothing
-   [ ] A refused action does not save and does not move the bar
-   [ ] The bar on screen roughly predicts whether the tile will work
-   [ ] The moodlet bar updates immediately, and slides rather than snapping
-   [ ] Only the acted-on stat moves
-   [ ] The change can be saved

And once:

-   [ ] Your Usapyon visibly reacts to feeding (cleaning and playing do not — §2.9)

### Moodlet Popover

-   [ ] The button is visible top-left, over the room
-   [ ] Tapping it opens the card; tapping it again closes it
-   [ ] Nothing is dimmed
-   [ ] The bunny can still be tapped and its ears dragged while the card is open
-   [ ] The action tiles still work while the card is open
-   [ ] The tail points at the button and reads as one bubble — no seam across
        its base, no dark wedges inside the card
-   [ ] Opening it never shows a bar sliding into place from a stale value
-   [ ] Icons and colours match: carrot/orange, sponge/blue, heart/red

### Auto-open

-   [ ] A successful Feed, Clean or Play opens the card on its own
-   [ ] The bar visibly slides *after* the card has finished popping in
-   [ ] A card that opened itself closes again after ~2.5s
-   [ ] A card the player opened with the button does **not** close itself
-   [ ] Caring while the card is already open restarts nothing the player owns —
        a hand-opened card stays up
-   [ ] Tapping the button cancels a countdown left over from a care action
-   [ ] A **refused** action opens nothing (this is deliberate — §2.8)

### The face

-   [ ] All three stats above 30 → happy face
-   [ ] Any one stat below 30 → sad face
-   [ ] Any one stat below 5 → angry face
-   [ ] The worst stat wins: hunger 100 with cleanliness 4 is still angry
-   [ ] The face updates while the card is closed

### Persistence

-   [ ] Close the app
-   [ ] Reopen the app
-   [ ] All three saved stats are restored
-   [ ] A version-1 save (hunger only) opens, with the other two at 70 less decay
-   [ ] State remains correct on Android

### Offline Progression

-   [ ] `last_ticked_at` is stored
-   [ ] Elapsed time is calculated correctly
-   [ ] All three stats decrease according to elapsed time
-   [ ] No stat goes below 0
-   [ ] Debug +1h works
-   [ ] Debug +6h works
-   [ ] Debug +24h works

### Debug Tools

-   [ ] DebugPanel only appears in debug builds
-   [ ] Hunger +/- controls work
-   [ ] Cleanliness +/- controls work
-   [ ] Happiness +/- controls work
-   [ ] Fresh preset sets all three to 100
-   [ ] Neglected preset sets all three to 5, and the face turns angry
-   [ ] Debug changes do not automatically overwrite disk state
-   [ ] Save Current State works
-   [ ] Reload From Disk works
-   [ ] Reset Save works

### Android

-   [ ] All three care actions work on the real phone
-   [ ] Three tiles fit the action row without crowding
-   [ ] The panel opens and closes cleanly, and the pop-in reads as growing from
        the button
-   [ ] UI displays correctly
-   [ ] State persists between launches
-   [ ] Backgrounding/reopening behaves correctly
-   [ ] Offline progression behaves correctly

------------------------------------------------------------------------

## 🏁 Definition of Done

Milestone 2 is complete when this works on the actual phone:

> Open the app after being away → tap the button and see all three stats reflect
> elapsed time → feed it a carrot → it happily reacts → clean and play with it →
> every bar improves → close the app → reopen it → the correct state is still
> there.

At that point, the game has evolved from an **interactive character
demo** into the foundation of an actual **persistent virtual-pet game**.
🐰🥕💾

------------------------------------------------------------------------

## Not Part of Milestone 2

Avoid scope creep. All of these are real parts of the design — see
[`../design/01-game-mechanics.md`](../design/01-game-mechanics.md) — just not
yet:

-   **Reactions for cleaning and playing**, and the Usapyon refusing an action
    out loud. Both are named in §2.9 and §2.8 as the known gaps this milestone
    ships with.
-   **The feeding cooldown.** The design says a fed Usapyon stays full for a
    couple of hours *after eating*. That is a rule about elapsed time and it
    lands with the real feeding UI. Do not confuse it with §2.8's overcap
    refusal, which is a rule about wasted food and is built: both will
    eventually apply, and a feed will have to pass each. Note that the overcap
    rule already acts as a de-facto cooldown of about five hours from full — at
    4 hunger/hour it takes that long to fall from 100 back to 80 — so the two
    will compound rather than overlap.
-   **Care Points and Care Stars.** The whole progression layer waits, even
    though the three stats it earns from now exist.
-   Automatic day/night sleep
-   Debuffs / sickness
-   Garden, Coins, shop, cosmetics, minigames
-   Full inventory, multiple food types, tool upgrades
-   Advanced eating, washing or playing animations
-   A dim, a modal, or tap-outside-to-close — §2.7 deliberately has none
-   Numbers on the stat bars

There is no Energy stat and no Affection meter anywhere in the design. Do not
add them.

The purpose of Milestone 2 is to prove **the complete care loop**:

``` text
Stat → Care Action → Save → Time Passes → Stat
```

Hunger proves it with a reaction attached; cleanliness and happiness prove the
same architecture carries more than one stat without a new concept per stat.
