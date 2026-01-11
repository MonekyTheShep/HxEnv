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

enum LexerState {
	KeyState; // key gets appended into key buffer
	ValueState; // values gets appended into value buffer
	QuoteState; // if inside of quotes
	CommentState; // comments get appended into comment buffer
}

class OldLexer {
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
	var keyBuf = new StringBuf();
	var valueBuf = new StringBuf();
	var commentBuf = new StringBuf();

	inline static final whiteSpaceCharacter:String = "\\s+";

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
		this.query = StringTools.replace(query, "\r\n", "\n");
		this.pos = 0;
		this.lineNo = 1;

		// loop through chars appending tokens until no more
		tokenize();

		return tokens;
	}

	function tokenize() {
		// bools for new line
		var hasKey = false;
		var hasComment = false;
		var multiLines = false;
		var continuedNextLine = false;

		function finaliseTokens() {
			// if a key is valid append the value to it else throw error
			if (hasKey) {
				appendValue();
				hasKey = false;
			} else if (keyBuf.toString() != "") {
				throw("Invalid key no equals sign at line " + lineNo);
			} 

			// append value for multi line
			
			if (valueBuf.toString() != "") {
				appendValue();
			}

			if (continuedNextLine && hasComment) {
				throw("Cant have comment in multiline");
			} else {
				continuedNextLine = false;
			}

			// default state is key state
			if (multiLines) {
				state = ValueState;
				appendMultiLine();
				continuedNextLine = true;
				multiLines = false;
			} else {
				state = KeyState;
			}

			// append any comments

			if (hasComment) {
				appendComment();
				hasComment = false;
			}
		}

		trace(lineNo);

		while (true) {
			// if reached end break loop;
			if (this.pos >= query.length) {
				// when reached finalise
				finaliseTokens();

				tokens.push(Eof);

				break;
			}

			var char = nextChar();

			switch (char) {
				// when new line is found append the value/comment/multiline tokens;
				case '\n'.code:
					finaliseTokens();

					resetBuffers();

					// reset bools
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
						if (state == KeyState && StringTools.trim(keyBuf.toString()) != "") {
							appendKey();
							hasKey = true;
						} else if (state == ValueState) {
							// append any other = to value
							valueBuf.addChar(char);
						} else if (StringTools.trim(keyBuf.toString()) == "") {
							throw("Cant have empty key at line " + lineNo);
							hasKey = false;
						}

						state = ValueState;
					} else {
						commentBuf.addChar(char);
					}

					continue;

				// switch to comment state
				case '#'.code:
					switch (state) {
						case CommentState:
							state = CommentState;
							commentBuf.addChar(char);
						case KeyState:
							// cant have # inside of key
							if (keyBuf.toString() == "") {
								hasComment = true;
								state = CommentState;
							} else {
								invalidChar(char);
							}

						case ValueState:
							hasComment = true;
							state = CommentState;

						case QuoteState:
					}
					continue;

				// currently comments will override the "" and mess up them so that values after the initial " are just comments
				case '"'.code, "'".code:
					if (state != CommentState) {
						state = QuoteState;
					} else {
						commentBuf.addChar(char);
					}
				// force scan of quotes to the end of line

				case ','.code:
					// if , after comment ignore it i also need to add check for if its at end of line
					// peak ahead of the pos until reach new line
					if (state != CommentState) {
						var tempPos:Int = pos;

						var onlyValidChar:Bool = true;

						// create temp pos to peak ahead of the comma to check if the next is a newline
						while (tempPos < query.length) {
							onlyValidChar = true;
							var tempChar = query.charAt(tempPos);

							if (tempChar == "\n") {
								onlyValidChar = true;
								break;
							} else if (tempChar == " " || tempChar == "") {
								tempPos++;
								continue;
							} else if (tempChar == "#") {
								// ignore comment line since all values after it are ignored
								onlyValidChar = true;
								break;
							} else {
								// this bool is useless since throw ends the program
								onlyValidChar = false;
								throw("Invalid multi line at " + lineNo);
							}
						}

						multiLines = onlyValidChar;
					} else {
						commentBuf.addChar(char);
					}

				// append characters to buffers
				default:
					if ((idChar[char]) 
						|| (char == "_".code) 
						|| (char == '"'.code) 
						|| (char == "'".code) 
						|| (char == " ".code) 
						|| (char == ".".code)) {
						switch (state) {
							case KeyState:
								if (char != " ".code) keyBuf.addChar(char);
							case ValueState:
								if (char != '"'.code || char != "'".code) valueBuf.addChar(char);
							case CommentState:
								commentBuf.addChar(char);
							case QuoteState:
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
		tokens.push(Comment(commentBuf.toString()));
		commentBuf = new StringBuf();
	}

	function appendKey() {
		final trimmedKey:String = StringTools.trim(keyBuf.toString());
		tokens.push(Key(trimmedKey));
		tokens.push(Equals);
		keyBuf = new StringBuf();
	}

	function appendValue() {
		final trimmedValue:String = StringTools.trim(valueBuf.toString());

		tokens.push(Value(trimmedValue));
		valueBuf = new StringBuf();
	}

	function appendMultiLine() {
		tokens.push(Comma);
	}

	function isWhiteSpace(char:String):Bool {
		var r = new EReg(whiteSpaceCharacter, "g");

		return r.match(char);
	}

	function resetBuffers() {
		keyBuf = new StringBuf();
		valueBuf = new StringBuf();
		commentBuf = new StringBuf();
	}

	function invalidChar(char) {
		throw "Unexpected char " + String.fromCharCode(char) + " at line " + lineNo;
	}
}
