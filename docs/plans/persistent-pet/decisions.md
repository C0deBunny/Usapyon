# Decisions: A Usapyon that needs you

All settled on 2026-09-15 in one `/grill-me` session, in the order below. Each one
depends on the ones above it.

## 1. One always-catching-up clock, with no separate offline path

- **Date:** 2026-09-15
- **Considered:** decay only at launch, frozen while the app is open · a single
  `catch_up_to(now)` called from launch, a heartbeat, and resume · authoritative decay at
  launch plus a cosmetic bar that drifts during play
- **Chosen:** one `catch_up_to(now)` everywhere. Offline progression stops being a
  feature with its own code and becomes the ordinary case with a large gap. Because
  nothing else advances time, double-charging the same seconds and losing a session's
  hours are not bugs that can be introduced — the code has no shape that expresses them.
  The cosmetic option was rejected outright: two numbers for one value is precisely the
  duplicate authoritative state §2.1 forbids, and it leaves open which one the save file
  gets.
- **Consequence:** the debug time buttons get their correctness for free. `+6 hours`
  rewinds `last_ticked_at` by 21600 and calls `catch_up_to(now)` — the exact call a cold
  launch makes — so §2.4's "debug time simulation should call the real gameplay logic"
  holds structurally rather than by anyone remembering it.
- **Trade-off:** a 60-second `Timer` runs for the whole session. At 4/hour a tick moves
  hunger by 0.067, so nothing visible is gained during a short session; the timer earns
  its place by making the launch path and the running path the same code.

## 2. `last_saved_at` becomes `last_ticked_at`

- **Date:** 2026-09-15
- **Considered:** keep the milestone's `last_saved_at` · rename to `last_ticked_at`
- **Chosen:** rename. The field answers "when was time last accounted for", which is a
  different question from "when was the file last written" — and since saves happen only
  at meaningful checkpoints, the two drift apart within a single session. A player who
  feeds at 09:00 and closes at 12:00 either loses three hours or is charged them twice,
  depending on which meaning the reader assumed. The name was doing the misleading.
- **Trade-off:** departs from the milestone doc's wording, which is why the doc needs the
  reconciliation table in `plan.md`.

## 3. Trust the device clock, clamp backwards to zero

- **Date:** 2026-09-15
- **Considered:** trust it completely · clamp negative elapsed to zero · clamp both ends
  with a maximum offline window
- **Chosen:** clamp backwards only. Without the clamp, a clock moved back produces
  negative elapsed and hunger goes *up* — a free meal from changing the date, and a
  genuinely baffling bug the first time a phone crosses a timezone or hits DST. Forward
  skipping is left alone: this is a single-player game with no leaderboard, and a player
  who wants to fast-forward their own pet is not taking anything from anyone. A forward
  cap was declined because hunger already floors at 0 after 25 hours, so it would be a
  no-op today and speculative tomorrow.
- **Trade-off:** setting the clock forward genuinely skips time. Accepted as not worth
  defending against.

## 4. Hunger decays at 4 per hour

- **Date:** 2026-09-15
- **Considered:** 5/hour (full to empty in 20 hours) · 4/hour (25 hours)
- **Chosen:** 4/hour, so a full Usapyon is not quite empty after 24 hours and checking in
  once a day is a viable bare minimum rather than a guaranteed failure.
- **Trade-off:** it lands at 4, not 0 — technically alive, effectively starving. Whether
  that reads as tense or as punishing cannot be decided from a debug button; it needs
  real days on the phone. One constant in `BunnyCareRules`.

## 5. The Usapyon does not look hungry in Milestone 2

- **Date:** 2026-09-15
- **Considered:** bar only · a hungry face and droopier ears · no new art, but a slower
  idle and longer blinks to read as lethargy
- **Chosen:** bar only. `assets/sprites/bunny/` has exactly one face, `face_neutral`, so
  the expression option is blocked on art that does not exist. The lethargy option needs
  no art and was tempting, but §2.9 asks only for a reaction to *feeding*, and every
  threshold it would introduce ("at what hunger does it slow down?") is a tuning question
  that belongs after the loop works.
- **Trade-off:** at hunger 4 the Usapyon looks exactly as happy as at 100. The game says
  it is starving only in the bar.

## 6. GameState owns the heartbeat

