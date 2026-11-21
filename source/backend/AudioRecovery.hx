package backend;

import openfl.utils.AssetCache;
import openfl.utils.Assets;
import lime.media.AudioManager;
import flixel.FlxG;

/**
 * Drops and rebuilds the whole sound backend.
 *
 * Unplugging headphones or switching the default output device leaves OpenAL
 * playing into a device that no longer exists, and nothing tells the game about
 * it: the session stays silent until it is restarted. Windows has no event we
 * can listen to, so the cheapest reliable moment to look the default device up
 * again is a state change -- this is the fix Codename Engine ships ("auto fixes
 * audio on state change when you plug in/out your headphones").
 *
 * The order matters. Every FlxSound and every Sound cached by OpenFL is torn
 * down first, while its OpenAL source and buffer are still valid, because those
 * handles belong to the context that is about to be destroyed. Only then is the
 * device closed and reopened, so the next sound is decoded onto whatever device
 * the system now reports as the default.
 */
class AudioRecovery
{
	public static function reset():Void
	{
		#if (desktop || mobile)
		FlxG.sound.destroy(true);

		// flixel 5 has no FlxG.sound.resetCache(); the sound cache is OpenFL's, and
		// each cached Sound owns an OpenAL buffer belonging to the old context
		var cache:AssetCache = cast Assets.cache;
		if (cache != null && cache.sound != null)
		{
			for (sound in cache.sound)
			{
				if (sound != null) sound.close();
			}
			cache.sound.clear();
		}

		AudioManager.shutdown();
		AudioManager.init();
		#end
	}
}
