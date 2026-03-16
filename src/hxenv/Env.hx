package hxenv;

import haxe.iterators.ArrayIterator;
import hxenv.types.NodeType;

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

	public var parent(default, null):Null<Env>;

	/**
	 * The type of this node which is read only
	 *
	 * Determines whether this node represents a `Document`,
	 * `KeyValue`, or `Comment`.  
	 * This value controls how the node behaves within the ENV tree and
	 * how it is serialized.
	 */
	public var nodeType(default, null):Null<NodeType>;

	/**
	 * The name associated with this node which is read only
	 *
	 * For `KeyValue` nodes, this is the key name.  
	 * It is typically `null` for `Document` and `Comment` nodes.
	 */
	public var nodeName(default, null):Null<String>;

	/**
	 * The value associated with this node which is read only
	 *
	 * Used primarily by `KeyValue` nodes to store the key's value.  
	 * `Document` node normally does not use this field, and it
	 * may also be used for comment text depending on the implementation.
	 */
	public var nodeValue(default, null):Null<String>;

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
	public function new(type:NodeType, ?name:String, ?value:String):Void {
		if(type.getIndex() == KeyValue().getIndex()) {
			if (name == null || value == null) throw "Name and Value required for KeyValue Node.";

			Utils.validateKey(name);

			switch (type) {
				case KeyValue(variant):
					switch (variant) {
						case Raw:
							Utils.validateRawValue(value, name);
						case SingleQuote:
							Utils.validateSingleQuotedValue(value, name);
						default: // Double Quote doesn't need validation due to it storing any character.
					}
				default:
			}
		}

		if(type == Comment) {
			if (value == null) throw "Value required for Comment Node.";

			Utils.validateComment(value);
		}


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
	public static function createKey(key:String, value:String, variant:KeyValueVariant):Env {
		return new Env(KeyValue(variant), key, value);
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
	public function addChild(x:Env):Env {
		// returns if the child is disposed
		if (__disposed) {
			return null;
		}

		// a child can only have one parent
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
	 * Looks up a key within a Document Node and returns its value.
	 *
	 * 
	 * @param name The key name.
	 * @return The value string, or `null` if the key does not exist.
	 */
	public function get(name:String):Null<String> {
		if (nodeType == Document) {
			for (child in children) {
				if (child != null && child.nodeType.getIndex() == KeyValue().getIndex()  && child.nodeName == name) {
					return child.nodeValue;
				}
			}
		}
		return null;
	}

	/**
	 * Set a Key with a Value within a Document Node
	 * @param name The name of the Key
	 * @param value The value.
	 * @param variant (Optional) Used to set the variant of a key.
	 */
	public function set(key:String, value:String, ?variant:KeyValueVariant):Void {
		if (nodeType == Document) {
			for (child in children) {
				if (child.nodeType.getIndex() == KeyValue().getIndex() && child.nodeName == key) {
					// if it exists overwrite it
					child.nodeValue = value;
					if (variant != null) child.nodeType = KeyValue(variant);
					return;
				}
			}
			if (variant == null) throw 'Variant needed to create new key: ${key}!';
			addChild(createKey(key, value, variant));
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
	public function toString():String {
		return Printer.serialize(this);
	}

	/**
	 * Convert's a Env string into a Env instance
	 * @return Env instance
	 */
	public static function fromString(string:String):Env {
		var parser:Parser = new Parser();
		return parser.parseString(string);
	}

	/**
	 * Filters through children looking for Comment Nodes.
	 * @return Array Iterator of Comment Nodes.
	**/
	public function comments():Iterator<Env> {
		return children.filter(child -> child.nodeType == Comment).iterator();
	}

	/**
	 * Filters through children looking for KeyValue Nodes.
	 * @return Array Iterator of KeyValue Nodes
	**/
	public function keyValues():Iterator<Env> {
		return children.filter(child -> child.nodeType.getIndex() == KeyValue().getIndex()).iterator();
	}
}
