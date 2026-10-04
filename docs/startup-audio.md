# Intro, dialogue and MusicManager

## Lifecycle

`project.godot` opens `scenes/boot.tscn`. The credit screen is silent: the singleton's two players are idle, with no desktop, mission or action-audio instance yet. The first fresh key/click/touch/gamepad button starts music synchronously, before any await.

Boot prepares the desktop behind the credits with all applications closed and `intro_pending` set. It owns:

| Phase | Presentation |
| --- | --- |
| TITLE | Credits / Press any key; no playback |
| FADE_OUT | Credits fade to black over 0.2 s |
| BLACK | Full darkness for 0.15 s |
| PORTRAITS | Curator's connection window fades in over 0.3 s; text panels appear over 0.18 s |
| DIALOGUE | First four manually advanced lines on black; player fades in with their first reply |
| DESKTOP_REVEAL | Desktop fades in behind the conversation over 1 s |
| DIALOGUE | Remaining briefing over the dimmed desktop |
| HANDOFF | Portraits/dialogue/dimming fade out over 0.25 s; background music requested |
| PLAY | Tools available, all applications initially closed |

The black curtain is CanvasLayer 95, above the desktop CRT (90). Dialogue presentation is at 100; the final campaign summary is at 110. Two opaque text windows retain each speaker's last message, while titlebar accents mark the active speaker. Portrait height is capped at 320 px; the curator's connection window rises above the shared actor baseline. The taskbar has a reserved lower lane. Idle commentary pauses during briefings/debriefs. Target transitions retain music/window state; return to title clears campaign progress and stops playback, and the next game repeats the intro.

## Dialogue and portraits

Dialogue Manager **v4.1.0 for Godot 4.7** is installed under `addons/dialogue_manager` and enabled in `project.godot`. It owns importing, parsing, traversal, branching, conditions and mutations. The source is pinned, with MIT license and archive checksum in `UPSTREAM.json`. A documented one-line compatibility patch copies runtime line dictionaries, preventing the upstream resource self-reference cycle and mutation of imported source data; see `PATCHES.md`.

`data/dialogues/intro.dialogue` contains thirteen English lines, editable in the plugin's Dialogue tab. The first line is exactly **Wake the fuck up, samurai. We have asses to crack**. No password or paid clues are revealed. `$> Narrative.present("desktop_reveal")` marks the reveal after the fourth line; moving this command moves the reveal without changing code or line counts.

`intro.tres` is now a `DialogueEntry`, linking the imported dialogue, start cue, character resources, presentation preset, music IDs and presentation-cue-to-animation map. Character resources own names, slots and expression textures. `presentation.tres` owns dimensions and typing/fast-forward settings; `assets/ui/dialogue_theme.tres` owns chrome and fonts. `AnimationPlayer` clips own fade timings in the balloon and boot scenes.

The player character resource enables `reveal_on_first_line` and names `player_enter` as its first-line animation. The curator is present at entry; the player's portrait and complete text window (frame, name and body) remain invisible throughout the opening quote and fade in together at their first spoken line, independently of line indices. Offered responses also reveal their associated player presentation together. A separate PortraitAnimationPlayer prevents reveal animation from interrupting cinematic waits or being interrupted by ordinary line changes.

The boot-scoped `DialogueDirector` holds one active session and delegates traversal to `DialogueResource.get_next_dialogue_line()`. Its `DialogueStateContext` exposes the alias `Narrative`. It awaits presentation animations and rejects concurrent/invalid starts. Generation guards and cancellation release pending animation waits. `intro_dialogue.gd` is a custom plugin balloon using native `DialogueLabel` and `DialogueResponsesMenu`, not a second parser or graph engine.

Any fresh button completes printing; the next press advances. Motion, scroll, releases and keyboard echo do not confirm. Holding `dialogue_fast_forward` (Space) for 0.3 s boosts typing 8× and advances completed lines at 0.12 s intervals. Release restores normal speed; focus loss clears held input. Fast-forward never selects responses or bypasses cinematic waits. Long text retains readable type and scrolls with the wheel. The configured custom balloon also runs from the plugin's editor preview.

