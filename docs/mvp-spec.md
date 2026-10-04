# MVP v5 — windowed recon and simulated botnet

Product: [PRD](../PRD.MD). Technical rationale: [hashcat model](hashcat-model.md).

## Entry and audio

F5 opens `boot.tscn`, displaying only the silent start screen. Its ordered credits name mice-seller, GPT6.1 Sol, Google Image Pro and Karl Casey @ White Bat audio. A non-echo key press, mouse click, touch press or gamepad button creates the desktop and starts the MP3 soundtrack in the same input callback. Mouse motion, wheel, release and key echo do not enter. The entry key's repeats/release are consumed before normal desktop typing resumes.

The credit screen fades to black, the curator appears first, and thirteen manually advanced lines introduce the trainee assignment. The player's portrait fades in with their first reply. The first line is exactly `Wake the fuck up, samurai. We have asses to crack`. After four lines the desktop appears behind the conversation over 1 s. Any fresh button completes/advances a line; holding Space accelerates typing and progression. Tools and idle voices are blocked until the 0.25 s final handoff. Applications start closed with no active window.

Scene Autoload MusicManager receives editor-authored MusicCue resources. Sycophant repeats throughout the intro, then crossfades for 1.5 s into Hackers → New Beginnings → The Saga → repeat. Per-track overlap is 0.75 s. Music pauses both players/tween; Mute/volume update music and scene-local effects. Target transitions preserve playback/preferences. Return to title stops playback; a new campaign repeats the intro. Details: [startup and audio](startup-audio.md).

## Input and slots

One ordered dictionary, entered manually. Enter or Add saves a fragment; × removes it. Recon nodes purchase information but never insert fragments automatically. Duplicate exact fragments are no-ops, case variants are distinct. Trim outer whitespace, preserve inner spaces, reject blank/multiline/tabbed fragments and lengths above 64 characters. Failed insertion keeps the draft.

Normal mode has six slots. **Special characters** enables six fixed transformation rules and reduces capacity to five. If six slots are occupied, enabling the checkbox fails with an explanation and leaves both the dictionary and checkbox unchanged. Never silently delete a word. Turning rules off restores the sixth slot without changing any fragment. With rules enabled, the sixth visual cell is a non-editable RULE SLOT.

Saving, removing and toggling rules rebuild the preview pool without consulting the target hash. Preparation costs nothing. Rules and dictionary are locked during an attack and after a terminal result.

## Candidate generation

1. Enumerate all nonempty ordered subsets, lengths 1 through N, shorter ones first.
2. Within each length, traverse the stored fragment order deterministically.
3. Use a fragment at most once in each candidate; concatenate without separators.
4. Keep case and characters as entered.
5. If special mode is enabled, apply the following alternatives to each joined string:

| Rule | Output for `cat` |
|---|---|
| Unchanged | `cat` |
| Append `!` | `cat!` |
| Append `?` | `cat?` |
| Append `#` | `cat#` |
| Replace every lowercase `a` with `@` | `c@t` |
| Same replacement, then append `!` | `c@t!` |

These are alternatives, not arbitrary symbol insertion at every position. No automatic capitalization or other leet mappings. The tooltip and help describe the limited rules.

Deduplicate final strings globally, retaining their first derivation and deterministic order. Skip strings exceeding 64 characters; never truncate a password. The maximum pool is 1956, or 1950 in special mode, before deduplication/length filtering. An unexpected oversized job is rejected, not silently cut off.

Each generated candidate carries its exact string, source fragments and rule name. A successful match highlights the actual source chips and reports the derivation. An exhausted job never marks an individual fragment as definitively wrong: a correct word may need a different companion or rule.

Required example:

```text
Input: Fluffy, Barsik, 19, 90, Kek, lol
Generated: Barsik + 19 + 90 + Fluffy → Barsik1990Fluffy
```

## Attack model

The task supplies login and service ID. Catalog data supplies the service display name and positive finite time coefficient. Login attempts are simulated locally using a deterministic password comparison oracle; no real requests or hashcat process are sent. Public mission data contains only known identity/task/account, with no fact contents or solution object.

Snapshot the complete generated pool at launch. Let N be its unique count and k the service coefficient: duration = 60 × k × N / 1956 seconds. At elapsed time t, at most floor(t × 1956 / (60 × k)) requests are due. No artificial minimum duration is applied. Emit sampled terminal responses, counting every actual request. Stop immediately at success, trace, user Stop or pool exhaustion.

GameSession drives this clock from process deltas independently of presentation visibility. Tests drive explicit deltas instead of waiting one minute. At coefficient 1, a full unmatched 1956-request pass is incomplete at 59.999 seconds and complete at 60. Runtime display of completion follows on the next processed frame.

## Risk and state

States: READY, RUNNING, WON, LOST. Initially READY, empty dictionary, rules off, no sent requests, Exposure 0.

