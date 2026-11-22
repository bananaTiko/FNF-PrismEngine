package states;

import backend.WeekData;
import backend.StreamedSound;
import backend.Highscore;
import backend.PlayStats;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import haxe.Json;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;

	//Mic'd Up-style spinning disc, with a Plus-style song card in front of it
	var disc:FlxSprite;
	var cardSlideTargets:Array<FlxSprite> = [];
	var cardSlideBaseX:Array<Float> = [];
	var lastCardSongKey:String = '';
	var cardBG:FlxSprite;
	var cardTitle:FlxText;
	var cardInfo:FlxText;
	var cardFav:FlxText;

	//Full song list, plus the filtered/sorted view that's actually drawn
	var allSongs:Array<SongMetadata> = [];
	var searchBox:PsychUIInputText;
	var searchBG:FlxSprite;
	var sortText:FlxText;
	var favText:FlxText;
	var noResultsText:FlxText;
	static var sortModes:Array<String> = ['Name', 'Week', 'Favourites', 'Recent'];

	//Freeplay is split into two mixes; each one shows its own songs plus an erect section.
	static var mixNames:Array<String> = ['BF MIXES', 'PICO MIXES'];
	static var mixCategories:Array<Array<String>> = [['BF Mixes', 'BF Erect'], ['Pico Mixes', 'Pico Erect']];
	static var curMix:Int = 0;
	var mixTabs:Array<FlxText> = [];

	//The list is split into these groups with a heading above each one, so it stops being
	//one long scroll.
	static var freeplayCategories:Array<String> = ['BF Mixes', 'BF Erect', 'Pico Mixes', 'Pico Erect'];
	static var songOrder:Array<String> = [];
	static var songCategories:Map<String, String> = [];

	//The erect mixes aren't their own rows: a song's erect chart is picked with the
	//difficulty (Hard -> Erect -> Nightmare), the same way V-Slice does it.
	static var erectSongs:Map<String, String> = [];
	static var erectBaseSongs:Map<String, String> = [];

	//Every freeplay song, in the order it shows up in its mix and the section it belongs to.
	static function buildSongTable():Void
	{
		if (songOrder.length > 0) return;

		addSongTable('BF Mixes', [
			'tutorial', 'bopeebo', 'fresh', 'dad battle', 'spookeez', 'south', 'monster',
			'pico', 'philly nice', 'blammed', 'satin panties', 'high', 'milf',
			'cocoa', 'eggnog', 'winter horrorland', 'senpai', 'roses', 'thorns',
			'ugh', 'guns', 'stress', 'spaghetti', 'darnell (bf mix)', 'lit up (bf mix)'
		]);

		addSongTable('BF Erect', [
			'bopeebo erect', 'fresh erect', 'dad battle erect', 'spookeez erect', 'south erect',
			'pico erect', 'philly nice erect', 'blammed erect', 'satin panties erect', 'high erect',
			'cocoa erect', 'eggnog erect', 'senpai erect', 'roses erect', 'thorns erect', 'ugh erect'
		]);

		addSongTable('Pico Mixes', [
			'bopeebo (pico mix)', 'fresh (pico mix)', 'dad battle (pico mix)', 'spookeez (pico mix)',
			'south (pico mix)', 'pico (pico mix)', 'philly nice (pico mix)', 'blammed (pico mix)',
			'cocoa (pico mix)', 'eggnog (pico mix)', 'senpai (pico mix)', 'roses (pico mix)',
			'ugh (pico mix)', 'guns (pico mix)', 'stress (pico mix)',
			'darnell', 'lit up', '2hot', 'blazin'
		]);

		addSongTable('Pico Erect', ['darnell erect']);
	}

	static function addSongTable(category:String, names:Array<String>):Void
	{
		for (name in names)
		{
			songOrder.push(name);
			songCategories.set(name, category);

			if (name.endsWith(' erect'))
			{
				var base:String = name.substr(0, name.length - ' erect'.length);
				erectSongs.set(base, name);
				erectBaseSongs.set(name, base);
			}
		}
	}

	//The erect chart a song can switch to, if it has one.
	static function getErectName(songName:String):String
	{
		return (songName == null) ? null : erectSongs.get(songName.toLowerCase());
	}

	static function isErectDifficulty(diff:Int):Bool
	{
		var diffName:String = Difficulty.getString(diff, false);
		return diffName == 'Erect' || diffName == 'Nightmare';
	}

	//The chart a song actually plays at the given difficulty.
	static function chartSongName(song:SongMetadata, diff:Int):String
	{
		var erectName:String = getErectName(song.songName);
		if (erectName != null && isErectDifficulty(diff)) return erectName;
		return song.songName;
	}

	function currentChartSongName():String
	{
		if (songs.length < 1 || curSelected < 0 || curSelected >= songs.length) return '';
		return chartSongName(songs[curSelected], curDifficulty);
	}
	static inline var CATEGORY_GAP:Float = 95;
	var grpCategories:FlxTypedGroup<Alphabet> = null;
	var categoryNames:Array<String> = [];
	var categoryFirst:Array<Int> = [];
	var songGroups:Array<Int> = [];

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		buildSongTable();
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState(Language.getPhrase('freeplay_no_weeks',
				'NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.'),
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		createSongCard();

		applyFilterAndSort();
		buildSongObjects();
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);


		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if (songs.length > 0)
		{
			curSelected = FlxMath.wrap(curSelected, 0, songs.length - 1);
			bg.color = songs[curSelected].color;
			intendedColor = bg.color;
		}
		else curSelected = 0;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		
		player = new MusicPlayer(this);
		add(player);

		searchBG = new FlxSprite(10, 8).makeGraphic(320, 38, FlxColor.BLACK);
		searchBG.alpha = 0.6;
		add(searchBG);

		searchBox = new PsychUIInputText(14, 12, 312, '', 24);
		searchBox.maxLength = 40;
		searchBox.onChange = function(old:String, newText:String) onSearchChange(newText);
		add(searchBox);

		sortText = new FlxText(12, 50, 0, '', 16);
		sortText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sortText.scrollFactor.set();
		add(sortText);

		favText = new FlxText(12, 70, 0, '', 16);
		favText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		favText.scrollFactor.set();
		add(favText);

		//The two mixes sit at the top of the screen; the song list below follows the pick
		for (i in 0...mixNames.length)
		{
			var tab:FlxText = new FlxText(0, 12, 0, mixNames[i], 28);
			tab.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tab.borderSize = 2;
			tab.scrollFactor.set();
			add(tab);
			mixTabs.push(tab);
		}
		updateMixTabs();

		noResultsText = new FlxText(0, 300, FlxG.width, Language.getPhrase('freeplay_no_results', 'No songs found.'), 32);
		noResultsText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noResultsText.scrollFactor.set();
		noResultsText.visible = false;
		add(noResultsText);

		changeSelection();
		updateHint();
		updateTexts();
		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		var song:SongMetadata = new SongMetadata(songName, weekNum, songCharacter, color);
		song.category = getSongCategory(songName, weekNum, songCharacter);
		allSongs.push(song);
	}

	//Which group a song belongs to. The big table above wins; anything missing from it falls
	//back to its opponent and whether it's an erect mix.
	static function getSongCategory(songName:String, weekNum:Int, songCharacter:String):String
	{
		var lowerName:String = (songName == null) ? '' : songName.toLowerCase();
		if (songCategories.exists(lowerName)) return songCategories.get(lowerName);

		var week:String = (weekNum >= 0 && weekNum < WeekData.weeksList.length) ? WeekData.weeksList[weekNum].toLowerCase() : '';
		var lowerChar:String = (songCharacter == null) ? '' : songCharacter.toLowerCase();

		var erect:Bool = week.indexOf('erect') > -1 || lowerName.indexOf('erect') > -1;
		var pico:Bool = lowerChar.indexOf('pico') > -1 || week.indexOf('pico') > -1;

		if (pico) return erect ? 'Pico Erect' : 'Pico Mixes';
		return erect ? 'BF Erect' : 'BF Mixes';
	}

	static function categoryRank(category:String):Int
	{
		var index:Int = freeplayCategories.indexOf(category);
		return index < 0 ? freeplayCategories.length : index;
	}

	static function songOrderIndex(songName:String):Int
	{
		var index:Int = (songName == null) ? -1 : songOrder.indexOf(songName.toLowerCase());
		return index < 0 ? songOrder.length : index;
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;
	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		var typing:Bool = (searchBox != null && PsychUIInputText.focusOn == searchBox);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) //No decimals, add an empty space
			ratingSplit.push('');
		
		while(ratingSplit[1].length < 2) //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!player.playingMusic)
		{
			scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
			positionHighscore();
			
			if(songs.length > 1 && !typing)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0 && !typing)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (!typing && controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (!typing && controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
		}

		if (controls.BACK && !typing)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !player.playingMusic && !typing)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE && !typing && songs.length > 0)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var previewSong:String = currentChartSongName().toLowerCase();
				var poop:String = Highscore.formatSong(previewSong, curDifficulty);
				Song.loadFromJson(poop, previewSong);
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var playerPostfix:String = (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player';
						var streamedVocals:FlxSound = StreamedSound.vocalTrack(PlayState.SONG.song, playerPostfix, true);
						
						if(streamedVocals != null)
						{
							vocals = streamedVocals;
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch(e:Dynamic)
					{
						vocals = FlxDestroyUtil.destroy(vocals);
					}
					
					opponentVocals = new FlxSound();
					try
					{
						//trace('please work...');
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var oppPostfix:String = (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent';
						var streamedOpp:FlxSound = StreamedSound.vocalTrack(PlayState.SONG.song, oppPostfix);
						
						if(streamedOpp != null)
						{
							opponentVocals = streamedOpp;
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
							//trace('yaaay!!');
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic)
					{
						//trace('FUUUCK');
						opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
				}

				var streamedInst:StreamedSound = StreamedSound.create(Paths.instPath(PlayState.SONG.song));
				if(streamedInst != null)
				{
					streamedInst.playAsMusic(0.8, true);
					streamedInst.pause();
				}
				else
				{
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
					if (FlxG.sound.music != null) FlxG.sound.music.pause();
				}
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(!player.playing);
			}
		}
		else if (controls.ACCEPT && !player.playingMusic && !typing && songs.length > 0)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(currentChartSongName());
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

			try
			{
				Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch(e:haxe.Exception)
			{
				trace('ERROR! ${e.message}');

				var errorStr:String = e.message;
				if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = Language.getPhrase('chart_error_missing', 'Missing file: {1}', [errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1)]); //Missing chart
				else errorStr += '\n\n' + e.stack;

				missingText.text = Language.getPhrase('chart_error', 'ERROR WHILE LOADING CHART:\n{1}', [errorStr]);
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			@:privateAccess
			if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			LoadingState.loadAndSwitchState(new PlayState());
			#if !SHOW_LOADING_SCREEN if (FlxG.sound.music != null) FlxG.sound.music.stop(); #end
			stopMusicPlay = true;

			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else if(controls.RESET && !player.playingMusic && !typing && songs.length > 0)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(currentChartSongName(), curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (!typing && !player.playingMusic)
		{
			if (FlxG.keys.justPressed.TAB)
				cycleSort();
			if (FlxG.keys.justPressed.F && songs.length > 0)
				toggleFavourite();
			if (FlxG.keys.justPressed.R && songs.length > 1)
				randomSong();
			if (FlxG.keys.justPressed.Q)
				switchMix(-1);
			if (FlxG.keys.justPressed.E)
				switchMix(1);
			if (FlxG.mouse.justPressed)
			{
				for (i in 0...mixTabs.length)
				{
					if (!FlxG.mouse.overlaps(mixTabs[i])) continue;
					setMix(i);
					break;
				}
			}
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}
	
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic || songs.length < 1)
			return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
		#if !switch
		intendedScore = Highscore.getScore(currentChartSongName(), curDifficulty);
		intendedRating = Highscore.getRating(currentChartSongName(), curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
		else
			diffText.text = displayDiff.toUpperCase();

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
		updateSongCard();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic || songs.length < 1)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.targetY == curSelected)
			{
				item.alpha = 1;
				icon.alpha = 1;
			}
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		//Erect and Nightmare only exist for songs that shipped an erect chart.
		if (getErectName(songs[curSelected].songName) != null)
		{
			for (extra in ['Erect', 'Nightmare'])
				if (!Difficulty.list.contains(extra)) Difficulty.list.push(extra);
		}
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
		updateSongCard();
		updateHint();
	}

	inline private function _updateSongLastDifficulty()
	{
		if (curSelected >= 0 && curSelected < songs.length)
			songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(MathUtils.clamp(lerpSelected - _drawDistance, 0, songs.length));
		var max:Int = Math.round(MathUtils.clamp(lerpSelected + _drawDistance, 0, songs.length));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}

		updateCategoryRows();
	}

	function buildCategoryRows():Void
	{
		if (grpCategories != null)
		{
			for (member in grpCategories.members)
				if (member != null) member.destroy();
			grpCategories.clear();
		}
		else
		{
			grpCategories = new FlxTypedGroup<Alphabet>();
			add(grpCategories);
		}

		categoryNames = [];
		categoryFirst = [];
		songGroups = [];

		var groupIndex:Int = -1;
		var lastCategory:String = null;
		for (i in 0...songs.length)
		{
			var category:String = songs[i].category;
			if (category != lastCategory)
			{
				groupIndex++;
				lastCategory = category;
				categoryNames.push(category);
				categoryFirst.push(i);
			}
			songGroups.push(groupIndex);
		}

		for (i in 0...categoryNames.length)
		{
			var header:Alphabet = new Alphabet(90, 320, categoryNames[i].toUpperCase(), true);
			header.setScale(0.62);
			header.alpha = 0.75;
			header.startPosition.y = (320 + CATEGORY_GAP * i) - CATEGORY_GAP;
			grpCategories.add(header);
		}
	}

	function updateCategoryRows():Void
	{
		if (grpCategories == null) return;

		for (i in 0...grpCategories.members.length)
		{
			var header:Alphabet = grpCategories.members[i];
			if (header == null || i >= categoryFirst.length) continue;

			header.visible = header.active = true;
			header.x = ((categoryFirst[i] - lerpSelected) * header.distancePerItem.x) + header.startPosition.x;
			header.y = ((categoryFirst[i] - lerpSelected) * 1.3 * header.distancePerItem.y) + header.startPosition.y;
		}
	}

	function getFavouriteKey(song:SongMetadata):String
		return song.folder + ':' + song.songName;

	function isFavourite(song:SongMetadata):Bool
		return ClientPrefs.data.favorites.contains(getFavouriteKey(song));

	function applyFilterAndSort():Void
	{
		var query:String = (searchBox != null && searchBox.text != null) ? searchBox.text.trim().toLowerCase() : '';
		var allowed:Array<String> = mixCategories[curMix];
		var filtered:Array<SongMetadata> = [];
		for (song in allSongs)
		{
			if (!allowed.contains(song.category)) continue;
			if (erectBaseSongs.exists(song.songName.toLowerCase())) continue;
			if (query.length > 0 && !song.songName.toLowerCase().contains(query))
				continue;
			filtered.push(song);
		}

		switch(ClientPrefs.data.freeplaySort)
		{
			case 'Name':
				filtered.sort(function(a:SongMetadata, b:SongMetadata):Int
				{
					var name1:String = a.songName.toLowerCase();
					var name2:String = b.songName.toLowerCase();
					if (name1 == name2) return 0;
					return name1 < name2 ? -1 : 1;
				});
			case 'Recent':
				var recentKeys:Array<String> = PlayStats.getRecentKeys();
				var played:Array<SongMetadata> = [];
				var unplayed:Array<SongMetadata> = [];
				for (song in filtered)
				{
					if (recentKeys.contains(Paths.formatToSongPath(song.songName) + '|' + curDifficulty)) played.push(song);
					else unplayed.push(song);
				}
				played.sort(function(a:SongMetadata, b:SongMetadata):Int
				{
					var indexA:Int = recentKeys.indexOf(Paths.formatToSongPath(a.songName) + '|' + curDifficulty);
					var indexB:Int = recentKeys.indexOf(Paths.formatToSongPath(b.songName) + '|' + curDifficulty);
					return indexA - indexB;
				});
				filtered = played.concat(unplayed);
			case 'Favourites':
				var favs:Array<SongMetadata> = [];
				var rest:Array<SongMetadata> = [];
				for (song in filtered)
				{
					if (isFavourite(song)) favs.push(song);
					else rest.push(song);
				}
				filtered = favs.concat(rest);
			default:
				//Group by category first, then keep the original week/song order inside it
				var order:Array<Int> = [for (i in 0...filtered.length) i];
				order.sort(function(a:Int, b:Int):Int
				{
					var rankA:Int = categoryRank(filtered[a].category);
					var rankB:Int = categoryRank(filtered[b].category);
					if (rankA != rankB) return rankA - rankB;

					var posA:Int = songOrderIndex(filtered[a].songName);
					var posB:Int = songOrderIndex(filtered[b].songName);
					if (posA != posB) return posA - posB;

					if (filtered[a].week != filtered[b].week) return filtered[a].week - filtered[b].week;
					return a - b;
				});
				var ordered:Array<SongMetadata> = [];
				for (i in order) ordered.push(filtered[i]);
				filtered = ordered;
		}
		songs = filtered;
	}

	function buildSongObjects():Void
	{
		if (grpSongs != null)
		{
			var oldMembers:Array<Alphabet> = grpSongs.members.copy();
			grpSongs.clear();
			for (member in oldMembers)
				if (member != null) member.destroy();
		}
		else
		{
			grpSongs = new FlxTypedGroup<Alphabet>();
			add(grpSongs);
		}

		for (icon in iconArray)
		{
			if (icon == null) continue;
			remove(icon, true);
			icon.destroy();
		}
		iconArray = [];
		_lastVisibles = [];

		buildCategoryRows();
		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			//Every group after the first starts lower, to leave room for its heading
			if (songGroups[i] > 0) songText.startPosition.y = 320 + CATEGORY_GAP * songGroups[i];
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();
	}

	function refreshList():Void
	{
		var curKey:String = null;
		if (curSelected >= 0 && curSelected < songs.length)
			curKey = getFavouriteKey(songs[curSelected]);

		applyFilterAndSort();
		buildSongObjects();

		curSelected = 0;
		if (curKey != null)
		{
			for (i in 0...songs.length)
			{
				if (getFavouriteKey(songs[i]) == curKey)
				{
					curSelected = i;
					break;
				}
			}
		}
		if (songs.length > 0) curSelected = FlxMath.wrap(curSelected, 0, songs.length - 1);

		lerpSelected = curSelected;
		changeSelection(0, false);
		updateHint();
		updateTexts(0.0);
	}

	function onSearchChange(newText:String):Void
	{
		stopSongPreview();
		refreshList();
	}

	function randomSong():Void
	{
		var pick:Int = curSelected;
		while(pick == curSelected) pick = FlxG.random.int(0, songs.length - 1);

		curSelected = pick;
		changeSelection(0, false);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function cycleSort():Void
	{
		var index:Int = sortModes.indexOf(ClientPrefs.data.freeplaySort) + 1;
		if (index < 1 || index >= sortModes.length) index = 0;
		ClientPrefs.data.freeplaySort = sortModes[index];
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		refreshList();
	}

	function switchMix(dir:Int):Void
		setMix(FlxMath.wrap(curMix + dir, 0, mixNames.length - 1));

	function setMix(index:Int):Void
	{
		if (index == curMix || index < 0 || index >= mixNames.length) return;

		curMix = index;
		stopSongPreview();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		updateMixTabs();
		refreshList();
	}

	function updateMixTabs():Void
	{
		var gap:Float = 40;
		var total:Float = gap * (mixTabs.length - 1);
		for (tab in mixTabs) total += tab.width;

		var x:Float = (FlxG.width - total) / 2;
		for (i in 0...mixTabs.length)
		{
			var tab:FlxText = mixTabs[i];
			tab.x = x;
			tab.alpha = (i == curMix) ? 1 : 0.45;
			x += tab.width + gap;
		}
	}

	function toggleFavourite():Void
	{
		if (songs.length < 1) return;

		var key:String = getFavouriteKey(songs[curSelected]);
		if (ClientPrefs.data.favorites.contains(key))
			ClientPrefs.data.favorites.remove(key);
		else
			ClientPrefs.data.favorites.push(key);

		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		updateSongCard();
		updateHint();

		if (ClientPrefs.data.freeplaySort == 'Favourites')
			refreshList();
	}

	function createSongCard():Void
	{
		var cardW:Int = 300;
		var cardH:Int = 180;
		var cardX:Float = FlxG.width - cardW - 40;
		var cardY:Float = 280;
		var centerX:Float = cardX + cardW / 2;
		var centerY:Float = cardY + cardH / 2;

		//Disc art from FNF: Mic'd Up (Verwex), 'Freeplay_Discs' sparrow sheet
		disc = new FlxSprite();
		disc.frames = Paths.getSparrowAtlas('Freeplay_Discs');
		disc.animation.addByPrefix('disc', 'dad', 24);
		disc.animation.play('disc');
		if(songs.length > 0) disc.color = songs[curSelected].color;
		disc.setGraphicSize(330, 330);
		disc.updateHitbox();
		disc.antialiasing = ClientPrefs.data.antialiasing;
		disc.setPosition(centerX - disc.width / 2, centerY - disc.height / 2);
		add(disc);

		cardBG = new FlxSprite(cardX, cardY).makeGraphic(cardW, cardH, 0xFF000000);
		cardBG.alpha = 0.6;
		add(cardBG);

		cardTitle = new FlxText(cardX + 14, cardY + 10, cardW - 28, '', 24);
		cardTitle.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cardTitle.borderSize = 2;
		cardTitle.wordWrap = true;
		add(cardTitle);

		cardInfo = new FlxText(cardX + 14, cardY + 64, cardW - 28, '', 16);
		cardInfo.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cardInfo.borderSize = 1;
		add(cardInfo);

		cardFav = new FlxText(cardX + 14, cardY + cardH - 30, cardW - 28, '', 16);
		cardFav.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT);
		add(cardFav);

		for (spr in [cardBG, cardTitle, cardInfo, cardFav])
		{
			cardSlideTargets.push(spr);
			cardSlideBaseX.push(spr.x);
		}
	}

	function animateCardChange():Void
	{
		if(disc != null)
		{
			FlxTween.cancelTweensOf(disc);
			disc.angle = 0;
			FlxTween.tween(disc, {angle: -360}, 0.45, {ease: FlxEase.quartOut, onComplete: function(_) {
				if(disc != null) disc.angle = 0;
			}});
		}

		for (i in 0...cardSlideTargets.length)
		{
			var spr:FlxSprite = cardSlideTargets[i];
			if(spr == null) continue;

			FlxTween.cancelTweensOf(spr);
			spr.x = cardSlideBaseX[i] + 20;
			FlxTween.tween(spr, {x: cardSlideBaseX[i]}, 0.28, {ease: FlxEase.quartOut});
		}
	}

	function updateSongCard():Void
	{
		if(cardBG == null) return;

		var hasSong:Bool = songs.length > 0 && curSelected >= 0 && curSelected < songs.length;
		disc.visible = cardBG.visible = cardTitle.visible = cardInfo.visible = cardFav.visible = hasSong;
		if(!hasSong) return;

		var song:SongMetadata = songs[curSelected];
		cardTitle.text = song.songName;

		var weekName:String = (song.week >= 0 && song.week < WeekData.weeksList.length) ? WeekData.weeksList[song.week] : '?';
		var scoreKey:String = Highscore.formatSong(chartSongName(song, curDifficulty), curDifficulty);
		var bestScore:Int = Highscore.songScores.exists(scoreKey) ? Highscore.songScores.get(scoreKey) : 0;
		var bestRating:Float = Highscore.songRating.exists(scoreKey) ? Highscore.songRating.get(scoreKey) : 0;
		var bestText:String = bestScore > 0
			? Language.getPhrase('freeplay_card_best', 'Best: {1} ({2}%)', [bestScore, CoolUtil.floorDecimal(bestRating * 100, 1)])
			: Language.getPhrase('freeplay_card_best_none', 'Best: not played yet');

		cardInfo.text = Language.getPhrase('freeplay_card_week', 'Week: {1}', [weekName])
			+ '\n' + Language.getPhrase('freeplay_card_character', 'Character: {1}', [song.songCharacter])
			+ '\n' + Language.getPhrase('freeplay_card_difficulty', 'Difficulty: {1}', [Difficulty.getString(curDifficulty)])
			+ '\n' + bestText;

		cardFav.text = isFavourite(song)
			? Language.getPhrase('freeplay_fav_yes', 'Favourite: YES (F to remove)')
			: Language.getPhrase('freeplay_fav_no', 'Favourite: NO (F to add)');

		disc.color = song.color;

		var cardKey:String = song.folder + ':' + song.songName;
		if(lastCardSongKey != cardKey)
		{
			if(lastCardSongKey.length > 0) animateCardChange();
			lastCardSongKey = cardKey;
		}
	}

	function updateHint():Void
	{
		if (sortText != null)
			sortText.text = Language.getPhrase('freeplay_sort', 'Sort: {1} (TAB)', [ClientPrefs.data.freeplaySort])
				+ ' | ' + Language.getPhrase('freeplay_random_hint', 'Random (R)')
				+ ' | ' + Language.getPhrase('freeplay_mix_hint', 'Mix (Q/E)');

		if (favText != null)
		{
			if (songs.length < 1)
				favText.text = '';
			else
				favText.text = (isFavourite(songs[curSelected])
					? Language.getPhrase('freeplay_fav_yes', 'Favourite: YES (F to remove)')
					: Language.getPhrase('freeplay_fav_no', 'Favourite: NO (F to add)'));
		}

		if (noResultsText != null)
			noResultsText.visible = songs.length < 1;
	}

	function stopSongPreview():Void
	{
		if (!player.playingMusic) return;

		FlxG.sound.music.stop();
		destroyFreeplayVocals();
		FlxG.sound.music.volume = 0;
		instPlaying = -1;

		player.playingMusic = false;
		player.switchPlayMusic();

		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
	}

	override function destroy():Void
	{
		if (searchBox != null && PsychUIInputText.focusOn == searchBox)
			PsychUIInputText.focusOn = null;

		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (FlxG.sound.music != null && !FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var category:String = "BF Mixes";
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}