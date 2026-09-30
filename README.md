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

## Run and test

Tested with **Godot 4.7.2**, Windows / GL Compatibility. Open `project.godot` and press **F5**.

```text
godot --path .
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --path . --script res://tests/ui_smoke.gd
```

If Godot is not on PATH, substitute its executable path. On the development machine:

```powershell
& "P:\Progs\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path .
```

Default window 1440×900; minimum 1024×720. UI tests capture screenshots to `user://screenshots`, or to a directory passed after `--` as `--capture-dir=C:/Temp/asscrackers`. Tests return nonzero on assertion failure. Headless UI runs skip screenshots.

## Code and scope

`candidate_generator.gd` owns expansion and derivations; `dictionary_service.gd` owns words and capacity; `attack_engine.gd` owns comparisons and risk; `game_session.gd` owns timer and mission. `scripts/ui/main.gd` builds the Control-based screen.

One authored English mission; no network, external cracking process, saves or procedural targets. Generated audio and procedural portrait require no runtime services. Real-user usability, subjective audio and standalone export still need human validation.

[Product](PRD.MD) · [Rules](docs/mvp-spec.md) · [Hashcat references and math](docs/hashcat-model.md) · [Verification](docs/verification.md)
