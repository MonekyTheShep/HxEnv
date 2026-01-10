import sys.io.File;
import hxenv.Lexer;

class Main {
    static function main() {
        var lexer:Lexer = new Lexer();

        var content:String = File.getContent("test.env");
        trace(lexer.lex(content));
    }
}