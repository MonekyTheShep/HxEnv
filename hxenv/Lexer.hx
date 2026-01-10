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

		// loop through chars appending tokens until no more
		tokenize();

		return tokens;
	}

	function tokenize() {
		while (true) {
			// if reached end break loop;
			if (this.pos >= query.length) {
				// when reached finalise

				// should i add empty key?
				// if (key != "") {
				// 	appendKey();
				// }

				if (value != "") {
					appendValue();
				}

				if (comment != "") {
					appendComment();
				}

				tokens.push(Eof);
				break;
			}

			var char = nextChar();

			trace(state);

			switch (char) {
				// switch the state to value when found "="
				case '='.code:
					// if key state append key to cache
					// if value state append equals to the value
					if (state == KeyState || key != "") {
						appendKey();
					} else if (state == ValueState) {
						value += String.fromCharCode(char);
					}

					state = ValueState;
					continue;

				// switch the state to key state when newline found
				case '\n'.code:
					// push value before new line
					if (state == ValueState || value != "") {
						appendValue();
					}

					if (state == CommentState || comment != "") {
						appendComment();
					}

					state = KeyState;

					tokens.push(Newline);
					continue;

				// // switch to comment state
				// case '#'.code:
				// 	// make sure no idiot can stick # in the middle of a value
				// 	if (state == KeyState || key != "") {
				// 		state = CommentState;
				// 	} else if (state == ValueState) {
				// 		value += String.fromCharCode(char);
				// 	}

				// 	continue;

				default:
					if ((char >= 'A'.code && char <= 'Z'.code)
						|| (char >= 'a'.code && char <= 'z'.code)
						|| (char >= '0'.code && char <= '9'.code)
						|| (char == "_".code)) {
							switch (state) {
								case KeyState:
									key += String.fromCharCode(char);
								case ValueState:
									value += String.fromCharCode(char);
									
								case CommentState:
									comment += String.fromCharCode(char);
							}
						
					}
			}
		}
		return;
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

	function appendComment() {
		final trimmedComment:String = StringTools.trim(comment);
		tokens.push(Comment(trimmedComment));
		comment = "";
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
}
