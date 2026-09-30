# ASS / CRACKERS — MVP v4

## Product decision: a dictionary contains fragments

Keep the simplified chip interface, but correct its semantics: chips contain useful words and numbers, not necessarily complete passwords. Hashdog performs the combination work.

**Read the dossier → collect meaningful fragments → optionally enable symbol rules → run the dictionary.**

One authored mission. Colourful cyberpunk, absurd hallucinations and black humour. Password recovery is simulated against a captured local hash, using a bounded candidate pool and a fictional compute relay.

## Required interaction

- Exactly **one dictionary**, with up to **six fragments**, or **five** with Special characters enabled.
- The dictionary is the large central workspace. All six slots remain visible.
- A large input below it accepts a word or number. **Enter saves it.** There is no add button.
- Each saved fragment is a large chip with an **×** to remove it.
- The compact terminal above it sends `hashdog run` when **RUN DICTIONARY** is pressed, then displays responses.
- Players do not need to learn a command language. Combination is automatic; one checkbox enables a documented special-character rule set.
- The dossier is read-only. Players infer and manually enter their fragments.
- **English** game text, dossier, tooltips, feedback and test descriptions.

For example, `Fluffy, Barsik, 19, 90, Kek, lol` must generate `Barsik1990Fluffy`. Try every nonempty ordered subset, using each fragment at most once. Case stays as typed. Optional symbol rules expand each combination.

Six fragments yield at most **1956** candidates. Five fragments with six rule variants yield at most **1950**. These are comparable combinatorial bounds, not identical success probabilities. Duplicate strings and overlong candidates reduce the actual count.

## Kept from the first prototype

- The authored ANUS INDUSTRIES HR mission and its deducible password.
- Exposure 0–100 models risk of using a monitored compute relay, not detection from offline hash operations.
- Run costs +10 Exposure; exhausting a whole pool without a match adds +5. Individual hash checks are free of Exposure penalties.
- The old ten-request limit and RATE_LIMIT defeat are removed. Every generated candidate can be checked; an exhausted job returns control to the player unless traced.
- Responsive asynchronous batches, victory, trace defeat and clean restart.
- A one-time clue at Exposure ≥60, strange cat commentary, optional FX and generated synth audio.
- Godot 4.7 / GDScript / GL Compatibility. Local simulation without runtime services.

## Success criteria

The player supplies relevant facts, not a finished password. Generated-pool size, rule mode and derivation of a successful password must be visible and predictable. GPU behaviour is explicitly simulated; this is not a real hashcat integration.

The new interaction needs another human playtest; automated tests cannot establish clarity or fun.

## Documents

- [Rules and interface](docs/mvp-spec.md)
- [Implementation and acceptance](docs/implementation-plan.md)
- [Verification results](docs/verification.md)
- [Hashcat references and budget calculation](docs/hashcat-model.md)
- [Run instructions](README.md)

`docs/archive/` preserves earlier requirements and reports. This version supersedes both the multi-dictionary CLI and the v3 complete-guess interpretation.
