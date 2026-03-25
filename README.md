# HxEnv

The beginning of a ENV file Parser


## TODO

```
Check for Edge cases
```


## Example Usage Parse and Access
```haxe
var content:String = File.getContent("example.env");
var parser:Parser = new Parser();

var env:Env = parser.parseString(content);

// returns the value of a key
trace(env.get("KEY"));

var string:String = env.toString();

var out = File.write("testout.env");
        
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

env.set("Key", "Value", DoubleQuote);
env.addComment("Comment");
env.get("Key"); // Value

var string:String = env.toString(); // output serialised env

var out = File.write("testout.env");
        
try {
    out.writeString(string);

    out.flush();
    out.close();
} 
catch (e:Dynamic) {
    trace("Error: " + e);
}

```
