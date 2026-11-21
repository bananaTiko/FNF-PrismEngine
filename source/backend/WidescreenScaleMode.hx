package backend;

import flixel.system.scaleModes.BaseScaleMode;

/**
 * Opt-in desktop "no black bars" scaling.
 *
 * The default `RatioScaleMode` keeps a 16:9 picture and letterboxes it, so a
 * 21:9 monitor wastes a third of its screen. This mode instead grows the game
 * itself to the window's aspect ratio: nothing is stretched and nothing is cut
 * off, the extra width simply becomes more visible game, and HUD or menus that
 * anchor to `FlxG.width` move out with it.
 *
 * Enable it with `FlxG.scaleMode = new WidescreenScaleMode();`, or through
 * `backend.Widescreen` which wraps it in the save-data option.
 */
class WidescreenScaleMode extends BaseScaleMode
{
	public function new()
	{
		super();
	}

	override public function onMeasure(Width:Int, Height:Int):Void
	{
		var oldWidth:Int = FlxG.width;
		var oldHeight:Int = FlxG.height;

		super.onMeasure(Width, Height);

		// Growing FlxG.width only shows more game if the cameras grow with it
		Widescreen.syncCameras(oldWidth, oldHeight);
	}

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		var baseRatio:Float = FlxG.initialWidth / FlxG.initialHeight;
		if(baseRatio <= 0 || Width <= 0 || Height <= 0)
		{
			gameSize.set(Width, Height);
			return;
		}

		var ratio:Float = Width / Height;
		if(ratio <= 0) ratio = baseRatio;

		if(ratio > baseRatio)
		{
			// Wider than the design: keep the design height, gain pixels on the sides.
			// FlxG.width/height are only writable inside flixel's scale-mode package,
			// which is why this needs untyped, same as MobileScaleMode.
			untyped FlxG.height = FlxG.initialHeight;
			untyped FlxG.width = Math.ceil(FlxG.initialHeight * ratio);
		}
		else
		{
			// Taller than the design (portrait window): keep the width, gain height.
			untyped FlxG.width = FlxG.initialWidth;
			untyped FlxG.height = Math.ceil(FlxG.initialWidth / ratio);
		}

		// Fill the window exactly, so there is no bar left to draw.
		gameSize.set(Width, Height);
	}
}
