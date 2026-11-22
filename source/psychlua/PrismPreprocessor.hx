package psychlua;

/**
 * Source handling for `.prism`, the Python/Lua-flavoured HScript dialect:
 *
 *   # comment            -> // comment     (Haxe's #if/#elseif/#else/#end are left alone)
 *   local name = value   -> var name = value
 *   nil                  -> null
 *   elif                 -> else if
 *   def name(...)        -> function name(...)
 *   True / False / None  -> true / false / null
 *   and / or / not       -> && / || / !
 *   value is None        -> value == null    (is not None -> != null)
 *
 * The rewrite is token based: text inside string literals and existing `//` comments is never
 * touched, so colours like '#FF0000' or the word "nil" inside a string stay as written. A token
 * after a dot is a member name rather than a keyword, so it is left alone and reported by
 * `warnings()` instead of being rewritten into something that cannot parse.
 *
 * This class is the only entry point, and it owns the choice of implementation. The `haxe*`
 * functions are the portable version; on cpp targets the same work is done by PrismNative. Both
 * walk UTF-8 bytes rather than Haxe String code units, which keeps them byte-for-byte identical
 * even for text outside the BMP (an emoji in a comment, say), where code-unit walking would split
 * a surrogate pair.
 */
class PrismPreprocessor
{
	static inline var NEWLINE:Int = 10;
	static inline var SPACE:Int = 32;
	static inline var TAB:Int = 9;
	static inline var HASH:Int = 35;
	static inline var SLASH:Int = 47;
	static inline var BACKSLASH:Int = 92;
	static inline var ASTERISK:Int = 42;
	static inline var DOT:Int = 46;
	static inline var DOUBLE_QUOTE:Int = 34;
	static inline var SINGLE_QUOTE:Int = 39;

	static var DIRECTIVES:Array<String> = ['#if', '#elseif', '#else', '#end'];

	/** Simple token rewrites. `is None` needs lookahead, so it is handled separately. */
	static var TOKENS:Map<String, String> = [
		'nil' => 'null',
		'elif' => 'else if',
		'def' => 'function',
		'True' => 'true',
		'False' => 'false',
		'None' => 'null',
		'and' => '&&',
		'or' => '||',
		'not' => '!'
	];

	/** Every token above plus `is`, for the member-name warning. */
	static var TOKEN_NAMES:Array<String> = ['def', 'True', 'False', 'None', 'and', 'or', 'not', 'is'];

	/** Rewrites `.prism` source into Haxe source. */
	public static function process(code:String):String
	{
		if(code == null) return null;

		#if cpp
		return PrismNative.transform(code);
		#else
		return processHaxe(code);
		#end
	}

	/** 53-bit content hash, cheap enough to tell whether a cached file is still current. */
	public static function hash(code:String):Float
	{
		if(code == null) return 0;

		#if cpp
		return PrismNative.hash(code);
		#else
		return haxeHash(code);
		#end
	}

	/** Empty when the source looks balanced, otherwise a message with a line number. */
	public static function validate(code:String):String
	{
		if(code == null) return '';

		#if cpp
		return PrismNative.validate(code);
		#else
		return haxeValidate(code);
		#end
	}

	/** Portable version of the rewrite. Walks UTF-8 bytes, one line at a time. */
	public static function processHaxe(code:String):String
	{
		if(code == null || code.length < 1) return code;

		var input:haxe.io.Bytes = haxe.io.Bytes.ofString(code);
		var out:haxe.io.BytesBuffer = new haxe.io.BytesBuffer();

		var pos:Int = 0;
		while(pos <= input.length)
		{
			var lineEnd:Int = pos;
			while(lineEnd < input.length && input.get(lineEnd) != NEWLINE) lineEnd++;

			transformLine(input, pos, lineEnd, out);

			if(lineEnd >= input.length) break;

			out.addByte(NEWLINE);
			pos = lineEnd + 1;
		}
		return out.getBytes().toString();
	}

