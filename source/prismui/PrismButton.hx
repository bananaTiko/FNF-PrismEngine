package prismui;

import flixel.text.FlxText.FlxTextAlign;

/**
 * A plain prismUI button: a row with a centred label and one callback.
 */
class PrismButton extends PrismWidget
{
	public var centered:Bool = true;

	public function new(x:Float = 0, y:Float = 0, label:String = '', ?onPress:Void->Void, wid:Float = -1, hei:Float = -1)
	{
		super(x, y, label);

		this.onPress = onPress;
		resize(wid < 0 ? PrismUI.px(PrismUI.theme.rowWidth) : wid,
			hei < 0 ? PrismUI.px(PrismUI.theme.rowHeight) : hei);
	}

	override public function layout():Void
	{
		super.layout();

		if(!centered) return;

		var pad:Float = PrismUI.px(PrismUI.theme.rowPadding);
		labelText.fieldWidth = wid - pad * 2;
		labelText.x = pad;
		labelText.alignment = FlxTextAlign.CENTER;
		labelText.y = hei * 0.5 - labelText.height * 0.5;
	}
}
