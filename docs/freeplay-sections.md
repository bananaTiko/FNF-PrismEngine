# Freeplay sections

Freeplay's mixes (the tabs at the top, e.g. `BF MIXES` / `PICO MIXES`) and the sections under
them (`BF Mixes`, `Pico Mixes`, ...) are no longer hardcoded per menu. The stock ones live in
`FreeplayState`, and any mod can add to them — or add completely new sections and mixes — with a
small data file.

## Where the file goes

| Who | Path |
| --- | --- |
| Mods folder (all mods) | `mods/data/freeplay-sections.json` |
| Enabled mod | `mods/<mod>/data/freeplay-sections.json` |

This is the same search order the weeks use: the stock sections are built first, then the mods
folder, then each enabled mod in load order. Every file found is merged into the list.

A mod only describes what it adds. It never has to copy the stock file, and it can't remove
stock songs.

## Format

```json
{
  "mixes": [
    { "name": "BF MIXES", "sections": ["BF Mixes"] }
  ],
  "sections": [
    { "name": "BF Mixes", "mix": "BF MIXES", "songs": ["bopeebo", "fresh"] }
  ]
}
```

Both blocks are optional.

- `mixes[].name` — the tab label, shown as written (upper case is the stock style).
- `mixes[].sections` — sections shown in that tab, in order. A mix that doesn't exist yet is
  created.
- `sections[].name` — the heading drawn above that group of songs.
- `sections[].mix` — optional shortcut that puts the section in that mix without editing the
  `mixes` block.
- `sections[].songs` — song names as they appear in the week files, case-insensitive. Songs are
  appended in the order given, so a mod adding to a stock section lands at the end of it.

Songs only show up in Freeplay if they belong to a week (`data/<mod>/weeks/*.json`), same as
normal mods. Anything not named in a sections file still appears, grouped by its opponent.
Erect charts are difficulties of their base song, not separate Freeplay entries.

## Example: a mod adding its own section and songs

`mods/my-mod/data/freeplay-sections.json`:

```json
{
  "sections": [
    { "name": "My Mod", "mix": "BF MIXES", "songs": ["my song", "my song (pico mix)"] }
  ]
}
```

Freeplay then shows a `MY MOD` heading under the `BF MIXES` tab with those songs in it.

## Example: a mod adding a whole mix

```json
{
  "mixes": [
    { "name": "EXTRA MIXES", "sections": ["Extra Mix"] }
  ],
  "sections": [
    { "name": "Extra Mix", "songs": ["my song"] }
  ]
}
```

A third tab named `EXTRA MIXES` appears beside the stock ones and can be switched to with the mix
controls or by clicking it. Sections can be shared between mixes, and a section with no songs in
it simply draws no heading.
