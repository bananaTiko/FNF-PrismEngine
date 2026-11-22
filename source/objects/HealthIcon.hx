package objects;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	/**
	 * Finds the icon for a character. Stage variants like `bf-car` or `mom-car` usually
	 * don't have their own art, so the suffix is dropped a piece at a time before falling
	 * back to the generic face.
	 */
	static function findIconImage(char:String):String
	{
		var candidate:String = char;
		while(candidate != null && candidate.length > 0)
		{
			var name:String = 'icons/' + candidate;
			if(Paths.fileExists('images/' + name + '.png', IMAGE)) return name;

			name = 'icons/icon-' + candidate; //Older versions of psych engine's support
			if(Paths.fileExists('images/' + name + '.png', IMAGE)) return name;

			var dash:Int = candidate.lastIndexOf('-');
			if(dash < 0) break;
			candidate = candidate.substr(0, dash);
		}
		return 'icons/icon-face'; //Prevents crash from missing icon
	}

	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		if(this.char != char) {
			var name:String = findIconImage(char);
			
			var graphic = Paths.image(name, allowGPU);
			var iSize:Float = Math.round(graphic.width / graphic.height);
			loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
			updateHitbox();

			animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			if(char.endsWith('-pixel') || name.indexOf('-pixel') > -1)
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
