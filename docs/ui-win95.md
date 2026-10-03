# Windows 95 in-game UI

## Layout

`boot.tscn` is the project entry point. It first shows `start_screen.tscn` with its own dark, grid-based cyberpunk theme and credits. The first accepted input creates the desktop below and starts music synchronously. No audio player or mission exists before that gesture. Restart operates inside the existing desktop. See [startup and audio](startup-audio.md).

```text
main.tscn
├── Background                 desktop_background.gd, teal gradient + 48px grid
├── DesktopIcons               five PNG shortcuts, activation/help requests
├── Applications               desktop_windows.gd owns open/close/drag + activation
│   ├── terminal.tscn          botnet, known account, requests, Run/Stop, Exposure
│   ├── dictionary.tscn        checkbox, six persistent slots, input + feedback
│   ├── operator.tscn          self-portrait from operator.tres
│   └── dossier.tscn           discovered/retrieved recon graph
├── intel_detail.tscn          owned, leaf-anchored source information/query window
├── taskbar.tscn               application buttons + global Exposure/time/Stop
├── DialogLayer
│   ├── modal_layer.tscn / result.tscn
│   └── modal_layer.tscn / help.tscn
└── retro_effects.tscn         CanvasLayer 90, dithering → CRT
```

`Applications` is a plain Control with a window manager, not a layout Container. Initial positions and sizes are chosen once; titlebars subsequently move windows without resizing them. Their usable bounds leave the two-row taskbar accessible. Resizing the game viewport clamps window positions, preserving their dimensions. Overlap is intentional and controlled by active-window draw order. Containers still own geometry inside applications.

Shortcuts and taskbar buttons open or activate existing application instances. X hides an application; it never deletes its controls or stops domain work. Closing the active window activates another visible window. Dragging is bounded to keep windows accessible; modal dialogs cancel any active drag. Recon's leaf subwindow follows its owner and graph scrolling, stays inside usable screen bounds and hides when its owner closes or another application is activated. Read Me opens modal help.

The project uses `canvas_items` stretch mode for the CRT pipeline. The root window's content-scale size tracks its actual size, keeping small fonts at native pixel density when resized. Portrait remains square and preserves its aspect ratio. Dialogs center over a blocking scrim and keep keyboard focus inside their controls. Escape closes dialogs and restores focus.

## Reusable primitives

The window consists of `window_background.tscn`, `titlebar.tscn`, and `Stack/ContentMargin/Content`. Content has 12px horizontal and 10px vertical margins, separate from the titlebar. Wrapped labels are first given a real width before the manager fixes window height, avoiding transient zero-width minimum-size expansion. The titlebar composes an independent icon, title Label and close button. Buttons retain separate backgrounds, borders and text.

Fragment slots remain persistent and never insert data automatically. Graph node buttons are keyed by stable fact IDs, created only when a source becomes discoverable and updated after a purchase. Graph extents grow with visible nodes; their authored positions do not jump. Edges are drawn behind the buttons. All information requests travel through main to GameSession; graph and detail windows never charge Exposure themselves.

## Exported kit mapping

| Element | Figma node / local source | Integration |
| --- | --- | --- |
| Window border | `1:2692`, `window-frame--type-empty` | StyleBoxTexture, center disabled; separate gray face |
| Button states | `1:11`, `1:13`, `1:15` | Border-only StyleBoxTexture, independent text and face |
| Input | `1:1849`, `input--state-default` | AtlasTexture crops the edit area, excluding label and dropdown |
| Checkbox | `1:1628`, `1:1629`, `1:1632`, `1:1633` | Theme icons for unchecked/checked/disabled states |
| Close | `1:2335` | Icon on a separate button; live close signal |
| Statusbar | `1:3295` | Pastel inset StyleBox based on kit geometry; separate Label |
| Terminal | `2:983`, `2:730` | Program and Run Program icons |
| Dictionary | `2:722` | Folder icon |
| Self-portrait | `2:780` + `avatars/avatar.png` | Paint title icon; profile Resource supplies portrait |
| Dossier / facts | `2:993`, `2:750` | Search in PC and Notepad icons |
| Taskbar / dialogs | `2:784`, `2:988`, `2:754` | Start, Help and File icons |

`game_theme.tres` owns the pastel sage faces, cream insets, lavender active titlebars, muted teal inactive titlebars and control states. Rasterized kit labels are deliberately excluded from border centers so titles, words and results stay real editable Godot text. No source sheet or screenshot is used as a whole-screen UI texture.

## Retro effects

`retro_effects.tscn` has explicit full-viewport `BackBufferCopy` nodes before each pass. This ensures the CRT reads the dithered result rather than a stale pre-effect screen texture. Both overlays ignore mouse input and render after the desktop and dialogs. Hiding their CanvasLayer bypasses both shaders and copies; the existing FX checkbox controls that visibility.

- URSC: `canvas_item/dithering.gdshader` adapted to read the screen, with an inline Bayer 4×4 pattern and a 0.2 blend strength at color depth 32. Source: https://github.com/Zorochase/ultimate-retro-shader-collection.
- Flowerwall CRT: based on the user's `flowerwall_crt 2.0.2.zip`, with unused helpers removed and `effect_strength` added to blend its output with the source. Source: https://github.com/art-oria/Flowerwall-CRT-shader-for-Godot.
- CRT defaults: effect blend 0.4, RGB mask 0.08, scanlines 0.08, grain 0.025 and smearing 0.12. Curvature and wiggle are disabled; no blur/bloom passes are enabled.
- MIT notices are included alongside each shader. The upstream editor plugin, debug F1/F2 settings UI and material-save code are not installed; resources remain read-only at runtime.

## Data ownership

- ExposureBudget owns the ledger shared by IntelService and AttackEngine. GameSession owns their lifecycle and runtime clock.
- Main orchestrator listens to domain signals, handles UI requests and passes display data down.
- `OperatorProfile` / `data/ui/operator.tres` owns the portrait, filename, display name and description.
- `DesktopCopy` / `data/ui/help.tres` owns tutorial copy, location and idle voice lines.
- `public_mission` contains known identity/account/task only. Recon snapshots contain metadata for discoverable nodes and content for purchased nodes only. Undiscovered nodes and hidden solution never reach the graph.
- Theme and profile definitions are read-only shared resources. No runtime theme construction or per-refresh scene reconstruction.

## Verification

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/ui_components.gd
godot --path . --script res://tests/ui_smoke.gd -- --capture-dir=<existing directory> --webp
godot --path . --script res://tests/startup_audio.gd -- --capture-dir=<existing directory>
```

Component tests instantiate each UI scene under a neutral host. UI smoke sends viewport mouse events for dragging, X, reopening, graph selection, paid queries and global Stop. It verifies fixed sizes, persistent window identities/positions, padding and bounds at 1024×720, 1440×900 and 1920×1080, bought information after closing/reopening, modal focus, background work and presentation preferences. Domain timing tests use explicit deltas; one tiny graphical run also exercises the real background clock.
