# Hashcat analogy and bounded search budget

Official references consulted for this iteration:

- [Combinator attack](https://hashcat.net/wiki/doku.php?id=combinator_attack)
- [Rule-based attack](https://hashcat.net/wiki/doku.php?id=rule_based_attack)

Hashcat's built-in combinator mode combines **two** dictionaries by appending each left word to each right word. Its rule language can append characters (`$X`) and replace characters (`sXY`), among many other operations. A plain dictionary attack does not inherently generate every permutation of arbitrary fragments.

Hashdog deliberately adds a small game-specific all-subset/all-order generator behind one dictionary UI. It borrows combination and rule concepts; it does not claim that this is the default behaviour of hashcat or implement its whole command language.

## Why six normal slots and five special slots?

With N distinct fragments, no repeated use within a candidate and all nonempty ordered subsets:

```text
C(N) = Σ(k=1..N) N! / (N-k)!
C(6) = 6 + 30 + 120 + 360 + 720 + 720 = 1956
C(5) = 5 + 20 + 60 + 120 + 120 = 325
```

Choose six special-mode alternatives per joined string:

```text
:       unchanged
$!      append !
$?      append ?
$#      append #
sa@     replace lowercase a with @
sa@$!   replace lowercase a with @, then append !
```

These rule notations explain the analogy; the game uses direct string operations, not a hashcat runtime.

```text
normal maximum:  1956
special maximum: 325 × 6 = 1950
difference:      6 candidates (about 0.31%)
```

The comparable quantity is the **upper bound on candidates**, not success probability. Actual count can be smaller: different source orders may produce the same string, `sa@` does nothing when there is no `a`, and strings above 64 characters are skipped. We display the unique count rather than pretending all 1950/1956 candidates always exist.

The budget requires explicit limits: no repeated fragment use, no arbitrary-length permutations, no universal symbol insertion and no hidden case variants. Adding more rules in future requires revisiting the slot limit and formula.

## Offline checks versus online requests

Hash recovery operates against a captured hash. Thousands of local candidate comparisons are not thousands of login attempts. The old ten-request game limit would prevent this intended mechanic from working and has therefore been removed.

The game uses a SHA-256 fixture and paced CPU comparisons in Godot. GPU throughput is simulated and labelled as such. Exposure represents the fictional danger of consuming a monitored compute relay: +10 per job, +5 for a completely exhausted job. That risk model is game balance, not a claim about real hashcat detection.
