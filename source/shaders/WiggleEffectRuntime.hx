package shaders;

import flixel.addons.display.FlxRuntimeShader;

enum WiggleEffectType
{
  DREAMY; // 0
  WAVY; // 1
  HEAT_WAVE_HORIZONTAL; // 2
  HEAT_WAVE_VERTICAL; // 3
  FLAG; // 4
}

/**
 * To use:
 * 1. Create an instance of the class, specifying speed, frequency, and amplitude.
 * 2. Call `sprite.shader = wiggleEffect` on the target sprite.
 * 3. Call the update() method on the instance every frame.
 */
class WiggleEffectRuntime extends FlxRuntimeShader
{
  //Kept inline: this used to be loaded from assets/shared/shaders/wiggle.frag, which isn't
  //shipped, so the week 6 erect stage crashed while building its background wiggles.
  static final FRAGMENT_SOURCE:String = '#pragma header

uniform float uTime;
uniform int effectType;
uniform float uSpeed;
uniform float uFrequency;
uniform float uWaveAmplitude;

const int EFFECT_TYPE_DREAMY = 0;
const int EFFECT_TYPE_WAVY = 1;
const int EFFECT_TYPE_HEAT_WAVE_HORIZONTAL = 2;
const int EFFECT_TYPE_HEAT_WAVE_VERTICAL = 3;
const int EFFECT_TYPE_FLAG = 4;

vec2 sineWave(vec2 pt)
{
	float x = 0.0;
	float y = 0.0;

	if (effectType == EFFECT_TYPE_DREAMY)
	{
		float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
		pt.x += offsetX;
	}
	else if (effectType == EFFECT_TYPE_WAVY)
	{
		float offsetY = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
		pt.y += offsetY;
	}
	else if (effectType == EFFECT_TYPE_HEAT_WAVE_HORIZONTAL)
	{
		x = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
	}
	else if (effectType == EFFECT_TYPE_HEAT_WAVE_VERTICAL)
	{
		y = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
	}
	else if (effectType == EFFECT_TYPE_FLAG)
	{
		y = sin(pt.y * uFrequency + 10.0 * pt.x + uTime * uSpeed) * uWaveAmplitude;
		x = sin(pt.x * uFrequency + 5.0 * pt.y + uTime * uSpeed) * uWaveAmplitude;
	}

	return vec2(pt.x + x, pt.y + y);
}

void main()
{
	vec2 uv = sineWave(openfl_TextureCoordv);
	gl_FragColor = texture2D(bitmap, uv);
}';

  public static function getEffectTypeId(v:WiggleEffectType):Int
  {
    return WiggleEffectType.getConstructors().indexOf(Std.string(v));
  }

  public var effectType(default, set):WiggleEffectType = DREAMY;

  function set_effectType(v:WiggleEffectType):WiggleEffectType
  {
    this.setInt('effectType', getEffectTypeId(v));
    return effectType = v;
  }

  public var waveSpeed(default, set):Float = 0;

  function set_waveSpeed(v:Float):Float
  {
    this.setFloat('uSpeed', v);
    return waveSpeed = v;
  }

  public var waveFrequency(default, set):Float = 0;

  function set_waveFrequency(v:Float):Float
  {
    this.setFloat('uFrequency', v);
    return waveFrequency = v;
  }

  public var waveAmplitude(default, set):Float = 0;

  function set_waveAmplitude(v:Float):Float
  {
    this.setFloat('uWaveAmplitude', v);
    return waveAmplitude = v;
  }

  var time(default, set):Float = 0;

  function set_time(v:Float):Float
  {
    this.setFloat('uTime', v);
    return time = v;
  }

  public function new(speed:Float, freq:Float, amplitude:Float, ?effect:WiggleEffectType = DREAMY):Void
  {
    super(FRAGMENT_SOURCE);

    // These values may not propagate to the shader until later.
    this.waveSpeed = speed;
    this.waveFrequency = freq;
    this.waveAmplitude = amplitude;
    this.effectType = effect;
  }

  public function update(elapsed:Float)
  {
    // The setter tied to this value automatically propagates the value to the shader.
    this.time += elapsed;
  }
}
