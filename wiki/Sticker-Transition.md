# Sticker Transition

A built-in transition that slaps a handful of stickers over the playfield while a song starts or ends — the screen V-Slice shows when you beat or quit a track.

It is the third built-in entry in **Options → Visuals → Transition**, next to `Fade` and `None`:

| Selection | Behaviour |
| --- | --- |
| `Fade` | default; black gradient wipe on every state change |
| `None` | switches instantly |
| `Sticker` | stickers on freeplay songs, fade everywhere else |

## Freeplay only

`Sticker` deliberately only plays where a freeplay song is involved (`backend/Transitions.hx`):

- **Entering a song** from Freeplay — stickers pop in over Freeplay as the song loads.
- **Leaving a song** back to Freeplay or the results screen — stickers pop in over the song.

Anything else — Story Mode, the main menu, options, the editors — falls back to the normal fade, so choosing `Sticker` cannot make the whole game choppy. Story Mode is recognised through `PlayState.isStoryMode`, which `FreeplayState` clears and `StoryMenuState` sets.

## Adding the art

There is no sticker art in the repository, so the transition is invisible until you provide some. Put PNGs here:

```
assets/shared/images/transitionSwag/default/*.png
```

or, to override without touching the engine, in a mod:

```
mods/My-Mod/images/transitionSwag/default/*.png
```

Every `.png` in the folder becomes a sticker, used in file-name order, up to 16 per change. They are scattered randomly across the screen, rotated up to 20°, scaled to 0.35–0.75 of their own size and popped in one after another.

### Ordering and picking

Add a `stickers.json` next to the images to choose which ones are used and in what order:

```json
{
  "name": "default",
  "artist": "",
  "stickers": ["one", "two", "three"]
}
```

Names are written **without** the `.png` extension. With no `stickers.json`, every PNG in the folder is used. A mod's folder takes priority over the shared one.

### Behaviour with no art

If the folder is empty or missing, the transition closes immediately and the state change happens at once. A player who selects `Sticker` without installing art sees an instant cut — never a blank screen or a stuck game.

## Technical notes

- `source/backend/StickerTransition.hx` is a `MusicBeatSubstate`, like the fade, and lasts 0.6 s.
- On enter it pops stickers in; on exit it fades them away.
- `Transitions.playOut` takes the state being switched to as an optional second argument, which is how "leaving a freeplay song" is told apart from "back to the main menu".
- `StickerTransition.stickerNames()` returns the names it found, which is handy for checking the folder is right.
