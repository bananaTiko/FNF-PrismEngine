package psychlua;

import flixel.util.FlxTimer;

/**
 * Named timers owned by one script. Both the Lua and the Prism backends use this so a script
 * can name, replace and cancel its timers without keeping FlxTimer handles around, and so
 * everything is dropped when the script closes.
 */
class ScriptTimers
{
	var timers:Map<String, FlxTimer> = new Map();

	public function new() {}

	/** Runs `callback` once after `seconds`. Reusing a name replaces the old timer. */
	public function setTimeout(name:String, seconds:Float, callback:Void->Void):Bool
	{
		cancel(name);

		var timer:FlxTimer = new FlxTimer();
		timers.set(name, timer);
		timer.start(Math.max(seconds, 0.0001), function(_) {
			timers.remove(name);
			callback();
		}, 1);
		return true;
	}

	/** Runs `callback` every `seconds` until it is cancelled or the script closes. */
	public function setInterval(name:String, seconds:Float, callback:Void->Void):Bool
	{
		cancel(name);

		var timer:FlxTimer = new FlxTimer();
		timers.set(name, timer);
		timer.start(Math.max(seconds, 0.0001), function(_) callback(), 0);
		return true;
	}

	public function cancel(name:String):Bool
	{
		var timer:FlxTimer = timers.get(name);
		if(timer == null) return false;

		timer.cancel();
		timers.remove(name);
		return true;
	}

	public function clear():Void
	{
		for (timer in timers)
			if(timer != null) timer.cancel();

		timers = new Map();
	}

	public function count():Int
	{
		var total:Int = 0;
		for (_ in timers.keys()) total++;
		return total;
	}
}
