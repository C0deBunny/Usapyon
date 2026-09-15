# Usapyon — Design Docs

> **Nothing in this folder is a build instruction.**
> These are worked-out ideas, not tickets. What actually gets built, and in what
> order, is decided only in [`../milestones/`](../milestones/).

They also disagree with each other in places, because they were written at
different times. When they do:

1. **[`01-game-mechanics.md`](01-game-mechanics.md) wins** on anything about
   stats, care, progression, currency or naming. It is the settled systems
   design.
2. **[`archive/concept.md`](archive/concept.md) never wins.** It is the original pitch,
   superseded and trimmed to pointers.
3. **The repo wins over all of them** on how the project is actually laid out.

| Doc | Owns |
| --- | --- |
| [01-game-mechanics.md](01-game-mechanics.md) | Care stats, Care Points, Care Stars, garden, coins, cosmetics, naming. |
| [02-art-direction.md](02-art-direction.md) | Visual language, linework, palette, character rules. |
| [03-music-direction.md](03-music-direction.md) | Audio mood and instrumentation. |
| [04-ui-architecture.md](04-ui-architecture.md) | How UI is constructed — containers, theme, reusable scenes. Not which stats exist. |

Platform and engine constraints (portrait, touch-only, GL Compatibility, export
settings) live in `CLAUDE.md`, not here.

## Folders

- `reference/` — art reference images.
- `psd/` — the Photoshop source files, including the master rig.
- `archive/` — superseded docs, kept only for context. Nothing in here is
  current; [`concept.md`](archive/concept.md) is the original pitch.

None of it is imported by Godot; `docs/.gdignore` keeps the whole tree out of the
project.
