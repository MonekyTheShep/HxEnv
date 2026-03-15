package hxenv;

import hxenv.types.NodeType.KeyValueVariant;
import haxe.extern.EitherType;
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
       
        var result = readValue();

        return Env.createKey(key, result.value, result.variant);
    }

    function readKey():String {
        return switch consumeToken() { // Consume Key
            case Key(key): key;
            default: "";
        };
    }

    function readValue():{value : String, variant : KeyValueVariant} {
        expect(Equals, 'Expected EQUALS sign after KEY at line ${lineNo}'); // Consume Equals
        
        var valueToken = expect([Value(""), SingleQuote(""), DoubleQuote("")], 'Expected VALUE after EQUALS at line ${lineNo}'); // Consume Value

        return switch valueToken {
            case Value(value):
                {value: value, variant: Raw}; 
            case SingleQuote(value):
                {value: value, variant: SingleQuote}; 
            case DoubleQuote(value):
                {value: value, variant: DoubleQuote}; 
            default: {value: "", variant: Raw};
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
    function expect(expected:EitherType<Token, Array<Token>>, ?err:String):Token {
		final token:Token = consumeToken();

        var containExpected:Bool = false;
        if (Std.isOfType(expected, Array)) {
            var tokens:Array<Token> = expected;
            for (t in tokens) {
                if (t.getIndex() == token.getIndex()) {
                    containExpected = true;
                    break;
                }
            }
            
        } else {
            var t:Token = expected;
            if (t.getIndex() == token.getIndex()) containExpected = true;
        }
        
        if (!containExpected) {
            if (err != null) throw err;
            if (Std.isOfType(expected, Array)) {
                throw 'Expected tokens ${expected} but received ${token.getName()} at line ${lineNo}';
            }

            if (Std.isOfType(expected, Token)) {
                throw 'Expected token ${expected.getName()} but received ${token.getName()} at line ${lineNo}';
            }

            return null;    
        } else {
            return token;
        }
	}
}