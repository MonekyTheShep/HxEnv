import hxenv.Env;
import hxenv.Printer;
import hxenv.Parser;
import sys.io.File;


class Main {
    static function main() {

        
        var content:String = File.getContent("test.env");
        // hm
        var start = haxe.Timer.stamp();


        var env:Env = Parser.parseString(content);

        trace(env.get("KEY"));
        trace(env.has("KEY"));
        trace(env.getAll());

        var string = Printer.serialize(env);

        var out = File.write(Sys.getCwd() + '/testout.env');
        
        try {
            out.writeString(string);

            out.flush();
            out.close();
        } 
        catch (e:Dynamic) {
            trace("Error: " + e);
        }
        
        var end = haxe.Timer.stamp();
        // find difference between end and start
		var elapsed = end - start;
        trace("Elapsed time: " + elapsed + " seconds");
    }
}