package hxenv;

import hxenv.Lexer.Token;

class Parser {
    var lexer:Lexer;

    var previousToken:Token;
    var currentToken:Token;

    public function new(query:String) {
        this.lexer = new Lexer(query);
        advance();
    }

    public function parse():Dynamic {
        return parseSection();
    }

    function parseSection():Dynamic {
        var section:Dynamic = {};

        while (peek() != TEof) {
            parseStatement(section);
        }
        return section;
    }

    function parseStatement(section:Dynamic) {
        switch peek() {
            case TIdentifier(_):
                parseKey(section);
            case TNewline:
                advance();
            default:
                throw "Unexpected symbol!";
        }
    }

    function parseKey(section:Dynamic) {
        var key:String = expectIdentifier();
        expect(TEquals);
        var value:String = expectValue();
        expectTerminator();

        Reflect.setField(section, key, value);
    }

    inline function peek():Token {
        return currentToken;
    }

    inline function previous():Token {
        return previousToken;
    }

    inline function advance():Token {
        previousToken = currentToken;
        currentToken = lexer.token();

        while (currentToken.match(TComment(_))) {
            currentToken = lexer.token();
        }

        return currentToken;
    }

    function expectIdentifier():String {
        switch (peek())
        {
            case TIdentifier(val):
                advance();
                return val;
            default:
                throw "Expected identifier!";
        }

    }

    function expectValue():String {
        switch (peek())
        {
            case TString(val):
                advance();
                return val;
            default:
                throw "Expected value!";
        }

    }

    function expectTerminator() {
        switch (peek())
        {
            case TNewline:
                advance();
            case TEof:
                return;
            default:
                throw "Expected key value terminator!";
        }
    }

    function check(token:Token):Bool {
        return peek() == token;
    }

    function expect(expected:Token, ?err:String) {
		if (!check(expected)) {
            throw "Expected token!";
        }

        advance();
	}
}