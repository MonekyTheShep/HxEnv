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
                    nextToken();
                    env.addChild(new Env(Comment, null, value));
            
                case Equals:
                    if (pos == 0) throw 'Unexpected equals! Expected KEY before EQUALS at line ${lineNo}';
                    if (Type.enumIndex(tokens[pos - 1]) != Type.enumIndex(Key(""))) throw 'Unexpected equals! Expected KEY before EQUALS at line ${lineNo}';

                case Newline:
                    lineNo++;
                    nextToken();

                default:
                    nextToken();
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
        return switch peekToken() {
            case Key(key): key;
            default: "";
        };
    }

    function readValue():String {
        expect(Equals, 'No EQUALS sign after KEY at line ${lineNo}');

        expect(Value(""), 'Expected VALUE after EQUALS at line ${lineNo}');
        
        return switch peekToken() {
            case Value(value): value;
            default: "";
        } 
    }

    inline function peekToken():Token {
        return tokens[pos];
    }

    inline function nextToken():Token {
        return tokens[pos++];
    }

    /**
        Checks if the next token meets the expected token by comparing the enum index.
    **/
    function expect(expected:Token, ?err:String):Void {
		nextToken();
    
		if (Type.enumIndex(peekToken()) != Type.enumIndex(expected)) {
            if (err == null) throw 'Expected token ${expected} but received ${peekToken()} at line ${lineNo}';
            
            throw err;
        };
	}
}