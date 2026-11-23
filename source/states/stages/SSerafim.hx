package states.stages;

import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import objects.Character;
import objects.FlxAtlasSprite;
import objects.Note;
import objects.StrumNote;
import shaders.SserafimShader;
import states.stages.objects.PerspectiveSprite;
import states.stages.objects.SserafimLipSync;

/**
 * The SSERAFIM diner from Spaghetti, ported from V-Slice's `sserafim` stage.
 *
 * Props keep V-Slice's stage coordinates (the song runs at zoom 0.5, the same zoom
 * the original stage uses). The stage also runs the song's custom events:
 * the band members showing up and taking turns, the door kick, the truck/back
 * lights, the darkening and the "see you" end cards.
 */
class SSerafim extends BaseStage
{
	var bg:BGSprite;
	var perspectiveFloor:PerspectiveSprite;
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

	// In event order: yunjin, kazuha, chaewon, eunchae, Sakura (the player) and GF.
	// V-Slice swaps their CharacterType on every `sserafimSing` so the current lead
	// sings the player's notes; the same flags drive the lip-sync mouths.
	var band:Array<Character> = [];
	var singFlags:Array<Bool> = [false, false, false, false, false, false];
	var mouths:Array<SserafimLipSync> = [null, null, null, null, null, null];

	/**
	 * V-Slice positions characters by their feet. Its characterOrigin is
	 * (bounds.width / 2, bounds.height) while the atlas is drawn shifted by
	 * -bounds.topLeft, so the point that lands on the stage position is the
	 * bottom-centre of the whole main-timeline bounds. These are those points
	 * (bounds.x + width / 2, bounds.y + height) measured from the V-Slice atlas
	 * matrices and spritemap rects. Baking them means a character can be placed
	 * while still hidden, without drawing it or touching its alpha.
	 */
	static final FEET_ORIGINS:Map<String, Array<Float>> = [
		'sserafim-yunjin' => [449.0976602189243, 844.650798407942],
		'sserafim-chaewon' => [532.7721099853516, 816.5062469482422],
		'sserafim-eunchae' => [493.96503714823626, 682.1432730056346],
		'sserafim-gf' => [1186.05, 860.5953308105469],
		'sserafim-kazuha' => [479.36452065818014, 920.1373352050782],
		'sserafim-sakura' => [471.2061737060547, 748.1230090137572]
	];

	static final LIP_ATLAS:Map<String, String> = [
		'sserafim-yunjin' => 'sserafim/sserafim-lipsync-yunjin',
		'sserafim-kazuha' => 'sserafim/sserafim-lipsync',
		'sserafim-chaewon' => 'sserafim/sserafim-lipsync',
		'sserafim-eunchae' => 'sserafim/sserafim-lipsync',
		'sserafim-sakura' => 'sserafim/sserafim-lipsync',
		'sserafim-gf' => 'sserafim/sserafim-lipsync'
	];

	// Mouth anchors inside each character atlas (x, y, rotation), taken from the
	// "mouth" symbol each pose nests, and the per-animation offsets V-Slice's
	// character scripts apply to the mouth sprite.
	static final LIP_ANCHORS:Map<String, Map<String, Array<Float>>> = [
		'sserafim-yunjin' => ['idle' => [545.8, 373.3, 1.56], 'left' => [498.1, 362.4, -6.34], 'right' => [581.7, 365.4, -9.88], 'up' => [545.1, 344.8, -12.39], 'down' => [534.1, 385.7, -0.62]],
		'sserafim-chaewon' => ['idle' => [530.2, 331.1, 172.93], 'left' => [510.8, 332.8, 173.22], 'right' => [551.9, 310.1, 166.67], 'up' => [537.8, 300.3, 163.85], 'down' => [530.4, 333.8, 178.33]],
		'sserafim-eunchae' => ['idle' => [661.2, 293.2, -174.04], 'left' => [637.2, 286.5, -172.65], 'right' => [683.1, 280.3, -178.28], 'up' => [662.3, 290.2, -160.55], 'down' => [641.9, 285.6, 175.6]],
		'sserafim-kazuha' => ['idle' => [514.0, 241.1, -3.66], 'left' => [480.6, 227.4, 1.82], 'right' => [541.6, 233.5, 6.36], 'up' => [509.2, 197.6, 9.99], 'down' => [516.9, 258.7, -7.09]],
		'sserafim-sakura' => ['idle' => [431.3, 198.8, 3.77], 'left' => [418.2, 193.1, 9.56], 'right' => [465.4, 180.9, 7.78], 'up' => [449.9, 156.2, 15.73], 'down' => [425.4, 211.8, 2.2], 'singUP-joint' => [490.3, 157.0, 18.48], 'singRIGHT-joint' => [463.6, 181.6, 3.77], 'singDOWN-joint' => [403.4, 225.9, 1.63], 'singLEFT-joint' => [419.2, 195.2, 9.47]]
	];

