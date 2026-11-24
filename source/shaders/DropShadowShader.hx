package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import openfl.display.BitmapData;

/**
 * V-Slice's rim light / drop shadow, ported from `funkin/graphics/shaders/DropShadowShader.hx`.
 *
 * The rim used to be a hard `luma > threshold` step smoothed by jittered samples, which left the
 * glow speckled and offset from the sprite's edge. This version takes the edge width from the
 * pixel neighbourhood (`fwidth` where the driver has derivatives) and fades the threshold with
 * `smoothstep`, so the highlight follows the sprite's own outline instead of a noisy mask.
 *
 * Also carries Animate's "Adjust Color" filter, since the stages use both together.
 */
class DropShadowShader extends FlxShader
{
  /** The color of the drop shadow. */
  public var color(default, set):FlxColor;

  /**
   * The angle of the drop shadow.
   * 0 = RIGHT, 90 = UP, 180 = LEFT, 270 = DOWN
   */
  public var angle(default, set):Float;

  /** An offset for the angle, used for rotated frames. */
  public var angleOffset(default, set):Float;

  /** The distance or size of the drop shadow, in pixels of the texture. */
  public var distance(default, set):Float;

  /** The strength of the drop shadow, an alpha multiplier. */
  public var strength(default, set):Float;

  /** Brightness threshold: anything below it is not affected by the drop shadow. */
  public var threshold(default, set):Float;

  /**
   * Kept for the stages that still set it. The edge width now comes from the pixel
   * neighbourhood, so there is no sample count to configure any more.
   */
  public var antialiasAmt(default, set):Float;

  /** Whether the shader should use the alternate mask. */
  public var useAltMask(default, set):Bool;

  /**
   * The image for the alternate mask: its blue channel marks what uses `maskThreshold`
   * instead of `threshold` (e.g. the tankmen on GF's speakers).
   */
  public var altMaskImage(default, set):BitmapData;

  public var maskThreshold(default, set):Float;

  public var attachedSprite(default, set):FlxSprite;

  public var baseHue(default, set):Float;
  public var baseSaturation(default, set):Float;
  public var baseBrightness(default, set):Float;
  public var baseContrast(default, set):Float;

  function makeHueMatrix(h:Float):Array<Float>
  {
    var c = Math.cos(h);
    var s = Math.sin(h);

    var wR = 0.299;
    var wG = 0.587;
    var wB = 0.114;

    return [
      wR + (1 - wR) * c - wR * s,          wG - wG * c - wG * s, wB - wB * c + (1 - wB) * s,
      wR - wR * c + 0.143 * s, wG + (1 - wG) * c + 0.140 * s,    wB - wB * c - 0.283 * s,
      wR - wR * c - (1 - wR) * s,          wG - wG * c + wG * s, wB + (1 - wB) * c + wB * s
    ];
  }

  function makeSaturationMatrix(s:Float):Array<Float>
  {
    var lr = 0.2126;
    var lg = 0.7152;
    var lb = 0.0722;

    var inv = 1.0 - s;

    return [
      lr * inv + s,     lg * inv,   lb * inv,
      lr * inv, lg * inv + s,   lb * inv,
      lr * inv,     lg * inv, lb * inv + s
    ];
  }

  function updateAngle():Void
  {
    var newAngle = (angle + angleOffset) * FlxAngle.TO_RAD;
    var cos = Math.cos(newAngle);
    var sin = Math.sin(newAngle);

    angCos.value = [cos];
    angSin.value = [sin];
  }

  /**
   * Sets all 4 adjust color values at once.
   * @param b The brightness value
   * @param h The hue value
   * @param c The contrast value
   * @param s The saturation value
   */
  public function setAdjustColor(b:Float, h:Float, c:Float, s:Float):Void
  {
    baseBrightness = b;
    baseHue = h;
    baseContrast = c;
    baseSaturation = s;
  }

  function set_baseHue(val:Float):Float
  {
    baseHue = val;

    hueMatrix.value = makeHueMatrix(val * FlxAngle.TO_RAD);
    return baseHue;
  }

