package backend;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import openfl.events.Event;
import openfl.media.Sound;
#if desktop
import haxe.io.Bytes;
import hxflac.openfl.FLACStreamedSound;
import sys.io.File;
#end

/**
 * A `FlxSound` that decodes a FLAC file while it plays instead of unpacking the
 * whole thing into memory first (`Paths.loadSoundFile` does that, which is fine
 * for short effects but costs tens of MB for a song's instrumental and vocals).
 *
 * Anything that is not FLAC keeps the plain FlxSound path: Lime already streams
 * OGG/WAV from disk on its own.
 */
class StreamedSound extends FlxSound
{
	static final CHUNK_SIZE:Int = 65536;

	/** Seeks shorter than this are skipped: every seek reopens the stream from the start. */
	static final SEEK_TOLERANCE:Float = 50;

	#if desktop
	var _stream:FLACStreamedSound;
	var _streamBytes:Bytes;
	/** Position the stream was left at when paused, or -1. Resuming there needs no seek. */
	var _continueTime:Float = -1;
	#end

	private function new(file:String, looped:Bool = false)
	{
		super();

		#if desktop
		_streamBytes = File.getBytes(file);
		_stream = new FLACStreamedSound(_streamBytes, CHUNK_SIZE);

		_sound = null;
		this.looped = looped;
		exists = true;
		_length = durationOf(_streamBytes);
		endTime = _length;
		updateTransform();
		#end
	}

	/** Streamed sound for a supported FLAC file, or null when it should use the decoded path. */
	public static function create(file:String, looped:Bool = false):StreamedSound
		return Paths.isFlac(file) ? new StreamedSound(file, looped) : null;

	/** The song's instrumental, streamed when it is a FLAC file. */
	public static function instTrack(song:String):FlxSound
	{
		var streamed:StreamedSound = create(Paths.instPath(song));
		return streamed != null ? streamed : new FlxSound().loadEmbedded(Paths.inst(song));
	}

	/**
	 * A vocal track, streamed when it is a FLAC file. `postfix` picks the character
	 * specific file; `fallbackToDefault` also tries the plain `Voices` file.
	 * Returns null when neither exists.
	 */
	public static function vocalTrack(song:String, ?postfix:String, fallbackToDefault:Bool = false):FlxSound
	{
		var file:String = Paths.voicesPath(song, postfix);
		if(file == null && fallbackToDefault) file = Paths.voicesPath(song);
		if(file == null) return null;

		var streamed:StreamedSound = create(file);
		if(streamed != null) return streamed;

		var sound:Sound = Paths.voices(song, postfix);
		if(sound == null && fallbackToDefault) sound = Paths.voices(song);
		if(sound == null) return null;
		return new FlxSound().loadEmbedded(sound);
	}

	/** Frees the FLAC handle and its bytes without destroying the FlxSound itself. */
	public function releaseStream():Void
	{
		#if desktop closeStream(); #end
	}

	/** Makes this the current `FlxG.sound.music`, the way `FlxG.sound.playMusic` would. */
	public function playAsMusic(volume:Float = 1, looped:Bool = false):StreamedSound
	{
		if(FlxG.sound.music != null && FlxG.sound.music != this)
		{
			var previous:FlxSound = FlxG.sound.music;
			previous.stop();
			if(previous is StreamedSound) (cast previous : StreamedSound).releaseStream();
		}

		FlxG.sound.music = this;
		this.volume = volume;
		this.looped = looped;
		play();
		return this;
	}

	// ---- FlxSound hooks: streamed while we hold a stream, plain otherwise --------

	override function startSound(StartTime:Float):Void
	{
		#if desktop
		if(_stream != null)
		{
			startStream(StartTime);
			return;
		}
		#end
		super.startSound(StartTime);
	}

	override function cleanup(destroySound:Bool, resetPosition:Bool = true):Void
	{
		#if desktop
		if(_stream != null)
		{
			stopChannel();
			if(destroySound)
			{
				closeStream();
				exists = false;
			}
			if(resetPosition)
			{
				_time = 0;
				_paused = false;
			}
			return;
		}
		#end
		super.cleanup(destroySound, resetPosition);
	}

