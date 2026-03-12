package hxenv;

class Utils {
    public static var valChar:Map<Int, Bool> = populateValChars();

    static function populateValChars():Map<Int, Bool> {
		var valChar = new Map<Int, Bool>(); 

		// populate value chars with bools at ascii positions
		for (i in 'A'.code...'Z'.code + 1) {
			valChar[i] = true;
		}

		for (i in 'a'.code...'z'.code + 1) {
			valChar[i] = true;
		}

		for (i in '0'.code...'9'.code + 1) {
			valChar[i] = true;
		}

		valChar["_".code] = true;
		valChar[".".code] = true;
		valChar["-".code] = true;
		valChar["/".code] = true;
		valChar[":".code] = true;
		valChar["@".code] = true;
		valChar["%".code] = true;
		valChar["+".code] = true;
		valChar[",".code] = true;
		valChar["=".code] = true;
		return valChar;
	}

    public static var idChar:Map<Int, Bool> = populateIdChars();

    static function populateIdChars():Map<Int, Bool> {
		var idChar = new Map<Int, Bool>(); 

		// populate identifier chars with bools at ascii positions
		for (i in 'A'.code...'Z'.code + 1) {
			idChar[i] = true;
		}

		for (i in 'a'.code...'z'.code + 1) {
			idChar[i] = true;
		}

		for (i in '0'.code...'9'.code + 1) {
			idChar[i] = true;
		}

		idChar["_".code] = true;
		return idChar;
	}

    public static function normaliseValue(value:String) {
        if (value.length == 0) return "";

        var needQuotes:Bool = false;

        for (i in 0...value.length) {
            final char:Int = value.charCodeAt(i);

            if (!valChar[char]) {
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