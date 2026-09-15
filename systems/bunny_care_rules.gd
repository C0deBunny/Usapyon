class_name BunnyCareRules
extends RefCounted

## Every number that decides how caring for a Usapyon feels, and the rules that
## apply them. This is the file you open to change the pacing.
##
## The functions are pure: they take a hunger value and hand back something, and
## never mention GameState. That keeps "what the values are" (GameState) apart
## from "how much they change" (here) — and it means they can be checked with a
## single print(), with no autoload, no scene and no tree.
##
## Hunger reads as fullness: 100 is completely full, 0 is starving.
##
## The stored float is a decay accumulator, not the number the game reasons
## about. Every rule here except decayed() runs on care_value(), and so does
## every player-facing readout.

## A new Usapyon starts partly hungry, so the first carrot has somewhere to go
## and the second one is refused — which is both halves of the feeding rule in
## two taps.
const STARTING_HUNGER: float = 70.0

## Full to empty in 25 hours, so a Usapyon left overnight and all day is nearly
## empty but not quite: checking in once a day is the bare minimum, not a
## guaranteed failure. Whether that reads as tense or as punishing needs real
## days on a phone, not a debug button.
const DECAY_PER_HOUR: float = 4.0

const CARROT: float = 20.0

const SECONDS_PER_HOUR: float = 3600.0

## The scale. These live here rather than in GameState because can_eat() needs
## the cap and the rules may not name GameState. GameState's setter clamps with
## them, so the clamp and the feeding rule cannot drift apart.
const MIN_HUNGER: float = 0.0
const MAX_HUNGER: float = 100.0


## The hunger the game and the player both work in. The stored float exists only
## so decay can accumulate between 60-second heartbeats; every rule below and
## every visible readout goes through here, so the bar, the label and the feed
## button can never disagree about what the number is.
##
## That matters more than it looks: a refused tap is silent, so if the label
## rounded 80.4 to "Hunger 80" while the rule judged 80.4, the player would see a
## number that says feeding should work and a button that does nothing.
static func care_value(hunger: float) -> int:
	return roundi(hunger)


## Whether `amount` of food would fit without any of it being wasted.
##
## Deriving the limit from the food instead of naming a threshold is the whole
## point. A carrot unlocks at 80, a +40 lettuce would unlock at 60 and +10
## pellets at 90, with nothing to retune when they arrive. Writing `80` down as a
## constant would be correct only while carrots are the only food.
static func can_eat(hunger: float, amount: float) -> bool:
	return care_value(hunger) + amount <= MAX_HUNGER


## Hunger after eating `amount` — always an exact whole number, because it adds
## to the same rounded value can_eat() judged. That is what makes "feeding never
## overcaps" provable rather than approximate.
##
## Still uncapped on its own: clamping stays the GameState setter's job, so it
## happens on every write rather than only the ones that remembered to ask. This
## function does not enforce can_eat() either — call GameState.try_feed(), which
## does both.
static func fed(hunger: float, amount: float) -> float:
	return care_value(hunger) + amount


## Hunger after `seconds` of no care. The one rule that reads the raw float, and
## it has to: at 4/hour a 60-second heartbeat moves hunger by 0.067, so rounding
## here would round every tick back to where it started and time would stop.
##
## Negative elapsed never reaches here — GameState.catch_up_to() clamps a
## backwards clock to zero first.
static func decayed(hunger: float, seconds: float) -> float:
	return hunger - DECAY_PER_HOUR * (seconds / SECONDS_PER_HOUR)
