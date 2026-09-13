# Progress: Background music

<!-- Living log. Append newest entries at the top:
     ## YYYY-MM-DD
     - Did: <what changed> (<sha>)
     - Verified: <how>
     - Next: <what remains> / Blocked: <on what>
-->

## 2026-09-13 (1)

- Did: the prerequisite sprite move landed first as its own commit (`c1bfb67`) — the
  eight texture paths in `bunny.tscn` were rewritten from `res://assets/bunny/` to
  `res://assets/sprites/bunny/` by hand rather than waiting for the editor to do it, so
  the rename shows up in git as a clean `R` with no path churn left to land in this
  commit.
- Did: added `autoloads/music.gd` and `autoloads/music.tscn`, and registered
  `Music="*res://autoloads/music.tscn"` in `project.godot`. `assets/audio/Usapyon_main.ogg`
  got its generated `.import`. Nothing under `scenes/` was touched.
- Deviated from the plan on one point: `fade_out()` also sets `stream_paused = true`
  once the fade completes, and `fade_in()` clears it and calls `play()` if the player is
  stopped. The plan described the fades as volume-only, which would have left the track
  decoding inaudibly forever after a fade-out. The pause runs from a `tween_callback`, so
  killing the tween — which `_fade_to()` does before every new fade — also cancels the
  pending pause, and a fade-in interrupting a fade-out cannot leave the player silently
  paused.
- Verified by temporary instrumentation in `_ready()`, since a clean headless exit proves
  nothing about whether the script ran: the stream resolves to
  `AudioStreamOggVorbis(res://assets/audio/Usapyon_main.ogg)`, playback starts at
  `-40 dB`, and after 2 s `volume_db` is `0.0` with playback position `1.95` — so the
  fade completes and the audio is genuinely advancing. `fade_out(0.5)` then reaches
  `-40 dB` with `paused=true`, and `fade_in(0.5)` returns to `0.0` with `paused=false`
  and `playing=true`. Instrumentation removed; final `--quit-after 400` run has no script
  errors.

### Two findings from the validation runs

- **The `Music` bus does not exist yet, and the fallback is silent.** `music.tscn` sets
  `bus = &"Music"`, but the instrumented run reported `bus=Master`: Godot quietly
  substituted Master rather than warning. The plan predicted this failure mode; it is
  worth recording that it produces *no* diagnostic at all. Consequence for whoever does
  the editor work: **create the bus before opening `music.tscn` in the editor.** Opening
  and saving that scene while the bus is missing risks Godot persisting `&"Master"` into
  the file, turning a temporary fallback into a permanent one.
- **The autoload leaks four objects at exit.** Every headless run now ends with
  `4 ObjectDB instances were leaked at exit` and `2 resources still in use at exit`.
  Investigated rather than accepted on sight: removing the autoload from `project.godot`
  makes the run clean again, so it is definitely ours. `--verbose` names all four —
  `AudioStreamOggVorbis`, `OggPacketSequence`, `AudioStreamPlaybackOggVorbis`,
  `OggPacketSequencePlayback` — which is the stream and its playback, none of our own
  objects. The count is constant at 4 across 300-, 400- and 1200-frame runs, so it is not
  growing; and it still appears with the fade removed entirely, so the `Tween` is not
  involved. `stop()` in `_exit_tree()` does not clear it, nor does `stop()` plus
  `stream = null` — the reference is held above us, by the cached imported resource. Left
  alone: it is shutdown ordering, it costs nothing on Android where quit is process
  death, and the fixes attempted were worse than the noise. **Recorded here because it
  now pollutes the headless baseline** — a future session running the `CLAUDE.md`
  validation commands will see these two lines and should not read them as a regression.
- Next, and none of it is doable from outside the editor:
  1. **Create the `Music` bus** — bottom Audio panel, Add Bus, rename to `Music`. Do this
     first, before opening `music.tscn`. Then confirm the Music strip actually moves
     during playback; if it stays flat, the player is still on Master.
  2. **Tick Loop** on `Usapyon_main.ogg` in the Import tab and Reimport. Currently
     `loop=false`. Without it the music stops dead after 119 s with no error anywhere.
  3. **Listen past the two-minute mark** — this is the only way to confirm both 1 and 2,
     and the only way to judge whether the ~3.5 s fade-out lull is tolerable
     (`decisions.md` 1).
  4. **Judge `target_volume_db`** through a phone speaker. It is set to `0.0` from
     measurement, not from anyone hearing it (`decisions.md` 9).
  5. **Background the app on a device** and listen, to settle `decisions.md` 10.
