package hxenv;

import hxenv.types.EntryType;

class Env {
	// stores the previous instance reference
	public var parent:Null<Env>;

	// node type is read only
	public var nodeType(default, null):Null<EntryType>;

	// values of node for keyvalue and comment
	public var nodeName:Null<String>;
	public var nodeValue:Null<String>;

	// array of children instances
	public var children:Array<Env>;

	public function new(type:EntryType, ?name:String, ?value:String):Void {
		this.nodeType = type;
		this.nodeName = name;
		this.nodeValue = value;
		this.children = new Array<Env>();
	}

    public static function createDocument():Env {
        return new Env(Document);
    }

    public static function createKey(k:String, v:String):Env {
        return new Env(KeyValue, k, v);
    }

    public function addChild<T:Env>(x:T):T {
        // returns if the child is disposed
        if (__disposed) {
            return null;
        }
        if (x.parent != null) {
            x.parent.removeChild(x);
        }
        children.push(x);
        x.parent = this;
        return x;
    }

    public function removeChild(x:Env):Bool {
        // add disposed part
        if(!__disposed && children.remove(x)) {
            x.parent = null;
            return true;
        }

        return false;
    }

    var __disposed:Bool = false;

    public function dispose():Void {
        if (__disposed) {
            return;
        }

        // loop through nodes children disposing of all
        if (children != null && children.length > 0) {
            for (child in children) {
                if (child != null) {
                    child.dispose();
                }
            }
        }

        parent = null;
        nodeName = null;
        nodeValue = null;
        nodeType = null;
        children = null;

        __disposed = true;


    }

    public function get(name:String):Null<String> {
        if (nodeType == Document) {
            for (child in children) {
                if (child != null && child.nodeType == KeyValue && child.nodeName == name) {
                    return child.nodeValue;
                }
            }
        }
        return null;
    }

    public function set(name:String, value:String):Void {
        if (nodeType == Document) {
            for (child in children) {
                if (child.nodeType == KeyValue && child.nodeName == name) {
                    // if it exists overwrite it
                    child.nodeValue = value;
                    return;
                }
            }
            addChild(createKey(name, value));
        }
    }


    public function comment(value:String):Void {
        addChild(new Env(Comment, null, value));
    }
    

    public function toString():String {
		return Printer.serialize(this);
	}


    // add iterators later
}


