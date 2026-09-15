# Plan: A Usapyon that needs you

## Goal

Milestone 2 in full: turn the interactive character from Milestone 1 into a pet with
one real care loop.

> Open the app after being away → hunger reflects the time that passed → feed a carrot
> → it reacts → hunger improves → close the app → reopen → the state is still right.

Verified on the actual phone, not on desktop. Hunger is the only stat. It exists to
prove the architecture that cleanliness and happiness will later slot into unchanged.

## Non-goals

Everything in the milestone's own "Not Part of Milestone 2" list — cleanliness,
happiness, the feeding cooldown, Care Points and Care Stars, day/night sleep, sickness,
garden, coins, shop, cosmetics, minigames, multiple foods, full inventory, advanced
eating animations, production-quality stat UI. There is no Energy stat and no Affection
meter in the design; do not add them.

The **feeding cooldown remains a non-goal** — the design's ~2-hour "isn't hungry right
now" timer still waits for the real feeding UI. What *was* added, late and deliberately,
is a different rule that happens to look similar: feeding is refused when the food would
push hunger past 100. That is an anti-waste guard against unbounded Care Points, not a
timer, and both rules will eventually apply. See `decisions.md` 21.

Four further boundaries were drawn during planning, inside what the milestone allows:

- **The Usapyon does not look hungry.** It idles identically at hunger 100 and hunger 4;
  only the bar differs. `assets/sprites/bunny/` contains exactly one face
  (`face_neutral`), so any hungry expression needs art that does not exist.
  See `decisions.md` 5.
- **No sound effect and no sparkles on feeding.** The reaction is a bounce and happy
  eyes, built from what is already in the rig. `assets/audio/` holds one file, the music
  track, and there is no SFX bus. See `decisions.md` 15.
- **No anti-cheat on the device clock.** Moving the phone's clock forward genuinely skips
  time. Single-player game, nobody to cheat. See `decisions.md` 3.
- **A refused feed says nothing.** The button stays enabled and a tap on a full Usapyon
  simply does nothing. The design wants the Usapyon itself to refuse — "*Your Usapyon
  isn't hungry right now*" — and that animation is not Milestone 2 work. Greying the
  button out would be a different decision to undo later, not a step toward it.
  See `decisions.md` 26.

## Context

Read `CLAUDE.md` and `docs/conventions.md` first. The GL Compatibility renderer, the
1080×1920 portrait target, the `uid://` handling rules, the ask-first list, the headless
validation commands, the debug/release save split and the testing split between desktop
and phone all apply and are not repeated here.

What exists today that this touches:

- **`scenes/main.tscn` is a `Control`** holding a `ColorRect` background and one `Bunny`
  instance at `(540, 1050)`. There is no `CanvasLayer` and no UI of any kind. This
  milestone adds the first UI layer.
- **The `idle` animation writes `Visual:position` and `Visual:scale` every frame, on
  loop, forever.** Any tween targeting those properties is silently overwritten — the
  `AnimationPlayer` wins. This is the single most important existing fact for the
  feeding reaction; see `decisions.md` 14.
- **`ear.gd` already solved that problem once.** Its header comment: *"the ear Sprite2D
  keeps the idle animation's own small rotation, so the drag and the idle wobble never
  write the same property."* The `EarPull` node carries the drag, the ear `Sprite2D`
  child carries the idle. The bounce uses the same trick, not a new one.
- **`eye.gd` has `is_busy()`**, which already stops a blink from opening an eye that is
  held shut — it covers both a finger and the post-release timer. The happy eyes reuse
  it rather than adding a state. See `decisions.md` 16.
- **`ear.gd` and `eye.gd` catch their press on an `Area2D` but their release in
  `_unhandled_input`**, so a finger that wanders off the node still works. A `Control`
  that consumes a release before it reaches `_unhandled_input` would strand a gesture.
  This is the main risk in the milestone; see Risks and `decisions.md` 13.
- **`autoloads/music.gd`** is the only autoload and the only existing example of the
  pattern. It is also the source of a known 4-object leak in the headless baseline — see
  Risks.
