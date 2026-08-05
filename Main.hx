import hxenv.Parser;
import sys.io.File;


class Main {
    static function main() {        
        var content:String = File.getContent("test.env");

        var parser:Parser = new Parser(content);

        var env:Dynamic = parser.parse();

        for (field in Reflect.fields(env))
        {
            trace(field);
            trace(Reflect.field(env, field));
        }
    }
}
