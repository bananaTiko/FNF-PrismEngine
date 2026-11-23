package flxanimate.filters;

import flixel.system.FlxAssets.FlxShader;

/**
 * Project-local copy of flxanimate's MaskShader.
 *
 * The upstream shader writes `0.` and `1.` for float literals. Strict GLSL
 * implementations (including Mesa's software renderer) reject those in
 * relational operators with "could not implicitly convert operands to
 * relational operator", which crashes any FlxAnimate mask render. Use
 * explicit `0.0`/`1.0` literals instead.
 */
class MaskShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform sampler2D mainPalette;

	uniform vec2 relativePos;

	void main()
	{
		vec2 maskPos = vec2(openfl_TextureCoordv.x + (relativePos.x), openfl_TextureCoordv.y + (relativePos.y));

		float maskAlpha = texture2D(mainPalette, maskPos).a;

		if ((maskPos.x < 0.0 || maskPos.x > 1.0) || (maskPos.y < 0.0 || maskPos.y > 1.0))
			maskAlpha = 0.0;

		if (maskAlpha > 0.0)
			maskAlpha = 1.0;

		gl_FragColor = texture2D(bitmap, openfl_TextureCoordv) * maskAlpha;
	}
	')

	public function new()
	{
		super();
		relativePos.value = [0, 0];
	}
}
