# Milestone 2 — A Usapyon That Needs You 🥕

**Status: next.** Builds on [`01-interactive-bunny.md`](01-interactive-bunny.md).

Systems design — what the stats are and where progression goes — lives in
[`../design/01-game-mechanics.md`](../design/01-game-mechanics.md). This file
owns only what gets built in this milestone, and how.

## Goal

Move the Usapyon from a **cute interactive character** to a **persistent
virtual pet with needs and care**.

Milestone 2 is complete when this loop works end-to-end:

> Open app → see current hunger → feed your Usapyon → hunger changes → it
> reacts → save → close app → reopen later → state is restored and
> time-away effects are applied.

------------------------------------------------------------------------

## Core Architecture

| System | Responsibility |
| --- | --- |
| **GameState** | Single source of truth during the current game session |
| **SaveManager** | Loads and saves player data locally |
| **BunnyStats** | Contains gameplay rules for hunger, feeding, and time decay |
| **Bunny / `bunny.gd`** | Presentation, animations, reactions, and interactions |
| **DebugPanel** | Developer-only controls for manipulating/testing state |
| **UI** | Displays hunger and provides feeding controls |

### Data flow

``` text
save file
    ↓
SaveManager
    ↓
GameState  ←── single source of truth
    ↓
BunnyStats / Actions modify state
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
└── bunny
    ├── hunger
    └── last_saved_at
```

Later this expands with the rest of the design — cleanliness, happiness, care
points, care stars, coins, inventory, customization — but none of that is
required for Milestone 2.

### Rules

-   `GameState` is the source of truth while the game is running.
-   UI and Bunny read from `GameState`.
-   Gameplay actions and game systems manipulate `GameState`.
-   Do not keep duplicate authoritative hunger values elsewhere.

------------------------------------------------------------------------

## 2.2 — SaveManager

Create a global/autoload `SaveManager`.

Responsibilities:

``` text
load save file
write save file
create default/new-player state
reset save
```

