import hxenv.Lexer;
class Main {
    static function main() {
        var lexer:Lexer = new Lexer();

        trace(lexer.lex("GAY123=PENIS\nNIGGA321=TEST\nYAY=ENV\n"));
    }
}