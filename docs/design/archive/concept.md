# Usapyon — Game Concept

> **Superseded, kept for context.** This is the original pitch, from before the
> systems were worked out. It is the origin of the tone and the creature, and
> nothing else.
>
> Where it described gameplay, later docs now own it and this file has been
> trimmed down to pointers. Do not build from anything here.

Usapyon is a cute, mobile-first virtual bunny/pet game inspired by Tamagotchi,
but designed around a modern smartphone rather than trying to literally recreate
an old Tamagotchi.

The core fantasy is simple:

Everyone gets their own little Usapyon. You care for it, bond with it, customize
it, play with it, and gradually make it yours.

The name Usapyon comes from usa / usagi (rabbit) plus pyon, the Japanese
onomatopoeia associated with hopping. It fits the cute Japanese-inspired
identity really well.

## 🐰 The creature

The Usapyon is the heart of the entire game.

Every player starts with one, initially with a relatively simple/default
appearance. Over time we can allow customization such as fur colors, patterns,
ears, facial features, accessories, hats, clothing and potentially rarer
cosmetic variants.

Importantly, customization should be **layered** onto the creature, rather than
requiring us to create hundreds of completely separate sprites.

It should also feel alive through relatively simple animations and reactions:
blinking, breathing/idling, hopping, sleeping, eating, getting excited, looking
sad, reacting when tapped/petted, etc.

We don't need complicated animation to sell this. A few expressive poses plus
squash/stretch, movement and particles can go a long way.

## 👆 Interactions

The Usapyon shouldn't just be something you look at.

Eventually we could support interactions such as tapping it, petting by swiping,
feeding by dragging food, putting it to bed, cleaning it, playing with toys and
watching it react to things.

The phone touchscreen makes those little tactile interactions particularly
appropriate.

## 🏠 Environment

Initially: one simple room/background.

Later, the player's Usapyon can have its own little home/space that can
potentially be decorated — furniture, wallpaper, floors, beds, food bowls, toys,
seasonal decorations, plants.

That is expansion content.

## The most important scope rule

Our first meaningful milestone should not be:

> "Make a Tamagotchi game."

It should be:

> "Make one cute creature that feels good to interact with." 🐰❤️

If we can get to the point where you open the app, see your Usapyon idling,
tap/pet it, it makes an adorable sound, squishes/hops and gives you a happy
reaction — then we have something worth turning into a game.

*(That milestone is now done — see
[`milestones/01-interactive-bunny.md`](../../milestones/01-interactive-bunny.md).)*

------------------------------------------------------------------------

## What this document no longer covers

| It used to describe | Now owned by |
| --- | --- |
| Art direction and visual rules | [`02-art-direction.md`](../02-art-direction.md) |
| Core stats and the care loop | [`01-game-mechanics.md`](../01-game-mechanics.md) |
| Progression, currency, cosmetics, minigames | [`01-game-mechanics.md`](../01-game-mechanics.md) |
| How development is staged | [`../milestones/`](../../milestones/) |

Two ideas from this pitch were explored and then **dropped**, so that nobody
revives them from here:

- **Affection / bond as a meter.** Progression is Care Points and Care Stars
  instead. Bonding is still the *feeling* we want, but it is not a number.
- **An Energy stat.** Sleep is automatic on a day/night schedule and is not a
  care stat at all.