- **`project.godot` has one `[autoload]` entry.** Autoload order is instantiation order,
  which matters here: `GameState` must be listed before `SaveManager`, because
  `SaveManager._ready()` writes into `GameState`.

## Approach

Three autoloads and one pure-static rules module, mapped directly onto the milestone's
own responsibility split so that the split is structural rather than a convention anyone
has to remember:

```text
autoloads/game_state.gd        WHAT the values are   (+ owns the clock)
systems/bunny_care_rules.gd    HOW they change       (pure statics)
autoloads/save_manager.gd      HOW they persist
scenes/bunny.gd                HOW it reacts
```

The load-bearing idea is that **offline progression is not a special case.** One
function advances the clock, and every caller uses it:

```gdscript
func catch_up_to(now: int) -> void:
	var elapsed: int = maxi(0, now - last_ticked_at)   # backwards clock → 0
	hunger = BunnyCareRules.decayed(hunger, elapsed)   # setter clamps and emits
	last_ticked_at = now
```

Called at launch, on a 60-second heartbeat while the app is open, on resume from
background, by `Reload From Disk`, and by the debug time buttons — which rewind
`last_ticked_at` and then call it, so the debug panel exercises the player's code path
rather than a parallel one. There is no second way for time to pass, so double-charging
and lost hours are not bugs that can be written; they are shapes the code does not have.

The stored timestamp is therefore **`last_ticked_at`, not the milestone's
`last_saved_at`** — it records the last moment time was *accounted for*, which is a
different question from when the file was last *written*. Conflating the two is how you
get a session that either double-charges three hours or loses them. See `decisions.md` 2.

One consequence worth stating because it shapes the save rules: since `last_ticked_at`
is refreshed every 60 seconds, an Android kill that never delivers a lifecycle
notification loses the *feed* but not the *time* — the unsaved gap simply becomes
offline decay on the next launch, which is correct by construction. Under-saving is
self-healing for the clock and lossy only for actions. That is why saves hang off
actions and not off a timer.

`hunger` is a property with a backing var, so clamping to 0–100 and emitting `changed`
happen on every write including `GameState.hunger = 5` from the debug panel. The
invariant cannot be skipped by a caller who does not know about it.

The second load-bearing idea arrived later: **the float is a decay accumulator, not the
number the game reasons about.** Every gameplay rule and every player-facing readout goes
through `BunnyCareRules.care_value(hunger) -> int`; only `decayed()` sees the fraction.
That single choice settles two things at once. The bar, the label and the feed button all
derive from one integer, so the screen can never contradict the button — which matters
because a refused tap is silent, and "Hunger 80" that does nothing while "Hunger 80" that
works are otherwise indistinguishable. And because the gate *and* the addition both run on
the rounded value, a feed lands on an exact integer ≤ 100 every time: "never overcap" is
provable rather than approximate, and the setter's clamp becomes unreachable from feeding.
See `decisions.md` 23.

## Components

- **`autoloads/game_state.gd`** (new) — `hunger: float` as a property over `_hunger`,
  clamping and emitting `changed` only when the value actually moves (otherwise the
  heartbeat would announce nothing 60 times an hour once hunger sits at 0).
  `last_ticked_at: int`. Owns the 60-second `Timer`, `catch_up_to()`, and
  `_notification()` for `NOTIFICATION_APPLICATION_PAUSED` (save) and
  `NOTIFICATION_APPLICATION_RESUMED` (catch up). Signals: `changed` for anything that
  redraws, `fed` for the one moment that deserves a reaction. Also `reset_to_new()`, and
  `try_feed(amount) -> bool` — the whole feed action, so the rule, the write, the signal
  and the save are one call any interaction can make (`decisions.md` 25).

- **`systems/bunny_care_rules.gd`** (new) — `class_name BunnyCareRules`, static functions
  only, never names `GameState`. `STARTING_HUNGER = 70.0`, `DECAY_PER_HOUR = 4.0`,
  `CARROT = 20.0`, and `MIN_HUNGER` / `MAX_HUNGER`, which live here rather than in
  `GameState` so that `can_eat` can stay pure (`decisions.md` 24).
  `care_value(hunger) -> int` is the rounded value gameplay and the UI both run on;
  `can_eat(hunger, amount) -> bool` refuses a feed that would overcap — derived from the
  food, so there is no `80` anywhere and a future lettuce gets the right window for free;
  `fed(hunger, amount) -> float` and `decayed(hunger, seconds) -> float`. Testable with a
  `print()` and no scene tree, which is exactly the headless verification `CLAUDE.md` asks
  for. This is the file you open to change how the game feels.

