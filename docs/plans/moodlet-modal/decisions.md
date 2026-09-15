# Decisions: Moodlet Modal

## 1. Fold into milestone 02 rather than open milestone 03

- **Date:** 2026-09-15
- **Considered:** write `03-*.md` for the new stats · amend `02-persistent-pet.md` · build first and reconcile the docs afterwards
- **Chosen:** amend milestone 02 — there was time to finish the care loop properly rather than ship a milestone that proves the architecture with one stat and leaves the other two hanging.
- **Trade-off:** milestone 02 stops being a record of one shipped slice and becomes a larger target. Its "Not Part of Milestone 2" list loses its first entry, which was the explicit reason this decision had to be made at all rather than assumed.

## 2. Three hand-written properties, not a dict or a Resource

- **Date:** 2026-09-15
- **Considered:** three properties each with their own copied setter · one `_stats` Dictionary keyed by a `Stat` enum with `get_stat()`/`set_stat()` · a `CareStat` Resource per stat
- **Chosen:** three properties — `GameState.cleanliness` autocompletes, the debug panel and HUD keep reading plain names, and no new concept enters the codebase. CLAUDE.md asks for simple over clever and puts resource-driven data on the "ask first" list.
- **Trade-off:** roughly 45 lines of near-identical setter code, and a fourth stat means a fourth copy. Accepted as the visible, boring kind of duplication.

## 3. Generalise `BunnyCareRules` names to be stat-agnostic

- **Date:** 2026-09-15
- **Considered:** rename to `care_value`/`can_restore`/`restored`/`decayed` with `CARROT`/`SPONGE`/`BALL` · keep `fed()` and `can_eat()` and call them for cleaning too · generalise but use one shared `CARE_AMOUNT`
- **Chosen:** full rename with three separate amount constants. The maths was always stat-agnostic; only the vocabulary was not. Three constants that happen to equal 20 today cost nothing and mean the first food worth +40 needs no restructuring.
- **Trade-off:** every existing call site changes once, and the milestone doc's function names change with them.

## 4. Three `try_*` functions rather than one `try_care(stat, amount)`

- **Date:** 2026-09-15
- **Considered:** `try_feed`/`try_clean`/`try_play` · a single `try_care(stat, amount)` · three functions sharing a private helper
- **Chosen:** three functions. Consistent with decision 2 — a single `try_care` would reintroduce exactly the stat-id indirection the properties just rejected, and the Clean button would read `try_care(Stat.CLEANLINESS, SPONGE)`.
- **Trade-off:** the `can_restore` check and the `SaveManager.save()` call appear three times.

## 5. Bump save `VERSION` to 2; missing keys read 70

- **Date:** 2026-09-15
- **Considered:** version 2 with absent keys defaulting to `STARTING_VALUE` (70) · version 2 defaulting to 100 · leave `VERSION` at 1
- **Chosen:** version 2, absent keys read 70 — the same value a brand-new Usapyon gets, then decayed by elapsed time like every other stat. Milestone 02 already states the rule: missing keys read as defaults.
- **Trade-off:** an existing player's Usapyon appears mid-range on both new stats rather than spotless, which is slightly unearned in the other direction. 100 would have handed out two full bars nothing paid for.

## 6. Full-parity debug panel

- **Date:** 2026-09-15
- **Considered:** readout + ±10 row per stat · readouts for all three but ± for hunger only · one "all stats ±10" row
- **Chosen:** full parity, plus a new Neglected preset (all 5). Putting one stat low and another high is precisely the state the modal is most worth looking at, and only per-stat controls can produce it.
- **Trade-off:** the debug panel gets considerably taller.

## 7. No care reaction for cleaning or playing this iteration

- **Date:** 2026-09-15
- **Considered:** one `cared(stat)` signal replacing `fed` · three signals `fed`/`cleaned`/`played` · leave `fed` alone and give the other two no reaction
- **Chosen:** leave `fed` alone. Reactions were ruled out of scope for this pass, so `fed` keeps driving the happy hop and nothing new is invented for the other two.
- **Trade-off:** feeding hops and the other two actions are silent, which is a visible asymmetry. Combined with decision 13 it leaves Clean and Play with a single bar tween as their only feedback, and nothing at all when refused. Recorded as the plan's headline risk.

## 8. Delete the top-centre hunger panel

- **Date:** 2026-09-15
- **Considered:** delete it, stats live only in the modal · keep it as a permanent hunger bar · replace it with a compact always-on row for all three and drop the modal
- **Chosen:** delete it. The reference shows no stat chrome on the main screen in either state, and keeping hunger visible would draw it twice in two different styles while weakening the modal's reason to exist.
- **Trade-off:** hunger is no longer visible at a glance — it is one tap away.

## 9. The popover is one self-contained scene, including its button

