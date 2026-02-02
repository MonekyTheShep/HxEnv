package hxenv;

class Printer {
	static public function serialize(doc:Env):String {
		final stringBuffer:StringBuf = new StringBuf();

		for (child in doc.children) {
            switch (child.nodeType) {
                case Comment:
                            stringBuffer.add("#" + child.nodeValue);
					        stringBuffer.add("\n");
                case KeyValue:
                            stringBuffer.add(child.nodeName + "=");
					        stringBuffer.add(child.nodeValue);
                            stringBuffer.add("\n");

                default:
            }
		}

		return stringBuffer.toString();
	}
}
