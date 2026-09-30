# MVP v3 — archived complete-guess specification (superseded by v4)

Product intent: [PRD](../PRD.MD). This replaces the command-heavy v2 specification.

## 1. Screen and interaction

- Header: mission state, Exposure and remaining requests.
- Main workspace: a compact terminal above a large dictionary field, with a large text input underneath.
- Dictionary: six visible rounded chip slots, three columns by two rows; insertion order is reading order.
- Dossier: a read-only, independently scrollable panel on the right. No add buttons, dictionary destinations or generated tokens.
- Footer: help, effects, music, mute and volume. Result can be reopened after a completed run.
- Default window 1440×900; minimum 1024×720. Native text sizing with responsive Control containers. No dictionary scrolling is needed to see all six slots.

Enter in the large field saves one complete password guess. Spaces inside the input belong to that candidate; the field is not a shell, list parser or command entry. Outer whitespace is trimmed. Quotes have no special syntax. Successful save clears the input. Rejected save preserves the text and explains the problem next to the field.

The **×** removes exactly that chip, preserving the order of the others. New guesses occupy the next free position. No facts are added automatically.

**RUN DICTIONARY** logs `$ hashdog run` and starts checking the saved chips. The user never needs to type commands. If the input contains an unsaved guess, the run is blocked for free with a prompt to press Enter or clear the field. This prevents silently ignoring a draft.

## 2. The one dictionary

- Ordered unique strings, case-sensitive.
- Maximum six saved guesses. A seventh is rejected without changing the dictionary.
- Maximum 64 characters per guess; reject blank strings and embedded newline/tab characters.
- Duplicate entry is a harmless no-op; no reordering, no extra slot.
- No automatic combination, capitalization, leet or suffix operations.
- One chip equals one exact password candidate. `Barsik` and `B@rsik1990!` are two distinct guesses.
- Long text may be ellipsized on a chip; its full value is available in the tooltip and never truncated in the model.
- Chips show READY, TESTING, REJECTED or MATCH based on actual attempts. Previous rejections are not automatically skipped.

Saving and removing are free. The six-slot limit applies to the current dictionary, not all guesses ever made. A player may remove guesses and add replacements while requests remain.

## 3. Attack and resources

Session phases: READY, RUNNING, WON, LOST.

Initial state: empty dictionary, 10 requests left, Exposure 0, no result, no hint.

1. Only a loaded READY session with a nonempty dictionary can run.
2. Snapshot the dictionary. Add 10 Exposure.
3. If Exposure reaches 100, lose with TRACE before sending a request.
4. Otherwise send one candidate every 350 ms, first candidate after 350 ms.
5. Spend one request and compare exactly, including case.
6. Match: SUCCESS, even on the tenth request. Do not add the miss penalty.
7. Miss: add 5 Exposure, clamp to 100, then check TRACE before RATE_LIMIT.
8. If the queue ends while resources remain, return to READY. This is not defeat.

Input, removal and repeated runs are locked while RUNNING and after a terminal result. Every subsequent run tests all remaining chips again and pays another +10 Exposure. No hidden filtering or replenishment.

The terminal displays commands and server-style replies. A resource warning forecasts how many guesses can be checked if all fail; it never consults the secret password.

Examples:
- First candidate correct: 1 request used, Exposure 10.
- One wrong candidate followed by the correct one in the same run: 2 used, Exposure 15.
- Six misses, then a second run with four misses: 10 used, Exposure 70, RATE_LIMIT.
- Six separate single-miss runs: 6 used, Exposure 90. Starting another run causes TRACE without sending a seventh request.

## 4. Results and reset

- ACCESS GRANTED reveals the password and reasoning.
- RATE LIMIT EXCEEDED explains the request limit without revealing the password.
- TRACE DETECTED explains detection; if both budgets were exhausted, show both facts.
- VIEW DICTIONARY hides the result panel for inspection; RESULT reopens it.
- RESTART MISSION clears dictionary, resources, attempt history, hints and input, then loads the same mission.
- Stop old timers and reject callbacks from old session generations. Audio and FX preferences persist through restart.

## 5. Mission data

`data/targets/target_001.json` is the authoritative authored English content. `schema_version` is now **2**.

Public fields: `id`, `display_name`, `brief`, and `facts`. Each fact has `id`, `label`, `value`, `source`, `note`. Old `token` and `dictionary` metadata is removed.

Internal `solution`: `password`, nonempty unique valid `fact_ids`, `hint_fact_id` referencing one of them, and `explanation`. UI receives a public mission copy without `solution`; only victory exposes the answer. This is presentation separation, not protection against inspecting local files.

Validate required fields, types, schema version, unique fact IDs and solution references before starting. A malformed mission produces an English error screen rather than a partial game.

The existing answer is preserved. The current cat, birth year, old password pattern and message to IT explain every part. Manual input is intentional; the user must infer the finished password rather than assemble it through a programming interface.

## 6. Hallucination and presentation

At Exposure ≥60, once per active mission, mark the relevant fact. Do not trigger over a terminal result. The marker remains; if FX is enabled, briefly brighten it. With FX off, retain the static clue and readable terminal message.

All player-facing copy is English, including dossier, help, results and errors. Keep cyberpunk cyan/magenta, dark backgrounds, the unreliable cat and corporate black humour. Effects cannot hide input, candidates or resources.

Generated sounds and optional synth loop remain. No new external assets are required.

## 7. Architecture

- `dictionary_service.gd`: a single six-slot list; validation, insertion, removal, snapshot.
- `attack_engine.gd`: deterministic checks and resource rules, independent of UI and time.
- `game_session.gd`: owns the dictionary, engine, mission, timer and generation; guards all edits.
- `mission_loader.gd`: schema-v2 validation and load diagnostics.
- `main.gd`: input, chips, terminal feedback, read-only dossier and results.

The former command parser, dispatcher and autocomplete are removed, not left as hidden alternate paths around the six-slot limit.
