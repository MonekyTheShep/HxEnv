import hxenv.Env;
import sys.io.File;


class Main {
    static function main() {        
        var content:String = File.getContent("test.env");

        var env:Env = Env.fromString(content);

        trace(env.get("KEY"));
        trace(env.get("KEY2"));

        env.set("€", "gay");

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
