package shaders;

import flixel.util.FlxColor;

/**
 * V-Slice's shader for the SSERAFIM diner, ported from `funkin/graphics/shaders/SserafimShader.hx`.
 *
 * It does two things the stage needs: it darkens the stage (instead of a black overlay), and it
 * tints whatever it is applied to with the colour of the lights behind the truck, which is what
 * gives the chorus its purple/pink glow. The truck's own lights brighten the scene through the
 * same shader.
 *
 * The hue/saturation/brightness/contrast block is a recreation of Animate's "Adjust Color" filter,
 * written by Rozebud, adapted from Andrey-Postelzhuks' shader.
 */
class SserafimShader extends ErrorHandledShader
{
	/** How dark the stage currently is, 0-1. */
	public var darkenAmount(default, set):Float;

	/** Colour of the pulse light behind the truck. */
	public var pulseLightColor(default, set):FlxColor;

	/** How strong the pulse light behind the truck is. */
	public var pulseLightStrength(default, set):Float;

	/** How strong the truck's own lights are. */
	public var truckLightStrength(default, set):Float;

	/** Characters react more strongly to the lights than the stage does. */
	public var isCharacter(default, set):Bool;

	public var baseHue(default, set):Float;
	public var baseSaturation(default, set):Float;
	public var baseBrightness(default, set):Float;
	public var baseContrast(default, set):Float;

	/** The pulse light's colour after the HSL round trip, ready for the shader. */
	var pulseColorValue:Array<Float>;

	/** Sets all four "Adjust Color" values at once. */
	public function setAdjustColor(brightness:Float, hue:Float, contrast:Float, saturation:Float):Void
	{
		baseBrightness = brightness;
		baseHue = hue;
		baseContrast = contrast;
		baseSaturation = saturation;
	}

	function set_baseHue(val:Float):Float
	{
		baseHue = val;
		hue.value = [val];
		return val;
	}

	function set_baseSaturation(val:Float):Float
	{
		baseSaturation = val;
		saturation.value = [val];
		return val;
	}

	function set_baseBrightness(val:Float):Float
	{
		baseBrightness = val;
		brightness.value = [val];
		return val;
	}

	function set_baseContrast(val:Float):Float
	{
		baseContrast = val;
		contrast.value = [val];
		return val;
	}

	function set_darkenAmount(val:Float):Float
	{
		darkenAmount = val;
		darkAmt.value = [val];
		return val;
	}

	function set_pulseLightColor(col:FlxColor):FlxColor
	{
		pulseLightColor = col;
		updatePulseColor();
		return col;
	}

	function set_pulseLightStrength(val:Float):Float
	{
		pulseLightStrength = val;
		updatePulseColor();
		return val;
	}

	/**
	 * The shader used to scale the light colour in HSL space for every single pixel, which is the
	 * most expensive thing it did, and the light colour is one uniform for the whole sprite. The
	 * maths is done here instead, once per change, and the result goes to the shader as a colour.
	 */
	function updatePulseColor():Void
	{
		if (pulseLightStrength <= 0)
		{
			pulseColorValue = [0, 0, 0];
			pulseColor.value = pulseColorValue;
			return;
		}

		var r:Float = pulseLightColor.red / 255;
		var g:Float = pulseLightColor.green / 255;
		var b:Float = pulseLightColor.blue / 255;

		// rgb2hsl
		var cMin:Float = Math.min(Math.min(r, g), b);
		var cMax:Float = Math.max(Math.max(r, g), b);
		var delta:Float = cMax - cMin;
		var lightness:Float = (cMax + cMin) * 0.5;
		var hue:Float = 0;
		var saturation:Float = 0;

		if (delta != 0)
		{
			saturation = (lightness < 0.5) ? delta / (cMax + cMin) : delta / (2 - cMax - cMin);

			var dr:Float = (((cMax - r) / 6) + (delta / 2)) / delta;
			var dg:Float = (((cMax - g) / 6) + (delta / 2)) / delta;
			var db:Float = (((cMax - b) / 6) + (delta / 2)) / delta;

			if (r == cMax) hue = db - dg;
			else if (g == cMax) hue = (1 / 3) + dr - db;
			else hue = (2 / 3) + dg - dr;

			hue -= Math.floor(hue);
		}

		// hsl2rgb, with the lightness scaled by how strong the light is
		lightness *= pulseLightStrength;

		if (saturation == 0)
			pulseColorValue = [lightness, lightness, lightness];
		else
		{
			var q:Float = (lightness < 0.5) ? lightness * (1 + saturation) : lightness + saturation - lightness * saturation;
			var p:Float = 2 * lightness - q;
			var f:Float = hue * 6;
			pulseColorValue = [
				p + clamp01(Math.abs(f - 3) - 1) * (q - p),
				p + clamp01(2 - Math.abs(f - 2)) * (q - p),
				p + clamp01(2 - Math.abs(f - 4)) * (q - p)
			];
		}

		pulseColor.value = pulseColorValue;
	}

