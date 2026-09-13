# Decisions: Background music

## 1. Loop the whole track, fade-out included

- **Date:** 2026-09-13
- **Considered:** ship the fade-and-restart as-is · trim the 0.4 s lead-in and the ~3 s
  fade and loop the musical body · crossfade the tail into the head with two players ·
  re-generate the track loop-safe from the start
- **Chosen:** ship as-is — the track is not a loop (it fades to the noise floor over its
  last three seconds), and every fix carries uncertainty that shipping does not. Trimming
  only sounds right if the last bar happens to resolve into the first, which nobody has
  verified by ear. A code crossfade always smooths the seam but never makes it musical.
  Re-generating depends on the generator cooperating. Shipping the honest version puts
  the question in front of ears instead of in front of guesses.
- **Trade-off:** roughly 3.5 s of near-silence every two minutes, which will read as a
  bug to anyone who did not make this decision. Reversal is cheap and code-free — one
  re-encode (`-ss 0.4 -t 116`) plus a listen at the seam — so this is a decision that can
  be revisited the moment it grates, and should be.

## 2. Convert to Ogg Vorbis; do not keep the WAV master

- **Date:** 2026-09-13
- **Considered:** Ogg Vorbis · keep the WAV and apply QOA compression on import · keep
  the raw 22 MB WAV. And separately for the master: move it to the gitignored `design/` ·
  commit it alongside the Ogg · delete it
- **Chosen:** Ogg Vorbis, master deleted — 21.9 MB became 1.59 MB, about 107 kbps for
  48 kHz stereo. Godot keeps an imported Ogg compressed in memory and
  decodes during playback, so the resident cost tracks the file rather than expanding to
  22 MB of PCM, which matters on the cheap Android hardware the GL Compatibility renderer
  is chosen for. It also keeps a 22 MB binary out of git history permanently.
- **Trade-off:** lossless is gone, and nobody A/B'd the encode against the master before
  it was deleted. Any future re-encode — including the trim in decision 1 — starts from
  the Ogg, making it a second-generation lossy encode. At ~107 kbps on soft music-box
  material that is unlikely to be audible, but it is a one-way door already walked
  through.

## 3. A `Music` autoload, not a node in `main.tscn`

- **Date:** 2026-09-13
- **Considered:** an `AudioStreamPlayer` sitting beside `ColorRect` and `Bunny` in
  `main.tscn` · a global autoload singleton
- **Chosen:** the autoload — music that survives scene changes without restarting is the
  behaviour wanted the moment a title screen or a minigame exists, and retrofitting it
  later means moving the node, moving the script, and re-testing the fade.
- **Trade-off:** this is explicitly building ahead of a need that does not exist — there
  is exactly one scene today, so nothing can interrupt the music either way. `CLAUDE.md`
  requires asking before adding an autoload, and the lighter option was on the table and
  declined. The cost is a global, a new folder, and a volume knob that no longer lives
  where you are looking when you open `main.tscn`.

## 4. A dedicated `Music` bus, not straight to Master

- **Date:** 2026-09-13
- **Considered:** route the player to Master and put volume on the node ·
  create `default_bus_layout.tres` with a `Music` bus
- **Chosen:** the dedicated bus — it is where music-versus-SFX balance and a music-only
  mute will have to live, and the file has to exist before either is possible.
- **Trade-off:** another build-ahead call. Right now the bus does nothing that Master
  would not do, it is one more resource file to keep consistent, and it introduces a
  silent failure mode: a name mismatch falls back to Master and still sounds correct.
  Adding the bus later would have been a two-minute editor job that broke nothing.

## 5. Fade in over 1.5 s rather than plain `autoplay`

- **Date:** 2026-09-13
- **Considered:** tick `autoplay` in the inspector and write no script at all · tween
  `volume_db` up from silence on `_ready()`
- **Chosen:** the fade — a cold start straight into music is harsh on an app whose whole
  identity is cozy, and the track itself starts with only 0.4 s of silence to soften it.
