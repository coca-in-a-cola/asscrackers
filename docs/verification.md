# MVP v4 verification — generated fragment combinations

Environment: Windows, Godot **4.7.2.stable.steam.ed1daf0bf**, GL Compatibility / NVIDIA GeForce RTX 3050.

## Executed checks

- Headless editor import: no script/import errors.
- `tests/run_tests.gd`: **63 checks, 0 failures**.
- Graphical `tests/ui_smoke.gd`: **43 checks, 0 failures**.
- Separate debug launch through Godot MCP: `errors: []`, no warnings. Game left running for playtest.

The exact user example was checked end-to-end: the six fragments `Fluffy, Barsik, 19, 90, Kek, lol` generated `Barsik1990Fluffy`, and the engine recovered it by comparing candidate SHA-256 hashes. The winning derivation was `Barsik + 19 + 90 + Fluffy`.

Tests independently verify the 1956/1950 maxima, deterministic subset order, no repeated fragments, deduplication, all six symbol rules, final-length filtering, mode-switch atomicity and capacity enforcement. A full unmatched 1956-candidate run completes with Exposure 15 rather than stopping at ten checks.

The authored mission was solved in the real UI using fragments plus the checkbox, with no complete-password entry. The result showed `Barsik + 19 + 90` and `a → @ + !`. Tests also cover the full 1950-candidate unmatched special pool, incremental timer batches, locked controls, unsaved input, FX-off clue, scrolling, relay trace, reset and persistent presentation preferences.

## Visual review

Viewed the final minimum-size 1024×720 screen, the 1440×900 running job and the victory derivation. The checkbox, five fragment chips plus reserved rule cell, input and footer fit. Batch counters and sampled output are visible; the success screen identifies actual sources.

Screenshots are outside the repository under `C:/Users/Me/AppData/Local/Temp/opencode/`:

```text
asscrackers-desktop.png
asscrackers-combinations.png
asscrackers-specials.png
asscrackers-minimum.png
asscrackers-victory.png
asscrackers-running.png
asscrackers-exhausted.png
asscrackers-trace.png
```

## Limits of verification

This is timed CPU hashing labelled as GPU simulation; no real hashcat process or GPU kernel was tested. Another human playtest is needed for clarity, the symbol trade-off, puzzle difficulty and relay-risk balance. Sound perception, other machines and standalone export remain unverified.

Earlier verification counts in `archive/` apply to superseded mechanics only.
