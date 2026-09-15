# Usapyon — Project Conventions

How the project always works, regardless of which milestone is in progress.
Milestone docs describe *what* to build; this describes the rules they all
share.

Engine, renderer, resolution and coding style live in `CLAUDE.md`.

------------------------------------------------------------------------

## Debug and release builds

The same codebase produces both builds. Development tooling is compiled in but
gated on `OS.is_debug_build()`, so it never reaches a player.

```text
ONE CODEBASE
      │
      ├───────────────┐
      ▼               ▼
 Debug Export      Release Export
      │               │
 DebugPanel ✅       DebugPanel ❌
 Debug Save ✅       Real Save ✅
 Testing tools ✅    Player build ✅
```

### Save file separation

Development and test data never touch real player data:

| Build | Save file |
| --- | --- |
| Debug | `user://savegame_debug.json` |
| Release | `user://savegame.json` |

The development build can then hold deliberately strange test states — a
starving Usapyon, a save dated three weeks ago — without contaminating real
progression.

`user://` is app-private storage on Android. `res://` is read-only in an
exported build; never write there at runtime.

------------------------------------------------------------------------

## Testing

Use both desktop and a real Android phone. They catch different things, and
neither substitutes for the other.

### Desktop — for fast iteration

- Game state and stat logic
- Save and load behaviour
- Debug controls and presets
- UI layout and structure
- Anything you want to re-run twenty times in a minute

### The phone — for anything that touches reality

- Touch interactions and multitouch
- Whether tap targets are actually thumb-sized
- Performance and battery
- Audio
- Android lifecycle: backgrounding, interruption, saving on close
- Long-term playtesting

The rule of thumb: **if a finger, the OS, or the passage of real time is
involved, it is not verified until it has run on the phone.**

Keep one persistent development save on the phone. It reveals pacing problems
that injected mock data never will.

### Headless validation

Claude cannot run the editor or see the game, but can check that the project
still parses and does not throw — see the commands in `CLAUDE.md`. Both exit 0
on a scene whose script was never attached, so they prove the project loads,
not that the code ran. To verify behaviour, add a temporary `print()`, run it,
read the output, then remove it.

Anything visual or feel-related needs you to run it, and the doc or message
should say so explicitly and say what to look for.
