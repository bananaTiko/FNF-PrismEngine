package shaders;

import flixel.addons.display.FlxRuntimeShader;

class AdjustColorShader extends FlxRuntimeShader
{
  //Kept inline: the fragment used to be loaded from assets/shared/shaders/adjustColor.frag,
  //which isn't shipped, so every stage that tints with this shader crashed on load.
  static final FRAGMENT_SOURCE:String = '#pragma header

uniform float hue;
uniform float saturation;
uniform float brightness;
uniform float contrast;

vec3 applyHue(vec3 color, float hueDegrees)
{
	float angle = radians(hueDegrees);
	vec3 axis = vec3(0.57735, 0.57735, 0.57735);
	float cosAngle = cos(angle);
	return color * cosAngle + cross(axis, color) * sin(angle) + axis * dot(axis, color) * (1.0 - cosAngle);
}

vec3 applySaturation(vec3 color, float value)
{
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(grey), color, 1.0 + value / 100.0);
}

vec3 applyBrightness(vec3 color, float value)
{
	return clamp(color + vec3(value / 100.0), 0.0, 1.0);
}

vec3 applyContrast(vec3 color, float value)
{
	return clamp((color - 0.5) * (1.0 + value / 100.0) + 0.5, 0.0, 1.0);
}

void main()
{
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	if (color.a > 0.0)
	{
		color.rgb = applyHue(color.rgb, hue);
		color.rgb = applySaturation(color.rgb, saturation);
		color.rgb = applyBrightness(color.rgb, brightness);
		color.rgb = applyContrast(color.rgb, contrast);
	}

	gl_FragColor = color;
}';

  public var hue(default, set):Float;
  public var saturation(default, set):Float;
  public var brightness(default, set):Float;
  public var contrast(default, set):Float;

  public function new()
  {
    super(FRAGMENT_SOURCE);
    // FlxG.debugger.addTrackerProfile(new TrackerProfile(HSVShader, ['hue', 'saturation', 'brightness', 'contrast']));
    hue = 0;
    saturation = 0;
    brightness = 0;
    contrast = 0;
  }

  function set_hue(value:Float):Float
  {
    this.setFloat('hue', value);
    this.hue = value;

    return this.hue;
  }

  function set_saturation(value:Float):Float
  {
    this.setFloat('saturation', value);
    this.saturation = value;

    return this.saturation;
  }

  function set_brightness(value:Float):Float
  {
    this.setFloat('brightness', value);
    this.brightness = value;

    return this.brightness;
  }

  function set_contrast(value:Float):Float
  {
    this.setFloat('contrast', value);
    this.contrast = value;

    return this.contrast;
  }
}
