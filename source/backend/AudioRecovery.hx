package backend;

import openfl.utils.AssetCache;
import openfl.utils.Assets;
import lime.media.AudioManager;
#if lime_openal
import lime.media.openal.ALC;
#end
import flixel.FlxG;

/**
 * Rebuilds the sound backend when the default output device changes.
 *
 * Unplugging headphones or switching the default output device leaves OpenAL
 * playing into a device that no longer exists, and nothing tells the game about
 * it: the session stays silent until it is restarted. Windows has no event we
 * can listen to, so the cheapest reliable moment to look the default device up
 * again is a state change.
 *
 * Only a changed device is rebuilt. Doing it on every state change tore down
 * every sound each time, which restarted the menu track from the beginning
 * whenever a menu was opened.
 *
 * The order matters. Every FlxSound and every Sound cached by OpenFL is torn
 * down first, while its OpenAL source and buffer are still valid, because those
 * handles belong to the context that is about to be destroyed. Only then is the
 * device closed and reopened, so the next sound is decoded onto whatever device
 * the system now reports as the default.
 */
class AudioRecovery
{
	static var knownDevice:String = null;

	/** Name of the system's default output device, or null where it cannot be read. */
	public static function currentDevice():String
	{
		#if (lime_openal && !macro)
		var name:String = ALC.getString(null, ALC.DEFAULT_ALL_DEVICES_SPECIFIER);

		// OpenAL only answers the _ALL_ query when its enumerator extension is
		// present; the plain specifier is what every other implementation has.
		if (name == null || name.length < 1)
			name = ALC.getString(null, ALC.DEFAULT_DEVICE_SPECIFIER);

		if (name != null && name.length > 0)
			return name;
		#end

		return null;
	}

	/**
	 * Rebuilds the backend if the default output device changed since the last
	 * check. Returns whether it rebuilt, because that kills the current music.
	 *
	 * When the platform cannot report a device name nothing is rebuilt: silence
	 * after a device change is better than losing the music on every state change.
	 */
	public static function checkDevice():Bool
	{
		var device:String = currentDevice();
		if (device == null)
			return false;

		if (knownDevice == null)
		{
			// first state after launch: the backend was initialised by OpenFL already
			knownDevice = device;
			return false;
		}

		if (device == knownDevice)
			return false;

		knownDevice = device;
		reset();
		return true;
	}

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
