package backend;

/**
 * Lifetime play statistics that persist across sessions, in the spirit of Kade Engine's Stats class.
 * Kept out of ClientPrefs so it never shows up in the options menu, and loaded lazily because the
 * save file may not be open yet when the game boots.
 */
class PlayStats
{
	static inline var SAVE_KEY:String = 'playStats';

	public static var songsPlayed:Int = 0;
	public static var notesHit:Int = 0;
	public static var notesMissed:Int = 0;
	public static var secondsPlayed:Float = 0;
	/** "song|difficulty" keys, most recently played first. */
	public static var recentKeys:Array<String> = [];
	static inline var MAX_RECENT:Int = 30;

	static var loaded:Bool = false;

	public static function load():Void
	{
		if (loaded) return;
		loaded = true;
		if (FlxG.save == null || FlxG.save.data == null) return;

		var saved:Dynamic = Reflect.field(FlxG.save.data, SAVE_KEY);
		if (saved == null) return;

		songsPlayed = intField(saved, 'songsPlayed');
		notesHit = intField(saved, 'notesHit');
		notesMissed = intField(saved, 'notesMissed');
		secondsPlayed = floatField(saved, 'secondsPlayed');

		var recent:Dynamic = Reflect.field(saved, 'recentKeys');
		if(recent != null && Std.isOfType(recent, Array))
			for (entry in (recent:Array<Dynamic>))
				if(entry != null) recentKeys.push(Std.string(entry));
	}

	/** Records a finished song run. */
	public static function addSong(hit:Int, missed:Int, seconds:Float):Void
	{
		load();

		songsPlayed++;
		notesHit += hit;
		notesMissed += missed;
		secondsPlayed += (seconds > 0 ? seconds : 0);

		save();
	}

	public static function totalNotes():Int
		return notesHit + notesMissed;

	/** Lifetime accuracy across every note ever hit, as a 0-100 percentage. */
	public static function lifetimeAccuracy():Float
	{
		var total:Int = totalNotes();
		if (total <= 0) return 0;
		return (notesHit / total) * 100;
	}

	public static function playTimeString():String
	{
		var total:Int = Std.int(secondsPlayed);
		var hours:Int = Std.int(total / 3600);
		var minutes:Int = Std.int((total % 3600) / 60);
		var seconds:Int = total % 60;

		if (hours > 0) return Language.getPhrase('playtime_hours', '{1}h {2}m', [hours, minutes]);
		if (minutes > 0) return Language.getPhrase('playtime_minutes', '{1}m {2}s', [minutes, seconds]);
		return Language.getPhrase('playtime_seconds', '{1}s', [seconds]);
	}

	/** Notes that a song was played, for Freeplay's "Recent" sort. */
	public static function recordRecent(songKey:String):Void
	{
		if(songKey == null || songKey.length < 1) return;
		load();

		recentKeys.remove(songKey);
		recentKeys.insert(0, songKey);
		while(recentKeys.length > MAX_RECENT) recentKeys.pop();
		save();
	}

	static function save():Void
	{
		if (FlxG.save == null || FlxG.save.data == null) return;

		Reflect.setField(FlxG.save.data, SAVE_KEY, {
			songsPlayed: songsPlayed,
			notesHit: notesHit,
			notesMissed: notesMissed,
			secondsPlayed: secondsPlayed,
			recentKeys: recentKeys.copy()
		});
		FlxG.save.flush();
	}

	public static function getRecentKeys():Array<String>
	{
		load();
		return recentKeys;
	}

	static function intField(obj:Dynamic, field:String):Int
	{
		var value:Dynamic = Reflect.field(obj, field);
		return (value == null) ? 0 : Std.int(value);
	}

	static function floatField(obj:Dynamic, field:String):Float
	{
		var value:Dynamic = Reflect.field(obj, field);
		return (value == null) ? 0 : (value : Float);
	}
}
