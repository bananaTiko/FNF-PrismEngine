package objects;

import flixel.system.FlxAssets.FlxSoundAsset;

/**
 * Small port of P-Slice's `mikolka.funkin.FunkinSound`, keeping only `load`.
 * P-Slice's version reuses its freeplay sound pooling which Prism doesn't have.
 */
class FunkinSound extends FlxSound
{
	/**
	 * Creates a sound synchronously.
	 * @param embeddedSound The sound asset
	 * @param volume Volume from 0 to 1
	 * @param looped Whether it loops
	 * @param autoDestroy Whether it gets destroyed after playing
	 * @param autoPlay Whether it starts playing right away
	 */
	public static function load(embeddedSound:FlxSoundAsset, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false, autoPlay:Bool = false,
			?onComplete:Void->Void, ?onLoad:Void->Void):Null<FunkinSound>
	{
		if (embeddedSound == null) return null;

		var sound:FunkinSound = new FunkinSound();
		sound.loadEmbedded(embeddedSound, looped, autoDestroy);
		sound.volume = volume;

		if (onComplete != null) sound.onComplete = onComplete;
		if (onLoad != null) onLoad(); // embedded sounds are already loaded

		FlxG.sound.list.add(sound);
		if (autoPlay) sound.play();

		return sound;
	}
}
