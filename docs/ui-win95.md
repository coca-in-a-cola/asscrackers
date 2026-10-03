# Windows 95 in-game UI

## Layout

```text
main.tscn
├── Background                 desktop_background.gd, teal gradient + 48px grid
├── DesktopIcons               five PNG shortcuts, activation/help requests
├── Applications               desktop_windows.gd owns fixed geometry + activation
│   ├── terminal.tscn          log, relay exposure, Run, statusbar
│   ├── dictionary.tscn        checkbox, six persistent slots, input + feedback
│   ├── operator.tscn          self-portrait from operator.tres
│   └── dossier.tscn           public mission facts + hint
├── taskbar.tscn               Help, Result, FX, Synth, Mute, volume, state
├── DialogLayer
│   ├── modal_layer.tscn / result.tscn
│   └── modal_layer.tscn / help.tscn
└── retro_effects.tscn         CanvasLayer 90, dithering → CRT
```

`Applications` is a custom Container: it places compact windows using `fit_child_in_rect`, with a separate compact arrangement below 1250px width or 780px available height. At 1440×900, terminal is 600×300, dictionary 600×366, profile 350×156 and dossier 430×528. Larger screens center this group instead of stretching its contents. At 1024×720, workspace and record widths adapt without overlapping controls. HBox/VBox/Grid/Scroll/Center containers still own geometry inside each application.

The grid remains visible with FX disabled. Desktop shortcuts activate applications and raise their draw order; titlebar clicks also activate windows. `Read Me` opens help. Positioning, activation and existing close-request signals are separate from application content, providing an extension point for future dragging, minimizing and opening/closing. Current application positions are fixed.

The project uses `canvas_items` stretch mode for the CRT pipeline. The root window's content-scale size tracks its actual size, keeping small fonts at native pixel density when resized. Portrait remains square and preserves its aspect ratio. Dialogs center over a blocking scrim and keep keyboard focus inside their controls. Escape closes dialogs and restores focus.

## Reusable primitives

The window consists of `window_background.tscn`, `titlebar.tscn`, and a content container. The titlebar composes an independent icon, title Label and optional close button. Buttons have their own background Panel, border style, label and optional native Button icon. Labels are never rasterized into the game interface.

Each fragment slot has a status Label, word Label and separate remove Button. Its `remove_requested(fragment)` signal travels up to the dictionary panel, then to the game orchestrator. Slots are authored once in the scene and updated in place. Fact cards are instantiated only when mission data changes; they never mutate domain data or insert fragments automatically.

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

- Domain services continue owning mission, dictionary, candidate queue and exposure.
- Main orchestrator listens to domain signals, handles UI requests and passes display data down.
- `OperatorProfile` / `data/ui/operator.tres` owns the portrait, filename, display name and description.
- `DesktopCopy` / `data/ui/help.tres` owns tutorial copy, location and idle voice lines.
- Dossier reads `public_mission`; hidden solution remains in the domain session.
- Theme and profile definitions are read-only shared resources. No runtime theme construction or per-refresh scene reconstruction.

## Verification

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/ui_components.gd
godot --path . --script res://tests/ui_smoke.gd -- --capture-dir=<existing directory> --webp
```

Component test instantiates every UI scene under a neutral host, waits for ready and frees it. UI smoke covers add/remove, special rules, locked running state, success/trace, restart, FX/audio preferences, literal fragment rendering, log scrolling, persistent slot identities, avatar source/aspect and modal keyboard focus. It also sends real viewport mouse events to shortcuts/titlebars, checks application bounds and non-overlap at 1024×720, 1440×900 and 1920×1080, and captures the desktop with FX both off and on.
