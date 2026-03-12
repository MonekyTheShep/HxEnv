package hxenv;

class Util {
    public static function normaliseValue(value:String) {
        if (value.length == 0) return "";

        var needQuotes:Bool = false;

        for (i in 0...value.length) {
            final char:Int = value.charCodeAt(i);

            if (char == '\n'.code || char == ' '.code || char == "'".code || char == '"'.code) {
                needQuotes = true;
                break;
            }
        }

        if (needQuotes) {
            final escaped:String = StringTools.replace(value, '"', '\\"');
            return '"${escaped}"';
        }

        return value;

    }
}