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
		this.state = KeyState;
		
       var result = [];
		while (true) {
			var t = token();

            result.push(t);
			if (t == Eof) break;
			
		}
		return result;
    }

    function token():Token {
		while (true) {
            final char = peek();
			
            switch (char) {
				case '\n'.code:
					advance();
					lineNo++;
					state = KeyState;
                    return Newline;
                case "=".code:
					advance();
                    state = ValueState;
                    return Equals;
                case "#".code:
                    return readComment();
				case '"'.code, "'".code:
					throw "Quote support will be added in later versions!";
                default: 
					if (isEof(char)) return Eof;
					if (state == KeyState) return readKeyIdentifier();
					if (state == ValueState) return readValue();
            }
        }
    }
	
	function readKeyIdentifier():Token {
		final start:Int = pos;

		while (!isEof(peek()) && !isCommentPrefix(peek())) {
			if (!idChar[peek()]) break;
			advance();
		}

		var keyValue:String = StringTools.trim(query.substr(start, pos - start));

		for (i in 0...keyValue.length) {
			if (!idChar[keyValue.charCodeAt(i)]) invalidChar(keyValue.charCodeAt(i));
		}

		return Key(keyValue);
	}

	function readValue():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek()) && !isCommentPrefix(peek())) {
			advance();
		}

		var value:String = query.substring(start, pos);

		for (i in 0...value.length) {
			if (isQuote(value.charCodeAt(i))) invalidChar(value.charCodeAt(i));
		}

		return Value(query.substring(start, pos));
	}

    function readComment():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek())) {
			advance();
		}

		return Comment(query.substring(start, pos));
	}

    inline function advance():Int {
		return StringTools.fastCodeAt(query, pos++);
	}

    inline function peek():Int {
        return StringTools.fastCodeAt(query, pos);
    }

	function invalidChar(char:Int) throw 'Unexpected char ${String.fromCharCode(char)} at line ${lineNo}!';
	inline function isEof(char:Int):Bool return StringTools.isEof(char);
	inline function isNewline(char:Int):Bool return char == '\n'.code;
	inline function isCommentPrefix(char:Int):Bool return char == '#'.code;
	inline function isQuote(char:Int):Bool return char == "'".code || char == '"'.code;
}