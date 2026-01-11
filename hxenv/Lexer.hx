package hxenv;

import haxe.Rest;

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

    // buffers used because we have states for the lexer to add to these buffers

	var keyBuf = new StringBuf();
	var valueBuf = new StringBuf();
	var commentBuf = new StringBuf();
	var tokenQueue:Array<Token> = [];

	var done:Bool = false;
    var hasComment:Bool = false;

	public function new() {}

	public function lex(q:String):Array<Token> {
		// normalise new line between windows and unix systems
		this.query = StringTools.replace(q, "\r\n", "\n");
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
                trace("Key: ", keyBuf.toString());
			    trace("Value: ", valueBuf.toString());
            }
			

            // make functions to handle key, value, comments

            if (keyBuf.length != 0) {
                tokenQueue.push(Key(keyBuf.toString()));
			    tokenQueue.push(Equals);
			    tokenQueue.push(Value(valueBuf.toString()));
            } else if (!hasComment){
                throw "Empty Key";
            }
			
            if (commentBuf.length > 0) {
                tokenQueue.push(Comment(commentBuf.toString()));
                hasComment = false;
            } 
            
			tokenQueue.push(Newline);
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
					addTokenQueue();
					resetBuffers();

				}

                if (tokenQueue.length > 0) {
					return tokenQueue.shift();
				}
			}

			var char = nextChar();

			switch (char) {
				case '\n'.code:
					addTokenQueue();

					resetBuffers();

                    lineNo++;

					state = KeyState;

					return tokenQueue.shift();

				case "=".code:
					state = ValueState;

				case '"'.code, "'".code:
					// look until it finds a closing quote or \n

				case "#".code:
                    hasComment = true;
                    state = CommentState;
					// look until it finds the end line

                case ",".code:
                    // look until end 

				default:
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

	inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

	function resetBuffers() {
		keyBuf = new StringBuf();
		valueBuf = new StringBuf();
		commentBuf = new StringBuf();
	}
}
