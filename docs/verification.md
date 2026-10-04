# Campaign verification — three goals, submission, marks and endings

Environment: Windows, Godot 4.7.2.stable.steam.ed1daf0bf, GL Compatibility / NVIDIA GeForce RTX 3050.

## Executed checks

- `tests/run_tests.gd`: **92 checks, 0 failures**.
- `tests/ui_components.gd`: **52 checks, 0 failures**.
- Graphical `tests/ui_smoke.gd`: **124 checks, 0 failures**.
- Graphical `tests/startup_audio.gd`: **120 checks, 0 failures**.
- `tests/campaign_domain.gd`: **71 checks, 0 failures**.
- Graphical `tests/campaign_flow.gd`: **110 checks, 0 failures**.

Total: **569 checks, 0 failures**. Final native runs finish without script errors or resource-leak diagnostics. Music consumers resolve the configured instance through the Engine runtime registry; they do not require a compile-time Autoload identifier. The UI mouse driver synchronizes the native pointer and delivers each press/release pair atomically: Windows hover polling otherwise cancels synthetic presses between frames. Explicit button masks and settling preserve real GUI delivery rather than emitting button signals directly. Campaign return-to-title actions are also exercised with native keyboard activation.

Domain tests drive controlled time deltas: a full pass is running with 1955 requests at 59.999 s and finishes with 1956 requests at 60 s, costing exactly 20 Exposure. Service coefficient 2 doubles duration; early success, Stop and trace send only their accounted requests. No real-time minute-long delay is required by the tests.

Recon tests verify hidden content, discovery prerequisites, multiple-parent cross-references, one-time prices, the useful 45-point trail, independent public snapshots, schema validation and a recon query tracing an active attack. Existing generator and symbol-rule tests remain.

UI tests send mouse events through the viewport for dragging, close/reopen, graph clicks and source purchases. They verify stable dimensions/identities/positions, source subwindows, reading after reopening, the known target login, full-pool forecast, early victory, background work, taskbar Stop with all apps closed, real-clock completion of a one-candidate hidden job, and preferences/reset behavior.

Startup/audio checks cover editor-authored Autoload cues, initial silence/no desktop, credits, actual entry input, full black before portraits, curator-first entry, a player portrait that stays hidden throughout the opening quote then fades in with the first player reply, held-entry isolation, any-key completion, three resolutions, the four-line reveal barrier, held-Space progression, risk/tool lockout and closed applications after handoff. Real MP3 seeks verify Sycophant repetition throughout the briefing, its handoff to Hackers, background wrap, paused overlaps, mute/zero level, taskbar Music clicks, finished fallback, Restart continuity and singleton survival after scene destruction.

Dialogue Manager integration verifies native labels and imported `.dialogue` data, equal text-column widths/bottoms, bounded portraits, retained messages, awaited authored commands, invalid/concurrent-start rejection, SUCCESS waiting for explicit submission, conditional response selection, no auto-selection under held Space, long-text wheel scrolling at minimum resolution, cancellation during entry/reveal, and standalone custom-balloon preview. Compiled source dictionaries remain unchanged. The v4.1.0 resource-cycle compatibility patch is recorded under the addon; music shutdown releases both streams and overlap tween.

Campaign tests validate all three mission schemas/IDs, coefficients 1/1.5/2, useful recon prices 45/32/38, and successful generation from semantic fragments and permitted rules. Exact threshold units and fractional means are checked; trace has no mark, duplicate success/submission is rejected, pending snapshots are independent, target reset invalidates old work generations, and mismatched goal IDs fail before launch. The real UI completes all targets, verifies every before/after cue in order, all four final branches, a complete three-row summary, window position persistence after legitimate resolution clamping, audio/FX preferences and TRACE return from each target.

Regression fix: hidden windows previously cached wrapped-text minimum heights before reflow. Transparent prelayout plus `layout_ready` now produces bounded fixed-size windows on their first manual opening. The bad test curtain path was corrected; graphical suites have 45-second watchdogs and run with a bounded CLI frame budget. Final suites finish normally with no script errors.

Campaign domain/flow suites have 30/90-second watchdogs and bounded CLI frames. One failed negative-ID test initially retained external Resource references in a duplicated campaign and mutated its original goal in memory; the fixture now explicitly copies the goal and array. Its stalled test process was terminated, and subsequent final runs exit normally. No mission files were changed by the test.

Recon-popup regression: each opening samples every drawn frame and asserts the final preferred width, including the first visible frame. Source metadata retains readable height. Closing during invisible reflow cancels the reveal; rapid source changes show only the latest fact. Viewed the anchored query capture after adding the width/metadata-height guard.

## Visual captures

Viewed default desktop, source query, revealed deep branch, minimum resolution and help. Content margins separate controls from frame edges. Help/results are modal; source details remain attached to their leaf and fit usable screen bounds. Window overlap is intentional and controlled through titlebars/taskbar buttons.

Viewed the dark cyberpunk entry at 1024×720 and 1440×900, plus its transition to the desktop. Title, credits and entry prompt remain distinct and unclipped. Typography review: named roles, one monospace family/two weights, intact glyphs and clean display/body separation (TYPE-ROLE-TOKEN / FACE-CAP / GLYPH-INTEGRITY / DISPLAY-HUD-SPLIT: 2/2 each). Composition review: safe edges, balanced columns, clear scan path and restrained title shadow (COMP-SAFE-EDGE / BALANCE / SCAN and LIGHT-BLOOM-ABUSE: 2/2 each). Corner metadata is intentionally smaller; the primary prompt and credit values remain prominent.

