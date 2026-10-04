# Intro, dialogue and MusicManager

## Lifecycle

`project.godot` opens `scenes/boot.tscn`. The credit screen is silent: the singleton's two players are idle, with no desktop, mission or action-audio instance yet. The first fresh key/click/touch/gamepad button starts music synchronously, before any await.

Boot prepares the desktop behind the credits with all applications closed and `intro_pending` set. It owns:

| Phase | Presentation |
| --- | --- |
| TITLE | Credits / Press any key; no playback |
| FADE_OUT | Credits fade to black over 0.2 s |
| BLACK | Full darkness for 0.15 s |
| PORTRAITS | Player fades in over 0.3 s; 0.1 s pause; curator fades in over 0.3 s |
| DIALOGUE | First four manually advanced lines on black |
| DESKTOP_REVEAL | Desktop fades in behind the conversation over 1 s |
| DIALOGUE | Remaining briefing over the dimmed desktop |
| HANDOFF | Portraits/dialogue/dimming fade out over 0.25 s; background music requested |
| PLAY | Tools available, all applications initially closed |

The black curtain is CanvasLayer 95, above the desktop CRT (90). Intro presentation is at 100. Header, text and hint plates preserve contrast; the inactive portrait is darkened with RGB tint, not transparency. The idle voice timer starts only at handoff. Restart resets the mission without repeating the intro or resetting music/window state.

## Dialogue and portraits

`data/dialogues/intro.tres` is an editor-authored `DialogueSequence`: portrait textures, names, line dictionaries and the desktop-reveal index. Thirteen English lines introduce the trainee, mysterious curator, easy HR target, layoff order and Exposure. The first line is exactly **Wake the fuck up, samurai. We have asses to crack**. No password or paid clues are revealed.

`dialogue_playback.gd` owns the cursor and reveal barrier as a RefCounted logic object. `intro_dialogue.gd` projects its signals into a skippable typewriter and speaker portraits. Any fresh button completes printing; the next press advances. Motion, scroll, releases and keyboard echo do not confirm. Holding `dialogue_fast_forward` (Space) for 0.3 s boosts typing 8× and advances completed lines at 0.12 s intervals. Release restores normal speed; focus loss clears held input. Fade durations stay intact.

The entry key and keys still held at handoff are suppressed until release. During the briefing, input interception and main-level guards prevent tool/recon/run actions and risk spending.

Transparent portraits in `assets/portraits/` derive from the untouched JPGs in `assets/exp/`. The authoring tool removes magenta and side-code panels, decontaminates narrow outline spill, aligns faces and feathers the lower bust. Self-portrait uses `player-icon.png`. See the portraits README for offline rebuild dependencies.

## Editor-driven MusicManager

The Autoload is **a scene**, `scenes/audio/music_manager.tscn`. Select its root to edit the exported `cues: Array[MusicCue]`:

- `data/audio/intro.tres`: id `intro`, **Sycophant**, repeat enabled.
- `data/audio/background.tres`: id `background`, **Hackers → New Beginnings → The Saga**, repeat enabled.

MusicCue exports ID, `Array[AudioStream]`, repeat, track crossfade and cue-entry transition durations. Files/order are Inspector inputs, not script constants. Default overlap is 0.75 s; the background cue's entry crossfade is 1.5 s. Native MP3 looping is disabled; resources are never mutated at runtime.

```gdscript
MusicManager.play_cue(&"intro")       # Accepted entry gesture.
MusicManager.play_cue(&"background")  # Conversation ends / handoff begins.
```

Sycophant covers the entire conversation, including the desktop portion, repeating if necessary. A new cue requested during an existing two-player overlap is queued until that overlap completes, avoiding abrupt cuts.

The manager persists independently of scenes and runs while the tree is paused. It uses equal-power sine/cosine gains. Music toggles pause/resume both players and their tween; Mute silences without stopping the clock; master level is clamped to 0–1 and zero is true silence. Main listens to `changed`, synchronizing taskbar preferences and scene-local action effects. Defaults: level 0.35, music trim -8 dB. Music/SFX route separately through `default_bus_layout.tres`. Repeated cue calls are idempotent.

## Hidden-window reflow

Hidden Containers do not complete wrapped-text layout. The manager briefly lays windows out with the whole group at zero opacity, assigns widths, waits four frames, fixes sizes and restores authored visibility. No application is visually shown. `layout_ready` gates early requests. This prevents cached zero-width minimum heights from stretching windows to maximum height on first opening.

## Verification

Startup/audio tests drive real viewport input: silence/configuration, exact quote, portrait order, three resolutions, manual/held input, reveal barrier, closed applications and handoff quarantine. Real MP3 seeks test Sycophant repeat, cue handoff, background wrap, paused overlap, mute/zero level, finished fallback and singleton survival after scene destruction. Desktop smoke waits for layout readiness and then manually opens the initially closed applications.

Both graphical suites have a 45-second failure watchdog. The CLI frame limit also bounds failures before test initialization:

```text
godot --path . --max-fps 60 --quit-after 3000 --script res://tests/startup_audio.gd -- --capture-dir=<existing directory>
godot --path . --max-fps 60 --quit-after 3000 --script res://tests/ui_smoke.gd -- --capture-dir=<existing directory> --webp
```

WebP captures stay outside the repository. Native Windows verified; browser and standalone-export audio have not been exercised.
