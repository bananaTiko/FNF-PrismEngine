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
 * again is a state change -- this is the fix Codename Engine ships.
 *
 * Only a changed device is rebuilt. Rebuilding on every state change tore down
 * every sound each time, which restarted the menu track from the beginning
 * whenever a menu was opened.
 */
class AudioRecovery
{
	/** Default output device as last seen, or null before the first check. */
	static var knownDevice:String = null;

	/** Rebuilds the backend if the default output device changed since the last check. */
	public static function checkDevice():Bool
	{
		var device:String = currentDevice();
		if (device == null)
			return false; // the platform cannot tell us; leave audio alone

		var changed:Bool = knownDevice != null && device != knownDevice;
		knownDevice = device;
		if (!changed)
			return false;

		reset();

		// reopening the device can make OpenAL report it differently (OpenAL Soft
		// falls back to a generic name when the device is gone), so the baseline is
		// what it reports now, not what it reported before the rebuild
		var reopened:String = currentDevice();
		if (reopened != null)
			knownDevice = reopened;

		return true;
	}

	/** Name of the system's default output device, or null where it cannot be read. */
	static function currentDevice():String
	{
		#if (lime_openal && !macro)
		// the _ALL_ query is the one that carries the friendly device name, but it
		// only answers when OpenAL has its device enumerator extension
		var name:String = ALC.getString(null, ALC.DEFAULT_ALL_DEVICES_SPECIFIER);
		if (name == null || name.length < 1)
			name = ALC.getString(null, ALC.DEFAULT_DEVICE_SPECIFIER);

		if (name != null && name.length > 0)
			return name;
		#end

		return null;
	}

	/**
	 * Drops and rebuilds the whole sound backend.
	 *
	 * The order matters. Every FlxSound and every Sound cached by OpenFL is torn
	 * down first, while its OpenAL source and buffer are still valid, because those
	 * handles belong to the context that is about to be destroyed. Only then is the
	 * device closed and reopened, so the next sound is decoded onto whatever device
	 * the system now reports as the default.
	 */
	static function reset():Void
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
