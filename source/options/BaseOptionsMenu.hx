package options;

import prismui.PrismList;
import prismui.PrismPanel;
import prismui.PrismUI;
import prismui.PrismValueRow;

import flixel.text.FlxText.FlxTextAlign;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

import options.Option;
import backend.GamepadIcons;
import backend.InputFormatter;

/**
 * Shared settings menu, now built from prismUI rows.
 *
 * Every settings screen in the game (graphics, visuals, gameplay, mod settings,
 * language...) extends this class, so this is the single place the option list
 * is drawn: a `PrismPanel` with a `PrismList` of `PrismValueRow`s, one per
 * `Option`. Switches, sliders and the keybind overlay all live here; what an
 * option *does* is still entirely up to `Option` and its subclasses.
 */
class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var rows:Array<PrismValueRow> = [];
	private var list:PrismList;
	private var panel:PrismPanel;

	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	public var bg:FlxSprite;
	public function new()
	{
		super();

		if(title == null) title = Language.getPhrase('options_title', 'Options');
		if(rpcTitle == null) rpcTitle = Language.getPhrase('rpc_options_menu', 'Options Menu');

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = PrismUI.theme.accentDark;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var dim:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		dim.scale.set(FlxG.width, FlxG.height);
		dim.updateHitbox();
		dim.alpha = 0.4;
		add(dim);

		panel = new PrismPanel(40, 0, 800, 580, title);
		panel.y = (FlxG.height - panel.hei) * 0.5;
		add(panel);

		list = new PrismList();
		list.rowWidth = panel.wid - PrismUI.px(PrismUI.theme.panelPadding) * 2;
		list.rowHeight = 46;
		list.visibleRows = 8;
		list.onChange = function(index:Int) {
			curSelected = index;
			curOption = optionsArray[index];
			onSelectionChanged();
			updateDescription();
		};
		list.onActivate = function(index:Int) pressOption(optionsArray[index]);
		panel.addContent(list);

		descText = new FlxText(PrismUI.px(PrismUI.theme.panelPadding), 0,
			panel.wid - PrismUI.px(PrismUI.theme.panelPadding) * 2, '', PrismUI.px(PrismUI.theme.descriptionSize));
		PrismUI.theme.styleText(descText, PrismUI.px(PrismUI.theme.descriptionSize), PrismUI.theme.textMuted, FlxTextAlign.CENTER);
		panel.add(descText);

		for (i in 0...optionsArray.length)
		{
			var option:Option = optionsArray[i];
			var row:PrismValueRow = new PrismValueRow(0, 0, option.name);
			row.data = option;
			row.description = option.description;
			row.onAdjust = function(direction:Int) adjustOption(option, direction, true);
			option.child = row;
			rows.push(row);
			list.addItem(row);
		}

		// fill in every value once, now that each option has its row
		for (option in optionsArray)
			updateTextFrom(option);

		curOption = optionsArray[0];
		list.select(0, true);
		list.refreshSelection();
		reloadCheckboxes();
		updateDescription();
		onSelectionChanged();

		FlxG.mouse.visible = true;
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:FlxText;
	var bindingText2:FlxText;

	/** Called whenever the highlighted option changes. Subclasses hook previews here. */
	public function onSelectionChanged():Void {}

	override function update(elapsed:Float)
	{
		if(bindingKey)
		{
			bindingKeyUpdate(elapsed);
			super.update(elapsed);
			return;
		}

		super.update(elapsed);

		if(nextAccept <= 0)
		{
			// A single press is handled by the row itself; this only ramps while held.
			final canRamp:Bool = curOption != null && curOption.type != STRING
				&& curOption.type != BOOL && curOption.type != KEYBIND;

			if(canRamp && (controls.UI_LEFT || controls.UI_RIGHT))
			{
				if(holdTime > 0.5)
				{
					holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
					holdValue = clampNumeric(curOption, holdValue);
					applyNumeric(curOption, holdValue);
					updateTextFrom(curOption);
					curOption.change();
				}
				holdTime += elapsed;
			}
			else if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
			{
				if(holdTime > 0.5) FlxG.sound.play(Paths.sound('scrollMenu'));
				holdTime = 0;
			}
			else if(!controls.UI_LEFT && !controls.UI_RIGHT)
			{
				holdTime = 0;
			}

			if(controls.RESET)
			{
				var leOption:Option = optionsArray[curSelected];
				if(leOption.type != KEYBIND)
				{
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != BOOL)
					{
						if(leOption.type == STRING) leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				}
				else
				{
					leOption.setValue(!controls.controllerMode ? leOption.defaultKeys.keyboard : leOption.defaultKeys.gamepad);
					updateBind(leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function bindingKeyUpdate(elapsed:Float)
	{
		if(FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				if (!controls.controllerMode) curOption.keys.keyboard = NONE;
				else curOption.keys.gamepad = NONE;
				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			if(!controls.controllerMode)
			{
				if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast (FlxG.keys.firstJustReleased(), FlxKey);

					if(keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if(keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;
				if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER))
					keyPressed = LEFT_TRIGGER; //it wasnt working for some reason
				else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					keyPressed = RIGHT_TRIGGER; //it wasnt working for some reason
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if(gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();
							if(keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}

				if(keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if(keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}

			if(changed)
			{
				var key:String = null;
				if(!controls.controllerMode)
				{
					if(curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';
					curOption.setValue(curOption.keys.keyboard);
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if(curOption.keys.gamepad == null) curOption.keys.gamepad = 'NONE';
					curOption.setValue(curOption.keys.gamepad);
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	function updateBind(?text:String = null, ?option:Option = null)
	{
		if(option == null) option = curOption;
		if(text == null)
		{
			text = option.getValue();
			if(text == null) text = 'NONE';

			if(!controls.controllerMode)
				text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else
				text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}

		var row:PrismValueRow = rowFor(option);
		if(row == null) return;

		row.setValueText(text);
		gamepadIconCheck(row, text);
	}

	function gamepadIconCheck(row:PrismValueRow, text:String)
	{
		if(!controls.controllerMode)
		{
			row.clearIcon();
			return;
		}

		//draws the symbol the connected pad has for this bind
		var frame:String = GamepadIcons.frameFor(text);
		if(frame != null) row.setIcon(frame);
		else row.clearIcon();
	}

	function startBinding()
	{
		bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bindingBlack.scale.set(FlxG.width, FlxG.height);
		bindingBlack.updateHitbox();
		bindingBlack.alpha = 0;
		FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
		add(bindingBlack);

		bindingText = new FlxText(0, 160, FlxG.width, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [curOption.name]), 32);
		PrismUI.theme.styleText(bindingText, 32, PrismUI.theme.accent, FlxTextAlign.CENTER);
		add(bindingText);

		bindingText2 = new FlxText(0, 340, FlxG.width, Language.getPhrase('controls_rebinding2', 'Hold ESC to Cancel\nHold Backspace to Delete'), 32);
		PrismUI.theme.styleText(bindingText2, 32, PrismUI.theme.textMuted, FlxTextAlign.CENTER);
		add(bindingText2);

		bindingKey = true;
		holdingEsc = 0;
		list.keyboard = false;
		ClientPrefs.toggleVolumeKeys(false);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function closeBinding()
	{
		bindingKey = false;
		if(bindingBlack != null)
		{
			remove(bindingBlack);
			bindingBlack.destroy();
			bindingBlack = null;
		}

		if(bindingText != null)
		{
			remove(bindingText);
			bindingText.destroy();
			bindingText = null;
		}

		if(bindingText2 != null)
		{
			remove(bindingText2);
			bindingText2.destroy();
			bindingText2 = null;
		}

		list.keyboard = true;
		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option) {
		if(option.type == KEYBIND)
		{
			updateBind(option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == PERCENT) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);

		refreshRow(rowFor(option), option);
	}

	/** Paints one row from its option, whatever kind it is. */
	function refreshRow(row:PrismValueRow, option:Option):Void
	{
		if(row == null || option == null) return;

		row.showSwitch = (option.type == BOOL);
		row.showSlider = (option.type == INT || option.type == FLOAT || option.type == PERCENT);

					switch(option.type)
			{
				case BOOL:
					row.switchOn = (option.getValue() == true);
					row.setValueText('');
				case KEYBIND:
					updateBind(option);
				default:
					row.clearIcon();
					option.refreshChild(); //keeps the per-value translation
			}

		if(row.showSlider) row.sliderValue = sliderFraction(option);
	}

	function rowFor(option:Option):PrismValueRow
	{
		for (row in rows)
			if(row != null && row.data == option) return row;
		return null;
	}

	function sliderFraction(option:Option):Float
	{
		var min:Dynamic = option.minValue;
		var max:Dynamic = option.maxValue;
		var value:Dynamic = option.getValue();
		var minF:Float = (min == null) ? 0 : (min : Float);
		var maxF:Float = (max == null) ? 1 : (max : Float);
		var valF:Float = (value == null) ? 0 : (value : Float);
		return (maxF > minF) ? (valF - minF) / (maxF - minF) : 0;
	}

	function clampNumeric(option:Option, value:Dynamic):Float
	{
		var result:Float = (value : Float);
		var min:Dynamic = option.minValue;
		var max:Dynamic = option.maxValue;
		if(min != null && result < (min : Float)) result = (min : Float);
		if(max != null && result > (max : Float)) result = (max : Float);
		return result;
	}

	function applyNumeric(option:Option, value:Float):Void
	{
		if(option.type == INT)
			option.setValue(Math.round(value));
		else
			option.setValue(FlxMath.roundDecimal(value, option.decimals));
	}

	function pressOption(option:Option):Void
	{
		if(option == null || nextAccept > 0) return;

		switch(option.type)
		{
			case BOOL:
				FlxG.sound.play(Paths.sound('scrollMenu'));
				option.setValue(option.getValue() != true);
				option.change();
				reloadCheckboxes();

			case KEYBIND:
				startBinding();

			default:
		}
	}

	/** Left/right on a row: a press steps once, holding is ramped in `update()`. */
	function adjustOption(option:Option, direction:Int, fromPress:Bool = true):Void
	{
		if(option == null || direction == 0) return;
		if(option.type == BOOL || option.type == KEYBIND) return;

		if(option.type == STRING)
		{
			if(!fromPress) return;
			var num:Int = option.curOption + direction;
			if(num < 0)
				num = option.options.length - 1;
			else if(num >= option.options.length)
				num = 0;

			option.curOption = num;
			option.setValue(option.options[num]);
		}
		else
		{
			var next:Dynamic = option.getValue() + direction * option.changeValue;
			holdValue = clampNumeric(option, next);
			applyNumeric(option, holdValue);
			if(fromPress) holdTime = 0;
		}

		updateTextFrom(option);
		option.change();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateDescription():Void
	{
		if(descText == null || optionsArray == null || curSelected < 0 || curSelected >= optionsArray.length) return;

		descText.text = optionsArray[curSelected].description;
		var height:Float = descText.textField.textHeight > 0 ? descText.textField.textHeight : descText.height;
		descText.y = panel.hei - PrismUI.px(PrismUI.theme.panelPadding) - height;
	}

	function changeSelection(change:Int = 0)
	{
		if(optionsArray == null || optionsArray.length < 1) return;
		if(list != null) list.select(FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1));
	}

	function reloadCheckboxes()
	{
		for (row in rows)
		{
			if(row == null) continue;
			var option:Option = row.data;
			refreshRow(row, option);
		}
	}
}
