Usapyon — current game concept

Usapyon is a cute, mobile-first virtual bunny/pet game inspired by Tamagotchi, but designed around a modern smartphone rather than trying to literally recreate an old Tamagotchi.

The core fantasy is simple:

Everyone gets their own little bunny. You care for it, bond with it, customize it, play with it, and gradually make it yours.

The name Usapyon comes from usa / usagi (rabbit) plus pyon, the Japanese onomatopoeia associated with hopping. It fits the cute Japanese-inspired identity really well.

🐰 The bunny

The bunny is the heart of the entire game.

Every player starts with a bunny, initially with a relatively simple/default appearance. Over time we can allow customization such as fur colors, patterns, ears, facial features, accessories, hats, clothing and potentially rarer cosmetic variants.

Importantly, customization should be layered onto the bunny, rather than requiring us to create hundreds of completely separate bunny sprites.

The bunny should also feel alive through relatively simple animations and reactions: blinking, breathing/idling, hopping, sleeping, eating, getting excited, looking sad, reacting when tapped/petted, etc.

We don't need complicated animation to sell this. A few expressive poses plus squash/stretch, movement and particles can go a long way.

🎨 Art direction

We decided against pixel art and leaned toward the cute sticker/vector-like kawaii style from the bunny reference you showed.

The general direction is:

soft rounded shapes + thick dark outlines + pastel colors + very expressive face + minimal shading + clean mobile-game presentation.

Something in this visual territory:

6

That style is actually quite suitable for an AI-heavy workflow because we don't need highly detailed frame-by-frame animation.

We should eventually establish a Usapyon style guide so generated assets don't gradually become inconsistent. Things like outline thickness, eye style, proportions, palette, shading rules, paws, ears, etc. should become fixed.

The reference bunny you showed is probably a good starting point for defining that visual language.

🎮 Core gameplay

The first version should be deliberately tiny.

You open Usapyon and see your bunny in its little environment. The bunny has a handful of needs/emotional states and you interact with it.

Eventually the basic loop could become something like:

check bunny → see what it needs → interact/feed/play → bunny reacts → needs improve → earn affection/progression → come back later

Possible core stats include:

Hunger, Happiness, Energy and Affection/Bond.

But I wouldn't immediately implement six meters because "Tamagotchi has stats" isn't by itself good design. We should decide which stats actually create interesting decisions.

Time continues while you're away, so returning to Usapyon matters. However, I would not make the bunny brutally punish the player for not opening the game. We're making a cozy pet game, not a guilt simulator. 😄

❤️ Bonding should be central

One direction I think is especially promising is making bond/affection more important than traditional Tamagotchi survival.

Your bunny gradually gets attached to you.

That could unlock things such as new reactions, animations, interactions, cosmetics, activities and perhaps personality behaviors.

So instead of:

“Keep these meters above zero or bunny dies.”

Usapyon can lean toward:

“Spend time with your bunny and discover more of its personality.”

That gives the game a much friendlier identity.

👆 Interactions

The bunny shouldn't just be something you look at.

Eventually we could support interactions such as tapping it, petting by swiping, feeding by dragging food, putting it to bed, cleaning it, playing with toys and watching it react to things.

The phone touchscreen makes those little tactile interactions particularly appropriate.

Even our first prototype could simply have:

tap bunny → bunny squishes/jumps → hearts appear → happiness increases.

That alone gives us our first actual game feel test.

🏠 Environment

Initially: one simple room/background.

Later, the player's bunny can have its own little home/space that can potentially be decorated.

That opens another large customization avenue:

furniture, wallpaper, floors, beds, food bowls, toys, seasonal decorations, plants, etc.

But that's expansion content. We absolutely should not build a decorating system in v1.

🛍️ Cosmetics & progression

Long term, cosmetics are probably one of Usapyon's strongest progression systems.

Players could earn currency through caring for their bunny and playing minigames, then spend it on things like clothing, accessories, food, toys and decorations.

This gives us a natural loop:

Care for bunny
↓
Build bond / complete activities
↓
Earn currency & unlock things
↓
Buy cosmetics / items
↓
Personalize bunny & home
↓
More things to do with bunny

And because the game is fundamentally about “my bunny”, cosmetic rewards actually have meaning.

🕹️ Minigames

Minigames are an expansion system, not part of our initial build.

That's one reason this idea is such a good first game: we can ship something tiny and then bolt additional activities onto it.

Eventually there could be simple games like hopping over obstacles, catching carrots, memory games, digging, racing, rhythm/timing games, etc.

They can award coins, items or affection.

Each minigame can effectively be its own small development project without requiring us to rewrite the core pet game.

🌱 How I'd structure development

Rather than thinking about “making the whole game,” I'd build Usapyon in increasingly complete versions.

Prototype: Bunny on screen → tap bunny → bunny reacts.

First gameplay: Hunger/happiness → feeding → petting → passage of time → save/load.

First actual game: polished bunny → animations → sounds → simple progression → a few items → basic UI.

Expansion: cosmetics → shop/currency → more interactions → minigames → room customization → more content.

And only much later should we worry about things like achievements, cloud saves, monetization, notifications, Google Play services, analytics, etc.

The most important scope rule

Our first meaningful milestone should not be:

“Make a Tamagotchi game.”

It should be:

“Make one cute bunny that feels good to interact with.” 🐰❤️

If we can get to the point where you open the app, see Usapyon idling, tap/pet it, it makes an adorable sound, squishes/hops and gives you a happy reaction — then we have something worth turning into a game.

That is where I'd go next. And since you're handing the implementation side to Claude, I'd actually spend our next design session defining the bunny itself: proportions, art rules, personality, animations, expressions and the exact first interaction set before you ask Claude to build much more.