- **Trade-off:** the node needs a script it would otherwise not have, which is what makes
  decision 6 possible at all. More consequentially, the tween overwrites `volume_db`
  within a frame of `_ready()`, so the inspector field stops being the volume control and
  a separate `@export var target_volume_db` has to become the real knob. That indirection
  is the actual price of the fade, and it is the kind of thing that wastes twenty minutes
  the first time someone tunes the volume and hears nothing change.

## 6. Public `fade_in()` / `fade_out()` rather than fire-and-forget

- **Date:** 2026-09-13
- **Considered:** no public API — the autoload just starts and loops forever · public
  fade methods for future callers
- **Chosen:** the public methods — a sleep interaction or a minigame will want to hand
  off cleanly, and the tween machinery is already there for the launch fade.
- **Trade-off:** `fade_out()` has no caller on the day it is written, and an API shaped
  for an imagined caller usually fits the real one badly. If nothing calls it by the time
  the next feature lands, delete it rather than carrying it.

## 7. `autoloads/`, not flat in `scenes/`

- **Date:** 2026-09-13
- **Considered:** `scenes/music.tscn` alongside `bunny.tscn` and `main.tscn` ·
  a new `autoloads/` folder · a script-only autoload with no scene at all
- **Chosen:** `autoloads/music.tscn` — a global service is a different kind of thing from
  a node you instance into a tree, and putting the singleton in the same drawer as the
  bunny's body parts blurs that. Script-only was rejected separately: it would hardcode
  the stream, bus and volume in GDScript instead of leaving them as inspector fields.
- **Trade-off:** a folder holding exactly one thing, and a second place to look for
  scenes. Only pays off if a second autoload ever appears.

## 8. The loop flag is set in the editor, not in code or a hand-edited `.import`

- **Date:** 2026-09-13
- **Considered:** tick **Loop** in the FileSystem Import tab · hand-edit
  `Usapyon_main.ogg.import` to `loop=true` after a headless import · set `stream.loop =
  true` in `_ready()`
- **Chosen:** the editor — `.import` files are the editor's to own, and the code option
  is worse than it looks: it mutates a shared resource at runtime and leaves the import
  setting silently disagreeing with the script, which is exactly the discrepancy that
  costs an hour in six months.
- **Trade-off:** a manual step outside version control's view, and one that fails
  silently — if it is skipped, the music simply stops after two minutes with no error
  anywhere. It cannot be verified headlessly; it has to be confirmed by ear.

## 9. `target_volume_db` starts at 0.0, not attenuated

- **Date:** 2026-09-13
- **Considered:** −6 dB, the usual reflex for background music · 0.0 dB, no attenuation
- **Chosen:** 0.0 dB — measurement beats reflex. The track peaks around −13 dBFS where
  mastered game music usually sits near −2, so it is already roughly 10 dB quieter than a
  normal asset. Attenuating on top of that would bury it under a phone speaker.
- **Trade-off:** decided from sample measurements, not from listening. If it turns out
  loud in practice the fix is one exported field — but note that 0.0 dB is the ceiling
  for this design, so if it ever needs to be *louder*, the track has to be re-mastered
  rather than turned up.

## 10. Defer the Android backgrounding handler until a device test

- **Date:** 2026-09-13
- **Considered:** write the `NOTIFICATION_APPLICATION_PAUSED` / `_RESUMED` handler up
  front · install the APK, background it, and listen first
- **Chosen:** test first — whether Godot already suspends audio when the Android activity
  pauses is genuinely unknown here and cannot be determined without a device. Writing a
  handler against an unconfirmed bug is four lines of code defending a guess.
- **Trade-off:** the first build carries a real chance of playing music from a pocket,
  which is a bad first impression if anyone else sees it before the test happens. The fix
  is small and well understood — the `NOTIFICATION_APPLICATION_FOCUS_OUT` handling in
  `scenes/eye.gd` and `scenes/ear.gd` is the same shape.
