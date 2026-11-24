package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;

/**
 * A screenspace version of DropShadowShader: the only way to use the rim light on FlxAnimate
 * sprites, since those render through their own texture.
 *
 * It shares the base class' properties and Adjust Color maths, but samples the texture by the
 * sprite's own UVs and scales the shadow distance by the camera zoom, because the render texture
 * is screen sized rather than the sprite's sheet.
 */
class DropShadowScreenspace extends DropShadowShader
{
  /*
    The current zoom of the camera. Needed to figure out how much to multiply the shadow size by.
   */
  public var curZoom(default, set):Float;

  function set_curZoom(val:Float):Float
  {
    curZoom = val;
    zoom.value = [val];
    return val;
  }

  // The render texture covers the whole sprite, so there are no frame bounds to clamp to.
  override public function updateFrameInfo(frame:FlxFrame):Void
  {
    angleOffset = frame.angle;
  }

  @:glFragmentSource('
      #pragma header

      // this is the same rim light as DropShadowShader, sampling a screenspace texture

      #ifdef GL_ES
      #ifdef GL_OES_standard_derivatives
      #define HAS_DERIVATIVES
      #endif
      #else
      #if __VERSION__ >= 130
      #define HAS_DERIVATIVES
      #endif
      #endif

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

      uniform float zoom;

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

      vec4 createDropShadowEx(vec2 uv, vec2 ratio)
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
        float intensity = smoothstep(threshold - delta, threshold + delta, color3_light);

        vec3 color3_no_effect = color4.a > 0.0 ? color4.rgb / color4.a : color4.rgb;
        vec3 color3 = applyHSBCEffect(color3_no_effect);

        // the render texture is screen sized, so the distance has to follow the camera zoom
        vec2 checked = vec2(
          uv.x + ((dist * zoom) * angCos * ratio.x),
          uv.y - ((dist * zoom) * angSin * ratio.y)
        );

        float shadowAlpha = texture2D(bitmap, checked).a;
        float rim = (1.0 - (shadowAlpha * str)) * intensity;
        color3 += dropColor * rim;

        return vec4(color3 * color4.a, color4.a);
      }

      void main()
      {
        gl_FragColor = createDropShadowEx(openfl_TextureCoordv, 1.0 / openfl_TextureSize.xy);
      }
    ')
  override public function new()
  {
    super();

    angle = 90;
    strength = 1;
    distance = 15;
    threshold = 0.1;

    baseHue = 0;
    baseSaturation = 0;
    baseBrightness = 0;
    baseContrast = 0;

    useAltMask = false;

    color = 0xFFDFEF3C;

    antialiasAmt = 2;
    curZoom = 1;
  }
}
