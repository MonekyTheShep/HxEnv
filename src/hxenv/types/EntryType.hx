package hxenv.types;

// Root -> Document -> Array of NodeTypes
enum abstract EntryType(Int) {
   final Document:EntryType = 1;  
   final Comment:EntryType = 2;
   final KeyValue:EntryType = 3;
   //final Section:EntryType = 4;

   // add string values later
}