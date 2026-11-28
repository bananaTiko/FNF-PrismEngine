package states.stages.objects;

import flixel.FlxSprite;
import objects.Character;
import objects.FlxAtlasSprite;

/**
 * One of Spaghetti's lip-sync mouths.
 *
 * V-Slice puts these inside the character atlas: each pose has a `mouth` symbol where the mouth goes, and the sprite is drawn
 * on that symbol's coordinates (see `objects.SpriteElement`), so it needs no position of its own on the stage. What's left is
 * the small per-pose offset and angle the character's script gives the mouth, and the frame the song is on.
 */
class SserafimLipSync extends FlxAtlasSprite
{
	public var character:Character;
	public var singing:Bool = false;

	// animation name -> [offsetX, offsetY, angle], V-Slice's `SserafimLipSyncPose`
	final offsets:Map<String, Array<Float>>;
	var posedFor:String = null;

	public function new(character:Character, path:String, offsets:Map<String, Array<Float>>, ?alpha:Float = 1.0, ?flip:Bool = false)
	{
		super(0, 0, path);
		this.character = character;
		this.offsets = offsets;
		this.alpha = alpha;
		if (flip) flipX = true;
	}

	/** The pose the character is on decides where the mouth sits on its face, and how it's turned. */
	public function applyPose(anim:String):Void
	{
		if (anim == posedFor) return;
		posedFor = anim;

		// Miss poses fall back to the idle numbers, like the character script's own switch does.
		var lip:Array<Float> = (anim != null && offsets.exists(anim)) ? offsets.get(anim) : offsets.get('idle');
		if (lip == null) return;

		x = lip[0];
		y = lip[1];
		angle = lip[2];
	}

	/** V-Slice flaps the mouth at 24fps straight from the song clock. */
	public function advance():Void
	{
		if (anim == null || anim.curInstance == null || anim.curSymbol == null) return;
		anim.curFrame = singing ? Std.int(Conductor.songPosition / 1000 * 24) - 1 : 0;
	}
}
