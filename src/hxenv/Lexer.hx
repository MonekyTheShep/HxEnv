package hxenv;

enum Token {
	Key(key:String); // 𝑥 = 𝑦
	Equals; // =
	RawValue(value:String); // 𝑥 = 𝑦
	SingleQuoteValue(value:String); // 𝑥 = '𝑦'
	DoubleQuoteValue(value:String); // 𝑥 = "𝑦"

	Comment(value:String); // #comment
	Newline; // \n
	Eof; // end of file
}

enum LexerState {
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
    public var verboseMode:Bool;

    public function new(?verboseMode:Bool) {
		this.verboseMode = false;
	}

    public function lex(query:String):Array<Token> {
        this.query = StringTools.replace(query, "\r\n", "\n");
		this.pos = 0;
		this.lineNo = 1;
		this.col = 1;
		this.state = KeyState;
		this.tokenQueue = new Array<Token>();
		
       var result:Array<Token> = [];
		while (true) {
			var t = token();

			if (t != null) result.push(t);
			if (t == Eof) break;
			
		}
		return result;
    }

    function token():Token {
		while (true) {
			if (tokenQueue.length > 0) {
				return tokenQueue.shift();
			}

			while (isSpace(peek()) && !isEof(peek())) advance(); // Skip white spaces

			if (isEof(peek())) {
				if (state == ValueState) { // Value edge case
						tokenQueue.push(RawValue(""));
						state = KeyState;
						return null;
				}
				return Eof;
			} 


            final char:Int = peek();

            switch (char) {
				case '\n'.code:
					advance();
					lineNo++;
					col = 1;
					if (state == ValueState) { // Value edge case
						tokenQueue.push(RawValue(""));
						tokenQueue.push(Newline);
						state = KeyState;
						return null;
					}
					state = KeyState;
                    return Newline;
                case '='.code:
					if (state == ValueState) return readRawValue(); // If state is already value state return value
					advance();
                    state = ValueState;
                    return Equals;
                case '#'.code:
                    return readComment();
				case '"'.code:
					return readDoubleQuoteValue();
				case "'".code:
					return readSingleQuoteValue();
                default: 
					
					if (state == KeyState) return readKeyIdentifier();
					if (state == ValueState) return readRawValue();
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

		var keyIdentifier:String = StringTools.trim(query.substring(start, pos));
		return Key(keyIdentifier);
	}

	function readSingleQuoteValue():Token {
		final quote = advance(); // Consume Starting Quote
		var stringBuf:StringBuf = new StringBuf();

		while (!isEof(peek()) && !isNewline(peek()) && peek() != quote) {
			stringBuf.addChar(advance());
		}

		if (isEof(peek()) || isNewline(peek())) throw 'Unclosed \' quotes at at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Quote

		state = KeyState;
		return SingleQuoteValue(stringBuf.toString());
	}

	function readDoubleQuoteValue():Token {
		final quote = advance(); // Consume Starting Quote
		var stringBuf:StringBuf = new StringBuf();
		
		while (!isEof(peek()) && peek() != quote) {
			if (isBackSlash(peek())) {
				advance(); // Consume Escape Character
				if (isEof(peek())) throw 'Unclosed \" quotes at at line ${lineNo}, col ${col}!';
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
			} else {
				if (isNewline(peek())) {
					lineNo++;
					col = 1;
				} 
				stringBuf.addChar(advance());
			}
		}

		if (isEof(peek())) throw 'Unclosed \" quotes at at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Quote
		state = KeyState;
		
		return DoubleQuoteValue(stringBuf.toString());
	}
	
	function readRawValue():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek()) && !isSpace(peek())) {
			if(!Utils.valChar[peek()]) invalidChar(peek());
			advance();
		}

		var value:String = query.substring(start, pos);
		
		state = KeyState;
		// if(value.length == 0) return null;
		return RawValue(value);
	}

    function readComment():Token {
		final start:Int = pos + 1;

		while (!isNewline(peek()) && !isEof(peek())) {
			advance();
		}

		return Comment(query.substring(start, pos));
	}

    inline function advance():Int {
		col++;
		return StringTools.fastCodeAt(query, pos++);
	}

    inline function peek():Int {
        return StringTools.fastCodeAt(query, pos);
    }	
	
	inline function peekNext():Int {
        return StringTools.fastCodeAt(query, pos + 1);
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
	inline function isSpace(char:Int):Bool return char == ' '.code || char == '\t'.code;
	inline function isQuote(char:Int):Bool return char == "'".code || char == '"'.code || char == '`'.code;
	inline function isBackSlash(char:Int):Bool return char == '\\'.code;
	
	inline function isDigit(c:Int):Bool return c >= '0'.code && c <= '9'.code;
	inline function isAlpha(c:Int):Bool return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code);
	inline function isAlphaNumeric(c:Int):Bool return isAlpha(c) || isDigit(c);
	
}