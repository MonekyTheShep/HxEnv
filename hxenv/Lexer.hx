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
// add multiline state
enum LexerState {
	KeyState;
	ValueState;
	CommentState;
	QuoteState;
}

class Lexer {
	var query:String;
	var pos:Int;
	var lineNo:Int;
	var state:LexerState = KeyState;
	public var verboseMode:Bool = false;

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

	// should i make it a state?
	var multiLines = false;
	var nextMultiLine = false;

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
			if (keyBuf.length != 0 && verboseMode == true) {
				trace("Key: ", keyBuf.toString());
				trace("Value: ", valueBuf.toString());
			}
		
			// if the key is valid emit the key and value
			if (hasKey) {
				emitKeyAndValue();
			}
			// for multiline support
			// if there is a multiline emit value on its own

			if (nextMultiLine && hasComment) {
				throw "Cant have comment in multiline";
			} else if (nextMultiLine) {
				emitValue();
			}

			// if a comment is valid emit it
			if (hasComment) {
				emitComment();
			}
		}

		while (true) {
			if (tokenQueue.length > 0) {
				// returns the first element so it builds the tokens in order.
				return tokenQueue.shift();
			}

			if (this.pos >= query.length) {
				// add remaining tokens when reached end line

				if (done == true) {
					return Eof;
				} else {
					done = true;
					if (keyBuf.length > 0 && !hasKey) {
						throw "No equals sign after key, cant build KEY=VALUE";
					}

					if (state == CommentState || state == ValueState) {
						addTokenQueue();
					}
					
				}
			}

			var char = nextChar();

			switch (char) {
				case '\n'.code:
					lineNo++;

					if (keyBuf.length > 0 && !hasKey) {
						throw "No equals sign after key, cant build KEY=VALUE";
					}

					// i need add detection for when a key is empty
					if (state == CommentState || state == ValueState) {
						addTokenQueue();
					}

					// default state is key state
					if (multiLines) {
						state = ValueState;
						tokenQueue.push(Comma);

						multiLines = false;
						// bool to make sure next line doesnt have comment
						// you cant have comments on multilines
						nextMultiLine = true;
					} else {
						state = KeyState;
					}

					resetBuffers();

					tokenQueue.push(Newline);

				case "=".code:
					if (state == KeyState) {
						if (keyBuf.length == 0) {
							throw "Cant have empty key";
						}
						state = ValueState;
						hasKey = true;
					} else if (state == ValueState) {
						throw "Cant have more than one equal sign";
						// valueBuf.addChar(char);
					} else if (state == CommentState) {
						commentBuf.addChar(char);
					}

				case '"'.code, "'".code:
					throw "fuck you im not handling quotes";
				// look until it finds a closing quote or \n
				// right now ill just make it throw an error i cant be asked to handle it

				case "#".code:
					// need to add comment validation
					if (state == CommentState) {
						commentBuf.addChar(char);
					} else if (state == ValueState) {
						hasComment = true;
						state = CommentState;
					} else if (state == KeyState) {
						if (keyBuf.length == 0) {
							hasComment = true;
							state = CommentState;
						} else {
							throw "You idiot you cant have a # before the value.";
						}
					}

				// look until it finds the end line

				case ",".code:
					throw "multi line support added next update iteration";
					if (state == ValueState || state == KeyState) {
						var tempPos:Int = pos;
						// peak ahead system until reached valid character

						var tempChar = query.charAt(tempPos);
						while (tempPos < query.length) {
							if (tempChar == "\n") {
								break;
							} else if (tempChar == " " || tempChar == "") {
								tempPos++;
								continue;
							} else if (tempChar == "#") {
								// ignore comment line since all values after it are ignored
								break;
							} else {
								throw("Invalid multi line at " + lineNo);
							}
						}

						multiLines = true;
					} else if (state == CommentState) {
						commentBuf.addChar(char);
					}

				default:
					if (char != null) {
						if ((idChar[char]) || (char == "_".code) || (char == " ".code) || (char == ".".code)) {
							switch state {
								case KeyState:
									if (char != " ".code) keyBuf.addChar(char);
								case ValueState:
									valueBuf.addChar(char);
								case CommentState:
									commentBuf.addChar(char);
								case QuoteState:
							}
						}
					}
			}
		}
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

	function emitKeyAndValue() {
		final trimmedKey:String = StringTools.trim(keyBuf.toString());
		tokenQueue.push(Key(trimmedKey));
		tokenQueue.push(Equals);
		final trimmedValue:String = StringTools.trim(valueBuf.toString());
		tokenQueue.push(Value(trimmedValue));
		hasKey = false;
	}

	function emitComment() {
		tokenQueue.push(Comment(commentBuf.toString()));
		hasComment = false;
	}

	function emitValue() {
		final trimmedValue:String = StringTools.trim(valueBuf.toString());
		tokenQueue.push(Value(trimmedValue));
		nextMultiLine = false;
	}

	// buffers reset every line

	function resetBuffers() {
		keyBuf = new StringBuf();
		valueBuf = new StringBuf();
		commentBuf = new StringBuf();
	}
}
