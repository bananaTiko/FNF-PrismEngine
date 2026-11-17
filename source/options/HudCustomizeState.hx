package options;

/**
 * Lets the player nudge the HUD text elements around and stores the offsets in ClientPrefs.
 * Inspired by Edak Engine's Gameplay Customize state, which does the same thing with the
 * hit rating sprite.
 */
class HudCustomizeState extends MusicBeatState
{
	static inline var ELEMENT_COUNT:Int = 4;

	var names:Array<String> = ['Score Text', 'Judgement Counters', 'NPS Counter', 'Hit Timing Readout'];
	var texts:Array<FlxText> = [];
	var baseX:Array<Float> = [];
	var baseY:Array<Float> = [];
	var offsetsX:Array<Float> = [];
	var offsetsY:Array<Float> = [];

	var selected:Int = 0;
	var highlight:FlxSprite;
	var infoTxt:FlxText;
	var helpTxt:FlxText;

	var dragging:Bool = false;
	var dragOffX:Float = 0;
	var dragOffY:Float = 0;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Customizing HUD', null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF2F2F2F;
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		offsetsX = [ClientPrefs.data.hudScoreX, ClientPrefs.data.hudJudgementX, ClientPrefs.data.hudNpsX, ClientPrefs.data.hudTimingX];
		offsetsY = [ClientPrefs.data.hudScoreY, ClientPrefs.data.hudJudgementY, ClientPrefs.data.hudNpsY, ClientPrefs.data.hudTimingY];

		var scoreY:Float = FlxG.height - 100;
		addElement(0, 0, scoreY, FlxG.width, 20, CENTER, 'Score: 123456 | Misses: 2 | Rating: SICK! (98.5%) - FC');
		addElement(1, 0, scoreY + 24, FlxG.width, 18, CENTER, 'SICK: 240 | GOOD: 12 | BAD: 3 | SHIT: 1 | MISS: 2');
		addElement(2, 10, 10, 160, 18, LEFT, 'NPS: 8.4');
		addElement(3, FlxG.width - 130, 10, 120, 18, RIGHT, '-12ms');

		highlight = new FlxSprite().makeGraphic(1, 1, FlxColor.YELLOW);
		highlight.alpha = 0.3;
		highlight.scrollFactor.set();
		add(highlight);

		infoTxt = new FlxText(0, FlxG.height - 70, FlxG.width, '', 20);
		infoTxt.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoTxt.borderSize = 1.25;
		infoTxt.scrollFactor.set();
		add(infoTxt);

		helpTxt = new FlxText(0, FlxG.height - 42, FlxG.width, 'MOUSE: drag\nARROWS: select   RESET: reset   BACK: save & exit', 16);
		helpTxt.setFormat(Paths.font('vcr.ttf'), 16, 0xFFAAAAAA, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helpTxt.borderSize = 1;
		helpTxt.scrollFactor.set();
		add(helpTxt);

		FlxG.mouse.visible = true;

		updateSelectionVisuals();

		super.create();
	}

	function addElement(index:Int, baseXPos:Float, baseYPos:Float, width:Float, size:Int, align:FlxTextAlign, text:String):Void
	{
		baseX[index] = baseXPos;
		baseY[index] = baseYPos;

		var txt:FlxText = new FlxText(baseXPos + offsetsX[index], baseYPos + offsetsY[index], width, text, size);
		txt.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, align, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.borderSize = 1.25;
		txt.scrollFactor.set();
		texts[index] = txt;
		add(txt);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			saveOffsets();
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new OptionsState());
			return;
		}

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.RESET)
		{
			offsetsX[selected] = 0;
			offsetsY[selected] = 0;
			applyOffsetToText(selected);
			updateSelectionVisuals();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		var mouse:FlxPoint = FlxG.mouse.getScreenPosition();
		if (!dragging && FlxG.mouse.justPressed)
		{
			for (i in 0...texts.length)
			{
				var txt:FlxText = texts[i];
				if (mouse.x >= txt.x && mouse.x <= txt.x + txt.width && mouse.y >= txt.y && mouse.y <= txt.y + txt.height)
				{
					selected = i;
					dragging = true;
					dragOffX = mouse.x - txt.x;
					dragOffY = mouse.y - txt.y;
					updateSelectionVisuals();
					FlxG.sound.play(Paths.sound('scrollMenu'));
					break;
				}
			}
		}

		if (dragging)
		{
			if (FlxG.mouse.pressed)
			{
				var txt:FlxText = texts[selected];
				txt.x = mouse.x - dragOffX;
				txt.y = mouse.y - dragOffY;
				offsetsX[selected] = txt.x - baseX[selected];
				offsetsY[selected] = txt.y - baseY[selected];
				updateSelectionVisuals();
				updateInfoText();
			}
			else
			{
				dragging = false;
				saveOffsets();
			}
		}
	}

	function changeSelection(change:Int):Void
	{
		selected = FlxMath.wrap(selected + change, 0, ELEMENT_COUNT - 1);
		updateSelectionVisuals();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function applyOffsetToText(index:Int):Void
	{
		texts[index].x = baseX[index] + offsetsX[index];
		texts[index].y = baseY[index] + offsetsY[index];
	}

	function updateSelectionVisuals():Void
	{
		var txt:FlxText = texts[selected];
		highlight.setPosition(txt.x - 4, txt.y - 3);
		highlight.scale.set(Math.max(txt.width + 8, 8), Math.max(txt.height + 6, 6));
		updateInfoText();
	}

	function updateInfoText():Void
	{
		infoTxt.text = '> ${names[selected]} <   (${Math.round(offsetsX[selected])}, ${Math.round(offsetsY[selected])})';
	}

	function saveOffsets():Void
	{
		ClientPrefs.data.hudScoreX = offsetsX[0];
		ClientPrefs.data.hudScoreY = offsetsY[0];
		ClientPrefs.data.hudJudgementX = offsetsX[1];
		ClientPrefs.data.hudJudgementY = offsetsY[1];
		ClientPrefs.data.hudNpsX = offsetsX[2];
		ClientPrefs.data.hudNpsY = offsetsY[2];
		ClientPrefs.data.hudTimingX = offsetsX[3];
		ClientPrefs.data.hudTimingY = offsetsY[3];
		ClientPrefs.saveSettings();
	}

	override function destroy()
	{
		FlxG.mouse.visible = false;
		super.destroy();
	}
}
