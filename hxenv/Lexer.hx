package hxenv;

enum Token {
	Key(key:String); // 𝑥 = 𝑦
	Value(value:String); // 𝑥 = 𝑦
	Comment(value:String); // # {comment}
	Equals; // =
	Comma; // ,
	Newline; // \n
	Eof; // end of file
}

// complex rules
enum LexerState {
	KeyState;
	ValueState;
	CommentState;
}

class Lexer {
	var query:String;
	var pos:Int;
	var lineNo:Int;
	var state:LexerState = KeyState;

	// valid chars
	var idChar:Array<Bool>;

	// buffers used because we have states for the lexer to add to these buffers
	var keyBuf = new StringBuf();
	var valueBuf = new StringBuf();
	var commentBuf = new StringBuf();
	var tokenQueue:Array<Token> = [];

	var done:Bool = false;

	// flags for each line
	var hasComment:Bool = false;
	var hasKey:Bool = false;

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
		// normalise new line between windows and unix systems
		this.query = StringTools.replace(query, "\r\n", "\n");
		this.pos = 0;
		this.lineNo = 1;

		var result = [];
		while (true) {
			var t = token();

			if (t == Eof) {
				result.push(t);
				break;
			}

			result.push(t);
		}
		return result;
	}

	function token() {
		// use this to build line tokens
		function addTokenQueue() {
			// debug lines
			if (keyBuf.length != 0) {
				// trace("Key: ", keyBuf.toString());
				// trace("Value: ", valueBuf.toString());
			}

			// make functions to handle key, value

			if (keyBuf.length > 0) {
				final trimmedKey:String = StringTools.trim(keyBuf.toString());
				tokenQueue.push(Key(trimmedKey));
				tokenQueue.push(Equals);
				final trimmedValue:String = StringTools.trim(valueBuf.toString());
				tokenQueue.push(Value(trimmedValue));
			} else if (!hasComment) {
				throw "Cant have empty key";
			}

			if (commentBuf.length != 0) {
				tokenQueue.push(Comment(commentBuf.toString()));
				hasComment = false;
			}
		}

		while (true) {
			if (tokenQueue.length > 0) {
				// returns the first element so it builds the tokens in order.
				return tokenQueue.shift();
			}

			if (this.pos >= query.length) {
				// add remaining tokens

				if (done == true) {
					return Eof;
				} else {
					done = true;
					if (state == ValueState) {
						addTokenQueue();
					}
				}
			}

			var char = nextChar();

			switch (char) {
				case '\n'.code:
					lineNo++;

					if (state != KeyState) {
						addTokenQueue();
					}

					state = KeyState;

					resetBuffers();

					tokenQueue.push(Newline);

				case "=".code:
					if (state == KeyState) {
						state = ValueState;
					} else if (state == ValueState) {
                        throw "Cant have more than one equal sign";
						//valueBuf.addChar(char);
					} else if (state == CommentState) {
						commentBuf.addChar(char);
					}

				case '"'.code, "'".code:
					// look until it finds a closing quote or \n
					// right now ill just make it throw an error i cant be asked to handle it

				case "#".code:
					// need to add comment validation
					if (state == CommentState) {
						commentBuf.addChar(char);
					} else if (state == KeyState) {
						// cant have # inside of key
						if (keyBuf.toString() == "") {
							hasComment = true;
							state = CommentState;
						} else {
							throw "You idiot you cant have a # before the value.";
						}
					} else if (state == ValueState) {
						hasComment = true;
						state = CommentState;
					}

				// look until it finds the end line

				case ",".code:
					// look until end

				default:
					if (char != null) {
						if ((idChar[char]) || (char == "_".code) || (char == '"'.code) || (char == "'".code) || (char == " ".code) || (char == ".".code)) {
							switch state {
								case KeyState:
									keyBuf.addChar(char);
								case ValueState:
									valueBuf.addChar(char);
								case CommentState:
									commentBuf.addChar(char);
							}
						}
					}
			}
		}
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

	function resetBuffers() {
		keyBuf = new StringBuf();
		valueBuf = new StringBuf();
		commentBuf = new StringBuf();
	}
}
