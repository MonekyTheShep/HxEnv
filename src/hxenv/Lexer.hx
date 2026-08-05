package hxenv;

using StringTools;

enum Token {
	TIdentifier(name:String);
	TString(val:String);

	TEquals; 
	TError(err:String);

	TComment(value:String); 
	TNewline;
	TEof;
}

class Lexer {
	var query:String;
	var pos:Int;
	var line:Int;
	var col:Int;
	var tokenQueue:Array<Token>;

	public function new(query:String) {
		this.query = query;
		this.pos = 0;
		this.line = 1;
		this.col = 1;
		this.tokenQueue = new Array();
	}

	public function token():Token {
		return lex();
	}

	function lex():Token {
		while (true) {
			if (tokenQueue.length > 0) {
				return tokenQueue.shift();
			}

			skipWhiteSpace();

			if (isEof(peek())) {
				return TEof;
			}

			final currentChar:Int = peek();

			function readValue(char:Int) {
				if (char == '"'.code) {
					return readQuote(true);
				} else if (char == "'".code) {
					return readQuote(false);
				} else {
					return readRawRalue();
				}
			}

			if (currentChar == '\n'.code) {
				incLine();
				return TNewline;
			} else if (currentChar == '='.code) {
				advance(); // Consume Equal
				tokenQueue.push(TEquals);
				tokenQueue.push(readValue(peek()));
				continue;
			} else if (currentChar == '#'.code) {
				return readComment();
			} else if (currentChar == '"'.code || currentChar == "'".code) {
				return readValue(currentChar);
			}

			return readIdentifier();
		}
	}

	function readRawRalue():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek())) {
			if (!Utils.valChar[peek()]) return TError(invalidChar(peek()));
			advance();
		}

		return TString(query.substring(start, pos));
	}

	function readIdentifier():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek()) && !isEqual(peek())) {
			if (!Utils.idChar[peek()]) return TError(invalidChar(peek()));
			advance();
		}

		return TIdentifier(query.substring(start, pos));
	}

	function readQuote(interpolated:Bool):Token {
		final quote = advance(); // Consume Starting Quote
		var stringBuf:StringBuf = new StringBuf();

		while (!isEof(peek()) && !isNewline(peek()) && peek() != quote) {
			if (interpolated && isBackSlash(peek())) {
				readInterpolated(stringBuf);
			}
			else stringBuf.addChar(advance());
			
		}

		if (peek() != quote) throw 'Unclosed \' quotes at line $line}, col ${col}!';

		advance(); // Consume Ending Quote

		return TString(stringBuf.toString());
	}

	function readInterpolated(stringBuf:StringBuf) {
		if (isBackSlash(peek())) {
			advance();
			if (isEof(peek())) return;
			var escaped:Int = advance(); 
			switch (escaped) {
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
				default:
					stringBuf.addChar(escaped);
			}
		}
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

	//----------------------------------------------------------------------------------
	// Helper Functions
	//----------------------------------------------------------------------------------
	function invalidChar(char:Int):String {
		return 'Unexpected char `${(char != '\n'.code) ? String.fromCharCode(char) : "\\n"}` at line $line, col ${col}!';
	}
	
	function incLine() {
		advance();
		line++;
		col = 1;
	}

	function skipWhiteSpace() {
		while (!isEof(peek()) && isSpace(peek()))
			advance(); // Skip white spaces
	}

	inline function isEof(char:Int):Bool return StringTools.isEof(char);
	inline function isNewline(char:Int):Bool return char == '\n'.code;
	inline function isEqual(char:Int):Bool return char == '='.code;
	inline function isCommentPrefix(char:Int):Bool return char == '#'.code;
	inline function isInterpolatedPrefix(char:Int):Bool return char == '$'.code;
	inline function isSpace(char:Int):Bool return char == ' '.code || char == '\t'.code || char == '\r'.code;
	inline function isQuote(char:Int):Bool return char == "'".code || char == '"'.code || char == '`'.code;
	inline function isBackSlash(char:Int):Bool return char == '\\'.code;

	inline function isDigit(c:Int):Bool return c >= '0'.code && c <= '9'.code;
	inline function isAlpha(c:Int):Bool return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code);
	inline function isAlphaNumeric(c:Int):Bool return isAlpha(c) || isDigit(c);
}
