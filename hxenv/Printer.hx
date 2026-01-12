package hxenv;

class Printer {
    static public function serialize(doc:Env):String {
        final stringBuffer:StringBuf = new StringBuf();

        switch (doc.root) {
            case Document(children):
                for (child in children) {
                    switch child {
                        case Comment(text):
                            stringBuffer.add("#" + text);
					        stringBuffer.add("\n");
                        case Entry(key, value):
                            stringBuffer.add(key + "=");
					        stringBuffer.add(value);
                            stringBuffer.add("\n");

                        default:
                    }
                }
            default:
        }
        return stringBuffer.toString();
    }
}