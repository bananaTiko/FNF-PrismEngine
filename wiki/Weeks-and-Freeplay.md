# Weeks and Freeplay

A week is a `.json` file in a mod's `weeks/` folder (or `assets/base_game/shared/weeks/`). The file name is the week's id; the engine reads every week JSON it can find and lists them in Story Mode and Freeplay.

## Fields

```json
{
  "songs": [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]]],
  "weekCharacters": ["dad", "bf", "gf"],
  "weekBackground": "stage",
  "storyName": "Daddy Dearest",
  "weekBefore": "tutorial",
  "weekName": "Week 1",
  "startUnlocked": true,
  "hideStoryMode": false,
  "hideFreeplay": false,
  "difficulties": ""
}
```

| Field | Meaning |
| --- | --- |
| `songs` | `[songName, iconName, [r, g, b]]` per song — the icon and colour shown on the week's track list |
| `weekCharacters` | menu characters: `[opponent, player, girlfriend]`, sparrow sheets from `images/menucharacters/`. An empty string leaves that slot blank |
| `weekBackground` | the track-list background, `images/menubackgrounds/<name>.png` (a 1280×386 banner under the top bar) |
| `storyName` | subtitle shown in Story Mode |
| `weekName` | title shown in Story Mode and used as the progress key |
| `weekBefore` | the week that must be finished first; omit for none |
| `startUnlocked` | unlocked from the start regardless of `weekBefore` |
| `hiddenUntilUnlocked` | hide the week entirely until it unlocks |
| `hideStoryMode` / `hideFreeplay` | keep the songs out of one of the two menus |
| `difficulties` | comma-separated difficulty list override; empty means the default set |

## Week banners and backgrounds

`weekBackground` is a **banner**, drawn under the top bar and scaled to the window width — not a full-screen image. A full-screen background belongs in `weekBackground` too when used as a menu background, but the Story Mode track list expects the wide 1280×386 shape, so art cropped for a 16:9 screen will lose its edges there.

Menu characters need sparrow sheets (`images/menucharacters/<name>.png` + `.xml`). Animate-atlas characters cannot be used in these slots.

## Story Mode vs Freeplay

- **Story Mode** walks a week's songs in order and saves progress against `weekName`.
- **Freeplay** lists every song from every week that is not marked `hideFreeplay`, plus songs that belong to no week.

Both read the same week files, so a song appears only once even if several weeks reference it.

## Freeplay shortcuts

| Input | Effect |
| --- | --- |
| `R` once | jump to a random song |
| `R` twice within 0.4 s | prompt to reset that song's score |
| typing | filters the list through the search box |

The double-press window is `RESET_DOUBLE_PRESS` in `source/states/FreeplayState.hx`.

## Week Editor

`source/states/editors/WeekEditorState.hx` edits a week and writes the JSON back. It also draws the banner the same way Story Mode does, so an incorrectly sized image shows up immediately rather than only in game.
