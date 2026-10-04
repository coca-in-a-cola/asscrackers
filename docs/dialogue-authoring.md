# Editing dialogue in Godot

## Existing intro

1. Open `project.godot` in Godot 4.7.2. Dialogue Manager is already enabled under **Project Settings → Plugins**.
2. Open `data/dialogues/intro.dialogue`. Godot opens the **Dialogue** workspace.
3. Edit normal speaker/text lines, save, and use the plugin's test command (**Ctrl+F5**) for a balloon preview. Use **F5** for the complete intro, music and desktop transitions.
4. Fix any syntax errors reported by the editor before testing.

```text
~ start
Curator: Wake the fuck up, samurai. We have asses to crack
Player: Is that the official onboarding?
Curator: No. The official one costs extra.
Player: Great. What am I breaking?

$> Narrative.present("desktop_reveal")

Curator: ANUS INDUSTRIES. HR portal. Lexa's account. We need the layoff order.
```

`~ start` is the starting cue. `=> END` ends the conversation. The reveal command
waits until the animation finishes. Insert, remove or reorder text around it freely;
there is no hidden fourth-line counter. The mandatory opening quote must stay exact.

## Characters and expressions

Select `data/dialogues/characters/player.tres` or `curator.tres` in the Inspector.
Each `DialogueCharacter` defines:

- **ID:** the speaker token used in `.dialogue`, currently `Player` or `Curator`.
- **Display name:** the visible name, independently editable.
- **Slot:** LEFT or RIGHT.
- **Expressions:** texture dictionary with required `neutral` fallback.
- **Reveal on first line / First line animation:** optionally keep the portrait hidden until that character first speaks. Player enables this and uses `player_enter`; curator appears with the opening connection window. These are character-resource inputs, not line-count checks.

Add a texture under a new expression key, then select it in the script:

```text
Curator: [#expression=angry] That was careless.
```

Unknown/missing expression keys fall back to `neutral`. Add any new speaker to the
conversation's `characters` array; this two-column balloon accepts one character
per slot. Dialogue entry validation rejects missing speakers or duplicate slots.

## Layout, appearance and motion

- `data/dialogues/presentation.tres`: width fraction/cap, portrait height fraction/cap,
  connection-window rise, equal-column gap, text-panel height, bottom clearance,
  typing speed, punctuation pauses and Space hold/acceleration settings.
- `assets/ui/dialogue_theme.tres`: text fonts/colors and frame/titlebar style roles.
- `scenes/ui/intro_dialogue.tscn` → **AnimationPlayer**: `enter`, `exit`, and standalone
  preview `desktop_reveal`. Edit durations/keyframes using Godot's animation editor.
- **PortraitAnimationPlayer** in the same scene: `player_enter`, the independent first-reply fade. Its duration is editable without changing dialogue code.
- `scenes/boot.tscn` → **CinematicPlayer**: credit fade, black pause and real desktop reveal.

Keep bottom clearance sufficient for the taskbar and hint lane. Portraits do not
expand with leftover screen height. Long paragraphs scroll rather than shrinking
to unreadable text. Runtime does not modify these input resources.

## Campaign conversations

Open `data/dialogues/campaign.dialogue` to edit `after_hr`, `before_finance`,
`after_finance`, `before_vault`, `after_vault` and `ending`. The ending contains
one branch per `Campaign.final_mark` (A/B/C/D). All text remains writer-editable.

## New conversation

1. Create a `.dialogue` file through the Dialogue editor and choose a start cue.
2. Duplicate `data/dialogues/intro.tres` as a new **DialogueEntry**.
3. Set its ID, dialogue resource, start cue, character array and presentation preset.
4. Set entry/exit music IDs if this conversation should change music; leave them
   empty to preserve current playback. Music cues are configured in `data/audio/`.
5. Set presentation cue mappings only for commands used by this conversation.
   Each mapping targets an existing `AnimationPlayer` clip; unknown clips are rejected.
6. Select a goal under `data/campaign/goals/` and assign the entry to **Before Dialogue**
   or **After Dialogue**. The after-dialogue starts only after **SUBMIT RESULT**;
   completion advances to the next goal's briefing, or the final ending/summary.

`data/campaign/main.tres` owns goal order, grading and final dialogue. See
[campaign authoring](campaign.md). `tests/fixtures/dialogue_backend.dialogue`
remains test-only neutral copy, not game narrative.

## Choices

Use native Dialogue Manager response syntax and conditions. Each allowed response
selects its own branch through `DialogueResponse.next_id`; unavailable responses
are disabled and omitted from keyboard focus. Choices occupy the left text window.
Space fast-forward stops at choices and cinematic waits.

```text
Curator: Ready?
- Yes => ready
- Not yet => later

~ ready
Player: Ready.
=> END

~ later
Player: Give me a minute.
=> END
```

Reference: [Dialogue Manager v4.1.0 docs](https://github.com/nathanhoad/godot_dialogue_manager/tree/v4.1.0/docs).
