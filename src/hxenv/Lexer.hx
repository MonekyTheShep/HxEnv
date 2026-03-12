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
		idChar[" ".code] = true;
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
            final char = nextChar();

            switch (char) {
				case '\n'.code:
					state = KeyState;
                    return Newline;
                case "=".code:
                    state = ValueState;
                    return Equals;
                case "#".code:
                    return readComment();
                default: 
					if (isEof(char)) return Eof;
					if (!idChar[char]) invalidChar(char);
					if (state == KeyState) return readKeyIdentifier();
					if (state == ValueState) return readValue();
            }
        }
    }
	
	function readKeyIdentifier():Token {
		final start:Int = pos - 1;

		while (idChar[peek()] && !isEof(peek()) && !isCommentPrefix(peek())) {
			nextChar();
		}

		trace(query.substr(start, pos - start));
		
		return Key(query.substr(start, pos - start));
	}

	function readValue():Token {
		final start:Int = pos - 1;

		while (!isNewline(peek()) && !isEof(peek()) && !isCommentPrefix(peek())) {
			nextChar();
		}

		return Value(query.substr(start, pos - start));
	}

    function readComment():Token {
		final start:Int = pos;

		while (!isNewline(peek()) && !isEof(peek())) {
			nextChar();
		}

		return Comment(query.substr(start, pos - start));
	}


    inline function nextChar():Int {
		if (this.pos >= query.length) return -1;
		return StringTools.fastCodeAt(query, pos++);
	}

    inline function peek():Int {
		if (this.pos >= query.length) return -1;
        return StringTools.fastCodeAt(query, pos);
    }

	function invalidChar(char:Int) throw new haxe.Exception("Unexpected char '" + String.fromCharCode(char)+"'");
	inline function isEof(char:Int):Bool return char == -1;
	inline function isNewline(char:Int):Bool return char == '\n'.code;
	inline function isCommentPrefix(char:Int):Bool return char == '#'.code;
}