package hxenv;

using StringTools;

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
		valChar["#".code] = true;
		valChar["%".code] = true;
		valChar["~".code] = true;
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

	public static function validateKey(key:String) {
		for (char in key) {
			if (!Utils.idChar[char]) throw 'Unexpected char `${String.fromCharCode(char)}` in key: "${key}"!';
		}
	}

	public static function validateRawValue(value:String, key:String) {
		for (char in value) {
			if (!Utils.valChar[char]) throw 'Unexpected char `${String.fromCharCode(char)}` in value of key: "${key}"!';
		}
	}

	public static function validateSingleQuotedValue(value:String, key:String) {
		for (char in value) {
			if (char == "'".code && char == '\n'.code) throw 'Unexpected char `${String.fromCharCode(char)}` in value of key: "${key}"!';
		}
	}

	public static function validateComment(value:String) {
		for (char in value) {
			if (char == "\n".code) throw 'Unexpected char `${String.fromCharCode(char)}` in comment: "${value}"!';
		}
	}
}
