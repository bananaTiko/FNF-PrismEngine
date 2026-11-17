package backend;

/**
 * Port of P-Slice's `mikolka.compatibility.VsliceOptions`, mapped onto Prism Engine's
 * own client preferences so the ported stage code can share one set of flags.
 */
class VsliceOptions
{
	public static var FLASHBANG(get, never):Bool;
	static function get_FLASHBANG():Bool return ClientPrefs.data.flashing;

	public static var ANTIALIASING(get, never):Bool;
	static function get_ANTIALIASING():Bool return ClientPrefs.data.antialiasing;

	public static var LOW_QUALITY(get, never):Bool;
	static function get_LOW_QUALITY():Bool return ClientPrefs.data.lowQuality;

	public static var CAM_ZOOMING(get, never):Bool;
	static function get_CAM_ZOOMING():Bool return ClientPrefs.data.camZooms;

	public static var SHADERS(get, never):Bool;
	static function get_SHADERS():Bool return ClientPrefs.data.shaders;

	/**
	 * Whether the "naughty" dialogue/asset variants may be used.
	 * Prism has no such toggle yet, so this follows the flashing setting.
	 */
	public static var NAUGHTYNESS(get, never):Bool;
	static function get_NAUGHTYNESS():Bool return ClientPrefs.data.flashing;
}
