package psychlua;

#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
import lime.system.Clipboard;

/**
 * In-game console for Lua/HScript messages.
 * Open it with F1 during a song, press F5 to hot-reload every loaded script.
 */
class ScriptConsole extends MusicBeatSubstate
{
	static final MAX_VISIBLE:Int = 20;

	var titleText:FlxText;
	var logText:FlxText;
	var hintText:FlxText;

	var scroll:Int = 0;
	var started:Bool = false;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.85;
		bg.scrollFactor.set();
		add(bg);

		titleText = new FlxText(20, 10, FlxG.width - 40, '', 24);
		titleText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT);
		titleText.scrollFactor.set();
		add(titleText);

		logText = new FlxText(20, 46, FlxG.width - 40, '', 16);
		logText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT);
		logText.scrollFactor.set();
		add(logText);

		hintText = new FlxText(20, FlxG.height - 62, FlxG.width - 40, '', 16);
		hintText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.YELLOW, LEFT);
		hintText.scrollFactor.set();
		add(hintText);

		refresh();
	}

	function getLog():Array<states.PlayState.ScriptLogEntry>
	{
		if (PlayState.instance == null) return [];
		return PlayState.instance.scriptLog;
	}

	function refresh():Void
	{
		var logs:Array<states.PlayState.ScriptLogEntry> = getLog();

		if (logs.length < 1)
		{
			logText.text = 'No script messages yet.';
			scroll = 0;
		}
		else
		{
			var maxScroll:Int = Std.int(Math.max(0, logs.length - MAX_VISIBLE));
			scroll = Std.int(FlxMath.bound(scroll, 0, maxScroll));

			var lines:Array<String> = [];
			var end:Int = Std.int(Math.min(logs.length, scroll + MAX_VISIBLE));
			for (i in scroll...end)
				lines.push(logs[i].text);

			logText.text = lines.join('\n');
		}

		titleText.text = 'SCRIPT CONSOLE  (' + logs.length + ' message' + (logs.length == 1 ? '' : 's') + ')';
		hintText.text = 'F5: reload scripts   C: copy log   UP/DOWN: scroll   ESC: close';
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Ignore the keys that were used to open the console
		if (!started)
		{
			started = true;
			return;
		}

		if (FlxG.keys.justPressed.UP)
		{
			scroll--;
			refresh();
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			scroll++;
			refresh();
		}
		if (FlxG.keys.justPressed.PAGEUP)
		{
			scroll -= MAX_VISIBLE;
			refresh();
		}
		if (FlxG.keys.justPressed.PAGEDOWN)
		{
			scroll += MAX_VISIBLE;
			refresh();
		}

		if (FlxG.keys.justPressed.C)
		{
			var lines:Array<String> = [];
			for (entry in getLog())
				lines.push(entry.text);

			Clipboard.text = lines.join('\n');
			hintText.text = 'Log copied to the clipboard!';
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
		}

		if (FlxG.keys.justPressed.F5 && PlayState.instance != null)
		{
			PlayState.instance.reloadScripts();
			refresh();
		}

		if (controls.BACK)
			close();
	}
}
#end
