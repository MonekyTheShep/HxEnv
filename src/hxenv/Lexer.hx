enum Token {
    Section(section:String);
    Key(key:String);
    Value(value:String);
    Equals;
    Newline;
    Eof;
}

class Lexer {

    var query:String;

    // store current pos in query
    var pos:Int;

    // valid chars
    var idChar : Array<Bool>;

    // store current token from char
    var cache: Array<Token>;


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
        this.query = query;
        this.pos = 0;

        cache = [];
        var result = [];


        return result;
    }

}

