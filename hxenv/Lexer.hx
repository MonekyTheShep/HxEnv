package hxenv;

enum Token {
	Key(key:String);
	Value(value:String);
	Equals;
	Newline;
	Eof;
}

enum LexerState {
	KeyState;
	ValueState;
	CommentState;
}

class Lexer {
	var query:String;

	// store current pos in query
	var pos:Int;

	// current line number
	var lineNo:Int;

	// valid chars
	var idChar:Array<Bool>;

	// store current token from char
	var cache:Array<Token> = [];

	var state:LexerState = KeyState;
	var key:String = "";
	var value:String = "";

	public function new() {
		idChar = [];

		// populate valid chars with bools at ascii positions

		for (i in 'A'.code...'Z'.code + 1) {
			idChar[i] = true;
		}

		for (i in 'a'.code...'z'.code + 1) {
			idChar[i] = true;
		}

		for (i in '0'.code...'9'.code + 1) {
			idChar[i] = true;
		}
	}

	public function lex(query:String):Array<Token> {
		this.query = query;
		this.pos = 0;
		this.lineNo = 0;

		var result = [];

		// loop through chars appending tokens until no more
		tokenize();

		return cache;
	}

	function tokenize() {
		while (true) {
			// if reached end break loop;
			if (this.pos >= query.length) {
				// when reached end add the end value;
				if (value != "") {
					cache.push(Value(value));
				}
				cache.push(Eof);
				break;
			}

			var char = nextChar();

			switch (char) {
				// switch the state to value when found "="
				case '='.code:
					state = ValueState;
					cache.push(Key(key));
					cache.push(Equals);
					key = "";

				// switch the state to key state
				case '\n'.code:
					state = KeyState;
					cache.push(Value(value));
					cache.push(Newline);
					value = "";

				
				// switch to comment state
				case '#'.code:
					state = CommentState;			

				default:
					if ((char >= 'A'.code && char <= 'Z'.code) || (char >= 'a'.code && char <= 'z'.code )) {
						if (state == KeyState) {
							key += String.fromCharCode(char);
						} else if (state == ValueState) {
							value += String.fromCharCode(char);
						}
					}
					
			}
		}
		return;
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}
}
