# Usapyon — UI Architecture

How the interface is put together: Controls, containers, theme, reusable scenes.

> **This document owns UI construction only.**
>
> - Which stats exist and what they do → [`01-game-mechanics.md`](01-game-mechanics.md)
> - Who owns the state the UI reads → [`../milestones/02-persistent-pet.md`](../milestones/02-persistent-pet.md)
> - What gets built now → [`../milestones/`](../milestones/)
> - Platform constraints (portrait, touch-only, GL Compatibility) → `CLAUDE.md`
>
> Screen layouts and stat names appearing below are **illustration only**. They
> are there to show the container structure, not to specify the design.

## Core Principle

Use a **hybrid approach**:

- **Godot Controls + Containers** for layout and UI behavior
- **Godot Theme resources** for consistent styling
- **Claude Code** for generating UI scenes, theme setup, scripts, signals, and simple animations
- **Custom sprites/textures** for Usapyon, icons, decorative art, and anything where the exact visual shape matters

Think of it like front-end development:

| Web | Godot |
|---|---|
| `div` | `Control` |
| flex row | `HBoxContainer` |
| flex column | `VBoxContainer` |
| CSS grid | `GridContainer` |
| padding wrapper | `MarginContainer` |
| `<button>` | `Button` |
| `<img>` | `TextureRect` |
| CSS design system | `Theme` |
| component | `.tscn` scene |
| event listener | signal |
| CSS transition / animation | Tween / AnimationPlayer |

---

## Recommended Main Scene Structure

Today `main.tscn` is just a background and the `Bunny` instance. When UI
arrives, it goes on its own `CanvasLayer` above the world:

```text
Main
├── Background
├── Bunny
│
└── CanvasLayer
    └── UI
```

Keep the **game world** and **UI** separate.

A `CanvasLayer` is useful for interface elements that should remain on top of the game world.

---

## Suggested UI Structure

```text
Game
├── Background
├── UsapyonArea
│   └── Usapyon
│
└── UI
    ├── TopBar
    │   ├── HungerMeter
    │   ├── HappinessMeter
    │   └── CoinsLabel
    │
    ├── DialogueBubble
    │
    └── BottomMenu
        ├── FeedButton
        ├── PlayButton
        └── CleanButton
```

A layout **purely to show the structure** — not a design decision. The exact
meters, labels, day counter and dialogue bubble below are placeholder filler:

```text
┌───────────────────────────────┐
│  ♡♡♡♡♡       ☀ Day 01    ¥120 │
│                               │
│                               │
│              (\_/)            │
│              ( •ᴗ•)           │
│              / >🥕            │
│                               │
│       "I'm hungry~!"          │
│                               │
│  Hunger   ♥♥♥♡♡               │
│  Happy    ♥♥♥♥♡               │
│                               │
├───────────────────────────────┤
│      🍓         🎾        🧼   │
│     Feed       Play      Clean │
└───────────────────────────────┘
```

---

## Reusable UI Scenes

Do not build every UI element directly inside one giant scene.

Create reusable components instead:

```text
ui/
├── main_ui.tscn
├── stat_bar.tscn
├── kawaii_button.tscn
├── dialogue_bubble.tscn
├── popup_panel.tscn
└── theme/
    └── usapyon_theme.tres
```

For example, one `StatBar` scene can be reused for:

```text
Hunger      ♥♥♥♡♡
Cleanliness ♥♥♥♥♡
Happiness   ♥♥♡♡♡
```

A reusable `StatBar` might contain:

```text
HBoxContainer
├── TextureRect icon
├── Label name
└── ProgressBar value
```

Possible exported properties:

```gdscript
@export var stat_name: String
@export var icon: Texture2D
@export var value: float
```

---

## Use Containers Instead of Manual Positioning

Avoid placing everything with fixed `x` and `y` coordinates.

Instead of:

```text
Button position:
x = 137
y = 624
```

Prefer:

```text
MarginContainer
└── VBoxContainer
    ├── Stats
    ├── Spacer
    └── HBoxContainer
        ├── Feed
        ├── Play
        ├── Clean
        └── Sleep
```

Useful Godot containers:

- `HBoxContainer`
- `VBoxContainer`
- `GridContainer`
- `MarginContainer`
- `CenterContainer`
- `PanelContainer`

This makes the UI easier to resize and maintain.

---

## Build One Theme Early

Create a single theme resource, for example:

```text
usapyon_theme.tres
```

Use it to define things like:

```text
UsapyonTheme
├── Button
│   ├── normal
│   ├── pressed
│   ├── disabled
│   ├── font
│   └── font_size
├── Panel
├── Label
├── ProgressBar
└── ...
```

This is much better than styling each button individually.

Later, you can create theme variations such as:

```text
Button
├── KawaiiButton
├── SmallButton
├── MenuButton
└── DangerousButton
```

Think of this like CSS component variants.

