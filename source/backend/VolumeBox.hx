package backend;

import flixel.FlxG;
import flixel.system.ui.FlxSoundTray;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.media.Sound;

/**
 * V-Slice's volume box, standing in for flixel's plain meters.
 *
 * Flixel calls `show()` whenever a volume or mute key changes the volume. This subclass
 * throws away the drawn box and bars and uses the art V-Slice ships instead —
 * `images/soundtray/volumebox` with `bars_1` .. `bars_10` laid over it — then slides it
 * down from the top of the screen and fades it back out a second later. Changing the
 * volume plays `soundtray/Volup` or `Voldown`, and `VolMAX` when it is already at 100%.
 *
 * It is installed as flixel's custom tray from Main (see `_customSoundTray`), so it draws
 * over the game the way the original does rather than living inside a state.
 */
class VolumeBox extends FlxSoundTray
{
	static inline var GRAPHIC_SCALE:Float = 0.30;
	static inline var BAR_X:Float = 9;
	static inline var BAR_Y:Float = 5;
	static inline var MARGIN:Float = 10;

	// How long each value takes to close in on its target, in seconds.
	static inline var SLIDE_DURATION:Float = 0.768;
	static inline var FADE_DURATION:Float = 0.307;

	var boxWidth:Float = 0;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;
	var upSound:Sound;
	var downSound:Sound;
	var maxSound:Sound;

	public function new()
	{
		super();

		// The stock tray has its own box, label and bars, and scales itself up 2x.
		removeChildren();
		scaleX = scaleY = 1;
		_bars = [];

		addChild(makeBitmap('soundtray/volumebox', 0, 0));

		// Faint full bar underneath, so the empty slots still read as a meter.
		var backing:Bitmap = makeBitmap('soundtray/bars_10', BAR_X, BAR_Y);
		backing.alpha = 0.4;
		addChild(backing);

		for (i in 1...11)
		{
			var bar:Bitmap = makeBitmap('soundtray/bars_$i', BAR_X, BAR_Y);
			bar.visible = false;
			addChild(bar);
			_bars.push(bar);
		}

		upSound = Paths.sound('soundtray/Volup');
		downSound = Paths.sound('soundtray/Voldown');
		maxSound = Paths.sound('soundtray/VolMAX');

		visible = false;
		screenCenter();
		y = -height - MARGIN;
	}

	override public function update(ms:Float):Void
	{
		var elapsed:Float = ms / 1000;

		// A muted game shows an empty box rather than nothing, so the player can tell why
		// the volume keys stopped making a difference.
		var hasVolume:Bool = !FlxG.sound.muted && FlxG.sound.volume > 0;

		if (hasVolume)
		{
			if (_timer > 0)
			{
				_timer -= elapsed;
				if (_timer <= 0)
				{
					lerpYPos = -height - MARGIN;
					alphaTarget = 0;
				}
			}
			else if (y <= -height)
			{
				visible = false;
				active = false;
				saveVolumePreferences();
			}
		}
		else if (!visible)
		{
			popUp();
		}

		y = smoothLerp(y, lerpYPos, elapsed, SLIDE_DURATION);
		alpha = smoothLerp(alpha, alphaTarget, elapsed, FADE_DURATION);
		screenCenter();
	}

	override public function show(up:Bool = false):Void
	{
		if (!silent)
		{
			var sound:Sound = null;
			if (!FlxG.sound.muted)
			{
				if (up && FlxG.sound.volume >= 1) sound = maxSound;
				else sound = up ? upSound : downSound;
			}
			if (sound != null) FlxG.sound.play(sound);
		}

		popUp();
		saveVolumePreferences();
	}

	override public function screenCenter():Void
	{
		// The stock version centers an assumed 80px box; ours has to use the real art.
		if (boxWidth <= 0) boxWidth = Paths.image('soundtray/volumebox').width * GRAPHIC_SCALE;
		x = 0.5 * (Lib.current.stage.stageWidth - boxWidth) - FlxG.game.x;
	}

	function popUp():Void
	{
		_timer = 1;
		lerpYPos = MARGIN;
		visible = true;
		active = true;
		alphaTarget = 1;
		updateBars();
	}

	function updateBars():Void
	{
		var filled:Int = (FlxG.sound.muted || FlxG.sound.volume <= 0) ? 0 : Math.round(FlxG.sound.volume * 10);

		for (i in 0..._bars.length)
			_bars[i].visible = i < filled;
	}

	function makeBitmap(key:String, x:Float, y:Float):Bitmap
	{
		var bmp:Bitmap = new Bitmap(Paths.image(key).bitmap);
		bmp.x = x;
		bmp.y = y;
		bmp.scaleX = bmp.scaleY = GRAPHIC_SCALE;
		bmp.smoothing = true;
		return bmp;
	}

	function saveVolumePreferences():Void
	{
		#if FLX_SAVE
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}

	/** Exponential decay, so the slide and fade look the same at any framerate. */
	static inline function smoothLerp(value:Float, target:Float, elapsed:Float, duration:Float):Float
	{
		if (value == target || elapsed <= 0) return target;
		return target + Math.pow(0.01, elapsed / duration) * (value - target);
	}
}
