# Usapyon

Cute mobile pet game — Tamagotchi-adjacent, but progression comes from the
*quality* of daily care rather than from keeping the pet alive.
Godot 4.7 / GDScript, Android, portrait.

"Usapyon" is the game and the species. The creature is **a Usapyon** — never a
pet named Usapyon. Player-facing text says "your Usapyon".

## Where the docs live

| Question | File |
| --- | --- |
| What is already built? | `docs/milestones/01-interactive-bunny.md` |
| What am I building now? | `docs/milestones/02-persistent-pet.md` |
| How does a system work? | `docs/design/01-game-mechanics.md` |
| How is the UI built? | `docs/design/04-ui-architecture.md` |
| How should art/music look? | `docs/design/02-art-direction.md`, `03-music-direction.md` |
| How do builds, saves and testing work? | `docs/conventions.md` |

Milestones are the only build authority. `docs/design/` is thinking, not
instructions — see `docs/design/README.md`.

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
  When adding a node or a script reference by hand, omit `uid=` on the `ext_resource` and
  omit `unique_id=` on new nodes — Godot resolves the script by path and fills both in on
  next save. For a script it generates a `.gd.uid` file; commit it alongside the `.gd`.
- `.tscn`/`.tres` are plain text and diffable, but the editor owns them. Hand-editing is
  fine for simple node setups; anything fiddly, tell the developer what to do in the editor.
  When hand-editing, `script` is a **property line**, not a node-header attribute:
	```
	[node name="Bunny" type="Node2D"]
	script = ExtResource("9_bunny")
	```
	Godot silently ignores unknown header attributes — no import error, no runtime error,
	the script simply never runs.
- **Android export**: single preset `Android`, `arm64-v8a` only, non-gradle template,
  output `builds/usapyon-debug.apk`. `builds/` and `.godot/` are gitignored.
- **Claude cannot run the editor or see the game.** Anything visual or feel-related needs
  the developer to run it — say so explicitly and say what to look for.
- **But Claude can validate headlessly**, and should before claiming something works:
	```
	GODOT="/c/Users/denze/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
	"$GODOT" --headless --path "C:/Coding/usa-pyon" --import        # imports + parses scenes
	"$GODOT" --headless --path "C:/Coding/usa-pyon" --quit-after 120 # catches runtime errors
	```
	Godot is not on PATH. Both commands exit 0 on a scene whose script was never attached —
	they prove the scene parses and nothing throws, not that the code ran. To verify
	behaviour, add a temporary `print()`, run, read the output, then remove it.

	`--quit-after N` counts **frames** and runs at roughly real time headless (1800 frames
	≈ 14s), so size it to the timing you need to observe. Don't wrap the run in `timeout` —
	killing the process discards buffered stdout and the prints vanish.

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
- **Don't build ahead of the current milestone.** `docs/milestones/` sets the scope; the
  prototype is _bunny on screen → tap → it reacts_. No stats, save system, shop or
  minigames until asked for.

## Ask first

- Adding any plugin, addon or external dependency.
- Changing renderer, resolution or orientation in `project.godot`.
- Introducing a new architectural pattern (autoload singleton, state machine, resource-driven data).