  function set_baseSaturation(val:Float):Float
  {
    baseSaturation = val;

    if (val > 0)
      val *= 3;
    val = 1 + (val / 100);
    saturationMatrix.value = makeSaturationMatrix(val);
    return baseSaturation;
  }

  function set_baseBrightness(val:Float):Float
  {
    baseBrightness = val;

    brightness.value = [val / 255];
    return baseBrightness;
  }

  function set_baseContrast(val:Float):Float
  {
    var e:Float = 2.718281828459045;

    baseContrast = val;

    val = 1 + (val / 100);
    if (val > 1.0)
    {
      val = (((0.00852259 * Math.pow(e, 4.76454 * (val - 1.0))) * 1.01) - 0.0086078159) * 10.0;
      val += 1.0;
    }
    contrast.value = [val];
    return baseContrast;
  }

  function set_threshold(val:Float):Float
  {
    threshold = val;
    thr.value = [val];
    return val;
  }

  function set_antialiasAmt(val:Float):Float
  {
    // The new edge smoothing does not need samples, but the stages still set this.
    return antialiasAmt = val;
  }

  function set_angle(val:Float):Float
  {
    angle = val;
    updateAngle();
    return val;
  }

  function set_angleOffset(val:Float):Float
  {
    angleOffset = val;
    updateAngle();
    return val;
  }

  function set_distance(val:Float):Float
  {
    distance = val;
    dist.value = [val];
    return val;
  }

  function set_strength(val:Float):Float
  {
    strength = val;
    str.value = [val];
    return val;
  }

  function set_color(val:FlxColor):FlxColor
  {
    color = val;
    dropColor.value = [val.red / 255, val.green / 255, val.blue / 255];
    return val;
  }

  function set_attachedSprite(spr:FlxSprite):FlxSprite
  {
    attachedSprite = spr;
    updateFrameInfo(attachedSprite.frame);
    return spr;
  }

  public function loadAltMask(path:String):Void
  {
    #if html5
    BitmapData.loadFromFile(path).onComplete(function(bmp:BitmapData) {
      altMaskImage = bmp;
    });
    #else
    altMaskImage = openfl.display.BitmapData.fromFile(path);
    #end
  }

  public function onAttachedFrame(name:String, frameNum:Int, frameIndex:Int):Void
  {
    if (attachedSprite != null)
      updateFrameInfo(attachedSprite.frame);
  }

  public function updateFrameInfo(frame:FlxFrame):Void
  {
    uFrameBounds.value = [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.bottom];
    angleOffset = frame.angle;
  }

  function set_altMaskImage(_bitmapData:BitmapData):BitmapData
  {
    altMask.input = _bitmapData;

    return _bitmapData;
  }

  function set_maskThreshold(val:Float):Float
  {
    maskThreshold = val;
    thr2.value = [val];
    return val;
  }

  function set_useAltMask(val:Bool):Bool
  {
    useAltMask = val;
    useMask.value = [val];
    return val;
  }

