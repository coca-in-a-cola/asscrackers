# MVP v5 verification — windows, paid recon and botnet clock

Environment: Windows, Godot 4.7.2.stable.steam.ed1daf0bf, GL Compatibility / NVIDIA GeForce RTX 3050.

## Executed checks

- `tests/run_tests.gd`: **92 checks, 0 failures**.
- `tests/ui_components.gd`: **46 checks, 0 failures**.
- Graphical `tests/ui_smoke.gd`: **103 checks, 0 failures**.
- Graphical `tests/startup_audio.gd`: **85 checks, 0 failures**.

Domain tests drive controlled time deltas: a full pass is running with 1955 requests at 59.999 s and finishes with 1956 requests at 60 s, costing exactly 20 Exposure. Service coefficient 2 doubles duration; early success, Stop and trace send only their accounted requests. No real-time minute-long delay is required by the tests.

Recon tests verify hidden content, discovery prerequisites, multiple-parent cross-references, one-time prices, the useful 45-point trail, independent public snapshots, schema validation and a recon query tracing an active attack. Existing generator and symbol-rule tests remain.

UI tests send mouse events through the viewport for dragging, close/reopen, graph clicks and source purchases. They verify stable dimensions/identities/positions, source subwindows, reading after reopening, the known target login, full-pool forecast, early victory, background work, taskbar Stop with all apps closed, real-clock completion of a one-candidate hidden job, and preferences/reset behavior.

Startup/audio checks cover ordered author/tool/music credits, no mission/audio players before input, accepted/ignored gestures, held-entry-key isolation, native-pixel layout at all three resolutions, and no duplicate desktop or intro replay. They use real MP3 seeks to verify Hackers → New Beginnings → The Saga → Hackers, automatic equal-power overlap, pause/resume during the overlap, mute/volume zero, actual taskbar Music clicks, natural finished fallback and continuous audio across mission restart.

## Visual captures

Viewed default desktop, source query, revealed deep branch, minimum resolution and help. Content margins separate controls from frame edges. Help/results are modal; source details remain attached to their leaf and fit usable screen bounds. Window overlap is intentional and controlled through titlebars/taskbar buttons.

Viewed the dark cyberpunk entry at 1024×720 and 1440×900, plus its transition to the desktop. Title, credits and entry prompt remain distinct and unclipped. Typography review: named roles, one monospace family/two weights, intact glyphs and clean display/body separation (TYPE-ROLE-TOKEN / FACE-CAP / GLYPH-INTEGRITY / DISPLAY-HUD-SPLIT: 2/2 each). Composition review: safe edges, balanced columns, clear scan path and restrained title shadow (COMP-SAFE-EDGE / BALANCE / SCAN and LIGHT-BLOOM-ABUSE: 2/2 each). Corner metadata is intentionally smaller; the primary prompt and credit values remain prominent.

Screenshots are outside the repository under `C:/Users/Me/AppData/Local/Temp/opencode/windowed-recon/`:

- `asscrackers-desktop.webp`, `asscrackers-desktop-clean.webp`
- `asscrackers-help.webp`
- `asscrackers-intel-query.webp`, `asscrackers-intel-revealed.webp`
- `asscrackers-minimum.webp`, `asscrackers-fullhd.webp`
- `asscrackers-victory.webp`, `asscrackers-background-job.webp`, `asscrackers-trace.webp`
- `asscrackers-start-1024.webp`, `asscrackers-start-1440.webp`, `asscrackers-start-1920.webp`, `asscrackers-start-desktop.webp`

## Scope

Requests are a local game simulation. Human playtesting is still needed for recon pricing, readability and difficulty. Other machines and standalone exports have not been validated. Earlier reports in `archive/` describe superseded mechanics.
