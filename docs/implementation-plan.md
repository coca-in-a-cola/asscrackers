# MVP v4 — acceptance

## Required automated coverage

- The exact user example `Fluffy, Barsik, 19, 90, Kek, lol` generates and recovers `Barsik1990Fluffy` by actual hash comparison.
- All nonempty ordered subsets are covered; shorter candidates appear first; no repeated fragment use.
- Normal maximum is 1956; special maximum is 1950. Deduplicate collisions and enforce final-string length.
- Each of the six rule variants works. Rules off never introduces symbols or case changes.
- Enabling rules with six words is rejected without mutation. Removing one permits the switch. Disabling restores capacity without changing words.
- Candidate preview is rebuilt only on preparation changes, independent of the target.
- All candidates can be checked: no old ten-request cutoff or per-miss Exposure penalty.
- Batch processing stops immediately on match; exhaustion applies one +5 and returns to preparation.
- Runtime locks, copied queues, single result/hint events and restart generation guards remain effective.
- UI presents the real slot count, reserved rule slot, actual unique candidate count and source/rule derivation on success.
- Both window sizes fit; no dossier add buttons; all content remains English.

Results: [verification](verification.md).

## Human playtest

Confirm that the player now thinks in relevant words and dates rather than exact passwords. Check whether the checkbox's five-slot trade-off and limited symbol rules are understandable. Evaluate whether pacing and per-job risk feel appropriate. Automated tests do not establish these qualities.