---

## Buttons: Generate the Theme, Draw the Icons

A good workflow is:

- Let **Claude Code** generate the Godot button theme / `StyleBoxFlat` setup
- Make the actual **icons yourself**
- Use real Godot `Button` nodes rather than baking every button into an image

Example button design:

```text
╭────────╮
│   🥕   │
│  Feed  │
╰────────╯
```

Custom assets can stay very small:

```text
icons/
├── carrot.png
├── ball.png
├── soap.png
├── moon.png
├── heart.png
└── coin.png
```

The actual button should still be a Godot `Button`.

Benefits:

- pressed states
- easy text changes
- resizing
- localization later
- global theme changes

> **Touch only.** The game is Android, portrait, fingers — there is no cursor to
> hover and no keyboard to focus. Do not style `hover` or `focus`, and never let
> a state be reachable only by hovering. Style `normal`, `pressed` and
> `disabled`; make `pressed` obvious, because a finger covers the button it is
> pressing. Tap targets must be thumb-sized.

---

## Example Theme Styling With StyleBoxFlat

Claude Code can generate styling like this:

```gdscript
var normal_style := StyleBoxFlat.new()

normal_style.bg_color = Color("#F8BBD0")
normal_style.corner_radius_top_left = 16
normal_style.corner_radius_top_right = 16
normal_style.corner_radius_bottom_left = 16
normal_style.corner_radius_bottom_right = 16

normal_style.content_margin_left = 14
normal_style.content_margin_right = 14
normal_style.content_margin_top = 10
normal_style.content_margin_bottom = 10

$Button.add_theme_stylebox_override("normal", normal_style)
```

Disabled state:

```gdscript
var disabled_style := normal_style.duplicate()
disabled_style.bg_color = Color("#EBD7DF")

.add_theme_stylebox_override("disabled", disabled_style)
```

Pressed state:

```gdscript
var pressed_style := normal_style.duplicate()
pressed_style.bg_color = Color("#F48FB1")

$Button.add_theme_stylebox_override("pressed", pressed_style)
```

Once you like the look, move these values into a real Godot `Theme` resource instead of keeping everything in code.

---

## Suggested First Color Palette

Example starter palette:

```text
Background     #FFF6F8
Primary Pink   #F7A8C4
Dark Pink      #D96C98
Cream          #FFF3D6
Text           #674C59
```

Later you can swap the entire palette through the theme instead of editing every screen manually.

---

## Use NinePatchRect for Cute Panels

For reusable panels, dialogue boxes, popups, and windows, use a `NinePatchRect`.

Instead of creating separate images for:

```text
small panel
medium panel
large panel
dialog panel
inventory panel
```

Create one texture and let Godot stretch the center while preserving the corners.

Conceptually:

```text
┌───┬─────┬───┐
│ ↖ │  ↑  │ ↗ │
├───┼─────┼───┤
│ ← │     │ → │
├───┼─────┼───┤
│ ↙ │  ↓  │ ↘ │
└───┴─────┴───┘
```

This is especially useful for:

- speech bubbles
- shop windows
- stat panels
- confirmation popups
- inventory panels
- menu windows

---

## What Should Be Custom Sprites?

Use custom art where the exact visual shape matters.

The Usapyon itself is **a layered rig, not one image per pose**. Expressions,
and later accessories and customization, swap a single part — otherwise every
new hat would mean redrawing every pose.

As built:

```text
assets/sprites/bunny/
├── body_base.png
├── ear_left.png
├── ear_right.png
├── face_neutral.png
├── eye_left_neutral.png
├── eye_left_closed.png
├── eye_right_neutral.png
└── eye_right_closed.png
```

New expressions are new part textures (another `face_*`, another `eye_*_*`),
swapped at runtime. Motion — bobbing, hopping, squash, ear pulls — comes from
animating the rig, not from extra frames. The master Photoshop file is in
[`psd/`](psd/).

UI art is separate, and is where flat images do belong:

```text
assets/sprites/ui/
├── heart.png
├── carrot.png
├── coin.png
├── sparkle.png
├── panel_9patch.png
├── button_9patch.png
└── speechbubble_9patch.png
```

---

## How Claude Code Fits In

Claude Code is useful for generating:

- `.tscn` scene structures
- `.gd` scripts
- reusable UI components
- theme setup
- `StyleBoxFlat` styling
- signals
- state synchronization
- save/load code
- tweens
- `AnimationPlayer` setup
- simple particles and reactions

A good prompt is specific and component-focused.

Example:

```text
Create a reusable StatBar scene in Godot.

Structure:
HBoxContainer
├── TextureRect icon
├── Label name
└── ProgressBar value

Expose:
@export var stat_name: String
@export var icon: Texture2D
@export var value: float

Add set_value() and animate value changes using a Tween.
```

Avoid asking it to generate the entire game UI in one huge scene.

