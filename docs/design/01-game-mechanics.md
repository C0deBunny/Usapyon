# Usapyon — Game Mechanics

> **This document owns the game's systems design.** Where any other design
> doc disagrees about stats, progression, currency or care, this one is right.
>
> It describes the intended shape of the finished game, **not** what to build
> now. Build scope lives in [`../milestones/`](../milestones/).

## 1. Core Concept

**Usapyon** is a Tamagotchi-style virtual pet game centered around
caring for a bunny, earning permanent progression, unlocking better ways
to provide care, and customizing your Usapyon and its home.

The basic daily care loop should remain quick and approachable. Optional
systems such as gardening, minigames, collecting, and customization add
depth for players who want to spend more time in the game.

A central design principle is:

**Basic care is always enough to keep your Usapyon healthy. Better care is
needed to keep progressing.**

------------------------------------------------------------------------

## 2. Naming

**Usapyon is a species, not a name.**

-   *Usapyon* is the title of the game.
-   A *Usapyon* is the fantasy creature the player cares for — one of a kind of
    bunny, not an individual called Usapyon.
-   In player-facing text, refer to it as **your Usapyon**:

> *"Take good care of your Usapyon, or it will get sad."*

Never write "feed Usapyon" or "Usapyon is hungry" as though it were the pet's
proper name.

------------------------------------------------------------------------

## 3. Core Care Needs

Your Usapyon has three main care stats:

-   🥕 **Hunger** — restored by feeding it.
-   🧼 **Cleanliness** — restored by cleaning it.
-   😊 **Happiness** — restored through playing and other enjoyable
    activities.

Basic versions of every essential care action are always available. The
player should never become unable to care for their Usapyon because they have
no coins or have not unlocked something.

Examples of starter care:

-   🥣 Unlimited basic pellets for feeding.
-   🧽 A basic sponge for cleaning.
-   🎾 A simple ball/play interaction for Happiness.

### Sleep

🌙 **Sleep is not a care stat.**

Your Usapyon follows a day/night schedule and automatically sleeps at night.
The player does not need to manually refill an Energy meter.

------------------------------------------------------------------------

## 4. Care Points

Care actions award **Care Points (CP)**.

Care Points represent the quality and amount of care the player has
provided during the current day.

Examples:

-   🥣 Basic pellets provide Hunger and a basic amount of CP.
-   🥕 Better/homegrown food provides better care and more CP.
-   🧽 A starter sponge provides basic cleaning and CP.
-   🫧 An upgraded sponge provides improved care and more CP.
-   🎾 Playing with your Usapyon provides Happiness and CP.
-   🎮 Minigames can also provide Happiness and normal play-related CP.

The exact values are not decided yet and should eventually be balanced
through playtesting.

------------------------------------------------------------------------

## 5. Daily Care Stars

Each day has a **Care Point target**.

If the player earns enough Care Points during that day, your Usapyon earns:

**⭐ 1 Care Star**

Care Stars are the main permanent progression system.

-   A maximum of roughly one Star can be earned per successful day.
-   Stars are permanent.
-   Stars never decrease.
-   Missing a Star means losing that day's potential progression, not
    losing previous progress.

### Increasing Care Requirements

The Care Point requirement increases at certain progression stages.

Early in the game, basic care is enough to earn Stars.

Later, relying only on starter pellets, the starter sponge, and other
basic care becomes inefficient for reaching the higher CP requirements.
The player is encouraged to use the better care options they have
unlocked.

Example concept:

| Progression | Daily CP Target | Expected Care |
| --- | ---: | --- |
| Beginning | 150 CP | Basic food, cleaning, play |
| Early | 180 CP | First crops begin helping |
| Growing | 220 CP | Better food and cleaning tools |
| Established | 260 CP | More varied/upgraded care |
| Late | 300 CP | Many high-quality care options |

These numbers are placeholders.

The CP requirement should **not increase every single Star**. Instead,
increases should happen at meaningful progression milestones, after the
player has already gained access to tools that make the new requirement
reasonable.

### Main Progression Loop

**Care for your Usapyon → earn CP → earn ⭐ → unlock better care →
purchase/use upgrades → meet higher CP targets → earn more ⭐**

This means the player eventually **needs to upgrade in order to continue
progressing comfortably**, while your Usapyon can still remain healthy using
basic care.

------------------------------------------------------------------------

## 6. Neglect and Sickness

