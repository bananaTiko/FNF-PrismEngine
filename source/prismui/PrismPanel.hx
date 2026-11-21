package prismui;

/**
 * A prismUI surface: shaded body, header strip, title and a content group.
 *
 * Menus put a list (or several columns of widgets) into `content`, so they only
 * have to lay out their own rows relative to (0, 0).
 */
class PrismPanel extends FlxSpriteGroup
{
	public var wid(default, null):Float = 600;
	public var hei(default, null):Float = 400;

	public var bg(default, null):FlxSprite;
	public var header(default, null):FlxSprite;
	public var headerLine(default, null):FlxSprite;
	public var titleText(default, null):FlxText;
	public var content(default, null):FlxSpriteGroup;

	@:isVar public var title(get, set):String;

	public function new(x:Float = 0, y:Float = 0, width:Float = 800, height:Float = 520, title:String = '')
	{
		super(x, y);

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bg.color = PrismUI.theme.surface;
		bg.alpha = 0.94;
		add(bg);

		header = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(header);

		headerLine = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		headerLine.color = PrismUI.theme.accent;
		add(headerLine);

		titleText = new FlxText(0, 0, 100, title);
		add(titleText);

		content = new FlxSpriteGroup();
		add(content);

		resize(width, height);
		this.title = title;
	}

	public function resize(width:Float, height:Float):Void
	{
		wid = width;
		hei = height;
		var t:PrismTheme = PrismUI.theme;
		var headerHeight:Float = PrismUI.px(t.headerHeight);
		var pad:Float = PrismUI.px(t.panelPadding);

		bg.setGraphicSize(Std.int(width), Std.int(height));
		bg.updateHitbox();

		header.setGraphicSize(Std.int(width), Std.int(headerHeight));
		header.updateHitbox();
		header.color = t.surfaceRaised;
		header.alpha = 1;

		headerLine.setGraphicSize(Std.int(width), PrismUI.px(2));
		headerLine.updateHitbox();
		headerLine.y = headerHeight;

		titleText.x = pad;
		titleText.y = headerHeight * 0.5 - titleText.height * 0.5;

		content.x = pad;
		content.y = headerHeight + pad;
	}

	/** Centres the panel on the game screen. */
	public function center():Void
	{
		x = (FlxG.width - wid) * 0.5;
		y = (FlxG.height - hei) * 0.5;
	}

	/** Adds a widget or group to the panel's content area. */
	public function addContent<T:FlxSprite>(object:T):T
	{
		content.add(object);
		return object;
	}

	function get_title():String
		return titleText.text;

	function set_title(value:String):String
	{
		titleText.text = value == null ? '' : value;
		PrismUI.theme.styleText(titleText, PrismUI.px(PrismUI.theme.titleSize), PrismUI.theme.text);
		titleText.x = PrismUI.px(PrismUI.theme.panelPadding);
		titleText.y = PrismUI.px(PrismUI.theme.headerHeight) * 0.5 - titleText.height * 0.5;
		return (title = value);
	}
}
