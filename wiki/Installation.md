# Installation

## Playing a released build

Every push to a build branch runs the **Build** workflow, which produces one artifact per platform:

| Platform | Artifact | File inside |
| --- | --- | --- |
| Windows | `windowsBuild` | `PrismEngine.exe` |
| Linux | `linuxBuild` | `PrismEngine` |
| macOS | `macBuild` | `PrismEngine.app` |

1. Open the repository's **Actions** tab and pick the newest green **Build** run.
2. Download the artifact for your platform from the *Artifacts* section at the bottom of the run summary.
3. Extract the archive **as a folder** — the executable needs the files next to it (`assets/`, `mods/`, shared libraries).
4. Run the executable.

Artifacts are zipped per run and expire; if the run you want is gone, download a newer one or [build it yourself](Building).

### Platform notes

- **Windows** — if the engine fails to start, install the [Visual C++ Redistributable](https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist). SmartScreen may warn about an unsigned binary; that is expected for a self-built release.
- **Linux** — the build needs VLC at runtime for video cutscenes. Install it with your package manager (`vlc` on Debian/Ubuntu), otherwise cutscenes are skipped. If the binary is not marked executable, `chmod +x PrismEngine`.
- **macOS** — the app is unsigned, so Gatekeeper blocks it on first launch. Right-click the app → *Open*, or run `xattr -dr com.apple.quarantine PrismEngine.app`. Apple Silicon builds from CI are `arm64`.

## First launch

The engine writes its settings and save data next to the executable:

```
settings.json      options, keybinds, volumes
saveData/          scores, achievements, week progress
mods/              created on first run if missing
```

On first run the engine plays the intro. `ENTER` accepts, `ESCAPE` backs out, and everything else is on [Controls](Controls).

## Updating

Replace the executable and the files shipped with it. **Keep your `settings.json`, `saveData/` and `mods/`** — deleting them resets options, scores and installed mods.

## Uninstalling

Delete the folder. Nothing is written outside it, apart from an optional Discord rich-presence entry and, on Linux, the VLC packages you installed.