	static final LIP_OFFSETS:Map<String, Map<String, Array<Float>>> = [
		'sserafim-yunjin' => ['idle' => [8, 6, 23], 'up' => [6, 8, 22], 'right' => [6, 8, 23], 'down' => [8, 6, 23], 'left' => [6, 8, 23]],
		'sserafim-chaewon' => ['idle' => [41, 3, -166], 'up' => [38, 0, -168], 'right' => [39, 1, -165], 'down' => [41, 3, -167], 'left' => [40, 2, -165]],
		'sserafim-eunchae' => ['idle' => [43, 6, -168], 'up' => [45, 10, -166], 'right' => [42, 5, -166], 'down' => [41, 3, -168], 'left' => [43, 6, -169]],
		'sserafim-kazuha' => ['idle' => [5, 4, -13], 'up' => [7, 2, -14], 'right' => [7, 2, -13], 'down' => [4, 6, -12], 'left' => [5, 4, -14]],
		'sserafim-sakura' => ['idle' => [7, 2, -14], 'up' => [8, 1, -15], 'right' => [7, 2, -15], 'down' => [6, 3, -15], 'left' => [7, 2, -14], 'singUP-joint' => [10, -1, -14],
			'singRIGHT-joint' => [6, 3, -15], 'singDOWN-joint' => [5, 5, -15], 'singLEFT-joint' => [7, 2, -16]]
	];

	var cover:FlxSprite;
	var seeYou1:BGSprite;
	var seeYou2:BGSprite;

	var strumsHidden:Bool = false;
	var yunjinDancing:Bool = false;
	var ended:Bool = false;

	// Intro cutscene (V-Slice's "LSFM intro"): BF and GF at the counter before the
	// forklift comes through the window. If the atlases can't load it falls back
	// to a plain fade so the song still starts.
	var cutsceneMain:FlxAtlasSprite;
	var cutsceneBf:FlxAtlasSprite;
	var cutsceneGf:FlxAtlasSprite;
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

	// V-Slice hides the opponent strumline on the stage's first update: Kazuha never
	// charts anything in Spaghetti, so the left arrows should never be on screen.
	var opponentStrumsHidden:Bool = false;

	// A retry recreates the state; V-Slice instead resets the stage in place and
	// resumes from its post-cutscene shot, so the intro must not play again.
	var retryResume:Bool = false;

	// V-Slice tints the diner through this shader: it is what colours the lights behind
	// the truck, and what darkens the stage and brightens it for the truck close-up.
	var stageShader:SserafimShader;
	var characterShader:SserafimShader;

	var lightsEnabled:Bool = false;
	var lightsColors:Array<Int> = [];
	var lightsDurations:Array<Float> = [];
	var lightsIntensities:Array<Float> = [];

