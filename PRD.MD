# ASS / CRACKERS — MVP v5

## Product decision: a dictionary contains fragments

Keep the simplified chip interface, but correct its semantics: chips contain useful words and numbers, not necessarily complete passwords. Hashdog performs the combination work.

**Buy recon leads → discover branches → collect meaningful fragments → optionally enable symbol rules → dispatch the botnet.**

Three authored missions: Human Resources, Finance and Executive Vault. Pastel retro desktop, absurd commentary and black humour. Each task supplies a known login and target service; a fictional botnet submits a bounded password-candidate pool. Paid reconnaissance and requests share one Exposure budget per target.

## Required interaction

- Start with a silent cyberpunk entry screen: made by mice-seller, made with GPT6.1 Sol, + Google Image Pro, then music by Karl Casey @ White Bat audio. Press any key (or click/touch/gamepad button) creates the desktop and starts music without leaking the entry input into game controls.
- Fade to black, reveal the curator first, then reveal the player with their first reply, and play the trainee briefing. Include exactly "Wake the fuck up, samurai. We have asses to crack". Any fresh button completes/advances text; holding Space accelerates dialogue. Dialogue Manager v4.1.0 provides writer-editable `.dialogue` scenarios and runtime. Compact portraits sit over two aligned text windows, with the curator inside a connection window. An authored command reveals the empty desktop after four lines; applications remain closed until manually opened. Resource inputs support later post-success conversations.
- Exactly **one dictionary**, with up to **six fragments**, or **five** with Special characters enabled.
- The dictionary is the large central workspace. All six slots remain visible.
- A large input below it accepts a word or number. **Enter or Add saves it.**
- Each saved fragment is a large chip with an **×** to remove it.
- The compact terminal above it sends `hashdog run` when **RUN DICTIONARY** is pressed, then displays responses.
- Players do not need to learn a command language. Combination is automatic; one checkbox enables a documented special-character rule set.
- G-D's Eye is a directed recon graph rooted at the target. Paid source queries reveal information and dependent branches. Players infer and manually enter fragments; repeat reading is free.
- Applications open, close and move through titlebar dragging, with fixed sizes and padded content. Closing a view preserves its state and does not stop the botnet. Global progress and Stop remain on the taskbar.
- **English** game text, dossier, tooltips, feedback and test descriptions.
- SUCCESS displays a large MARK and SUBMIT RESULT; only submission starts the debrief and next target. Marks use ≤25 A, ≤50 B, ≤75 C, otherwise D below 100. Final mark uses mean final Exposure. TRACE ends the whole campaign and returns to the initial screen. Three submitted targets produce a grade-specific curator line and campaign summary; no plot twists or per-target retry button.

For example, `Fluffy, Barsik, 19, 90, Kek, lol` must generate `Barsik1990Fluffy`. Try every nonempty ordered subset, using each fragment at most once. Case stays as typed. Optional symbol rules expand each combination.

Six fragments yield at most **1956** candidates. Five fragments with six rule variants yield at most **1950**. These are comparable combinatorial bounds, not identical success probabilities. Duplicate strings and overlong candidates reduce the actual count.

## Kept from the first prototype

- The authored ANUS INDUSTRIES HR mission and its deducible password.
- Exposure 0–100 combines priced recon queries, +2 per launch and +18/1956 per sent request. A full pass costs exactly 20; unsent requests and repeat reading are free.
- The old ten-request limit and RATE_LIMIT defeat are removed. Every generated candidate can be checked; an exhausted job returns control to the player unless traced.
- A full 1956-candidate first-level pass takes at most 60 seconds; time is proportional to unique candidates and the service's catalog coefficient. Early success and Stop end work sooner.
- Background requests, victory, trace defeat and clean restart. No free automatic clue bypasses paid recon.
- Strange commentary, optional FX and generated action effects. A data-driven MusicManager scene Autoload plays Sycophant throughout the intro, crossfading at handoff into Hackers → New Beginnings → The Saga. Music pauses/resumes; Mute/volume apply to both categories. Target transitions preserve playback; returning to title stops music and the next campaign repeats onboarding.
- Godot 4.7 / GDScript / GL Compatibility. Local simulation without runtime services.

## Success criteria

The player weighs the cost of investigating another source against sending a larger pool. Candidate count, rule mode, predicted time/risk and successful derivation are visible. All services and requests are game simulations.

The new interaction needs another human playtest; automated tests cannot establish clarity or fun.

## Documents

- [Rules and interface](docs/mvp-spec.md)
- [Implementation and acceptance](docs/implementation-plan.md)
- [Verification results](docs/verification.md)
- [Hashcat references and budget calculation](docs/hashcat-model.md)
- [Run instructions](README.md)
- [Entry screen and soundtrack](docs/startup-audio.md)

`docs/archive/` preserves earlier requirements and reports. This version supersedes the offline captured-hash/per-job risk model, while keeping the bounded fragment generator.
