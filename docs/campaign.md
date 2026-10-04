# Campaign, submission and marks

## Playing the assignment

The authored campaign contains three targets, in order:

| Target | Account | Document | Time coefficient |
| --- | --- | --- | --- |
| Human Resources / Lexa | `lexa@anus.industries` | Layoff order | 1.0 |
| Finance / Mira | `mira@anus.industries` | Corrected payment register | 1.5 |
| Executive Vault / Oleg | `oleg@anus.industries` | Signed archive copy | 2.0 |

Each target has its own public identity, paid recon graph, fragments and password
habits. The original HR prices are unchanged. The complete useful recon routes
cost 45, 32 and 38 Exposure respectively, before attacks. Smaller investigations
and candidate pools can produce better marks. These are local game simulations.

Flow:

```text
Silent title → first briefing → target 1
SUCCESS → result / MARK / SUBMIT RESULT → after-target dialogue
→ next briefing → next target
Last SUBMIT RESULT → last debrief → grade-specific curator line → summary
TRACE on any target → GAME OVER → RETURN TO TITLE
```

SUCCESS is not automatically submitted. The large button confirms one frozen
result exactly once. Double clicks do not duplicate results or advance twice.
There is no player-facing mission-retry button. An exhausted candidate pool is
still editable; only reaching 100 Exposure ends the whole assignment.

## Exact grading

`data/campaign/grading.tres` is a `GradingPolicy`. Default successful marks:

| Exposure | Mark |
| --- | --- |
| 0–25 inclusive | A |
| >25–50 inclusive | B |
| >50–75 inclusive | C |
| >75–100 exclusive | D |

100 is TRACE, never a successful D. Exposure includes every paid recon query,
launch and sent request on that target. The result freezes exact fixed-point units
on success. Display rounding does not affect a threshold.

The final mark uses **mean final Exposure**, not mean letters. The comparison is
`sum_units <= threshold × SCALE × target_count`; it does not round a float first.
For example, risks 25 and 76 average to 50.5 and yield C, irrespective of letter
rounding. The summary shows each submitted target, risk, mark and request count,
plus mean risk and total requests/jobs.

## Editing data

- **Campaign order:** `data/campaign/main.tres`, exported `goals` array.
- **Goal metadata:** `data/campaign/goals/*.tres`: ID, title, mission JSON path,
  success text, before/after DialogueEntry references. Goal IDs must match JSON IDs.
- **Targets and recon:** `data/targets/target_001.json` through `target_003.json`.
- **Services/timing:** `data/services/services.json`.
- **Marks/thresholds:** `data/campaign/grading.tres`.
- **First briefing:** `data/dialogues/intro.dialogue`.
- **All other conversations and endings:** `data/dialogues/campaign.dialogue` in
  Godot's Dialogue workspace. Its `~` cues are referenced by individual `.tres` entries.

The final cue branches on the scene-scoped `Campaign.final_mark` context and says
one curator line for A/B/C/D. No plot twists are introduced. To adjust the wording,
edit the `.dialogue` file; to move a conversation, reassign the goal's entry resource.
See [dialogue authoring](dialogue-authoring.md) for portraits and presentation.

## State ownership and reset

`CampaignState` is a RefCounted model owned by boot. It owns the current goal,
pending snapshot, submitted results and exact aggregate risk. Its phases are IDLE,
ACTIVE, AWAITING_SUBMIT, TRANSITION, COMPLETE and FAILED. Input resources are read-only.

`GameSession.start_mission(path)` owns each target's budget, dictionary, recon and
attack clock. Switching targets clears those fields, invalidates the previous work
generation and closes applications, while keeping their current clamped positions.
Audio/FX preferences and background playback remain. Before/after conversations
block tools and pause idle commentary.

`boot.gd` owns presentation transitions, submit gating, dialogue roles and return
to title. Return cancels active dialogue/work, destroys the desktop, clears campaign
progress, stops both music streams/queued fades, and resets the entry prompt. A new
game starts target 1 and repeats the full intro; audio/FX preferences remain.

Campaign validation rejects missing/invalid missions, mismatched/duplicate IDs,
invalid grading and missing dialogue cues. Invalid mission/dialogue data produces
a return-to-title error screen rather than silently skipping a target.

## Verification

`campaign_domain.gd` covers exact grade boundaries, fractional averages, immutable
pending snapshots, one-time submission, ordered advancement, authored solvability,
recon costs, mission reset and stale-generation rejection.

`campaign_flow.gd` runs the real three-target UI loop, all before/after cues, all
four endings, success/summary bounds at three resolutions, saved window positions,
preferences across new campaigns and TRACE on every target. Its watchdog is 90 s.

```text
godot --headless --path . --max-fps 60 --quit-after 2400 --script res://tests/campaign_domain.gd
godot --path . --max-fps 60 --quit-after 6000 --script res://tests/campaign_flow.gd
```
