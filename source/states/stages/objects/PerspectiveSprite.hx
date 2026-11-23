package states.stages.objects;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;

/**
 * V-Slice's PerspectiveSprite, used by the Spaghetti stage for its floor.
 *
 * Skews a FlxSkewedSprite so its bottom-centre sits on one point and its
 * top-centre lands on another, with independent scroll factors for each point.
 * That cheap fake perspective is what keeps the diner floor lined up with the
 * stools and tables while the camera pans and zooms.
 *
 * Ported from preload/scripts/stages/props/PerspectiveSprite.hxc.
 */
class PerspectiveSprite extends FlxTypedSpriteGroup<FlxSprite>
{
	public var sprite:FlxSkewedSprite;
	public var bottomObj:FlxObject;
	public var topObj:FlxObject;

	public function new()
	{
		super(0, 0);

		sprite = new FlxSkewedSprite();
		sprite.matrixExposed = true;
		sprite.antialiasing = true;
		add(sprite);

		bottomObj = new FlxObject();
		topObj = new FlxObject();
	}

	/** Sets the bottom point first, then the top point. */
	public function setPositions(bottomX:Float, bottomY:Float, topX:Float, topY:Float):Void
	{
		bottomObj.setPosition(bottomX, bottomY);
		topObj.setPosition(topX, topY);
	}

	/** Sets the bottom point's scroll factors first, then the top point's. */
	public function setScrollFactors(bottomX:Float, bottomY:Float, topX:Float, topY:Float):Void
	{
		bottomObj.scrollFactor.set(bottomX, bottomY);
		topObj.scrollFactor.set(topX, topY);
	}

	/**
	 * Pins the bottom-centre of the sprite to the bottom point and skews the
	 * top-centre to the top point. V-Slice calls this every frame with camGame.
	 */
	public function updateSkew(?targetCam:FlxCamera):Void
	{
		if (targetCam == null) targetCam = FlxG.camera;

		// Correct for the different scroll factors so both points stay put on screen.
		var correctedBottom:FlxPoint = new FlxPoint(bottomObj.x + (targetCam.scroll.x * (sprite.scrollFactor.x - bottomObj.scrollFactor.x)),
			bottomObj.y + (targetCam.scroll.y * (sprite.scrollFactor.y - bottomObj.scrollFactor.y)));
		var correctedTop:FlxPoint = new FlxPoint(topObj.x + (targetCam.scroll.x * (sprite.scrollFactor.x - topObj.scrollFactor.x)),
			topObj.y + (targetCam.scroll.y * (sprite.scrollFactor.y - topObj.scrollFactor.y)));

		var distX:Float = correctedTop.x - correctedBottom.x;
		var distY:Float = correctedTop.y - (correctedBottom.y - sprite.height);

		sprite.transformMatrix.a = 1;
		sprite.transformMatrix.b = 0;
		sprite.transformMatrix.c = -(distX / sprite.height);
		sprite.transformMatrix.d = 1 - (distY / sprite.height);
		sprite.transformMatrix.tx = distX / 2;
		sprite.transformMatrix.ty = distY / 2;

		// Align the sprite's bottom-centre to the bottom point.
		sprite.x = correctedBottom.x - sprite.width / 2;
		sprite.y = correctedBottom.y - sprite.height;
	}

	override public function isOnScreen(?camera:FlxCamera):Bool
	{
		// Skewing pushes the sprite out of its normal bounds, so it must never be culled.
		return true;
	}
}
