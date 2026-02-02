import hxenv.Env;
import hxenv.Printer;
import hxenv.Parser;
import sys.io.File;


class Main {
    static function main() {        
        var content:String = File.getContent("test.env");

        var env:Env = Parser.parseString(content);
        trace(env.get("KEY"));
        trace(env.get("KEY2"));

        // var string = Printer.serialize(env);

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
