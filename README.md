# HxEnv

.ENV File Parser which supports multi line and variable interpolation.

## Variable Interpolation using ${}
```
KEY=VALUE
KEY2="${KEY}"
```

## Multi Line using Double Quotes.
```
KEY="THIS IS
MULTI LINE SUPPORT"
```


## "example.env" File
```
KEY=VALUE
```

## Modify or Access Existing Env Files
```haxe
var content:String = File.getContent("example.env");
var parser:Parser = new Parser();

var env:Env = parser.parseString(content);

// returns the value of a key
trace(env.get("KEY")); // VALUE

var string:String = env.toString();

var out = File.write("exampleout.env");
        
try {
    out.writeString(string);

    out.flush();
    out.close();
} 
catch (e:Dynamic) {
    trace("Error: " + e);
}
```


## Create Env Files
```haxe

var env = new Env();

env.set("KEY", "VALUE", DoubleQuote);
env.addComment("Comment");
env.get("KEY"); // VALUE

var string:String = env.toString(); // output serialised env

var out = File.write("exampleout.env");
        
try {
    out.writeString(string);

    out.flush();
    out.close();
} 
catch (e:Dynamic) {
    trace("Error: " + e);
}

```