	override public function pause():FlxSound
	{
		#if desktop
		if(_stream != null)
		{
			if(_channel == null) return this;

			_time = _stream.playbackTime * 1000;
			_continueTime = _time;
			_paused = true;
			stopChannel();
			return this;
		}
		#end
		return super.pause();
	}

	override function set_time(value:Float):Float
	{
		#if desktop
		if(_stream != null)
		{
			value = Math.max(0, value);
			if(_channel != null)
			{
				var current:Float = _stream.playbackTime * 1000;
				if(Math.abs(value - current) < SEEK_TOLERANCE)
				{
					_time = value;
					return value;
				}
			}
			else if(_paused && Math.abs(value - _time) < SEEK_TOLERANCE)
			{
				// Still asking for the spot we paused on: keep it, so resuming does not seek.
				_time = value;
				return value;
			}
			_continueTime = -1;
		}
		#end
		return super.set_time(value);
	}

	override public function update(elapsed:Float):Void
	{
		#if desktop
		if(_stream != null)
		{
			if(_channel == null || _paused) return;

			_time = _stream.playbackTime * 1000;
			updateTransform();
			if(endTime != null && _time >= endTime) stopped();
			return;
		}
		#end
		super.update(elapsed);
	}

	override function updateTransform():Void
	{
		super.updateTransform();
		#if desktop
		if(_stream != null) _stream.volume = _transform.volume;
		#end
	}

	override public function loadEmbedded(EmbeddedSound:FlxSoundAsset, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound
	{
		#if desktop
		// FlxG.sound.playMusic() reuses the current music instance for the next track:
		// drop the stream and behave like a normal FlxSound from here on.
		if(_stream != null) closeStream();
		#end
		return super.loadEmbedded(EmbeddedSound, Looped, AutoDestroy, OnComplete);
	}

	override public function destroy():Void
	{
		#if desktop closeStream(); #end
		super.destroy();
	}

	#if desktop
	function startStream(startTime:Float):Void
	{
		stopChannel();

		// Unpausing right where the stream stopped: it still holds that position, so
		// keep decoding from there instead of walking the file from the start again.
		var resuming:Bool = _continueTime >= 0 && Math.abs(startTime - _continueTime) < SEEK_TOLERANCE;
		_continueTime = -1;

		_time = startTime;
		_paused = false;
		if(!resuming) _stream.seekMilliseconds(startTime);
		_channel = _stream.play(0, 0, _transform);
		if(_channel != null)
		{
			_channel.addEventListener(Event.SOUND_COMPLETE, stopped);
			active = true;
			updateTransform();
		}
		else
		{
			exists = false;
			active = false;
		}
	}

	function stopChannel():Void
	{
		if(_channel != null)
		{
			_channel.removeEventListener(Event.SOUND_COMPLETE, stopped);
			_channel.stop();
			_channel = null;
		}
		active = false;
	}

	function closeStream():Void
	{
		stopChannel();
		_continueTime = -1;
		if(_stream != null)
		{
			_stream.close();
			_stream = null;
		}
		_streamBytes = null;
	}

	/**
	 * Length in milliseconds, read from STREAMINFO (the first FLAC metadata block).
	 * A streamed Sound has no decoded buffer, so `Sound.length` reports 0.
	 */
	static function durationOf(bytes:Bytes):Float
	{
		if(bytes.length < 42 || bytes.getString(0, 4) != 'fLaC') return 0;

		var p:Int = 8; // "fLaC" + the STREAMINFO block header
		var sampleRate:Int = (bytes.get(p + 10) << 12) | (bytes.get(p + 11) << 4) | (bytes.get(p + 12) >> 4);
		var totalSamples:Float = (bytes.get(p + 13) & 0x0F) * 4294967296.0
			+ bytes.get(p + 14) * 16777216.0
			+ bytes.get(p + 15) * 65536.0
			+ bytes.get(p + 16) * 256.0
			+ bytes.get(p + 17);

		if(sampleRate <= 0 || totalSamples <= 0) return 0;
		return totalSamples / sampleRate * 1000;
	}
	#end
}
