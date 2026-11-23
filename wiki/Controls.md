# Controls

Defaults come straight from `source/backend/ClientPrefs.hx` (`keyBinds` and `gamepadBinds`). Every bind has **two** slots — a primary and a secondary.

## Gameplay

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Note left | `A` / `←` | D-pad left / `X` |
| Note down | `S` / `↓` | D-pad down / `A` |
| Note up | `W` / `↑` | D-pad up / `Y` |
| Note right | `D` / `→` | D-pad right / `B` |

## Menus

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Navigate | `W` `A` `S` `D` / arrow keys | D-pad or left stick |
| Accept | `SPACE` / `ENTER` | `A` / `START` |
| Back | `BACKSPACE` / `ESCAPE` | `B` |
| Pause | `ENTER` / `ESCAPE` | `START` |
| Reset | `R` | `BACK` |

## Audio

| Action | Keyboard |
| --- | --- |
| Mute | `0` |
| Volume up | `NUMPAD +` / `+` |
| Volume down | `NUMPAD -` / `-` |

## Debug

| Action | Keyboard |
| --- | --- |
| Debug 1 (chart/debug overlay) | `7` |
| Debug 2 | `8` |

## Freeplay and other shortcuts

| Where | Input | Effect |
| --- | --- | --- |
| Freeplay | `R` (single press) | Jump to a random song |
| Freeplay | `R` twice within 0.4 s | Ask to reset that song's score |
| Freeplay | type in the search box | Filter the song list |
| Anywhere | gamepad | Pause/resume with `START` |

The 0.4 s window for the double-press reset is `RESET_DOUBLE_PRESS` in `source/states/FreeplayState.hx`.

## Changing the binds

**In game:** Options → Controls. Each action shows both slots; press the slot, then the new key.

**In files:** binds are stored in `settings.json` under `keyboard` and `gamepad` next to the executable. Delete the file (or use *Reset to default* in the Controls menu) to go back to the table above.

**In source:** add an entry to `ClientPrefs.keyBinds`, then expose it in `source/states/options/ControlsSubState.hx` (the label list) and, if gameplay code should read it directly, add a getter in `source/backend/Controls.hx`. Code can also skip the getter and call `controls.justPressed("your_action")` by name.
