package hxenv;

enum Token {
	Key(key:String); // 𝑥 = 𝑦
	Value(value:String); // 𝑥 = 𝑦
	Comment(value:String); // # {comment}
	Equals; // = 
	Newline; // \n
	Eof; // end of file
} 

enum LexerState {
	KeyState; // key gets appended into key buffer
	ValueState; // values gets appended into value buffer
	CommentState; // comments get appended into comment buffer
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
	var lineNo:Int = 1;

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
		this.lineNo = 1;

		// loop through chars appending tokens until no more
		tokenize();

		return tokens;
	}

	function tokenize() {
		var hasKey = false;
		var hasComment = false;
		trace(lineNo);

		while (true) {
			// if reached end break loop;
			if (this.pos >= query.length) {
				// when reached finalise
				// add value if it has key
				if (hasKey) {
					appendValue();
				}

				// append any comments before end
				if (hasComment)
					appendComment();

				tokens.push(Eof);
				break;
			}

			var char = nextChar();

			switch (char) {
				// when new line is found append the value or comment and then reset back to default state
				case '\n'.code:
					if (state == ValueState && hasKey) {
						appendValue();
						hasKey = false;
					} 

					if (state == CommentState && hasComment) {
						appendComment();
						hasComment = false;
					}

					// default state is key state
					state = KeyState;
					key = "";
					value = "";
					hasComment = false;
					hasKey = false;

					tokens.push(Newline);
					lineNo++;
					trace(lineNo);

					continue;

				// switch the state to value when found "="
				case '='.code:
					// append the key when = is found if its not empty
					// if this a comment state ignore this and add to comment
					if (state != CommentState) {
						if (state == KeyState && key != "") {
							appendKey();
							hasKey = true;
						} else if (state == ValueState) {
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
							state = CommentState;
							comment += String.fromCharCode(char);
						case KeyState:
							// cant have # inside of key
							if (key == "") {
								hasComment = true;
								state = CommentState;
							} else {
								invalidChar(char);
							}

						case ValueState:
							hasComment = true;
							state = CommentState;
					}
					continue;

				default:
					if ((char >= 'A'.code && char <= 'Z'.code)
						|| (char >= 'a'.code && char <= 'z'.code)
						|| (char >= '0'.code && char <= '9'.code)
						|| (char == "_".code)
						|| (char == '"'.code)
						|| (char == "'".code)
						|| (char == " ".code)
						|| (char == ".".code)) {
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
		tokens.push(Comment(comment));
		comment = "";
	}

	function appendKey() {
		final trimmedKey:String = StringTools.trim(key);
		tokens.push(Key(trimmedKey));
		tokens.push(Equals);
		key = "";
	}

	// quotation handling

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
