import hxenv.Lexer;
import hxenv.Env;
import hxenv.Printer;
import hxenv.Parser;
import sys.io.File;


class Main {
    static function main() {        
        var content:String = File.getContent("test.env");

        var parser:Parser = new Parser();

        var env:Env = Env.fromString(content);

        trace(env.get("KEY"));
        trace(env.get("KEY2"));

        var out = File.write(Sys.getCwd() + '/testout.env');
        
        try {
            out.writeString(env.toString());

            out.flush();
            out.close();
        } 
        catch (e:Dynamic) {
            trace("Error: " + e);
        }
        
    }
}
