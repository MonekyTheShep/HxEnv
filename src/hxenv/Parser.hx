package hxenv;

import hxenv.Lexer.Token;

class Parser {
    var tokens:Array<Token>;
    var pos:Int;
    var lineNo:Int;
    
    public function new() {}

    public function parseString(string:String):Env {
        var lexer:Lexer = new Lexer();
		return parse(lexer.lex(string));
	}

    public function parse(args:Array<Token>):Env
    {
        this.pos = 0;
        this.lineNo = 1;
        this.tokens = args;
        trace(tokens);

        var env:Env = Env.createDocument();

        while (peekToken() != Eof) {
            switch peekToken() {
                case Key(_):
                    env.addChild(parseKeyValue());

                case Comment(value):
                    consumeToken();
                    env.addChild(new Env(Comment, null, value));
            
                case Equals:
                    throw 'Unexpected equals! Expected KEY before EQUALS at line ${lineNo}';

                case Value(_):
                    throw 'Unexpected VALUE! Expected KEY and EQUALS before VALUE at line ${lineNo}';

                case Newline:
                    lineNo++;
                    consumeToken();

                default:
                    consumeToken();
            }
        }

        return env;
    }

    function parseKeyValue():Env {
        var key:String = readKey();
       
        var value:String = readValue();

        return Env.createKey(key, value);
    }

    function readKey():String {
        return switch consumeToken() { // Consume Key
            case Key(key): key;
            default: "";
        };
    }

    function readValue():String {
        expect(Equals, 'Expected EQUALS sign after KEY at line ${lineNo}'); // Consume Equals
        
        var valueToken = expect(Value(""), 'Expected VALUE after EQUALS at line ${lineNo}'); // Consume Value

        return switch valueToken {
             case Value(value):
                value; 
            default: "";
        }
    }

    inline function peekToken():Token {
        return tokens[pos];
    }

    inline function consumeToken():Token {
        return tokens[pos++];
    }

    /**
        Checks if token meets the expected token by comparing the enum index while consuming token.
    **/
    function expect(expected:Token, ?err:String):Token {
		final token:Token = consumeToken();
    
		if (Type.enumIndex(token) != Type.enumIndex(expected)) {
            if (err != null) throw err;
            throw 'Expected token ${expected.getName()} but received ${token.getName()} at line ${lineNo}';
        } else {
            return token;
        }
	}
}