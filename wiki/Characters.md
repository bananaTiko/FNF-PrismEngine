# Characters

A character is a `.json` file in a mod's `characters/` folder (or `assets/base_game/shared/characters/`), named after the character: `characters/dad.json` → `"player2": "dad"` in a chart.

Two kinds are supported: **sparrow** characters (a `.png` + `.xml` sprite sheet) and **Animate** characters (a V-Slice atlas — `Animation.json` + `spritemap1.json`/`.png`).

## Fields

```json
{
  "image": "characters/bfPixel",
  "no_antialiasing": true,
  "position": [0, 350],
  "camera_position": [50, -60],
  "scale": 6,
  "flip_x": true,
  "sing_duration": 4,
  "healthicon": "bf-pixel",
  "healthbar_colors": [123, 214, 246],
  "animations": []
}
```

| Field | Meaning |
| --- | --- |
| `image` | path under `images/` **without** extension; `characters/bfPixel` means `images/characters/bfPixel.png` + `.xml` |
| `animations` | list of animations (see below) |
| `position` | x/y offset from the character's default spot on the stage |
| `camera_position` | where the camera sits when this character is the focus |
| `scale` | sprite scale (pixel characters use whole numbers like `6`) |
| `flip_x` | mirror the sprite horizontally |
| `healthicon` | icon name under `images/icons/` (a `.png`, or a sprite sheet for animated icons) |
| `healthbar_colors` | `[r, g, b]` used for this character's side of the health bar |
| `sing_duration` | how long sing animations hold before returning to idle, in steps |
| `no_antialiasing` | keeps pixel art crisp |

`healthbar_colors` colours the **health bar**, not the icon — the icon's own pixels keep their colours. If a character's bar looks wrong, this is the field to check, and the engine reads it whenever the health bar is rebuilt.

## Animations

```json
{
  "anim": "singLEFT",
  "name": "BF NOTE LEFT0",
  "fps": 24,
  "loop": false,
  "offsets": [12, -6],
  "indices": []
}
```

| Field | Meaning |
| --- | --- |
| `anim` | the name the engine asks for (`idle`, `singLEFT`, `singDOWN`, `singUP`, `singRIGHT`, `danceLeft`, `danceRight`, `hey`, …) |
| `name` | the animation's name **inside the XML/atlas** — this usually differs from `anim` |
| `fps`, `loop` | playback speed and whether it repeats |
| `offsets` | per-animation x/y nudge, used to line pixel art up |
| `indices` | frame order, for sheets whose frames are not in animation order |

### Alt and censor animations

Section `altAnim` flags and cutscenes ask for names like `singLEFT-alt` or `-censor`. If a character JSON does not define that exact animation, the engine falls back to the base name instead of showing a T-pose or crashing. Ship the `-alt` animations when you want a distinct look; skip them and the base animation plays.

## Missing art is not faked

If a character, icon or animation references a file that does not exist, the engine reports it rather than substituting a stand-in. A silent dark placeholder almost always means a wrong `image` path or a typo between `anim` and `name`.

## Menu characters

Story-mode and freeplay icons are a **separate** system: `images/menucharacters/<name>.png` + `.xml`, sparrow format only, referenced from a week's `weekCharacters`. An Animate-atlas character cannot be dropped into a menu slot without exporting a sparrow sheet.

## Making one

1. Copy a similar character JSON from `assets/base_game/shared/characters/`.
2. Change `image`, `healthicon` and every `name` to match your XML.
3. Drop the `.json` into `mods/My-Mod/characters/` and the art into `mods/My-Mod/images/characters/`.
4. Use the **Character Editor** (`source/states/editors/CharacterEditorState.hx`) to check offsets and animation names live; it can write the JSON back.

`docs/characters/TemplateCharacter.hx` and `TemplateCharacter.lua` are script templates for character behaviour.