> Partly superseded by decision 16 — still one scene, no longer a modal.

- **Date:** 2026-09-15
- **Considered:** own scene `moodlet_panel.tscn` · build it directly inside `hud.tscn` · its own `CanvasLayer` in `main.tscn`
- **Chosen:** own scene, and the button moved inside it. Building it in `hud.tscn` would push `hud.gd` well past a screenful, which CLAUDE.md calls the signal to split. Keeping the button outside the scene would mean the panel's dim draws over it forever.
- **Trade-off:** the scene is "button plus panel" rather than just a panel, so its name is slightly narrower than its job.

## 10. The button renders above the dim and toggles explicitly

> Superseded by decision 16 — the dim is gone. The explicit toggle survives it.

- **Date:** 2026-09-15
- **Considered:** dim covers everything including the button, so tapping it counts as tapping outside · button stays above the dim · dim covers the room only, leaving the tiles live
- **Chosen:** button above the dim, bright, as the reference draws it. Godot stops input at the first Control that handles it, so there is no double-fire — but there is also no free close, hence real toggle logic.
- **Trade-off:** a few lines of open/close branching that the dim-covers-everything option would have given away for nothing.

## 11. Plain rounded panel, no speech-bubble tail

> Superseded by decision 22 — the tail arrived, drawn rather than textured.

- **Date:** 2026-09-15
- **Considered:** plain `PanelContainer` with a new SURFACE stylebox · a small rotated triangle sprite as a tail · a 9-patch speech-bubble texture
- **Chosen:** plain panel. It reuses the same border, radius and shadow as every button, so it reads as the same family, and needs no new art. The tail is a later pass.
- **Trade-off:** less visibly "spoken by" the button than the reference draws it.

## 12. Pop-in scale tween from the button corner

- **Date:** 2026-09-15
- **Considered:** scale tween with `TRANS_BACK` from a top-left pivot, dim fading in parallel · fade only · no animation
- **Chosen:** the pop-in. It matches the bounce language `bunny.gd` already uses and connects the panel to where it came from.
- **Trade-off:** the pivot has to be set correctly for it to read as growing out of the button rather than merely scaling near it — listed as an open question.

## 13. No numbers on the bars

- **Date:** 2026-09-15
- **Considered:** bar only, as the reference draws it · a number to the right of the bar · the number folded into the label, as `hud.gd` does today
- **Chosen:** no numbers. The reference is most explicit on exactly this detail, and the proper answer to a silent refusal is the Usapyon refusing out loud, not a number the player has to do arithmetic on.
- **Trade-off:** milestone 02's checklist line *"The number on screen always predicts whether the button will work"* stops being literally true — a bar cannot distinguish 78 from 82. Rewritten to refer to the bar, with the gap noted. The debug panel keeps exact floats.

## 14. Small visual calls

- **Date:** 2026-09-15
- **Considered / chosen, each over its stated alternative:**
  - **Bars tween on value change** over snapping — with reactions out of scope the tween is the only feedback a Clean or Play tap produces.
  - **Tiles press in their stat's colour** over pressing cream — `TileButton.accent` already exists for exactly this and was unused, and the pressed state is the one thing a finger does not cover.
  - **A new `IconButton` theme variation** for the panel button over reusing a caption-less `TileButton` — the tile's content margins were sized for icon-over-caption, so an empty caption sits visibly off-centre and still reserves line height.
- **Trade-off:** three more things in the generated theme, and a tween guard needed so the once-a-minute heartbeat does not spawn tweens forever.

## 15. Real art replaces every placeholder icon

- **Date:** 2026-09-15
- **Considered:** ship with the placeholder mapping agreed during planning (`cog.png` for the bunny face, `broom.png` for the sponge) · use the real art that landed mid-session
- **Chosen:** real art. `bunny_happy.png` and `sponge.png` both exist in `assets/sprites/ui/`, so the substitutions are unnecessary — and the substitution applies to the Clean *tile* as well as the moodlet, since `01-game-mechanics.md` calls the starter tool a sponge.
- **Trade-off:** none. The rules constant is `SPONGE` rather than `BROOM`, so no rename is owed later.

---

*Second pass, after seeing it running in Godot. Decisions 16–23 rework the
popover's behaviour and size; everything above them stands unless a note says
otherwise.*

## 16. Drop the modal — a popover with everything behind it live

- **Date:** 2026-09-15
- **Considered:** keep the dim and the tap-outside-to-close modal · a plain toggle with no dim and nothing blocked
- **Chosen:** the toggle. Seeing it running made the modal read as far heavier than a corner stat readout deserves — darkening the room and freezing the bunny to glance at three bars is the wrong weight of gesture. The Usapyon stays tappable, its ears stay draggable, and the care tiles stay live while the popover is up.
- **Trade-off:** no tap-outside-to-close, so the button must toggle explicitly. Decision 10's reasoning goes with the dim; its toggle survives.

