# MVP v3 — archived complete-guess acceptance

## Completed change

1. Replaced named dictionaries and CLI manipulation with one six-slot list.
2. Rebuilt the workspace around visible chips and a large Enter-to-save input.
3. Converted the terminal into run-command and response feedback.
4. Removed all dossier add buttons and automatic token metadata.
5. Translated game text and authored facts to English, keeping the solution deducible.
6. Replaced obsolete parser/mutation tests with dictionary and direct-input interaction tests.

## Automated acceptance

- Empty dictionary and all six slots on startup.
- Enter creates one chip; duplicate is a no-op; seventh entry is rejected without losing the draft.
- × removes the selected chip; subsequent entry goes to the end; no hidden combination/mutation.
- No dossier Button descendants or fact-to-dictionary metadata.
- Long guesses preserve their model value and full tooltip; literal brackets are not markup.
- Run does not ignore an unsaved input; while running, input and removal are locked.
- The snapshot is checked in display order, with a real 350 ms timer in the UI test.
- Success, queue exhaustion, tenth-request behaviour, RATE_LIMIT and TRACE.
- Clean restart, stale callback protection, persistent audio/FX preferences.
- Hint works with effects off; terminal autoscroll respects manual scrolling.
- Minimum-window bounds for input, footer and all six chips.

Actual results: [verification](verification.md).

## Human acceptance still needed

- Can a player discover Enter → chip → run without reading the help dialog?
- Is it clear that each chip is a complete password, not a fragment automatically combined with others?
- Are the six current slots and ten total requests distinguishable?
- Does reading the dossier produce a meaningful hypothesis without guessing the designer's intent?
- Is typing the finished password enjoyable, or should the authored puzzle itself become simpler?

The first playtest established that v2 was confusing. This iteration addresses interaction complexity; its usability must be tested again rather than inferred from passing code tests.
