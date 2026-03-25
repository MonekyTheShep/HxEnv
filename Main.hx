import hxenv.Env;
import sys.io.File;


class Main {
    static function main() {        
        var content:String = File.getContent("test.env");

        var env:Env = Env.fromString(content);

        trace("KEY: " + env.get("KEY"));
        trace("KEY2: " + env.get("KEY2"));
        trace("KEY3: " + env.get("KEY3"));

        var out = File.write("testout.env");
        
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
