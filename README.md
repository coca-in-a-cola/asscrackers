# ASS / CRACKERS

A cyberpunk password-recovery puzzle with corporate black humour and an unreliable cat.

## Play

1. Read the dossier on the right.
2. Type relevant **words and numbers**, pressing **Enter** after each to save a chip.
3. Optionally enable **Special characters**.
4. Press **RUN DICTIONARY**. Hashdog generates and checks combinations for you.

**A chip is a fragment, not necessarily a whole password.**

```text
Dictionary: Fluffy, Barsik, 19, 90, Kek, lol
Among generated candidates: Barsik + 19 + 90 + Fluffy → Barsik1990Fluffy
```

The tool tries all nonempty subsets in every order, using each fragment at most once. Case is preserved. Use **×** to remove a fragment. The dossier has no add buttons; you must infer and type your own inputs.

## Slots and special characters

- Normal mode: **6 fragments**, up to **1956** combinations.
- Special mode: **5 fragments**, up to **1950** candidates after six rule alternatives.
- If all six slots are occupied, remove one before enabling rules. Nothing is deleted automatically.

Special mode tries: the unchanged combination, suffix `!`, suffix `?`, suffix `#`, lowercase `a` replaced with `@`, and that replacement followed by `!`. It does not try every symbol in every position. The tooltip and HOW TO PLAY show the same rules.

Duplicate results are checked once per job. Overlong candidates are omitted rather than truncated. The displayed unique count may be lower than the maximum. On success, the result explains exactly which fragments and rule matched.

## The run

The fixture is a captured local SHA-256 authentication hash. The terminal sends a fictional `hashdog run --combine` command and shows sampled batch output. The generated candidates are really hashed and compared, but **GPU execution is simulated in Godot**, not delegated to real hashcat.

There is **no ten-login-request limit**. All generated candidates can be checked. Work is paced in batches of up to 64 per 100 ms to keep the interface responsive.

Exposure represents risk at your fictional compute relay: **+10 per job**, **+5 when the entire pool fails**. Individual hash comparisons add no Exposure. At 100 the relay is traced. Otherwise an exhausted job lets you revise fragments and run again. A draft still in the input must be saved or cleared before launching.

FX, SYNTH, MUTE and master volume remain available. Restart clears words, rules and session resources but keeps these presentation preferences.

## Desktop

The teal grid wallpaper surrounds four compact, fixed application windows. Existing Win95 borders and PNG icons use a pastel sage/lavender theme. Click a desktop shortcut or a titlebar to activate an application; **Read Me** opens help. Window dragging and closing are reserved for a later iteration.

**FX** toggles the whole retro stack: subtle URSC-derived dithering followed by Flowerwall CRT scanlines, RGB mask, grain and color smearing. Wallpaper and pastel colors remain with FX off. Curvature, screen shake and bloom are disabled so small text and click targets stay aligned.

## Run and test

Tested with **Godot 4.7.2**, Windows / GL Compatibility. Open `project.godot` and press **F5**.

```text
godot --path .
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/ui_components.gd
godot --path . --script res://tests/ui_smoke.gd
```

If Godot is not on PATH, substitute its executable path. On the development machine:

```powershell
& "P:\Progs\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path .
```

Default window 1440×900; minimum 1024×720. UI tests capture screenshots to `user://screenshots`, or to a directory passed after `--` as `--capture-dir=C:/Temp/asscrackers`. Tests return nonzero on assertion failure. Headless UI runs skip screenshots.

## Code and scope

`candidate_generator.gd` owns expansion and derivations; `dictionary_service.gd` owns words and capacity; `attack_engine.gd` owns comparisons and risk; `game_session.gd` owns timer and mission. `scenes/main.tscn` composes the Windows 95 desktop from independent scenes. `scripts/ui/main.gd` connects signals and projects session state onto existing controls.

One authored English mission; no network, external cracking process, saves or procedural targets. Generated audio and the procedural background require no runtime services. The operator's self-portrait uses `avatars/avatar.png`, configured in `data/ui/operator.tres`. Real-user usability, subjective audio and standalone export still need human validation.

## UI authoring

- `scenes/ui/atoms/`: button, icon, checkbox, input, window background, titlebar, statusbar, modal layer.
- `scenes/ui/components/`: window, fragment slot, fact card, dialog, desktop shortcut, retro effects.
- `scenes/ui/panels/`: terminal, dictionary, operator, dossier, taskbar, help, result.
- `assets/ui/windows95/game_theme.tres`: shared palette, fonts, texture borders, control states. Textures use Nearest; borders stretch independently of labels and icons.
- `scripts/ui/components/desktop_windows.gd`: responsive fixed placement and active-window ownership, separated from application content for future drag/open/close behavior.
- `assets/shaders/flowerwall/`, `assets/shaders/ursc/`: adapted third-party shaders and MIT licenses. Post-process parameters are authored in `retro_effects.tscn`; no editor plugin or extra Autoload is required.
- `data/ui/operator.tres`: self-portrait and operator copy. `data/ui/help.tres`: tutorial and idle voices. Mission records remain in `data/targets/target_001.json`.

Static UI is authored in `.tscn`; six dictionary slots persist for the entire scene lifetime. The only runtime UI instantiation is the variable-length dossier list, using `fact_card.tscn`. Components can run separately with F6. See [UI architecture and asset mapping](docs/ui-win95.md).

[Product](PRD.MD) · [Rules](docs/mvp-spec.md) · [Hashcat references and math](docs/hashcat-model.md) · [Verification](docs/verification.md)
