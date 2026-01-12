package hxenv.types;

enum EntryType {
    // root
    Document(children:Array<EntryType>);

    // children
    Entry(key:String, value:String);
    Comment(text:String);
}