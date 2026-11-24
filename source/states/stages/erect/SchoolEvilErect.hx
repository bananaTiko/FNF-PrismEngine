package states.stages.erect;


import shaders.WiggleEffectRuntime;
import states.stages.cutscenes.SchoolDoof;
import flixel.addons.effects.FlxTrail;
import backend.VsliceOptions;
import substates.GameOverSubstate;

class SchoolEvilErect extends BaseStage
{
	var backSpikes:BGSprite;
	var school:BGSprite;
	var spike:BGSprite;
	var street:BGSprite;
	var wiggleBack:WiggleEffectRuntime = null;
	var wiggleSchool:WiggleEffectRuntime = null;
	var wiggleStreet:WiggleEffectRuntime = null;
	var wiggleSpike:WiggleEffectRuntime = null;

	override function create()
	{
		var _song = PlayState.SONG;
		if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1)
			GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1)
			GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1)
			GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1)
			GameOverSubstate.characterName = 'bf-pixel-dead';

		backSpikes = new BGSprite('weeb/erect/evil/weebBackSpikes', -662, -60,0.5,0.5);
		backSpikes.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		backSpikes.updateHitbox();
		backSpikes.antialiasing = false;
		add(backSpikes);

		school = new BGSprite('weeb/erect/evil/weebSchool', -816, -38, 0.75, 0.75);
		school.makePixel();
		add(school);

		spike = new BGSprite('weeb/erect/evil/backSpike', 1416, 464,0.85,0.85);
		spike.makePixel();
		add(spike);

		var blackBg:FlxSprite = new FlxSprite(-500, 660);
		blackBg.makeGraphic(2400, 2000, 0xFF000000);
		add(blackBg);

		street = new BGSprite('weeb/erect/evil/weebStreet', -662, 6);
		street.makePixel();
		add(street);

		setDefaultGF('gf-pixel');

		FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.8);
		if (isStoryMode && !seenCutscene)
		{
			var cutscene = new SchoolDoof(songName);
			setStartCallback(cutscene.doSpiritIntro);
		}
	}

	override function createPost()
	{
		var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		if (VsliceOptions.SHADERS)
		{
			wiggleBack = new WiggleEffectRuntime(2 * 0.8, 4 * 0.4, 0.011, WiggleEffectType.DREAMY);
			wiggleSchool = new WiggleEffectRuntime(2, 4, 0.017, WiggleEffectType.DREAMY);
			wiggleSpike = new WiggleEffectRuntime(2, 4, 0.01, WiggleEffectType.DREAMY);
			wiggleStreet = new WiggleEffectRuntime(2, 4, 0.007, WiggleEffectType.DREAMY);
			backSpikes.shader = wiggleBack;
			school.shader = wiggleSchool;
			spike.shader = wiggleSpike;
			street.shader = wiggleStreet;
		}
		// No rim light here: the lighting pass left the characters as black cut-outs.
		addBehindDad(trail);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		wiggleBack?.update(elapsed);
		wiggleSchool?.update(elapsed);
		wiggleSpike?.update(elapsed);
		wiggleStreet?.update(elapsed);
	}

	// Ghouls event
	var bgGhouls:BGSprite;

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch (eventName)
		{
			case "Trigger BG Ghouls":
				if (!VsliceOptions.LOW_QUALITY)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
		}
	}

	override function eventPushed(event:objects.Note.EventNote)
	{
		// used for preloading assets used on events
		switch (event.event)
		{
			case "Trigger BG Ghouls":
				if (!VsliceOptions.LOW_QUALITY)
				{
					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if (name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					addBehindGF(bgGhouls);
				}
		}
	}
}