Not earning enough Care Points means:

**No Star is earned that day.**

This is the basic consequence for insufficient care.

Missing a target on its own carries **no setback at all** — no lost Stars, no
lost items, no lost unlocks. The player simply does not gain that day's Star.

**Prolonged** neglect is different. It can apply a temporary **debuff**, which
makes reaching the daily CP target harder until it is cleared.

### 🤒 Sickness

Sickness is the first such debuff.

-   Your Usapyon becomes sick after significant, repeated neglect.
-   While sick, earning Care Points is harder — for example a stat such as
    Cleanliness is capped below its normal maximum, so the care actions that
    depend on it yield less CP.
-   The player clears it with medicine, good care, and rest.
-   It eventually recovers, and normal care and progression continue.

A debuff raises the bar temporarily. It never removes permanent Stars, items,
or unlocks, and it is never a punishment for a single missed day.

Additional conditions could be added later, but sickness alone is enough
for an early implementation.

------------------------------------------------------------------------

## 7. Food

### Basic Food

🥣 **Pellets are free and unlimited.**

They ensure your Usapyon can always be fed, even if the player:

-   Has zero coins.
-   Has no crops ready.
-   Has not unlocked the garden.
-   Does not currently care about earning Stars.

Pellets provide adequate basic care but relatively low Care Points
compared with upgraded food.

### Feeding Frequency

Your Usapyon cannot simply be fed repeatedly.

After eating, your Usapyon is full for a period of time (conceptually around
two hours). The game can present this naturally as:

> *Your Usapyon isn't hungry right now.*

This prevents food spam while keeping the mechanic understandable.

------------------------------------------------------------------------

## 8. Garden

🌱 The Garden is unlocked later through Care Star progression.

It allows the player to grow better foods for your Usapyon.

Garden crops provide stronger/higher-quality care than basic pellets and
therefore help the player meet increasingly demanding Care Point
targets.

Different crops can eventually have different strengths or secondary
effects.

Examples:

-   🥕 Carrot — reliable everyday food.
-   🥬 Lettuce — very filling.
-   🍓 Strawberry — Hunger plus Happiness.
-   🌿 Herb — potentially useful for recovery/health.
-   🎃 Larger/rarer crops — stronger effects but longer growing times.

### Seed Unlocks

Seeds follow the same progression model as other upgrades:

**⭐ Reach required Star milestone → seed becomes available → 🪙 buy it
once → permanently own it**

Example:

> ⭐ Carrot Seeds unlocked\
> 🪙 Purchase Carrot Seeds\
> 🌱 Carrots can now be planted infinitely.

Once a seed type has been purchased, planting it **does not cost
additional coins**.

The garden is instead limited by things such as:

-   Number of garden plots.
-   Crop growing time.
-   Which crops the player chooses to grow.

This avoids turning gardening into a recurring tax on the player's
cosmetic savings.

------------------------------------------------------------------------

## 9. Care Upgrades

Functional care upgrades are gradually unlocked through Stars.

Examples include:

-   🧽 Better sponges.
-   🥕 Better food/seed types.
-   🎾 Potentially improved toys.
-   🌱 Garden improvements.
-   Future care tools.

The general progression model is:

**⭐ Stars unlock access → 🪙 Coins purchase the upgrade → upgrade is
permanently owned**

Functional upgrades should be relatively inexpensive.

Their purpose is to improve the quality of care and provide enough Care
Points to keep up with higher progression requirements — not to make
basic care intentionally frustrating.

------------------------------------------------------------------------

## 10. Minigames

🎮 Minigames are primarily **optional activities**.

They serve several purposes:

-   Increase 😊 Happiness.
-   Provide normal play-related Care Points.
-   Provide 🪙 Coins.
-   Add gameplay variety.
-   Give players something to do when they want a longer play session.

Minigames should **not be required for ordinary daily care**.

A player who does not want to play a minigame can use a quick
interaction instead:

> 🎾 Play with a ball → Happiness increases.

The player should therefore be able to perform their essential care
relatively quickly.

### Unlocking Minigames

Additional minigames can be unlocked through Star progression.

New minigames primarily provide **variety**, not stronger care or
dramatically higher income.

This prevents later minigames from making earlier ones obsolete.

------------------------------------------------------------------------

## 11. Coins

🪙 Coins are mainly a **fun/customization currency**.

