package prismui;

import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;

/**
 * The single place colours, fonts and spacing live.
 *
 * Every prismUI widget draws itself with these values, and the older `backend.ui`
 * editor panels pull their colours from here too, so a menu, a chart editor box and
 * an options row all look like they belong to the same game.
 */
class PrismTheme
{
	// Surfaces, darkest to lightest
	public var background:FlxColor = 0xF20A0812;
	public var surface:FlxColor = 0xFF151121;
	public var surfaceRaised:FlxColor = 0xFF211A33;
	public var surfaceHover:FlxColor = 0xFF302649;
	public var surfaceActive:FlxColor = 0xFF3C2F5C;

	// Lines and accents
	public var border:FlxColor = 0xFF3B3054;
	public var accent:FlxColor = 0xFFEA71FD;
	public var accentDark:FlxColor = 0xFF6B2A78;

	// Type
	public var text:FlxColor = 0xFFFFFFFF;
	public var textMuted:FlxColor = 0xFFA99EC2;
	public var textDisabled:FlxColor = 0xFF5F5776;
	public var danger:FlxColor = 0xFFFF5C8A;
	public var success:FlxColor = 0xFF62F2A0;

	public var font:String = 'vcr.ttf';
	public var fontSize:Int = 22;
	public var valueSize:Int = 20;
	public var titleSize:Int = 30;
	public var descriptionSize:Int = 18;

	// Metrics, in design pixels; prismUI scales them through PrismUI.px()
	public var rowHeight:Float = 46;
	public var rowGap:Float = 4;
	public var rowWidth:Float = 560;
	public var rowPadding:Float = 14;
	public var accentBar:Float = 5;
	public var panelPadding:Float = 16;
	public var headerHeight:Float = 44;

	public function new() {}

	inline public function fontPath():String
		return Paths.font(font);

	public function styleText(txt:FlxText, size:Int, color:FlxColor, align:FlxTextAlign = FlxTextAlign.LEFT):Void
	{
		txt.setFormat(fontPath(), size, color, align, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.borderSize = 1.4;
	}

	/** Draws a value as a bar fill, e.g. sliders, from 0..1. */
	public function fillColor(amount:Float):FlxColor
	{
		return (amount <= 0) ? textDisabled : accent;
	}
}
