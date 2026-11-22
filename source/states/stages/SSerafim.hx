package states.stages;

import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import objects.Character;
import objects.FlxAtlasSprite;
import objects.StrumNote;

/**
 * The SSERAFIM diner from Spaghetti, ported from V-Slice's `sserafim` stage.
 *
 * Props keep V-Slice's stage coordinates (the song runs at zoom 0.5, the same zoom
 * the original stage uses). The stage also runs the song's custom events:
 * the band members showing up and taking turns, the door kick, the truck/back
 * lights, the darkening and the "see you" end cards.
 *
 * Not ported yet: the V-Slice shader (darkening is a black overlay and the truck's
 * brightening a white wash instead), the perspective floor skew and the lipsync
 * mouths.
 */
class SSerafim extends BaseStage
{
	var bg:BGSprite;
	var floorSprite:BGSprite;
	var backTables:BGSprite;
	var backStools:BGSprite;
	var truck:BGSprite;
	var truckDoor:BGSprite;
	var frontStool:BGSprite;
	var counterStretch:BGSprite;
	var burgerCutscene:BGSprite;

	var truckLight1:BGSprite;
	var truckLight2:BGSprite;
	var backLightColor:BGSprite;
	var backLightWhite:BGSprite;

	var yunjin:Character;
	var chaewon:Character;
	var eunchae:Character;

	var dust:Array<FlxBackdrop> = [];

	var cover:FlxSprite;
	var darkOverlay:FlxSprite;
	var seeYou1:BGSprite;
	var seeYou2:BGSprite;

	var strumsHidden:Bool = false;
	var beatCount:Int = 0;
	var yunjinDancing:Bool = false;
	var ended:Bool = false;

	// Intro cutscene (V-Slice's "LSFM intro"): BF and GF at the counter before the
	// forklift comes through the window. If the atlases can't load it falls back
	// to a plain fade so the song still starts.
	var cutsceneMain:FlxAtlasSprite;
	var cutsceneBf:FlxAtlasSprite;
	var cutsceneGf:FlxAtlasSprite;
	var cutsceneWhite:FlxSprite;
	var skipText:FlxText;
	var cutsceneTimers:Array<FlxTimer> = [];
	var cutsceneSound:FlxSound;
	var cutscenePlaying:Bool = false;
	var cutsceneSkipped:Bool = false;
	var cutsceneFinished:Bool = false;
	var cutsceneSkipAllowed:Bool = true;
	var canSkipCutscene:Bool = false;
	var cutsceneFailed:Bool = false;
	var normalZoom:Float = 0.5;

	var lightsEnabled:Bool = false;
	var lightsColors:Array<Int> = [];
	var lightsDurations:Array<Float> = [];
	var lightsIntensities:Array<Float> = [];
	var lightsTween:Array<FlxTween> = [];

