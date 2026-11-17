package shaders;

import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;

/**
 * Rain overlay for the Philly stages: displaced screen sampling plus procedural streaks.
 * Used as a camera filter (PhillyStreets, PhillyBlazin, PhillyStreetsErect) and, with
 * `spriteMode` on, as a sprite shader that keeps the sprite's own transparency
 * (SpookyMansionErect's window).
 */
class RainShader extends FlxShader
{
	@:glVertexHeader('
		  // normalized screen coord
		  //   (0, 0) is the top left of the window
		  //   (1, 1) is the bottom right of the window
		  varying vec2 screenCoord;
	  ', true)
	@:glVertexBody('
		  screenCoord = vec2(
			  openfl_TextureCoord.x > 0.0 ? 1.0 : 0.0,
			  openfl_TextureCoord.y > 0.0 ? 1.0 : 0.0
		  );
	  ')
	@:glFragmentHeader('
	// normalized screen coord
	//   (0, 0) is the top left of the window
	//   (1, 1) is the bottom right of the window
	varying vec2 screenCoord;

	// equals (camera.viewLeft, camera.viewTop, camera.viewRight, camera.viewBottom)
	uniform vec4 uCameraBounds;

	// equals (frame.uv.x, frame.uv.y, frame.uv.width, frame.uv.height)
	uniform vec4 uFrameBounds;

	// screen coord -> world coord conversion
	// returns world coord in px
	vec2 screenToWorld(vec2 screenCoord) {
		float left = uCameraBounds.x;
		float top = uCameraBounds.y;
		float right = uCameraBounds.z;
		float bottom = uCameraBounds.w;
		vec2 scale = vec2(right - left, bottom - top);
		vec2 offset = vec2(left, top);
		return screenCoord * scale + offset;
	}

	// world coord -> screen coord conversion
	// returns normalized screen coord
	vec2 worldToScreen(vec2 worldCoord) {
		float left = uCameraBounds.x;
		float top = uCameraBounds.y;
		float right = uCameraBounds.z;
		float bottom = uCameraBounds.w;
		vec2 scale = vec2(right - left, bottom - top);
		vec2 offset = vec2(left, top);
		return (worldCoord - offset) / scale;
	}

	// screen coord -> frame coord conversion
	// returns normalized frame coord
	vec2 screenToFrame(vec2 screenCoord) {
		float left = uFrameBounds.x;
		float top = uFrameBounds.y;
		float right = uFrameBounds.z;
		float bottom = uFrameBounds.w;
		float width = right - left;
		float height = bottom - top;

		float clampedX = clamp(screenCoord.x, left, right);
		float clampedY = clamp(screenCoord.y, top, bottom);

		return vec2(
			(clampedX - left) / (width),
			(clampedY - top) / (height)
		);
	}

	// internally used to get the maximum `openfl_TextureCoordv`
	vec2 bitmapCoordScale() {
		return openfl_TextureCoordv / screenCoord;
	}

	// internally used to compute bitmap coord
	vec2 screenToBitmap(vec2 screenCoord) {
		return screenCoord * bitmapCoordScale();
	}

	// samples the frame buffer using a screen coord
	vec4 sampleBitmapScreen(vec2 screenCoord) {
		return texture2D(bitmap, screenToBitmap(screenCoord));
	}

	// samples the frame buffer using a world coord
	vec4 sampleBitmapWorld(vec2 worldCoord) {
		return sampleBitmapScreen(worldToScreen(worldCoord));
	}
	  ', true)

	@:glFragmentSource("
	#pragma header

	uniform float uScale;
	uniform float uIntensity;
	uniform float uTime;
	uniform bool uSpriteMode;
	uniform vec3 uRainColor;

	float rand(vec2 a) {
		return fract(sin(dot(mod(a, vec2(1000.0)).xy, vec2(12.9898, 78.233))) * 43758.5453);
	}

	float rainDist(vec2 p, float scale, float intensity) {
		// scale everything
		p *= 0.1;
		// sheer
		p.x += p.y * 0.1;
		// scroll
		p.y -= uTime * 500.0 / scale;
		// expand Y
		p.y *= 0.03;
		float ix = floor(p.x);
		// shift Y
		p.y += mod(ix, 2.0) * 0.5 + (rand(vec2(ix)) - 0.5) * 0.3;
		float iy = floor(p.y);
		vec2 index = vec2(ix, iy);
		// mod
		p -= index;
		// shift X
		p.x += (rand(index.yx) * 2.0 - 1.0) * 0.35;
		// distance
		vec2 a = abs(p - 0.5);
		float res = max(a.x * 0.8, a.y * 0.5) - 0.1;
		// decimate
		bool empty = rand(index) < mix(1.0, 0.1, intensity);
		return empty ? 1.0 : res;
	}

	void main() {
		vec2 wpos = screenToWorld(screenCoord);
		if (uSpriteMode) wpos = screenToWorld(screenToFrame(openfl_TextureCoordv));
		vec2 origWpos = wpos;
		float intensity = uIntensity;

		vec3 add = vec3(0);
		float rainSum = 0.0;

		const int numLayers = 4;
		float scales[4];
		scales[0] = 1.0;
		scales[1] = 1.8;
		scales[2] = 2.6;
		scales[3] = 4.8;

		for (int i = 0; i < numLayers; i++) {
			float scale = scales[i];
			float r = rainDist(wpos * scale / uScale + 500.0 * float(i), scale, intensity);
			if (r < 0.0) {
				float v = (1.0 - exp(r * 5.0)) / scale * 2.0;
				wpos.x += v * 10.0 * uScale;
				wpos.y -= v * 2.0 * uScale;
				add += vec3(0.1, 0.15, 0.2) * v;
				rainSum += (1.0 - rainSum) * 0.75;
			}
		}

		vec3 color = sampleBitmapWorld(wpos).xyz;
		// camera filters are opaque, only sprite mode carries the texture's own alpha
		float alpha = 1.0;
		if (uSpriteMode) {
			vec2 rwpos = worldToScreen(wpos - origWpos);
			color = flixel_texture2D(bitmap, openfl_TextureCoordv + rwpos).xyz;
			alpha = flixel_texture2D(bitmap, openfl_TextureCoordv + rwpos).w;
		}

		color += add;
		color = mix(color, uRainColor, 0.1 * rainSum);

		gl_FragColor = vec4(color, alpha);
	}
		")

	public var time(default, set):Float = 1;

	function set_time(value:Float):Float
	{
		this.uTime.value[0] = value;
		return time = value;
	}

	// The scale of the rain depends on the world coordinate system, so higher resolution makes
	// the raindrops smaller. This parameter can be used to adjust the total scale of the scene.
	// The size of the raindrops is proportional to the value of this parameter.
	public var scale(default, set):Float = 1;

	function set_scale(value:Float):Float
	{
		this.uScale.value[0] = value;
		return scale = value;
	}

	// When on, the shader samples the sprite's own frame instead of the screen, keeping its alpha.
	public var spriteMode(default, set):Bool = false;

	function set_spriteMode(value:Bool):Bool
	{
		this.uSpriteMode.value[0] = value;
		return spriteMode = value;
	}

	// The intensity of the rain. Zero means no rain and one means the maximum amount of rain.
	public var intensity(default, set):Float = 0.5;

	function set_intensity(value:Float):Float
	{
		this.uIntensity.value[0] = value;
		return intensity = value;
	}

	// Tint the streaks are mixed towards, defaulting to the colour the shader used to hardcode.
	public var rainColor(default, set):FlxColor = 0xFF6680cc;

	function set_rainColor(color:FlxColor):FlxColor
	{
		this.uRainColor.value = [color.red / 255, color.green / 255, color.blue / 255];
		return rainColor = color;
	}

	public function new()
	{
		super();
		this.uTime.value = [1.0];
		this.uScale.value = [1.0];
		this.uSpriteMode.value = [false];
		this.uIntensity.value = [0.5];
		uCameraBounds.value = [0, 0, FlxG.width, FlxG.height];
		uFrameBounds.value = [0, 0, FlxG.width, FlxG.height];

		this.rainColor = 0xFF6680cc;
	}

	public function update(elapsed:Float):Void
	{
		time += elapsed;
	}

	public function updateViewInfo(screenWidth:Float, screenHeight:Float, camera:FlxCamera):Void
	{
		uCameraBounds.value = [camera.viewLeft, camera.viewTop, camera.viewRight, camera.viewBottom];
	}

	public function updateFrameInfo(frame:FlxFrame)
	{
		// NOTE: uv.width is actually the right pos and uv.height is the bottom pos
		uFrameBounds.value = [frame.uv.x, frame.uv.y, frame.uv.width, frame.uv.height];
	}
}
