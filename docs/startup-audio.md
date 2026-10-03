# Entry screen and soundtrack

## Lifecycle

`project.godot` opens `scenes/boot.tscn`. Boot owns the one-time transition. `scenes/ui/start_screen.tscn` projects the title, credits and Press any key prompt; its input handler emits an accepted gesture once. Until then there is no desktop instance, mission, idle voice timer or audio player. The packed desktop/audio resources are available before entry, without playing them.

Accepted: a non-echo key press, left/right/middle click, touch press or gamepad button press. Ignored: motion, scroll, analog drift, release and key echo. The handler consumes the initiating event. Boot also suppresses the entry key's held repeats/release, then permits normal typing.

Boot instantiates the existing desktop and calls `start_audio()` synchronously, with no await before first playback. The start screen is hidden/freed. Mission Restart resets only the game session, preserving the audio component and never replaying the intro.

## Credits and visual ownership

Order and spelling:

```text
made by mice-seller
made with GPT6.1 Sol
+ Google Image Pro
music by Karl Casey @ White Bat audio
```

`assets/ui/startup_theme.tres` owns the dark navy, cyan, rose and amber roles and monospace typography. The background draws a subtle 48px grid, scanlines, corner registration marks and sparse edge ticks. Real text uses containers; title sizing/margins tighten below 800px height. The prompt pulses between 60% and 100% opacity without disappearing or moving its layout. Startup styling is isolated from the desktop's pastel Windows 95 theme.

## Playlist

The main scene's Audio node serializes an exported `Array[AudioStream]`, in this order:

1. `res://assets/sfx/Karl Casey - Hackers.mp3`
2. `res://assets/sfx/Karl Casey - New Beginnings.mp3`
3. `res://assets/sfx/Karl Casey - The Saga.mp3`

MP3 import looping is disabled; the playlist wraps after The Saga. Resources are never modified at runtime. `scripts/ui/game_audio.gd` replaces the removed `synth_audio.gd` and its generated eight-second loop. Generated short add/run/hint/success/fail effects remain.

Two persistent AudioStreamPlayers overlap when the active track is within 0.75 seconds of its end. A bound tween applies equal-power sine/cosine gains, then retires the outgoing player. The finished signal is a fallback if a frame hitch skips the overlap window. No beat synchronization or track-state mapping is applied.

Music toggling pauses/resumes both music players and an active crossfade tween. It does not seek or recreate playback. Repeated enable is idempotent. Mute and the clamped 0–1 master slider update both audio categories immediately, including during overlap; zero is actual silence. Muting leaves playback advancing. `default_bus_layout.tres` routes music to Music and action tones to SFX, both feeding Master. Default master level remains 0.35; music keeps the prior -8dB relative trim.

## Verification

`tests/startup_audio.gd` instantiates the real boot scene and sends viewport input events. It verifies silence/no session before input, exact credits, three resolutions, accepted/ignored input, held-key isolation, no duplicate desktop, and actual taskbar Music clicks. Real imported MP3s are sought near their ends to exercise automatic crossfades and playlist wrap without waiting for complete songs. Tests pause an active overlap, resume muted, update volume, exercise natural finished fallback, and restart the mission without resetting audio.

Run:

```text
godot --path . --script res://tests/startup_audio.gd -- --capture-dir=<existing directory>
```

Graphical captures are WebP; headless runs skip capture checks. Desktop smoke and domain/component suites remain separate. Browser and standalone-export playback have not been exercised by this Windows native run.
