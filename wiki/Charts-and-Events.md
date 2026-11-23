# Charts and Events

A song is a folder inside a mod (or `assets/shared/songs/`) named after the song:

```
mods/My-Mod/songs/bopeebo/
  bopeebo.json          the chart
  events.json           events (optional)
  Inst.ogg              instrumental
  Voices-Player.ogg     player vocals (optional)
  Voices-Opponent.ogg   opponent vocals (optional)
```

Audio can be `.ogg`, `.wav` or `.flac`; the engine tries them in that order and uses the first it finds, so an `.ogg` sitting next to a `.wav` always wins. Song-length audio is streamed, not loaded into RAM. FLAC is desktop-only — see [Troubleshooting](Troubleshooting) if a song reports missing audio on another target.

Vocal variants the engine understands: `Voices-Player` + `Voices-Opponent`, per-character `Voices-<character>`, or a single `Voices` for both.

## Chart JSON

```json
{
  "song": {
    "song": "bopeebo",
    "bpm": 100,
    "speed": 1.0,
    "player1": "bf",
    "player2": "dad",
    "gfVersion": "gf",
    "stage": "stage",
    "needsVoices": true,
    "validScore": true,
    "notes": [
      {
        "sectionNotes": [[0, 0, 250]],
        "lengthInSteps": 16,
        "mustHitSection": true,
        "bpm": 100,
        "changeBPM": false,
        "altAnim": false
      }
    ],
    "events": []
  }
}
```

| Field | Meaning |
| --- | --- |
| `song` | song name; matches the folder name |
| `bpm`, `speed` | default tempo and scroll speed |
| `player1` / `player2` | character JSON names for the player and opponent |
| `gfVersion` | the background character |
| `stage` | stage JSON name |
| `needsVoices` | whether vocal tracks are loaded |
| `notes[]` | sections, in order |
| `sectionNotes` | notes in the section: `[timeMs, noteData, sustainMs, noteType?]` |
| `lengthInSteps` | how many steps (16ths) the section lasts |
| `mustHitSection` | whether the player's side is the one being sung |
| `changeBPM` + `bpm` | per-section tempo change |
| `altAnim` | makes the opponent use its `-alt` animations |

`noteData` is `0–3` for the opponent's left/down/up/right, `4–7` for the player's. A `mustHitSection` flips which side the same numbers belong to, which is what the Chart Editor writes.

## Events

Events are `[timeMs, eventName, value1, value2]` triples attached to the chart or to `events.json`:

```json
{ "events": [[1500, "Hey!", "bf", "0.6"]] }
```

**`events.json` always wins.** If the song folder has one, the engine replaces whatever the chart file had with it (`Song.mergeEventFile`), so converted charts that kept stale inline events do not fight the event file. Keep events in `events.json` for this fork.

Event names are case- and spelling-normalised, so `zoom_camera`, `Zoom Camera` and legacy V-Slice spellings all reach the same handler (`PlayState.normalizeEventName`):

| Written as | Normalised to |
| --- | --- |
| `zoom_camera` | `Zoom Camera` |
| `target_camera` | `Target Camera` |
| `set_camera_bop` / `setcamerabop` / `set camera bop` | `Set Camera Bopping` |
| `trgger bg ghouls` (sic) | `Trigger BG Ghouls` |
| `camera follow pos` | `Camera Follow Pos` |
| `play animation` | `Play Animation` |
| `change character` | `Change Character` |
| `add camera zoom` | `Add Camera Zoom` |

Any other name is passed through untouched, which is how custom events from `custom_events/` are matched.

## Importing other chart formats

The Chart Editor can import charts through **moonchart** (`backend/MoonchartImporter.hx`):

- FNF Legacy / Psych / V-Slice / Kade / Codename / Imaginative
- osu!mania, Quaver, StepMania, Guitar Hero, MIDI

Pick the file in the editor's import option and it is converted to this engine's chart JSON. Check the result visually afterwards — holds, note types and event timing are the parts worth double-checking after a conversion.

## Time signatures

`backend/TimeSignature.hx` means charts are not limited to 4/4. Signature changes are read from the chart, so sections and the editor's grid follow the song rather than assuming four beats per bar.

## Chart Editor

The editor (`source/states/editors/ChartingState.hx`) is reachable from the **Editors** menu, with the `7` debug key from the main menu, or from the pause menu during a song. It writes the chart back into the song folder it loaded from — keep a copy before editing a song you care about.

Sibling editors, all under `source/states/editors/`: Character, Stage, Week, Dialogue, Dialogue Character, Menu Character, Note Splash.

## Validation in CI

Every push parses all `assets/**/*.json` before starting a build. A trailing comma in a chart or event file stops CI in about a second with the file name and reason, instead of spending twenty minutes compiling an engine that would fail when the song loads. Run the same check locally with:

```bash
node .github/scripts/check-assets.js
```
