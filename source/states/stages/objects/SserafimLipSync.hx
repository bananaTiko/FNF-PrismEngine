package states.stages.objects;

import objects.Character;
import objects.FlxAtlasSprite;

/**
 * One of Spaghetti's lip-sync mouths.
 *
 * V-Slice attaches these to the character atlas' mouth symbols. Psych's flxanimate
 * has no sprite elements inside atlas keyframes, so the mouth is drawn as its own
 * sprite at the anchor the character's current pose gives it.
 */
class SserafimLipSync extends FlxAtlasSprite
{
	public var character:Character;
	public var singing:Bool = false;
	// The stage's black cover sits above everything in V-Slice, mouths included.
	public var hiddenByCover:Bool = false;

	// animation name -> [x, y, angle] in the character atlas' own coordinates
	final anchors:Map<String, Array<Float>>;
	// animation name -> [offsetX, offsetY, angle] from the character's script
	final offsets:Map<String, Array<Float>>;
	// BF, dad and GF sit inside PlayState's sprite groups, so the mouth has to add
	// the group's offset to their local position.
	final parentX:Float;
	final parentY:Float;

	public function new(character:Character, path:String, anchors:Map<String, Array<Float>>, offsets:Map<String, Array<Float>>, parentX:Float = 0, parentY:Float = 0,
			?alpha:Float = 1.0, ?flip:Bool = false)
	{
		super(0, 0, path);
		this.character = character;
		this.anchors = anchors;
		this.offsets = offsets;
		this.parentX = parentX;
		this.parentY = parentY;
		this.alpha = alpha;
		if (flip) flipX = true;
		visible = false;
	}

	function anchorFor(anim:String):Array<Float>
	{
		if (anim == null) return null;

		var key:String = null;
		if (anim == 'idle' || anim == 'danceLeft' || anim == 'danceRight') key = 'idle';
		else if (anim.indexOf('LEFT') != -1) key = 'left';
		else if (anim.indexOf('DOWN') != -1) key = 'down';
		else if (anim.indexOf('UP') != -1) key = 'up';
		else if (anim.indexOf('RIGHT') != -1) key = 'right';

		return key == null ? null : anchors.get(key);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (character == null)
		{
			visible = false;
			return;
		}

		var animName:String = character.getAnimationName();
		var anchor:Array<Float> = anchorFor(animName);
		visible = !hiddenByCover && character.visible && character.alpha > 0.5 && anchor != null;
		if (!visible) return;

		var lip:Array<Float> = offsets.exists(animName) ? offsets.get(animName) : offsets.get('idle');

		scale.set(character.scale.x, character.scale.y);
		scrollFactor.set(character.scrollFactor.x, character.scrollFactor.y);
		angle = character.angle + anchor[2] + (lip != null ? lip[2] : 0);
		if (lip != null) offset.set(lip[0], lip[1]);

		x = parentX + character.x + anchor[0] * character.scale.x;
		y = parentY + character.y + anchor[1] * character.scale.y;

		// V-Slice flaps the mouth at 24 fps straight from the song clock.
		if (singing) anim.curFrame = Std.int(Conductor.songPosition / 1000 * 24) - 1;
		else anim.curFrame = 0;
	}
}
