package hxenv;

import hxenv.types.EntryType;


class Env {
    public var root:EntryType;

    public function new() {
       this.root = Document([]);
       // children get added to root
    }

    public function set(key:String, value:String):Void {
        if (key == "") throw "Cant set empty key";
        switch (root) {
            case Document(children):
                // loop through index of children
                for (childIndex => child in children) {
                    switch child {
                        case Entry(k, v):
                            if(key == k) {
                                // overwrite element with index of the child with new entry if key is the same
                                children[childIndex] = Entry(key, value);
                                return;
                            }
                        default:
                    }
                    
                }

                children.push(Entry(key, value));
            default:
        }
    }

    public function addComment(text:String) {
        switch (root) {
            case Document(children):
                children.push(Comment(text));
            default:
        }
    }

    public function get(key:String):String {
        switch (root) {
            case Document(children):
                for (child in children) {
                    switch child {
                        case Entry(k, v):
                            if (key == k) {
                                return v;
                            }
                        default:
                    }
                }
            default:
        }
        return null;
    }

    public function has(key:String):Bool {
        switch (root) {
            case Document(children):
                for (child in children) {
                    switch child {
                        case Entry(k, v):
                            if (key == k) {
                                return true;
                            }
                        default:
                    }
                }
            default:
        }
        return false;
    }

    public function getAll():EntryType {
        return root;
    }

    public function toString():String {
		return Printer.serialize(this);
	}

}

