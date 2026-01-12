package hxenv.types;

// represents an ast

// Root -> Document -> Array of Children
enum EntryType {
    // root
    Document(children:Array<EntryType>);

    // children
    Entry(key:String, value:String);
    Comment(text:String);
}