- Accepted nonempty launch: +2 Exposure and one job recorded.
- If that reaches 100: TRACE before checking any candidate.
- Each sent request increments request statistics and costs 18/1956 Exposure. Charge first; reaching 100 traces the operation before a successful reply can be accepted.
- Match: SUCCESS, no exhaustion penalty, stop all remaining work.
- Whole pool checked with no match: return to READY without any extra penalty.
- Stop returns to READY and preserves spent Exposure, fragments and request statistics. Unsent requests have no cost.
- Empty/invalid/concurrent launch, rejected input and toggles: no cost.
- Editing after exhaustion is allowed. A new run checks the newly generated pool from its beginning; previously tested candidates are not cached across runs.

One shared fixed-point ledger serves recon and botnet work: one point = 1956 units, each request = 18 units, limit = 195600 units. A full baseline pass costs exactly 20. The 1956 bound limits a job's search space; there is no ten-request limit or RATE_LIMIT result.

## Paid recon

Mission schema 3 stores fact IDs, generic source labels, costs, authored graph positions and prerequisite IDs. Validate integer costs from 1 to 99, existing unique dependencies, valid coordinates and graph acyclicity. Nodes become discoverable only when all their prerequisites have been retrieved. The target identity is free.

A discoverable leaf opens an adjacent subwindow with its price and Query button. Purchase charges its price once, reveals its value/note and may expose child nodes. Repeat reading is free. An intercepted query reaching 100 ends the mission without revealing its reply. Recon is allowed during RUNNING, sharing the attack ledger, but paid operations stop after WON/LOST. No automatic Exposure-threshold hint reveals unpaid content.

## UI

Keep the chip workspace and large input from v3. Relabel them as fragments. Show actual unique pool count, a Special characters checkbox, reserved rule cell and live checked/total progress. Tooltips/help explain rules and the two comparable upper bounds.

RUN DICTIONARY emits `hashdog botnet --login <known account> --combine`, plus `--specials` when enabled. These are presentation commands. An unsaved draft blocks launch for free rather than being silently ignored.

Applications have fixed dimensions, X, titlebar dragging and persistent state/position when reopened. Shortcuts and taskbar buttons open or activate them. Window movement is clamped to the usable desktop. Closing a terminal never stops its job. The always-accessible two-row taskbar shows Exposure, remaining time and Stop. Content margins are 12px horizontal and 10px vertical. Maintain 1440×900 default, 1024×720 minimum, English copy and optional FX/audio. Help/results remain modal; recon details are nonmodal and leaf-anchored.

## Results and reset

SUCCESS shows password, goal-specific result text, reasoning, actual fragments/rule, sent requests, jobs, final Exposure and a large MARK. It waits for SUBMIT RESULT, which records the frozen snapshot exactly once and starts the after-goal dialogue. Exhaustion is feedback, not defeat.

The ordered campaign contains HR, Finance and Executive Vault at coefficients 1, 1.5 and 2. New targets invalidate old work generations, clear fragments/candidates, bought information, risk and rule mode; close applications while retaining positions/preferences. Every target has before/after curator dialogue. After the third submit, one curator line branches on final mark and a summary displays all targets. TRACE shows GAME OVER and RETURN TO TITLE, clears campaign progress and returns to the silent initial screen. No player-facing per-target retry remains.

Marks: ≤25 A, ≤50 B, ≤75 C, >75 and <100 D. 100 is TRACE. Final mark uses mean exact Exposure across submitted targets with the same thresholds, never mean letters or rounded display values. Data lives in `data/campaign/`; see [campaign](campaign.md).

## Code ownership

- `candidate_generator.gd`: bounded, deterministic, target-independent expansion and derivation metadata.
- `dictionary_service.gd`: fragment storage and transactional mode/capacity changes.
- `exposure_budget.gd`: single exact risk ledger.
- `intel_service.gd`: discovery prerequisites, purchases and public recon snapshots.
- `service_catalog.gd`: named service/time coefficient resolution.
- `attack_engine.gd`: request snapshot, model clock, stop/match/trace.
- `game_session.gd`: mission lifecycle, runtime clock, readiness guards and events.
- `CampaignState` / `CampaignDefinition` / `CampaignGoal` / `GradingPolicy`: submitted snapshots, ordered resource-driven progression and exact per-target/mean-risk marks.
- `main.gd`: presentation projections and requests, no domain state ownership.
- `boot.gd` / `start_screen.gd`: entry lifecycle, credits and accepted-input isolation.
- Dialogue Manager v4.1.0: imported `.dialogue` scenarios, parsing, traversal, conditions and mutations.
- `dialogue_director.gd` / `intro_dialogue.gd`: one-session lifecycle, awaited cinematic cues, resource-driven two-column balloon and native plugin labels/choices.
- `music_manager.gd` / `MusicCue`: persistent music state with serialized editor inputs.
- `game_audio.gd`: scene-local action tones, following singleton volume/mute preferences.

Autogeneration is the intended game mechanic. The player supplies semantic clues, not exact concatenation syntax.