	static inline function clamp01(value:Float):Float
	{
		return value < 0 ? 0 : (value > 1 ? 1 : value);
	}

	function set_truckLightStrength(val:Float):Float
	{
		truckLightStrength = val;
		truckStrength.value = [val];
		return val;
	}

	function set_isCharacter(val:Bool):Bool
	{
		isCharacter = val;
		isChar.value = [val];
		return val;
	}

	@:glFragmentSource('
		#pragma header

		uniform float hue;
		uniform float saturation;
		uniform float brightness;
		uniform float contrast;

		uniform float darkAmt;
		uniform vec3 pulseColor;
		uniform float pulseStrength;
		uniform float truckStrength;
		uniform bool isChar;

		const vec3 grayscaleValues = vec3(0.3098039215686275, 0.607843137254902, 0.0823529411764706);
		const float e = 2.718281828459045;

		vec3 applyHueRotate(vec3 aColor, float aHue){
			float angle = radians(aHue);

			mat3 m1 = mat3(0.213, 0.213, 0.213, 0.715, 0.715, 0.715, 0.072, 0.072, 0.072);
			mat3 m2 = mat3(0.787, -0.213, -0.213, -0.715, 0.285, -0.715, -0.072, -0.072, 0.928);
			mat3 m3 = mat3(-0.213, 0.143, -0.787, -0.715, 0.140, 0.715, 0.928, -0.283, 0.072);
			mat3 m = m1 + cos(angle) * m2 + sin(angle) * m3;

			return m * aColor;
		}

		vec3 applySaturation(vec3 aColor, float value){
			if(value > 0.0){ value = value * 3.0; }
			value = (1.0 + (value / 100.0));
			vec3 grayscale = vec3(dot(aColor, grayscaleValues));
			return clamp(mix(grayscale, aColor, value), 0.0, 1.0);
		}

		vec3 applyContrast(vec3 aColor, float value){
			value = (1.0 + (value / 100.0));
			if(value > 1.0){
				value = (((0.00852259 * pow(e, 4.76454 * (value - 1.0))) * 1.01) - 0.0086078159) * 10.0;
				value += 1.0;
			}
			return clamp((aColor - 0.25) * value + 0.25, 0.0, 1.0);
		}

		vec3 applyHSBCEffect(vec3 color){
			color = color + ((brightness) / 255.0);
			color = applyHueRotate(color, hue);
			color = applyContrast(color, contrast);
			color = applySaturation(color, saturation);

			return color;
		}

		// controls how much to brighten/darken depending on combinedAlpha.
		const float lightMultiplier = 0.07;

		void main()
		{
			vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);

			vec3 unpremultipliedColor = col.a > 0.0 ? col.rgb / col.a : col.rgb;

			// Adjust Color is identity unless the stage actually set it, which is most of the
			// song, and it is the expensive half of this shader (hue matrix, contrast curve,
			// saturation mix). Skip it instead of computing a no-op for every pixel of every
			// prop, character and mouth.
			vec3 outColor = (hue == 0.0 && saturation == 0.0 && brightness == 0.0 && contrast == 0.0)
				? unpremultipliedColor
				: applyHSBCEffect(unpremultipliedColor);

			// No lights and no darkening: the multiply below would be white anyway.
			if (darkAmt == 0.0 && truckStrength == 0.0 && pulseStrength == 0.0)
			{
				gl_FragColor = vec4(outColor.rgb * col.a, col.a);
				return;
			}

			// truckLight1.alpha + backLightColor.alpha
			float combinedAlpha = truckStrength + pulseStrength;

			float darkFactor = (combinedAlpha*lightMultiplier) + darkAmt;
			if(darkAmt > 0.65) darkFactor = (combinedAlpha*(-1.0 * lightMultiplier)) + darkAmt;

			vec3 multiplyColor;

			// Already HSL-scaled on the CPU: the light colour is the same for every pixel, so
			// there is no reason to convert it per pixel here.
			vec3 bruhColor = pulseColor;

			if(isChar == true){
				multiplyColor = mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), darkFactor/5.0);
				multiplyColor = mix(multiplyColor, bruhColor, darkFactor/3.0);
			}else{
				multiplyColor = mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), darkFactor);
				multiplyColor = mix(multiplyColor, bruhColor, darkFactor/2.0);
			}

			outColor *= multiplyColor;

			gl_FragColor = vec4(outColor.rgb * col.a, col.a);
		}
	')

	public function new(char:Bool = false)
	{
		super('SserafimShader');

		darkenAmount = 0.0;
		pulseLightColor = FlxColor.WHITE;
		pulseLightStrength = 0.0;
		truckLightStrength = 0.0;
		isCharacter = char;

		baseHue = 0;
		baseSaturation = 0;
		baseBrightness = 0;
		baseContrast = 0;

		pulseColorValue = [0, 0, 0];
		pulseColor.value = pulseColorValue;
	}
}
