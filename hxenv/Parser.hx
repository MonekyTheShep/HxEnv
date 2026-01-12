package hxenv;

import hxenv.Lexer.Token;


// basic parser
class Parser {
    public static function parseString(string:String):Env {
        var lexer:Lexer = new Lexer();
        var tokens = lexer.lex(string);
        trace(tokens);
		return parse(tokens);
	}

    public static function parse(tokens:Array<Token>):Env
    {
        var env = new Env();

        var tokenIndex:Int = 0;
        while (tokenIndex < tokens.length) {
            switch tokens[tokenIndex] {
                case Key(key):
                    tokenIndex++;
                    if (tokenIndex >= tokens.length || tokens[tokenIndex] != Equals) {
                        throw "No equals sign after key";
                    }
                    tokenIndex++;

                    switch (tokens[tokenIndex]) {
                        case Value(value):
                            env.set(key, value);
                        default:
                    }

                case Comment(value):
                    env.addComment(value);
                    tokenIndex++;

                case Newline:
                    // skip token
                    // or should i add a new line entry type?
                    trace("Found new line");
                    tokenIndex++;
                    
                default:
                    tokenIndex++;   
            }
        }

        return env;
    }
}