- **`autoloads/save_manager.gd`** (new) — writes `savegame.tmp` then renames over the
  real file; the previous file is kept as `.bak` first. Load tries the main file, falls
  back to `.bak`, and only then calls `GameState.reset_to_new()`. Schema
  `{"version": 1, "hunger": 72.0, "last_ticked_at": 1757894400}`; missing keys read as
  defaults so a Milestone 2 save opens in Milestone 3. Paths per `docs/conventions.md`.

- **`project.godot`** — `GameState` and `SaveManager` added to `[autoload]`, in that
  order, after `Music`.

- **`scenes/bunny.tscn`** — a new `Bounce` `Node2D` inserted between `Bunny` and
  `Visual`. Nothing else in the rig moves. The `idle` animation's four tracks address
  `Visual:position`, `Visual:scale` and the two ear rotations by `NodePath` relative to
  the `AnimationPlayer`'s root, which is still `Bunny` — so those paths gain a `Bounce/`
  segment. **Check and update all four**, in both `idle` and `RESET`; getting this wrong
  produces no error, just an idle animation that silently stops working.

- **`scenes/bunny.gd`** — connects to `GameState.fed`; `celebrate()` tweens
  `Bounce:scale` and `Bounce:position` and holds both eyes shut for the duration.

- **`scenes/eye.gd`** — gains `hold_shut(seconds)`: `close()` plus starting the existing
  `_release_timer`. No new state; `is_busy()` already covers that timer, so blinking
  leaves the eyes alone for exactly as long as the bounce lasts.

- **`scenes/hud.tscn`** (new) — a `CanvasLayer` over `main.tscn`. `ProgressBar` plus a
  value `Label` anchored top-centre at roughly y=120, clear of the Usapyon (centre
  y=1050, ears reaching to about y=730). A `FEED CARROT` button in the bottom thumb
  zone. Every non-interactive node set to `mouse_filter = IGNORE` so the touch surface
  is as small as possible. Bar and label both read `care_value()`, so neither can
  contradict the button; the float stays internal and is never written back. The button
  is never disabled — when the Usapyon is too full, the tap is simply a no-op.

- **`scenes/debug_panel.tscn`** (new) — instanced into `main.tscn` only when
  `OS.is_debug_build()`, hidden by default, toggled by a small 🛠 button top-right.
  Hunger ±10, `+1h` / `+6h` / `+24h`, Save Current State, Reload From Disk, Reset Save,
  and the `Fresh` / `Hungry` presets. Debug edits never write the file; only
  Save Current State does.

The feed action is the milestone's own flow diagram read top to bottom, with the overcap
gate in front of it — and it lives in `GameState`, not in the HUD, because `fed` is a
`GameState` signal and nothing outside `GameState` should be firing it:

```gdscript
# game_state.gd
func try_feed(amount: float) -> bool:
	if not BunnyCareRules.can_eat(hunger, amount):
		return false
	hunger = BunnyCareRules.fed(hunger, amount)
	fed.emit()
	SaveManager.save()
	return true
```

which leaves `hud.gd` with a one-line handler:

```gdscript
func _on_feed_pressed() -> void:
	GameState.try_feed(BunnyCareRules.CARROT)
```

## Reconciling the milestone doc

`CLAUDE.md` makes milestones the only build authority, and
`docs/milestones/02-persistent-pet.md` currently disagrees with this plan in seven
places. **Reconcile the milestone doc before writing code**, so a later session reading
the authority does not meet names this plan has replaced:

