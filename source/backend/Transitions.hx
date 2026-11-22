package backend;

/**
 * Chooses what plays when a state changes.
 *
 * `ClientPrefs.data.transition` holds the name: `Fade` is the engine's own
 * CustomFadeTransition, `None` switches instantly (no transition substate at all),
 * and any other name is a script in `data/transitions/`, run by ScriptTransition.
 * A missing or broken script falls back to the fade, so a bad name can't lock the
 * player out of every menu.
 */
class Transitions
{
	public static inline var FADE:String = 'Fade';
	public static inline var NONE:String = 'None';
	public static inline var FOLDER:String = 'data/transitions/';

	/** Everything the options menu offers: the two built-ins, then the scripts found. */
	public static function names():Array<String>
	{
		var names:Array<String> = [FADE, NONE];
		#if HSCRIPT_ALLOWED
		for (name in scriptNames())
			if(!names.contains(name)) names.push(name);
		#end
		return names;
	}

	/** Names of the `.hx` files in data/transitions/, mods included. */
	public static function scriptNames():Array<String>
	{
		var names:Array<String> = [];
		#if HSCRIPT_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), FOLDER))
		{
			if(!FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) continue;

			for (file in FileSystem.readDirectory(folder))
			{
				if(!file.toLowerCase().endsWith('.hx')) continue;

				var name:String = file.substr(0, file.length - 3);
				if(!names.contains(name)) names.push(name);
			}
		}
		names.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
		#end
		return names;
	}

	/** Path of the script for a transition name, or null when it isn't one. */
	public static function scriptPath(name:String):Null<String>
	{
		#if HSCRIPT_ALLOWED
		if(name == null || name == FADE || name == NONE) return null;

		// directoriesWithFile() lists shared assets first and the loaded mod last,
		// so walk it backwards to let a mod override a transition it ships.
		var folders:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), FOLDER);
		var i:Int = folders.length - 1;
		while (i >= 0)
		{
			var path:String = folders[i] + name + '.hx';
			if(FileSystem.exists(path)) return path;
			--i;
		}
		#end
		return null;
	}

	/** Transition played while a state is being entered. */
	public static function playIn():Void
	{
		if(ClientPrefs.data.transition == NONE) return;

		#if HSCRIPT_ALLOWED
		var path:Null<String> = scriptPath(ClientPrefs.data.transition);
		if(path != null)
		{
			FlxG.state.openSubState(new ScriptTransition(0.5, true, path, ClientPrefs.data.transition));
			return;
		}
		#end

		FlxG.state.openSubState(new CustomFadeTransition(0.5, true));
	}

	/** Transition played while a state is being left; `onFinish` runs once it is over. */
	public static function playOut(onFinish:Void->Void):Void
	{
		if(ClientPrefs.data.transition == NONE)
		{
			onFinish();
			return;
		}

		#if HSCRIPT_ALLOWED
		var path:Null<String> = scriptPath(ClientPrefs.data.transition);
		if(path != null)
		{
			var trans:ScriptTransition = new ScriptTransition(0.5, false, path, ClientPrefs.data.transition);
			trans.finishCallback = onFinish;
			FlxG.state.openSubState(trans);
			return;
		}
		#end

		CustomFadeTransition.finishCallback = onFinish;
		FlxG.state.openSubState(new CustomFadeTransition(0.5, false));
	}
}
