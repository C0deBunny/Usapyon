class_name BunnyCareRules
extends RefCounted

## Every number that decides how caring for a Usapyon feels, and the two rules
## that apply them. This is the file you open to change the pacing.
##
## The functions are pure: they take a hunger value and hand back a new one, and
## never mention GameState. That keeps "what the values are" (GameState) apart
## from "how much they change" (here) — and it means they can be checked with a
## single print(), with no autoload, no scene and no tree.
##
## Hunger reads as fullness: 100 is completely full, 0 is starving.

## A new Usapyon starts partly hungry, so the first carrot has somewhere to go
## and the second one demonstrates the clamp.
const STARTING_HUNGER: float = 70.0

## Full to empty in 25 hours, so a Usapyon left overnight and all day is nearly
## empty but not quite: checking in once a day is the bare minimum, not a
## guaranteed failure. Whether that reads as tense or as punishing needs real
## days on a phone, not a debug button.
const DECAY_PER_HOUR: float = 4.0

const CARROT: float = 20.0

const SECONDS_PER_HOUR: float = 3600.0


## Hunger after eating `amount`. Deliberately uncapped — clamping to 0..100 is
## the GameState setter's job, so it happens on every write rather than only on
## the writes that remembered to ask for it.
static func fed(hunger: float, amount: float) -> float:
	return hunger + amount


## Hunger after `seconds` of no care. Negative elapsed never reaches here:
## GameState.catch_up_to() clamps a backwards clock to zero first.
static func decayed(hunger: float, seconds: float) -> float:
	return hunger - DECAY_PER_HOUR * (seconds / SECONDS_PER_HOUR)