	override function create()
	{
		bg = new BGSprite('sserafim/bg', -1853, -815, 0.75, 0.75);
		add(bg);

		floorSprite = new BGSprite('sserafim/floor', 790, 625, 0.85, 0.85);
		add(floorSprite);

		counterStretch = new BGSprite('sserafim/cutscene/counter-stretch', -1858, 377, 0.93, 0.93);
		// It is a 1px strip, the cutscene stretches it into the long diner counter.
		counterStretch.scale.set(400, 1);
		counterStretch.updateHitbox();
		counterStretch.visible = false;
		add(counterStretch);

		burgerCutscene = new BGSprite('sserafim/cutscene/burger-cutscene', -97, 237, 0.93, 0.93);
		burgerCutscene.visible = false;
		add(burgerCutscene);

		backTables = new BGSprite('sserafim/back-tables', -1857, 267, 0.93, 0.93);
		add(backTables);

		backStools = new BGSprite('sserafim/back-stools', -1357, 426, 0.94, 0.94);
		add(backStools);

		backLightColor = new BGSprite('sserafim/lights/back-light-color', -1241, -949, 0.93, 0.93);
		backLightColor.blend = ADD;
		backLightColor.color = 0xFFCC3300;
		backLightColor.alpha = 0;
		add(backLightColor);

		backLightWhite = new BGSprite('sserafim/lights/back-light-white', -771, -599, 0.93, 0.93);
		backLightWhite.alpha = 0;
		add(backLightWhite);

		truck = new BGSprite('sserafim/truck-stuff', -983, -707, 0.95, 0.95);
		add(truck);

		truckDoor = new BGSprite('sserafim/truck-door', -980, -173, 0.95, 0.95);
		truckDoor.visible = false;
		add(truckDoor);

		truckLight1 = new BGSprite('sserafim/lights/truck-light-1', -962, -607, 0.95, 0.95);
		truckLight1.blend = ADD;
		truckLight1.alpha = 0;
		add(truckLight1);

		truckLight2 = new BGSprite('sserafim/lights/truck-light-2', -781, -464, 0.95, 0.95);
		truckLight2.alpha = 0;
		add(truckLight2);

		frontStool = new BGSprite('sserafim/front-stool', -280, 818, 1.0, 1.0);
		add(frontStool);

		dust.push(makeDust('sserafim/dust/dust-mid', -650, -200, 1.1, 1.5, 0.8, 350, 0xFF98847D));
		dust.push(makeDust('sserafim/dust/dust-back', -650, -250, 1.15, 1.5, 0.9, -300, 0xFF8B6C63));
		dust.push(makeDust('sserafim/dust/dust-mid', -650, -400, 1.2, 2.0, 0.8, -200, 0xFF6E645C));
		dust.push(makeDust('sserafim/dust/dust-back', -650, -1300, 1.25, 3.5, 0.9, -150, 0xFF886A60));

		// V-Slice cancels the countdown to play the intro. setStartCallback runs in its
		// place, and the intro starts the countdown once it is done.
		if (!seenCutscene) setStartCallback(startIntroCutscene);
	}

	function makeDust(image:String, x:Float, y:Float, scroll:Float, scale:Float, alpha:Float, velX:Float, color:Int):FlxBackdrop
	{
		var spr = new FlxBackdrop(Paths.image(image), X);
		spr.setPosition(x, y);
		spr.scrollFactor.set(scroll, scroll);
		spr.scale.set(scale, scale);
		spr.alpha = alpha;
		spr.velocity.x = velX;
		spr.color = color;
		return spr;
	}