**Caring does not earn Coins.** Caring earns Care Points, which reset daily and
exist only to reach that day's target and earn a ⭐. The two economies are
separate on purpose: CP measures today's care, Coins buy things.

The primary source of Coins is minigames, with additional occasional
sources such as:

-   🏆 Achievements.
-   🎁 Gifts.
-   ✨ Special events.

### Daily Minigame Rewards

Minigames should provide a useful daily Coin bonus without allowing
players to become rich immediately through grinding.

Concept example:

-   First few games of the day provide a shared total bonus of around
    **30 Coins**.
-   Once the daily bonus is exhausted, additional minigame plays provide
    only a small amount, such as **2--3 Coins**.

The daily bonus should be **shared across all minigames**.

Unlocking more minigames therefore gives the player more variety without
multiplying their daily income.

There should be no hard restriction preventing the player from
continuing to play minigames if they enjoy them.

------------------------------------------------------------------------

## 12. Cosmetics

🎀 Cosmetics are intended to be the primary long-term Coin sink.

Possible cosmetics include:

### Your Usapyon

-   Hats
-   Bows
-   Glasses
-   Scarves
-   Outfits
-   Other accessories

### Home

-   Wallpaper
-   Flooring
-   Beds
-   Rugs
-   Lamps
-   Plants
-   Furniture
-   Room themes

Cosmetics should generally cost significantly more than functional
upgrades.

This creates a saving goal:

> *Do I spend a small amount on this useful upgrade now, or keep saving
> for the cosmetic I really want?*

Functional progression should not constantly drain the player's savings,
however. Upgrades are occasional and relatively cheap; cosmetics are
where most Coins are expected to go.

------------------------------------------------------------------------

## 13. Resource Roles

Each major resource/system has a distinct purpose:

| System | Purpose |
| --- | --- |
| 🥕🧼😊 Care Stats | Your Usapyon's current needs |
| ❤️ Care Points | Daily care effort — resets each day, never spent |
| ⭐ Care Stars | Permanent progression and unlock milestones |
| 🪙 Coins | Mostly cosmetics, plus cheap permanent upgrades |
| 🌱 Garden | Better food and care through planning |
| 🎮 Minigames | Optional fun, Happiness, and Coin income |
| 🤒 Debuffs | Temporary difficulty from prolonged neglect |
| 🌙 Sleep | Automatic day/night behavior |

------------------------------------------------------------------------

## 14. Overall Gameplay Structure

### Daily Care Loop

**Check your Usapyon → feed → clean → play → earn Care Points → reach daily
CP target → earn ⭐**

### Progression Loop

**⭐ Stars → unlock new care options/content → 🪙 purchase upgrades →
provide higher-quality care → meet higher CP requirements → earn more
Stars**

### Optional Economy Loop

**🎮 Minigames → 🪙 Coins → 🎀 cosmetics / occasional upgrades**

### Gardening Loop

**⭐ Unlock seed → 🪙 purchase seed type once → 🌱 plant → wait →
harvest → 🥕 provide better care**

### Neglect Loop

**Poor care → miss ⭐ → continued/severe neglect → 🤒 condition →
medicine + good care + rest → recovery**

------------------------------------------------------------------------

## 15. Core Design Principles

1.  **Basic care should always be possible for free.**
2.  **A Usapyon should never require premium/upgraded care simply to
    survive.**
3.  **Better care is required for continued progression, not basic
    survival.**
4.  **Stars are permanent and represent long-term progress.**
5.  **Care Point requirements increase only after the player has access
    to better care options.**
6.  **Functional upgrades are relatively cheap and permanent.**
7.  **Cosmetics are the main reason to save Coins.**
8.  **Minigames are optional and should never become a mandatory daily
    grind.**
9.  **Daily essential care should remain quick.**
10. **Optional activities provide depth for players who want longer
    sessions.**
11. **Neglect causes temporary setbacks rather than deleting permanent
    progress.**
12. **New systems should expand the ways the player cares for their Usapyon
    rather than simply making old mechanics annoying.**

------------------------------------------------------------------------

## 16. Development Scope

Not described here. This document is the shape of the finished game; what gets
built, and in what order, lives in [`../milestones/`](../milestones/) — one file
per milestone, each stating its own scope and what it deliberately leaves out.

The Garden, Coins, shop, minigames, cosmetics, debuffs and upgrades are all
late additions. The core care loop comes first.
