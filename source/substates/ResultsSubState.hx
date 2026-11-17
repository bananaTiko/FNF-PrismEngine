package substates;

import backend.CoolUtil;
import backend.Language;
import backend.Paths;
import backend.PlayStats;
import states.PlayState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
 * Score breakdown shown at the end of a song.
 *
 * Modelled on Unholy Engine's results screen (song title, big rank, stat rows) and on
 * Friday Night Funkin' V-Slice's rank/accuracy presentation. Every value comes from
 * PlayState's existing scoring, so it stays correct for mods that override it.
 */
typedef ResultsData =
{
	var song:String;
	var score:Int;
	var accuracy:Float;
	var rank:String;
	var maxCombo:Int;
	var newBest:Bool;
	var misses:Int;
	var sicks:Int;
	var goods:Int;
	var bads:Int;
	var shits:Int;
}

class ResultsSubState extends MusicBeatSubstate
{
	var data:ResultsData;
	var canContinue:Bool = false;

	public function new(data:ResultsData)
	{
		super();
		this.data = data;
	}

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);
		FlxTween.tween(bg, {alpha: 0.85}, 0.4);

		var accuracy:Float = data.accuracy;
		if (Math.isNaN(accuracy)) accuracy = 0;
		accuracy = CoolUtil.floorDecimal(accuracy * 100, 2);

		addText(data.song.toUpperCase(), 70, 42, FlxColor.WHITE);

		var rankText:FlxText = addText(data.rank, 150, 88, rankColor(data.rank));
		FlxTween.tween(rankText.scale, {x: 1.05, y: 1.05}, 1.2, {type: FlxTween.PINGPONG});

		var judgeLabels:Array<String> = ClientPrefs.data.sekaiScoring
			? [
				Language.getPhrase('judge_perfect', 'PERFECT'),
				Language.getPhrase('judge_great', 'GREAT'),
				Language.getPhrase('judge_good', 'GOOD'),
				Language.getPhrase('judge_bad', 'BAD')
			]
			: [
				Language.getPhrase('judge_sick', 'Sick'),
				Language.getPhrase('judge_good_default', 'Good'),
				Language.getPhrase('judge_bad_default', 'Bad'),
				Language.getPhrase('judge_shit', 'Shit')
			];
		var judgeCounts:Array<Int> = [data.sicks, data.goods, data.bads, data.shits];
		var judgeLine:String = '';
		for (i in 0...judgeLabels.length)
			judgeLine += (i > 0 ? '  |  ' : '') + '${judgeLabels[i]}: ${judgeCounts[i]}';

		var lines:Array<String> = [
			Language.getPhrase('results_score', 'Score: {1}', [data.score]),
			Language.getPhrase('results_accuracy', 'Accuracy: {1}%', [accuracy]),
			Language.getPhrase('results_max_combo', 'Max Combo: {1}', [data.maxCombo]),
			Language.getPhrase('results_misses', 'Misses: {1}', [data.misses]),
			judgeLine
		];
		var y:Float = 300;
		for (line in lines)
		{
			addText(line, y, 28, FlxColor.WHITE);
			y += 44;
		}

		var lifetime:String = Language.getPhrase('results_lifetime', 'Lifetime: {1} notes hit over {2} songs', [PlayStats.notesHit, PlayStats.songsPlayed]);
		if (PlayStats.songsPlayed > 0)
			lifetime += Language.getPhrase('results_lifetime_extra', ' | {1} played | {2}% average', [PlayStats.playTimeString(), CoolUtil.floorDecimal(PlayStats.lifetimeAccuracy(), 1)]);
		addText(lifetime, 560, 18, 0xFF888888);

		addText(Language.getPhrase('results_continue', 'Press ACCEPT to continue'), FlxG.height - 80, 24, 0xFFAAAAAA);

		if (ClientPrefs.data.sekaiScoring)
		{
			var clearType:String = null;
			if (data.misses == 0 && data.bads == 0 && data.shits == 0)
				clearType = (data.goods == 0)
					? Language.getPhrase('results_all_perfect', 'ALL PERFECT')
					: Language.getPhrase('results_full_combo', 'FULL COMBO');
			if (clearType != null) addText(clearType, 232, 20, 0xFF9BE7FF);
		}

		if (data.newBest)
		{
			var best:FlxText = addText(Language.getPhrase('results_new_best', 'NEW BEST SCORE!'), 258, 28, 0xFFFFD700);
			FlxTween.tween(best, {alpha: 0.35}, 0.6, {type: FlxTween.PINGPONG});
		}

		new FlxTimer().start(0.6, function(_) canContinue = true);
		// Don't sit on the results forever: move on by itself if the player walks away.
		new FlxTimer().start(15, function(_) continueToNextState());
	}

	function addText(text:String, y:Float, size:Int, color:FlxColor):FlxText
	{
		var txt:FlxText = new FlxText(0, y, FlxG.width, text, size);
		txt.setFormat(Paths.font('vcr.ttf'), size, color, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.borderSize = 2;
		txt.scrollFactor.set();
		add(txt);
		return txt;
	}

	inline function rankColor(rank:String):FlxColor
	{
		return switch (rank.toUpperCase())
		{
			case 'S', 'S+', 'PERFECT': 0xFFFFD700; // gold
			case 'A': 0xFF6BFF6B;
			case 'B': 0xFF6BB3FF;
			case 'C': 0xFFFFC16B;
			default: 0xFFFF6B6B;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canContinue && controls.ACCEPT)
			continueToNextState();
	}

	function continueToNextState():Void
	{
		if (!canContinue) return;
		canContinue = false;
		if (PlayState.instance != null)
		{
			PlayState.instance.closeSubState();
			PlayState.instance.continueAfterSong();
		}
	}
}