- **Date:** 2026-09-15
- **Considered:** GameState holds the `Timer` and the lifecycle hooks · a third `Clock`
  autoload owning "when" · a `Timer` node in `main.tscn`
- **Chosen:** GameState. It is already an autoload node, so it can hold a `Timer` and
  `_notification()` without anything new being registered. The `Clock` autoload was
  cleaner on paper — three files, one sentence each — but `CLAUDE.md` says ask before
  adding autoloads and says no managers until there is real pain, and a third singleton
  to own a 60-second timer is the shape of premature structure. The `main.tscn` option
  fails outright: time would only pass while that scene is in the tree, and the launch
  catch-up has to live elsewhere anyway, splitting the logic.
- **Trade-off:** GameState is no longer a pure data bag — it has a timer and lifecycle
  behaviour. The boundary that keeps it honest: GameState owns *what the values are* and
  *when they advance*, but never *by how much*. Every rule stays in `BunnyCareRules`.

## 7. One `changed` signal, plus a separate `fed`

- **Date:** 2026-09-15
- **Considered:** one signal per stat carrying its value · a single `changed` · `changed`
  plus a distinct `fed`
- **Chosen:** initially `changed` alone, for scaling — three stats should not mean three
  signals. That immediately collided with §2.9: `changed` also fires on the heartbeat, on
  launch decay and on every debug `+10`, so a Usapyon listening to it would bounce
  happily when it got *hungrier*. Resolved by adding `fed` for the one moment that
  deserves a reaction. Two other routes were considered and rejected — having the feed
  handler call `bunny.celebrate()` directly (couples the UI to the Bunny node), and
  having the Bunny diff hunger against a remembered value (a second copy of the
  authoritative number, and the debug panel would still trigger it).
- **Trade-off:** a precedent that reaction-worthy moments get their own signal. Watch for
  it — `cleaned`, `played_with`, `slept` would be the point at which this needs
  rethinking rather than extending.

## 8. `BunnyStats` becomes `BunnyCareRules`

