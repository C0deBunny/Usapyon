# Plan: Background music

## Goal

Music plays from the moment the app opens and keeps playing unattended, so the bunny
is no longer sitting in silence. One track, fading in gently at launch, looping on its
own for as long as the app is open.

Nothing about the bunny changes. This is a layer added beside the existing prototype,
not a change to it.

## Non-goals

- **No mute, no volume slider, no settings screen.** There is no UI in the game at all
  yet; adding audio does not change that.
- No sound effects. No tap squeak, no ear-pull sound, no reaction of any kind. The
  bunny and the music are unaware of each other.
- No ducking, no layering, no music that responds to what the bunny is doing.
- No seamless loop. See `decisions.md` 1 — a deliberate, reversible call, not something
  left undone by accident.
- No pause-on-backgrounding handler. See `decisions.md` 10.

## Context

Read `CLAUDE.md` first — the GL Compatibility renderer, the ask-first rules, the
`uid://` handling and the headless validation commands all apply and are not repeated
here.

**The project has no audio of any kind today.** There is no `default_bus_layout.tres`,
no `[autoload]` section in `project.godot`, and no `AudioStreamPlayer` anywhere.
`scenes/main.tscn` is a `Control` holding a `ColorRect` background and one `Bunny`
instance, and that is the entire scene tree. Everything here is new construction;
nothing has to be untangled first.

**The asset** is `assets/audio/Usapyon_main.ogg` — Ogg Vorbis, 48 kHz stereo,
**119.46 s**, 1.59 MB. Measured properties that matter:

- It opens with roughly **0.4 s of near-silence** before the music starts.
- It **fades out over the last ~3 s**, reaching the noise floor by the end. Peak
  amplitude runs −18 dBFS at 1 s, −13 dBFS mid-track, −25 dBFS at 117 s, −44 dBFS at
  119 s. This is a track with an ending, not a loop.
- It is mastered **quietly** — peaks around −13 dBFS where game music typically sits
  near −2 dBFS. That directly drives the starting volume; see `decisions.md` 9.

It was converted from a 21.9 MB WAV master which has since been deleted. Godot holds
an imported Ogg as compressed data in memory and decodes it during playback, so the
resident cost is roughly the 1.6 MB file rather than the 22 MB of PCM a `.wav` would
have expanded to.

**Prerequisite, unrelated to this feature.** The working tree currently carries an
uncommitted move of the bunny sprites from `assets/bunny/` to `assets/sprites/` — 16
deletions plus an untracked `assets/sprites/`, with `scenes/bunny.tscn` still listing
`res://assets/bunny/...` on every texture. Those resolve through their UIDs so nothing
is broken, but Godot will rewrite the path strings the next time that scene is saved.
Land that move as its own commit **before** starting here, so the path churn does not
end up mixed into the music commit.

## Approach

A `Music` autoload owns a single `AudioStreamPlayer` and does nothing else.

The autoload is a **scene**, not a bare script, so the stream, the bus and the starting
volume stay inspector fields you can click rather than constants buried in GDScript. It
lives in a new `autoloads/` folder to keep a global service visually separate from the
scene-tree nodes in `scenes/` (`decisions.md` 7).

Looping is the **stream's own responsibility**, not the script's. With `loop` ticked on
the Ogg's import settings, `AudioStreamPlayer.play()` loops forever with no `finished`
signal handling, no `_process`, and nothing to keep in sync. The script's only job is
the fade.

`_ready()` sets `volume_db` to a silent floor, calls `play()`, and tweens `volume_db` up
to `target_volume_db` over `fade_duration`. Because the tween overwrites `volume_db`
immediately, that inspector field is *not* the volume knob — `target_volume_db` is,
which is why it exists as a separate `@export`. `autoplay` on the player must stay
**off**: the script calls `play()` itself, and setting both starts the stream twice.

`fade_in()` and `fade_out()` are public so a future sleep interaction or minigame can
hand off cleanly (`decisions.md` 6). They share one tween reference, killed before each
new fade, so a fade-out interrupted by a fade-in does not leave two tweens fighting over
the same property.