Saves go to `user://`, and debug builds write a separate file from release
builds — see [`../conventions.md`](../conventions.md#save-file-separation) for
the paths and why they are split.

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

## 2.3 — BunnyStats / Gameplay Rules

`BunnyStats` contains the rules for changing the care stats.

### Hunger reads as fullness

**100 = completely full, 0 = starving.** Feeding raises the number; time lowers
it. Every stat in the game follows this direction — a full bar is always good
news — so a stat bar can be drawn the same way for all of them without anyone
having to remember which one is inverted.

For Milestone 2 it only needs concepts such as:

``` text
feed(amount)
apply_elapsed_time(seconds)
clamp_hunger()
```

Example:

``` text
Carrot
→ +20 hunger
```

Time progression:

``` text
Time passes
→ hunger slowly decreases
```

Keep these rules separate from `bunny.gd`.

### Responsibility split

``` text
GameState   = what your Usapyon's current values ARE
BunnyStats  = rules for HOW those values change
Bunny       = how your Usapyon visually reacts
SaveManager = how those values persist
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
│ Hunger: 72             │
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
│ [Fresh] [Hungry]       │
└────────────────────────┘
```

### Debug behavior

Direct stat manipulation can change `GameState` directly:

``` text
Set Hunger = 5
    ↓
GameState.hunger = 5
    ↓
Bunny/UI immediately react
```

Time simulation should call the **real gameplay logic**:

``` text
Debug: +6 hours
    ↓
BunnyStats.apply_elapsed_time(6 hours)
    ↓
GameState changes
```

This ensures the debug panel tests the same logic real players use.

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
Hungry Bunny
Later: Sleepy Bunny
Later: Rich Player
Later: Everything Unlocked
```

For Milestone 2, only `Fresh` and `Hungry` are necessary.

Conceptually:

``` text
Fresh Bunny
hunger = 100

Hungry Bunny
hunger = 5
```

Presets inject known values into the runtime `GameState`.

This makes it easy to reproduce specific situations without waiting for
them naturally.

------------------------------------------------------------------------

## 2.6 — Offline Progression ⏰

Store:

``` text
last_saved_at
```

When the game loads:

``` text
current time - last_saved_at
        ↓
elapsed time
        ↓
BunnyStats.apply_elapsed_time()
        ↓
GameState.hunger decreases
```

The game does **not** need to continuously run in the background.

### Important rules

Clamp hunger:

``` text
0 <= hunger <= 100
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

## 2.7 — Hunger UI

Add a simple temporary hunger display.

It does not need final artwork yet.

Examples:

``` text
🥕 Hunger
████████░░ 80%
```

or simply:

``` text
Hunger: 80
```

The UI must read from `GameState`.

It should **not maintain its own separate hunger value**.

``` text
GameState changes
    ↓
UI updates
```

------------------------------------------------------------------------

## 2.8 — First Food: Carrot 🥕

Add exactly one food item for this milestone:

``` text
Carrot
+20 Hunger
```

Do not build the full inventory, shop, food rarity, or economy yet.

The first interaction can be simple:

``` text
[ FEED CARROT ]
```

Flow:

``` text
Player feeds carrot
        ↓
BunnyStats.feed(20)
        ↓
GameState.hunger changes
        ↓
UI updates
        ↓
Bunny reacts
        ↓
SaveManager saves
```

Later this can evolve into physically dragging a carrot onto your Usapyon.

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

------------------------------------------------------------------------

## 2.10 — Save Behavior

For Milestone 2, save after meaningful actions such as:

``` text
feeding
reset/new bunny
important player-driven stat changes
app background/pause
```

Do not write the save file for every tiny hunger change.

A `dirty` state system can be added later if needed.

------------------------------------------------------------------------

## Milestone 2 Test Checklist

Desktop covers the logic, the phone covers everything a finger or the OS
touches — see [`../conventions.md`](../conventions.md#testing).

### New Game

-   [ ] No save exists
-   [ ] Default bunny state is created
-   [ ] GameState contains the correct default hunger
-   [ ] Initial save can be created

### Feeding

-   [ ] Player can feed one carrot
-   [ ] Hunger increases by the intended amount
-   [ ] Hunger cannot exceed 100
-   [ ] Hunger UI updates immediately
-   [ ] Your Usapyon visibly reacts
-   [ ] Feeding change can be saved

### Persistence

-   [ ] Close the app
-   [ ] Reopen the app
-   [ ] Saved hunger is restored
-   [ ] State remains correct on Android

### Offline Progression

-   [ ] `last_saved_at` is stored
-   [ ] Elapsed time is calculated correctly
-   [ ] Hunger decreases according to elapsed time
-   [ ] Hunger never goes below 0
-   [ ] Debug +1h works
-   [ ] Debug +6h works
-   [ ] Debug +24h works

### Debug Tools

-   [ ] DebugPanel only appears in debug builds
-   [ ] Hunger +/- controls work
-   [ ] Fresh Bunny preset works
-   [ ] Hungry Bunny preset works
-   [ ] Debug changes do not automatically overwrite disk state
-   [ ] Save Current State works
-   [ ] Reload From Disk works
-   [ ] Reset Save works

### Android

-   [ ] Feeding works on the real phone
-   [ ] UI displays correctly
-   [ ] State persists between launches
-   [ ] Backgrounding/reopening behaves correctly
-   [ ] Offline progression behaves correctly

------------------------------------------------------------------------

## 🏁 Definition of Done

Milestone 2 is complete when this works on the actual phone:

> Open the app after being away → your Usapyon's hunger reflects elapsed time
> → feed it a carrot → it happily reacts → hunger improves →
> close the app → reopen it → the correct state is still there.

At that point, the game has evolved from an **interactive character
demo** into the foundation of an actual **persistent virtual-pet game**.
🐰🥕💾

------------------------------------------------------------------------

## Not Part of Milestone 2

Avoid scope creep. All of these are real parts of the design — see
[`../design/01-game-mechanics.md`](../design/01-game-mechanics.md) — just not
yet:

-   **Cleanliness and Happiness.** Both are core care stats and both are coming.
    Hunger alone is enough to prove the architecture, and the other two then
    slot into the same pattern.
-   **The feeding cooldown.** The design says a fed Usapyon stays full for a
    couple of hours. Milestone 2 deliberately allows repeat feeding so the loop
    stays easy to test; the cooldown lands with the real feeding UI.
-   **Care Points and Care Stars.** The whole progression layer waits until
    there are three stats to earn CP from.
-   Automatic day/night sleep
-   Debuffs / sickness
-   Garden, Coins, shop, cosmetics, minigames
-   Full inventory and multiple food types
-   Advanced eating animations
-   Production-quality stat UI

There is no Energy stat and no Affection meter anywhere in the design. Do not
add them.

The purpose of Milestone 2 is to prove **one complete care loop** first:

``` text
Hunger → Feed → Reaction → Save → Time Passes → Hunger
```

Once that works cleanly, the same architecture can support the rest of
the care stats.
