package hxenv;

import hxenv.types.EntryType;

/**
 * Represents a node inside of an **ENV** document tree.
 * Credit to HxMini for the AST
 * An `Ini` instance can be one of several types (`Document`,
 * `KeyValue`, `Comment`) and **may** contain children nodes. 
 * This class can be used to parse build, modify, and serialize ENV files.
 * 
 * The tree-like structure is mutable: each node holds a reference to its `parent`
 * and it's list of `children.
 * 
 * @see https://en.wikipedia.org/wiki/Env
 */

class Env {

	/**
    * Stores the previous node instance that created the child (itself);
    **/ 

	public var parent:Null<Env>;

	/**
	 * The type of this node which is read only
	 *
	 * Determines whether this node represents a `Document`,
	 * `KeyValue`, or `Comment`.  
	 * This value controls how the node behaves within the ENV tree and
	 * how it is serialized.
	 */
	public var nodeType(default, null):Null<EntryType>;

	/**
	 * The name associated with this node.
	 *
	 * For `KeyValue` nodes, this is the key name.  
	 * It is typically `null` for `Document` and `Comment` nodes.
	 */
	public var nodeName:Null<String>;

	/**
	 * The value associated with this node.
	 *
	 * Used primarily by `KeyValue` nodes to store the key's value.  
	 * `Document` node normally does not use this field, and it
	 * may also be used for comment text depending on the implementation.
	 */
	public var nodeValue:Null<String>;

	/**
	 * This instances children.
	 */
	public var children:Array<Env>;

	/**
	 * `hxEnv`'s constructor
	 * @param type Note Type (Document, Comment, KeyValue)
	 * @param name Name Currently unused
	 * @param value Value (Used for key values)
	 */
	public function new(type:EntryType, ?name:String, ?value:String):Void {
		this.nodeType = type;
		this.nodeName = name;
		this.nodeValue = value;
		this.children = new Array<Env>();
        this.__disposed = false;
	}

	/**
	 * Create a document.
	 * @return Env
	 */
	public static function createDocument():Env {
		return new Env(Document);
	}

	/**
	 * Create a key
	 * @param k The Key Name.
	 * @param v The Value.
	 * @return Env
	 */
	public static function createKey(k:String, v:String):Env {
		return new Env(KeyValue, k, v);
	}

	@:noCompletion var __disposed:Bool = false;

	/**
	 * Disposes this node and all of its descendants / children.
	 *
	 * After disposal, the node becomes unusable.
	 */
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

	/**
	 * Adds/Pushes a child into the tree.
	 * @param x child
	 */
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

	/**
	 * Removes a child from the children tree.
	 * @param x child
	 * @return Bool
	 */
	public function removeChild(x:Env):Bool {
		// add disposed part
		if (!__disposed && children.remove(x)) {
			x.parent = null;
			return true;
		}

		return false;
	}

	/**
	 * Looks up a key within this Document and returns its value.
	 *
	 * 
	 * @param name The key name.
	 * @return The value string, or `null` if the key does not exist.
	 */
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

	/**
	 * Set a Key and Value
	 * @param name The name of the variable
	 * @param value The value.
	 */
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

	/**
	 * Create a comment.
	 * @param value 
	 */
	public function comment(value:String):Void {
		addChild(new Env(Comment, null, value));
	}

	/**
	 * Convert's this into a readable string.
	 * @return String Value
	 */
	@:to public function toString():String {
		return Printer.serialize(this);
	}

	// add iterators later
}
