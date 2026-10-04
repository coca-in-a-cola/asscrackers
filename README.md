# ASS / CRACKERS

A cyberpunk password-recovery puzzle with corporate black humour and an unreliable cat.

## Play

Press any key on the silent entry screen (click, touch and gamepad buttons also work). Sycophant starts, the screen fades to black, and the curator opens the briefing. The player's portrait appears with their first reply. The entry screen credits, in order:

```text
made by mice-seller
made with GPT6.1 Sol
+ Google Image Pro
music by Karl Casey @ White Bat audio
```

Any key/button/click completes a printing line, then advances on the next press. **Hold Space** to fast-forward dialogue. After four lines the desktop gradually appears behind the conversation. When the briefing ends, all applications are closed: open them through shortcuts or the taskbar.

1. Open **G-D's Eye**, select a source and pay its Exposure price to retrieve information. New branches appear as you investigate.
2. Type relevant **words and numbers**, pressing **Enter** after each to save a chip.
3. Optionally enable **Special characters**.
4. Press **RUN DICTIONARY**. Hashdog sends generated passwords through the simulated botnet to the known target account.

**A chip is a fragment, not necessarily a whole password.**

```text
Dictionary: Fluffy, Barsik, 19, 90, Kek, lol
Among generated candidates: Barsik + 19 + 90 + Fluffy → Barsik1990Fluffy
```

The tool tries all nonempty subsets in every order, using each fragment at most once. Case is preserved. Use **×** to remove a fragment. Information nodes do not insert fragments automatically; infer and type your own inputs.

## Slots and special characters

- Normal mode: **6 fragments**, up to **1956** combinations.
- Special mode: **5 fragments**, up to **1950** candidates after six rule alternatives.
- If all six slots are occupied, remove one before enabling rules. Nothing is deleted automatically.

Special mode tries: the unchanged combination, suffix `!`, suffix `?`, suffix `#`, lowercase `a` replaced with `@`, and that replacement followed by `!`. It does not try every symbol in every position. The tooltip and HOW TO PLAY show the same rules.

Duplicate results are checked once per job. Overlong candidates are omitted rather than truncated. The displayed unique count may be lower than the maximum. On success, the result explains exactly which fragments and rule matched.

## The run

The task supplies the target account and service. The terminal presents fictional distributed login requests from 24 botnet relays, using `hashdog botnet --login ... --combine`. Authentication is a deterministic local game simulation; no network or external cracking process is involved.

`Time = 60 × service coefficient × unique candidates / 1956` seconds. At the first service's coefficient of 1, a full unmatched 1956-candidate pass takes exactly **60 seconds** in the model clock. Five ordinary fragments produce at most 325 candidates (about 9.97 seconds); three produce 15 (about 0.46 seconds). A match ends work early. Special rules change the real candidate count, so they affect both time and risk.

Recon and botnet requests share **Exposure 0–100**. Launch costs **2**, each sent login request costs **18 / 1956**, and a full pass costs **20**. Recon has a per-node price, charged once; repeat reading is free. At 100 the operation is traced. Stop and early success save the cost of unsent requests; exhausted pools have no extra penalty. Save or clear an unsaved draft before launching.

FX, Music, Mute and master volume remain available. Each new target clears words, rules, recon and Exposure while preserving presentation preferences, window positions and background music.

## Campaign and marks

Three targets: **HR / Lexa → Finance / Mira → Executive Vault / Oleg**. On success,
review the result and large **MARK**, then press **SUBMIT RESULT** to deliver the file
and continue through the curator's debrief/next briefing. There is no automatic
advance or mission-retry button. Exposure ≤25 earns A, ≤50 B, ≤75 C, otherwise D;
100 is **TRACE / GAME OVER**, returning to the silent initial screen.

After the third submission, the curator delivers one grade-specific line and the
campaign summary shows all three results. The final mark uses **mean Exposure**,
not mean letters, without rounding before comparison. [Campaign rules and authoring](docs/campaign.md).

## Soundtrack

**Sycophant** accompanies the entire intro, repeating if reading takes longer than the song. At handoff it crossfades over 1.5 seconds into **Hackers → New Beginnings → The Saga → repeat**, by Karl Casey / White Bat audio. Background tracks overlap for 0.75 seconds. The scene Autoload **MusicManager** owns playback; its exported MusicCue resources are editable in Inspector (`data/audio/intro.tres`, `background.tres`). Music pauses/resumes from the taskbar; Mute silences music and action effects while playback continues. Volume zero is silent. Short generated action effects remain.

Before input the singleton's players are idle; there is no desktop or mission. The entry gesture starts playback synchronously. Entry and handoff held keys are consumed until release so they cannot type a fragment or open an application accidentally. Target transitions preserve playback; returning to title stops it, clears campaign progress and enables the full intro on a new game. See [intro and audio architecture](docs/startup-audio.md).

## Desktop

Four fixed-size applications start closed on teal grid wallpaper. Open them through shortcuts or the taskbar, drag their titlebars to move them and use **X** to close them. Reopening preserves position and content. No resize handles are provided. **Closing the terminal does not stop the botnet**: progress, Exposure and Stop remain on the taskbar. **Read Me** opens help.

