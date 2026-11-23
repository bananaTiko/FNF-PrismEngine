package objects;

import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import openfl.utils.Assets;

import backend.ClientPrefs;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef SubtitleEntry = {
	var start:Float;
	var end:Float;
	var text:String;
}

/**
 * In-game subtitles, drawn on the HUD.
 * Subtitle cues are read from standard `.srt` files, the same format Funkin' uses
 * (`data/songs/<song>/subtitles/song-lyrics.srt`). Files are resolved through
 * `Language.getFileTranslation()`, so a locale can ship its own translated `.srt`.
 */
class Subtitles extends FlxSpriteGroup
{
	public var offsets:Array<Float> = [0, 0];

	public var alignment(default, set):String = 'bottom';

	var subtitleText:FlxText;
	var background:FlxSprite;
	var subtitlesData:Array<SubtitleEntry> = [];
	var assignedSound:FlxSound = null;

	public function new(x:Float = 0, y:Float = 0, ?alignment:String = 'bottom')
	{
		super(0, 0);

		offsets = [x, y];

		background = new FlxSprite();
		background.makeGraphic(1, 1, FlxColor.BLACK);
		background.alpha = 0.55;
		background.visible = false;
		add(background);

		subtitleText = new FlxText(0, 0, Std.int(FlxG.width - 200), '', 32);
		subtitleText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		subtitleText.visible = false;
		add(subtitleText);

		this.alignment = alignment;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if(assignedSound == null || subtitlesData.length < 1) return;

		//Cue times come out of the .srt in seconds, while FlxSound.time is in milliseconds
		var currentTime:Float = assignedSound.time * 0.001;

		var currentLines:Array<String> = [];
		for(data in subtitlesData)
		{
			if(currentTime >= data.start && currentTime <= data.end)
				currentLines.push(data.text);
		}

		if(currentLines.length > 0)
			setText(currentLines.join('\n'));
		else
			setText('');
	}

	/**
	 * Loads an `.srt` file and syncs it to `sound`.
	 * `filePath` is relative to the `data/` folder, e.g. `songs/monster/subtitles/song-lyrics`.
	 */
	public function assignSubtitles(filePath:String, ?sound:FlxSound):Void
	{
		clearSubtitles();

		if(sound == null) return;
		if(filePath == null || filePath.length < 1) return;

		var raw:String = null;
		for (candidate in candidatePaths(filePath))
		{
			raw = readText(Paths.srt(candidate));
			if(raw != null && raw.length > 0) break;
		}

		if(raw == null || raw.length < 1)
		{
			FlxG.log.warn('No subtitle file for $filePath');
			return;
		}

		subtitlesData = parseSRT(raw);
		if(subtitlesData.length < 1) return;

		assignedSound = sound;
	}

	/**
	 * `.srt` files ship per locale (`song-lyrics-fr-CA.srt`) next to the plain one, so a
	 * translated cue list is used when the game language has one.
	 */
	static function candidatePaths(filePath:String):Array<String>
	{
		var paths:Array<String> = [];
		var lang:String = (ClientPrefs.data != null) ? ClientPrefs.data.language : null;
		if(lang != null && lang.length > 1 && lang != 'en-US')
		{
			paths.push('$filePath-$lang');
			var dash:Int = lang.indexOf('-');
			if(dash > 0) paths.push('$filePath-' + lang.substr(0, dash));
		}
		paths.push(filePath);
		return paths;
	}

	/**
	 * Reads a text file whether it was embedded as an asset or just copied next to the
	 * executable. Most songs have no subtitle file at all, and lime treats an unknown asset
	 * id as a hard error rather than "not found", so every asset call here is guarded.
	 */
	static function readText(path:String):String
	{
		if(path == null || path.length < 1) return null;

		#if sys
		if(FileSystem.exists(path)) return File.getContent(path);
		#end

		var known:Bool = false;
		try { known = Assets.exists(path); } catch(e:Dynamic) {}
		if(!known) return null;

		#if sys
		//Let the asset system resolve the game folder, which is not always the working directory
		try
		{
			var resolved:String = Assets.getPath(path);
			if(resolved != null && resolved != path && FileSystem.exists(resolved)) return File.getContent(resolved);
		}
		catch(e:Dynamic) {}
		#end

		try
		{
			return Assets.getText(path);
		}
		catch(e:Dynamic) {}

		//Binary-typed assets still carry their bytes, so decode those as text
		try
		{
			return Assets.getBytes(path).toString();
		}
		catch(e:Dynamic) {}

		return null;
	}