	override function create()
	{
		// V-Slice's sserafim stage json sets cameraZoom 0.5. Every prop position below
		// and the character positions are authored for it.
		defaultCamZoom = 0.5;
		camGame.zoom = 0.5;

		stageShader = new SserafimShader();
		characterShader = new SserafimShader(true);

		bg = new BGSprite('sserafim/bg', -1853, -815, 0.75, 0.75);
		add(bg);

		// V-Slice's stage JSON disables its flat floor and replaces it with this skewed
		// sprite, pinned between (760, 1375) and (790, 625) with per-edge scroll.
		perspectiveFloor = new PerspectiveSprite();
		perspectiveFloor.sprite.loadGraphic(Paths.image('sserafim/floor'));
		perspectiveFloor.setPositions(760, 1375, 790, 625);
		perspectiveFloor.setScrollFactors(1.05, 1.05, 0.93, 0.93);
		add(perspectiveFloor);
		perspectiveFloor.updateSkew(camGame);

		counterStretch = new BGSprite('sserafim/cutscene/counter-stretch', -1858, 377, 0.93, 0.93);
		// It is a 1px strip, the cutscene stretches it into the long diner counter.
		counterStretch.scale.set(400, 1);
		counterStretch.updateHitbox();
		counterStretch.visible = false;

		burgerCutscene = new BGSprite('sserafim/cutscene/burger-cutscene', -97, 237, 0.93, 0.93);
		burgerCutscene.visible = false;

		backTables = new BGSprite('sserafim/back-tables', -1857, 267, 0.93, 0.93);

		backStools = new BGSprite('sserafim/back-stools', -1357, 426, 0.94, 0.94);

		// V-Slice's stage zIndexes: backTables and the counter are both 12,
		// burgerCutscene is 13 and backStools is 14.
		add(backTables);
		add(counterStretch);
		add(burgerCutscene);
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

		truckLight2 = new BGSprite('sserafim/lights/truck-light-2', -781, -464, 0.95, 0.95);
		truckLight2.alpha = 0;

		// truckLight1 sits above truckLight2 in the V-Slice stage (23 vs 22).
		add(truckLight2);
		add(truckLight1);

		frontStool = new BGSprite('sserafim/front-stool', -280, 818, 1.0, 1.0);

		dust.push(makeDust('sserafim/dust/dust-mid', -650, -200, 1.1, 1.5, 0.8, 350, 0xFF98847D));
		dust.push(makeDust('sserafim/dust/dust-back', -650, -250, 1.15, 1.5, 0.9, -300, 0xFF8B6C63));
		dust.push(makeDust('sserafim/dust/dust-mid', -650, -400, 1.2, 2.0, 0.8, -200, 0xFF6E645C));
		dust.push(makeDust('sserafim/dust/dust-back', -650, -1300, 1.25, 3.5, 0.9, -150, 0xFF886A60));

		// V-Slice runs every prop through the stage shader except the lights and the
		// solid cover, which need their own blend modes.
		for (spr in [bg, backTables, backStools, truck, truckDoor, frontStool, counterStretch, burgerCutscene])
			spr.shader = stageShader;
		perspectiveFloor.sprite.shader = stageShader;
		for (d in dust) d.shader = stageShader;

		// V-Slice cancels the countdown to play the intro. setStartCallback runs in its
		// place, and the intro starts the countdown once it is done. Like V-Slice, the
		// intro only plays in Story Mode: Freeplay jumps straight into the song.
		retryResume = isStoryMode && PlayState.retrying;
		if (isStoryMode && !seenCutscene && !PlayState.retrying) setStartCallback(startIntroCutscene);
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

	/**
	 * A full-camera colour wash. One stretched pixel does the same job as a three-screen
	 * bitmap without the memory and the texture upload.
	 */
	function makeOverlay(color:Int):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite();
		spr.makeGraphic(1, 1, color);
		spr.origin.set(0, 0);
		spr.scale.set(FlxG.width * 3, FlxG.height * 3);
		spr.setPosition(-FlxG.width, -FlxG.height);
		spr.scrollFactor.set(0, 0);
		spr.alpha = 0;
		spr.cameras = [camGame];
		return spr;
	}

