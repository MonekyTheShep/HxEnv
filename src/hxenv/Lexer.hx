package hxenv;

import haxe.macro.Expr.Catch;

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
	MultiLineState;
}

class Lexer {
	var query:String;
	var pos:Int;
	var lineNo:Int;
	var col:Int;
	var state:LexerState;
    public var verboseMode:Bool;

    public function new(?verboseMode:Bool) {
		this.verboseMode = false;

	}

    static var idChar:Map<Int, Bool> = populateIdChars();

    static function populateIdChars():Map<Int, Bool> {
		var idChar = new Map<Int, Bool>(); 

		// populate identifier chars with bools at ascii positions
		for (i in 'A'.code...'Z'.code + 1) {
			idChar[i] = true;
		}

		for (i in 'a'.code...'z'.code + 1) {
			idChar[i] = true;
		}

		for (i in '0'.code...'9'.code + 1) {
			idChar[i] = true;
		}

		idChar["_".code] = true;
		idChar["-".code] = true;
		idChar["$".code] = true;
		idChar[".".code] = true;
		idChar[0] = true;
		return idChar;
	}

    public function lex(query:String):Array<Token> {
        this.query = StringTools.replace(query, "\r\n", "\n");
		this.pos = 0;
		this.lineNo = 1;
		this.col = 1;
		this.state = KeyState;
		
       var result:Array<Token> = [];
		while (true) {
			var t = token();

            result.push(t);
			if (t == Eof) break;
			
		}
		return result;
    }

    function token():Token {
		while (true) {
            final char:Int = peek();

            switch (char) {
				case '\n'.code:
					advance();
					lineNo++;
					col = 1;
					state = KeyState;
                    return Newline;
                case '='.code:
					advance();
                    state = ValueState;
                    return Equals;
                case '#'.code:
                    return readComment();
				case '`'.code:
					quoteError();
				case '"'.code:
					quoteError();
				case "'".code:
					return readSingleQuote();
                default: 
					if (isEof(char)) return Eof;
					if (state == KeyState) return readKeyIdentifier();
					if (state == ValueState) return readValue();
            }
        }
    }
	
	function readKeyIdentifier():Token {
		final start:Int = pos;

		while (!isEqual(peek()) && !isNewline(peek()) && !isEof(peek())) {
			if (!idChar[peek()]) invalidChar(peek());
			advance();
		}

		var keyIdentifier:String = StringTools.trim(query.substring(start, pos));
		return Key(keyIdentifier);
	}

	// function readMultiLine():Token {
	// 	var quote = advance();
	// 	var stringBuf:StringBuf = new StringBuf();

	// 	while (!isEof(peek()) && peek() != quote) {
	// 		if (peek() == '\n'.code) {
	// 			advance();
	// 			continue; // Skip new line
	// 		}
	// 		stringBuf.add(String.fromCharCode(advance()));
	// 	}

	// 	if (isEof(peek())) throw 'Unclosed ` quotes';

	// 	advance();
	// 	trace(stringBuf.toString());
	// 	return Value(stringBuf.toString());
	// }

	function readSingleQuote():Token {
		var quote = advance(); // Consume Starting Quote
		var stringBuf:StringBuf = new StringBuf();

		while (!isEof(peek()) && !isNewline(peek()) && peek() != quote) {
			stringBuf.add(String.fromCharCode(advance()));
		}

		if (isEof(peek()) || isNewline(peek())) throw 'Unclosed \' quotes at at line ${lineNo}, col ${col}!';

		advance(); // Consume Ending Quote
		
		while (peek() == ' '.code) advance(); // Skip white spaces after quote
		return Value(stringBuf.toString());
	}

	function readValue():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek()) && !isCommentPrefix(peek())) {
			if (isQuote(peek())) quoteError();
			if(!isAlphaNumeric(peek()) && !isSpace(peek())) invalidChar(peek());
			advance();
		}

		var value:String = query.substring(start, pos);
		return Value(value);
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

	function invalidChar(char:Int) throw 'Unexpected char \'${String.fromCharCode(char)}\' at line ${lineNo}, col ${col}!';
	inline function isEof(char:Int):Bool return StringTools.isEof(char);
	inline function isNewline(char:Int):Bool return char == '\n'.code;
	inline function isEqual(char:Int):Bool return char == '='.code;
	inline function isCommentPrefix(char:Int):Bool return char == '#'.code;
	inline function isSpace(char:Int):Bool return char == ' '.code;
	inline function isQuote(char:Int):Bool return char == "'".code || char == '"'.code || char == '`'.code;
	function quoteError() throw 'Unexpected backtick quote or double quote at line ${lineNo}, col ${col}! Support will be added in later revisions!';

	inline function isDigit(c:Int):Bool return c >= '0'.code && c <= '9'.code;
	inline function isAlpha(c:Int):Bool return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code);
	inline function isAlphaNumeric(c:Int):Bool return isAlpha(c) || isDigit(c);
	
}