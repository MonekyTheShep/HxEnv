package hxenv.types;

// Root -> Document -> List of NodeTypes
enum NodeType {
   Document;
   Comment;
   KeyValue(variant:KeyValueVariant);
}

enum KeyValueVariant {
   Raw;
   SingleQuote;
   DoubleQuote;
}