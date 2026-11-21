package prismui;

import backend.GamepadIcons;

import flixel.text.FlxText.FlxTextAlign;

/**
 * A label with a value column on the right.
 *
 * The owner of the row decides what the value is and what happens when it is
 * changed; the row just draws it as text, a switch or a slider, and reports
 * left/right presses through `onAdjust`. That keeps `options.Option` in charge
 * of how settings behave while prismUI stays in charge of how they look.
 */
class PrismValueRow extends PrismWidget
{
	public var valueText(default, null):FlxText;
	public var iconSprite(default, null):FlxSprite;

	public var showSwitch(default, set):Bool = false;
	public var switchOn(default, set):Bool = false;
	public var showSlider(default, set):Bool = false;
	public var sliderValue(default, set):Float = 0;

	/** Called with -1 (left) or +1 (right). */
	public var onAdjust:Int->Void = null;

	var switchTrack:FlxSprite;
	var switchKnob:FlxSprite;
	var trackBg:FlxSprite;
	var trackFill:FlxSprite;

	public function new(x:Float = 0, y:Float = 0, label:String = '')
	{
		super(x, y, label);

		trackBg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(trackBg);
		trackFill = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(trackFill);
		switchTrack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(switchTrack);
		switchKnob = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(switchKnob);

		valueText = new FlxText(0, 0, 100, '');
		add(valueText);

		iconSprite = new FlxSprite();
		iconSprite.visible = false;
		add(iconSprite);

		layout();
		refreshStyle();
	}

	override public function layout():Void
	{
		var t:PrismTheme = PrismUI.theme;
		var pad:Float = PrismUI.px(t.rowPadding);
		var switchW:Float = PrismUI.px(46);
		var switchH:Float = PrismUI.px(22);
		var right:Float = wid - pad;

		if(valueText != null)
		{
			var valueRight:Float = showSwitch ? right - switchW - pad : right;
			var valueW:Float = Math.max(PrismUI.px(50), wid * 0.32);
			valueText.fieldWidth = valueW;
			valueText.alignment = FlxTextAlign.RIGHT;
			valueText.x = Math.max(pad, valueRight - valueW);
			valueText.y = hei * 0.5 - valueText.height * 0.5;
		}

		labelText.fieldWidth = Math.max(PrismUI.px(10), wid - pad * 2 - PrismUI.px(t.accentBar) - wid * 0.32 - (showSwitch ? switchW + pad : 0));
		labelText.x = pad + PrismUI.px(t.accentBar);
		labelText.y = hei * 0.5 - labelText.height * 0.5;

		switchTrack.setGraphicSize(Std.int(switchW), Std.int(switchH));
		switchTrack.updateHitbox();
		switchTrack.x = right - switchW;
		switchTrack.y = hei * 0.5 - switchH * 0.5;

		switchKnob.setGraphicSize(Std.int(switchH - PrismUI.px(6)), Std.int(switchH - PrismUI.px(6)));
		switchKnob.updateHitbox();
		switchKnob.y = switchTrack.y + PrismUI.px(3);
		switchKnob.x = switchOn ? switchTrack.x + switchW - switchKnob.width - PrismUI.px(3) : switchTrack.x + PrismUI.px(3);

		var trackW:Float = wid - pad * 2 - PrismUI.px(t.accentBar);
		var trackH:Float = PrismUI.px(6);
		trackBg.setGraphicSize(Std.int(trackW), Std.int(trackH));
		trackBg.updateHitbox();
		trackBg.x = pad + PrismUI.px(t.accentBar);
		trackBg.y = hei - PrismUI.px(11);

		trackFill.setGraphicSize(Std.int(Math.max(0, trackW * sliderValue)), Std.int(trackH));
		trackFill.updateHitbox();
		trackFill.x = trackBg.x;
		trackFill.y = trackBg.y;

		if(iconSprite != null && iconSprite.visible)
		{
			iconSprite.x = right - iconSprite.width;
			iconSprite.y = hei * 0.5 - iconSprite.height * 0.5;
		}
	}

	override public function refreshStyle():Void
	{
		super.refreshStyle();

		if(valueText == null || switchTrack == null) return;

		var t:PrismTheme = PrismUI.theme;

		valueText.color = !enabled ? t.textDisabled : (focused ? t.accent : t.textMuted);
		valueText.visible = valueText.text.length > 0 && !iconSprite.visible;

		switchTrack.visible = showSwitch;
		switchKnob.visible = showSwitch;
		switchTrack.color = switchOn ? t.accent : t.border;
		switchTrack.alpha = switchOn ? 0.9 : 0.8;
		switchKnob.color = switchOn ? 0xFF17121F : t.textMuted;

		trackBg.visible = showSlider;
		trackFill.visible = showSlider;
		trackBg.color = 0xFF2A2340;
		trackBg.alpha = 0.85;
		trackFill.color = t.fillColor(sliderValue);
		trackFill.alpha = enabled ? 0.95 : 0.4;
	}

	public function setValueText(value:String):Void
	{
		valueText.text = value == null ? '' : value;
		PrismUI.theme.styleText(valueText, PrismUI.px(PrismUI.theme.valueSize), PrismUI.theme.textMuted, FlxTextAlign.RIGHT);
		if(valueText.text.length > 0) clearIcon();
		layout();
		refreshStyle();
	}

	/** Draws the connected pad's own symbol for a bind, instead of its name. */
	public function setIcon(frame:String):Void
	{
		if(frame == null || frame.length < 1)
		{
			clearIcon();
			return;
		}

		try
		{
			iconSprite.frames = Paths.getSparrowAtlas(GamepadIcons.ATLAS);
			iconSprite.animation.addByPrefix('icon', frame, 24, false);
			iconSprite.animation.play('icon');
			iconSprite.visible = true;
			iconSprite.setGraphicSize(PrismUI.px(26), PrismUI.px(26));
			iconSprite.updateHitbox();
			valueText.visible = false;
			layout();
		}
		catch(e:Dynamic)
		{
			// no atlas for this pad: fall back to the bind's name
			clearIcon();
		}
	}

	public function clearIcon():Void
	{
		if(iconSprite == null) return;
		iconSprite.visible = false;
		iconSprite.animation.stop();
		iconSprite.frames = null;
		valueText.visible = valueText.text.length > 0;
		layout();
	}

	override public function adjust(direction:Int):Void
	{
		if(!enabled || direction == 0) return;
		if(showSwitch) return; // switches are toggled with accept, like before
		if(onAdjust != null) onAdjust(direction);
	}

	function set_showSwitch(value:Bool):Bool
	{
		showSwitch = value;
		layout();
		refreshStyle();
		return value;
	}

	function set_switchOn(value:Bool):Bool
	{
		switchOn = value;
		layout();
		refreshStyle();
		return value;
	}

	function set_showSlider(value:Bool):Bool
	{
		showSlider = value;
		layout();
		refreshStyle();
		return value;
	}

	function set_sliderValue(value:Float):Float
	{
		sliderValue = Math.max(0, Math.min(1, value));
		layout();
		refreshStyle();
		return sliderValue;
	}
}
