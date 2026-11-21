package prismui;

/**
 * Base class for every prismUI control.
 *
 * A widget is a row: a surface, a focus accent bar and a label. It knows how to
 * resize itself, how to draw hover/focus/disabled states from `PrismTheme`, and
 * how to turn a mouse click into `onPress`. Subclasses add a value column, a
 * switch, a slider track, and so on.
 */
class PrismWidget extends FlxSpriteGroup
{
	public var wid(default, null):Float = 240;
	public var hei(default, null):Float = 44;

	public var focusable:Bool = true;
	public var enabled(default, set):Bool = true;
	public var focused(default, set):Bool = false;
	public var hovered:Bool = false;

	public var bg(default, null):FlxSprite;
	public var accentBar(default, null):FlxSprite;
	public var labelText(default, null):FlxText;

	/** Mouse click or keyboard accept. */
	public var onPress:Void->Void = null;
	/** Mouse entered the row. */
	public var onHover:Void->Void = null;

	@:isVar public var label(get, set):String;
	public var description:String = '';
	/** Free slot for whatever the owner needs to hang off the widget. */
	public var data:Dynamic = null;

	public function new(x:Float = 0, y:Float = 0, label:String = '')
	{
		super(x, y);

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(bg);

		accentBar = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(accentBar);

		labelText = new FlxText(0, 0, 100, '');
		add(labelText);

		this.label = label;
		resize(PrismUI.px(PrismUI.theme.rowWidth), PrismUI.px(PrismUI.theme.rowHeight));
	}

	public function resize(width:Float, height:Float):Void
	{
		wid = width;
		hei = height;

		bg.setGraphicSize(Std.int(width), Std.int(height));
		bg.updateHitbox();

		accentBar.setGraphicSize(PrismUI.px(PrismUI.theme.accentBar), Std.int(height));
		accentBar.updateHitbox();
		accentBar.x = 0;
		accentBar.y = 0;

		layout();
		refreshStyle();
	}

	/** Places the label; subclasses extend this to lay out their own pieces. */
	public function layout():Void
	{
		var pad:Float = PrismUI.px(PrismUI.theme.rowPadding) + PrismUI.px(PrismUI.theme.accentBar);
		labelText.x = pad;
		labelText.y = hei * 0.5 - labelText.height * 0.5;
	}

	public function refreshStyle():Void
	{
		var t:PrismTheme = PrismUI.theme;

		if(focused && enabled)
		{
			bg.color = t.surfaceActive;
			bg.alpha = 1;
		}
		else if(hovered && enabled)
		{
			bg.color = t.surfaceHover;
			bg.alpha = 1;
		}
		else
		{
			bg.color = t.surfaceRaised;
			bg.alpha = enabled ? 0.9 : 0.45;
		}

		accentBar.visible = focused && enabled;
		accentBar.color = t.accent;

		labelText.color = !enabled ? t.textDisabled : (focused ? t.text : t.textMuted);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if(bg == null || !exists || !visible) return;

		var wasHovered:Bool = hovered;
		hovered = enabled && FlxG.mouse.overlaps(bg, camera);
		if(hovered && !wasHovered && onHover != null) onHover();
		if(hovered && enabled && FlxG.mouse.justPressed) activate();

		refreshStyle();
	}

	/** Mouse click or keyboard accept on this row. */
	public function activate():Void
	{
		if(!enabled) return;
		if(onPress != null) onPress();
	}

	/** Left/right adjustment (-1 or +1). Rows with a value override this. */
	public function adjust(direction:Int):Void {}

	public function setLabelText(value:String):Void
	{
		label = value;
	}

	function get_label():String
		return labelText.text;

	function set_label(value:String):String
	{
		labelText.text = value == null ? '' : value;
		PrismUI.theme.styleText(labelText, PrismUI.px(PrismUI.theme.fontSize), PrismUI.theme.text);
		layout();
		refreshStyle();
		return (label = value);
	}

	function set_enabled(value:Bool):Bool
	{
		enabled = value;
		if(!value) hovered = false;
		refreshStyle();
		return value;
	}

	function set_focused(value:Bool):Bool
	{
		focused = value;
		refreshStyle();
		return value;
	}
}
