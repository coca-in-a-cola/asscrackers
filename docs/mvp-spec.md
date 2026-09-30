# MVP v4 — fragment dictionary and generated candidates

Product: [PRD](../PRD.MD). Technical rationale: [hashcat model](hashcat-model.md).

## Input and slots

One ordered dictionary, entered manually. Enter saves a fragment; × removes it. Dossier content has no action buttons. Duplicate exact fragments are no-ops, case variants are distinct. Trim outer whitespace, preserve inner spaces, reject blank/multiline/tabbed fragments and lengths above 64 characters. Failed insertion keeps the draft.

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

The local fixture represents a captured authentication hash. On mission load, derive SHA-256 from the authored secret; the engine compares each generated candidate's SHA-256 against that hash. The public dossier never receives the solution object. This is a game fixture, not secret storage protection.

The implementation uses Godot's CPU hashing and timed batches; the UI explicitly says **GPU simulation**. It launches no real hashcat process and sends no login requests.

Snapshot the complete generated pool at launch. Each 100 ms tick checks up to 64 candidates; stop immediately at a match or pool exhaustion. The terminal shows one labelled sample per batch, not a fabricated line for every candidate. Progress counts every actual comparison. Large jobs remain responsive and normally take about three seconds at the full pool size; wall-clock timing is presentation pacing, not a hardware benchmark.

## Risk and state

States: READY, RUNNING, WON, LOST. Initially READY, no fragments, no rules, no checked hashes, Exposure 0.

- Accepted nonempty launch: +10 Exposure and one job recorded.
- If that reaches 100: TRACE before checking any candidate.
- Each local comparison increments checked-hash statistics, with no per-candidate Exposure.
- Match: SUCCESS, no exhaustion penalty, stop all remaining work.
- Whole pool checked with no match: +5 Exposure once. Return to READY unless that reaches 100, in which case TRACE.
- Empty/invalid/concurrent launch, rejected input and toggles: no cost.
- Editing after exhaustion is allowed. A new run checks the newly generated pool from its beginning; previously tested candidates are not cached across runs.

**No ten-request limit and no RATE_LIMIT result remain.** The 1956 bound limits a job's search space; it is not a dwindling mission request account. Fictional Exposure belongs to the compute relay, not to the physics of offline password hashing.

Examples: first successful job costs 10 Exposure regardless of the match index. A failed job then a successful one costs 25. Six exhausted jobs cost 90; launching a seventh reaches TRACE before any new comparison.

## UI

Keep the chip workspace and large input from v3. Relabel them as fragments. Show actual unique pool count, a Special characters checkbox, reserved rule cell and live checked/total progress. Tooltips/help explain rules and the two comparable upper bounds.

RUN DICTIONARY emits `hashdog run --combine`, plus `--specials` when enabled. These are fictional presentation commands, not hashcat-compatible syntax. An unsaved draft blocks launch for free rather than being silently ignored.

Maintain 1440×900 default and 1024×720 minimum, visible chips/input/footer, read-only scrollable dossier, English text, optional FX and generated audio. One-time clue at Exposure ≥60 remains, except on terminal-result transitions.

## Results and reset

SUCCESS shows the recovered password, authored reasoning, actual source fragments, applied rule, hashes checked, jobs and Exposure. TRACE shows relay detection without revealing the password. An exhausted pool shows terminal feedback, not a defeat modal.

Restart stops the timer, invalidates old callbacks, clears fragments and generated candidates, turns special rules off and resets engine/hints. Audio/FX preferences persist. The schema-2 mission remains compatible; its brief describes the captured-hash scenario.

## Code ownership

- `candidate_generator.gd`: bounded, deterministic, target-independent expansion and derivation metadata.
- `dictionary_service.gd`: fragment storage and transactional mode/capacity changes.
- `attack_engine.gd`: hash comparisons, complete pool snapshot, batch stepping, per-job risk.
- `game_session.gd`: cache regeneration, readiness guards, timer, mission and events.
- `main.gd`: fragment chips, rule control, actual counts and sampled output.

Autogeneration is the intended game mechanic. The player supplies semantic clues, not exact concatenation syntax.
