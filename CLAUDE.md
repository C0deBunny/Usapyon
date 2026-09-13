# Usapyon

Cute mobile bunny pet game — Tamagotchi-adjacent but bond-focused, not survival-focused.
Godot 4.7 / GDScript, Android, portrait.

## Developer context

The developer is a **front-end developer with no game dev experience**. Godot's model
(scene tree, nodes, signals, frame loop) is unfamiliar; general programming is not.

When introducing a Godot concept, compare it to the web equivalent where that genuinely
helps. Don't explain general programming.

| Godot                             | Web equivalent                                           |
| --------------------------------- | -------------------------------------------------------- |
| Scene (`.tscn`)                   | Component — a reusable tree you instance                 |
| Node                              | DOM element, but typed (`Sprite2D`, `Area2D`, `Control`) |
| Script (`.gd`) attached to a node | The component's class/behaviour                          |
| Signal                            | Event listener / emitter                                 |
| `_process(delta)`                 | `requestAnimationFrame`                                  |
| `Tween` / `AnimationPlayer`       | CSS transitions / keyframe animations                    |
| `user://` files                   | localStorage                                             |
| `Control` + anchors/containers    | Flex/grid layout                                         |

Biggest mental shifts worth reinforcing: the **scene tree is the source of truth and the
editor edits it directly**, and **outside `Control` nodes there is no layout engine** —
positions are world coordinates you manage yourself.

## Godot / Android technicals

- **Renderer is GL Compatibility** (OpenGL ES3), chosen for cheap Android GPUs and battery.
  Don't propose Forward+/Mobile-renderer-only features (advanced 2D lighting, SDF GI,
  compute shaders).
- **Design resolution 1080×1920 portrait**, `stretch/mode=canvas_items`, `aspect=expand`.
  Build against that reference size; other aspect ratios gain extra space rather than
  letterboxing, so anchor UI instead of assuming exact pixel bounds.
- **Portrait-locked, touch-only.** No hover states, no keyboard/mouse-only input.
  Thumb-sized tap targets.
- **Save data goes to `user://`** (app-private storage on Android). `res://` is read-only
  in an exported build — never write to it at runtime.
- **Scenes are referenced by `uid://`**, not paths. Never hand-edit or invent a UID.
- `.tscn`/`.tres` are plain text and diffable, but the editor owns them. Hand-editing is
  fine for simple node setups; anything fiddly, tell the developer what to do in the editor.
- **Android export**: single preset `Android`, `arm64-v8a` only, non-gradle template,
  output `builds/usapyon-debug.apk`. `builds/` and `.godot/` are gitignored.
- **Claude cannot run the editor or see the game.** Anything visual or feel-related needs
  the developer to run it — say so explicitly and say what to look for.
- **But Claude can validate headlessly**, and should before claiming something works:
	```
	GODOT="/c/Users/denze/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
	"$GODOT" --headless --path "C:/Coding/usa-pyon" --import        # imports + parses scenes
	"$GODOT" --headless --path "C:/Coding/usa-pyon" --quit-after 120 # catches runtime errors
	```
	Godot is not on PATH. This catches broken scenes and script errors, not how it looks.

## Coding rules

- Simple concepts over clever ones. Readable beats compact.
- **Prefer built-in Godot features** — `Tween`, `AnimationPlayer`, signals, `Timer`,
  containers, `Area2D` input — over custom code that reimplements them.
- **Keep scripts small.** One script, one responsibility. If a script grows past roughly
  a screenful, that's a signal to split the scene, not to add regions.
- **Optimize for maintainability, not premature scalability.** No managers, registries,
  event buses, data-driven config layers or plugin systems until there is real pain.
- GDScript with static typing (`var speed: float = 200.0`) — catches errors and runs faster.
- `snake_case` for files, variables and functions; `PascalCase` for node names and classes.
- **Don't build ahead of the current milestone.** `Design/general.MD` sets the scope; the
  prototype is _bunny on screen → tap → it reacts_. No stats, save system, shop or
  minigames until asked for.

## Ask first

- Adding any plugin, addon or external dependency.
- Changing renderer, resolution or orientation in `project.godot`.
- Introducing a new architectural pattern (autoload singleton, state machine, resource-driven data).