Three of these choices — the autoload, the dedicated bus, the fade — deliberately take
the heavier side of a build-ahead trade that `CLAUDE.md` normally warns against. Each
was chosen knowingly with the lighter alternative on the table; see `decisions.md` 3, 4
and 5. A future reader should not "simplify" them back on the assumption they were
unconsidered.

## Components

- **`assets/audio/Usapyon_main.ogg`** *(exists)* — needs **Loop** ticked in the editor's
  Import tab, then Reimport. A manual step; see Risks.
- **`autoloads/music.tscn`** *(new)* — an `AudioStreamPlayer` root named `Music`, with
  `stream` set to the Ogg, `bus` set to `"Music"`, and `autoplay` **off**.
- **`autoloads/music.gd`** *(new)* — attached to that root. Exports
  `target_volume_db: float = 0.0` and `fade_duration: float = 1.5`. Owns `_ready()`
  (play + fade in) and the public `fade_in(duration)` / `fade_out(duration)`. Should stay
  well under a screenful; if it grows, something has been added that does not belong to
  it.
- **`default_bus_layout.tres`** *(new, created in the editor)* — Master plus a `Music`
  bus routed to it. Made via the bottom **Audio** panel rather than hand-written, so the
  editor owns its own resource format — the same reasoning as `decisions.md` 8.
- **`project.godot`** — gains `[autoload]` with `Music="*res://autoloads/music.tscn"`.
- **`scenes/main.tscn`, `scenes/bunny.tscn`, and all three `.gd` files under `scenes/`** —
  untouched. The bunny does not know music exists.

## Risks

- **The loop tick is a silent failure.** If `loop` is not enabled on the Ogg's import
  settings, the track plays once, stops after two minutes, and never restarts — no
  error, no warning, nothing in the headless output. Both validation commands in
  `CLAUDE.md` still exit 0. It cannot be verified from outside the editor, so it has to
  be confirmed by listening past the two-minute mark. This is the most likely way this
  feature ships broken.
- **Bus name mismatch.** If the player's `bus` is `"Music"` but no bus by that name
  exists, Godot warns and falls back to Master. The audible result is *correct music*,
  which is exactly why it goes unnoticed — create the bus before wiring the player, and
  check that the Audio panel's Music strip actually moves during playback.
- **The two-minute lull reads as a bug.** The track fades to silence and restarts,
  leaving roughly 3.5 s of near-nothing every loop. This was chosen, but nobody hearing
  it for the first time will know that. Reversing it is one re-encode (`-ss 0.4 -t 116`
  or the Audacity equivalent) plus a re-listen at the seam — no code changes.
- **`volume_db` in the inspector is a decoy.** `_ready()` overwrites it within a frame.
  Anyone tuning volume by editing that field sees no effect and concludes the audio is
  broken. `target_volume_db` is the knob, and it lives in the autoload scene rather than
  in `main.tscn`, so it is not where you would instinctively look.
- **Android backgrounding is unverified.** Whether music keeps playing with the phone in
  a pocket is genuinely unknown and cannot be tested from outside a device. Deferred
  rather than guessed at (`decisions.md` 10). The fix, if needed, is a `_notification`
  handler toggling `stream_paused` — the same shape as the
  `NOTIFICATION_APPLICATION_FOCUS_OUT` handling already in `scenes/eye.gd:75` and
  `scenes/ear.gd:99`.
- **`fade_out()` has no caller.** It is dead code the day it is written, by design.
  Accepted as part of `decisions.md` 6 — but if no caller has appeared by the time the
  next feature lands, delete it rather than carrying it.

## Open questions

- **Is 0.0 dB right?** The starting value is reasoned from the track's measured peak
  level, not from anyone hearing it. It needs judging through a phone speaker, which is
  the only output that matters here. Tune `target_volume_db` down if it dominates.
- **Is the two-minute lull actually tolerable?** Unanswerable until it has been lived
  with for more than one loop.
- **Does the music keep playing when the app is backgrounded?** Device test.
- **Is 1.5 s the right fade?** The track's own 0.4 s of lead-in silence sits inside that
  window, so the perceived fade is shorter than the number suggests.
