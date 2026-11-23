# Mods

A mod is a folder inside `mods/` next to the executable that mirrors the engine's own asset paths. The engine looks in enabled mods first and falls back to `assets/`, which is why an override only needs the file you changed, at the same relative path.

`MODS_ALLOWED` must be defined in `Project.xml` (it is by default on desktop).

## Create a mod

The quickest start is the template shipped in the repository:

```bash
# from the repository root
unzip example_mods/modTemplate.zip -d mods/
```

That gives you `mods/My-Mod/` with every folder and a `readme.txt` explaining each one:

```
My-Mod/
  pack.json            metadata shown in the mods menu
  pack.png             icon (square)
  characters/          character .json files
  custom_events/       custom event scripts
  custom_notetypes/    note type data
  data/                achievements.json, credits.txt, introText.txt, .lang files
  images/              characters/, icons/, noteSkins/, noteSplashes/, menubackgrounds/, …
  music/               menu music
  scripts/             .lua / .hx / .prism scripts
  shaders/             .frag shaders
  songs/<song>/        charts, events.json, Inst / Voices audio
  stages/              stage .json files
  videos/              cutscene videos
  weeks/               week .json files
```

`example_mods/prism_test/` is a smaller working example (a single `.prism` script).

## pack.json

```json
{
  "name": "Name",
  "description": "Description",
  "restart": false,
  "runsGlobally": false,
  "color": [170, 0, 255],
  "discordRPC": "863222024192262205",
  "iconFramerate": 10
}
```

| Field | Meaning |
| --- | --- |
| `name` | folder name shown in the mods menu; must match the folder |
| `description` | text under the icon |
| `restart` | ask to restart the game after toggling this mod |
| `runsGlobally` | keep its scripts running in every menu, not only in its own songs |
| `color` | menu accent colour |
| `discordRPC` | Discord application ID used while this mod is active |
| `iconFramerate` | animation speed of `pack.png` (animated PNG/sequence) |

Missing `pack.json` is not fatal; the mod still loads, but shows up with a default icon and no description.

## Enabling and disabling

The **Mods** menu toggles mods at runtime and writes the result to `mods/modsList.txt`:

```
My-Mod|1
Other-Mod|0
```

`1` is enabled, `0` is disabled, one mod per line in load order. **Earlier lines load first**, and the last enabled mod that contains a given file wins. Edit the file directly if you want a specific order; the menu rewrites it.

Some changes (stages, characters, weeks) need a restart, which is what `pack.json`'s `restart` flag is for.

## Overriding engine content

To change one file, copy it out of `assets/` and put the **same relative path** into your mod:

```
assets/base_game/week1/images/countdown.png
→ mods/My-Mod/images/countdown.png
```

Do not copy whole `assets/` trees — an override is a single file, and duplicating the rest just makes the mod huge and hides future engine updates.

## Scripts

`scripts/` holds `.lua`, `.hx` and `.prism` scripts. Songs can also carry their own script named after the song (`songs/mysong/mysong.lua`). See [Scripting](Scripting) for what can be scripted and what the `.prism` extension means here.

## Distribution

Zip the mod folder itself (not its contents), so extracting into `mods/` recreates `mods/My-Mod/`. Keep `pack.json` inside it and avoid absolute paths.
