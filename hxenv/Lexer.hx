package hxenv;

// should i make a token for double and single quote states?
enum Token {
	Key(key:String); // 𝑥 = 𝑦
	Equals; // =
	Value(value:String); // 𝑥 = 𝑦
	
	InterpolatedValue(values:Array<Token>); // holds values that can contain key as ${key}
	NonInterpolatedValue(value:String); // holds literal values
	Backtick(multilines:Array<String>); // holds multiple lines

	Comment(value:String); // # {comment}
	Newline; // \n
	Eof; // end of file
}

// complex rules
// add multiline state
enum LexerState {
	KeyState;
	ValueState;
	CommentState;
	// everything inside is treated as a string
	SingleQuoteState;
	// may contain variables
	DoubleQuoteState;
	// for multi line
	Backtick;
}

class Lexer {
	var query:String;
	var pos:Int;
	var lineNo:Int;
	var char:Null<Int>;
	var state:LexerState;

	// is lexing done?
	var done:Bool;

	public var verboseMode:Bool;

	// valid chars
	static var idChar:Map<Int, Bool> = populateValidChars();

	// buffers used because we have states for the lexer to add to these buffers
	var keyBuf:StringBuf;
	var valueBuf:StringBuf;
	var commentBuf:StringBuf;
	var tokenQueue:Array<Token>;
	// var singleQuoteBuf = new StringBuf();
	// var doubleQuoteBuf = new StringBuf();
	
	// flags for each line
	var hasComment:Bool;
	var hasKey:Bool;

	public function new(?verboseMode:Bool) {
		this.verboseMode = false;
	}

	public function lex(query:String):Array<Token> {
		// normalise new line between windows and unix systems
		this.query = StringTools.replace(query, "\r\n", "\n");
		this.pos = 0;
		this.lineNo = 1;
		this.state = KeyState;

		this.done = false;
		this.hasComment = false;
		this.hasKey = false;

		this.keyBuf = new StringBuf();
		this.valueBuf = new StringBuf();
		this.commentBuf = new StringBuf();
		this.tokenQueue = new Array<Token>();

		

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

	static function populateValidChars():Map<Int, Bool> {
		var idChar = new Map<Int, Bool>(); 

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

		idChar["_".code] = true;
		idChar[" ".code] = true;
		idChar[".".code] = true;
		idChar[0] = true;
		return idChar;
	}

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

		// if a comment is valid emit it
		if (hasComment) {
			emitComment();
		}
	}

	function token() {
		while (true) {
			// use this to build line tokens
			if (tokenQueue.length > 0) {
				// returns the first element so it builds the tokens in order.
				return tokenQueue.shift();
			}

			if (this.pos >= query.length) {
				// add remaining tokens when reached end line

				if (done == true) {
					return Eof;
				} 
			
				if (keyBuf.length > 0 && !hasKey) {
					throw "No equals sign after key, cant build KEY=VALUE";
				}

				done = true;
				if (state == CommentState || state == ValueState) {
					addTokenQueue();
				}
				
			}

			char = nextChar() ?? 0;

			switch (char) {
				case '\n'.code:
					handleNewLine();
				case "=".code:
					handleEquals();
				case "#".code:
					handleComment();
				case "`".code:
					throw "multi line support added next update iteration";
					handleBackTick();
				// look until it finds a closing quote or \n
				// right now ill just make it throw an error i cant be asked to handle it
				case '"'.code, "'".code:
					throw "fuck you im not handling quotes";

				default:
					if (!(idChar[char])) {
						invalidChar(char);
					}

					switch state {
						case KeyState:
							if (char != " ".code) keyBuf.addChar(char);
						case ValueState:
							valueBuf.addChar(char);
						case CommentState:
							commentBuf.addChar(char);
						default:
					}
			}
		}
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

	function handleNewLine() {
		lineNo++;

		if (keyBuf.length > 0 && !hasKey) {
			throw "No equals sign after key, cant build KEY=VALUE";
		}

		// i need add detection for when a key is empty
		if (state == CommentState || state == ValueState) {
			addTokenQueue();
		}

		state = KeyState;

		resetBuffers();

		tokenQueue.push(Newline);
	}

	function handleEquals() {
		if (keyBuf.length == 0 && state == KeyState) {
			throw "Cant have empty key";
		}

		if (state == ValueState) {
			throw "Cant have more than one equal sign";
		}
		
		if (state == CommentState) {
			commentBuf.addChar(char);
		} else if (state == KeyState) {
			state = ValueState;
			hasKey = true;
		}
	}

	function handleComment() {
		if (state == KeyState && keyBuf.length != 0) {
			throw "You cant have a comment inside of a key.";
		}

		if (state == CommentState) {
			commentBuf.addChar(char);
		} else if (state == ValueState) {
			hasComment = true;
			state = CommentState;
		} else if (state == KeyState) {
			hasComment = true;
			state = CommentState;
		}
	}

	function handleBackTick() {
		if (state == ValueState && valueBuf.length != 0) {
			throw "Can't have characters before backtick.";
		}

		if (state == CommentState) {
			commentBuf.addChar(char);
		} else if (state == ValueState) {
			state = Backtick;
		}

		// if (state == ValueState || state == KeyState) {
		// 	var tempPos:Int = pos;
		// 	// peak ahead system until reached valid character

		// 	var tempChar = query.charAt(tempPos);
		// 	while (tempPos < query.length) {
		// 		if (tempChar == "\n") {
		// 			break;
		// 		} else if (tempChar == " " || tempChar == "") {
		// 			tempPos++;
		// 			continue;
		// 		} else if (tempChar == "#") {
		// 			// ignore comment line since all values after it are ignored
		// 			break;
		// 		} else {
		// 			throw("Invalid multi line at " + lineNo);
		// 		}
		// 	}

		// 	multiLines = true;
		// } else if (state == CommentState) {
		// 	commentBuf.addChar(char);
		// }
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
	}

	// buffers reset every line

	function resetBuffers() {
		keyBuf = new StringBuf();
		valueBuf = new StringBuf();
		commentBuf = new StringBuf();
	}

	inline function invalidChar(c) {
		throw "Unexpected char '" + String.fromCharCode(c) + "'";
	}
}