	static function transformLine(input:haxe.io.Bytes, start:Int, end:Int, out:haxe.io.BytesBuffer):Void
	{
		var body:Int = start;
		while(body < end && (input.get(body) == SPACE || input.get(body) == TAB)) body++;

		// Haxe's own directives are handed to the compiler untouched.
		if(body < end && input.get(body) == HASH && isDirective(input, body, end))
		{
			out.add(input.sub(start, end - start));
			return;
		}

		if(body > start) out.add(input.sub(start, body - start));

		// `local x = 1` -> `var x = 1`, the same prefix swap the cpp side makes.
		if(matchesAt(input, body, end, 'local '))
		{
			out.addString('var ');
			body += 6;
		}

		var quote:Int = 0;
		var i:Int = body;

		while(i < end)
		{
			var c:Int = input.get(i);

			if(quote != 0)
			{
				out.addByte(c);
				if(c == BACKSLASH && i + 1 < end)
				{
					out.addByte(input.get(i + 1));
					i += 2;
					continue;
				}
				if(c == quote) quote = 0;
				i++;
				continue;
			}

			if(c == DOUBLE_QUOTE || c == SINGLE_QUOTE)
			{
				quote = c;
				out.addByte(c);
				i++;
				continue;
			}

			if(c == HASH)
			{
				out.addString('//');
				out.add(input.sub(i + 1, end - i - 1));
				return;
			}

			if(c == SLASH && i + 1 < end && input.get(i + 1) == SLASH)
			{
				out.add(input.sub(i, end - i));
				return;
			}

			if(isIdentStart(c) && (i == body || !isIdentChar(input.get(i - 1))))
			{
				var wordEnd:Int = i;
				while(wordEnd < end && isIdentChar(input.get(wordEnd))) wordEnd++;

				var word:String = input.getString(i, wordEnd - i);

				// After a dot this is a field or method name, never one of the keywords.
				if(!isMemberAccess(input, body, i))
				{
					var replacement:String = TOKENS.get(word);
					if(replacement != null)
					{
						out.addString(replacement);
						i = wordEnd;
						continue;
					}

					if(word == 'is')
					{
						var phrase = noneComparison(input, wordEnd, end);
						if(phrase != null)
						{
							out.addString(phrase.text);
							i = phrase.end;
							continue;
						}
					}
				}

				out.add(input.sub(i, wordEnd - i));
				i = wordEnd;
				continue;
			}

			out.addByte(c);
			i++;
		}
	}

	/** Reports Python tokens used after a dot, where the rewrite must leave them alone. */
	public static function warnings(code:String):Array<String>
	{
		var found:Array<String> = [];
		if(code == null) return found;

		var input:haxe.io.Bytes = haxe.io.Bytes.ofString(code);
		var line:Int = 1;
		var quote:Int = 0;
		var i:Int = 0;

		while(i < input.length)
		{
			var c:Int = input.get(i);
			if(c == NEWLINE) line++;

			if(quote != 0)
			{
				if(c == BACKSLASH) { i += 2; continue; }
				if(c == quote) quote = 0;
				i++;
				continue;
			}

			if(c == DOUBLE_QUOTE || c == SINGLE_QUOTE) { quote = c; i++; continue; }

			if(c == HASH || (c == SLASH && i + 1 < input.length && input.get(i + 1) == SLASH))
			{
				while(i < input.length && input.get(i) != NEWLINE) i++;
				continue;
			}

			if(c == SLASH && i + 1 < input.length && input.get(i + 1) == ASTERISK)
			{
				i += 2;
				while(i + 1 < input.length && !(input.get(i) == ASTERISK && input.get(i + 1) == SLASH))
				{
					if(input.get(i) == NEWLINE) line++;
					i++;
				}
				i += 2;
				continue;
			}

			if(isIdentStart(c) && (i == 0 || !isIdentChar(input.get(i - 1))))
			{
				var end:Int = i;
				while(end < input.length && isIdentChar(input.get(end))) end++;
				var word:String = input.getString(i, end - i);

				if(TOKEN_NAMES.contains(word) && isMemberAccess(input, 0, i))
					found.push('line ' + line + ': ' + word + ' is a member name here, so it was left as written');

				i = end;
				continue;
			}

			i++;
		}
		return found;
	}

	// -------------------------------------------------------------------------------------
	// Byte level helpers. The C++ implementation has the same set over std::string.
	// -------------------------------------------------------------------------------------

	/** True when the nearest non-space character before `at` is a dot. */
	static function isMemberAccess(input:haxe.io.Bytes, from:Int, at:Int):Bool
	{
		var i:Int = at;
		while(i > from && (input.get(i - 1) == SPACE || input.get(i - 1) == TAB)) i--;
		return i > from && input.get(i - 1) == DOT;
	}

	/** Matches `is None` and `is not None` after an `is` keyword, returning the replacement. */
	static function noneComparison(input:haxe.io.Bytes, from:Int, end:Int):{text:String, end:Int}
	{
		var first = readWord(input, skipSpace(input, from, end), end);
		if(first == null) return null;

		if(first.word == 'not')
		{
			var second = readWord(input, skipSpace(input, first.end, end), end);
			if(second != null && second.word == 'None') return {text: '!= null', end: second.end};
			return null;
		}

		if(first.word == 'None') return {text: '== null', end: first.end};
		return null;
	}

	static function skipSpace(input:haxe.io.Bytes, from:Int, end:Int):Int
	{
		var i:Int = from;
		while(i < end && (input.get(i) == SPACE || input.get(i) == TAB)) i++;
		return i;
	}

	static function readWord(input:haxe.io.Bytes, at:Int, end:Int):{word:String, end:Int}
	{
		if(at >= end || !isIdentStart(input.get(at))) return null;

		var wordEnd:Int = at;
		while(wordEnd < end && isIdentChar(input.get(wordEnd))) wordEnd++;
		return {word: input.getString(at, wordEnd - at), end: wordEnd};
	}

