package backend;

import flixel.system.scaleModes.BaseScaleMode;
import flixel.system.scaleModes.RatioScaleMode;

/**
 * Switches the game between letterboxed 16:9 and widescreen ("no black bars").
 *
 * This is opt-in: `ClientPrefs.data.widescreen` starts at false, and desktop is
 * the only place it does anything. `refresh()` is cheap and idempotent, so it is
 * safe to call from every state creation - it only swaps the scale mode when the
 * saved setting and the current mode disagree.
 */
class Widescreen
{
	/** The scale mode currently installed, if it is ours. */
	public static inline function isActive():Bool
		return Std.isOfType(FlxG.scaleMode, WidescreenScaleMode);

	public static inline function isSupported():Bool
	{
		#if desktop
		return true;
		#else
		return false;
		#end
	}

	/** Applies the saved setting. Call after prefs load, and when the option changes. */
	public static function refresh():Void
	{
		if(!isSupported()) return;
		apply(ClientPrefs.data != null && ClientPrefs.data.widescreen);
	}

	public static function apply(enable:Bool):Void
	{
		if(!isSupported()) return;
		// Before FlxGame has measured the window there is nothing to scale.
		if(FlxG.stage == null || FlxG.initialWidth < 1 || FlxG.initialHeight < 1) return;

		if(enable == isActive()) return;

		var oldWidth:Int = FlxG.width;
		var oldHeight:Int = FlxG.height;
		FlxG.scaleMode = enable ? new WidescreenScaleMode() : new RatioScaleMode();
		syncCameras(oldWidth, oldHeight);
	}

	/**
	 * Grows the cameras that were exactly the old game size, so the extra width is
	 * actually rendered. Cameras that were deliberately a different size (previews,
	 * minimaps) are left alone.
	 */
	public static function syncCameras(oldWidth:Int, oldHeight:Int):Void
	{
		if(FlxG.cameras == null || oldWidth < 1 || oldHeight < 1) return;
		if(FlxG.width == oldWidth && FlxG.height == oldHeight) return;

		for (camera in FlxG.cameras.list)
		{
			if(camera == null) continue;
			if(camera.width == oldWidth && camera.height == oldHeight)
				camera.setSize(FlxG.width, FlxG.height);
		}
	}
}