G-D's Eye is a scrollable directed graph rooted at the target's identity. Clicking a leaf opens an adjacent information subwindow. An unretrieved leaf offers a priced query; retrieved content can be read again for free. Some sources require multiple retrieved parents. The first mission's useful recon trail costs 45 Exposure; an optional club record is a distraction.

**FX** toggles the whole retro stack: subtle URSC-derived dithering followed by Flowerwall CRT scanlines, RGB mask, grain and color smearing. Wallpaper and pastel colors remain with FX off. Curvature, screen shake and bloom are disabled so small text and click targets stay aligned.

## Run and test

Tested with **Godot 4.7.2**, Windows / GL Compatibility. Open `project.godot` and press **F5**.

```text
godot --path .
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/ui_components.gd
godot --path . --max-fps 60 --quit-after 3000 --script res://tests/ui_smoke.gd
godot --path . --max-fps 60 --quit-after 3000 --script res://tests/startup_audio.gd
godot --headless --path . --max-fps 60 --quit-after 2400 --script res://tests/campaign_domain.gd
godot --path . --max-fps 60 --quit-after 6000 --script res://tests/campaign_flow.gd
```

If Godot is not on PATH, substitute its executable path. On the development machine:

```powershell
& "P:\Progs\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path .
```

Default window 1440×900; minimum 1024×720. UI tests capture screenshots to `user://screenshots`, or to a directory passed after `--` as `--capture-dir=C:/Temp/asscrackers`. Tests return nonzero on assertion failure. Headless UI runs skip screenshots.

## Code and scope

`candidate_generator.gd` owns expansion; `dictionary_service.gd` owns fragments; `exposure_budget.gd` owns exact fixed-point risk; `intel_service.gd` owns paid discovery; `attack_engine.gd` owns the request snapshot and model clock; `game_session.gd` coordinates the mission independently of window visibility. `service_catalog.gd` reads names and time coefficients from `data/services/services.json`.

Three authored English missions; no network, external cracking process, saves or procedural targets. The local MP3 soundtrack, generated action effects and procedural backgrounds require no runtime services. The operator's self-portrait uses `assets/portraits/player-icon.png`, configured in `data/ui/operator.tres`. Real-user usability, subjective audio and standalone export still need human validation.

## UI authoring

- `scenes/boot.tscn` / `scenes/ui/start_screen.tscn`: silent credits, phased fade orchestration, held-key isolation and delayed control handoff.
- `data/dialogues/intro.dialogue`: write/edit the briefing in Godot's **Dialogue** workspace, with syntax checking and custom-balloon preview. Dialogue Manager v4.1.0 owns branching/runtime. See [authoring guide](docs/dialogue-authoring.md).
- `data/dialogues/intro.tres`, `characters/`, `presentation.tres`: resource-driven conversation entry, portraits/names/expressions, dimensions and typing settings. `data/dialogues/campaign.dialogue` contains before/after conversations and four final branches.
- `data/campaign/main.tres`, `goals/`, `grading.tres`: ordered targets, mission file inputs, result copy, dialogue references and exact A/B/C/D grading.
- `scenes/ui/intro_dialogue.tscn` / `assets/ui/dialogue_theme.tres`: capped portraits, curator connection window, two aligned retained-text windows, native plugin typewriting/choices and Space acceleration. AnimationPlayer clips own transitions.
- `assets/ui/startup_theme.tres`: isolated dark terminal palette and typography; `startup_background.gd` draws its grid/registration marks. The desktop retains its own pastel theme.
- `scenes/audio/music_manager.tscn` / `scripts/audio/music_manager.gd`: persistent two-player music and exported MusicCue inputs. `data/audio/` owns tracks/order/timing. `game_audio.gd` owns action tones only; `default_bus_layout.tres` routes Music/SFX independently.
- `scenes/ui/atoms/`: button, icon, checkbox, input, window background, titlebar, statusbar, modal layer.
- `scenes/ui/components/`: window, fragment slot, dialog, desktop shortcut, intel detail, retro effects. The earlier fact-card primitive remains available.
- `scenes/ui/panels/`: terminal, dictionary, operator, dossier, taskbar, help, result.
- `assets/ui/windows95/game_theme.tres`: shared palette, fonts, texture borders, control states. Textures use Nearest; borders stretch independently of labels and icons.
- `scripts/ui/components/desktop_windows.gd`: initial placement, open/close/drag, screen clamping and active-window ownership. Windows remain alive when closed.
- `scripts/ui/components/intel_graph.gd`: stable authored node positions, directional links, discovery states and graph extents.
- `assets/shaders/flowerwall/`, `assets/shaders/ursc/`: adapted third-party shaders and MIT licenses. Post-process parameters are authored in `retro_effects.tscn`; no editor plugin or extra Autoload is required.
- `data/ui/operator.tres`: self-portrait and operator copy. `data/ui/help.tres`: tutorial and idle voices. Mission records remain in `data/targets/target_001.json`.

Static UI is authored in `.tscn`; six dictionary slots and application instances persist for the scene lifetime. Discovered graph buttons are instantiated once and updated in place. Mission schema 3 validates costs, references and graph acyclicity. See [UI architecture and asset mapping](docs/ui-win95.md).

[Product](PRD.MD) · [Rules](docs/mvp-spec.md) · [Hashcat references and math](docs/hashcat-model.md) · [Verification](docs/verification.md)
