package hxenv;

import hxenv.Utils.Util;

class Printer {
	static public function serialize(doc:Env):String {
        if (doc.nodeType != Document) throw "Serialize can only be used on Document Node!";

		final stringBuffer:StringBuf = new StringBuf();

		for (child in doc.children) {
            switch (child.nodeType) {
                case Comment:
                            stringBuffer.add("#" + child.nodeValue);
					        stringBuffer.add("\n");
                case KeyValue:
                            stringBuffer.add(child.nodeName + "=");
					        stringBuffer.add(Util.normaliseValue(child.nodeValue));
                            stringBuffer.add("\n");

                default:
            }
		}

		return stringBuffer.toString();
	}
}
