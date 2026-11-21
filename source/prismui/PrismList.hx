package prismui;

/**
 * A vertical list of prismUI widgets with one selected row.
 *
 * Handles wrap-around keyboard navigation, mouse hover/click, the paged window
 * that keeps the selection on screen, and the shared menu sounds, so every menu
 * in the engine gets the same behaviour instead of a copy of the same loop.
 */
class PrismList extends FlxSpriteGroup
{
	public var items(default, null):Array<PrismWidget> = [];
	public var selected(default, set):Int = 0;

	/** How many rows are on screen at once; the window scrolls past that. */
	public var visibleRows(default, set):Int = 6;
	public var rowWidth:Float = 560;
	public var rowHeight:Float = 46;
	public var rowGap:Float = 4;
	public var wrap:Bool = true;

	public var keyboard:Bool = true;
	public var mouse:Bool = true;
	public var playSounds:Bool = true;
	/** Hold shift to jump several rows at once, for long lists like the language picker. */
	public var fastStep:Bool = false;

	/** Selection moved (keyboard, mouse or code). */
	public var onChange:Int->Void = null;
	/** Accept pressed, or a row clicked. */
	public var onActivate:Int->Void = null;

	var _offset:Int = 0;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		rowWidth = PrismUI.theme.rowWidth;
		rowHeight = PrismUI.theme.rowHeight;
		rowGap = PrismUI.theme.rowGap;
	}

	public function addItem(item:PrismWidget):PrismWidget
	{
		if(item == null) return null;

		var index:Int = items.length;
		items.push(item);
		add(item);

		item.resize(PrismUI.px(rowWidth), PrismUI.px(rowHeight));
		item.onHover = function() {
			if(mouse) select(index, true);
		};
		item.onPress = function() {
			if(mouse) select(index, true);
			if(playSounds) PrismUI.sound('confirmMenu', 0.6);
			if(onActivate != null) onActivate(index);
		};

		relayout();
		return item;
	}

	public function clearItems():Void
	{
		for (item in items)
		{
			if(item == null) continue;
			remove(item, true);
		}

		items = [];
		_offset = 0;
		@:bypassAccessor selected = 0;
	}

	public function moveSelection(delta:Int):Void
	{
		if(items.length < 1) return;
		select(selected + delta); //the select sound lives in select(), so it plays once
	}

	public function activate():Void
	{
		if(items.length < 1 || selected < 0 || selected >= items.length) return;
		if(playSounds) PrismUI.sound('confirmMenu', 0.6);
		if(onActivate != null) onActivate(selected);
	}

	public function adjustSelected(direction:Int):Void
	{
		if(items.length < 1 || selected < 0 || selected >= items.length) return;
		items[selected].adjust(direction);
	}

	/** Selects a row; `silent` skips the scroll sound. */
	public function select(index:Int, silent:Bool = false):Void
	{
		if(items.length < 1) return;

		var target:Int = index;
		if(wrap) target = ((index % items.length) + items.length) % items.length;
		else target = Std.int(Math.max(0, Math.min(items.length - 1, index)));

		if(target == selected)
		{
			refreshSelection();
			return;
		}

		if(!silent && playSounds) PrismUI.sound('scrollMenu', 0.4);
		selected = target;
	}

	/** Re-reads the selected row, e.g. after a menu rebuilt its items. */
	public function refreshSelection():Void
	{
		for (i in 0...items.length)
		{
			var item:PrismWidget = items[i];
			if(item == null) continue;
			item.focused = (i == selected);
		}
		relayout();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if(!keyboard || items.length < 1 || !exists || !visible) return;

		var ctrl:Controls = Controls.instance;
		if(ctrl == null) return;

		var step:Int = (fastStep && FlxG.keys.pressed.SHIFT) ? 4 : 1;
		if(ctrl.UI_UP_P) moveSelection(-step);
		if(ctrl.UI_DOWN_P) moveSelection(step);
		if(ctrl.UI_LEFT_P) adjustSelected(-1);
		if(ctrl.UI_RIGHT_P) adjustSelected(1);
		if(ctrl.ACCEPT) activate();
	}

	/** Keeps the selected row inside the paged window and stacks the rows. */
	public function relayout():Void
	{
		if(items.length < 1) return;

		var rows:Int = Std.int(Math.max(1, Math.min(visibleRows, items.length)));

		if(selected < _offset) _offset = selected;
		else if(selected >= _offset + rows) _offset = selected - rows + 1;
		_offset = Std.int(Math.max(0, Math.min(_offset, items.length - rows)));

		for (i in 0...items.length)
		{
			var item:PrismWidget = items[i];
			if(item == null) continue;

			var slot:Int = i - _offset;
			var onScreen:Bool = slot >= 0 && slot < rows;

			item.x = 0;
			item.y = slot * PrismUI.px(rowHeight + rowGap);
			item.visible = onScreen;
			item.alpha = onScreen ? 1 : 0;
		}
	}

	function set_selected(value:Int):Int
	{
		@:bypassAccessor selected = value;
		refreshSelection();
		if(onChange != null) onChange(value);
		return value;
	}

	function set_visibleRows(value:Int):Int
	{
		visibleRows = Std.int(Math.max(1, value));
		relayout();
		return visibleRows;
	}
}