`CampaignGoal` resources export before/after DialogueEntry references. A successful mission freezes its result and shows MARK / SUBMIT RESULT. Only submission starts the after-dialogue, followed by the next target's briefing or the grade-specific ending and summary. `Campaign.final_mark` is exposed through a scene-scoped DialogueStateContext. TRACE offers GAME OVER / RETURN TO TITLE. The generic `dialogue_requested` signal remains available for auxiliary conversations. See [campaign](campaign.md) and [dialogue authoring](dialogue-authoring.md).

The entry key and keys still held at handoff are suppressed until release. During the briefing, input interception and main-level guards prevent tool/recon/run actions and risk spending.

Transparent portraits in `assets/portraits/` derive from the untouched JPGs in `assets/exp/`. The authoring tool removes magenta and side-code panels, decontaminates narrow outline spill, aligns faces and feathers the lower bust. Self-portrait uses `player-icon.png`. See the portraits README for offline rebuild dependencies.

## Editor-driven MusicManager

The Autoload is **a scene**, `scenes/audio/music_manager.tscn`. Its ready instance registers under `Engine` as `MusicManager`; consumers resolve a Node reference with `Engine.get_singleton("MusicManager")`. They do not depend on a compile-time Autoload identifier, which can be unavailable during editor configuration reload or isolated CLI compilation. Only the owning instance unregisters it on shutdown. Select its root to edit the exported `cues: Array[MusicCue]`:

- `data/audio/intro.tres`: id `intro`, **Sycophant**, repeat enabled.
- `data/audio/background.tres`: id `background`, **Hackers → New Beginnings → The Saga**, repeat enabled.

MusicCue exports ID, `Array[AudioStream]`, repeat, track crossfade and cue-entry transition durations. Files/order are Inspector inputs, not script constants. Default overlap is 0.75 s; the background cue's entry crossfade is 1.5 s. Native MP3 looping is disabled; resources are never mutated at runtime.

```gdscript
var music: Node = Engine.get_singleton("MusicManager")
music.play_cue(&"intro")       # Accepted entry gesture.
music.play_cue(&"background")  # Conversation ends / handoff begins.
```

Sycophant covers the entire conversation, including the desktop portion, repeating if necessary. A new cue requested during an existing two-player overlap is queued until that overlap completes, avoiding abrupt cuts.

The manager persists independently of scenes and runs while the tree is paused. It uses equal-power sine/cosine gains. Music toggles pause/resume both players and their tween; Mute silences without stopping the clock; master level is clamped to 0–1 and zero is true silence. Main listens to `changed`, synchronizing taskbar preferences and scene-local action effects. Defaults: level 0.35, music trim -8 dB. Music/SFX route separately through `default_bus_layout.tres`. Repeated cue calls are idempotent.

## Hidden-window reflow

Hidden Containers do not complete wrapped-text layout. The manager briefly lays windows out with the whole group at zero opacity, assigns widths, waits four frames, fixes sizes and restores authored visibility. No application is visually shown. `layout_ready` gates early requests. This prevents cached zero-width minimum heights from stretching windows to maximum height on first opening.

Recon source details use the same prelayout principle inside `intel_detail.gd`: `present()` prepares hidden content at the exported `preferred_size`, reflows for four frames at zero opacity and emits `presentation_ready` for final anchoring before becoming drawable. Visible updates retain the fixed width; metadata labels have bounded horizontal minimums and readable height. Closing during preparation invalidates the pending reveal; rapid selections retain only the latest fact. This removes the first-open one-frame width flash without loading or recreating windows.

## Verification

Startup/audio tests drive real viewport input: silence/configuration, exact quote, portrait order, three resolutions, equal text columns, capped portraits, manual/held input, authored reveal barrier, closed applications and handoff quarantine. Integration fixtures exercise a real successful mission's configured follow-up, conditional response selection, cancellation during entry/reveal, long-text scrolling and the plugin preview. Real MP3 seeks test Sycophant repeat, cue handoff, background wrap, paused overlap, mute/zero level, finished fallback and singleton survival after scene destruction. Desktop smoke waits for layout readiness and then manually opens the initially closed applications.

Both graphical suites have a 45-second failure watchdog. The CLI frame limit also bounds failures before test initialization:

```text
godot --path . --max-fps 60 --quit-after 3000 --script res://tests/startup_audio.gd -- --capture-dir=<existing directory>
godot --path . --max-fps 60 --quit-after 3000 --script res://tests/ui_smoke.gd -- --capture-dir=<existing directory> --webp
```

WebP captures stay outside the repository. Native Windows verified; browser and standalone-export audio have not been exercised.
