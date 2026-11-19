package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.gamepad.FlxGamepad;
import objects.Alphabet;

/**
 * Button symbols for the pad that is actually connected.
 *
 * The bind menus used to swap only PlayStation's square and triangle into the
 * text (see the old playstationCheck), which left every other pad showing
 * letters. This draws the real symbol for each bind instead, picking the Xbox,
 * PlayStation or Nintendo variant from the detected model.
 */
class GamepadIcons
{
	public static inline var ATLAS:String = 'ui/controllerIcons';
	static inline var ICON_HEIGHT:Float = 64;

	// bind label as written by InputFormatter -> frame prefix in the atlas
	static var LABELS:Map<String, String> = [
		'A' => 'a', 'B' => 'b', 'X' => 'x', 'Y' => 'y',
		'O' => 'b', '[' => 'x', ']' => 'y', // PlayStation face buttons
		'L1' => 'left_shoulder', 'LB' => 'left_shoulder', 'L' => 'left_shoulder',
		'R1' => 'right_shoulder', 'RB' => 'right_shoulder', 'R' => 'right_shoulder',
		'L2' => 'left_trigger', 'LT' => 'left_trigger', 'ZL' => 'left_trigger',
		'R2' => 'right_trigger', 'RT' => 'right_trigger', 'ZR' => 'right_trigger',
		'L3' => 'left_stick_click', 'LS' => 'left_stick_click',
		'R3' => 'right_stick_click', 'RS' => 'right_stick_click',
		'Start' => 'start', 'Options' => 'start', '+' => 'start',
		'Back' => 'back', 'Share' => 'back', 'Select' => 'back', '-' => 'back',
		'Guide' => 'guide',
		'D. Up' => 'dpad_up', 'D. Down' => 'dpad_down',
		'D. Left' => 'dpad_left', 'D. Right' => 'dpad_right'
	];

	public static function currentModel():FlxGamepadModel
	{
		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		return gamepad != null ? gamepad.detectedModel : FlxGamepadModel.UNKNOWN;
	}

	static function modelSuffix(model:FlxGamepadModel):String
	{
		switch(model)
		{
			case PS4, PSVITA:
				return '_ps';
			case SWITCH_PRO, SWITCH_JOYCON_LEFT, SWITCH_JOYCON_RIGHT:
				return '_nin';
			default:
				return '';
		}
	}

	/** Frame prefix for a bind label, or null when that bind has no symbol. */
	public static function frameFor(text:String, ?model:FlxGamepadModel = null):String
	{
		if(text == null) return null;
		if(model == null) model = currentModel();

		var key:String = LABELS.get(text);
		if(key == null) return null;

		// On PlayStation, "X" in a bind means cross, not the Xbox X button
		if(text == 'X' && (model == PS4 || model == PSVITA)) key = 'a';
		return key + modelSuffix(model);
	}

	static function animNames(icon:FlxSprite):Array<String>
	{
		var names:Array<String> = [];
		if(icon.frames == null) return names;
		for (frame in icon.frames.frames)
		{
			if(frame.name == null) continue;
			var name:String = frame.name;
			var i:Int = name.length;
			// the atlas names its frames <anim><digits>, so drop the digits
			while (i > 0 && name.charCodeAt(i - 1) >= 48 && name.charCodeAt(i - 1) <= 57) i--;
			names.push(name.substr(0, i));
		}
		return names;
	}

	/**
	 * Replaces the first letter of `alpha` with the matching symbol, hiding the
	 * rest of the text. Returns true when the bind has a symbol to show.
	 */
	public static function apply(alpha:Alphabet):Bool
	{
		if(alpha == null || alpha.letters.length == 0) return false;

		var key:String = frameFor(alpha.text);
		if(key == null) return false;

		var icon:FlxSprite = new FlxSprite();
		icon.frames = Paths.getSparrowAtlas(ATLAS);

		var names:Array<String> = animNames(icon);
		var frame:String = key;
		if(names.indexOf(frame) < 0)
		{
			// not every set ships every variant (the dpad only has default and PS)
			var cut:Int = frame.indexOf('_ps');
			if(cut < 0) cut = frame.indexOf('_nin');
			if(cut > -1) frame = frame.substr(0, cut);
			if(names.indexOf(frame) < 0) return false;
		}

		icon.animation.addByPrefix('icon', frame, 24, false);
		icon.animation.play('icon');
		icon.antialiasing = ClientPrefs.data.antialiasing;
		icon.updateHitbox();
		if(icon.height > 0) icon.scale.set(ICON_HEIGHT / icon.height, ICON_HEIGHT / icon.height);

		var first = alpha.letters[0];
		icon.setPosition(first.x, first.y + first.height - icon.height);
		for (letter in alpha.letters)
			if(letter != null) letter.visible = false;

		alpha.add(icon); // preAdd offsets it by the group's own position
		return true;
	}
}