	override function createPost()
	{
		// The diner is dark at the start of the song, the forklift's lights and the
		// end cards sit above the characters.
		darkOverlay = new FlxSprite();
		darkOverlay.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
		darkOverlay.setPosition(-FlxG.width, -FlxG.height);
		darkOverlay.scrollFactor.set(0, 0);
		darkOverlay.alpha = 0;
		darkOverlay.cameras = [camGame];
		add(darkOverlay);

		// V-Slice brightens the stage and characters with its adjust-colour shader as
		// the truck closes in; a white wash stands in for it here.
		cutsceneWhite = new FlxSprite();
		cutsceneWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
		cutsceneWhite.setPosition(-FlxG.width, -FlxG.height);
		cutsceneWhite.scrollFactor.set(0, 0);
		cutsceneWhite.alpha = 0;
		cutsceneWhite.cameras = [camGame];
		add(cutsceneWhite);

		cover = new FlxSprite();
		cover.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
		cover.setPosition(-FlxG.width, -FlxG.height);
		cover.scrollFactor.set(0, 0);
		cover.alpha = 0;
		cover.cameras = [camGame];
		add(cover);

		seeYou1 = new BGSprite('sserafim/end/end-1', 0, 0, 0, 0);
		seeYou1.scale.set(0.67, 0.67);
		seeYou1.updateHitbox();
		seeYou1.screenCenter();
		seeYou1.visible = false;
		add(seeYou1);

		seeYou2 = new BGSprite('sserafim/end/end-2', 0, 0, 0, 0);
		seeYou2.scale.set(0.67, 0.67);
		seeYou2.updateHitbox();
		seeYou2.setPosition(FlxG.width - 40 - seeYou2.width, FlxG.height - 40 - seeYou2.height);
		seeYou2.visible = false;
		add(seeYou2);

		// The band, as stage characters. yunjin starts behind the closed truck door.
		yunjin = new Character(-621, 154, 'sserafim-yunjin');
		yunjin.scrollFactor.set(0.95, 0.95);
		add(yunjin);

		chaewon = new Character(687, 98, 'sserafim-chaewon');
		chaewon.scrollFactor.set(0.95, 0.95);
		add(chaewon);

		eunchae = new Character(770, 675, 'sserafim-eunchae');
		eunchae.scrollFactor.set(0.97, 0.97);
		add(eunchae);

		yunjin.playAnim('doorclosed', true);
		chaewon.visible = false;
		eunchae.visible = false;

		// Everyone is hidden until their show/sing events, and the opponent icon and
		// girlfriend only turn up when yunjin kicks the door open.
		boyfriend.visible = false;
		dad.visible = false;
		gf.visible = false;
		if (game.iconP2 != null) game.iconP2.visible = false;

		for (spr in dust)
			add(spr);

		normalZoom = defaultCamZoom;
		createCutsceneSprites();

		skipText = new FlxText(936, 618, 0, 'Skip [ ACCEPT ]', 40);
		skipText.setFormat(Paths.font('vcr.ttf'), 40, 0xFFFFFFFF, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
		skipText.scrollFactor.set();
		skipText.borderSize = 2;
		skipText.alpha = 0;
		skipText.visible = false;
		skipText.cameras = [camOther];
		add(skipText);
	}

	function hideOpponentStrums()
	{
		if (strumsHidden) return;
		strumsHidden = true;
		// Spaghetti's chart only has player notes.
		var oppStrums:Array<StrumNote> = cast game.opponentStrums.members;
		for (strum in oppStrums)
			if (strum != null) strum.visible = false;
	}

	override function countdownTick(count:Countdown, num:Int)
	{
		hideOpponentStrums();
	}

	override function startSong()
	{
		hideOpponentStrums();
	}

	override function beatHit()
	{
		beatCount++;
		if (yunjinDancing && yunjin != null && yunjin.visible) yunjin.dance();
		if (chaewon != null && chaewon.visible) chaewon.dance();
		if (eunchae != null && eunchae.visible) eunchae.dance();

		if (lightsEnabled && lightsColors.length > 0)
		{
			flashBackLight(lightsIntensities[beatCount % lightsIntensities.length],
				lightsDurations[beatCount % lightsDurations.length],
				lightsColors[beatCount % lightsColors.length]);
		}
	}

	function parseBools(str:String):Array<Bool>
	{
		var out:Array<Bool> = [];
		if (str == null) return out;
		for (part in str.split(','))
			out.push(part.trim().toLowerCase() == 'true');
		return out;
	}

	function parseFloats(str:String):Array<Float>
	{
		var out:Array<Float> = [];
		if (str == null) return out;
		for (part in str.split(','))
		{
			var f = Std.parseFloat(part.trim());
			if (!Math.isNaN(f)) out.push(f);
		}
		return out;
	}

	function parseColor(str:String):Int
	{
		str = str.trim();
		if (str.startsWith('0x') || str.startsWith('0X')) str = str.substr(2);
		if (str.startsWith('#')) str = str.substr(1);
		return Std.parseInt('0x' + str);
	}

	function kick(isFinal:Bool)
	{
		if (isFinal)
		{
			yunjin.playAnim('kick2', true);
			yunjinDancing = true;
			FlxG.sound.play(Paths.sound('sserafim/door-kick-2'));
			gf.visible = true;
			if (game.iconP2 != null) game.iconP2.visible = true;
			// The door is part of her animation at first, so only show it afterwards.
			new FlxTimer().start(23 / 24, function(tmr:FlxTimer) truckDoor.visible = true);
		}
		else
		{
			yunjin.playAnim('kick1', true);
			FlxG.sound.play(Paths.sound('sserafim/door-kick-1'));
		}
	}

	function flashBackLight(amount:Float, duration:Float, color:Int)
	{
		for (twn in lightsTween)
			if (twn != null) twn.cancel();
		lightsTween = [];

		backLightColor.color = color;
		backLightColor.alpha = amount * 0.8;
		backLightWhite.alpha = amount * 0.7;

		lightsTween.push(FlxTween.tween(backLightColor, {alpha: 0}, duration, {ease: FlxEase.cubeInOut}));
		lightsTween.push(FlxTween.tween(backLightWhite, {alpha: 0}, duration, {ease: FlxEase.cubeInOut}));
	}

	function truckLights(amount:Float, duration:Float)
	{
		FlxTween.cancelTweensOf(truckLight1);
		FlxTween.cancelTweensOf(truckLight2);
		truckLight1.alpha = amount;
		truckLight2.alpha = amount;
		FlxTween.tween(truckLight1, {alpha: 0}, duration, {ease: FlxEase.cubeInOut});
		FlxTween.tween(truckLight2, {alpha: 0}, duration, {ease: FlxEase.cubeInOut});
	}

	function clearDust(progress:Float)
	{
		var eased:Float = FlxEase.sineOut(Math.min(1, Math.max(0, progress)));
		var starts:Array<Float> = [-400, -450, -600, -1500];
		var drops:Array<Float> = [100, 200, 150, 100];
		var speeds:Array<Float> = [350, -300, -200, -150];
		for (i in 0...dust.length)
		{
			dust[i].alpha = 1 - eased;
			dust[i].y = starts[i] + drops[i] * eased;
			dust[i].velocity.x = speeds[i] * (1 - eased);
		}
	}

	function endStuff()
	{
		if (ended) return;
		ended = true;

		FlxG.sound.play(Paths.sound('sserafim/cutscene/end-1'));
		cover.alpha = 1;
		if (game.camHUD != null) game.camHUD.visible = false;
		seeYou1.visible = true;

		new FlxTimer().start(4, function(tmr:FlxTimer) {
			seeYou1.visible = false;
			seeYou2.visible = true;
			FlxG.sound.play(Paths.sound('sserafim/cutscene/end-2'));
		});

		new FlxTimer().start(9, function(tmr:FlxTimer) {
			seeYou1.visible = false;
			seeYou2.visible = false;
			game.endSong();
		});
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch (eventName)
		{
			case 'SSerafim Icon':
				var id:String = value2;
				if (id != null && id.length > 0 && game.iconP2 != null)
				{
					game.iconP2.changeIcon(id);
					game.iconP2.visible = true;
				}

			case 'sserafimShow':
				var vis:Array<Bool> = parseBools(value1);
				if (vis.length >= 5)
				{
					yunjin.visible = vis[0];
					dad.visible = vis[1];
					chaewon.visible = vis[2];
					eunchae.visible = vis[3];
					boyfriend.visible = vis[4];
				}

			case 'sserafimSing':
				// V-Slice swaps which member's mouth moves; we don't have the lipsync
				// sprites yet, so the flags are only read here for later use.
				parseBools(value1);

			case 'sserafimKick':
				var isFinal:Bool = value1 != null && value1.trim().toLowerCase() == 'true';
				kick(isFinal);
				if (isFinal)
				{
					var ms:Float = value2 != null ? Std.parseFloat(value2) : 0;
					if (ms > 0) new FlxTimer().start(ms / 1000, function(tmr:FlxTimer) clearDust(1));
				}

			case 'sserafimCover':
				cover.alpha = (value1 != null && value1.trim().toLowerCase() == 'true') ? 1 : 0;

			case 'sserafimDark':
				var amt:Float = flValue1 != null ? flValue1 : (value1 != null ? Std.parseFloat(value1) : 0);
				var dur:Float = value2 != null ? Std.parseFloat(value2) : 0;
				if (Math.isNaN(amt)) amt = 0;
				FlxTween.cancelTweensOf(darkOverlay);
				FlxTween.tween(darkOverlay, {alpha: amt}, dur, {ease: FlxEase.sineInOut});

			case 'sserafimLights':
				var amt:Float = value1 != null ? Std.parseFloat(value1) : 0;
				var dur:Float = value2 != null ? Std.parseFloat(value2) : 0;
				if (Math.isNaN(amt)) amt = 0;
				if (Math.isNaN(dur) || dur <= 0) dur = 0.5;
				truckLights(amt, dur);

			case 'sserafimFlash':
				var dur:Float = value1 != null ? Std.parseFloat(value1) : 0;
				if (Math.isNaN(dur) || dur <= 0) dur = 0.5;
				camGame.flash(FlxColor.WHITE, dur);

			case 'sserafimPulseLights':
				lightsEnabled = (value1 != null && value1.trim().toLowerCase() == 'true');
				if (lightsEnabled && value2 != null)
				{
					var parts:Array<String> = value2.split('|');
					lightsColors = [];
					if (parts.length > 0 && parts[0].trim().length > 0)
						for (c in parts[0].split(','))
							lightsColors.push(parseColor(c));
					lightsDurations = parts.length > 1 ? parseFloats(parts[1]) : [];
					lightsIntensities = parts.length > 2 ? parseFloats(parts[2]) : [];
					if (lightsDurations.length < 1) lightsDurations = [0.5];
					if (lightsIntensities.length < 1) lightsIntensities = [0.7];
				}
				else if (!lightsEnabled)
				{
					backLightColor.alpha = 0;
					backLightWhite.alpha = 0;
				}

			case 'sserafimBeautiful':
				if (gf != null)
				{
					gf.idleSuffix = (value1 != null && value1.trim().toLowerCase() == 'true') ? '-beautiful' : '';
					gf.dance();
				}

			case 'sserafimEnd':
				endStuff();

			case 'sserafimGuitarVibration':
				// Haptic-only in V-Slice.
		}
	}

	function createCutsceneSprites()
	{
		try
		{
			cutsceneMain = new FlxAtlasSprite(-395, 10, 'sserafim/cutscene/cutscene-main');
			cutsceneMain.scrollFactor.set(0.94, 0.94);
			cutsceneMain.visible = false;
			add(cutsceneMain);

			cutsceneGf = new FlxAtlasSprite(655, -104, 'sserafim/cutscene/gf-get-up');
			cutsceneGf.scrollFactor.set(0.95, 0.95);
			cutsceneGf.visible = false;
			add(cutsceneGf);

			cutsceneBf = new FlxAtlasSprite(1220, 531, 'sserafim/cutscene/bf-get-up');
			cutsceneBf.scrollFactor.set(0.99, 0.99);
			cutsceneBf.visible = false;
			add(cutsceneBf);
		}
		catch (e:Dynamic)
		{
			cutsceneFailed = true;
			FlxG.log.warn('Spaghetti intro cutscene art could not be loaded, fading instead: ' + e);
		}
	}

	function playCutsceneAnim(spr:FlxAtlasSprite, paused:Bool = false)
	{
		if (spr == null) return;
		spr.anim.play('', true, false, 0);
		if (paused) spr.anim.pause();
	}

	function setCutsceneVisibility(active:Bool)
	{
		if (cutsceneMain != null) cutsceneMain.visible = active;
		if (!active)
		{
			if (cutsceneGf != null) cutsceneGf.visible = false;
			if (cutsceneBf != null) cutsceneBf.visible = false;
		}

		// The band only turns up when the song's events reveal them.
		if (active)
		{
			yunjin.visible = false;
			chaewon.visible = false;
			eunchae.visible = false;
			boyfriend.visible = false;
			dad.visible = false;
			gf.visible = false;
		}

		truck.visible = !active;
		truckDoor.visible = false;
		backTables.visible = !active;
		backStools.visible = !active;
		frontStool.visible = !active;
		for (d in dust) d.visible = !active;

		floorSprite.loadGraphic(Paths.image(active ? 'sserafim/cutscene/floor-cutscene' : 'sserafim/floor'));

		counterStretch.visible = active;
		burgerCutscene.visible = active;
	}

	function cutsceneTimer(delay:Float, callback:Void->Void)
	{
		var tmr:FlxTimer = new FlxTimer().start(delay, function(t:FlxTimer) {
			cutsceneTimers.remove(t);
			callback();
		});
		cutsceneTimers.push(tmr);
	}

	function clearCutsceneTimers()
	{
		for (t in cutsceneTimers)
			if (t != null) t.cancel();
		cutsceneTimers = [];
	}

	function setCutsceneDarken(amount:Float, duration:Float)
	{
		FlxTween.cancelTweensOf(darkOverlay);
		FlxTween.tween(darkOverlay, {alpha: amount}, duration, {ease: FlxEase.sineInOut});
	}

	function startIntroCutscene()
	{
		// The start callback runs just before createPost, so give the stage one frame to
		// finish building before the first shot is set up.
		new FlxTimer().start(0, function(tmr:FlxTimer) beginIntroCutscene());
	}

	function beginIntroCutscene()
	{
		if (cutsceneFailed)
		{
			startCutsceneFallbackFade();
			return;
		}

		cutscenePlaying = true;
		game.inCutscene = true;
		game.canPause = false;
		if (game.camHUD != null) game.camHUD.visible = false;

		setCutsceneVisibility(true);
		playCutsceneAnim(cutsceneMain);

		// The shot opens close, then pulls back over three seconds.
		camGame.zoom = 0.5;
		camFollow.setPosition(660, -200);
		FlxTween.cancelTweensOf(camGame);
		FlxTween.cancelTweensOf(camFollow);
		FlxTween.tween(camGame, {zoom: 0.7}, 3, {ease: FlxEase.circOut});
		FlxTween.tween(camFollow, {x: 660, y: 300}, 3, {ease: FlxEase.circOut});
		camGame.fade(FlxColor.BLACK, 3, true, null, true);

		cutsceneTimer(20 / 24, function()
			cutsceneSound = FlxG.sound.play(Paths.sound('sserafim/cutscene/start-cutscene')));

		// GF taps herself, then taps BF.
		cutsceneTimer(245 / 24, function() setCutsceneDarken(0.2, 0.01));
		cutsceneTimer(251 / 24, function() setCutsceneDarken(0, 0.8));
		cutsceneTimer(406 / 24, function() setCutsceneDarken(0.2, 0.01));
		cutsceneTimer(411 / 24, function() setCutsceneDarken(0, 0.8));

		// The truck closes in, so the frame washes out and skipping stops here.
		cutsceneTimer(499 / 24, function() {
			cutsceneSkipAllowed = false;
			if (skipText != null)
			{
				skipText.visible = false;
				skipText.alpha = 0;
			}
			FlxTween.cancelTweensOf(cutsceneWhite);
			FlxTween.tween(cutsceneWhite, {alpha: 0.45}, 49 / 24, {ease: FlxEase.sineOut});
		});

		cutsceneTimer(548 / 24, function() {
			FlxTween.cancelTweensOf(cutsceneWhite);
			FlxTween.tween(cutsceneWhite, {alpha: 0.6}, 15 / 24, {ease: FlxEase.expoIn});
		});

		// Crash: white flash, then black while the stage is swapped to the wreck.
		cutsceneTimer(563 / 24, function() {
			FlxTween.cancelTweensOf(cutsceneWhite);
			FlxTween.cancelTweensOf(camGame);
			if (cutsceneWhite != null) cutsceneWhite.alpha = 0;
			camGame.flash(FlxColor.WHITE, 30 / 24);
			cover.alpha = 1;
			setCutsceneVisibility(false);
		});

		// Fade in on the wrecked diner while BF and GF sit up.
		cutsceneTimer(650 / 24, function() {
			camGame.zoom = 0.7;
			FlxTween.cancelTweensOf(camGame);
			FlxTween.tween(camGame, {zoom: 0.55}, 3, {ease: FlxEase.circOut});
			camFollow.setPosition(1070, 470);
			FlxTween.tween(cover, {alpha: 0}, 3, {ease: FlxEase.sineOut});
			if (cutsceneGf != null)
			{
				cutsceneGf.visible = true;
				playCutsceneAnim(cutsceneGf, true);
			}
			if (cutsceneBf != null)
			{
				cutsceneBf.visible = true;
				playCutsceneAnim(cutsceneBf, true);
			}
		});

		cutsceneTimer(710 / 24, function() {
			playCutsceneAnim(cutsceneGf);
			playCutsceneAnim(cutsceneBf);
		});

		cutsceneTimer(730 / 24, endIntroCutscene);
	}

	function endIntroCutscene()
	{
		if (cutsceneFinished) return;
		cutsceneFinished = true;
		cutscenePlaying = false;

		if (cutsceneGf != null) cutsceneGf.visible = false;
		if (cutsceneBf != null) cutsceneBf.visible = false;
		if (skipText != null) skipText.visible = false;

		camGame.zoom = normalZoom;
		defaultCamZoom = normalZoom;
		game.inCutscene = false;
		if (game.camHUD != null) game.camHUD.visible = true;
		game.canPause = true;
		startCountdown();
	}

	function startCutsceneFallbackFade()
	{
		game.inCutscene = true;
		game.canPause = false;
		if (game.camHUD != null) game.camHUD.visible = false;
		camGame.fade(FlxColor.BLACK, 0.01, false, null, true);
		camGame.fade(FlxColor.BLACK, 1.5, true, null, true);
		new FlxTimer().start(1.5, function(tmr:FlxTimer) endIntroCutscene());
	}

	function skipIntroCutscene()
	{
		if (!cutscenePlaying || cutsceneFinished) return;
		cutsceneSkipped = true;
		cutscenePlaying = false;
		cutsceneFinished = true;

		clearCutsceneTimers();
		FlxTween.cancelTweensOf(cutsceneWhite);
		FlxTween.cancelTweensOf(camGame);
		FlxTween.cancelTweensOf(camFollow);
		if (cutsceneWhite != null) cutsceneWhite.alpha = 0;
		if (skipText != null)
		{
			skipText.visible = false;
			skipText.alpha = 0;
		}
		if (cutsceneSound != null) cutsceneSound.fadeOut(0.4, 0);

		camGame.fade(FlxColor.BLACK, 0.4, false, function()
		{
			camGame.fade(FlxColor.BLACK, 0.4, true);
		}, true);

		// A short beat of black, then the wrecked diner where the intro left off.
		new FlxTimer().start(0.6, function(tmr:FlxTimer)
		{
			setCutsceneVisibility(false);
			if (cutsceneGf != null)
			{
				cutsceneGf.visible = true;
				playCutsceneAnim(cutsceneGf, true);
				cutsceneGf.anim.curFrame = 23;
			}
			if (cutsceneBf != null)
			{
				cutsceneBf.visible = true;
				playCutsceneAnim(cutsceneBf, true);
				cutsceneBf.anim.curFrame = 23;
			}
			camGame.zoom = normalZoom;
			camFollow.setPosition(1070, 470);
			cover.alpha = 0;

			game.inCutscene = false;
			if (game.camHUD != null) game.camHUD.visible = true;
			game.canPause = true;
			startCountdown();
		});
	}

	override function update(elapsed:Float)
	{
		if (game == null || game.controls == null) return;
		if (cutscenePlaying && !cutsceneSkipped)
		{
			if (game.controls.ACCEPT && cutsceneSkipAllowed)
			{
				if (!canSkipCutscene)
				{
					canSkipCutscene = true;
					if (skipText != null)
					{
						skipText.visible = true;
						FlxTween.tween(skipText, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
					}
				}
				else skipIntroCutscene();
			}
		}
	}

	override function destroy()
	{
		clearCutsceneTimers();
		if (cutsceneSound != null) cutsceneSound.stop();
		for (twn in lightsTween)
			if (twn != null) twn.cancel();
		lightsTween = [];
	}
}
