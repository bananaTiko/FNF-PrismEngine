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
	}

	/** Records a finished song run. */
	public static function addSong(hit:Int, missed:Int, seconds:Float):Void
	{
		load();

		songsPlayed++;
		notesHit += hit;
		notesMissed += missed;
		secondsPlayed += (seconds > 0 ? seconds : 0);

		if (FlxG.save == null || FlxG.save.data == null) return;
		Reflect.setField(FlxG.save.data, SAVE_KEY, {
			songsPlayed: songsPlayed,
			notesHit: notesHit,
			notesMissed: notesMissed,
			secondsPlayed: secondsPlayed
		});
		FlxG.save.flush();
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

		if (hours > 0) return '${hours}h ${minutes}m';
		if (minutes > 0) return '${minutes}m ${seconds}s';
		return '${seconds}s';
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
