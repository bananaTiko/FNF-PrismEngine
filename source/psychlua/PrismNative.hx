package psychlua;

#if cpp
@:cppFileCode('
#include <string>
#include <cstring>
#include <cstdint>

namespace prism
{
	inline bool identStart(char c) { return (c >= 97 && c <= 122) || (c >= 65 && c <= 90) || c == 95; }
	inline bool identChar(char c) { return identStart(c) || (c >= 48 && c <= 57); }

	inline bool isDirective(const std::string &line, size_t at)
	{
		const char *dirs[] = {"#if", "#elseif", "#else", "#end"};
		for (int i = 0; i < 4; i++)
		{
			size_t n = std::strlen(dirs[i]);
			if (line.compare(at, n, dirs[i]) == 0)
			{
				size_t end = at + n;
				if (end >= line.size() || !identChar(line[end])) return true;
			}
		}
		return false;
	}

	inline size_t skipSpace(const std::string &s, size_t at)
	{
		while (at < s.size() && (s[at] == 32 || s[at] == 9)) at++;
		return at;
	}

	inline bool readWord(const std::string &s, size_t at, std::string &word, size_t &end)
	{
		if (at >= s.size() || !identStart(s[at])) return false;

		end = at;
		while (end < s.size() && identChar(s[end])) end++;
		word = s.substr(at, end - at);
		return true;
	}

	/** True when the nearest non-space character before `at` is a dot. */
	inline bool memberAccess(const std::string &s, size_t at)
	{
		size_t i = at;
		while (i > 0 && (s[i - 1] == 32 || s[i - 1] == 9)) i--;
		return i > 0 && s[i - 1] == 46;
	}

	/** Matches `is None` and `is not None` after an `is` keyword. */
	inline bool noneComparison(const std::string &s, size_t from, std::string &text, size_t &end)
	{
		std::string word;
		if (!readWord(s, skipSpace(s, from), word, end)) return false;

		if (word == "not")
		{
			std::string second;
			size_t secondEnd = 0;
			if (!readWord(s, skipSpace(s, end), second, secondEnd) || second != "None") return false;

			text = "!= null";
			end = secondEnd;
			return true;
		}

		if (word == "None") { text = "== null"; return true; }
		return false;
	}

	std::string transformLine(const std::string &line)
	{
		size_t start = 0;
		while (start < line.size() && (line[start] == 32 || line[start] == 9)) start++;
		if (start < line.size() && line[start] == 35 && isDirective(line, start)) return line;

		std::string body = line.substr(start);
		if (body.compare(0, 6, "local ") == 0) body = "var " + body.substr(6);

		std::string out;
		char quote = 0;

		for (size_t i = 0; i < body.size(); )
		{
			char c = body[i];

			if (quote != 0)
			{
				out += c;
				if (c == 92 && i + 1 < body.size()) { out += body[i + 1]; i += 2; continue; }
				if (c == quote) quote = 0;
				i++;
				continue;
			}

			if (c == 34 || c == 39) { quote = c; out += c; i++; continue; }

			if (c == 35)
			{
				out += "//";
				out += body.substr(i + 1);
				break;
			}

			if (c == 47 && i + 1 < body.size() && body[i + 1] == 47)
			{
				out += body.substr(i);
				break;
			}

			if (identStart(c) && (i == 0 || !identChar(body[i - 1])))
			{
				size_t end = i;
				while (end < body.size() && identChar(body[end])) end++;

				std::string word = body.substr(i, end - i);

				// After a dot this is a field or method name, never one of the keywords.
				if (memberAccess(body, i))
				{
					out += word;
					i = end;
					continue;
				}

				if (word == "nil") out += "null";
				else if (word == "elif") out += "else if";
				else if (word == "def") out += "function";
				else if (word == "True") out += "true";
				else if (word == "False") out += "false";
				else if (word == "None") out += "null";
				else if (word == "and") out += "&&";
				else if (word == "or") out += "||";
				else if (word == "not") out += "!";
				else if (word == "is")
				{
					std::string phrase;
					size_t phraseEnd = end;
					if (noneComparison(body, end, phrase, phraseEnd))
					{
						out += phrase;
						i = phraseEnd;
						continue;
					}
					out += word;
				}
				else out += word;

				i = end;
				continue;
			}

			out += c;
			i++;
		}

		return line.substr(0, start) + out;
	}

	std::string transformSource(const std::string &in)
	{
		std::string out;
		size_t pos = 0;

		while (pos <= in.size())
		{
			size_t nl = in.find(10, pos);
			if (nl == std::string::npos)
			{
				out += transformLine(in.substr(pos));
				break;
			}

			out += transformLine(in.substr(pos, nl - pos));
			out += (char)10;
			pos = nl + 1;
		}
		return out;
	}

	uint64_t fnv1a(const std::string &in)
	{
		uint64_t hash = 14695981039346656037ULL;
		for (size_t i = 0; i < in.size(); i++)
		{
			hash ^= (unsigned char)in[i];
			hash *= 1099511628211ULL;
		}
		return hash;
	}

	std::string validate(const std::string &in)
	{
		int line = 1;
		int braces = 0, parens = 0, brackets = 0;
		char quote = 0;

		for (size_t i = 0; i < in.size(); i++)
		{
			char c = in[i];
			if (c == 10) line++;

			if (quote != 0)
			{
				if (c == 92 && i + 1 < in.size()) { i++; continue; }
				if (c == quote) quote = 0;
				continue;
			}

			if (c == 34 || c == 39) { quote = c; continue; }

			if (c == 35 || (c == 47 && i + 1 < in.size() && in[i + 1] == 47))
			{
				while (i < in.size() && in[i] != 10) i++;
				line++;
				continue;
			}

			if (c == 47 && i + 1 < in.size() && in[i + 1] == 42)
			{
				i += 2;
				while (i + 1 < in.size() && !(in[i] == 42 && in[i + 1] == 47))
				{
					if (in[i] == 10) line++;
					i++;
				}
				i++;
				continue;
			}

			if (c == 123) braces++;
			else if (c == 125) { if (--braces < 0) return "extra } on line " + std::to_string(line); }
			else if (c == 40) parens++;
			else if (c == 41) { if (--parens < 0) return "extra ) on line " + std::to_string(line); }
			else if (c == 91) brackets++;
			else if (c == 93) { if (--brackets < 0) return "extra ] on line " + std::to_string(line); }
		}

		if (quote != 0) return "unterminated string near line " + std::to_string(line);
		if (braces > 0) return std::to_string(braces) + " unclosed brace(s)";
		if (parens > 0) return std::to_string(parens) + " unclosed parenthesis";
		if (brackets > 0) return std::to_string(brackets) + " unclosed bracket";
		return "";
	}
}
')

/**
 * The cpp implementation of the `.prism` source pass, hash and balance check.
 *
 * Only compiled on cpp targets, and only ever called from PrismPreprocessor, which owns the
 * choice of implementation and the portable Haxe versions. Nothing here needs a fallback.
 */
class PrismNative
{
	public static function transform(code:String):String
		return code == null ? null : cppTransform(code);

	public static function hash(code:String):Float
		return code == null ? 0 : cppHash(code);

	public static function validate(code:String):String
		return code == null ? '' : cppValidate(code);

	// The bodies below exist only so the signatures type-check; on cpp the @:functionCode block
	// replaces them, and this class is not compiled anywhere else.

	@:functionCode('
		std::string in(code.c_str());
		std::string out = prism::transformSource(in);
		return ::String(out.c_str());
	')
	static function cppTransform(code:String):String
		return null;

	@:functionCode('
		std::string in(code.c_str());
		unsigned long long h = prism::fnv1a(in) & 0x1FFFFFFFFFFFFFULL;
		return (double)h;
	')
	static function cppHash(code:String):Float
		return 0;

	@:functionCode('
		std::string in(code.c_str());
		return ::String(prism::validate(in).c_str());
	')
	static function cppValidate(code:String):String
		return '';
}
#end
