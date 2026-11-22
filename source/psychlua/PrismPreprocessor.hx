package psychlua;

using StringTools;

/**
 * A small source-to-source pass that gives `.prism` a Python/Lua flavour on top of HScript:
 *
 *   # comment            -> // comment     (Haxe's #if/#elseif/#else/#end are left alone)
 *   local name = value   -> var name = value
 *   nil                  -> null
 *   elif                 -> else if
 *
 * The rewrite is token based: text inside string literals and existing `//` comments is never
 * touched, so colours like '#FF0000' or the word "nil" inside a string stay as written.
 */
class PrismPreprocessor
{
	static var DIRECTIVES:Array<String> = ['#if', '#elseif', '#else', '#end'];

	public static function process(code:String):String
	{
		if(code == null || code.length < 1) return code;

		var lines:Array<String> = code.split('\n');
		for (i in 0...lines.length)
			lines[i] = processLine(lines[i]);
		return lines.join('\n');
	}

	static function processLine(line:String):String
	{
		var trimmed:String = StringTools.ltrim(line);
		if(isDirective(trimmed)) return line;

		var indent:String = line.substr(0, line.length - trimmed.length);
		if(trimmed.startsWith('local ')) trimmed = 'var ' + trimmed.substr('local '.length);

		return indent + rewriteTokens(trimmed);
	}

	/** Walks the line once, skipping strings and any comment that is already there. */
	static function rewriteTokens(text:String):String
	{
		var out:String = '';
		var quote:String = null;
		var i:Int = 0;

		while(i < text.length)
		{
			var c:String = text.charAt(i);

			if(quote != null)
			{
				out += c;
				if(c == '\\' && i + 1 < text.length)
				{
					out += text.charAt(i + 1);
					i += 2;
					continue;
				}
				if(c == quote) quote = null;
				i++;
				continue;
			}

			if(c == '"' || c == "'")
			{
				quote = c;
				out += c;
				i++;
				continue;
			}

			if(c == '#') return out + '//' + text.substr(i + 1);
			if(c == '/' && i + 1 < text.length && text.charAt(i + 1) == '/') return out + text.substr(i);

			if(isIdentStart(c) && (i == 0 || !isIdentChar(text.charAt(i - 1))))
			{
				var end:Int = i;
				while(end < text.length && isIdentChar(text.charAt(end))) end++;

				var word:String = text.substring(i, end);
				if(word == 'nil') out += 'null';
				else if(word == 'elif') out += 'else if';
				else out += word;

				i = end;
				continue;
			}

			out += c;
			i++;
		}
		return out;
	}

	static function isDirective(trimmed:String):Bool
	{
		for (directive in DIRECTIVES)
			if(trimmed.startsWith(directive) &&
				(trimmed.length == directive.length || !isIdentChar(trimmed.charAt(directive.length))))
				return true;
		return false;
	}

	static inline function isIdentStart(c:String):Bool
		return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';

	static inline function isIdentChar(c:String):Bool
		return isIdentStart(c) || (c >= '0' && c <= '9');
}
