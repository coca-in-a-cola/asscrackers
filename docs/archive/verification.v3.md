# MVP v3 — archived direct-input verification

Environment: Windows, Godot **4.7.2.stable.steam.ed1daf0bf**, GL Compatibility / NVIDIA GeForce RTX 3050.

## Results

- Headless editor import completed without script/import errors.
- `tests/run_tests.gd`: **55 checks, 0 failures**.
- Graphical `tests/ui_smoke.gd`: **39 checks, 0 failures**.
- Separate debug launch: `errors: []`, no warnings after renaming a local variable that shadowed `Node.ready`.
- Captured and visually inspected populated dictionaries at 1440×900 and 1024×720. Input, six chips, removal controls and footer are visible. Long guesses are ellipsized without changing their stored values.

The first UI run exposed a clipped footer at minimum size. Reduced terminal and chip minimum heights; the second run passed all bounds checks.

## Covered behaviour

Single-list capacity, duplicate handling, exact case and whitespace semantics, atomic invalid input, removal order, independent snapshots, resource priorities, repeated runs, validation of English schema-v2 data, read-only dossier, absence of add-token metadata, stale callbacks, single hint/result events.

The graphical runner additionally checks Enter-to-save, seventh-guess draft preservation, actual × removal, all six slot bounds, the unsaved-draft guard, controls locked during attacks, exact request order, real-timer victory and both defeats, English command/response output, literal markup-like text, FX-off hints, log scrolling, generated audio startup and preferences surviving restart.

## Screenshots

Final graphical run wrote the following files outside the repository under `C:/Users/Me/AppData/Local/Temp/opencode/`:

- `asscrackers-desktop.png`
- `asscrackers-chips.png`
- `asscrackers-minimum.png`
- `asscrackers-victory.png`
- `asscrackers-rate-limit.png`
- `asscrackers-hint.png`

## Limitations

Another human playtest is needed to establish whether this interaction is now clear. Automated button signals are not a substitute for real keyboard/mouse usability or the puzzle's difficulty. Audio playback is technically tested; subjective listening and standalone export on another machine remain unverified.

The 80/26 counts in `archive/verification.v2.md` describe the old CLI prototype and do not apply to this revision.