  @:glFragmentSource('
    #pragma header

    // Smooth the threshold with the pixel neighbourhood where the driver has derivatives,
    // and fall back to a single pixel otherwise.
    #ifdef GL_ES
    #ifdef GL_OES_standard_derivatives
    #define HAS_DERIVATIVES
    #endif
    #else
    #if __VERSION__ >= 130
    #define HAS_DERIVATIVES
    #endif
    #endif

    // equals (frame.left, frame.top, frame.right, frame.bottom)
    uniform vec4 uFrameBounds;

    uniform float dist;
    uniform float str;
    uniform float thr;

    uniform float angCos;
    uniform float angSin;

    uniform sampler2D altMask;
    uniform bool useMask;
    uniform float thr2;

    uniform vec3 dropColor;

    uniform mat3 hueMatrix;
    uniform mat3 saturationMatrix;
    uniform float brightness;
    uniform float contrast;

    const vec3 lumaValue = vec3(0.2126, 0.7152, 0.0722);

    vec3 applyHSBCEffect(vec3 color)
    {
      vec3 bh = (brightness + color) * hueMatrix;
      vec3 c = (bh - 0.25) * contrast + 0.25;
      vec3 s = c * saturationMatrix;
      return s;
    }

    float getLumaRGB(vec3 color)
    {
      return dot(color.rgb, lumaValue);
    }

    vec4 getTexRGBA(vec2 uv)
    {
      return texture2D(bitmap, uv);
    }

    float getLumaTex(vec2 uv)
    {
      return getLumaRGB(getTexRGBA(uv).rgb);
    }

    // Average luma difference to the neighbours, so the threshold fades across an edge
    // instead of flipping on it.
    float lwidth_manual(float center, vec2 uv, vec2 px)
    {
      vec3 p2x1 = getTexRGBA(uv + vec2( 1.0,  0.0) * px).rgb;
      vec3 p1x2 = getTexRGBA(uv + vec2( 0.0,  1.0) * px).rgb;
      vec3 p2x2 = getTexRGBA(uv + vec2( 1.0,  1.0) * px).rgb;

      float right     = getLumaRGB(p2x1);
      float down      = getLumaRGB(p1x2);
      float diagonal  = getLumaRGB(p2x2);

      float dx = abs(right - center);
      float dy = abs(down - center);
      float dd = abs(diagonal - center);

      return ((dx + dy + dd * 0.7) / (1.0 + 1.0 + 0.7)) * 2.0;
    }

    float getThreshold(vec2 uv)
    {
      float threshold = thr;

      if (useMask)
      {
        float maskIntensity = texture2D(altMask, uv).b;
        if (maskIntensity > 0.0)
          threshold = thr2;
      }

      return threshold;
    }

    vec4 createDropShadowEx(vec2 uv, vec2 ratio, vec2 size)
    {
      vec4 color4 = texture2D(bitmap, uv);

      #ifdef HAS_DERIVATIVES
      vec2 px = max(ratio, fwidth(uv));
      #else
      vec2 px = ratio;
      #endif

      float color3_light = getLumaRGB(color4.rgb);
      float delta = lwidth_manual(color3_light, uv, px);

      float threshold = getThreshold(uv);

      // Anything dimmer than the threshold (the outlines in the sprite) keeps its colours
      // instead of taking the rim colour.
      float intensity = smoothstep(threshold - delta, threshold + delta, color3_light);

      float shadowAlpha = 0.0;

      // Un-premultiply before the colour filter, and premultiply again at the end.
      vec3 color3_no_effect = color4.a > 0.0 ? color4.rgb / color4.a : color4.rgb;
      vec3 color3 = applyHSBCEffect(color3_no_effect);

      // Sample the pixel in the lights direction: where it is empty, this pixel is on the
      // edge facing the light and takes the rim colour.
      vec2 checked = vec2(
        uv.x + (dist * angCos * ratio.x),
        uv.y - (dist * angSin * ratio.y)
      );

      if (checked.x > uFrameBounds.x &&
        checked.y > uFrameBounds.y &&
        checked.x < uFrameBounds.z &&
        checked.y < uFrameBounds.w)
      {
        shadowAlpha = texture2D(bitmap, checked).a;
      }

      float rim = (1.0 - (shadowAlpha * str)) * intensity;
      color3 += dropColor * rim;

      return vec4(color3 * color4.a, color4.a);
    }

    void main()
    {
      gl_FragColor = createDropShadowEx(openfl_TextureCoordv, 1.0 / openfl_TextureSize.xy, openfl_TextureSize.xy);
    }
  ')
  public function new()
  {
    super();

    angle = 0;
    angleOffset = 0;
    strength = 1;
    distance = 15;
    threshold = 0.1;

    baseHue = 0;
    baseSaturation = 0;
    baseBrightness = 0;
    baseContrast = 0;

    antialiasAmt = 2;
    useAltMask = false;
  }
}
