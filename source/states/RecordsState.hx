package states;

import backend.Difficulty;
import backend.Highscore;
import backend.PlayStats;

/**
 * Lifetime play records: totals from PlayStats plus the best saved score for every song/difficulty.
 * Opened from Options > Records.
 */
class RecordsState extends MusicBeatState
{
	inline static var MAX_ENTRIES:Int = 8;
	/** How long "press RESET again" stays up before the key goes back to being harmless. */
	inline static var CLEAR_CONFIRM_TIME:Float = 3;

	var statsText:FlxText;
	var scoresText:FlxText;
	var hintText:FlxText;
	var hintTimer:Float = 0;
	var clearArmed:Bool = false;

	override function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayStats.load();
		Highscore.load();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFF4a6fa5;
		bg.screenCenter();
		add(bg);

		var title:Alphabet = new Alphabet(0, 36, Language.getPhrase('records_title', 'Records'), true);
		title.screenCenter(X);
		add(title);

		statsText = new FlxText(0, 140, FlxG.width, buildStats(), 24);
		statsText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		statsText.borderSize = 2;
		add(statsText);

		scoresText = new FlxText(0, statsText.y + statsText.height + 30, FlxG.width, buildTopScores(), 20);
		scoresText.setFormat(Paths.font('vcr.ttf'), 20, 0xFFFFE9A6, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoresText.borderSize = 2;
		add(scoresText);

		hintText = new FlxText(0, FlxG.height - 44, FlxG.width, defaultHint(), 18);
		hintText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintText.borderSize = 1;
		add(hintText);

		super.create();
	}

	function buildStats():String
	{
		var lines:Array<String> = [
			Language.getPhrase('records_stats_songs', 'Songs played: {1}', [PlayStats.songsPlayed]),
			Language.getPhrase('records_stats_hit', 'Notes hit: {1}', [PlayStats.notesHit]),
			Language.getPhrase('records_stats_missed', 'Notes missed: {1}', [PlayStats.notesMissed]),
			Language.getPhrase('records_stats_accuracy', 'Lifetime accuracy: {1}%', [CoolUtil.floorDecimal(PlayStats.lifetimeAccuracy(), 1)]),
			Language.getPhrase('records_stats_time', 'Time played: {1}', [PlayStats.playTimeString()])
		];
		return lines.join('\n');
	}

	function buildTopScores():String
	{
		var entries:Array<{key:String, score:Int, rating:Float}> = [];
		for (key => score in Highscore.songScores)
		{
			if (score <= 0) continue;

			var rating:Float = Highscore.songRating.exists(key) ? Highscore.songRating.get(key) : 0;
			entries.push({key: key, score: score, rating: rating});
		}

		if (entries.length < 1)
			return Language.getPhrase('records_no_scores', 'No scores yet - go play something!');

		entries.sort(function(a, b):Int return b.score - a.score);

		var lines:Array<String> = [Language.getPhrase('records_best_scores', 'BEST SCORES')];
		var count:Int = Std.int(Math.min(entries.length, MAX_ENTRIES));
		for (i in 0...count)
		{
			var entry = entries[i];
			var line:String = '${i + 1}. ' + prettyKey(entry.key) + ' - ' + entry.score;
			if (entry.rating > 0)
				line += ' (' + CoolUtil.floorDecimal(entry.rating * 100, 1) + '%)';
			lines.push(line);
		}
		return lines.join('\n');
	}

	/** Turns a saved "bopeebo-hard" style key into "Bopeebo (Hard)". */
	static function prettyKey(key:String):String
	{
		var diff:Int = 0;
		for (i in 0...Difficulty.list.length)
		{
			var suffix:String = Difficulty.getFilePath(i);
			if (suffix.length > 0 && key.endsWith(suffix))
			{
				diff = i;
				key = key.substr(0, key.length - suffix.length);
				break;
			}
		}

		var name:String = key.replace('-', ' ');
		if (name.length > 0) name = name.substr(0, 1).toUpperCase() + name.substr(1);
		return name + ' (' + Difficulty.getString(diff) + ')';
	}

	static function defaultHint():String
		return Language.getPhrase('records_hint', 'BACK: Return    RESET: Clear records');

	function setHint(text:String, color:Int):Void
	{
		hintText.text = text;
		hintText.color = color;
	}

	function resetHint():Void
	{
		clearArmed = false;
		hintTimer = 0;
		setHint(defaultHint(), FlxColor.WHITE);
	}

	/** Wipes the lifetime stats and every saved song score, then redraws both lists. */
	function clearRecords():Void
	{
		PlayStats.reset();
		Highscore.resetAll();

		statsText.text = buildStats();
		scoresText.text = buildTopScores();
		scoresText.y = statsText.y + statsText.height + 30;

		FlxG.sound.play(Paths.sound('confirmMenu'));
		clearArmed = false;
		hintTimer = CLEAR_CONFIRM_TIME;
		setHint(Language.getPhrase('records_cleared', 'Records cleared'), 0xFF77FF77);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (hintTimer > 0)
		{
			hintTimer -= elapsed;
			if (hintTimer <= 0) resetHint();
		}

		if (controls.RESET)
		{
			// Two presses, so a stray R does not throw away every record.
			if (clearArmed)
			{
				clearRecords();
				return;
			}

			clearArmed = true;
			hintTimer = CLEAR_CONFIRM_TIME;
			setHint(Language.getPhrase('records_clear_confirm', 'Press RESET again to clear every record'), 0xFFFF5555);
			FlxG.sound.play(Paths.sound('scrollMenu'));
			return;
		}

		if (controls.BACK || controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new options.OptionsState());
		}
	}
}
