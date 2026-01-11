package hxenv;

class Env {
    var values:Map<String, String>;

    public function new() {
       values = new Map<String, String>();
    }

    public function set(key:String, value:String):Void {
        if value == null return;
        values.set(key, value);
    }

    public function get(key:String):String {
        if (values.exists(key)) {
            return values.get(key);
        }
    }

    public function has(key:String):Bool {
        return values.exists(key);
    }

    public function getAll():Map<String, String> {
        return values;
    }
}