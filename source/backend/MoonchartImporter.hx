package backend;

import haxe.Json;
import moonchart.Moonchart;
import moonchart.backend.FormatData.PossibleValue;
import moonchart.backend.FormatDetector;
import moonchart.formats.BasicFormat.DynamicFormat;
import moonchart.formats.BasicFormat.FormatStringify;
import moonchart.formats.fnf.legacy.FNFPsych;

/**
 * Chart importing powered by moonchart (bananaTiko/moonchart-prism fork).
 *
 * Reads any format moonchart knows about (FNF Legacy/Psych/V-Slice/Kade/Codename/Imaginative,
 * osu!mania, Quaver, StepMania, Guitar Hero, MIDI...) and converts it into Prism Engine's
 * chart JSON, which the Chart Editor can load directly.
 */
class MoonchartImporter
{
	static var _initialized:Bool = false;

	public static function init():Void
	{
		if(_initialized) return;
		_initialized = true;
		Moonchart.init();
	}

	/**
	 * Name of the format moonchart detects for this file, or null if it can't tell.
	 */
	public static function getFormatName(path:String):Null<String>
	{
		if(path == null || path.length < 1) return null;
		init();

		try
		{
			var format = FormatDetector.findFormat(path);
			if(format == null) return null;
			return FormatDetector.getFormatData(format).name;
		}
		catch(e:Dynamic) {}

		return null;
	}

	/**
	 * Whether this chart needs a separate metadata file to be read (FNF V-Slice and friends).
	 */
	public static function needsMetadata(path:String):Bool
	{
		if(path == null || path.length < 1) return false;
		init();

		try
		{
			var format = FormatDetector.findFormat(path);
			if(format == null) return false;
			return FormatDetector.getFormatData(format).hasMetaFile == PossibleValue.TRUE;
		}
		catch(e:Dynamic) {}

		return false;
	}

	/**
	 * Converts any supported chart into a Psych Engine chart JSON string.
	 * @param path Chart file path
	 * @param metaPath Metadata file path, only needed for formats like FNF (V-Slice)
	 * @param difficulty Difficulty to convert, null lets moonchart pick one
	 * @return Converted chart JSON, or null if the file couldn't be read
	 */
	public static function convertToPsych(path:String, ?metaPath:String = null, ?difficulty:String = null):Null<String>
	{
		if(path == null || path.length < 1) return null;
		init();

		try
		{
			var converted:String = build(path, metaPath, difficulty);

			// A multi-difficulty file may not have the difficulty we asked for,
			// in that case let moonchart pick one on its own
			if(difficulty != null && !hasNotes(converted))
				converted = build(path, metaPath, null);

			return converted;
		}
		catch(e:Dynamic)
		{
			trace('Moonchart import failed for "$path": $e');
			return null;
		}
	}

	static function build(path:String, ?metaPath:String, ?difficulty:String):Null<String>
	{
		var detected:DynamicFormat = (metaPath != null && metaPath.length > 0)
			? FormatDetector.instanceFromFiles([path, metaPath], difficulty)
			: FormatDetector.instanceFromFiles(path, difficulty);

		if(detected == null) return null;

		var converted = new FNFPsych().fromFormat(detected, difficulty);
		if(converted == null) return null;

		var output:FormatStringify = converted.stringify();
		return (output != null) ? output.data : null;
	}

	/**
	 * Checks if a converted chart actually has notes, so we know the conversion worked.
	 */
	static function hasNotes(chartJson:String):Bool
	{
		if(chartJson == null || chartJson.length < 1) return false;

		try
		{
			var song:Dynamic = Json.parse(chartJson);
			if(Reflect.hasField(song, 'song')) song = Reflect.field(song, 'song');
			if(song == null || !Reflect.hasField(song, 'notes')) return false;

			for(section in (song.notes:Array<Dynamic>))
			{
				if(section == null || !Reflect.hasField(section, 'sectionNotes')) continue;
				var notes:Array<Dynamic> = Reflect.field(section, 'sectionNotes');
				if(notes != null && notes.length > 0) return true;
			}
		}
		catch(e:Dynamic) {}

		return false;
	}
}