| Where | Doc says | Should say |
| --- | --- | --- |
| §2.1, §2.6, and the Offline Progression checklist | `last_saved_at` (3 places) | `last_ticked_at` (`decisions.md` 2) |
| Architecture table, the data-flow block, §2.3, §2.4, §2.6, §2.8 | `BunnyStats` (7 places) | `BunnyCareRules` (`decisions.md` 8) |
| §2.3 | `feed(amount)`, `apply_elapsed_time(seconds)`, `clamp_hunger()` | pure `fed(h, amt)` / `decayed(h, secs)` returning floats, clamped inside the GameState setter (`decisions.md` 9, 10) |
| §2.4 | `Debug: +6 hours → BunnyStats.apply_elapsed_time(6 hours)` | rewind `last_ticked_at`, then `catch_up_to(now)` (`decisions.md` 1) |
| §2.5 | `Fresh Bunny → hunger = 100` only | `Fresh` stays 100, and a *new game* starts at 70 — they are different states (`decisions.md` 17) |
| §2.2 | SaveManager creates default state | `GameState.reset_to_new()` reads `BunnyCareRules.STARTING_HUNGER` (`decisions.md` 20) |
| §2.2 | plain JSON | `version` field, atomic write, rolling `.bak` (`decisions.md` 11) |
| §2.3, §2.8 | feeding always succeeds | feeding is refused when it would overcap; `can_eat` and `care_value` join the rules module (`decisions.md` 21, 22, 23) |
| "Not Part of Milestone 2" | "deliberately allows repeat feeding" | the *cooldown* is still deferred; the overcap guard is not the cooldown (`decisions.md` 21) |

## Risks

- **A `Control` may eat the ear/eye release.** Both gestures catch release in
  `_unhandled_input`, which runs *after* the GUI pass. If a `Button` consumes a release
  over its own rect, the ear stays stretched until `FOCUS_OUT` rescues it. Deliberately
  left as a device test rather than pre-emptively refactoring working M1 code
  (`decisions.md` 13). **Test:** pull an ear, drag the finger over the FEED button, lift.
  Springs back → nothing to do. Stays stretched → move `ear.gd` and `eye.gd` from
  `_unhandled_input` to `_input`. Repeat for the 🛠 corner. Claude cannot see this; it
  needs the phone.

- **Atomic rename on Android `user://` is assumed, not verified.** The whole
  corrupt-file strategy rests on rename-over being atomic. It should be — `user://` is
  ordinary app-private internal storage — but confirm a `DirAccess` rename over an
  existing file actually succeeds on the device rather than failing silently and leaving
  the `.tmp` behind.

- **4 hunger/hour is a guess.** 100 → 0 in 25 hours means a full Usapyon left overnight
  and all day is nearly empty when you get home, which is the intent: once a day is the
  bare minimum and it should feel close. Whether that reads as *tense* or as *punishing*
  cannot be judged from a debug button — it needs real days on the phone. One constant
  in one file.

- **The headless baseline is already noisy.** Every run ends with
  `4 ObjectDB instances were leaked at exit` and `2 resources still in use at exit`,
  caused by the existing `Music` autoload's stream and investigated in
  `docs/plans/background-music/progress.md`. **Do not read those two lines as a
  regression from this work.** If the count rises above 4, that is new.

- **Hunger is a float and JSON round-trips it.** 72.4 saves and loads as 72.4. Since
  `decisions.md` 23, feeding *deliberately* writes a rounded value back — 72.4 + a carrot
  is 92.0, not 92.4 — so the thing to confirm is narrower than it was: no *display* path
  may write, and decay must keep running on the float. The debug panel's `%.1f` readout is
  the instrument for both; if it ever shows a whole number after a `+1h`, something has
  rounded that should not have.

## Open questions

- **Code says `Bunny`, player-facing strings say "your Usapyon".** Raised twice during
  planning and never ruled on. It is currently consistent by accident rather than by
  decision, and `docs/conventions.md` — which has no naming section — is where the rule
  belongs.
- **Which corner tap, and how big.** 🛠 top-right is decided; its exact size and whether
  it needs a margin from the hunger bar is a layout call best made with it on screen.
- **Whether `Fresh` / `Hungry` are enough presets.** The milestone asks for two. A third
  `Full = 100` was considered and declined; if `Fresh` at 100 turns out to be what you
  reach for while `Reset Save` covers the new-player case, they may want renaming.
