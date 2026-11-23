# Prism Engine Wiki

**Prism Engine** is a fork of [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) 1.0.4 that also carries over a large amount of *V-Slice* (FNF 0.5+) content: its stages, characters, events, time signatures and chart formats run alongside Psych's own mod system, Lua/HScript scripting and editors.

It is a HaxeFlixel game, so everything here is about a compiled desktop binary — there is no separate runtime to install.

## Start here

| I want to… | Read |
| --- | --- |
| Play a released build | [Installation](Installation) |
| Compile the engine myself | [Building](Building) |
| Learn the keys | [Controls](Controls) |
| Make a mod | [Mods](Mods) |
| Chart a song / add events | [Charts and Events](Charts-and-Events) |
| Add or edit characters | [Characters](Characters) |
| Add a week or freeplay entry | [Weeks and Freeplay](Weeks-and-Freeplay) |
| Write Lua / HScript / Prism scripts | [Scripting](Scripting) |
| Fix a build or runtime error | [Troubleshooting](Troubleshooting) |

## What this fork adds over Psych 1.0.4

- **V-Slice content support** — V-Slice stages, characters and events are ported and driven through `backend/VsliceOptions.hx`, so a setting such as `SHADERS` or `FLASHBANG` maps onto this engine's own client preferences instead of a second options menu.
- **Time signatures** — `backend/TimeSignature.hx`, so charts are not locked to 4/4.
- **Chart importing via moonchart** — `backend/MoonchartImporter.hx` reads FNF Legacy/Psych/V-Slice/Kade/Codename/Imaginative, osu!mania, Quaver, StepMania, Guitar Hero and MIDI charts and converts them to Prism's chart JSON, loadable straight into the Chart Editor.
- **Split vocals** — `Voices-Player` / `Voices-Opponent`, or per-character `Voices-<character>`, instead of one combined `Voices`.
- **Streamed song audio** — instrumentals and vocals are decoded while they play rather than unpacked into RAM first.
- **Events always win** — a song's `events.json` overrides events stored inside the chart file, so events live in one place.

## Project facts

| | |
| --- | --- |
| Engine | Prism Engine (`com.bananaTiko.prismengine`) |
| Based on | Psych Engine 1.0.4 (HaxeFlixel / OpenFL / Lime) |
| Haxe | 4.3.4 (the version CI builds with) |
| Targets | Windows, Linux, macOS (desktop); Android/iOS/HTML5 exist in the Lime project but are not shipped by CI |
| Licence | see `LICENSE` in the repository |

## Where things live

```
source/            Haxe source
  backend/         shared systems: Paths, Song, ClientPrefs, Mods, Controls, …
  states/          menus, PlayState, editors, cutscenes
assets/            the game's assets
  base_game/       engine content, split by week/shared
  shared/          data shared by everything (weeks, characters, songs)
mods/              installed mods (created next to the executable at runtime)
docs/              build instructions and script/character templates
setup/             dependency install scripts used by CI and by hand
```

> This wiki lives in the repository under `wiki/`. GitHub's wiki is a separate git repository, so see the publishing note at the bottom of [Building](Building).
