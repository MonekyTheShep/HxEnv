package hxenv;

class Printer {
	static public function serialize(doc:Env):String {
        if (doc.nodeType != Document) throw "Serialize can only be used on Document Node!";

		final stringBuffer:StringBuf = new StringBuf();

		for (child in doc.children) {
            switch (child.nodeType) {
                case Comment:
                            stringBuffer.add("#" + child.nodeValue);
					        stringBuffer.add("\n");
                case KeyValue(variant):
                            Utils.validateKey(child.nodeName);
                            stringBuffer.add(child.nodeName + "=");

                            switch (variant) {
                                case Raw:
                                    Utils.validateValue(child.nodeValue, child.nodeName);
                                    stringBuffer.add(child.nodeValue);
                                case DoubleQuote:
                                    final escaped:String = StringTools.replace(child.nodeValue, '"', '\\"');
                                    stringBuffer.add('"${escaped}"');
                                case SingleQuote:
                                    Utils.validateSingleQuote(child.nodeValue, child.nodeName);
                                    stringBuffer.add(Utils.normaliseValue(child.nodeValue));
                            }
					        
                            stringBuffer.add("\n");

                default:
            }
		}

		return stringBuffer.toString();
	}
}
