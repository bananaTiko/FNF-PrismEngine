package backend;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.Json;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * The sticker screen: a handful of stickers slapped over the playfield while a song
 * starts or ends.
 *
 * Only reached when the transition is set to `Sticker` *and* the state change involves
 * a song started from Freeplay — `Transitions.playIn`/`playOut` do that check, so Story
 * Mode and the menus keep the fade.
 *
 * Art lives in `images/transitionSwag/<set>/` in the shared assets or a mod, with the
 * default set called `default`. Every `.png` in that folder becomes a sticker; add a
 * `stickers.json` next to them to pick and order the names instead:
 *
 *   { "name": "default", "artist": "", "stickers": ["one", "two"] }
 *
 * With no art installed the transition closes immediately instead of holding the player
 * on a blank screen, so a missing sticker set can never trap anyone.
 */
class StickerTransition extends MusicBeatSubstate
{
	public static inline var SET:String = 'default';
	static inline var FOLDER:String = 'images/transitionSwag/';
	static inline var MAX_STICKERS:Int = 16;

	public static var finishCallback:Void->Void;

	public var duration:Float = 0.6;
	public var isTransIn:Bool = false;

	var stickers:Array<FlxSprite> = [];
	var elapsed:Float = 0;
	var closed:Bool = false;

	public function new(duration:Float = 0.6, isTransIn:Bool = false)
	{
		super();
		this.duration = duration;
		this.isTransIn = isTransIn;
	}

	override function create():Void
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var names:Array<String> = stickerNames();
		if(names.length < 1)
		{
			// Nothing installed: get out of the way rather than showing a blank screen.
			close();
			return;
		}

		var index:Int = 0;
		for (name in names)
		{
			var graphic = Paths.image(FOLDER + SET + '/' + name);
			if(graphic == null) continue;

			var sticker:FlxSprite = new FlxSprite();
			sticker.loadGraphic(graphic);
			sticker.scrollFactor.set();
			sticker.antialiasing = ClientPrefs.data.antialiasing;
			sticker.screenCenter();

			sticker.x += FlxG.random.float(-FlxG.width * 0.42, FlxG.width * 0.42);
			sticker.y += FlxG.random.float(-FlxG.height * 0.40, FlxG.height * 0.40);
			sticker.angle = FlxG.random.float(-20, 20);

			var targetScale:Float = 0.35 + FlxG.random.float(0, 0.4);
			add(sticker);
			stickers.push(sticker);

			if(isTransIn)
			{
				// Leaving: the stickers were already there, so shrink away quietly
				// while the new state finishes drawing.
				sticker.scale.set(targetScale);
				FlxTween.tween(sticker, {alpha: 0}, duration * 0.75, {startDelay: 0.05, ease: FlxEase.quadIn});
				FlxTween.tween(sticker.scale, {x: targetScale * 1.15, y: targetScale * 1.15}, duration * 0.75, {ease: FlxEase.quadOut});
			}
			else
			{
				// Entering: pop them in, one after another.
				var delay:Float = index * 0.015;
				sticker.alpha = 0;
				sticker.scale.set(targetScale * 0.4);
				FlxTween.tween(sticker, {alpha: 1}, 0.12, {startDelay: delay});
				FlxTween.tween(sticker.scale, {x: targetScale, y: targetScale}, 0.18, {startDelay: delay, ease: FlxEase.backOut});
			}

			++index;
		}

		super.create();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		this.elapsed += elapsed;
		if(!closed && this.elapsed >= duration)
			close();
	}

	/**
	 * Sticker names for a set, taken from the last folder that provides any (mods win,
	 * since `Mods.directoriesWithFile` lists shared assets first). An empty array means
	 * there is no sticker art at all.
	 */
	public static function stickerNames(?set:String = SET):Array<String>
	{
		var names:Array<String> = [];
		#if sys
		var folder:String = FOLDER + set + '/';
		var folders:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), folder);

		var i:Int = folders.length - 1;
		while (i >= 0)
		{
			var dir:String = folders[i];
			--i;

			if(!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) continue;

			var jsonFile:String = dir + 'stickers.json';
			if(FileSystem.exists(jsonFile))
			{
				try
				{
					var parsed:Dynamic = Json.parse(File.getContent(jsonFile));
					var list:Array<Dynamic> = Reflect.field(parsed, 'stickers');
					if(list != null)
					{
						for (entry in list)
						{
							var name:String = Std.string(entry);
							if(name.toLowerCase().endsWith('.png')) name = name.substr(0, name.length - 4);
							if(name.length > 0 && !names.contains(name)) names.push(name);
						}
					}
				}
				catch (e:Dynamic) trace('StickerTransition: could not read $jsonFile ($e)');
			}

			if(names.length < 1)
			{
				var files:Array<String> = FileSystem.readDirectory(dir);
				files.sort(Reflect.compare);
				for (file in files)
				{
					if(!file.toLowerCase().endsWith('.png')) continue;
					var name:String = file.substr(0, file.length - 4);
					if(!names.contains(name)) names.push(name);
				}
			}

			if(names.length > 0) break;
		}
		#end

		if(names.length > MAX_STICKERS)
			return names.slice(0, MAX_STICKERS);
		return names;
	}

	override function close():Void
	{
		if(closed) return;
		closed = true;

		super.close();

		if(finishCallback != null)
		{
			var callback:Void->Void = finishCallback;
			finishCallback = null;
			callback();
		}
	}
}
