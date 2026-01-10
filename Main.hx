import sys.io.File;
import hxenv.Lexer;

class Main {
    static function main() {
        var lexer:Lexer = new Lexer();

        
        var content:String = File.getContent("test.env");
        // hm
        var start = haxe.Timer.stamp();
        trace(lexer.lex(content));

        var end = haxe.Timer.stamp();
		var elapsed = end - start;
        trace("Elapsed time: " + elapsed + " seconds");
    }
}