	override function createPost()
	{
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
		eunchae.visible = false; // The band members only appear once their show event brings them in.

		// V-Slice's stage json positions: bf [1530, 970], dad [70, 470], gf [938.5, 392].
		if (boyfriend != null) boyfriend.scrollFactor.set(0.99, 0.99);
		if (dad != null) dad.scrollFactor.set(0.97, 0.97);
		if (gf != null) gf.scrollFactor.set(0.95, 0.95);

		// Everyone is hidden until their show/sing events, and the opponent icon and
		// girlfriend only turn up when yunjin kicks the door open.
		boyfriend.visible = false;
		dad.visible = false;
		gf.visible = false;
		if (game.iconP2 != null) game.iconP2.visible = false;

		band = [yunjin, dad, chaewon, eunchae, boyfriend, gf];
		for (char in band)
		{
			if (char == null) continue;
			char.skipSing = true; // clear until an sserafimSing event says otherwise

			// V-Slice replaces these characters' built-in mouths with the animated
			// lip-sync sprite and hides the static mouth so it doesn't show underneath.
			switch (char.curCharacter)
			{
				case 'sserafim-eunchae': char.hideAtlasSymbol('mouth default');
				case 'sserafim-sakura': char.hideAtlasSymbol('mouth edit');
			}
		}

		placeBand();

		// V-Slice layers: band/mouths 1000, frontStool 1500, dust 2000,
		// solidCover 9999, end cards 10000. Psych draws in insertion order.
		createLipSyncs();

		normalZoom = defaultCamZoom;
		createCutsceneSprites();

		add(frontStool);
		for (spr in dust)
			add(spr);

		cover = makeOverlay(FlxColor.BLACK);
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

		skipText = new FlxText(936, 618, 0, 'Skip [ ACCEPT ]', 40);
		skipText.setFormat(Paths.font('vcr.ttf'), 40, 0xFFFFFFFF, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
		skipText.scrollFactor.set();
		skipText.borderSize = 2;
		skipText.alpha = 0;
		skipText.visible = false;
		skipText.cameras = [camOther];
		add(skipText);

		for (char in [boyfriend, dad, gf, yunjin, chaewon, eunchae])
			if (char != null) char.shader = characterShader;
		for (spr in [cutsceneMain, cutsceneGf, cutsceneBf])
			if (spr != null) spr.shader = characterShader;

		if (retryResume) resumeAfterRetry();
	}

	function createLipSyncs():Void
	{
		var ids:Array<String> = ['sserafim-yunjin', 'sserafim-kazuha', 'sserafim-chaewon', 'sserafim-eunchae', 'sserafim-sakura', 'sserafim-gf'];
		for (i in 0...band.length)
		{
			var char:Character = band[i];
			var id:String = ids[i];
			if (char == null || !LIP_ANCHORS.exists(id)) continue;

			try
			{
				// Chaewon's mouth is drawn at half alpha, like her V-Slice script; kazuha and
				// Sakura share the flipped mouth atlas.
				var lip:SserafimLipSync = new SserafimLipSync(char, LIP_ATLAS.get(id), LIP_ANCHORS.get(id), LIP_OFFSETS.get(id), groupOffsetX(char),
					groupOffsetY(char), id == 'sserafim-chaewon' ? 0.5 : 1.0, id == 'sserafim-kazuha' || id == 'sserafim-sakura');
				lip.shader = characterShader;
				add(lip);
				mouths[i] = lip;
			}
			catch (e:Dynamic)
			{
				FlxG.log.warn('Spaghetti lip-sync atlas for $id could not be loaded: ' + e);
			}
		}
	}

	function applySinging():Void
	{
		// A member only animates while the chart makes them the lead.
		if (boyfriend != null) boyfriend.skipSing = !singFlags[4];
		if (dad != null) dad.skipSing = !singFlags[1];
		for (i in 0...mouths.length)
			if (mouths[i] != null) mouths[i].singing = singFlags[i];
	}

	function groupOffsetX(char:Character):Float
	{
		if (char == boyfriend && game.boyfriendGroup != null) return game.boyfriendGroup.x;
		if (char == dad && game.dadGroup != null) return game.dadGroup.x;
		if (char == gf && game.gfGroup != null) return game.gfGroup.x;
		return 0;
	}

	function groupOffsetY(char:Character):Float
	{
		if (char == boyfriend && game.boyfriendGroup != null) return game.boyfriendGroup.y;
		if (char == dad && game.dadGroup != null) return game.dadGroup.y;
		if (char == gf && game.gfGroup != null) return game.gfGroup.y;
		return 0;
	}

	/**
	 * Plays the note pose on every member the chart currently marks as singing, plus
	 * Sakura's kind-specific poses, which V-Slice always plays.
	 */
	function playMembers(note:Note, miss:Bool):Void
	{
		if (note == null || note.isSustainNote || note.noAnimation) return;

		var dir:Int = Std.int(Math.abs(note.noteData)) % 4;
		var base:String = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'][dir] + (miss ? 'miss' : '');
		for (i in 0...band.length)
		{
			var char:Character = band[i];
			if (char == null) continue;

			var kindAnim:String = (char.curCharacter == 'sserafim-sakura') ? sakuraKindAnim(note.noteType, base, miss) : null;
			// Sakura's kind poses play even when the sserafimSing flags do not make
			// her the current lead; everyone else only sings when flagged.
			if (kindAnim == null && !singFlags[i]) continue;

			var anim:String = (kindAnim != null) ? kindAnim : base;
			if (!char.hasAnimation(anim)) continue;
			if (!miss && char.specialAnim && !char.isAnimationFinished()) continue;

			char.playAnim(anim, true);
			char.holdTimer = 0;
		}
	}

	/**
	 * V-Slice's sserafim-sakura script branches on the chart's Sakura note kinds.
	 * Hits keep the kind's own suffix; on a miss the joint pose stays `joint` while
	 * both bf kinds use the `bf2` miss style, since there are no bf1 miss poses.
	 */
	function sakuraKindAnim(noteType:String, base:String, miss:Bool):String
	{
		if (noteType == null) return null;

		var suffix:String;
		switch (noteType)
		{
			case 'sakura-joint': suffix = 'joint';
			case 'sakura-bf1': suffix = miss ? 'bf2' : 'bf1';
			case 'sakura-bf2': suffix = 'bf2';
			default: return null;
		}
		return base + '-' + suffix;
	}

	override function goodNoteHit(note:Note)
	{
		playMembers(note, false);
	}

	override function noteMiss(note:Note)
	{
		playMembers(note, true);
	}

	function placeBand():Void
	{
		var feet:Array<Array<Float>> = [[-621, 154], [70, 470], [687, 98], [770, 675], [1530, 970], [938.5, 392]];
		for (i in 0...band.length)
			if (band[i] != null) placeCharacter(band[i], feet[i][0], feet[i][1]);
	}

	function placeCharacter(char:Character, feetX:Float, feetY:Float):Void
	{
		var origin:Array<Float> = FEET_ORIGINS.get(char.curCharacter);
		if (origin == null)
		{
			FlxG.log.warn('SSerafim: no baked feet origin for ${char.curCharacter}');
			return;
		}

		// BF, dad and GF live inside PlayState's sprite groups, so their local position
		// has to discount the group offset.
		var groupX:Float = 0;
		var groupY:Float = 0;
		if (char == boyfriend && game.boyfriendGroup != null)
		{
			groupX = game.boyfriendGroup.x;
			groupY = game.boyfriendGroup.y;
		}
		else if (char == dad && game.dadGroup != null)
		{
			groupX = game.dadGroup.x;
			groupY = game.dadGroup.y;
		}
		else if (char == gf && game.gfGroup != null)
		{
			groupX = game.gfGroup.x;
			groupY = game.gfGroup.y;
		}

		char.setPosition(feetX - groupX - origin[0], feetY - groupY - origin[1]);
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

	/** Whether the character is free to bop, i.e. is not holding a sing pose. */
	function canDance(char:Character):Bool
	{
		var anim:String = char.getAnimationName();
		return anim == null || !anim.startsWith('sing');
	}

	override function beatHit()
	{
		if (yunjinDancing && yunjin != null && yunjin.visible && canDance(yunjin)) yunjin.dance();
		if (chaewon != null && chaewon.visible && canDance(chaewon)) chaewon.dance();
		if (eunchae != null && eunchae.visible && canDance(eunchae)) eunchae.dance();

		if (lightsEnabled && lightsColors.length > 0)
		{
			// V-Slice steps through the colours on the song's own beat count.
			var beat:Int = game.curBeat;
			flashBackLight(lightsIntensities[beat % lightsIntensities.length],
				lightsDurations[beat % lightsDurations.length],
				lightsColors[beat % lightsColors.length]);
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
		FlxTween.cancelTweensOf(backLightColor);
		FlxTween.cancelTweensOf(backLightWhite);

		backLightColor.color = color;

		backLightColor.alpha = amount * 0.8;
		backLightWhite.alpha = amount * 0.7;

		characterShader.pulseLightColor = color;
		stageShader.pulseLightColor = color;

		characterShader.pulseLightStrength = backLightColor.alpha;
		stageShader.pulseLightStrength = backLightColor.alpha;

		FlxTween.tween(backLightColor, {alpha: 0}, duration, {
			ease: FlxEase.cubeInOut,
			onUpdate: function(tween:FlxTween)
			{
				characterShader.pulseLightStrength = backLightColor.alpha;
				stageShader.pulseLightStrength = backLightColor.alpha;
			},
			onComplete: function(tween:FlxTween)
			{
				characterShader.pulseLightStrength = 0;
				stageShader.pulseLightStrength = 0;
			}
		});
		FlxTween.tween(backLightWhite, {alpha: 0}, duration, {ease: FlxEase.cubeInOut});
	}

	function truckLights(amount:Float, duration:Float)
	{
		FlxTween.cancelTweensOf(truckLight1);
		FlxTween.cancelTweensOf(truckLight2);

		truckLight1.alpha = amount;
		truckLight2.alpha = amount;

		characterShader.truckLightStrength = amount;
		stageShader.truckLightStrength = amount;

		FlxTween.tween(truckLight1, {alpha: 0}, duration, {
			ease: FlxEase.cubeInOut,
			onUpdate: function(tween:FlxTween)
			{
				characterShader.truckLightStrength = truckLight1.alpha;
				stageShader.truckLightStrength = truckLight1.alpha;
			},
			onComplete: function(tween:FlxTween)
			{
				characterShader.truckLightStrength = 0;
				stageShader.truckLightStrength = 0;
			}
		});
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
				var flags:Array<Bool> = parseBools(value1);
				if (flags.length >= 5)
				{
					while (flags.length < 6) flags.push(false);
					singFlags = flags;
					applySinging();
				}

			case 'sserafimKick':
				var isFinal:Bool = value1 != null && value1.trim().toLowerCase() == 'true';
				kick(isFinal);
				if (isFinal)
				{
					var ms:Float = value2 != null ? Std.parseFloat(value2) : 0;
					if (ms > 0) new FlxTimer().start(ms / 1000, function(tmr:FlxTimer) startClear());
				}

			case 'sserafimCover':
				cover.alpha = (value1 != null && value1.trim().toLowerCase() == 'true') ? 1 : 0;

			case 'sserafimDark':
				var amt:Float = flValue1 != null ? flValue1 : (value1 != null ? Std.parseFloat(value1) : 0);
				var dur:Float = value2 != null ? Std.parseFloat(value2) : 0;
				if (Math.isNaN(amt)) amt = 0;
				setDarkenAmt(amt, dur);

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
			// V-Slice dims GF in the wrecked diner shot.
			cutsceneGf.alpha = 0.5;
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

	/**
	 * Plays one of the cutscene atlases the way V-Slice does: an empty name plays the
	 * atlas' own symbol, otherwise the frame label (`static`, `getup`) is used.
	 */
	function playCutsceneAnim(spr:FlxAtlasSprite, ?label:String, paused:Bool = false)
	{
		if (spr == null) return;
		if (label == null) spr.anim.play('', true, false, 0);
		else spr.playAnimation(label, true, false, false, 0);
		if (paused) spr.anim.pause();
	}

	function setCutsceneSpritesActive(active:Bool)
	{
		// Hidden atlases stop updating: the intro's three animations are heavy and they
		// have no business running through the rest of the song.
		for (spr in [cutsceneMain, cutsceneGf, cutsceneBf])
		{
			if (spr == null) continue;
			spr.active = active;
			if (!active) spr.anim.pause();
		}
	}

	function setCutsceneVisibility(active:Bool)
	{
		setCutsceneSpritesActive(active);

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

		perspectiveFloor.sprite.loadGraphic(Paths.image(active ? 'sserafim/cutscene/floor-cutscene' : 'sserafim/floor'));
		perspectiveFloor.updateSkew(camGame);

		counterStretch.visible = active;
		burgerCutscene.visible = active;

		if (active)
		{
			// BF and GF only sit up in the wrecked diner, so their atlases stay idle
			// until the crash.
			if (cutsceneGf != null) cutsceneGf.active = false;
			if (cutsceneBf != null) cutsceneBf.active = false;
		}
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

	function setDarkenAmt(amount:Float, duration:Float):Void
	{
		FlxTween.cancelTweensOf(characterShader);
		FlxTween.cancelTweensOf(stageShader);

		FlxTween.tween(characterShader, {darkenAmount: amount}, duration, {ease: FlxEase.sineInOut});
		FlxTween.tween(stageShader, {darkenAmount: amount}, duration, {ease: FlxEase.sineInOut});
	}

	/** V-Slice's "Adjust Color" tweens: the diner brightens as the truck closes in. */
	function setAdjustColor(brightness:Float, hue:Float, contrast:Float, duration:Float, ease:Float->Float):Void
	{
		FlxTween.cancelTweensOf(stageShader);
		FlxTween.cancelTweensOf(characterShader);

		FlxTween.tween(stageShader, {baseBrightness: brightness, baseHue: hue, baseContrast: contrast, baseSaturation: 0}, duration, {ease: ease});
		FlxTween.tween(characterShader, {baseBrightness: brightness, baseHue: hue, baseContrast: contrast, baseSaturation: 0}, duration, {ease: ease});
	}

	function resetClear():Void
	{
		yunjin.playAnim('doorclosed', true);
		yunjinDancing = false;

		truckDoor.visible = false;

		var things:Array<Dynamic> = [stageShader, characterShader, dust[0], dust[0].velocity, dust[1], dust[1].velocity, dust[2], dust[2].velocity,
			dust[3], dust[3].velocity];
		for (thing in things)
			FlxTween.cancelTweensOf(thing);

		stageShader.setAdjustColor(-24, 6, -26, -74);
		characterShader.setAdjustColor(-24, 6, -26, -74);

		clearDust(0);
	}

	function startClear():Void
	{
		FlxTween.tween(stageShader, {baseBrightness: 0, baseHue: 0, baseContrast: 0, baseSaturation: 0}, 6.0 * 4, {ease: FlxEase.sineOut});
		FlxTween.tween(characterShader, {baseBrightness: 0, baseHue: 0, baseContrast: 0, baseSaturation: 0}, 6.0 * 4, {ease: FlxEase.sineOut});

		for (i in 0...dust.length)
		{
			var duration:Float = ([5.0, 4.0, 6.0, 4.0][i]) * 4;
			FlxTween.tween(dust[i], {alpha: 0, y: dust[i].y + [100, 200, 150, 100][i]}, duration, {ease: FlxEase.sineOut});
			FlxTween.tween(dust[i].velocity, {x: 0}, duration, {ease: FlxEase.sineOut});
		}
	}

	/**
	 * V-Slice's onSongRetry + playCutsceneFromRestart. A retry rebuilds PlayState
	 * here, so this puts the fresh stage straight into the frame-23 diner shot
	 * instead of replaying the intro.
	 */
	function resumeAfterRetry():Void
	{
		cutscenePlaying = false;
		cutsceneSkipped = true;
		cutsceneFinished = true;
		if (skipText != null)
		{
			skipText.visible = false;
			skipText.alpha = 0;
		}

		setCutsceneVisibility(false);
		resetClear();
		cover.alpha = 0;

		// V-Slice's baseVisible/baseSinging plus the hidden opponent icon.
		yunjin.visible = true;
		chaewon.visible = false;
		eunchae.visible = false;
		boyfriend.visible = false;
		dad.visible = false;
		gf.visible = false;
		singFlags = [false, false, false, false, false, false];
		applySinging();

		lightsEnabled = false;
		backLightColor.alpha = 0;
		backLightWhite.alpha = 0;
		truckLight1.alpha = 0;
		truckLight2.alpha = 0;
		characterShader.darkenAmount = 0;
		stageShader.darkenAmount = 0;

		if (game.iconP2 != null) game.iconP2.visible = false;
		if (game.camHUD != null) game.camHUD.visible = true;
		game.inCutscene = false;
		game.canPause = true;

		// BF and GF are already on their feet when the song restarts.
		if (cutsceneGf != null)
		{
			cutsceneGf.visible = true;
			cutsceneGf.active = true;
			playCutsceneAnim(cutsceneGf, 'getup', true);
			cutsceneGf.anim.curFrame = 23;
		}
		if (cutsceneBf != null)
		{
			cutsceneBf.visible = true;
			cutsceneBf.active = true;
			playCutsceneAnim(cutsceneBf, 'getup', true);
			cutsceneBf.anim.curFrame = 23;
		}

		FlxTween.cancelTweensOf(camGame);
		FlxTween.cancelTweensOf(camFollow);
		camGame.zoom = normalZoom;
		FlxTween.tween(camGame, {zoom: 0.55}, 1, {ease: FlxEase.circOut});
		FlxTween.tween(camFollow, {x: 1070, y: 470}, 1, {ease: FlxEase.circOut});
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
		cutsceneTimer(245 / 24, function() setDarkenAmt(0.2, 0.01));
		cutsceneTimer(251 / 24, function() setDarkenAmt(0, 0.8));
		cutsceneTimer(406 / 24, function() setDarkenAmt(0.2, 0.01));
		cutsceneTimer(411 / 24, function() setDarkenAmt(0, 0.8));

		// The truck closes in, so the frame washes out and skipping stops here.
		cutsceneTimer(499 / 24, function() {
			cutsceneSkipAllowed = false;
			cutsceneSkipped = true;
			canSkipCutscene = false;
			FlxTween.tween(skipText, {alpha: 0}, 0.5, {
				ease: FlxEase.quadIn,
				onComplete: function(tween:FlxTween) skipText.visible = false
			});

			setAdjustColor(55, 0, -30, 49 / 24, FlxEase.sineOut);
		});

		// Truck gets really close.
		cutsceneTimer(548 / 24, function() {
			setAdjustColor(66, 10, -17, 15 / 24, FlxEase.expoIn);
		});

		// Car crash + flash.
		cutsceneTimer(563 / 24, function() {
			FlxTween.cancelTweensOf(stageShader);
			FlxTween.cancelTweensOf(characterShader);

			stageShader.setAdjustColor(0, 0, 0, 0);
			characterShader.setAdjustColor(0, 0, 0, 0);
			FlxTween.cancelTweensOf(camGame);
			camGame.fade(FlxColor.WHITE, 30 / 24, true, null, true);
			cover.alpha = 1;

			setCutsceneVisibility(false);
		});

		// Fade out from black and add dust.
		cutsceneTimer(650 / 24, function() {
			camGame.zoom = 0.7;
			FlxTween.cancelTweensOf(camGame);
			FlxTween.tween(camGame, {zoom: 0.55}, 3, {ease: FlxEase.circOut});
			camFollow.setPosition(1070, 470);
			resetClear();
			FlxTween.tween(cover, {alpha: 0}, 3, {ease: FlxEase.sineOut});
			if (cutsceneGf != null)
			{
				cutsceneGf.visible = true;
				cutsceneGf.active = true;
				playCutsceneAnim(cutsceneGf, 'static', true);
			}
			if (cutsceneBf != null)
			{
				cutsceneBf.visible = true;
				cutsceneBf.active = true;
				playCutsceneAnim(cutsceneBf, 'static', true);
			}
		});

		cutsceneTimer(710 / 24, function() {
			playCutsceneAnim(cutsceneGf, 'getup');
			playCutsceneAnim(cutsceneBf, 'getup');
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
		setCutsceneSpritesActive(false);
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
		FlxTween.cancelTweensOf(camGame);
		FlxTween.cancelTweensOf(camFollow);
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
			resetClear();
			if (cutsceneGf != null)
			{
				cutsceneGf.visible = true;
				cutsceneGf.active = true;
				playCutsceneAnim(cutsceneGf, 'getup', true);
				cutsceneGf.anim.curFrame = 23;
			}
			if (cutsceneBf != null)
			{
				cutsceneBf.visible = true;
				cutsceneBf.active = true;
				playCutsceneAnim(cutsceneBf, 'getup', true);
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

		if (perspectiveFloor != null && camGame != null) perspectiveFloor.updateSkew(camGame);

		if (!opponentStrumsHidden && game.opponentStrums != null)
		{
			opponentStrumsHidden = true;
			game.opponentStrums.visible = false;
		}

		var covered:Bool = cover != null && cover.alpha > 0.01;
		for (mouth in mouths)
			if (mouth != null) mouth.hiddenByCover = covered;
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
		FlxTween.cancelTweensOf(stageShader);
		FlxTween.cancelTweensOf(characterShader);
		FlxTween.cancelTweensOf(backLightColor);
		FlxTween.cancelTweensOf(backLightWhite);
		FlxTween.cancelTweensOf(truckLight1);
		FlxTween.cancelTweensOf(truckLight2);
	}
}
