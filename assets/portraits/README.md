# Character portraits

Transparent derivatives of `assets/exp/player.jpg` and `curator.jpg`. Sources remain unchanged. `tools/prepare_portraits.py` removes the magenta screen, retains the main connected silhouette (discarding the curator's side-code panels), removes edge spill, and matches face scale/placement on 640×512 bust canvases. The lower bust fades into transparency. `player-icon.png` is a 256×256 derivative for Self-portrait.

Authoring dependencies: Pillow, NumPy, SciPy. They are not required by the game. Rebuild from the project root with `python tools/prepare_portraits.py`; an optional `--dependency-dir` accepts an isolated package directory. `--preview-dir` writes black/teal WebP proof sheets outside the project.
