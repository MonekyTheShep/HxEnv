package hxenv;

using StringTools;

enum Token {
	TKey(key:String); // 𝑥 = 𝑦
	TEquals; // =

	TRawValue(value:String); // 𝑥 = 𝑦
	TSingleQuote(value:String); // x = '𝑦'
	TDoubleQuote(values:Array<TInterpolated>); // 𝑥 = "𝑦"

	TComment(value:String); // #comment
	TNewline; // \n
	TEof; // end of file
}

enum TInterpolated {
	TIdentifier(name:String);
	TString(value:String);
}

enum LexerState {
	DefaultState;
	KeyState;
	ValueState;
}

class Lexer {
	var query:String;
	var pos:Int;
	var lineNo:Int;
	var col:Int;
	var state:LexerState;
	var tokenQueue:Array<Token>;

	public function new() {}

	public function lex(query:String):Array<Token> {
		this.query = query.replace("\r\n", "\n").replace("\r", "\n"); // Normalise Windows carriage return to Unix new line
		this.pos = 0;
		this.lineNo = 1;
		this.col = 1;
		this.state = KeyState;
		this.tokenQueue = new Array<Token>();

		var result:Array<Token> = [];
		while (true) {
			var t = token();

			if (t != null)
				result.push(t);
			if (t == TEof)
				break;
		}
		trace(result);
		return result;
	}

	function token():Token {
		while (true) {
			if (tokenQueue.length > 0) {
				return tokenQueue.shift();
			}

			while (isSpace(peek()) && !isEof(peek()))
				advance(); // Skip white spaces

			if (isEof(peek())) {
				if (state == ValueState) return pushMultiToken([TRawValue(""), TEof]);
				return TEof;
			}

			final char:Int = peek();

			switch (char) {
				case '\n'.code:
					final startState = state;
					advance();
					lineNo++;
					col = 1;
					state = KeyState;
					if (startState == ValueState) { // Value edge case
						return pushMultiToken([TRawValue(""), TNewline]);
					}
					return TNewline;
				case '='.code:
					if (state == ValueState)
						return readRawValue();
					advance();
					state = ValueState;
					return TEquals;
				case '#'.code:
					return readComment();
				case '"'.code:
					return readDoubleQuoteValue();
				case "'".code:
					return readSingleQuoteValue();
				default:
					if (state == KeyState) return readKeyIdentifier();
					if (state == ValueState) return readRawValue();
					if (state == DefaultState) invalidChar(char); // Characters during default state are invalid.
			}
		}
	}

	function readKeyIdentifier():Token {
		final start:Int = pos;

		if (isDigit(peek())) invalidChar(peek()); // First character can't start with digit.
		while (!isEqual(peek()) && !isSpace(peek()) && !isNewline(peek()) && !isEof(peek())) {
			if (!Utils.idChar[peek()]) invalidChar(peek());
			advance();
		}

		return TKey(query.substring(start, pos));
	}

	function readSingleQuoteValue():Token {
		final quote = advance(); // Consume Starting Quote
		var stringBuf:StringBuf = new StringBuf();

		while (!isEof(peek()) && !isNewline(peek()) && peek() != quote) {
			stringBuf.addChar(advance());
		}

		if (isEof(peek()) || peek() != quote || isNewline(peek())) throw 'Unclosed \' quotes at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Quote

		state = DefaultState;
		return TSingleQuote(stringBuf.toString());
	}

	function readCurlyBraces():TInterpolated {
		advance(); // Consume Starting Brace.

		var identifierBuf:StringBuf = new StringBuf();

		while (!isEof(peek()) && !isNewline(peek()) && peek() != '}'.code) {
			if (!Utils.idChar[peek()]) invalidChar(peek());
			identifierBuf.addChar(advance());
		}

		if (isEof(peek()) || isNewline(peek()) || peek() != '}'.code) throw 'Unclosed {} braces at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Brace.

		if (identifierBuf.length > 0) {
			return TIdentifier(identifierBuf.toString());
		} else {
			return null;
		}
	}

	function readInterpolatedIdentifier():TInterpolated {
		var identifierBuf:StringBuf = new StringBuf();

		while (!isEof(peek()) && !isNewline(peek())) {
			if (!Utils.idChar[peek()]) break;
			identifierBuf.addChar(advance());
		}

		if (identifierBuf.length > 0) {
			return TIdentifier(identifierBuf.toString());
		} else {
			return null;
		}
	}
	

