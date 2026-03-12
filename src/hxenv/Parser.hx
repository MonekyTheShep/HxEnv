package hxenv;

import hxenv.Lexer.Token;


class Parser {
    static var lexer:Lexer = new Lexer();
    public static function parseString(string:String):Env {
        var tokens = lexer.lex(string);
        trace(tokens);
		return parse(tokens);
	}

    public static function parse(tokens:Array<Token>):Env
    {
        var env:Env = Env.createDocument();

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
                            env.addChild(Env.createKey(key, value));

                        default:
                            throw "Expected VALUE after EQUALS";

                    }   

                case Comment(value):
                    env.addChild(new Env(Comment, null, value));
                    tokenIndex++;

                case Newline:
                    // skip token
                    // or should i add a new line entry type?
                    // trace("Found new line");
                    tokenIndex++;

                case Eof:
                    break;

                default:
                    tokenIndex++;   
            }
        }

        return env;
    }



}