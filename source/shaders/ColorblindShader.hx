package shaders;

import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;

/**
 * Colour-vision-deficiency filter.
 *
 * Each mode is the standard daltonize colour matrix for that deficiency, so reds and greens (or
 * blues and greens) that used to collapse into the same shade become distinguishable instead of
 * just tinted. Used as a camera filter, so it covers the stage and the HUD in one pass.
 */
class ColorblindShader extends FlxShader
{
	public static final OFF:String = 'Off';
	public static final MODES:Array<String> = [OFF, 'Protanopia', 'Deuteranopia', 'Tritanopia'];

	/**
	 * Row-major matrices: output channel = row . input rgb.
	 * Protanopia (no red cones), deuteranopia (no green cones), tritanopia (no blue cones).
	 */
	static final MATRICES:Map<String, Array<Float>> = [
		'Protanopia' => [
			0.152286, 1.052583, -0.204868,
			0.114503, 0.786281, 0.099216,
			-0.003882, -0.048116, 1.051998
		],
		'Deuteranopia' => [
			0.367322, 0.860646, -0.227968,
			0.280085, 0.672501, 0.047413,
			-0.011820, 0.042940, 0.968881
		],
		'Tritanopia' => [
			1.255528, -0.076749, -0.178779,
			-0.078411, 0.930809, 0.147602,
			0.004733, 0.691367, 0.303900
		]
	];

	/** One shared filter per mode, so cameras can hold on to the same instance. */
	static var cache:Map<String, ShaderFilter> = [];

	/** The filter for `mode`, or null when the filter is off. */
	public static function filterFor(mode:String):ShaderFilter
	{
		if (mode == null || mode == OFF || !MATRICES.exists(mode)) return null;

		if (!cache.exists(mode))
		{
			var shader = new ColorblindShader();
			shader.mode = mode;
			cache.set(mode, new ShaderFilter(shader));
		}
		return cache.get(mode);
	}

	public var mode(default, set):String;

	function set_mode(value:String):String
	{
		mode = value;

		var rows:Array<Float> = MATRICES.get(value);
		if (rows == null)
			rows = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];

		// GLSL matrices are column-major, so the flat value list transposes the rows above.
		colorMatrix.value = [
			rows[0], rows[3], rows[6],
			rows[1], rows[4], rows[7],
			rows[2], rows[5], rows[8]
		];
		return mode;
	}

	@:glFragmentSource('
		#pragma header

		uniform mat3 colorMatrix;

		void main()
		{
			vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);

			// The camera render texture is premultiplied, as everywhere else in Flixel.
			vec3 rgb = col.a > 0.0 ? col.rgb / col.a : col.rgb;
			vec3 shifted = colorMatrix * rgb;

			gl_FragColor = vec4(shifted * col.a, col.a);
		}
	')
	public function new()
	{
		super();
		mode = OFF;
	}
}
