import hxenv.Lexer;
class Main {
    static function main() {
        var lexer:Lexer = new Lexer();

        trace(lexer.lex("GAY=PENIS\nNIGGA=TEST\n"));
    }
}