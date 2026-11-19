package substates;

import backend.Language;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import states.MainMenuState;
import states.TitleState;

class OutdatedSubState extends MusicBeatSubstate
{
	public static var updateVersion(get, never):String;
	static function get_updateVersion():String
		return CoolUtil.latestVersion;

	var leftState:Bool = false;

	var bg:FlxSprite;
	var warnText:FlxText;

	override function create()
	{
		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			Language.getPhrase('outdated_warning',
				'Sup bro, looks like you\'re running an outdated version of\nPrism Engine ({1})\n\n-----------------------------------------------\n\nPress ENTER to update to the latest version {2}\n\nPress ESCAPE to proceed anyway.\nYou can disable this warning by unchecking the\n"Check for Updates" setting in the Options Menu\n\n-----------------------------------------------\n\nThank you for using the Engine!',
				[MainMenuState.prismEngineVersion, updateVersion]),
			32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.scrollFactor.set();
		warnText.screenCenter(Y);
		warnText.alpha = 0.0;
		add(warnText);

		FlxTween.tween(bg, { alpha: 0.8 }, 0.6, { ease: FlxEase.sineIn });
		FlxTween.tween(warnText, { alpha: 1.0 }, 0.6, { ease: FlxEase.sineIn });
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				CoolUtil.browserLoad("https://github.com/bananaTiko/FNF-PrismEngine/releases");
			}
			else if(controls.BACK) {
				leftState = true;
			}
			if(leftState)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(bg, { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					ease: FlxEase.sineOut,
					onComplete: function (twn:FlxTween) {
						FlxG.state.persistentUpdate = true;
						close();
					}
				});
			}
		}
		super.update(elapsed);
	}
}
