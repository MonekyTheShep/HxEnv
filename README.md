# HxEnv

The beginning of a ENV file Parser


## TODO

```
Error checking move some outside of lexer
Multiline support
```


## Example Usage Parse and Access
```haxe
var content:String = File.getContent("example.env");
var env:Env = Parser.parseString(content);

var string = Printer.serialize(env);

var out = File.write(Sys.getCwd() + '/exampleout.env');
        
try {
    out.writeString(string);

    out.flush();
    out.close();
} 
catch (e:Dynamic) {
    trace("Error: " + e);
}
```


## Create Env File
```haxe

var env = new Env();

env.set("Key", "Value");
env.addComment("Comment");
env.get("Key"); // Value

trace(env.toString()); // output serialised env

```
