package substates;

import backend.CoolUtil;
import backend.Paths;
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

		var lines:Array<String> = [
			'Score: ${data.score}',
			'Accuracy: $accuracy%',
			'Max Combo: ${data.maxCombo}',
			'Misses: ${data.misses}',
			'Sick: ${data.sicks}  |  Good: ${data.goods}  |  Bad: ${data.bads}  |  Shit: ${data.shits}'
		];
		var y:Float = 300;
		for (line in lines)
		{
			addText(line, y, 28, FlxColor.WHITE);
			y += 44;
		}

		addText('Press ACCEPT to continue', FlxG.height - 80, 24, 0xFFAAAAAA);

		if (data.newBest)
		{
			var best:FlxText = addText('NEW BEST SCORE!', 258, 28, 0xFFFFD700);
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
