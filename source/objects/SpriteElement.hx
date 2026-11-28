package objects;

import flxanimate.animate.FlxElement;

/**
 * A sprite put inside of a texture atlas' frames, to be drawn along with them wherever those frames show up: V-Slice's
 * `animate.internal.elements.FlxSpriteElement`. It's how the LE SSERAFIM characters get their mouths: the atlas has a
 * `mouth` symbol where the mouth goes, and a sprite that follows the song is put on that symbol's frames.
 *
 *     var element = new SpriteElement(mouth);
 *     for (frame in atlas.getFramesWithKeyword('mouth')) frame.add(element);
 *
 * The sprite is drawn on the coordinates of the symbol it was put in, with its own position, offset, scale, angle and flip
 * (see `flxanimate.PsychFlxAnimate.drawPlacedSprite()`). The atlas doesn't update it: whoever made it does.
 */
class SpriteElement extends FlxElement
{
	public var sprite:Dynamic;

	public function new(?sprite:Dynamic)
	{
		super();
		this.sprite = sprite;
	}
}
