class_name BunnyCareRules
extends RefCounted

## Every number that decides how caring for a Usapyon feels, and the rules that
## apply them. This is the file you open to change the pacing.
##
## The functions are pure: they take a care value and hand back something, and
## never mention GameState. That keeps "what the values are" (GameState) apart
## from "how much they change" (here) — and it means they can be checked with a
## single print(), with no autoload, no scene and no tree.
##
## They take a plain float and say nothing about *which* stat it is, so hunger,
## cleanliness and happiness all run through the same four functions. Only the
## amounts below are per-action.
##
## Every stat reads as a good thing: 100 is completely full, clean or delighted,
## 0 is starving, filthy or miserable. A full bar is always good news, so every
## bar can be drawn the same way without anyone having to remember which one is
## inverted.
##
## The stored float is a decay accumulator, not the number the game reasons
## about. Every rule here except decayed() runs on care_value(), and so does
## every player-facing readout.

## A new Usapyon starts partly in need, so the first carrot has somewhere to go
## and the second one is refused — which is both halves of the care rule in two
## taps.
const STARTING_VALUE: float = 70.0

## Full to empty in 25 hours, so a Usapyon left overnight and all day is nearly
## empty but not quite: checking in once a day is the bare minimum, not a
## guaranteed failure. Whether that reads as tense or as punishing needs real
## days on a phone, not a debug button.
##
## One rate for all three stats. If cleanliness ever wants to fall faster than
## hunger, this splits into three constants and nothing else changes.
const DECAY_PER_HOUR: float = 4.0

# --- What each care action is worth ------------------------------------------
# All 20 today, but named per action rather than shared: the first food worth
# +40 then costs nothing to add, and can_restore() gives it the right window on
# its own.

const CARROT: float = 20.0
const SPONGE: float = 20.0
const BALL: float = 20.0

# --- When a stat is a problem ------------------------------------------------
# The Usapyon wears its worst stat on its face, so these are the two numbers
# that decide when it stops looking happy. Pacing numbers, not drawing ones —
# which face goes with which is the popover's business.
#
# From a full 100 at 4/hour, LOW is about 17 hours away and CRITICAL about 24,
# so a day's neglect is what it takes to see the angry face.

## Below this, the Usapyon looks unhappy.
const LOW_VALUE: float = 30.0
## Below this, it looks properly cross.
const CRITICAL_VALUE: float = 5.0

const SECONDS_PER_HOUR: float = 3600.0

## The scale. These live here rather than in GameState because can_restore()
## needs the cap and the rules may not name GameState. GameState's setter clamps
## with them, so the clamp and the care rules cannot drift apart.
const MIN_VALUE: float = 0.0
const MAX_VALUE: float = 100.0


## The value the game and the player both work in. The stored float exists only
## so decay can accumulate between 60-second heartbeats; every rule below and
## every visible readout goes through here, so the bar and the care buttons can
## never disagree about what the number is.
##
## That matters more than it looks: a refused tap is silent, so if a readout
## rounded 80.4 down while the rule judged 80.4, the player would see a state
## that says the action should work and a button that does nothing.
static func care_value(value: float) -> int:
	return roundi(value)


## Whether `amount` of care would fit without any of it being wasted.
##
## Deriving the limit from the action instead of naming a threshold is the whole
## point. A carrot unlocks at 80, a +40 lettuce would unlock at 60 and +10
## pellets at 90, with nothing to retune when they arrive. Writing `80` down as a
## constant would be correct only while every action happens to be worth 20.
static func can_restore(value: float, amount: float) -> bool:
	return care_value(value) + amount <= MAX_VALUE


## The value after `amount` of care — always an exact whole number, because it
## adds to the same rounded value can_restore() judged. That is what makes "care
## never overcaps" provable rather than approximate.
##
## Still uncapped on its own: clamping stays the GameState setter's job, so it
## happens on every write rather than only the ones that remembered to ask. This
## function does not enforce can_restore() either — call GameState.try_feed(),
## try_clean() or try_play(), which do both.
static func restored(value: float, amount: float) -> float:
	return care_value(value) + amount


## The value after `seconds` of no care. The one rule that reads the raw float,
## and it has to: at 4/hour a 60-second heartbeat moves a stat by 0.067, so
## rounding here would round every tick back to where it started and time would
## stop.
##
## Negative elapsed never reaches here — GameState.catch_up_to() clamps a
## backwards clock to zero first.
static func decayed(value: float, seconds: float) -> float:
	return value - DECAY_PER_HOUR * (seconds / SECONDS_PER_HOUR)
