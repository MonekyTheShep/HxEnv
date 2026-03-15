package hxenv;

enum Token {
	Key(key:String); // 𝑥 = 𝑦
	Equals; // =
	Value(value:String); // 𝑥 = 𝑦

	Comment(value:String); // #{comment}
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
		this.tokenQueue = [];
		
       	var result:Array<Token> = [];
		while (!isEof()) {
			if (tokenQueue.length > 0) {
				while (tokenQueue.length > 0) result.push(tokenQueue.shift());
				continue;
			}
			var t = token();

			if (t != null) result.push(t);
			
		}
		result.push(Eof);
		return result;
    }

    function token():Token {
		while (true) {
            final char:Int = peek();

			if (isEof()) {
				if (state == ValueState) tokenQueue.push(Value("")); tokenQueue.push(Newline); return null;  // Edge case if no chars are found after equals
				return null;
			}

			if (isNewline(char)) {
				final startState = state;
				advance();
				lineNo++;
				col = 1;
				state = KeyState;
				if (startState == ValueState) tokenQueue.push(Value("")); tokenQueue.push(Newline); return null; // Edge case if no chars are found after equals
                return Newline;
			}

			if (isEqual(char)) {
				if (state == ValueState) return readValue(); // If state is already value state return value
				advance();
                state = ValueState;
                return Equals;
			}

			if (isCommentPrefix(char)) {
				state = KeyState;
                return readComment();
			}

			if (isQuote(char)) {
				if (char == '"'.code) return readDoubleQuote();
				if (char == "'".code) return readSingleQuote();
			}

			if (Utils.idChar[char] && state == KeyState) return readKeyIdentifier();
			if (Utils.valChar[char] && state == ValueState) return readValue();

			invalidChar(char); // Any char not caught in if statements are invalid.
        }
    }
	
	function readKeyIdentifier():Token {
		final start:Int = pos;

		if (isDigit(peek())) invalidChar(peek()); // First character can't start with digit.
		while (!isEqual(peek()) && !isNewline(peek()) && !isEof()) {
			if(!Utils.idChar[peek()]) invalidChar(peek());
			advance();
		}

		var keyIdentifier:String = StringTools.trim(query.substring(start, pos));
		return Key(keyIdentifier);
	}

	function readSingleQuote():Token {
		final quote = advance(); // Consume Starting Quote
		var stringBuf:StringBuf = new StringBuf();

		while (!isEof() && !isNewline(peek()) && peek() != quote) {
			stringBuf.addChar(advance());
		}

		if (isEof() || isNewline(peek())) throw 'Unclosed \' quotes at at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Quote
		
		while (isSpace(peek())) advance(); // Skip white spaces after quote
		return Value(stringBuf.toString());
	}

	function readDoubleQuote():Token {
		final quote = advance(); // Consume Starting Quote
		var stringBuf:StringBuf = new StringBuf();
		
		while (!isEof() && peek() != quote) {
			if (isBackSlash(peek())) {
				advance(); // Consume Escape Character
				var next:Int = advance(); // Consume next character after Escape Character

				if (isEof()) throw 'Unclosed \" quotes at at line ${lineNo}, col ${col}!';

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

		if (isEof()) throw 'Unclosed \" quotes at at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Quote
		
		while (isSpace(peek())) advance(); // Skip white spaces after quote
		return Value(stringBuf.toString());
	}
	
	function readValue():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof() && !isSpace(peek())) {
			if(!Utils.valChar[peek()]) invalidChar(peek());
			advance();
		}

		var value:String = query.substring(start, pos);

		while (isSpace(peek())) advance(); // Skip white spaces after value
		return Value(value);
	}

    function readComment():Token {
		final start:Int = pos + 1;

		while (!isNewline(peek()) && !isEof()) {
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
	function invalidChar(char:Int) throw 'Unexpected char \'${String.fromCharCode(char)}\' at line ${lineNo}, col ${col}!';

	inline function isEof():Bool return pos >= query.length;
	inline function isNewline(char:Int):Bool return char == '\n'.code;
	inline function isEqual(char:Int):Bool return char == '='.code;
	inline function isCommentPrefix(char:Int):Bool return char == '#'.code;
	inline function isSpace(char:Int):Bool return char == ' '.code;
	inline function isQuote(char:Int):Bool return char == "'".code || char == '"'.code;
	inline function isBackSlash(char:Int):Bool return char == '\\'.code;
	
	inline function isDigit(c:Int):Bool return c >= '0'.code && c <= '9'.code;
	inline function isAlpha(c:Int):Bool return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code);
	inline function isAlphaNumeric(c:Int):Bool return isAlpha(c) || isDigit(c);
	
}