	/** Drops the current cue list. Named apart from `FlxSpriteGroup.clear()`, which destroys members. */
	public function clearSubtitles():Void
	{
		assignedSound = null;
		subtitlesData = [];
		setText('');
	}

	function setText(targetText:String):Void
	{
		if(targetText == null || targetText.length < 1)
		{
			if(subtitleText.text != '')
			{
				subtitleText.text = '';
				subtitleText.visible = false;
				background.visible = false;
			}
			return;
		}

		if(subtitleText.text == targetText)
		{
			subtitleText.visible = true;
			background.visible = true;
			return;
		}

		subtitleText.text = targetText;
		subtitleText.visible = true;

		background.makeGraphic(Std.int(inkWidth()) + 40, Std.int(inkHeight()) + 12, FlxColor.BLACK);
		background.alpha = 0.55;
		background.visible = true;

		updatePosition();
	}

	//Width of the actual text, not of its (full screen) field
	inline function inkWidth():Float
		return (subtitleText.textField.textWidth > 0) ? subtitleText.textField.textWidth : subtitleText.width;

	inline function inkHeight():Float
		return (subtitleText.textField.textHeight > 0) ? subtitleText.textField.textHeight : subtitleText.height;

	function updatePosition():Void
	{
		var textY:Float = (alignment == 'top') ? (10 + offsets[1]) : (FlxG.height - inkHeight() - 24 - offsets[1]);

		//The field is centered and the text is centered inside it, so the ink is centered too
		subtitleText.setPosition((FlxG.width - subtitleText.width) * 0.5, textY);
		background.setPosition((FlxG.width - inkWidth()) * 0.5 + offsets[0] - 20, textY - 6);
	}

	function set_alignment(value:String):String
	{
		alignment = value;
		updatePosition();
		return alignment;
	}

	/**
	 * Parses the contents of an `.srt` file into subtitle entries.
	 */
	public static function parseSRT(raw:String):Array<SubtitleEntry>
	{
		var entries:Array<SubtitleEntry> = [];
		if(raw == null) return entries;

		if(raw.length > 0 && raw.charCodeAt(0) == 0xFEFF) //UTF-8 BOM
			raw = raw.substr(1);

		raw = StringTools.replace(raw, '\r\n', '\n');
		raw = StringTools.replace(raw, '\r', '\n');

		var blocks:Array<String> = raw.split('\n\n');
		for(block in blocks)
		{
			var timeLine:String = null;
			var textLines:Array<String> = [];

			for(line in block.split('\n'))
			{
				var trimmed:String = line.trim();
				if(trimmed.length < 1) continue;

				if(timeLine == null && trimmed.indexOf('-->') > -1)
					timeLine = trimmed;
				else if(timeLine != null)
					textLines.push(trimmed);
			}

			if(timeLine == null || textLines.length < 1) continue;

			var times:Array<String> = timeLine.split('-->');
			if(times.length < 2) continue;

			var start:Float = parseSRTTime(times[0]);
			var end:Float = parseSRTTime(times[1]);
			if(end <= start) continue;

			entries.push({
				start: start,
				end: end,
				text: textLines.join('\n')
			});
		}

		return entries;
	}

	static function parseSRTTime(time:String):Float
	{
		var clean:String = StringTools.replace(time.trim(), ',', '.');
		var parts:Array<String> = clean.split(':');
		if(parts.length < 3) return 0;

		var hours:Float = Std.parseFloat(parts[0]);
		var minutes:Float = Std.parseFloat(parts[1]);
		var seconds:Float = Std.parseFloat(parts[2]);
		if(Math.isNaN(hours)) hours = 0;
		if(Math.isNaN(minutes)) minutes = 0;
		if(Math.isNaN(seconds)) seconds = 0;

		return (hours * 3600) + (minutes * 60) + seconds;
	}
}
