package hxenv;

enum Token {
	Key(key:String);
	Value(value:String);
	Comment(value:String);
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

	// valid chars
	var idChar:Array<Bool>;

	// store current token from char
	var tokens:Array<Token> = [];

	// store line
	var lineNo:Int = 0;

	var state:LexerState = KeyState;
	var key:String = "";
	var value:String = "";
	var comment:String = "";

	final whiteSpaceCharacter:String = "\\s+";

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

		// loop through chars appending tokens until no more
		tokenize();

		return tokens;
	}

	function tokenize() {
		var hasKey = false;
		var hasEqual = false;

		while (true) {
			// if reached end break loop;
			if (this.pos >= query.length) {
				// when reached finalise
				// add value if it has key
				if (hasKey) {
					appendValue();
				}

				// append any comments before end
				appendComment();

				tokens.push(Eof);
				break;
			}

			var char = nextChar();

			switch (char) {
				// when new line is found append the value or comment and then reset back to default state
				case '\n'.code:
					if (state == CommentState) {
						appendComment();
					} else if (state == ValueState) {
						if (hasKey) {
							appendValue();
							hasKey = false;
						} 
					}
					// default state is key state
					state = KeyState;

					tokens.push(Newline);
					lineNo++;
					//trace(lineNo);

					continue;

				// switch the state to value when found "="
				case '='.code:
					// append the key when = is found if its not empty
					// if this a comment state ignore this and add to comment
					if (state != CommentState) {
						if (state == KeyState && key != "") {
							appendKey();
							hasKey = true;
						}  else if (state == ValueState) {
							// append any other = to value
							value += String.fromCharCode(char);
						} else if (key == "") {
							trace("empty key");
							hasKey = false;
						}

						state = ValueState;
					} else {
						comment += String.fromCharCode(char);
					}

					continue;

				// switch to comment state
				case '#'.code:
					switch (state) {
						case CommentState:
							comment += String.fromCharCode(char);
						case KeyState:
							// cant have # inside of key
							if (key == "") {
								state = CommentState;
							} else {
								invalidChar(char);
							}

						case ValueState:
							state = CommentState;	
					}
					continue;

				default:
					if ((char >= 'A'.code && char <= 'Z'.code)
						|| (char >= 'a'.code && char <= 'z'.code)
						|| (char >= '0'.code && char <= '9'.code)
						|| (char == "_".code)
						|| (char == "#".code)
						|| (char == " ".code)) {
						switch (state) {
							case KeyState:
								key += String.fromCharCode(char);
							case ValueState:
								value += String.fromCharCode(char);
							case CommentState:
								comment += String.fromCharCode(char);
						}
					} else {
						invalidChar(char);
					}
			}
		}
		return;
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

	function appendComment() {
		if (comment != "") {
			tokens.push(Comment(comment));
			comment = "";
		}
	}

	function appendKey() {
		final trimmedKey:String = StringTools.trim(key);
		tokens.push(Key(trimmedKey));
		tokens.push(Equals);
		key = "";
	}

	function appendValue() {
		final trimmedValue:String = StringTools.trim(value);
		tokens.push(Value(trimmedValue));
		value = "";
	}

	function isWhiteSpace(char:String):Bool {
		var r = new EReg(whiteSpaceCharacter, "g");

		return r.match(char);
	}

	function invalidChar(char) {
		trace("Unexpected char:" + String.fromCharCode(char));
	}
}