Viewed the final two-column dialogue at minimum/default resolution, desktop briefing and conditional-response fixture. Player is unframed on the left, curator sits in the raised connection window, and both text panels share aligned baselines. Portraits share the same capped height; active-speaker titlebars replace portrait dimming. Opaque text surfaces and reserved taskbar/hint lanes prevent glyph collisions. COMP-SAFE-EDGE, COMP-BALANCE, COMP-FRAME and COMP-SCAN: 2/2. No bloom obscures dialogue (LIGHT-BLOOM-ABUSE: 2/2).

Viewed minimum-resolution successful result with the 64px-high SUBMIT RESULT button, default campaign summary, GAME OVER and the grade-specific curator ending. Result/summary have separate heading/mark/body/data roles, real readable glyphs and safe margins (TYPE-ROLE-TOKEN / TYPE-FACE-CAP / TYPE-GLYPH-INTEGRITY / TYPE-DISPLAY-HUD-SPLIT and COMP-SAFE-EDGE: 2/2). Summary rows align across all three targets; final mark and average are visually separate. TYPE-HUD-FLOOR remains desktop-only (1/2); localization and TV/mobile viewing are not claimed.

Focused typography review of the dialogue region (not an overall atlas grade):
- 2/2: TYPE-ROLE-TOKEN, TYPE-OPSZ-MATCH, TYPE-FACE-CAP, TYPE-PAIR-DNA, TYPE-GENRE-SIGNAL, TYPE-DISPLAY-HUD-SPLIT, TYPE-WEIGHT-STEPS, TYPE-WEIGHT-OPSZ, TYPE-XHEIGHT, TYPE-GLYPH-INTEGRITY, TYPE-TRACK-BODY, TYPE-TRACK-HUD, TYPE-LEAD-DENSE, TYPE-ALLCAPS-BODY, TYPE-CASE-SENTENCE, TYPE-CASE-MICRO, TYPE-ITALIC-UI, TYPE-MICRO-LEGAL, TYPE-PLATE-TYPE, TYPE-HINT-RASTER.
- 1/2: TYPE-SCALE-RATIO (compact role steps), TYPE-HUD-FLOOR and TYPE-ANGULAR-SIZE (desktop target), TYPE-LEAD-BODY (dense dialogue rhythm), TYPE-LOC-EXPAND (scroll fallback; localization not authored).
- N/A for absent pixel classes: TYPE-DIEGETIC-DISTRESS, TYPE-NUM-TABULAR, TYPE-NUM-LINING, TYPE-NUM-OSF-OK, TYPE-NUM-SLASH-ZERO, TYPE-NUM-DISTINCT, TYPE-NUM-WEIGHT, TYPE-MONO-DATA, TYPE-STAT-ALIGN, TYPE-TIMER-STABLE, TYPE-TRACK-DISPLAY, TYPE-LEAD-DISPLAY, TYPE-KERN-LOGO, TYPE-LIGA-DISPLAY, TYPE-LOC-RTL, TYPE-MARKETING-DISPLAY.

Screenshots are outside the repository under `C:/Users/Me/AppData/Local/Temp/opencode/windowed-recon/`:

- `asscrackers-desktop.webp`, `asscrackers-desktop-clean.webp`
- `asscrackers-help.webp`
- `asscrackers-intel-query.webp`, `asscrackers-intel-revealed.webp`
- `asscrackers-minimum.webp`, `asscrackers-fullhd.webp`
- `asscrackers-victory.webp`, `asscrackers-background-job.webp`, `asscrackers-trace.webp`
- `asscrackers-start-1024.webp`, `asscrackers-start-1440.webp`, `asscrackers-start-1920.webp`, `asscrackers-start-desktop.webp`
- Current intro: `asscrackers-intro-black.webp`, `asscrackers-intro-player.webp`, `asscrackers-intro-1024.webp`, `asscrackers-intro-1440.webp`, `asscrackers-intro-1920.webp`, `asscrackers-intro-reveal.webp`, `asscrackers-intro-briefing.webp`, `asscrackers-desktop-empty.webp`
- Portrait proof sheets: `portraits-black.webp`, `portraits-teal.webp`. Older start-desktop captures above belong to the superseded direct-entry flow.
- Backend/choice fixture: `asscrackers-dialogue-choices.webp` (test-only neutral copy).
- Entry-order captures: `asscrackers-intro-curator.webp` (curator alone), `asscrackers-intro-player.webp` (first player reply, mid-fade).
- Campaign: `asscrackers-submit-{1024,1440,1920}.webp`, `asscrackers-summary-{1024,1440,1920}.webp`, `asscrackers-ending-{A,B,C,D}.webp`, `asscrackers-game-over-{1,2,3}.webp`.

## Scope

Requests are a local game simulation. Human playtesting is still needed for recon pricing, readability and difficulty. Other machines and standalone exports have not been validated. Earlier reports in `archive/` describe superseded mechanics.