Small, reusable components are easier to review and maintain.

---

## Using Claude for Animations

Claude works well for animations that can be expressed through:

- Tweens
- movement
- scaling
- rotation
- fading
- UI transitions
- `AnimationPlayer`
- particle effects

Examples:

- button bounce
- panel pop-in
- Usapyon happy hop
- idle bobbing
- shaking when hungry
- heart particles
- sparkle effects
- speech bubble appearing
- button squash when pressed

### Example: Button Bounce

```gdscript
func bounce_button(button: Control) -> void:
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)

    button.scale = Vector2(0.9, 0.9)
    tween.tween_property(button, "scale", Vector2.ONE, 0.18)
```

### Example: Usapyon Happy Hop

```gdscript
func happy_hop() -> void:
    var start_y = position.y

    var tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)

    tween.tween_property(self, "position:y", start_y - 18, 0.15)
    tween.tween_property(self, "position:y", start_y, 0.18)
```

Claude is less useful for drawing frame-by-frame animation itself.

A good split is:

### Claude / Code

- bobbing
- hopping
- squash/stretch
- shaking
- fades
- particles
- UI transitions

### Custom Art

- facial expressions
- eating poses
- sleeping pose
- food art
- decorative sprites
- exact character silhouettes

---

## Keep Game State Out of the UI

The UI displays state. It never owns it, and neither does the Bunny scene.

Avoid:

```gdscript
func _on_feed_button_pressed():
    hunger += 10
    happiness += 2
    update_ui()
    play_animation()
    save_game()
```

The authoritative state lives in a `GameState` autoload, with the rules for
changing it kept separate again. That split is defined in
[`../milestones/02-persistent-pet.md`](../milestones/02-persistent-pet.md) — read
it there rather than duplicating it here.

What matters for the UI:

```text
FeedButton
    ↓
calls a gameplay action
    ↓
GameState changes
    ↓
UI and Bunny react to the change
```

A button knows how to be pressed. It does not know what feeding does.

---

## Keep the First Version Small

Which stats and actions exist is not this document's call —
[`01-game-mechanics.md`](01-game-mechanics.md) defines them (Hunger,
Cleanliness, Happiness; sleep is automatic and has no button), and
[`../milestones/`](../milestones/) decides which of them are built when.

What *is* this document's call: build only the screens the current milestone
needs, and build them out of reusable pieces from the start.

```text
             ┌───────────┐
             │  Usapyon  │
             └─────┬─────┘
                   │
         stats slowly decrease
                   ↓
        ┌──────────────────┐
        │ Player chooses   │
        │ an action        │
        └────────┬─────────┘
                 ↓
           stat increases
                 ↓
        cute animation ✨
                 ↓
              repeat
```

---

## Recommended Workflow

```text
You decide the visual direction
        ↓
Claude Code creates reusable UI structure
        ↓
Godot Theme handles styling
        ↓
Containers handle layout
        ↓
Your artwork provides icons + Usapyon sprites
        ↓
Tweens / AnimationPlayer provide motion
```

A useful rule for the first version:

> **Keep the UI boring structurally and cute visually.**

Structurally:

```text
Containers
Reusable scenes
Signals
One Theme
Few screens
Few states
```

Visually:

```text
pastels
round shapes
tiny icons
chunky typography
bouncy animations
sparkles
Usapyon reactions
🌸🐰✨
```

---

## Project Layout

This is the layout the repo actually uses. Follow it; do not invent a parallel
structure.

```text
res://
├── scenes/          scenes and the scripts that belong to them, side by side
│   ├── main.tscn
│   ├── bunny.tscn
│   ├── bunny.gd
│   ├── ear.gd
│   └── eye.gd
│
├── autoloads/       one folder per global
│   ├── music.tscn
│   └── music.gd
│
├── assets/
│   ├── sprites/
│   │   ├── bunny/        the layered rig
│   │   ├── ui/           flat icons — carrot, coin, heart, cog …
│   │   └── background/   room art
│   ├── fonts/
│   └── audio/
│
└── docs/            design notes, milestones, plans (.gdignore'd)
```

Two things differ from the common Godot tutorial layout, on purpose:

- **Scripts live beside their scene**, not in a separate `scripts/` folder. A
  scene and its behaviour are one component.
- **`assets/`**, not `art/` — audio lives there too.

UI lives in `scenes/ui/` with its own scripts, and its art in
`assets/sprites/ui/`. Every sprite category is a folder under `assets/sprites/`;
`fonts/` and `audio/` sit beside it because they are not sprites. Add folders
only when something actually needs them.

---

## Recommended Balance

For the UI itself, a good target is roughly:

```text
90% Godot Controls + Theme
10% custom UI artwork
```

The game world and the Usapyon itself rely much more heavily on sprites.

The key idea is:

> **Claude Code builds the skeleton. Godot builds the layout. Your sprites give it personality.**
