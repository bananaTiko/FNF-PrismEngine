# Building

The full dependency walkthrough (with the Visual Studio installer command and distro package names) is in [`docs/BUILDING.md`](../docs/BUILDING.md). This page is the short version plus the things that actually break.

## Requirements

| | |
| --- | --- |
| Haxe | **4.3.4** — the version CI and the zlib patch are tested against |
| hxcpp | **4.3.2** — pinned in CI |
| git | for the `haxelib git` dependencies |
| Windows | Visual Studio 2022 with *Desktop development with C++* (`setup/msvc-windows.bat` installs it) |
| Linux | `libvlc-dev libvlccore-dev` for a full build, `vlc` to run cutscenes |
| macOS | Xcode command line tools |

## Install the libraries

From the repository root:

```bash
# Linux / macOS
sh setup/unix.sh
```

```bat
:: Windows
setup\windows.bat
```

Both scripts install the same set: `lime 8.1.2`, `openfl 9.3.3`, `flixel 5.6.1`, `flixel-addons 3.2.2`, `hxvlc`, `hxflac`, `flxgif`, plus git builds of `moonchart`, `flxanimate`, `linc_luajit`, `funkin.vis` and `grig.audio`. Each is a clone or a download, so the first run is slow — CI caches `~/haxelib` (or `C:/haxelib`) and skips this whole step when `Project.xml` and `setup/**` are unchanged.

They expect to be run from the repository root and `cd ..` inside themselves; that is normal and means the rest of the script runs one directory up.

## Compile

```bash
haxelib run lime build Project.xml linux -release
```

Substitute the target for the platform:

| Target | Command |
| --- | --- |
| Linux | `haxelib run lime build Project.xml linux -release` |
| Windows | `haxelib run lime build windows -release` |
| macOS | `haxelib run lime build mac -release` |

The output lands in `export/release/<target>/bin`. Builds are **incremental** — hxcpp only recompiles the generated `.cpp` files that changed — so the second build is far quicker than the first. A clean full build is several minutes; expect the log to be thousands of lines.

### Release builds with the official defines

```bash
haxelib run lime build Project.xml linux --app-version="4.0.0-1" -D officialBuild
```

`-D officialBuild` needs the VLC development headers. Without them it fails while linking `hxvlc`; either install `libvlc-dev` or build with plain `-release`.

## Customising the build

`Project.xml` holds every feature switch. Comment a line out to drop a feature:

```xml
<!-- <define name="LUA_ALLOWED" if="desktop" /> -->
```

| Define | Removes |
| --- | --- |
| `LUA_ALLOWED` | Lua scripting |
| `HSCRIPT_ALLOWED` | HScript (`.hx`) scripting |
| `MODS_ALLOWED` | mods folder, mods menu, mod loading |
| `ACHIEVEMENTS_ALLOWED` | achievements |
| `DISCORD_ALLOWED` | Discord rich presence |
| `TRANSLATIONS_ALLOWED` | language switching |
| `VIDEOS_ALLOWED` | video cutscenes (hxvlc) |

## How CI builds it

`.github/workflows/build.yml` builds all three platforms as **independent jobs**, so they start at the same time instead of queueing:

1. **Validate JSON assets** — parses all of `assets/**/*.json` first (about a second). A chart or event file with a syntax error would otherwise only surface when the game loads it; now it stops the job immediately.
2. **Caches** — the haxelib folder (keyed on `Project.xml` + `setup/**`) and hxcpp's object cache (`~/.hxcpp_cache` or `C:/hxcpp_cache`, keyed on `source/**/*.hx`).
3. **Compile** into `build.log`, printing errors only.
4. **Upload** the `bin` folder as an artifact.

hxcpp's object cache is what makes an asset-only push cheap: every generated `.cpp` is keyed by an md5 of its contents, so unchanged files are copied out of the cache instead of compiled. It is enabled by the `HXCPP_COMPILE_CACHE` **environment variable** (not a `-D` flag — hxcpp ignores the define), which is why the workflow exports it rather than passing it to `lime`.

## Publishing this wiki to GitHub

GitHub keeps wiki content in its own git repository. To publish the pages in `wiki/`:

```bash
# once, after creating any first page in the GitHub UI so the wiki repo exists
git clone https://github.com/bananaTiko/FNF-PrismEngine.wiki.git
cp wiki/*.md FNF-PrismEngine.wiki/
cd FNF-PrismEngine.wiki
git add . && git commit -m "Initial wiki" && git push
```

`_Sidebar.md` is picked up automatically by GitHub as the navigation sidebar.
