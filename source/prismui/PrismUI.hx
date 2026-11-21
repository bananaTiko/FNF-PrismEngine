package prismui;

import flixel.text.FlxText.FlxTextAlign;

/**
 * prismUI: the engine's one UI framework.
 *
 * Menus build themselves out of `PrismPanel` + `PrismList` + widgets, and the
 * editors' tool boxes are drawn with the same palette, so there is exactly one
 * look and one set of metrics to change instead of a dozen hardcoded ones.
 *
 * ```haxe
 * var panel = new PrismPanel(0, 0, 700, 520, 'Options');
 * panel.center();
 * add(panel);
 * var list = new PrismList();
 * panel.addContent(list);
 * list.addItem(new PrismButton(0, 0, 'Graphics', () -> openSubState(...)));
 * ```
 */
class PrismUI
{
	public static var theme(default, null):PrismTheme = new PrismTheme();

	/** Extra multiplier for widget metrics. 1.0 keeps the sizes the art was drawn at. */
	public static var uiScale:Float = 1;

	/** Turn off when a menu has its own feedback, or while rebinding keys. */
	public static var soundsEnabled:Bool = true;

	/** Design pixels to screen pixels, rounded so text and bars land on whole pixels. */
	public static inline function px(value:Float):Int
		return Std.int(Math.max(1, Math.round(value * uiScale)));

	/** A themed, outlined label. `width` of 0 lets the text size itself. */
	public static function text(x:Float, y:Float, content:String, size:Int = 22, color:FlxColor = 0xFFFFFFFF, ?width:Float = 0):FlxText
	{
		var txt:FlxText = new FlxText(x, y, width == null ? 0 : width, content, size);
		theme.styleText(txt, size, color);
		return txt;
	}

	/** Centred one-line label, used for panel titles and descriptions. */
	public static function centeredText(y:Float, content:String, size:Int = 22, color:FlxColor = 0xFFFFFFFF):FlxText
	{
		var txt:FlxText = new FlxText(0, y, FlxG.width, content, size);
		theme.styleText(txt, size, color, FlxTextAlign.CENTER);
		return txt;
	}

	public static function sound(name:String, volume:Float = 0.6):Void
	{
		if(!soundsEnabled || name == null) return;
		FlxG.sound.play(Paths.sound(name), volume);
	}

	/** Fades a colour towards the panel surface, for disabled or secondary text. */
	public static function muted(color:FlxColor, amount:Float = 0.5):FlxColor
	{
		return FlxColor.interpolate(color, theme.surface, amount);
	}
}
