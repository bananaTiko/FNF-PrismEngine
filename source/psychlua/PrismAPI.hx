package psychlua;

#if HSCRIPT_ALLOWED
import backend.Paths;

/**
 * Gives Prism scripts the Lua-style globals that HScript does not have, without taking away
 * the real classes HScript already exposes. Everything here is a thin adapter over the same
 * helpers the Lua API uses, so both languages see one engine.
 */
class PrismAPI
{
	static inline function define(script:HScript, name:String, value:Dynamic):Void
		script.defineGlobal(name, value);

	static function logValue(value:Dynamic):Dynamic
	{
		var text:String = Std.string(value);
		if(PlayState.instance != null) PlayState.instance.addTextToDebug(text, FlxColor.WHITE);
		else trace(text);
		return value;
	}

	public static function inject(script:HScript):Void
	{
		if(script.scriptTimers == null) script.scriptTimers = new ScriptTimers();

		// --- Property access, the way Lua scripts spell it ---
		define(script, 'getProperty', function(name:String, ?variable:String = null) {
			// Both Lua spellings work: getProperty('sprite', 'alpha') and getProperty('sprite.alpha')
			if(variable == null && name.contains('.'))
			{
				variable = name.substr(name.indexOf('.') + 1);
				name = name.substr(0, name.indexOf('.'));
			}
			var obj:Dynamic = LuaUtils.getObjectDirectly(name);
			if(variable == null) return obj;
			return obj == null ? null : LuaUtils.getVarInArray(obj, variable);
		});
		define(script, 'setProperty', function(name:String, variable:String, ?value:Dynamic = null) {
			// setProperty('sprite', 'alpha', 0.5) or setProperty('sprite.alpha', 0.5)
			if(value == null && variable != null && name.contains('.'))
			{
				value = variable;
				variable = name.substr(name.indexOf('.') + 1);
				name = name.substr(0, name.indexOf('.'));
			}
			var obj:Dynamic = LuaUtils.getObjectDirectly(name);
			if(obj != null) LuaUtils.setVarInArray(obj, variable, value);
		});
		define(script, 'getPropertyFromClass', function(className:String, variable:String) {
			var cl:Dynamic = Type.resolveClass(className);
			return cl == null ? null : LuaUtils.getVarInArray(cl, variable);
		});
		define(script, 'setPropertyFromClass', function(className:String, variable:String, value:Dynamic) {
			var cl:Dynamic = Type.resolveClass(className);
			if(cl != null) LuaUtils.setVarInArray(cl, variable, value);
		});
		define(script, 'object', function(name:String) return LuaUtils.getObjectDirectly(name));

		// --- Notes ---
		define(script, 'note', function(id:Int) {
			var game:PlayState = PlayState.instance;
			if(game == null || game.notes == null || id < 0 || id >= game.notes.members.length) return null;
			return game.notes.members[id];
		});
		define(script, 'noteCount', function() {
			var game:PlayState = PlayState.instance;
			return (game == null || game.notes == null) ? 0 : game.notes.members.length;
		});

		// --- Audio ---
		define(script, 'playSound', function(name:String, ?volume:Float = 1) return FlxG.sound.play(Paths.sound(name), volume));
		define(script, 'playMusic', function(name:String, ?volume:Float = 1) return FlxG.sound.playMusic(Paths.music(name), volume));

		// --- Timers, with Haxe closures instead of Lua function names ---
		define(script, 'setTimeout', function(name:String, ms:Float, callback:Void->Void) {
			return script.scriptTimers.setTimeout(name, ms / 1000, callback);
		});
		define(script, 'setInterval', function(name:String, ms:Float, callback:Void->Void) {
			return script.scriptTimers.setInterval(name, ms / 1000, callback);
		});
		define(script, 'cancelTimer', function(name:String) return script.scriptTimers.cancel(name));
		define(script, 'clearTimers', function() {
			script.scriptTimers.clear();
			return true;
		});

		// --- Small conveniences: Python-ish, so simple scripts stay short ---
		define(script, 'print', function(value:Dynamic) return logValue(value));
		define(script, 'println', function(value:Dynamic) return logValue(value));
		define(script, 'len', function(value:Dynamic) {
			if(value == null) return 0;
			if(Std.isOfType(value, Array)) return (cast value : Array<Dynamic>).length;
			if(Std.isOfType(value, String)) return (value : String).length;
			return 0;
		});
		define(script, 'str', function(value:Dynamic) return Std.string(value));
		define(script, 'int', function(value:Dynamic) return Std.int(Std.parseFloat(Std.string(value))));
		define(script, 'float', function(value:Dynamic) return Std.parseFloat(Std.string(value)));
		define(script, 'range', function(count:Int) {
			var out:Array<Int> = [];
			for (i in 0...Std.int(Math.max(count, 0))) out.push(i);
			return out;
		});

		// --- Stop constants, same values the Lua side uses ---
		define(script, 'Function_Continue', LuaUtils.Function_Continue);
		define(script, 'Function_Stop', LuaUtils.Function_Stop);
		define(script, 'Function_StopLua', LuaUtils.Function_StopLua);
		define(script, 'Function_StopHScript', LuaUtils.Function_StopHScript);
		define(script, 'Function_StopAll', LuaUtils.Function_StopAll);

		define(script, 'MathUtils', backend.MathUtils);
	}
}
#end
