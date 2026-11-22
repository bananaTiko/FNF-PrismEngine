package backend;

/**
 * Small math helpers shared across the engine.
 *
 * FlxMath already covers `lerp`, `bound` and `remapToRange`; this class holds the
 * things it doesn't: degree-based trig, clamping, distance and a few curve helpers.
 */
class MathUtils
{
	public static var DEG_TO_RAD:Float = Math.PI / 180;
	public static var RAD_TO_DEG:Float = 180 / Math.PI;

	inline public static function degToRad(degrees:Float):Float
		return degrees * DEG_TO_RAD;

	inline public static function radToDeg(radians:Float):Float
		return radians * RAD_TO_DEG;

	inline public static function sinDeg(degrees:Float):Float
		return Math.sin(degrees * DEG_TO_RAD);

	inline public static function cosDeg(degrees:Float):Float
		return Math.cos(degrees * DEG_TO_RAD);

	inline public static function clamp(value:Float, min:Float, max:Float):Float
		return value < min ? min : (value > max ? max : value);

	inline public static function clampInt(value:Int, min:Int, max:Int):Int
		return value < min ? min : (value > max ? max : value);

	/** Rounds `value` to the nearest multiple of `step`. */
	inline public static function snap(value:Float, step:Float):Float
		return step == 0 ? value : Math.round(value / step) * step;

	inline public static function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var dx:Float = x2 - x1;
		var dy:Float = y2 - y1;
		return Math.sqrt(dx * dx + dy * dy);
	}

	/** Squared distance; cheaper than `distance` when you only compare lengths. */
	inline public static function distanceSq(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var dx:Float = x2 - x1;
		var dy:Float = y2 - y1;
		return dx * dx + dy * dy;
	}

	/** Angle in degrees from (x1, y1) towards (x2, y2). */
	inline public static function angleBetween(x1:Float, y1:Float, x2:Float, y2:Float):Float
		return Math.atan2(y2 - y1, x2 - x1) * RAD_TO_DEG;

	/** Loops `value` back into the [min, max) range, including negative values. */
	inline public static function wrap(value:Float, min:Float, max:Float):Float
	{
		var range:Float = max - min;
		if(range == 0) return min;
		var wrapped:Float = (value - min) % range;
		return (wrapped < 0 ? wrapped + range : wrapped) + min;
	}

	/** Moves `value` towards `target` by at most `amount`, without overshooting. */
	inline public static function approach(value:Float, target:Float, amount:Float):Float
		return value < target ? Math.min(value + amount, target) : Math.max(value - amount, target);
}