- **Date:** 2026-09-15
- **Considered:** `BunnyStats` (the milestone's name) · `CareRules` · `BunnyCareRules`
- **Chosen:** `BunnyCareRules`. "Stats" names the nouns the module *touches*; "rules"
  names what it *is*, and rules are all it will ever contain. The `Bunny` prefix is kept
  over the shorter `CareRules` for consistency with `bunny.gd`, `bunny.tscn` and the
  `Bunny` node, even though there is only one creature.
- **Trade-off:** another departure from the milestone doc's wording.

## 9. The rules are pure functions; GameState assigns the result

- **Date:** 2026-09-15
- **Considered:** rules mutate GameState directly, as the milestone's pseudocode implies ·
  rules take and return floats and never name GameState · fold the rules into GameState
  entirely
- **Chosen:** pure functions. Once GameState owned the heartbeat (decision 6), the
  mutating shape made GameState call the rules and the rules write back into GameState —
  a cycle in which neither can be exercised without the other. Pure functions cut it:
  `BunnyCareRules` can be verified with a single `print()` and no autoload, no scene and
  no tree, which is exactly the headless verification `CLAUDE.md` demands before claiming
  something works. Folding the rules into GameState was rejected because §2.3's
  "what the values ARE" versus "HOW they change" split would survive only as a comment
  header.
- **Trade-off:** call sites are longer —
  `GameState.hunger = BunnyCareRules.fed(GameState.hunger, amount)` rather than
  `BunnyCareRules.feed(amount)` — and a caller can forget to assign the result. The
  property setter (decision 10) limits the damage.

## 10. `hunger` is a property with a backing var

- **Date:** 2026-09-15
- **Considered:** a plain public `var`, callers clamp and emit · a plain var plus a
  `set_hunger()` method everyone is expected to call · a property whose setter clamps and
  emits, over a `_hunger` backing var
- **Chosen:** the property. §2.4 has the debug panel doing `GameState.hunger = 5`
  directly, and GDScript has no private variables, so any convention-based approach
  leaves that write skipping both the clamp and the signal — a silently stale bar and an
  out-of-range value, with no error anywhere. A property makes the invariant hold for
  writers who have never heard of it. The backing var is deliberate rather than relying
  on Godot's recursion behaviour inside a self-assigning setter.
- **Trade-off:** assignment now has invisible side effects, which is a real cost when the
  engine is new. Mitigated by it being one property in one file, commented as such.
- **Also decided here:** the setter emits `changed` only when the value actually moves.
  Otherwise, once hunger reaches 0 the heartbeat would announce nothing 60 times an hour.

## 11. Atomic write, rolling `.bak`, and a `version` field

- **Date:** 2026-09-15
- **Considered:** no version, defaults on read · version plus an explicit corrupt-file
  policy · version, atomic write, and a one-deep backup
- **Chosen:** all three. Writes go to `savegame.tmp` and rename over the real file, so an
  Android kill mid-write leaves either the old file or the new one and never half of one.
  The previous file is kept as `.bak` first, and a load that cannot parse the main file
  falls back to it. `version: 1` is one line today and removes all guesswork the first
  time a field changes meaning rather than merely being added.
- **Trade-off:** two files on disk and a "which one is real" moment when inspecting saves
  by hand. Accepted because one save behind is enormously better than gone, and "your pet
  vanished" is the worst possible failure for this game.

## 12. Save on feeding, new game, and backgrounding — never on the tick

- **Date:** 2026-09-15
- **Considered:** the milestone's three moments · those plus a periodic save every few
  minutes · saving on both `APPLICATION_PAUSED` and `APPLICATION_FOCUS_OUT`
- **Chosen:** the three moments, with `NOTIFICATION_APPLICATION_PAUSED` catching
  backgrounding. A periodic save buys almost nothing here: because `last_ticked_at` is
  refreshed every 60 seconds, an unsaved gap becomes correctly-computed offline decay on
  the next launch, so the only thing a timed write protects is a feed that happened
  seconds before an unannounced kill. `FOCUS_OUT` was declined for saving because it
  fires on every desktop window switch — and because `ear.gd` and `eye.gd` already use it
  for gesture release, keeping the two concerns on separate notifications.
- **Trade-off:** a feed immediately before an Android kill is lost. Judged acceptable
  against writing to disk forever while idle.

## 13. Settle the input-stealing question by device test, not by reasoning

- **Date:** 2026-09-15
- **Considered:** build the `CanvasLayer` with a minimal touch surface and assume it is
  fine · pre-emptively move `ear.gd` and `eye.gd` from `_unhandled_input` to `_input` ·
  build it, then test the specific gesture on the phone and decide
- **Chosen:** test first. Godot's GUI pass runs before `_unhandled_input`, so a `Button`
  that consumes a release over its own rect should strand an ear mid-pull — but "should"
  is a reading of input ordering, not an observation, and the fix touches two M1 files
  that were tuned on the device and currently work. Evidence before edits.
- **Test:** pull an ear, drag the finger over the FEED button, lift. Springs back →
  nothing to change. Stays stretched → switch both files to `_input`. Repeat for the 🛠
  corner button.
- **Trade-off:** one extra round trip through the developer, who is the only one who can
  see it.

## 14. The feeding bounce gets its own node above `Visual`

- **Date:** 2026-09-15
- **Considered:** a `celebrate` animation in the existing `AnimationPlayer` · tween the
  `Bunny` node itself · insert a `Bounce` node between `Bunny` and `Visual` and tween
  that
- **Chosen:** the `Bounce` node. The `idle` loop writes `Visual:position` and
  `Visual:scale` every frame forever, so a tween on those properties is simply
  overwritten — the `AnimationPlayer` wins and the bounce never appears, with no error to
  explain why. `ear.gd` already solved exactly this by splitting the drag and the idle
  wobble across two nodes; reusing that pattern adds no new concept to the rig. A
  `celebrate` animation would stop `idle` dead and snap back on return unless the blend
  is hand-authored in an editor Claude cannot see. Tweening `Bunny` directly avoids the
  conflict but collides with `main.tscn` owning that node's position.
- **Trade-off:** one more node in the rig, and the four `NodePath`s in `idle` and `RESET`
  gain a `Bounce/` segment. Get that wrong and the idle silently stops animating with no
  error — worth checking deliberately rather than assuming.

## 15. The reaction is bounce and happy eyes only

- **Date:** 2026-09-15
- **Considered:** bounce and eyes, using only what exists · plus a feeding sound effect ·
  plus a particle burst
- **Chosen:** bounce and eyes. §2.9 asks for a bounce, happy eyes, sparkles and a sound,
  but `assets/audio/` holds one file (the music) and there is no SFX bus, and no sparkle
  art exists. Adding either means blocking the loop on assets, and §2.9's actual point —
  that changing a stat produces a satisfying visible reaction — is met without them.
  Sparkles carry an extra unknown: under GL Compatibility, `GPUParticles2D` is limited
  and may need `CPUParticles2D` instead.
- **Trade-off:** a quieter reaction than the milestone pictures. Both are additive later
  and neither changes the architecture.

## 16. Happy eyes reuse `eye.gd`'s existing release timer

- **Date:** 2026-09-15
- **Considered:** add a `HAPPY` state to `Eye` alongside neutral and held · call
  `close()` and start the existing `_release_timer` · skip the happy eyes entirely
- **Chosen:** reuse the timer, as a new `hold_shut(seconds)` method. `is_busy()` already
  returns true while that timer runs, and blinking already leaves busy eyes alone — so
  the blink-fights-the-bounce problem is solved by code that exists, written for exactly
  this reason. A state enum would be clearer to read and is the right move once a real
  happy-eye texture exists, but that texture does not.
- **Trade-off:** "shut because happy" and "shut because a finger just lifted" are
  indistinguishable inside `Eye`. Fine while both mean the same closed sprite.

## 17. A new game starts at 70 and saves immediately; `Fresh` stays 100

- **Date:** 2026-09-15
- **Considered:** start at 100 · start at 100 but defer the first write · start partly
  hungry · and separately, whether the `Fresh` preset should match the new-game value
- **Chosen:** 70, written to disk on that first launch. Starting full makes the first
  carrot a no-op against a full bar, which is a poor first minute and a poor first test.
  70 also happens to demonstrate both cases in two taps: the first carrot shows an
  uncapped +20 to 90, the second shows the clamp at 100 rather than 110. Saving
  immediately means the file exists from the first run onwards, so "no save yet" stops
  being a state to reason about.
- **Chosen, separately:** `Fresh` stays 100 as §2.5 specifies, meaning *completely full*,
  while `Reset Save` produces the new-player state at 70. They are genuinely different
  scenarios and now have different names. A third `Full` preset was declined as a button
  too many.
- **Trade-off:** the first thing a new player meets is a Usapyon that already wants
  something. A tone call, not just a number, and reversible in one constant.

## 18. `Reload From Disk` runs the catch-up, identical to a cold launch

- **Date:** 2026-09-15
- **Considered:** reload raw, stamping `last_ticked_at = now` · reload and then
  `catch_up_to(now)` · two separate buttons for the two behaviours
- **Chosen:** catch up. The button's value is that it reproduces the startup path without
  closing the app, which is most of why you would reach for it while testing offline
  progression. Two buttons were declined as one control too many for a panel you come
  back to in a month.
- **Trade-off:** a three-week-old save loads as hunger 0, so you cannot use this button to
  inspect raw stored values. Read the JSON directly for that.

## 19. The DebugPanel is its own scene, toggled by a 🛠 top-right

- **Date:** 2026-09-15
- **Considered:** always visible in debug builds · its own scene, hidden behind a corner
  toggle · a separate `debug.tscn` that embeds `main.tscn`
- **Chosen:** own scene, instanced into `main.tscn` only when `OS.is_debug_build()`,
  hidden by default, with a small visible 🛠 top-right (clear of the centred hunger bar).
  Always-visible would put a panel in shot for every feel test on the phone, which is
  most of what the phone is for. A separate debug scene was rejected because you would
  stop testing the scene players actually load.
- **Trade-off:** the 🛠 is one more `Control` that can eat a gesture release in that
  corner — the same risk as decision 13, and tested the same way.

## 20. `autoloads/` plus a new `systems/`, with tuning constants in the rules

- **Date:** 2026-09-15
- **Considered:** all four scripts in `autoloads/` · the rules beside `bunny.gd` in
  `scenes/` · `autoloads/` for the two autoloads and a new `systems/` for the rules. And
  separately, whether `STARTING_HUNGER` belongs in `BunnyCareRules`, in `GameState`, or in
  `SaveManager`
- **Chosen:** `autoloads/game_state.gd`, `autoloads/save_manager.gd`,
  `systems/bunny_care_rules.gd`. Putting a non-autoload in `autoloads/` makes the folder
  name a lie; putting the rules in `scenes/` next to `bunny.gd` makes them read as the
  visible node's rules, which is the exact coupling §2.3 asks you to avoid.
- **Chosen, separately:** `STARTING_HUNGER` joins `DECAY_PER_HOUR` and `CARROT` in
  `BunnyCareRules`, so every number that decides how the game feels is in the one file
  you open to tune it. §2.2 lists "create default/new-player state" under SaveManager,
  but that would put gameplay numbers in the file about file I/O; SaveManager instead
  calls `GameState.reset_to_new()`.
- **Trade-off:** a new folder holding one file. It has an obvious future — the other care
  stats' rules land beside it.

## 21. Feeding is gated on overcap, not on a cooldown

- **Date:** 2026-09-15
- **Considered:** leave repeat feeding unrestricted as the milestone allows · bring the
  design's ~2-hour "isn't hungry right now" timer forward · block feeding whenever the
  food would push hunger past 100
- **Chosen:** the overcap gate. This is **not** the design's feeding cooldown arriving
  early — it answers a different question. `docs/design/01-game-mechanics.md` §7 defers
  spam by *time since eating*; this defers it by *whether the food would be wasted*. Both
  will eventually exist and a feed will have to pass both. The reason to build this one
  now is Care Points: CP is earned by feeding, so a player who taps a full Usapyon forever
  earns unbounded CP. The overcap gate bounds it structurally — total hunger restorable
  per day is capped by total decay (96 points at 4/hour), so no amount of tapping produces
  more.
- **Trade-off:** it is a de-facto cooldown as a side effect, and a longer one than the
  design's. Feed at 80, land on 100, and at 4/hour the button is dead for **five hours**.
  Nobody chose five; it falls out of `CARROT` and `DECAY_PER_HOUR` multiplying together.
  Worth watching once the real cooldown lands, because the two rules will compound.
- **Left open, for the design doc rather than the code:** this only bounds CP if **CP is
  earned per hunger point restored**. Per *feeding event* it inverts the incentive — free
  pellets at +10 unlock at 90 and can be fed roughly every 2.5 hours, while a carrot
  unlocks at 80 and goes every 5 — so the weakest free food would farm the most CP.

## 22. The threshold is derived from the food, never a constant

- **Date:** 2026-09-15
- **Considered:** `const NOT_HUNGRY = 80.0` beside `CARROT` · derive it from the food's
  own value · derive it with a small waste allowance
- **Chosen:** derive. `80` is not a number in its own right, it is `MAX_HUNGER - CARROT`,
  and writing it down as a constant is only correct while carrots are the only food. The
  garden in `docs/design/01-game-mechanics.md` already names lettuce as "very filling";
  under a fixed 80 a +40 lettuce fed at 78 wastes 18 points and still pays full CP, which
  is the exact loophole decision 21 exists to close. `can_eat(hunger, amount)` closes it
  for every food that will ever be added, with no constant to maintain — carrot unlocks at
  80, a +40 lettuce at 60, +10 pellets at 90, all for free.
- **Trade-off:** filling foods become *harder* to use than weak ones, which is the
  opposite of how an upgrade usually reads. That is the correct behaviour for an
  anti-waste rule but it is a real UX shape, and it is the mechanism behind the CP
  inversion flagged in decision 21.
- **Declined:** a waste allowance (`<= MAX + SLOP`). A second number to tune, guarding
  against a discomfort — sitting at 81 unable to act — that the rounding in decision 23
  already makes invisible.

## 23. Rounded integers are the game's currency; the float is a decay accumulator

- **Date:** 2026-09-15
- **Considered:** keep every calculation on the float and round only in the label ·
  round in the gate but add on the float · make the rounded integer the value that
  gameplay and UI both operate on
- **Chosen:** the rounded integer, everywhere except decay. The float exists so decay can
  accumulate between 60-second heartbeats; it is not a number the game or the player
  reasons about. Two problems fall away at once. The label prints `roundi(hunger)`, so at
  79.6 it reads "Hunger 80" and the button works, while at 80.4 it reads "Hunger 80" and
  the button does nothing — with a silent no-op (decision 26) there is no way to tell
  those apart, and the player's arithmetic (80 + 20 = 100) is correct and ignored. And
  gating on the rounded value while adding on the float leaves 80.4 + 20 = 100.4 clamped
  back to 100, so "never overcap" would be only approximately true. Gate *and* add on the
  rounded value and the result is an exact integer ≤ 100 every time: the guarantee becomes
  provable, and the clamp becomes unreachable from feeding.
- **Consequence:** `fed()` is `care_value(hunger) + amount`, so feeding discards the
  fractional part. `roundi` rounds half away from zero, so the error is ±0.5 and
  symmetric — expected drift over many feeds is zero, against 96 points of decay a day.
- **Consequence:** the `ProgressBar` reads `care_value` too, so bar, label and button can
  never disagree. No visible difference: at 4/hour a heartbeat moves the bar 0.067% either
  way.
- **Deliberately excluded:** the debug panel keeps `Hunger: %.1f`. It is a developer
  instrument, not player-facing UI, and it is the only window onto the float — precisely
  the thing that would reveal a rounded value leaking into stored state. The panel's
  direct `GameState.hunger` writes stay on the float and stay outside the gate; debug
  *should* bypass gameplay rules.
- **Trade-off:** "which number is real" now has a two-part answer. Mitigated by there
  being exactly one function, `care_value()`, that anyone can follow.

## 24. `MIN_HUNGER` / `MAX_HUNGER` move to `BunnyCareRules`

- **Date:** 2026-09-15
- **Considered:** leave them in `GameState` and pass the cap into `can_eat` · leave them
  and let `GameState` do the comparison itself · move them to `BunnyCareRules`
- **Chosen:** move. `can_eat` needs the cap, and decision 9 makes the rules pure — they
  may not name `GameState`. Passing the cap in preserves purity but lets the clamp and the
  gate silently disagree, since two call sites would each supply their own 100. Letting
  `GameState` compare leaks "how much things change" back out of the rules file that
  decision 20 exists to concentrate it in. The bounds are pacing numbers like
  `DECAY_PER_HOUR`; they belong in the file you open to tune the game. The `GameState`
  setter now clamps with `BunnyCareRules.MIN_HUNGER` / `MAX_HUNGER`.
- **Trade-off:** one more indirection in the setter, and `GameState` no longer states its
  own range. There was exactly one call site, so the move was mechanical.

## 25. `GameState.try_feed()` owns the feed action

- **Date:** 2026-09-15
- **Considered:** a two-line guard at the top of the `hud.gd` handler · move the whole
  action into `GameState.try_feed(amount) -> bool`
- **Chosen:** `try_feed`. The deciding argument is not future-proofing — it is that `fed`
  is a `GameState` signal that `GameState` never emits. `hud.gd` reaches into another
  object and fires its signal on its behalf, and adding the rule would make a script whose
  own docstring calls itself "the hunger display and the one feeding control" the sole
  authority on when feeding is legal. Three things already on the map land on this branch:
  §2.8's "later this can evolve into physically dragging a carrot onto your Usapyon" is a
  second caller; cleanliness and happiness "slot into the same pattern", which in `hud.gd`
  means three gameplay rules in a display script; and CP is awarded on a *successful*
  feed, which is the branch `try_feed` already owns. It is roughly eight lines **moved**,
  not added, and it worsens no coupling — `GameState._notification()` already calls
  `SaveManager.save()`, and `SaveManager._ready()` already writes into `GameState`.
- **Trade-off:** `GameState` grows a verb, having been mostly values and a clock. Decision
  6's boundary still holds: it decides *whether* and *when*, never *by how much*.
- **Also decided here:** it returns `bool`. Nothing consumes it today; it is what a
  refusal reaction will read.

## 26. A blocked tap is a silent no-op

- **Date:** 2026-09-15
- **Considered:** disable the button · keep it live and have the Usapyon visibly refuse ·
  keep it live and do nothing
- **Chosen:** live and doing nothing, for now. `docs/design/01-game-mechanics.md` §7 wants
  "*Your Usapyon isn't hungry right now*" — a message, not a dead control — and the
  refusal belongs with the Usapyon, not with a greyed rectangle. That animation is not
  Milestone 2 work, and disabling the button in the meantime would be a *different*
  decision to undo later rather than a step toward it. The `Button` still shows its
  pressed style, so a tap is not entirely unacknowledged.
- **Trade-off:** for now a blocked tap is indistinguishable from a missed one, which is
  the kind of thing a tester reports as a bug. Decision 23 is what makes it survivable:
  the number on screen always predicts what the button will do, so the player can at least
  see *that* they are full even without being told.
- **Consequence:** `hud.gd` never touches `disabled`, and `_refresh()` stays a pure
  redraw.
