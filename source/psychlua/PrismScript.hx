package psychlua;

#if HSCRIPT_ALLOWED

/**
 * `.prism` scripts: the HScript language (Haxe syntax, real engine classes) with the Lua API
 * bolted on by PrismAPI, plus a small header for load order.
 *
 * Header, anywhere in the file:
 *   //@priority 10
 *   //@requires other.prism
 */
class PrismScript extends HScript
{
	public static inline var EXTENSION:String = '.prism';
	static inline var PRIORITY_TAG:String = '//@priority';
	static inline var REQUIRES_TAG:String = '//@requires';

	override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		super(parent, file, varsToBring, manualRun, readSource(file));
		loadHeader();
	}

	/** Reads the file (or the inline code) and hands back the Python-flavoured version. */
	static function readSource(file:String):String
	{
		if(file == null || file.length < 1) return null;

		#if sys
		if(!file.contains('\n') && FileSystem.exists(file))
			return PrismPreprocessor.process(File.getContent(file));
		#end

		return file.contains('\n') ? PrismPreprocessor.process(file) : null;
	}

	override function preset():Void
	{
		super.preset();
		PrismAPI.inject(this);
	}

	function loadHeader():Void
	{
		#if sys
		if(filePath == null || filePath.length < 1 || !FileSystem.exists(filePath)) return;

		for (line in File.getContent(filePath).split('\n'))
		{
			var trimmed:String = line.trim();
			if(trimmed.startsWith(PRIORITY_TAG))
				priority = Std.parseInt(trimmed.substr(PRIORITY_TAG.length).trim());
			else if(trimmed.startsWith(REQUIRES_TAG))
				for (required in trimmed.substr(REQUIRES_TAG.length).split(','))
				{
					var req:String = required.trim();
					if(req.length > 0) requires.push(req);
				}
		}
		#end
	}
}
#end