	static function isDirective(input:haxe.io.Bytes, at:Int, end:Int):Bool
	{
		for (directive in DIRECTIVES)
		{
			var length:Int = directive.length;
			if(!matchesAt(input, at, end, directive)) continue;
			if(at + length >= end || !isIdentChar(input.get(at + length))) return true;
		}
		return false;
	}

	static function matchesAt(input:haxe.io.Bytes, at:Int, end:Int, text:String):Bool
	{
		if(at + text.length > end) return false;

		for (i in 0...text.length)
			if(input.get(at + i) != text.charCodeAt(i)) return false;
		return true;
	}

	static inline function isIdentStart(c:Int):Bool
		return (c >= 97 && c <= 122) || (c >= 65 && c <= 90) || c == 95;

	static inline function isIdentChar(c:Int):Bool
		return isIdentStart(c) || (c >= 48 && c <= 57);

	/**
	 * Same 64-bit FNV-1a as the cpp side, byte for byte, returning the same low 53 bits.
	 *
	 * Haxe Int is 32-bit, so the state is kept as two unsigned halves and the multiply by
	 * 1099511628211 (2^40 + 435) is done as `h * 435` plus `h << 40`. Every intermediate stays
	 * below 2^53, so the Float arithmetic is exact.
	 */
	public static function haxeHash(code:String):Float
	{
		if(code == null) return 0;

		var bytes:haxe.io.Bytes = haxe.io.Bytes.ofString(code);

		// FNV-1a 64-bit offset basis: 0xCBF29CE484222325
		var lo:Int = 0x84222325;
		var hi:Int = 0xCBF29CE4;

		for (i in 0...bytes.length)
		{
			lo = lo ^ bytes.get(i);

			var low:Float = unsignedInt(lo) * 435.0;
			var carry:Float = Math.floor(low / 4294967296.0);
			var newLo:Float = low - carry * 4294967296.0;
			var lowBits:Float = unsignedInt(lo) % 16777216.0;
			var newHi:Float = unsignedInt(hi) * 435.0 + carry + lowBits * 256.0;

			lo = fromUnsigned(newLo);
			hi = fromUnsigned(newHi);
		}

		var lowPart:Float = unsignedInt(lo);
		var highPart:Float = unsignedInt(hi) % 2097152.0;
		return highPart * 4294967296.0 + lowPart;
	}

	/** Portable version of the balance check. Also byte based, so offsets stay UTF-8 safe. */
	public static function haxeValidate(code:String):String
	{
		if(code == null) return '';

		var input:haxe.io.Bytes = haxe.io.Bytes.ofString(code);
		var line:Int = 1;
		var braces:Int = 0;
		var parens:Int = 0;
		var brackets:Int = 0;
		var quote:Int = 0;

		var i:Int = 0;
		while(i < input.length)
		{
			var c:Int = input.get(i);
			if(c == NEWLINE) line++;

			if(quote != 0)
			{
				if(c == BACKSLASH) { i += 2; continue; }
				if(c == quote) quote = 0;
				i++;
				continue;
			}

			if(c == DOUBLE_QUOTE || c == SINGLE_QUOTE) { quote = c; i++; continue; }

			if(c == HASH || (c == SLASH && i + 1 < input.length && input.get(i + 1) == SLASH))
			{
				while(i < input.length && input.get(i) != NEWLINE) i++;
				continue;
			}

			if(c == SLASH && i + 1 < input.length && input.get(i + 1) == ASTERISK)
			{
				i += 2;
				while(i + 1 < input.length && !(input.get(i) == ASTERISK && input.get(i + 1) == SLASH))
				{
					if(input.get(i) == NEWLINE) line++;
					i++;
				}
				i += 2;
				continue;
			}

			switch(c)
			{
				case 123: braces++;      // {
				case 125: if(--braces < 0) return 'extra } on line $line';
				case 40: parens++;       // (
				case 41: if(--parens < 0) return 'extra ) on line $line';
				case 91: brackets++;     // [
				case 93: if(--brackets < 0) return 'extra ] on line $line';
			}
			i++;
		}

		if(quote != 0) return 'unterminated string near line $line';
		if(braces > 0) return '$braces unclosed brace(s)';
		if(parens > 0) return '$parens unclosed parenthesis';
		if(brackets > 0) return '$brackets unclosed bracket';
		return '';
	}

	static inline function unsignedInt(value:Int):Float
	{
		return value < 0 ? value + 4294967296.0 : value;
	}

	static function fromUnsigned(value:Float):Int
	{
		var wrapped:Float = value % 4294967296.0;
		if(wrapped < 0) wrapped += 4294967296.0;
		return Std.int(wrapped >= 2147483648.0 ? wrapped - 4294967296.0 : wrapped);
	}
}
