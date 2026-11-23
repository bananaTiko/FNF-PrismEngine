# Scripting

Mods can change the game without touching the engine source. Three languages are available, and the scripting defines must be on in `Project.xml` (`LUA_ALLOWED`, `HSCRIPT_ALLOWED` — both on by default on desktop).

| Extension | Language | Compile flag |
| --- | --- | --- |
| `.lua` | Lua via linc_luajit | `LUA_ALLOWED` |
| `.hx` | HScript — Haxe syntax, real engine classes | `HSCRIPT_ALLOWED` |
| `.prism` | HScript with the Lua API bolted on, plus Python-flavoured syntax | `HSCRIPT_ALLOWED` |

## Where scripts live

```
mods/My-Mod/scripts/anything.lua        runs in every song of that mod
mods/My-Mod/songs/bopeebo/extra.hx      runs only in that song
mods/My-Mod/songs/bopeebo/whatever.prism
```

A script is picked up by extension, and every enabled mod's `scripts/` folder is loaded for its songs. `pack.json`'s `"runsGlobally": true` keeps a mod's scripts running outside songs as well.

## `.prism` scripts

`source/psychlua/PrismScript.hx` — this is the fork's own addition, and the one to reach for if you know Haxe. It is HScript, so you get real engine classes (`PlayState`, `Conductor`, `FlxG`), *and* the Lua helper API (`setProperty`, `getProperty`, `setTimeout`, `setInterval`, …) in the same file, plus some Python conveniences:

```
# comments start with a hash
local loaded = false        # `local` and `nil` work like in Python

function onCreate()
{
	var bf = nil
	if (bf == nil) print('nil works like null')

	setProperty('boyfriend', 'alpha', 1)
	setTimeout('hello', 1200, function() {
		print('timer fired 1.2 seconds in')
	})
}
```

A working example is `example_mods/prism_test/scripts/prism_test.prism`.

### Load order

Two header comments control ordering, anywhere in the file:

```
//@priority 10            # higher runs first
//@requires other.prism   # this script loads after other.prism
```

Use `//@requires` rather than relying on file names when one script depends on another having set something up.

## `.hx` scripts

Plain HScript — Haxe syntax with no Lua helpers. Useful for strongly-typed work against engine classes. `docs/scripts/TemplateScript.hx` is a starting point, and `docs/characters/TemplateCharacter.hx` shows the per-character variant.

## `.lua` scripts

The full Psych Lua API, unchanged. Callbacks such as `onCreate`, `onUpdate`, `onStepHit`, `goodNoteHit`, `opponentNoteHit` and the `setProperty`/`getProperty` family all behave as they do in Psych 1.0.4.

The API reference lives at <https://shadowmario.github.io/psychengine.lua/>, and `docs/scripts/TemplateScript.lua` plus `TemplateScript.prism` are the local templates.

## Choosing one

| You want | Use |
| --- | --- |
| Familiar Psych mods, existing snippets | `.lua` |
| Engine classes and types | `.hx` |
| Engine classes *and* the Lua helpers, Python-ish syntax | `.prism` |

Mixing is fine: a mod can ship Lua for content and Prism for the parts that need engine internals.

## Debugging

- `print()` writes to the game's console/log.
- Errors in a script are reported with the file name; a script that silently does nothing is usually disabled with its mod in the [Mods](Mods) menu.
- IRIS_DEBUG is defined in `Project.xml` by default, so HScript errors carry a stack trace.
