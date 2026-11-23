# Troubleshooting

Problems actually hit while building and running this engine, and what fixes them.

## Building

### `haxelib run lime build … ` fails while linking `hxvlc` (`-D officialBuild`)

`officialBuild` enables VLC video support and needs the VLC **development** headers:

```bash
sudo apt-get install libvlc-dev libvlccore-dev   # Debian/Ubuntu
```

If you do not need videos, drop `-D officialBuild` and build with plain `-release`.

### `zutil.h` / `expected identifier or '('` on macOS

hxcpp 4.3.2 bundles zlib 1.2.11, whose `zutil.h` treats Apple's `TARGET_OS_MAC` (defined by Apple's own headers) as classic Mac OS 9 — it turns `fdopen` into a null macro and breaks `<stdio.h>` on the macOS 14+ SDK. CI patches it before compiling:

```bash
for f in $(find "$HOME/haxelib/hxcpp" -name zutil.h -path '*zlib*'); do
  sed -i '' 's/#if defined(MACOS) || defined(TARGET_OS_MAC)/#if defined(MACOS)/' "$f"
done
```

Run that once after installing hxcpp on macOS and the error is gone.

### `haxelib` cannot find a library

```bash
haxelib setup ~/haxelib     # or C:/haxelib on Windows
sh setup/unix.sh            # reinstall the dependency set
```

A dependency installed under a different haxelib repository is the usual cause; `haxelib list` shows every library with its version, and `haxelib set <lib> <version>` pins one.

### The build "hangs" with thousands of lines of output

It is not hanging — hxcpp is compiling. A clean full build takes several minutes and prints one line per file. Local builds are incremental: only changed `.cpp` files recompile, so the second build is much faster.

## Running

### A song says the instrumental or vocals are missing

Check the exact names in the song folder:

```
songs/<song>/Inst.ogg
songs/<song>/Voices-Player.ogg
songs/<song>/Voices-Opponent.ogg
```

`.ogg`, `.wav` and `.flac` are searched in that order. FLAC only works on desktop — if the target is Android, iOS or HTML5, keep an OGG or WAV copy, because hxflac does not build there and those targets never look for FLAC.

### Video cutscenes do not play

- Linux: VLC is a runtime dependency (`sudo apt-get install vlc`).
- Make sure `VIDEOS_ALLOWED` is still defined in `Project.xml`.

### Seeking in a FLAC song is slow

Expected. Streamed FLAC has to decode from the start of the file to seek, so "Skip Time" from the pause menu and resyncing after unpausing cost more than they do with OGG or WAV, which seek instantly. Ship OGG for songs where players skip around.

### A character or icon shows as a dark placeholder

The art referenced by the character JSON is missing. Check `image` (`characters/foo` → `images/characters/foo.png` + `.xml`) and that every animation `name` exists inside the sheet. Nothing is substituted silently — a placeholder means a real path mismatch, not a rendering bug.

### Alt or censor animations do nothing

Expected if the character JSON does not define them: the engine falls back from `singLEFT-alt` / `-censor` to `singLEFT` rather than breaking. Add the animations if you want a distinct look.

### Events in the chart are ignored

`events.json` in the song folder **overrides** the chart's inline events. Either edit `events.json` or delete it so the chart's list is used. See [Charts and Events](Charts-and-Events).

### Story Mode shows a squashed or cropped week banner

`weekBackground` is a wide banner (1280×386) drawn under the top bar and scaled to the window width. Art cropped for 16:9 loses its edges there.

## macOS says the app is damaged / cannot be opened

The build is unsigned. Right-click → **Open**, or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine PrismEngine.app
```

## Windows SmartScreen warning

Also expected for an unsigned binary. *More info* → *Run anyway*.

## Resetting everything

Settings, keybinds and scores live next to the executable:

```
settings.json
saveData/
```

Delete `settings.json` to reset options and keybinds, `saveData/` to reset progress and scores. Back up `mods/` first if you keep mods there.