## 17. Size the popover off the reference, then take it further

- **Date:** 2026-09-15
- **Considered:** match the reference sheet exactly · shrink to ~55% of the first build · reference internals in a narrower box
- **Chosen:** measured the reference against the first build and found the **width was already right** — what read as oversized was every element inside being ~1.4× the reference. Shrank the internals past the reference rather than merely to it: icon 96→60, bar 44→22, label font 36→26, row gap 28→22, panel padding 40/36→24/20, bar outline 4→3. Panel lands at 384 × 267, against 424 × 378 before and 427 × 309 in the reference.
- **Trade-off:** `Cleanliness` at font 26 is small; it is a glanceable readout, not a control, so that is the intended register — but it needs confirming on a real phone rather than a monitor.

## 18. Auto-open on a care action; auto-close only if it opened itself

- **Date:** 2026-09-15
- **Considered:** auto-opened closes itself after ~2.5s while a hand-opened one stays · always stays until toggled · always auto-closes
- **Chosen:** the split rule. The popover exists to be watched during a care action, so it should arrive on its own and then get out of the way — but it must never overrule a decision the player made by hand. `_on_cared()` starts the countdown only if the popover was closed, and pressing the button cancels any countdown.
- **Trade-off:** two behaviours instead of one, which is a thing to remember when reading the code. The alternative was either a popover that accumulates over the bunny or one that yanks itself away mid-read.

## 19. A `cared` signal beside `fed`, not instead of it

- **Date:** 2026-09-15
- **Considered:** new `cared` signal on GameState · `hud.gd` reads the `try_*` return value · replace `fed` with `cared(stat)` now
- **Chosen:** add `cared`, emitted by all three `try_*` on success; `fed` stays feeding-only and keeps driving the hop. Two signals with one meaning each — `fed` = the bunny should react, `cared` = a care action landed. It carries no argument, because everything listening redraws from GameState anyway and a stat id would be the indirection decision 2 exists to avoid.
- **Trade-off:** a successful feed emits both. Wiring it in the HUD instead would have avoided the signal but left a future drag-a-carrot interaction having to remember to repeat it.

## 20. A refused action stays completely silent

- **Date:** 2026-09-15
- **Considered:** open the popover on refusal too, showing the full bar as the reason · success only · open and shake the offending bar
- **Chosen:** success only. "The popover opened" then means exactly one thing: something happened.
- **Trade-off:** the silent-refusal gap from decision 13 stays wide open — tap Feed at 90 and there is still nothing at all on screen. Opening on refusal would have closed it almost for free; this defers it to the Usapyon refusing out loud, which is not built.

## 21. The bar slide is the only emphasis, and it waits for the pop-in

- **Date:** 2026-09-15
- **Considered:** the moved row's icon pops · bar slide only · icon pop plus a brighter fill flash
- **Chosen:** slide only, but delayed. `BAR_TWEEN_DELAY` (0.15s) holds the fill until the pop-in has landed, then it runs for 0.4s — without the wait the first third of the fill happened while the card was still scaling up, which is the one moment it is meant to be watched.
- **Trade-off:** a beat of latency after the tap, and with three bars on screen it is less obvious *which* one moved.

## 22. Draw the tail, do not texture it

- **Date:** 2026-09-15
- **Considered:** a triangle PNG in a TextureRect · a rotated ColorRect · a `_draw()` on a small Control
- **Chosen:** `tail.gd` draws it: a filled triangle in `SURFACE`, then an antialiased polyline in `OUTLINE` on the two slanted edges only. No new art, exact colour match with the panel, and it cannot drift when `palette.gd` changes. The node is ordered *after* the panel and overlaps its top border by one border width, so the fill covers that border and the bubble actually opens; any deeper and the outline would spill onto the panel's fill.
- **Trade-off:** it needed a `Popover` wrapper node so the tail scales with the panel during the pop-in, and the tail carries no shadow of its own.

## 23. The button's face follows the worst stat

- **Date:** 2026-09-15
- **Considered:** the button never changes · it shows whether the popover is open · it shows the Usapyon's condition
- **Chosen:** condition. `bunny_happy` normally, `bunny_sad` when any stat is below `LOW_VALUE` (30), `bunny_angry` below `CRITICAL_VALUE` (5) — the *worst* stat decides, so a Usapyon that is fed but filthy does not look delighted. The thresholds live in `BunnyCareRules` beside the other pacing numbers; which face goes with which is the popover's business. From full at 4/hour that is roughly 17 hours to sad and 24 to cross.
- **Trade-off:** the button now means two things at once — tap target and mood readout — and it no longer says whether the popover is open. The popover is 384 × 267 and directly underneath it, so that was never ambiguous.
