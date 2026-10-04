# MVP v5 verification — windows, paid recon and botnet clock

Environment: Windows, Godot 4.7.2.stable.steam.ed1daf0bf, GL Compatibility / NVIDIA GeForce RTX 3050.

## Executed checks

- `tests/run_tests.gd`: **92 checks, 0 failures**.
- `tests/ui_components.gd`: **48 checks, 0 failures**.
- Graphical `tests/ui_smoke.gd`: **107 checks, 0 failures**.
- Graphical `tests/startup_audio.gd`: **77 checks, 0 failures**.

Domain tests drive controlled time deltas: a full pass is running with 1955 requests at 59.999 s and finishes with 1956 requests at 60 s, costing exactly 20 Exposure. Service coefficient 2 doubles duration; early success, Stop and trace send only their accounted requests. No real-time minute-long delay is required by the tests.

Recon tests verify hidden content, discovery prerequisites, multiple-parent cross-references, one-time prices, the useful 45-point trail, independent public snapshots, schema validation and a recon query tracing an active attack. Existing generator and symbol-rule tests remain.

UI tests send mouse events through the viewport for dragging, close/reopen, graph clicks and source purchases. They verify stable dimensions/identities/positions, source subwindows, reading after reopening, the known target login, full-pool forecast, early victory, background work, taskbar Stop with all apps closed, real-clock completion of a one-candidate hidden job, and preferences/reset behavior.

Startup/audio checks cover editor-authored Autoload cues, initial silence/no desktop, credits, actual entry input, full black before portraits, player-before-curator order, the exact reference line, held-entry isolation, any-key completion, three resolutions, the four-line reveal barrier, held-Space progression, risk/tool lockout and closed applications after handoff. Real MP3 seeks verify Sycophant repetition throughout the briefing, its handoff to Hackers, background wrap, paused overlaps, mute/zero level, taskbar Music clicks, finished fallback, Restart continuity and singleton survival after desktop destruction.

Regression fix: hidden windows previously cached wrapped-text minimum heights before reflow. Transparent prelayout plus `layout_ready` now produces bounded fixed-size windows on their first manual opening. The bad test curtain path was corrected; graphical suites have 45-second watchdogs and run with a bounded CLI frame budget. Final suites finish normally with no script errors.

## Visual captures

Viewed default desktop, source query, revealed deep branch, minimum resolution and help. Content margins separate controls from frame edges. Help/results are modal; source details remain attached to their leaf and fit usable screen bounds. Window overlap is intentional and controlled through titlebars/taskbar buttons.

Viewed the dark cyberpunk entry at 1024×720 and 1440×900, plus its transition to the desktop. Title, credits and entry prompt remain distinct and unclipped. Typography review: named roles, one monospace family/two weights, intact glyphs and clean display/body separation (TYPE-ROLE-TOKEN / FACE-CAP / GLYPH-INTEGRITY / DISPLAY-HUD-SPLIT: 2/2 each). Composition review: safe edges, balanced columns, clear scan path and restrained title shadow (COMP-SAFE-EDGE / BALANCE / SCAN and LIGHT-BLOOM-ABUSE: 2/2 each). Corner metadata is intentionally smaller; the primary prompt and credit values remain prominent.

Viewed the new dialogue at minimum/default resolution, the desktop reveal/briefing and manually opened applications. Portrait cutouts were also viewed on black/teal proof sheets. Header/hint plates and background dimming keep text separate from desktop/taskbar lettering. Inactive portraits are RGB-darkened, remaining opaque. Intro TYPE-GLYPH-INTEGRITY, TYPE-ROLE-TOKEN and COMP-SAFE-EDGE: 2/2; transparent bust edges and lower fades remain clean.

Screenshots are outside the repository under `C:/Users/Me/AppData/Local/Temp/opencode/windowed-recon/`:

- `asscrackers-desktop.webp`, `asscrackers-desktop-clean.webp`
- `asscrackers-help.webp`
- `asscrackers-intel-query.webp`, `asscrackers-intel-revealed.webp`
- `asscrackers-minimum.webp`, `asscrackers-fullhd.webp`
- `asscrackers-victory.webp`, `asscrackers-background-job.webp`, `asscrackers-trace.webp`
- `asscrackers-start-1024.webp`, `asscrackers-start-1440.webp`, `asscrackers-start-1920.webp`, `asscrackers-start-desktop.webp`
- Current intro: `asscrackers-intro-black.webp`, `asscrackers-intro-player.webp`, `asscrackers-intro-1024.webp`, `asscrackers-intro-1440.webp`, `asscrackers-intro-1920.webp`, `asscrackers-intro-reveal.webp`, `asscrackers-intro-briefing.webp`, `asscrackers-desktop-empty.webp`
- Portrait proof sheets: `portraits-black.webp`, `portraits-teal.webp`. Older start-desktop captures above belong to the superseded direct-entry flow.

## Scope

Requests are a local game simulation. Human playtesting is still needed for recon pricing, readability and difficulty. Other machines and standalone exports have not been validated. Earlier reports in `archive/` describe superseded mechanics.