	function readDoubleQuoteValue():Token {
		final quote = advance(); // Consume Starting Quote
		var interpolated:Array<TInterpolated> = new Array<TInterpolated>();
		var stringBuf:StringBuf = new StringBuf();

		while (!isEof(peek()) && peek() != quote) {
			if (isBackSlash(peek())) {
				advance(); // Consume Escape Character
				if (isEof(peek())) throw 'Unclosed \" quotes at line ${lineNo}, col ${col}!';
				var next:Int = advance(); // Consume next character after Escape Character

				switch (next) {
					case 'n'.code:
						stringBuf.add('\n');
					case 't'.code:
						stringBuf.add('\t');
					case 'r'.code:
						stringBuf.add('\r');
					case '\\'.code:
						stringBuf.add('\\');
					case '"'.code:
						stringBuf.add('"');
					case "'".code:
						stringBuf.add("'");
					case "$".code:
						stringBuf.add("$");
					default:
						stringBuf.addChar(next);
				}
			} else if (isInterpolatedPrefix(peek())) {
				if (stringBuf.length > 0) {
					interpolated.push(TString(stringBuf.toString()));
					stringBuf = new StringBuf();
				}

				advance(); // Consume Interpolated Prefix

				if (isEof(peek())) throw 'Unclosed \" quotes at line ${lineNo}, col ${col}!';

				var identifierToken:TInterpolated;
				if (peek() == '{'.code) {
					identifierToken = readCurlyBraces();
				} else {
					if (!Utils.idChar[peek()] || isDigit(peek())) { // Identifiers can't start with digit
						interpolated.push(TString('$'));
						stringBuf = new StringBuf();
						continue;
					}

					identifierToken = readInterpolatedIdentifier();
				}

				if (identifierToken != null) interpolated.push(identifierToken);
			} else {
				if (isNewline(peek())) {
					lineNo++;
					col = 1;
				}
				stringBuf.addChar(advance());
			}
		}

		if (stringBuf.length > 0) {
			interpolated.push(TString(stringBuf.toString()));
			stringBuf = new StringBuf();
		}

		if (isEof(peek()) || peek() != quote) throw 'Unclosed \" quotes at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Quote

		state = DefaultState;
		return TDoubleQuote(interpolated);
	}

	function readRawValue():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek()) && !isSpace(peek())) {
			if (!Utils.valChar[peek()]) invalidChar(peek());
			advance();
		}

		state = DefaultState;
		return TRawValue(query.substring(start, pos));
	}

	function readComment():Token {
		advance(); // Consume Comment Prefix
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek())) {
			advance();
		}

		return TComment(query.substring(start, pos));
	}

	inline function advance():Int {
		col++;
		return StringTools.fastCodeAt(query, pos++);
	}

	inline function peek():Int {
		return StringTools.fastCodeAt(query, pos);
	}

	inline function peekBy(by:Int):Int {
		return StringTools.fastCodeAt(query, pos + by);
	}

	function pushMultiToken(tokens:Array<Token>):Token {
		for (token in tokens) {
			tokenQueue.push(token);
		}

		return null;
	}

	//----------------------------------------------------------------------------------
	// Helper Functions
	//----------------------------------------------------------------------------------
	function invalidChar(char:Int) {
		if (char == '\n'.code) throw 'Unexpected char `\\n` at line ${lineNo}, col ${col}!';
		throw 'Unexpected char `${String.fromCharCode(char)}` at line ${lineNo}, col ${col}!';
	}

	inline function isEof(char:Int):Bool return StringTools.isEof(char);
	inline function isNewline(char:Int):Bool return char == '\n'.code;
	inline function isEqual(char:Int):Bool return char == '='.code;
	inline function isCommentPrefix(char:Int):Bool return char == '#'.code;
	inline function isInterpolatedPrefix(char:Int):Bool return char == '$'.code;
	inline function isSpace(char:Int):Bool return char == ' '.code || char == '\t'.code;
	inline function isQuote(char:Int):Bool return char == "'".code || char == '"'.code || char == '`'.code;
	inline function isBackSlash(char:Int):Bool return char == '\\'.code;

	inline function isDigit(c:Int):Bool return c >= '0'.code && c <= '9'.code;
	inline function isAlpha(c:Int):Bool return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code);
	inline function isAlphaNumeric(c:Int):Bool return isAlpha(c) || isDigit(c);
}
